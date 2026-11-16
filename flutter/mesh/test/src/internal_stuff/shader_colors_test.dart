import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

const _xyzToRgb = [
  3.2404542, -0.9692660, 0.0556434, //
  -1.5371385, 1.8760108, -0.2040259, //
  -0.4985314, 0.0415560, 1.0572252, //
];

List<double> _xyzToRgbVec(double x, double y, double z) => [
      _xyzToRgb[0] * x + _xyzToRgb[3] * y + _xyzToRgb[6] * z,
      _xyzToRgb[1] * x + _xyzToRgb[4] * y + _xyzToRgb[7] * z,
      _xyzToRgb[2] * x + _xyzToRgb[5] * y + _xyzToRgb[8] * z,
    ];

double _f2(double t) {
  const d = 6 / 29;
  return t > d ? t * t * t : 3 * d * d * (t - 4 / 29);
}

List<double> _labToRgb(List<double> lab) {
  final fy = (lab[0] + 16) / 116;
  return _xyzToRgbVec(
    0.950489 * _f2(fy + lab[1] / 500),
    _f2(fy),
    0.825188 * _f2(fy - lab[2] / 200),
  );
}

List<double> _xyYToRgb(List<double> xyY) {
  final x = xyY[0];
  final y = xyY[1];
  final luminance = xyY[2];
  return _xyzToRgbVec(
    luminance * x / y,
    luminance,
    luminance * (1 - x - y) / y,
  );
}

List<double> _convert(OMeshColorSpace space, Color color) {
  final output = Float32List(4);
  space.writeShaderColor(color, output, 0);
  return output;
}

void main() {
  group('OMeshShaderColorSpace.writeShaderColor', () {
    test('writes premultiplied rgb for linear', () {
      final result = _convert(
        OMeshColorSpace.linear,
        const Color.from(alpha: 0.5, red: 1, green: 0.5, blue: 0.25),
      );
      expect(result, [0.5, 0.25, 0.125, 0.5]);
    });

    test('writes CIELAB lightness for lab', () {
      final white = _convert(OMeshColorSpace.lab, const Color(0xFFFFFFFF));
      expect(white[0], closeTo(100, 1e-3));
      expect(white[3], 1);

      final red = _convert(OMeshColorSpace.lab, const Color(0xFFFF0000));
      expect(red[0], closeTo(53.24, 1e-2));
    });

    test('writes xyY for xyY', () {
      final white = _convert(OMeshColorSpace.xyY, const Color(0xFFFFFFFF));
      expect(white[0], closeTo(0.3127, 1e-3));
      expect(white[1], closeTo(0.3290, 1e-3));
      expect(white[2], closeTo(1, 1e-3));
    });

    test('gives black a white chromaticity in xyY instead of NaN', () {
      for (final color in const [Color(0xFF000000), Color(0x00000000)]) {
        final result = _convert(OMeshColorSpace.xyY, color);
        expect(result.any((v) => v.isNaN), isFalse);
        expect(result[0], closeTo(0.3127, 1e-6));
        expect(result[1], closeTo(0.3290, 1e-6));
        expect(result[2], 0);
      }
    });

    test('round-trips through the shader conversion back to rgb', () {
      final random = math.Random(1);
      for (var i = 0; i < 1000; i++) {
        final color = Color.from(
          alpha: random.nextDouble(),
          red: random.nextDouble(),
          green: random.nextDouble(),
          blue: random.nextDouble(),
        );
        final expected = [
          color.r * color.a,
          color.g * color.a,
          color.b * color.a,
        ];

        final lab = _convert(OMeshColorSpace.lab, color);
        final fromLab = _labToRgb(lab);
        final xyY = _convert(OMeshColorSpace.xyY, color);
        final fromXyY = _xyYToRgb(xyY);
        for (var c = 0; c < 3; c++) {
          expect(fromLab[c], closeTo(expected[c], 1e-4));
          expect(fromXyY[c], closeTo(expected[c], 1e-4));
        }
        expect(lab[3], closeTo(color.a, 1e-6));
      }
    });
  });
}
