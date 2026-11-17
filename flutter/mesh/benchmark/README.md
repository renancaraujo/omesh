# mesh benchmarks

Profile-mode benchmarks for the `mesh` package. They run on a real GPU (Impeller on macOS) and measure:

| group | what it measures |
|---|---|
| `paint` | UI-thread time of `OMeshRectPaint.paint` per frame (recording only), and RSS growth over 2000 frames |
| `raster` | raster thread + GPU time to render one recorded 3840×2160 frame (readback is kept to 1 pixel; the cost of an empty frame is subtracted) |
| `frames` | `FrameTiming` build and raster durations of real animated widgets on screen |
| `hash` | `OMeshRect.fromHash` decode time |

It also renders a few reference images so you can check that a change doesn't alter the output.

## Setup

Platform folders are not committed. Generate the macOS runner once:

```sh
flutter create --platforms=macos --empty --no-pub .
```

## Run

```sh
BENCH_OUT=build/main flutter drive --profile -d macos \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/mesh_benchmark_test.dart
```

This writes `build/main/results.json` and `build/main/images/*.rgba`.

To benchmark another version of the package (a branch checked out in a worktree, for example), point the app at it with a `pubspec_overrides.yaml` (ignored by git) and run again with a different `BENCH_OUT`:

```yaml
dependency_overrides:
  mesh:
    path: /path/to/other/checkout/flutter/mesh
```

## Compare

```sh
dart tool/compare.dart main=build/main branch=build/branch
```

Prints Markdown tables with each run against the first one, and a pixel diff of the reference images.

Numbers are noisy on a laptop: close other apps, keep it plugged in, and run each version more than once.
