import 'dart:ui' show ColorSpace;

import 'package:binarize/binarize.dart';
import 'package:flutter/services.dart';

/// {@template color_dict_payload_type}
/// A [PayloadType] for a dictionary of colors.
/// {@endtemplate}
class ColorDictPayloadType extends PayloadType<List<Color?>> {
  /// {@macro color_dict_payload_type}
  const ColorDictPayloadType(this._colorSlots);

  final int _colorSlots;

  @override
  List<Color?> get(ByteReader reader, [Endian? endian]) {
    final colorDictLength = reader.uint8();
    final colorDict = <Color?>[null];
    for (var i = 0; i < colorDictLength; i++) {
      final color = ColorPayloadType.instance.get(reader, endian);
      colorDict.add(color);
    }

    final colors = List<Color?>.filled(_colorSlots, null);
    for (var i = 0; i < _colorSlots; i++) {
      final colorIndex = reader.uint8();
      colors[i] = colorDict[colorIndex];
    }

    return colors;
  }

  @override
  void set(ByteWriter writer, List<Color?> value, [Endian? endian]) {
    assert(value.length <= _colorSlots, 'do not exceed color slots');

    final differentColors = value.whereNotNull().toSet();
    writer.uint8(differentColors.length);
    for (final color in differentColors) {
      ColorPayloadType.instance.set(writer, color, endian);
    }

    final colorDictAsMap = differentColors.indexed.fold<Map<Color, int>>(
      <Color, int>{},
      (previousValue, element) {
        final (index, color) = element;
        return previousValue..[color] = index;
      },
    );
    for (var i = 0; i < _colorSlots; i++) {
      final color = value[i];
      if (color == null) {
        writer.uint8(0);
      } else {
        final index = colorDictAsMap[color]!;
        writer.uint8(index + 1);
      }
    }
  }
}

extension on int {
  ColorSpace get colorSpace {
    return switch (this) {
      0 => ColorSpace.sRGB,
      1 => ColorSpace.extendedSRGB,
      2 => ColorSpace.displayP3,
      _ =>
        throw ArgumentError.value(this, 'color space', 'invalid color space'),
    };
  }
}

extension on ColorSpace {
  int get colorSpaceValue {
    return switch (this) {
      ColorSpace.sRGB => 0,
      ColorSpace.extendedSRGB => 1,
      ColorSpace.displayP3 => 2,
    };
  }
}

/// {@template color_payload_type}
/// A [PayloadType] for a color.
/// {@endtemplate}
class ColorPayloadType extends PayloadType<Color> {
  const ColorPayloadType._();

  /// {@macro color_payload_type}
  static const ColorPayloadType instance = ColorPayloadType._();

  @override
  Color get(ByteReader reader, [Endian? endian]) {
    // safeguard to save color meta information.
    // first 3 bits: color space
    final colorHeader = reader.uint8();

    final colorSpace = (colorHeader & 0x07).colorSpace;

    return switch (colorSpace) {
      ColorSpace.sRGB => _SRGBColorPayloadType.instance.get(reader, endian),
      ColorSpace.extendedSRGB =>
        _SRGBColorPayloadType.instance.get(reader, endian),
      ColorSpace.displayP3 =>
        _DisplayP3ColorPayloadType.instance.get(reader, endian),
    };
  }

  @override
  void set(ByteWriter writer, Color value, [Endian? endian]) {
    final colorSpace = value.colorSpace.colorSpaceValue;

    final colorHeader = colorSpace;
    writer.uint8(colorHeader);

    return switch (value.colorSpace) {
      ColorSpace.sRGB =>
        _SRGBColorPayloadType.instance.set(writer, value, endian),
      ColorSpace.extendedSRGB =>
        _SRGBColorPayloadType.instance.set(writer, value, endian),
      ColorSpace.displayP3 =>
        _DisplayP3ColorPayloadType.instance.set(writer, value, endian),
    };
  }
}

class _SRGBColorPayloadType extends PayloadType<Color> {
  const _SRGBColorPayloadType._();

  static const _SRGBColorPayloadType instance = _SRGBColorPayloadType._();

  @override
  Color get(ByteReader reader, [Endian? endian]) {
    final r = reader.uint8();
    final g = reader.uint8();
    final b = reader.uint8();
    final a = reader.uint8();

    return Color.fromARGB(a, r, g, b);
  }

  @override
  void set(ByteWriter writer, Color value, [Endian? endian]) {
    writer
      ..uint8(value.r.toUint8)
      ..uint8(value.g.toUint8)
      ..uint8(value.b.toUint8)
      ..uint8(value.a.toUint8);
  }
}

class _DisplayP3ColorPayloadType extends PayloadType<Color> {
  const _DisplayP3ColorPayloadType._();

  static const _DisplayP3ColorPayloadType instance =
      _DisplayP3ColorPayloadType._();

  @override
  Color get(ByteReader reader, [Endian? endian]) {
    final r = reader.float64(endian);
    final g = reader.float64(endian);
    final b = reader.float64(endian);
    final a = reader.float64(endian);

    return Color.from(
      alpha: a,
      red: r,
      green: g,
      blue: b,
      colorSpace: ColorSpace.displayP3,
    );
  }

  @override
  void set(ByteWriter writer, Color value, [Endian? endian]) {
    writer
      ..float64(value.r, endian)
      ..float64(value.g, endian)
      ..float64(value.b, endian)
      ..float64(value.a, endian);
  }
}

extension on double {
  int get toUint8 => (this * 255).round() & 0xFF;
}

extension on List<Color?> {
  Iterable<Color> whereNotNull() sync* {
    for (final element in this) {
      if (element != null) yield element;
    }
  }
}
