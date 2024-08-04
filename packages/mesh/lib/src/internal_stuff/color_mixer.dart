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

    final alpha = (a.alpha + (b.alpha - a.alpha) * t).round();
    final red = (a.red + (b.red - a.red) * t).round();
    final green = (a.green + (b.green - a.green) * t).round();
    final blue = (a.blue + (b.blue - a.blue) * t).round();

    return Color.fromARGB(alpha, red, green, blue);
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
