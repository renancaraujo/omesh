import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:mesh/mesh.dart';

/// D65 white point, the chromaticity given to colors with no luminance.
const double _whiteX = 0.3127;
const double _whiteY = 0.3290;

/// Converts colors to the color space the mesh shader interpolates in.
extension OMeshShaderColorSpace on OMeshColorSpace {
  /// Writes [color], premultiplied and converted to this color space, into
  /// [output] at [offset] as four floats.
  void writeShaderColor(Color color, Float32List output, int offset) {
    final alpha = color.a;
    final r = color.r * alpha;
    final g = color.g * alpha;
    final b = color.b * alpha;

    switch (this) {
      case OMeshColorSpace.linear:
        output
          ..[offset] = r
          ..[offset + 1] = g
          ..[offset + 2] = b;
      case OMeshColorSpace.lab:
        final (x, y, z) = _rgbToXyz(r, g, b);
        final fx = _labF(x / 0.950489);
        final fy = _labF(y);
        final fz = _labF(z / 0.825188);
        output
          ..[offset] = 116 * fy - 16
          ..[offset + 1] = 500 * (fx - fy)
          ..[offset + 2] = 200 * (fy - fz);
      case OMeshColorSpace.xyY:
        final (x, y, z) = _rgbToXyz(r, g, b);
        final sum = x + y + z;
        output
          ..[offset] = sum == 0 ? _whiteX : x / sum
          ..[offset + 1] = sum == 0 ? _whiteY : y / sum
          ..[offset + 2] = y;
    }
    output[offset + 3] = alpha;
  }
}

(double, double, double) _rgbToXyz(double r, double g, double b) {
  return (
    0.4124564 * r + 0.3575761 * g + 0.1804375 * b,
    0.2126729 * r + 0.7151522 * g + 0.0721750 * b,
    0.0193339 * r + 0.1191920 * g + 0.9503041 * b,
  );
}

const double _labD = 6 / 29;

double _labF(double t) {
  if (t > _labD * _labD * _labD) {
    return math.pow(t, 1 / 3).toDouble();
  }
  return t / (3 * _labD * _labD) + 4 / 29;
}
