import 'dart:ui';

/// A color space defines how colors are interpolated in a mesh gradient.
///
/// There are several ways to generate colors that are in between two colors.
/// Each color space has its own way of doing this.
///
/// Dont confure this with the [ColorSpace] in the [Color] class which
/// defines how colors are represented in memory.
enum OMeshColorSpace {
  /// The most common way of interpolating colors, this performs linear
  /// interpolation in the RGB color space.
  linear,

  /// Interpolates colors in the CIELAB color space.
  ///
  /// This color space is designed to be perceptually uniform, meaning that
  /// the difference between two colors is proportional to the difference in
  /// their perceived brightness.
  ///
  /// https://en.wikipedia.org/wiki/CIELAB_color_space
  lab,

  /// Interpolates colors in the CIE xyY color space.
  ///
  /// This colorspace is very reliant on luminance. Interpolating to and from
  /// black causes artifacts. Try adding at least a value of 1 to any of the
  /// color channels (R, G, or B) to avoid this.
  ///
  /// https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_xy_chromaticity_diagram_and_the_CIE_xyY_color_space
  xyY
}
