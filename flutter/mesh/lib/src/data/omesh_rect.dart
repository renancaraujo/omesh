import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mesh/mesh.dart';

/// The maximum amount of vertices allowed along
/// width or height in a [OMeshRect].
///
/// This exists to prevent excessive memory usage.
const int kMaxOMeshRectDimension = 40;

/// A Two Dimensional free-form rectangular mesh gradient defintion.
///
/// It is defined by a grid of vertices.
///
/// Vertices are defined by a normalized position in the range
/// of 0.0 to 1.0, being the origin (position x=0.0, y=0.0) the top-left
/// corner of the painted area and the bottom-right corner
/// (position x=1.0, y=1.0). See the property [vertices] for more.
///
/// Vertices can be colored by assigning a color to each vertex.
/// See the property [colors] for more.
@immutable
class OMeshRect {
  /// Creates a new [OMeshRect].
  const OMeshRect({
    required int width,
    required int height,
    required List<OVertex> vertices,
    required List<Color?> colors,
    Color? fallbackColor,
    Color? backgroundColor,
    OMeshColorSpace? colorSpace,
    bool? smoothColors = true,
  }) : this._(
          width: width,
          height: height,
          vertices: vertices,
          colors: colors,
          fallbackColor: fallbackColor,
          backgroundColor: backgroundColor,
          colorSpace: colorSpace ?? OMeshColorSpace.lab,
          smoothColors: smoothColors ?? true,
        );

  const OMeshRect._({
    required this.width,
    required this.height,
    required this.vertices,
    required this.colors,
    required this.fallbackColor,
    required this.backgroundColor,
    required this.colorSpace,
    required this.smoothColors,
  })  : assert(
          width > 1 && height > 1,
          'A mesh needs at least 2 vertices in each dimension.',
        ),
        assert(
          width <= kMaxOMeshRectDimension && height <= kMaxOMeshRectDimension,
          'Keep a reasonable amount of vertices,'
          ' max is $kMaxOMeshRectDimension',
        ),
        assert(
          vertices.length >= width * height,
          'vertices must contain width * height'
          ' ($width * $height = ${width * height})'
          ' amount of elements',
        ),
        assert(
          colors.length >= width * height,
          'colors must contain width * height'
          ' ($width * $height = ${width * height})'
          ' amount of elements, use null to omit a vertex color',
        );

  /// Linearly interpolates between two [OMeshRect]s.
  factory OMeshRect.lerp(OMeshRect a, OMeshRect b, double t) {
    if (t <= 0.0) {
      return a;
    }

    if (t >= 1.0) {
      return b;
    }

    if (a.width != b.width || a.height != b.height) {
      return b;
    }

    return OMeshRect._(
      width: b.width,
      height: b.height,
      fallbackColor: Color.lerp(
        a.fallbackColor,
        b.fallbackColor,
        t,
      ),
      backgroundColor: Color.lerp(
        a.backgroundColor,
        b.backgroundColor,
        t,
      ),
      colorSpace: b.colorSpace,
      smoothColors: b.smoothColors,
      vertices: [
        for (int i = 0; i < b.vertices.length; i++)
          a.vertices[i].lerpTo(b.vertices[i], t),
      ],
      colors: [
        for (int i = 0; i < b.colors.length; i++)
          Color.lerp(a.colors[i], b.colors[i], t),
      ],
    );
  }

  /// The width of the mesh in number of vertices.
  ///
  /// Must be greater than 1 and less than or equal to [kMaxOMeshRectDimension].
  final int width;

  /// The height of the mesh in number of vertices.
  ///
  /// Must be greater than 1 and less than or equal to [kMaxOMeshRectDimension].
  final int height;

  /// The color to use when a corner vertex (a vertex that sits on the edge of
  /// the mesh) does not have a color assigned.
  ///
  /// Defaults to black transparent.
  final Color? fallbackColor;

  /// The color to use as background of the painted area.
  ///
  /// This will be visible if any of the vertices has a color with
  /// any transparency of if the painted are is not fully covered
  /// by the mesh.
  ///
  /// If ommited, the background will be transparent.
  final Color? backgroundColor;

  /// The list of the positions of each vertex in the mesh.
  ///
  /// It should contain exactly [width] * [height] vertices.
  ///
  /// Vertices are defined by a normalized position in the range
  /// of 0.0 to 1.0, being the origin (position x=0.0, y=0.0) the top-left
  /// corner of the painted area and the bottom-right corner position x=1.0
  /// and y=1.0.
  ///
  /// Vertices positions are interpreted as following a logical grid
  /// order, where the first vertex is the top-left corner, folloed by the
  /// vertices in ordered by row and the last vertex is the
  /// bottom-right corner.
  ///
  /// For example, a 3x3 mesh would have the following vertex positions:
  ///
  /// ```dart
  /// vertices: [
  ///   (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // top row
  ///   (0.0, 0.5).v, (0.5, 0.5).v, (1.0, 0.5).v, // middle row
  ///   (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // bottom row
  /// ];
  /// ```
  ///
  /// The vertex positions can be modified by using the [setVertices] method.
  final List<OVertex> vertices;

  /// The color assigned to each vertex in the mesh.
  ///
  /// Unlike [vertices], this list can contain null values, which means
  /// that the color will be interpolated from the corners of the mesh.
  ///
  /// If the ommitted color is on a corner, the color will fallback to the
  /// [fallbackColor].
  final List<Color?> colors;

  /// The color space used to interpolate colors.
  ///
  /// Defaults to [OMeshColorSpace.lab].
  final OMeshColorSpace colorSpace;

  /// Whether to interpolate colors smoothly. If false, colors will be
  /// interpolated in a linear fashion from the lines of the mesh.
  final bool smoothColors;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OMeshRect &&
        other.width == width &&
        other.height == height &&
        other.fallbackColor == fallbackColor &&
        other.backgroundColor == backgroundColor &&
        listEquals(other.vertices, vertices) &&
        listEquals(other.colors, colors) &&
        other.colorSpace == colorSpace &&
        other.smoothColors == smoothColors;
  }

  @override
  int get hashCode {
    return width.hashCode ^
        height.hashCode ^
        fallbackColor.hashCode ^
        backgroundColor.hashCode ^
        vertices.hashCode ^
        colors.hashCode ^
        colorSpace.hashCode ^
        smoothColors.hashCode;
  }

  @override
  String toString() {
    return 'OMeshRect('
        'width: $width, '
        'height: $height, '
        'fallbackColor: $fallbackColor, '
        'backgroundColor: $backgroundColor, '
        'vertices: $vertices, '
        'colors: $colors, '
        'colorSpace: $colorSpace, '
        'smoothColors: $smoothColors'
        ')';
  }

  /// Returns a new [OMeshRect] with the given [vertices].
  OMeshRect setVertices(List<OVertex> vertices) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Returns a new [OMeshRect] with the given [vertex] at the given [onIndex].
  OMeshRect setVertex(OVertex vertex, {required int onIndex}) {
    return setVertices(
      List<OVertex>.generate(
        width * height,
        (index) => index == onIndex ? vertex : vertices[index],
      ),
    );
  }

  /// Returns a new [OMeshRect] with the given [fallbackColor].
  OMeshRect setFallbackColor(Color fallbackColor) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Returns a new [OMeshRect] with the given [backgroundColor].
  OMeshRect setBackgroundColor(Color? backgroundColor) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Returns a new [OMeshRect] with the given [colors].
  OMeshRect setColors(List<Color?> colors) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Returns a new [OMeshRect] with the given [color] at the given [onIndex].
  OMeshRect setColor(Color? color, {required int onIndex}) {
    return setColors(
      List<Color?>.generate(
        width * height,
        (index) => index == onIndex ? color : colors[index],
      ),
    );
  }

  /// Returns a new [OMeshRect] with the given [colorSpace].
  OMeshRect setColorSpace(OMeshColorSpace colorSpace) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Returns a new [OMeshRect] with the given [smoothColors].
  OMeshRect setSmoothColors(bool smoothColors) {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }

  /// Creates a copy of this [OMeshRect].
  OMeshRect clone() {
    return OMeshRect._(
      width: width,
      height: height,
      vertices: vertices.toList(),
      colors: colors.toList(),
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
      colorSpace: colorSpace,
      smoothColors: smoothColors,
    );
  }
}

/// A [Tween] that interpolates between two [OMeshRect].
///
/// Useful for animations, it is great to smoothly transition between
/// two [OMeshRect]s.
///
/// See also:
/// * [OMeshRect], a class that describes a mesh of vertices with colors.
/// * [AnimationController], Flutter's go to class to control animations.
/// * [Tween], for more details on how to use tweens.
class OMeshRectTween extends Tween<OMeshRect> {
  /// Creates a new [OMeshRectTween].
  OMeshRectTween({
    required OMeshRect super.begin,
    required OMeshRect super.end,
  });

  @override
  OMeshRect lerp(double t) => OMeshRect.lerp(begin!, end!, t);
}
