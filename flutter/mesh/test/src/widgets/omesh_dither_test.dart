import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

OMeshRect _mesh({
  required List<Color> colors,
  OMeshColorSpace colorSpace = OMeshColorSpace.linear,
  Color? backgroundColor,
}) {
  return OMeshRect(
    width: 2,
    height: 2,
    colorSpace: colorSpace,
    backgroundColor: backgroundColor,
    vertices: [
      (0.0, 0.0).v, (1.0, 0.0).v, //
      (0.0, 1.0).v, (1.0, 1.0).v, //
    ],
    colors: colors,
  );
}

OMeshRect _flat(Color color) => _mesh(colors: [color, color, color, color]);

/// A slow horizontal ramp: 8 levels over 256 pixels, so 8-bit output
/// shows plateaus about 32 pixels wide.
final OMeshRect _opaqueRamp = _mesh(
  colors: const [
    Color(0xff101010), Color(0xff181818), //
    Color(0xff101010), Color(0xff181818), //
  ],
);

/// A translucent ramp over an opaque background: 8 levels over 256 pixels.
final OMeshRect _translucentRamp = _mesh(
  backgroundColor: const Color(0xffffffff),
  colors: const [
    Color(0x40000000), Color(0x48000000), //
    Color(0x40000000), Color(0x48000000), //
  ],
);

final GlobalKey _boundaryKey = GlobalKey();

Future<Uint8List> _render(
  WidgetTester tester,
  Widget gradient, {
  Size size = const Size(64, 64),
  Duration settle = Duration.zero,
}) async {
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox.fromSize(size: size, child: gradient),
      ),
    ),
  );
  if (settle > Duration.zero) await tester.pump(settle);

  final bytes = await tester.runAsync(() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Future<Uint8List> _renderMesh(
  WidgetTester tester,
  OMeshRect mesh, {
  required bool dither,
  Size size = const Size(64, 64),
}) {
  return _render(
    tester,
    OMeshGradient(mesh: mesh, dither: dither, tessellation: 4),
    size: size,
  );
}

/// Largest change of any red, green or blue byte.
int _maxRgbChange(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  var max = 0;
  for (var i = 0; i < a.length; i++) {
    if (i % 4 == 3) continue;
    final d = (a[i] - b[i]).abs();
    if (d > max) max = d;
  }
  return max;
}

void _expectSameAlpha(Uint8List a, Uint8List b) {
  for (var i = 3; i < a.length; i += 4) {
    expect(a[i], b[i], reason: 'alpha at byte $i');
  }
}

/// Shares of red, green and blue bytes that went up and down.
(double up, double down) _changeShares(Uint8List off, Uint8List on) {
  var up = 0;
  var down = 0;
  var total = 0;
  for (var i = 0; i < off.length; i++) {
    if (i % 4 == 3) continue;
    total++;
    if (on[i] > off[i]) up++;
    if (on[i] < off[i]) down++;
  }
  return (up / total, down / total);
}

/// Share of horizontally neighbouring 8×8 blocks whose mean red is
/// exactly equal. High when the image has flat bands wider than a block,
/// near zero when the bands are broken up.
double _flatBlockShare(Uint8List bytes, Size size) {
  const block = 8;
  final width = size.width.toInt();
  final columns = width ~/ block;
  final rows = size.height.toInt() ~/ block;
  var equal = 0;
  var pairs = 0;
  for (var by = 0; by < rows; by++) {
    int? previous;
    for (var bx = 0; bx < columns; bx++) {
      var sum = 0;
      for (var y = by * block; y < (by + 1) * block; y++) {
        for (var x = bx * block; x < (bx + 1) * block; x++) {
          sum += bytes[(y * width + x) * 4];
        }
      }
      if (previous != null) {
        pairs++;
        if (sum == previous) equal++;
      }
      previous = sum;
    }
  }
  return equal / pairs;
}

/// Records the names of the canvas calls a paint makes.
class _RecordingCanvas implements Canvas {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    calls.add(name.substring('Symbol("'.length, name.length - 2));
    return null;
  }
}

void main() {
  late OMeshShaderProvider provider;

  setUp(() async {
    provider = await OMeshShaderProvider.load();
  });

  tearDown(() => provider.dispose());

  OMeshRectPaint meshPaint(OMeshRect mesh, {bool? dither}) {
    return dither == null
        ? OMeshRectPaint(
            shaderProvider: provider,
            meshRect: mesh,
            tessellation: 2,
            debugMode: null,
          )
        : OMeshRectPaint(
            shaderProvider: provider,
            meshRect: mesh,
            tessellation: 2,
            debugMode: null,
            dither: dither,
          );
  }

  test('dither is off by default', () {
    final mesh = _flat(const Color(0xff808080));
    expect(OMeshGradient(mesh: mesh).dither, isFalse);
    expect(
      AnimatedOMeshGradient(mesh: mesh, duration: Duration.zero).dither,
      isFalse,
    );
    expect(meshPaint(mesh).dither, isFalse);
  });

  group('paint order', () {
    List<String> callsFor(OMeshRect mesh, {required bool dither}) {
      final canvas = _RecordingCanvas();
      meshPaint(mesh, dither: dither)
          .paint(canvas, Offset.zero & const Size(10, 10));
      return canvas.calls;
    }

    final withBackground = _mesh(
      backgroundColor: const Color(0xff000000),
      colors: const [
        Color(0x80ff0000), Color(0x8000ff00), //
        Color(0x800000ff), Color(0x80ffffff), //
      ],
    );

    test('draws the background under the layer with dither off', () {
      expect(
        callsFor(withBackground, dither: false),
        ['drawRect', 'saveLayer', 'drawVertices', 'restore'],
      );
    });

    test('draws the background inside the layer with dither on', () {
      expect(
        callsFor(withBackground, dither: true),
        ['saveLayer', 'drawRect', 'drawVertices', 'restore'],
      );
    });

    test('draws no background when there is none', () {
      final mesh = _flat(const Color(0x80808080));
      for (final dither in [false, true]) {
        expect(
          callsFor(mesh, dither: dither),
          ['saveLayer', 'drawVertices', 'restore'],
        );
      }
    });
  });

  test('changing dither asks for a repaint', () {
    final paint = meshPaint(_flat(const Color(0xff808080)));
    final recorder = ui.PictureRecorder();
    paint.paint(Canvas(recorder), Offset.zero & const Size(10, 10));
    recorder.endRecording().dispose();
    expect(paint.needsRepaint, isFalse);

    paint.dither = false;
    expect(paint.needsRepaint, isFalse);

    paint.dither = true;
    expect(paint.needsRepaint, isTrue);
  });

  group('toggling dither', () {
    final mesh = _flat(const Color(0xff808080));

    testWidgets('through OMeshGradient', (tester) async {
      final off = await _renderMesh(tester, mesh, dither: false);
      final on = await _renderMesh(tester, mesh, dither: true);
      final offAgain = await _renderMesh(tester, mesh, dither: false);
      expect(_maxRgbChange(off, on), 1);
      expect(offAgain, off);
    });

    testWidgets('through AnimatedOMeshGradient', (tester) async {
      Future<Uint8List> render({required bool dither}) => _render(
            tester,
            AnimatedOMeshGradient(
              mesh: mesh,
              duration: const Duration(milliseconds: 100),
              dither: dither,
            ),
            settle: const Duration(milliseconds: 200),
          );
      final off = await render(dither: false);
      final on = await render(dither: true);
      final offAgain = await render(dither: false);
      expect(_maxRgbChange(off, on), 1);
      expect(offAgain, off);
    });
  });

  group('noise', () {
    testWidgets('is plus or minus one step on an opaque mesh', (tester) async {
      final mesh = _flat(const Color(0xff808080));
      final off = await _renderMesh(tester, mesh, dither: false);
      final on = await _renderMesh(tester, mesh, dither: true);
      _expectSameAlpha(off, on);
      expect(_maxRgbChange(off, on), 1);

      // Triangular noise of ±1 step moves an exact level up in 1/8 of the
      // pixels and down in another 1/8.
      final (up, down) = _changeShares(off, on);
      expect(up, inInclusiveRange(0.08, 0.17));
      expect(down, inInclusiveRange(0.08, 0.17));
    });

    testWidgets('is not scaled down on a translucent mesh', (tester) async {
      final mesh = _flat(const Color(0x80808080));
      final off = await _renderMesh(tester, mesh, dither: false);
      final on = await _renderMesh(tester, mesh, dither: true);
      _expectSameAlpha(off, on);
      expect(_maxRgbChange(off, on), 1);
      final (up, down) = _changeShares(off, on);
      expect(up + down, inInclusiveRange(0.16, 0.34));
    });

    testWidgets('keeps premultiplied colors at or below alpha', (tester) async {
      // Translucent white: red, green and blue already equal alpha.
      final mesh = _flat(const Color(0x80ffffff));
      final on = await _renderMesh(tester, mesh, dither: true);
      for (var i = 0; i < on.length; i += 4) {
        for (var c = 0; c < 3; c++) {
          expect(on[i + c], lessThanOrEqualTo(on[i + 3]));
        }
      }
    });

    for (final colorSpace in [OMeshColorSpace.lab, OMeshColorSpace.xyY]) {
      testWidgets('does not change the colors of translucent $colorSpace',
          (tester) async {
        // Mixing these in lab and xyY gives premultiplied red above alpha.
        // Dither must leave those values as they are.
        final mesh = _mesh(
          colorSpace: colorSpace,
          colors: const [
            Color(0x80ff0000), Color(0x80ffffff), //
            Color(0x80ff8000), Color(0x80ffff00), //
          ],
        );
        final off = await _renderMesh(tester, mesh, dither: false);
        final on = await _renderMesh(tester, mesh, dither: true);
        _expectSameAlpha(off, on);
        expect(_maxRgbChange(off, on), 1);
      });
    }
  });

  group('banding', () {
    const size = Size(256, 64);

    testWidgets('is removed on an opaque mesh', (tester) async {
      final off =
          await _renderMesh(tester, _opaqueRamp, dither: false, size: size);
      final on =
          await _renderMesh(tester, _opaqueRamp, dither: true, size: size);
      expect(_flatBlockShare(off, size), greaterThan(0.4));
      expect(_flatBlockShare(on, size), lessThan(0.1));
    });

    testWidgets('is removed on a translucent mesh over its background',
        (tester) async {
      final off = await _renderMesh(
        tester,
        _translucentRamp,
        dither: false,
        size: size,
      );
      final on = await _renderMesh(
        tester,
        _translucentRamp,
        dither: true,
        size: size,
      );
      expect(_flatBlockShare(off, size), greaterThan(0.4));
      expect(_flatBlockShare(on, size), lessThan(0.1));
    });
  });
}
