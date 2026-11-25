import 'dart:ui' show Color, ColorSpace;

import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, Endian, PayloadType;
import 'package:mesh/src/hash/binary_payload/number_encoding.dart';

/// The bits of the color header that hold the color space.
const int _kColorSpaceMask = 0x07;

/// Components stored as `n / 255`, red, green, blue and alpha.
const int _kEncodingUint8 = 0;

/// Components stored as `n / 255`, red, green and blue. Alpha is 1.
const int _kEncodingUint8Opaque = 1;

/// Components stored as four float64 values.
const int _kEncodingFloat64 = 2;

/// Components stored as zigzag varints of `n / 10^k`, where
/// `k = encoding - _kEncodingDecimal`.
const int _kEncodingDecimal = 3;

/// The last decimal encoding, `k = kMaxDecimalDigits`.
const int _kEncodingDecimalLast = _kEncodingDecimal + kMaxDecimalDigits;

/// {@template color_v2_payload_type}
/// A [PayloadType] for a single color in the v2 binary format.
///
/// The color is always encoded losslessly: 8-bit components when they are
/// exact, short decimals when possible, and float64 otherwise. The color
/// space of the color is preserved.
/// {@endtemplate}
class ColorV2PayloadType extends PayloadType<Color> {
  const ColorV2PayloadType._();

  /// {@macro color_v2_payload_type}
  static const ColorV2PayloadType instance = ColorV2PayloadType._();

  @override
  Color get(ByteReader reader, [Endian? endian]) {
    final header = reader.uint8();
    final colorSpace = _colorSpaceFromCode(header & _kColorSpaceMask);
    final encoding = header >> 3;

    final double red;
    final double green;
    final double blue;
    final double alpha;
    switch (encoding) {
      case _kEncodingUint8:
        red = reader.uint8() / 255;
        green = reader.uint8() / 255;
        blue = reader.uint8() / 255;
        alpha = reader.uint8() / 255;
      case _kEncodingUint8Opaque:
        red = reader.uint8() / 255;
        green = reader.uint8() / 255;
        blue = reader.uint8() / 255;
        alpha = 1;
      case _kEncodingFloat64:
        red = reader.float64(endian);
        green = reader.float64(endian);
        blue = reader.float64(endian);
        alpha = reader.float64(endian);
      case >= _kEncodingDecimal && <= _kEncodingDecimalLast:
        final digits = encoding - _kEncodingDecimal;
        red = fromScaledInt(reader.zigzag(), digits);
        green = fromScaledInt(reader.zigzag(), digits);
        blue = fromScaledInt(reader.zigzag(), digits);
        alpha = fromScaledInt(reader.zigzag(), digits);
      default:
        throw FormatException('Unknown color encoding $encoding');
    }

    return Color.from(
      alpha: alpha,
      red: red,
      green: green,
      blue: blue,
      colorSpace: colorSpace,
    );
  }

  @override
  void set(ByteWriter writer, Color value, [Endian? endian]) {
    final colorSpaceCode = _colorSpaceToCode(value.colorSpace);
    final components = [value.r, value.g, value.b, value.a];

    if (components.every(_isUint8Fraction)) {
      final opaque = value.a == 1;
      writer.uint8(
        colorSpaceCode |
            (opaque ? _kEncodingUint8Opaque : _kEncodingUint8) << 3,
      );
      for (final component in opaque ? components.take(3) : components) {
        writer.uint8((component * 255).round());
      }
      return;
    }

    for (var digits = 0; digits <= kMaxDecimalDigits; digits++) {
      if (components.every((c) => isExactDecimal(c, digits))) {
        writer.uint8(colorSpaceCode | (_kEncodingDecimal + digits) << 3);
        for (final component in components) {
          writer.zigzag(toScaledInt(component, digits));
        }
        return;
      }
    }

    writer.uint8(colorSpaceCode | _kEncodingFloat64 << 3);
    for (final component in components) {
      writer.float64(component, endian);
    }
  }
}

/// Whether [value] is exactly `n / 255` with `n` in `0..255`, which is how
/// [Color] stores 8-bit sRGB components.
bool _isUint8Fraction(double value) {
  // Checked before multiplying, which overflows for very large values. Also
  // false for NaN.
  if (!(value >= 0 && value <= 1)) return false;
  return (value * 255).round() / 255 == value;
}

int _colorSpaceToCode(ColorSpace colorSpace) {
  return switch (colorSpace) {
    ColorSpace.sRGB => 0,
    ColorSpace.extendedSRGB => 1,
    ColorSpace.displayP3 => 2,
  };
}

ColorSpace _colorSpaceFromCode(int code) {
  return switch (code) {
    0 => ColorSpace.sRGB,
    1 => ColorSpace.extendedSRGB,
    2 => ColorSpace.displayP3,
    _ => throw FormatException('Unknown color space $code'),
  };
}
