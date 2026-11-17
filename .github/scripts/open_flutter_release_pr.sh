#!/usr/bin/env bash
# Opens the release pull request of the flutter/mesh package from your machine.
#
# Local equivalent of the `release_pr` job of the "flutter release" workflow:
#   - bumps the version in pubspec.yaml and prepends the changelog section
#     (via prepare_flutter_release.sh)
#   - commits it as "chore: flutter-v<version>" on `chore/flutter-<version>`
#   - pushes the branch and opens the pull request against main
#
# Everything happens in a temporary worktree created from origin/main, so the
# checkout this is run from (branch, uncommitted changes) is left untouched.
#
# Usage: open_flutter_release_pr.sh <version> [--edit] [--dry-run]
#   --edit     open the changelog in $EDITOR before committing
#   --dry-run  show the diff and the pull request, change nothing
#
# Requires git and an authenticated GitHub CLI (gh).
set -euo pipefail

usage() {
  sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p;}' "${BASH_SOURCE[0]}"
}

version=""
edit=false
dry_run=false
for arg in "$@"; do
  case "$arg" in
    --edit) edit=true ;;
    --dry-run) dry_run=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $arg" >&2
      exit 1
      ;;
    *)
      if [[ -n "$version" ]]; then
        echo "only one version can be given" >&2
        exit 1
      fi
      version="$arg"
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"

remote="origin"
base="main"
package_dir="flutter/mesh"
changelog="$package_dir/CHANGELOG.md"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]; then
  current="$(sed -n 's/^version: //p' "$repo_root/$package_dir/pubspec.yaml")"
  echo "usage: $0 <semver version> [--edit] [--dry-run]" >&2
  echo "current version here: $current" >&2
  exit 1
fi

tag="flutter-v$version"
branch="chore/flutter-$version"
title="chore: flutter-v$version"

if ! command -v gh > /dev/null; then
  echo "the GitHub CLI (gh) is required: https://cli.github.com" >&2
  exit 1
fi

git -C "$repo_root" fetch --quiet --tags "$remote" "$base"

if git -C "$repo_root" rev-parse --quiet --verify "refs/tags/$tag" > /dev/null; then
  echo "tag $tag already exists, $version was already released" >&2
  exit 1
fi

if [[ "$dry_run" == false ]]; then
  if git -C "$repo_root" show-ref --quiet --verify "refs/heads/$branch"; then
    echo "branch $branch already exists locally" >&2
    exit 1
  fi
  if git -C "$repo_root" ls-remote --exit-code --heads "$remote" "$branch" > /dev/null; then
    echo "branch $branch already exists on $remote" >&2
    exit 1
  fi
fi

tmp_dir="$(mktemp -d)"
worktree="$tmp_dir/omesh"
created_branch=false
done_ok=false

cleanup() {
  git -C "$repo_root" worktree remove --force "$worktree" 2> /dev/null || true
  rm -rf "$tmp_dir"
  # A failed run leaves nothing behind, so it can simply be run again.
  if [[ "$created_branch" == true && "$done_ok" == false ]]; then
    git -C "$repo_root" branch --quiet -D "$branch" 2> /dev/null || true
  fi
}
trap cleanup EXIT

if [[ "$dry_run" == true ]]; then
  git -C "$repo_root" worktree add --quiet --detach "$worktree" "$remote/$base"
else
  git -C "$repo_root" worktree add --quiet --no-track -b "$branch" "$worktree" "$remote/$base"
  created_branch=true
fi

(cd "$worktree" && "$script_dir/prepare_flutter_release.sh" "$version" > /dev/null)

if [[ "$edit" == true && "$dry_run" == false ]]; then
  "${VISUAL:-${EDITOR:-vi}}" "$worktree/$changelog"
fi

# The changelog section of this version, without its "# v<version>" heading.
notes="$(
  awk -v heading="# v$version" '
    $0 == heading { inside = 1; next }
    inside && /^# v/ { exit }
    inside
  ' "$worktree/$changelog"
)"

if [[ -z "${notes//[[:space:]]/}" ]]; then
  echo "the changelog section of v$version is empty" >&2
  exit 1
fi

# Same body the "flutter release" workflow writes.
body_file="$tmp_dir/body.md"
cat > "$body_file" << EOF
## Description

$title
$notes

Review the changelog above and edit \`$changelog\` on this branch if needed. Merging this PR tags and publishes the package.

## (Required) Link to the issue

Link to the issue related to this contribution #
EOF

if [[ "$dry_run" == true ]]; then
  echo "=== dry run, nothing was committed, pushed or opened ==="
  echo
  echo "branch: $branch -> $base"
  echo "title:  $title"
  echo
  echo "=== diff ==="
  git -C "$worktree" --no-pager diff
  echo
  echo "=== pull request body ==="
  cat "$body_file"
  exit 0
fi

git -C "$worktree" add "$package_dir/pubspec.yaml" "$changelog"
git -C "$worktree" commit --quiet -m "$title"
git -C "$worktree" push --quiet --set-upstream "$remote" "$branch"

# gh refuses labels that do not exist yet (the workflow creates it on the fly).
if ! (cd "$worktree" && gh label list --search release --json name --jq '.[].name') | grep -qx release; then
  (cd "$worktree" && gh label create release --description "Release pull request" --color 0E8A16)
fi

(cd "$worktree" && gh pr create \
  --base "$base" \
  --head "$branch" \
  --title "$title" \
  --label release \
  --body-file "$body_file")

done_ok=true
