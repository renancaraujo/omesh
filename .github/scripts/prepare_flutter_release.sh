#!/usr/bin/env bash
# Prepares a release of the flutter/mesh package:
#   - bumps the version in pubspec.yaml
#   - prepends a changelog section listing the PRs merged since the last release
#
# Usage: prepare_flutter_release.sh <version>
set -euo pipefail

version="${1:-}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]; then
  echo "usage: $0 <semver version>" >&2
  exit 1
fi

repo_url="https://github.com/renancaraujo/omesh"
package_dir="flutter/mesh"
pubspec="$package_dir/pubspec.yaml"
changelog="$package_dir/CHANGELOG.md"

current="$(sed -n 's/^version: //p' "$pubspec")"
if [[ "$current" == "$version" ]]; then
  echo "pubspec.yaml is already at version $version" >&2
  exit 1
fi

previous_tag="$(git tag --list 'flutter-v*' --sort=-v:refname | head -n 1)"
range="HEAD"
if [[ -n "$previous_tag" ]]; then
  range="$previous_tag..HEAD"
fi

# One line per squash-merged PR touching the package, newest first.
# Dependency bumps and previous release PRs are left out.
entries="$(
  git log "$range" --no-merges --format='%s' -- "$package_dir" \
    | grep -Ev '^chore\(deps\)|^chore: flutter-v' \
    | sed -E "s|^(.*) \(#([0-9]+)\)$|- \1 [#\2]($repo_url/pull/\2)|" \
    || true
)"

if [[ -z "$entries" ]]; then
  echo "no changes found in $package_dir since $previous_tag" >&2
  exit 1
fi

sed -i.bak "s/^version: .*/version: $version/" "$pubspec" && rm "$pubspec.bak"

{
  echo "# v$version"
  echo
  echo "$entries"
  echo
  cat "$changelog"
} > "$changelog.new"
mv "$changelog.new" "$changelog"

echo "Prepared release $version (previous: ${previous_tag:-none})"
echo
echo "$entries"
