import 'package:flutter/services.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';

class ColorListPayloadType extends OMeshPayloadType<List<Color?>> {
  const ColorListPayloadType(this.colorSlots);

  final int colorSlots;

  @override
  List<Color?> get(ByteData data, ByteOffset o) {
    final length = data.getUint16(o.displace(2));
    final colors = List<Color?>.filled(colorSlots, null);
    for (var i = 0; i < length; i++) {
      final (index, color) = ColorPayloadType.instance.get(data, o);
      colors[index] = color;
    }
    return colors;
  }

  @override
  int length(List<Color?> value) {
    assert(value.length <= colorSlots, 'do not exceed color slots');
    const headerLength = 2;
    final colorLength = value.whereNotNull().fold<int>(
          0,
          (previousValue, element) =>
              previousValue + ColorPayloadType.instance.length((0, element)),
        );
    return headerLength + colorLength;
  }

  @override
  void set(List<Color?> value, ByteData data, ByteOffset o) {
    assert(value.length <= colorSlots, 'do not exceed color slots');
    data.setUint16(o.displace(2), value.whereNotNull().length);
    for (var i = 0; i < value.length; i++) {
      final color = value[i];
      if (color == null) continue;
      ColorPayloadType.instance.set((i, color), data, o);
    }
  }
}

class ColorPayloadType extends OMeshPayloadType<(int, Color)> {
  const ColorPayloadType._();

  static const ColorPayloadType instance = ColorPayloadType._();

  @override
  int length((int, Color) value) {
    const headerLength = 2;
    final colorLength = _SRGBColorPayloadType.instance.length(value.$2);
    return headerLength + colorLength;
  }

  @override
  (int, Color) get(ByteData data, ByteOffset o) {
    // safeguard to save color meta information.
    // first 10 bits: color index
    // next 3 bits: color space
    final colorHeader = data.getUint16(o.displace(2));

    final index = colorHeader & 0x3FF;
    // ignore: unused_local_variable
    final colorSpace = (colorHeader >> 10) & 0x7;

    return (index, _SRGBColorPayloadType.instance.get(data, o));
  }

  @override
  void set((int, Color) value, ByteData data, ByteOffset o) {
    final index = value.$1.clamp(0, 1023);
    // only support srgb for now
    const colorsScape = 0;
    final colorHeader = (index & 0x3FF) | ((colorsScape & 0x07) << 10);

    data.setUint16(o.displace(2), colorHeader);
    _SRGBColorPayloadType.instance.set(value.$2, data, o);
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
