import 'package:flutter/rendering.dart' show Color;
import 'package:mesh/mesh.dart';

/// Utility extension type for inferring colors from a [OMeshRect].
extension type OMeshRectColorMixer(OMeshRect mesh) {
  static Color _interpolateColors(Color a, Color b, double t) {
    if (t <= 0.0) {
      return a;
    }

    if (t >= 1.0) {
      return b;
    }

    final alpha = a.a + (b.a - a.a) * t;
    final red = a.r + (b.r - a.r) * t;
    final green = a.g + (b.g - a.g) * t;
    final blue = a.b + (b.b - a.b) * t;

    return Color.from(
      alpha: alpha,
      red: red,
      green: green,
      blue: blue,
    );
  }

  Color get _fb => mesh.fallbackColor;
  List<Color?> get _colors => mesh.colors;
  int get _w => mesh.width;
  int get _h => mesh.height;

  Color get _color00 => _colors[0] ?? _fb;
  Color get _color01 => _colors[_w - 1] ?? _fb;
  Color get _color10 => _colors[_w * (_h - 1)] ?? _fb;
  Color get _color11 => _colors[_w * _h - 1] ?? _fb;

  /// Get a tuple with the color of a vertex at [colorIndex] and a boolean
  /// indicating if the color was inferred or explicitly defined by the user.
  (Color color, bool bias) getVertexColor(int colorIndex) {
    assert(
      colorIndex >= 0 && colorIndex < _colors.length,
      'colorIndex must be within the range of vertices.length',
    );

    final definedColor = _colors[colorIndex];
    if (definedColor != null) {
      return (definedColor, mesh.smoothColors);
    }
    final row = colorIndex ~/ _w;
    final col = colorIndex % _w;
    final colorX1 = _interpolateColors(_color00, _color01, col / (_w - 1));
    final colorX2 = _interpolateColors(_color10, _color11, col / (_w - 1));
    return (_interpolateColors(colorX1, colorX2, row / (_h - 1)), false);
  }
}
