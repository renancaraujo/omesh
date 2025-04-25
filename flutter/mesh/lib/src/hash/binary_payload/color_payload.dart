import 'package:binarize/binarize.dart';
import 'package:flutter/services.dart';

class ColorListPayloadType extends PayloadType<List<Color?>> {
  const ColorListPayloadType(this.colorSlots);

  final int colorSlots;

  @override
  List<Color?> get(ByteReader reader, [Endian? endian]) {
    final colorDictLength = reader.uint8();
    final colorDict = <Color?>[null];
    for (var i = 0; i < colorDictLength; i++) {
      final color = ColorPayloadType.instance.get(reader, endian);
      colorDict.add(color);
    }

    final colors = List<Color?>.filled(colorSlots, null);
    for (var i = 0; i < colorSlots; i++) {
      final colorIndex = reader.uint8();
      colors[i] = colorDict[colorIndex];
    }

    return colors;
  }

  @override
  void set(ByteWriter writer, List<Color?> value, [Endian? endian]) {
    assert(value.length <= colorSlots, 'do not exceed color slots');

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
    for (var i = 0; i < colorSlots; i++) {
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

class ColorPayloadType extends PayloadType<Color> {
  const ColorPayloadType._();

  static const ColorPayloadType instance = ColorPayloadType._();

  @override
  Color get(ByteReader reader, [Endian? endian]) {
    // safeguard to save color meta information.
    // first 3 bits: color space
    final colorHeader = reader.uint8();
    // we read it but we are not prepared to use it yet.
    final colorSpace = colorHeader & 0x07;

    if (colorSpace != 0) {
      throw UnimplementedError('only srgb is supported for now');
    }

    return _SRGBColorPayloadType.instance.get(reader, endian);
  }

  @override
  void set(ByteWriter writer, Color value, [Endian? endian]) {
    // only support srgb for now
    const colorSpace = 0;
    const colorHeader = colorSpace;

    writer.uint8(colorHeader);

    _SRGBColorPayloadType.instance.set(writer, value, endian);
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
      ..uint8(value.red)
      ..uint8(value.green)
      ..uint8(value.blue)
      ..uint8(value.alpha);
  }
}

extension on List<Color?> {
  Iterable<Color> whereNotNull() sync* {
    for (final element in this) {
      if (element != null) yield element;
    }
  }
}
