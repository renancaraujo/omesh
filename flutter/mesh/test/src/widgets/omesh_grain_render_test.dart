import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

OMeshRect _mesh({
  required List<Color> colors,
  bool smoothColors = true,
  Color? backgroundColor,
}) {
  return OMeshRect(
    width: 2,
    height: 2,
    colorSpace: OMeshColorSpace.linear,
    smoothColors: smoothColors,
    backgroundColor: backgroundColor,
    vertices: [
      (0.0, 0.0).v, (1.0, 0.0).v, //
      (0.0, 1.0).v, (1.0, 1.0).v, //
    ],
    colors: colors,
  );
}

OMeshRect _flat(Color color) => _mesh(colors: [color, color, color, color]);

const _black = Color(0xff000000);
const _dark = Color(0xff202020);
const _mid = Color(0xff808080);
const _light = Color(0xffe0e0e0);
const _white = Color(0xffffffff);

/// A 3×3 mesh with a moved centre vertex and different colours in each
/// corner, so a flipped, shifted or wrongly scaled copy does not match.
final OMeshRect _asymmetric = OMeshRect(
  width: 3,
  height: 3,
  vertices: [
    (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, //
    (0.0, 0.5).v, (0.65, 0.3).v, (1.0, 0.5).v, //
    (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, //
  ],
  colors: const [
    Color(0xffff3b30), Color(0xffffcc00), Color(0xff34c759), //
    Color(0xff5856d6), Color(0xffffffff), Color(0xff00c7be), //
    Color(0xff000000), Color(0xffaf52de), Color(0xff007aff), //
  ],
);

/// Black to white from left to right, one level per pixel over 256 pixels,
/// with no easing, so a colour lookup moved by n pixels changes the value
/// by about n levels.
final OMeshRect _ramp = _mesh(
  smoothColors: false,
  colors: const [_black, _white, _black, _white],
);

const _rampRect = Rect.fromLTWH(0, 0, 256, 16);

/// Grain on every brightness, without scatter.
const _even = OMeshGrain(
  amount: 0.1,
  scatter: 0,
  shadows: 1,
  highlights: 1,
);

class _Pixels {
  _Pixels(this.width, this.height, this.bytes);

  final int width;
  final int height;
  final Uint8List bytes;

  int channel(int x, int y, int c) => bytes[(y * width + x) * 4 + c];

  int red(int x, int y) => channel(x, y, 0);

  /// The largest difference of any channel against [other].
  int maxDifference(_Pixels other) {
    expect(other.bytes.length, bytes.length);
    var max = 0;
    for (var i = 0; i < bytes.length; i++) {
      max = math.max(max, (bytes[i] - other.bytes[i]).abs());
    }
    return max;
  }

  /// The red channel of every pixel, minus [base].
  List<double> redOffsets(int base) => [
        for (var y = 0; y < height; y++)
          for (var x = 0; x < width; x++) (red(x, y) - base).toDouble(),
      ];

  /// The share of aligned [k]×[k] blocks whose pixels all have the same red
  /// value.
  double flatBlockShare(int k) {
    var flat = 0;
    var total = 0;
    for (var by = 0; by + k <= height; by += k) {
      for (var bx = 0; bx + k <= width; bx += k) {
        final first = red(bx, by);
        var same = true;
        for (var y = by; y < by + k && same; y++) {
          for (var x = bx; x < bx + k && same; x++) {
            same = red(x, y) == first;
          }
        }
        if (same) flat++;
        total++;
      }
    }
    return flat / total;
  }
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _std(List<double> values) {
  final mean = _mean(values);
  final squares = values.map((v) => (v - mean) * (v - mean));
  return math.sqrt(squares.reduce((a, b) => a + b) / values.length);
}

double _correlation(List<double> a, List<double> b) {
  final ma = _mean(a);
  final mb = _mean(b);
  var ab = 0.0;
  var aa = 0.0;
  var bb = 0.0;
  for (var i = 0; i < a.length; i++) {
    ab += (a[i] - ma) * (b[i] - mb);
    aa += (a[i] - ma) * (a[i] - ma);
    bb += (b[i] - mb) * (b[i] - mb);
  }
  return ab / math.sqrt(aa * bb);
}

Future<_Pixels> _toPixels(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(image.toByteData);
  final pixels = _Pixels(image.width, image.height, data!.buffer.asUint8List());
  image.dispose();
  return pixels;
}

/// Paints [mesh] with an [OMeshRectPaint] into [rect] of a canvas of
/// [canvasSize] logical pixels, scaled by [dpr], and reads it back at
/// physical resolution.
Future<_Pixels> _paint(
  WidgetTester tester,
  OMeshShaderProvider provider,
  OMeshRect mesh, {
  OMeshGrain? grain,
  double dpr = 1,
  Rect rect = const Rect.fromLTWH(0, 0, 64, 64),
  Size? canvasSize,
}) async {
  final size = canvasSize ?? Size(rect.right, rect.bottom);
  final painter = OMeshRectPaint(
    shaderProvider: provider,
    meshRect: mesh,
    tessellation: 8,
    debugMode: null,
    grain: grain,
    devicePixelRatio: dpr,
  );
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder)..scale(dpr), rect);
  final picture = recorder.endRecording();
  final image = (await tester.runAsync(
    () => picture.toImage(
      (size.width * dpr).round(),
      (size.height * dpr).round(),
    ),
  ))!;
  picture.dispose();
  painter.dispose();
  return await _toPixels(tester, image);
}

final GlobalKey _boundaryKey = GlobalKey();

Future<_Pixels> _render(
  WidgetTester tester,
  Widget gradient, {
  Size size = const Size(64, 64),
  double pixelRatio = 1,
}) async {
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox.fromSize(size: size, child: gradient),
      ),
    ),
  );
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: pixelRatio),
  ))!;
  return await _toPixels(tester, image);
}

/// Tracks the images that are alive while [body] runs.
Future<void> _trackImages(
  Future<void> Function(Set<ui.Image> alive, Set<ui.Image> created) body,
) async {
  final previousCreate = ui.Image.onCreate;
  final previousDispose = ui.Image.onDispose;
  final alive = <ui.Image>{};
  final created = <ui.Image>{};
  ui.Image.onCreate = (image) {
    previousCreate?.call(image);
    alive.add(image);
    created.add(image);
  };
  ui.Image.onDispose = (image) {
    previousDispose?.call(image);
    alive.remove(image);
  };
  try {
    await body(alive, created);
  } finally {
    ui.Image.onCreate = previousCreate;
    ui.Image.onDispose = previousDispose;
  }
}

void main() {
  late OMeshShaderProvider provider;

  Future<void> load(WidgetTester tester) async {
    provider = (await tester.runAsync(OMeshShaderProvider.load))!;
    addTearDown(provider.dispose);
    await tester.runAsync(provider.loadGrainShader);
    expect(provider.grainShader, isNotNull);
  }

  group('grain off', () {
    testWidgets('no grain, none and zero amounts paint the same', (t) async {
      await load(t);
      final plain = await _paint(t, provider, _asymmetric);
      for (final grain in const [
        OMeshGrain.none,
        OMeshGrain(amount: 0, scatter: 0, seed: 123),
        OMeshGrain(amount: 0, scatter: 0, shadows: 0, highlights: 3),
      ]) {
        final off = await _paint(t, provider, _asymmetric, grain: grain);
        expect(off.maxDifference(plain), 0, reason: '$grain');
      }
    });
  });

  group('grain pass', () {
    // Zero weights send the mesh through the offscreen image and the grain
    // shader, but add no noise, so the result must match the plain path.
    const zeroWeights = OMeshGrain(
      amount: 0.2,
      scatter: 0,
      shadows: 0,
      midtones: 0,
      highlights: 0,
    );

    for (final dpr in const [1.0, 2.0, 3.0]) {
      testWidgets('draws the same picture as the plain path at ratio $dpr',
          (t) async {
        await load(t);
        const rect = Rect.fromLTWH(13, 7, 60, 50);
        const canvasSize = Size(80, 64);
        final plain = await _paint(
          t,
          provider,
          _asymmetric,
          dpr: dpr,
          rect: rect,
          canvasSize: canvasSize,
        );
        final grained = await _paint(
          t,
          provider,
          _asymmetric,
          grain: zeroWeights,
          dpr: dpr,
          rect: rect,
          canvasSize: canvasSize,
        );
        expect(grained.maxDifference(plain), lessThanOrEqualTo(1));
      });
    }

    testWidgets('keeps alpha and translucent colours', (t) async {
      await load(t);
      final mesh = _mesh(
        colors: const [
          Color(0x40ff0000), Color(0x8000ff00), //
          Color(0xc00000ff), Color(0x00000000), //
        ],
      );
      final plain = await _paint(t, provider, mesh);
      final grained = await _paint(t, provider, mesh, grain: zeroWeights);
      expect(grained.maxDifference(plain), lessThanOrEqualTo(1));

      final noisy = await _paint(t, provider, mesh, grain: _even);
      for (var i = 3; i < noisy.bytes.length; i += 4) {
        expect(noisy.bytes[i], plain.bytes[i]);
      }
    });
  });

  group('grain amount', () {
    testWidgets('sets the size of the noise', (t) async {
      await load(t);
      final small = await _paint(
        t,
        provider,
        _flat(_mid),
        grain: _even.copyWith(amount: 0.05),
      );
      final large = await _paint(
        t,
        provider,
        _flat(_mid),
        grain: _even.copyWith(amount: 0.1),
      );
      // Triangular noise peaking at amount × 255 has a standard deviation
      // of amount × 255 / √6.
      final smallOffsets = small.redOffsets(0x80);
      final largeOffsets = large.redOffsets(0x80);
      expect(_std(smallOffsets), closeTo(0.05 * 255 / math.sqrt(6), 0.8));
      expect(_std(largeOffsets), closeTo(0.1 * 255 / math.sqrt(6), 1.2));
      expect(_mean(smallOffsets).abs(), lessThan(0.5));
      expect(_mean(largeOffsets).abs(), lessThan(0.5));
    });

    testWidgets('adds the same noise to red, green and blue', (t) async {
      await load(t);
      final pixels = await _paint(t, provider, _flat(_mid), grain: _even);
      for (var i = 0; i < pixels.bytes.length; i += 4) {
        expect(pixels.bytes[i + 1], pixels.bytes[i]);
        expect(pixels.bytes[i + 2], pixels.bytes[i]);
      }
    });
  });

  group('grain weights', () {
    Future<double> noise(WidgetTester t, Color color, OMeshGrain grain) async {
      final pixels = await _paint(t, provider, _flat(color), grain: grain);
      return _std(pixels.redOffsets((color.r * 255).round()));
    }

    const only = OMeshGrain(
      amount: 0.1,
      scatter: 0,
      shadows: 0,
      midtones: 0,
      highlights: 0,
    );

    testWidgets('shadows act on dark colours only', (t) async {
      await load(t);
      final grain = only.copyWith(shadows: 1);
      expect(await noise(t, _dark, grain), greaterThan(5));
      expect(await noise(t, _light, grain), 0);
    });

    testWidgets('highlights act on light colours only', (t) async {
      await load(t);
      final grain = only.copyWith(highlights: 1);
      expect(await noise(t, _light, grain), greaterThan(5));
      expect(await noise(t, _dark, grain), 0);
    });

    testWidgets('midtones act on middle grey, not on black or white',
        (t) async {
      await load(t);
      final grain = only.copyWith(midtones: 1);
      expect(await noise(t, _mid, grain), greaterThan(5));
      expect(await noise(t, _black, grain), 0);
      expect(await noise(t, _white, grain), 0);
    });
  });

  group('grain seed', () {
    testWidgets('the same seed repeats the pattern', (t) async {
      await load(t);
      final a = await _paint(t, provider, _flat(_mid), grain: _even);
      final b = await _paint(t, provider, _flat(_mid), grain: _even);
      expect(a.maxDifference(b), 0);
    });

    testWidgets('another seed gives an unrelated grain pattern', (t) async {
      await load(t);
      final a = await _paint(t, provider, _flat(_mid), grain: _even);
      final b = await _paint(
        t,
        provider,
        _flat(_mid),
        grain: _even.copyWith(seed: 7),
      );
      final correlation = _correlation(a.redOffsets(0x80), b.redOffsets(0x80));
      expect(correlation.abs(), lessThan(0.1));
    });

    testWidgets('another seed gives an unrelated scatter pattern', (t) async {
      await load(t);
      const scatter = OMeshGrain(amount: 0, scatter: 12);
      final plain = await _paint(t, provider, _ramp, rect: _rampRect);
      final a =
          await _paint(t, provider, _ramp, rect: _rampRect, grain: scatter);
      final b = await _paint(
        t,
        provider,
        _ramp,
        rect: _rampRect,
        grain: scatter.copyWith(seed: 7),
      );
      final correlation = _correlation(
        _rampShifts(a, plain),
        _rampShifts(b, plain),
      );
      expect(correlation.abs(), lessThan(0.1));
    });
  });

  group('grain cells', () {
    for (final dpr in const [2.0, 3.0]) {
      testWidgets('are one physical pixel at ratio $dpr', (t) async {
        await load(t);
        final pixels = await _paint(
          t,
          provider,
          _flat(_mid),
          grain: _even,
          dpr: dpr,
        );
        expect(pixels.flatBlockShare(dpr.toInt()), lessThan(0.05));
      });
    }

    testWidgets('neighbours are not correlated', (t) async {
      await load(t);
      final pixels = await _paint(t, provider, _flat(_mid), grain: _even);
      final left = <double>[];
      final right = <double>[];
      for (var y = 0; y < pixels.height; y++) {
        for (var x = 0; x + 1 < pixels.width; x++) {
          left.add(pixels.red(x, y).toDouble());
          right.add(pixels.red(x + 1, y).toDouble());
        }
      }
      expect(_correlation(left, right).abs(), lessThan(0.1));
    });
  });

  group('grain pattern', () {
    testWidgets('does not repeat along a diagonal', (t) async {
      await load(t);
      const size = 320;
      final pixels = await _paint(
        t,
        provider,
        _flat(_mid),
        grain: _even,
        rect: const Rect.fromLTWH(0, 0, 320, 320),
      );
      double correlationAt(int dx, int dy) {
        final a = <double>[];
        final b = <double>[];
        for (var y = math.max(0, -dy); y < size - math.max(0, dy); y++) {
          for (var x = math.max(0, -dx); x < size - math.max(0, dx); x++) {
            a.add(pixels.red(x, y).toDouble());
            b.add(pixels.red(x + dx, y + dy).toDouble());
          }
        }
        return _correlation(a, b);
      }

      for (final (dx, dy) in const [(97, -97), (194, -194), (97, 97)]) {
        expect(
          correlationAt(dx, dy).abs(),
          lessThan(0.05),
          reason: 'shift ($dx, $dy)',
        );
      }
    });
  });

  group('scatter', () {
    testWidgets('moves colour lookups by up to scatter pixels', (t) async {
      await load(t);
      final plain = await _paint(t, provider, _ramp, rect: _rampRect);
      final scattered = await _paint(
        t,
        provider,
        _ramp,
        rect: _rampRect,
        grain: const OMeshGrain(amount: 0, scatter: 12),
      );
      final shifts = _rampShifts(scattered, plain);
      // Triangular jitter peaking at 12 has a standard deviation of 12 / √6.
      expect(_std(shifts), closeTo(12 / math.sqrt(6), 0.8));
      expect(_mean(shifts).abs(), lessThan(0.5));
      final largest = shifts.map((s) => s.abs()).reduce(math.max);
      expect(largest, inInclusiveRange(9, 13));
    });
  });

  group('$OMeshRectPaint', () {
    testWidgets('a grain or ratio change asks for a repaint', (t) async {
      await load(t);
      final painter = OMeshRectPaint(
        shaderProvider: provider,
        meshRect: _flat(_mid),
        tessellation: 4,
        debugMode: null,
      );
      void painted() {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Rect.fromLTWH(0, 0, 4, 4));
        recorder.endRecording().dispose();
        expect(painter.needsRepaint, isFalse);
      }

      painted();
      painter.grain = const OMeshGrain();
      expect(painter.needsRepaint, isTrue);

      painted();
      painter.grain = const OMeshGrain(scatter: 3);
      expect(painter.needsRepaint, isTrue);

      painted();
      painter.grain = const OMeshGrain(scatter: 3);
      expect(painter.needsRepaint, isFalse);

      painter.devicePixelRatio = 2;
      expect(painter.needsRepaint, isTrue);
      painter.dispose();
    });

    testWidgets('frees the previous offscreen image on each paint', (t) async {
      await load(t);
      await _trackImages((alive, created) async {
        final painter = OMeshRectPaint(
          shaderProvider: provider,
          meshRect: _flat(_mid),
          tessellation: 4,
          debugMode: null,
          grain: _even,
        );
        for (var i = 0; i < 3; i++) {
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Rect.fromLTWH(0, 0, 16, 16));
          recorder.endRecording().dispose();
        }
        expect(created, hasLength(3));
        expect(alive, hasLength(1));

        painter.dispose();
        expect(alive, isEmpty);
      });
    });

    testWidgets('paints an infinite rect without grain', (t) async {
      await load(t);
      for (final grain in const [null, OMeshGrain()]) {
        final painter = OMeshRectPaint(
          shaderProvider: provider,
          meshRect: _flat(_mid),
          tessellation: 4,
          debugMode: null,
          grain: grain,
        );
        final recorder = ui.PictureRecorder();
        expect(
          () => painter.paint(
            Canvas(recorder),
            const Rect.fromLTWH(0, 0, double.infinity, 10),
          ),
          returnsNormally,
          reason: '$grain',
        );
        recorder.endRecording().dispose();
        painter.dispose();
      }
    });

    testWidgets('dispose works without painting', (t) async {
      await load(t);
      final painter = OMeshRectPaint(
        shaderProvider: provider,
        meshRect: _flat(_mid),
        tessellation: 4,
        debugMode: null,
        grain: const OMeshGrain(),
        devicePixelRatio: 2,
      );
      expect(painter.dispose, returnsNormally);
    });
  });

  group('$OMeshGradient grain', () {
    testWidgets('uses the device pixel ratio for grain cells', (t) async {
      await load(t);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetDevicePixelRatio);
      final pixels = await _render(
        t,
        OMeshGradient(mesh: _flat(_mid), grain: _even),
        pixelRatio: 2,
      );
      expect(pixels.flatBlockShare(2), lessThan(0.05));
    });

    testWidgets('repaints when grain changes in place', (t) async {
      await load(t);
      Widget gradient(OMeshGrain? grain) => OMeshGradient(
            key: const ValueKey('g'),
            mesh: _flat(_mid),
            grain: grain,
          );
      final plain = await _render(t, gradient(null));
      final grained = await _render(t, gradient(_even));
      final back = await _render(t, gradient(null));
      expect(grained.maxDifference(plain), greaterThan(0));
      expect(back.maxDifference(plain), 0);
    });

    testWidgets('frees its offscreen image when removed', (t) async {
      await load(t);
      await _trackImages((alive, created) async {
        await t.pumpWidget(
          Center(
            child: SizedBox.square(
              dimension: 32,
              child: OMeshGradient(mesh: _flat(_mid), grain: _even),
            ),
          ),
        );
        expect(created, isNotEmpty);
        await t.pumpWidget(const SizedBox());
        expect(alive, isEmpty);
      });
    });
  });

  group('$AnimatedOMeshGradient grain', () {
    testWidgets('passes grain to the painter', (t) async {
      await load(t);
      final pixels = await _render(
        t,
        AnimatedOMeshGradient(
          mesh: _flat(_mid),
          duration: const Duration(milliseconds: 100),
          grain: _even,
        ),
      );
      expect(_std(pixels.redOffsets(0x80)), greaterThan(5));
    });
  });
}

/// How far each pixel's colour lookup moved, in pixels, for the [_ramp]
/// mesh: the difference against the [plain] picture, left and right edges
/// and top and bottom rows skipped, where lookups are clamped to the patch.
List<double> _rampShifts(_Pixels scattered, _Pixels plain) => [
      for (var y = 2; y < scattered.height - 2; y++)
        for (var x = 20; x < scattered.width - 20; x++)
          (scattered.red(x, y) - plain.red(x, y)).toDouble(),
    ];
