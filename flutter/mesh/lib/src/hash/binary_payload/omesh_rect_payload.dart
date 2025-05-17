import 'dart:ui';

import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, PayloadType;
import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/color_payload.dart';
import 'package:mesh/src/hash/binary_payload/overtex_payload.dart';

/// {@template omesh_rect_payload_type}
/// A [PayloadType] for [OMeshRect].
/// {@endtemplate}
class OMeshRectPayloadType extends PayloadType<OMeshRect> {
  const OMeshRectPayloadType._();

  /// {@macro omesh_rect_payload_type}
  static const OMeshRectPayloadType instance = OMeshRectPayloadType._();

  @override
  OMeshRect get(ByteReader reader, [Endian? endian]) {
    final widthHeight = reader.uint8();
    final width = widthHeight >> 4;
    final height = widthHeight & 0xF;

    final verticesLength = width * height;
    final vertices = List<OVertex>.generate(
      verticesLength,
      (index) => OVertexPayloadType.instance.get(reader, endian),
    );
    final colors = ColorDictPayloadType(verticesLength).get(reader, endian);
    final metadata = _OMeshRectMetadataPayloadType.instance.get(reader, endian);

    return OMeshRect(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      colorSpace: metadata.colorSpace,
      smoothColors: metadata.smoothColors,
      fallbackColor: metadata.fallbackColor,
      backgroundColor: metadata.backgroundColor,
    );
  }

  @override
  void set(ByteWriter writer, OMeshRect value, [Endian? endian]) {
    final widthHeight = value.width << 4 | value.height;

    writer.uint8(widthHeight);

    for (var i = 0; i < value.vertices.length; i++) {
      OVertexPayloadType.instance.set(writer, value.vertices[i], endian);
    }

    ColorDictPayloadType(value.width * value.height)
        .set(writer, value.colors, endian);

    _OMeshRectMetadataPayloadType.instance.set(
      writer,
      (
        colorSpace: value.colorSpace,
        smoothColors: value.smoothColors,
        fallbackColor: value.fallbackColor,
        backgroundColor: value.backgroundColor,
      ),
      endian,
    );
  }
}

typedef _OMeshRectMetadata = ({
  OMeshColorSpace colorSpace,
  bool smoothColors,
  Color? fallbackColor,
  Color? backgroundColor,
});

class _OMeshRectMetadataPayloadType extends PayloadType<_OMeshRectMetadata> {
  const _OMeshRectMetadataPayloadType._();

  static const _OMeshRectMetadataPayloadType instance =
      _OMeshRectMetadataPayloadType._();

  @override
  _OMeshRectMetadata get(ByteReader reader, [Endian? endian]) {
    // first 3 bits: color space
    // next bit: smooth colors boolean
    // next bit: presence of fallback color
    // next bit: presence of background color
    final metadata = reader.uint8();

    final colorSpaceIndex = metadata >> 5; // first 3 bits (highest bits)
    final colorSpace = OMeshColorSpace.values[colorSpaceIndex];
    final smoothColors = ((metadata >> 4) & 0x1) == 1; // fourth bit
    final isThereFallbackColor = ((metadata >> 3) & 0x1) == 1; // fifth bit
    final isThereBackgroundColor =
        ((metadata >> 2) & 0x1) == 1; // sixth bit

    final fallbackColor = isThereFallbackColor
        ? ColorPayloadType.instance.get(reader, endian)
        : null;

    final backgroundColor = isThereBackgroundColor
        ? ColorPayloadType.instance.get(reader, endian)
        : null;

    return (
      colorSpace: colorSpace,
      smoothColors: smoothColors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
    );
  }

  @override
  void set(ByteWriter writer, _OMeshRectMetadata value, [Endian? endian]) {
    // first 3 bits: color space
    // next bit: smooth colors boolean
    // next bit: presence of fallback color
    // next bit: presence of background color

    final commbinedValues = value.colorSpace.index << 5 |
        (value.smoothColors ? 1 : 0) << 4 |
        (value.fallbackColor != null ? 1 : 0) << 3 |
        (value.backgroundColor != null ? 1 : 0) << 2;
    writer.uint8(commbinedValues);

    if (value.fallbackColor != null) {
      ColorPayloadType.instance.set(writer, value.fallbackColor!, endian);
    }

    if (value.backgroundColor != null) {
      ColorPayloadType.instance.set(writer, value.backgroundColor!, endian);
    }
  }
}
