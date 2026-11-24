import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

const _side = 100;
const _left = 60;
const _top = 70;
const int _canvasWidth = _left + _side;
const int _canvasHeight = _top + _side;

const _red = Color(0xffff0000);
const _green = Color(0xff00ff00);
const _blue = Color(0xff0000ff);
const _white = Color(0xffffffff);

Future<ByteData> _paint(
  WidgetTester tester,
  OMeshShaderProvider provider,
  OMeshRect mesh,
  Rect rect, {
  DebugMode? debugMode,
}) async {
  final recorder = PictureRecorder();
  OMeshRectPaint(
    shaderProvider: provider,
    meshRect: mesh,
    tessellation: 12,
    debugMode: debugMode,
  ).paint(Canvas(recorder), rect);
  final picture = recorder.endRecording();

  final bytes = await tester.runAsync(() async {
    final image = await picture.toImage(_canvasWidth, _canvasHeight);
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!;
  });
  picture.dispose();
  return bytes!;
}

/// Paints [mesh] at the origin and at an offset, and expects the same pixels
/// in both, give or take one step per channel.
Future<void> _expectSameAtOffset(
  WidgetTester tester,
  OMeshRect mesh, {
  DebugMode? debugMode,
}) async {
  final provider = (await tester.runAsync(OMeshShaderProvider.load))!;

  final atOrigin = await _paint(
    tester,
    provider,
    mesh,
    Rect.fromLTWH(0, 0, _side.toDouble(), _side.toDouble()),
    debugMode: debugMode,
  );
  final atOffset = await _paint(
    tester,
    provider,
    mesh,
    Rect.fromLTWH(
      _left.toDouble(),
      _top.toDouble(),
      _side.toDouble(),
      _side.toDouble(),
    ),
    debugMode: debugMode,
  );

  // The mesh was painted.
  const center = (_side ~/ 2 * _canvasWidth + _side ~/ 2) * 4;
  expect(atOrigin.getUint8(center + 3), 255);

  final mismatches = <String>[];
  for (var y = 0; y < _side; y++) {
    for (var x = 0; x < _side; x++) {
      final a = (y * _canvasWidth + x) * 4;
      final b = ((y + _top) * _canvasWidth + x + _left) * 4;
      for (var channel = 0; channel < 4; channel++) {
        final expected = atOrigin.getUint8(a + channel);
        final actual = atOffset.getUint8(b + channel);
        // Rounding may differ by one step between the two positions.
        if ((expected - actual).abs() > 1) {
          mismatches.add(
            '($x, $y) channel $channel: $expected at the origin, '
            '$actual at the offset',
          );
        }
      }
    }
  }

  expect(
    mismatches.length,
    0,
    reason: 'channel values differ, first: ${mismatches.firstOrNull}',
  );
}

void main() {
  group('OMeshRectPaint on a rect away from the origin', () {
    testWidgets('paints a flat mesh with the same colors', (tester) async {
      await _expectSameAtOffset(
        tester,
        OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            (0.0, 0.0).v, (1.0, 0.0).v, //
            (0.0, 1.0).v, (1.0, 1.0).v, //
          ],
          colors: const [
            _red, _green, //
            _blue, _white, //
          ],
        ),
      );
    });

    testWidgets('paints a distorted mesh with the same colors', (tester) async {
      await _expectSameAtOffset(
        tester,
        OMeshRect(
          width: 3,
          height: 3,
          vertices: [
            (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, //
            (0.0, 0.5).v,
            (0.4, 0.6).v.bezier(
                  north: (0.6, 0.3).v,
                  east: (0.8, 0.7).v,
                  south: (0.3, 0.9).v,
                  west: (0.1, 0.4).v,
                ),
            (1.0, 0.5).v, //
            (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, //
          ],
          colors: const [
            _red, _white, _green, //
            _white, _blue, _white, //
            _blue, _green, _red, //
          ],
        ),
      );
    });

    testWidgets('paints the debug dots in the same places', (tester) async {
      await _expectSameAtOffset(
        tester,
        OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            (0.0, 0.0).v, (1.0, 0.0).v, //
            (0.0, 1.0).v, (1.0, 1.0).v, //
          ],
          colors: const [
            _red, _green, //
            _blue, _white, //
          ],
        ),
        debugMode: DebugMode.dots,
      );
    });
  });
}
