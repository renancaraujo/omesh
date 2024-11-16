import 'package:flutter/services.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';

class ColorListPayloadType extends OMeshPayloadType<List<Color?>> {
  const ColorListPayloadType(this.colorSlots);

  final int colorSlots;

  @override
  List<Color?> get(ByteData data, ByteOffset o) {
    final colorDictLength = data.getUint8(o.displace(1));
    final colorDict = <Color?>[null];
    for (var i = 0; i < colorDictLength; i++) {
      final color = ColorPayloadType.instance.get(data, o);
      colorDict.add(color);
    }

    final colors = List<Color?>.filled(colorSlots, null);
    for (var i = 0; i < colorSlots; i++) {
      final colorIndex = data.getUint8(o.displace(1));
      colors[i] = colorDict[colorIndex];
    }

    return colors;
  }

  @override
  int length(List<Color?> value) {
    assert(value.length <= colorSlots, 'do not exceed color slots');
    const colorDictLengthLength = 1;
    final differentColors = value.whereNotNull().toSet();
    final colorDictLength =
        differentColors.fold<int>(0, (previousValue, element) {
      final colorLength = ColorPayloadType.instance.length(element);
      return previousValue + colorLength;
    });
    final colorLength = colorSlots;
    return colorDictLengthLength + colorDictLength + colorLength;
  }

  @override
  void set(List<Color?> value, ByteData data, ByteOffset o) {
    assert(value.length <= colorSlots, 'do not exceed color slots');

    final differentColors = value.whereNotNull().toSet();
    data.setUint8(o.displace(1), differentColors.length);
    for (final color in differentColors) {
      ColorPayloadType.instance.set(color, data, o);
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
        data.setUint8(o.displace(1), 0);
      } else {
        final index = colorDictAsMap[color]!;
        data.setUint8(o.displace(1), index + 1);
      }
    }
  }
}

class ColorPayloadType extends OMeshPayloadType<Color> {
  const ColorPayloadType._();

  static const ColorPayloadType instance = ColorPayloadType._();


  @override
  Color get(ByteData data, ByteOffset o) {
    // safeguard to save color meta information.
    // first 3 bits: color space
    final colorHeader = data.getUint8(o.displace(1));
    // we read it but we are not prepared to use it yet.
    final colorSpace = colorHeader & 0x07;

    if(colorSpace != 0) {
      throw UnimplementedError('only srgb is supported for now');
    }

    return _SRGBColorPayloadType.instance.get(data, o);
  }


  @override
  int length(Color value) {
    const headerLength = 1;
    final colorLength = _SRGBColorPayloadType.instance.length(value);
    return headerLength + colorLength;
  }

  @override
  void set(Color value, ByteData data, ByteOffset o) {
    
    // only support srgb for now
    const colorSpace = 0;
    const colorHeader = colorSpace;

    data.setUint8(o.displace(1), colorHeader);
    _SRGBColorPayloadType.instance.set(value, data, o);
  }
}

class _SRGBColorPayloadType extends OMeshPayloadType<Color> {
  const _SRGBColorPayloadType._();

  static const _SRGBColorPayloadType instance = _SRGBColorPayloadType._();

  @override
  int length(Color value) => 4;

  @override
  Color get(ByteData data, ByteOffset o) {
    final r = data.getUint8(o.displace(1));
    final g = data.getUint8(o.displace(1));
    final b = data.getUint8(o.displace(1));
    final a = data.getUint8(o.displace(1));

    return Color.fromARGB(a, r, g, b);
  }

  @override
  void set(Color value, ByteData data, ByteOffset o) {
    data
      ..setUint8(o.displace(1), value.red)
      ..setUint8(o.displace(1), value.green)
      ..setUint8(o.displace(1), value.blue)
      ..setUint8(o.displace(1), value.alpha);
  }
}

extension on List<Color?> {
  Iterable<Color> whereNotNull() sync* {
    for (final element in this) {
      if (element != null) yield element;
    }
  }
}
