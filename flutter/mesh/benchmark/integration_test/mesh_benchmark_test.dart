import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh_benchmark/meshes.dart';
import 'package:mesh_benchmark/scenarios.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final results = <String, Object?>{};
  void report(String group, String name, Object value) {
    final groupResults =
        (results[group] ??= <String, Object?>{}) as Map<String, Object?>;
    groupResults[name] = value;
    binding.reportData = {...?binding.reportData, 'results': results};
    print('$group/$name: $value');
  }

  const timeout = Timeout(Duration(minutes: 10));

  testWidgets('hash', timeout: timeout, (tester) async {
    final hash = denseMesh(0.3).getHash();
    report(
      'hash',
      'from_hash_10x10',
      _measureSync(() => OMeshRect.fromHash(hash: hash)),
    );
  });

  testWidgets('paint', timeout: timeout, (tester) async {
    final cases = {
      'example_3x4_t12': (exampleMesh, 12),
      'dense_10x10_t16': (denseMesh, 16),
      'dense_6x6_t24': ((double t) => denseMesh(t, size: 6), 24),
    };
    for (final MapEntry(key: name, value: (meshAt, tessellation))
        in cases.entries) {
      report(
        'paint',
        name,
        await _measurePaint(meshAt, tessellation: tessellation),
      );
    }
  });

  testWidgets('raster', timeout: timeout, (tester) async {
    final cases = {
      'example_3x4_lab': (exampleMesh(0.37), 12),
      'dense_10x10_lab': (denseMesh(0.61), 16),
      'dense_10x10_linear': (
        denseMesh(0.61, colorSpace: OMeshColorSpace.linear),
        16,
      ),
      'dense_10x10_xyy': (denseMesh(0.61, colorSpace: OMeshColorSpace.xyY), 16),
    };
    for (final MapEntry(key: name, value: (mesh, tessellation))
        in cases.entries) {
      report(
        'raster',
        name,
        await _measureRaster(mesh, tessellation: tessellation),
      );
    }
  });

  testWidgets('frames', timeout: timeout, (tester) async {
    final cases = <String, Widget>{
      'example_3x4': const CustomAnimationScenario(meshAt: exampleMesh),
      'dense_10x10': const CustomAnimationScenario(
        meshAt: denseMesh,
        tessellation: 16,
      ),
      'implicit_6x6': const ImplicitAnimationScenario(),
    };
    for (final MapEntry(key: name, value: scenario) in cases.entries) {
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: scenario),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      report('frames', name, await _measureFrames());
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  });

  testWidgets('images', timeout: timeout, (tester) async {
    final cases = {
      'example_lab': (exampleMesh(0.37), 12),
      'dense_lab': (denseMesh(0.61), 16),
      'dense_linear': (denseMesh(0.61, colorSpace: OMeshColorSpace.linear), 16),
      'dense_xyy': (denseMesh(0.61, colorSpace: OMeshColorSpace.xyY), 16),
      'dense_lab_t3': (denseMesh(0.2), 3),
      'transparent_lab': (transparentMesh(colorSpace: OMeshColorSpace.lab), 8),
      'transparent_xyy': (transparentMesh(), 8),
    };
    final images = <String, String>{};
    for (final MapEntry(key: name, value: (mesh, tessellation))
        in cases.entries) {
      images[name] = await _renderRgba(mesh, tessellation: tessellation);
    }
    results['images'] = images;
    binding.reportData = {...?binding.reportData, 'results': results};
  });
}

Future<Map<String, Object>> _measurePaint(
  OMeshRect Function(double t) meshAt, {
  required int tessellation,
  int frames = 2000,
  int warmup = 300,
}) async {
  final provider = await OMeshShaderProvider.load();
  final painter = OMeshRectPaint(
    shaderProvider: provider,
    meshRect: meshAt(0),
    tessellation: tessellation,
    debugMode: null,
  );
  const rect = Rect.fromLTWH(0, 0, 1170, 2532);
  final meshes = [for (var i = 0; i < 240; i++) meshAt(i / 240)];

  final samples = Float64List(frames);
  final sw = Stopwatch();
  final rssStart = ProcessInfo.currentRss;
  var rssPeak = rssStart;
  for (var i = -warmup; i < frames; i++) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    sw
      ..reset()
      ..start();
    painter
      ..meshRect = meshes[(i + warmup) % meshes.length]
      ..paint(canvas, rect);
    final picture = recorder.endRecording();
    sw.stop();
    picture.dispose();
    if (i >= 0) samples[i] = sw.elapsedTicks * 1e6 / sw.frequency;
    if (i % 25 == 0) rssPeak = math.max(rssPeak, ProcessInfo.currentRss);
  }
  provider.dispose();
  return {
    ..._stats(samples, 'us'),
    'rss_growth_mb': _round((rssPeak - rssStart) / (1024 * 1024)),
  };
}

Future<Map<String, Object>> _measureFrames({
  Duration duration = const Duration(seconds: 6),
}) async {
  final timings = <ui.FrameTiming>[];
  void onTimings(List<ui.FrameTiming> batch) => timings.addAll(batch);
  SchedulerBinding.instance.addTimingsCallback(onTimings);
  await Future<void>.delayed(duration + const Duration(milliseconds: 1200));
  SchedulerBinding.instance.removeTimingsCallback(onTimings);

  double ms(Duration d) => d.inMicroseconds / 1000;
  final build = Float64List.fromList([
    for (final t in timings) ms(t.buildDuration),
  ]);
  final raster = Float64List.fromList([
    for (final t in timings) ms(t.rasterDuration),
  ]);
  return {
    'build': _stats(build, 'ms'),
    'raster': _stats(raster, 'ms'),
  };
}

Future<Map<String, Object>> _measureRaster(
  OMeshRect mesh, {
  required int tessellation,
  Size size = const Size(3840, 2160),
  int iterations = 200,
  int warmup = 20,
}) async {
  final provider = await OMeshShaderProvider.load();
  final painter = OMeshRectPaint(
    shaderProvider: provider,
    meshRect: mesh,
    tessellation: tessellation,
    debugMode: null,
  );
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Offset.zero & size);
  final picture = recorder.endRecording();
  final emptyRecorder = ui.PictureRecorder();
  Canvas(emptyRecorder);
  final empty = emptyRecorder.endRecording();

  final meshSamples = Float64List(iterations);
  final emptySamples = Float64List(iterations);
  final sw = Stopwatch();
  for (var i = -warmup; i < iterations; i++) {
    for (final (p, samples) in [
      (picture, meshSamples),
      (empty, emptySamples),
    ]) {
      sw
        ..reset()
        ..start();
      await _rasterize(p, size);
      sw.stop();
      if (i >= 0) samples[i] = sw.elapsedTicks * 1e3 / sw.frequency;
    }
  }
  picture.dispose();
  empty.dispose();
  provider.dispose();

  final overhead = _median(emptySamples);
  return {
    ..._stats(meshSamples, 'ms'),
    'overhead_ms': _round(overhead),
    'net_median_ms': _round(_median(meshSamples) - overhead),
  };
}

Future<void> _rasterize(ui.Picture picture, Size size) async {
  final big = picture.toImageSync(size.width.toInt(), size.height.toInt());
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    big,
    Offset.zero & size,
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint(),
  );
  final small = recorder.endRecording();
  final image = await small.toImage(1, 1);
  await image.toByteData();
  image.dispose();
  small.dispose();
  big.dispose();
}

Future<String> _renderRgba(
  OMeshRect mesh, {
  required int tessellation,
  int size = 320,
}) async {
  final provider = await OMeshShaderProvider.load();
  final painter = OMeshRectPaint(
    shaderProvider: provider,
    meshRect: mesh,
    tessellation: tessellation,
    debugMode: null,
  );
  final recorder = ui.PictureRecorder();
  painter.paint(
    Canvas(recorder),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  provider.dispose();
  return base64Encode(bytes!.buffer.asUint8List());
}

Map<String, Object> _measureSync(
  void Function() body, {
  int iterations = 2000,
  int warmup = 200,
}) {
  final samples = Float64List(iterations);
  final sw = Stopwatch();
  for (var i = -warmup; i < iterations; i++) {
    sw
      ..reset()
      ..start();
    body();
    sw.stop();
    if (i >= 0) samples[i] = sw.elapsedTicks * 1e6 / sw.frequency;
  }
  return _stats(samples, 'us');
}

Map<String, Object> _stats(Float64List samples, String unit) {
  if (samples.isEmpty) return {'n': 0};
  final sorted = Float64List.fromList(samples)..sort();
  double at(double q) => sorted[((sorted.length - 1) * q).round()];
  final mean = sorted.reduce((a, b) => a + b) / sorted.length;
  return {
    'median_$unit': _round(at(0.5)),
    'p90_$unit': _round(at(0.9)),
    'mean_$unit': _round(mean),
    'n': sorted.length,
  };
}

double _median(Float64List samples) {
  final sorted = Float64List.fromList(samples)..sort();
  return sorted[sorted.length ~/ 2];
}

double _round(double v) => (v * 1000).round() / 1000;
