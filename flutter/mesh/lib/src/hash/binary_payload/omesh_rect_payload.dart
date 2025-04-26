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
    // first 7 bits: color space
    // next bit: smooth colors boolean
    final colorSpaceAndSmoothColors = reader.uint8();

    final colorSpace = OMeshColorSpace.values[colorSpaceAndSmoothColors >> 1];
    final smoothColors = colorSpaceAndSmoothColors & 0x1 != 0;

    // first bit: presence of fallback color
    // second bit: presence of background color
    final otherInfo = reader.uint8();

    final isThereFallbackColor = otherInfo & 0x1 != 0;
    final isThereBackgroundColor = otherInfo & 0x2 != 0;

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
    // first 7 bits: color space
    // next bit: smooth colors boolean
    writer.uint8(
      value.colorSpace.index << 1 | (value.smoothColors ? 1 : 0),
    );

    // first bit: presence of fallback color
    // second bit: presence of background color
    final otherInfo = (value.fallbackColor != null ? 0x1 : 0) |
        (value.backgroundColor != null ? 0x2 : 0);

    writer.uint8(otherInfo);

    if (value.fallbackColor != null) {
      ColorPayloadType.instance.set(writer, value.fallbackColor!, endian);
    }

    if (value.backgroundColor != null) {
      ColorPayloadType.instance.set(writer, value.backgroundColor!, endian);
    }
  }
}
