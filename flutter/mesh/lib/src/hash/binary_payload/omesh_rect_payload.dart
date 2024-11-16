import 'dart:ui';

import 'package:binarize/binarize.dart' show ByteData;
import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/color_payload.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';
import 'package:mesh/src/hash/binary_payload/overtex_payload.dart';

class OMeshRectPayloadType extends OMeshPayloadType<OMeshRect> {
  const OMeshRectPayloadType._();

  static const OMeshRectPayloadType instance = OMeshRectPayloadType._();

  @override
  OMeshRect get(ByteData data, ByteOffset o) {
    final widthHeight = data.getUint8(o.displace(1));
    final width = widthHeight >> 4;
    final height = widthHeight & 0xF;

    final verticesLength = width * height;
    final vertices = List<OVertex>.generate(
      verticesLength,
      (index) => OVertexPayloadType.instance.get(data, o),
    );
    final colors = ColorListPayloadType(verticesLength).get(data, o);
    final metadata = _OMeshRectMetadataPayloadType.instance.get(data, o);

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
  int length(OMeshRect value) {
    const widthHeightLength = 1;
    final verticesLength = value.vertices.fold<int>(
      0,
      (previousValue, element) =>
          previousValue + OVertexPayloadType.instance.length(element),
    );
    final colorsLength =
        ColorListPayloadType(value.height * value.height).length(value.colors);

    final metadataLength = _OMeshRectMetadataPayloadType.instance.length(
      (
        colorSpace: value.colorSpace,
        smoothColors: value.smoothColors,
        fallbackColor: value.fallbackColor,
        backgroundColor: value.backgroundColor,
      ),
    );

    return widthHeightLength + verticesLength + colorsLength + metadataLength;
  }

  @override
  void set(OMeshRect value, ByteData data, ByteOffset o) {
    final widthHeight = value.width << 4 | value.height;
    data.setUint8(o.displace(1), widthHeight);

    for (var i = 0; i < value.vertices.length; i++) {
      OVertexPayloadType.instance.set(value.vertices[i], data, o);
    }

    ColorListPayloadType(value.width * value.height).set(value.colors, data, o);

    _OMeshRectMetadataPayloadType.instance.set(
      (
        colorSpace: value.colorSpace,
        smoothColors: value.smoothColors,
        fallbackColor: value.fallbackColor,
        backgroundColor: value.backgroundColor,
      ),
      data,
      o,
    );
  }
}

typedef _OMeshRectMetadata = ({
  OMeshColorSpace colorSpace,
  bool smoothColors,
  Color? fallbackColor,
  Color? backgroundColor,
});

class _OMeshRectMetadataPayloadType
    extends OMeshPayloadType<_OMeshRectMetadata> {
  const _OMeshRectMetadataPayloadType._();

  static const _OMeshRectMetadataPayloadType instance =
      _OMeshRectMetadataPayloadType._();

  @override
  _OMeshRectMetadata get(ByteData data, ByteOffset o) {
    // first 7 bits: color space
    // next bit: smooth colors boolean
    final colorSpaceAndSmoothColors = data.getUint8(o.displace(1));

    final colorSpace = OMeshColorSpace.values[colorSpaceAndSmoothColors >> 1];
    final smoothColors = colorSpaceAndSmoothColors & 0x1 != 0;

    // first bit: presence of fallback color
    // second bit: presence of background color
    final otherInfo = data.getUint8(o.displace(1));

    final isThereFallbackColor = otherInfo & 0x1 != 0;
    final isThereBackgroundColor = otherInfo & 0x2 != 0;

    final fallbackColor =
        isThereFallbackColor ? ColorPayloadType.instance.get(data, o) : null;

    final backgroundColor =
        isThereBackgroundColor ? ColorPayloadType.instance.get(data, o) : null;

    return (
      colorSpace: colorSpace,
      smoothColors: smoothColors,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
    );
  }

  @override
  int length(_OMeshRectMetadata value) {
    const colorSpaceAndSmoothColorsLength = 1;
    const otherInfoLength = 1;
    final fallbackColorLength = value.fallbackColor != null
        ? ColorPayloadType.instance.length(value.fallbackColor!)
        : 0;
    final backgroundColorLength = value.backgroundColor != null
        ? ColorPayloadType.instance.length(value.backgroundColor!)
        : 0;

    return colorSpaceAndSmoothColorsLength +
        otherInfoLength +
        fallbackColorLength +
        backgroundColorLength;
  }

  @override
  void set(_OMeshRectMetadata value, ByteData data, ByteOffset o) {
    // first 7 bits: color space
    // next bit: smooth colors boolean
    data.setUint8(o.displace(1),
        value.colorSpace.index << 1 | (value.smoothColors ? 1 : 0));

    // first bit: presence of fallback color
    // second bit: presence of background color
    final otherInfo = (value.fallbackColor != null ? 0x1 : 0) |
        (value.backgroundColor != null ? 0x2 : 0);
    data.setUint8(o.displace(1), otherInfo);

    if (value.fallbackColor != null) {
      ColorPayloadType.instance.set(value.fallbackColor!, data, o);
    }

    if (value.backgroundColor != null) {
      ColorPayloadType.instance.set(value.backgroundColor!, data, o);
    }
  }
}
