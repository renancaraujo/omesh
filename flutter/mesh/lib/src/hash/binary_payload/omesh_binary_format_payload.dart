import 'dart:convert';

import 'package:binarize/binarize.dart'
    show ByteData, Bytes, Payload, PayloadType, binarize, uint8;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_payload.dart';

typedef OMeshBinaryFormat = ({
  int specVersion,
  int layerCount,
  List<(MeshType, OMeshRect)> layers,
});

class OMeshBinaryFormatPayloadType extends PayloadType<OMeshBinaryFormat> {
  const OMeshBinaryFormatPayloadType._();

  static const OMeshBinaryFormatPayloadType instance =
      OMeshBinaryFormatPayloadType._();

  @override
  OMeshBinaryFormat get(ByteData data, int offset) {
    final o = ByteOffset(offset);

    final value = data.getUint8(o.displace(1));

    /// first 3 bits are reserved for the spec version.
    /// next 3 bits are reserved for the layer count.
    final specVersion = value >> 5;
    final layerCount = (value >> 2) & 0x7;

    final layers = List.generate(
      layerCount,
      (_) => _LayerInfoPayloadType.instance.get(data, o),
    );

    return (
      specVersion: specVersion,
      layerCount: layerCount,
      layers: layers,
    );
  }



  @override
  int length(OMeshBinaryFormat value) {
    const metadataLength = 1;
    final layersLength = value.layers.fold<int>(
      0,
      (previousValue, element) =>
          previousValue + _LayerInfoPayloadType.instance.length(element),
    );

    return metadataLength + layersLength;
  }

  @override
  void set(OMeshBinaryFormat value, ByteData data, int offset) {
    final o = ByteOffset(offset);

    /// first 3 bits are reserved for the spec version.
    /// next 3 bits are reserved for the layer count.
    var v = value.specVersion << 5;
    v |= value.layerCount << 2;

    data.setUint8(o.displace(1), v);

    for (var i = 0; i < value.layers.length; i++) {
      _LayerInfoPayloadType.instance.set(value.layers[i], data, o);
    }
  }
}

enum MeshType {
  rect,
}

class _LayerInfoPayloadType extends OMeshPayloadType<(MeshType, OMeshRect)> {
  const _LayerInfoPayloadType._();

  static const _LayerInfoPayloadType instance = _LayerInfoPayloadType._();

  @override
  (MeshType, OMeshRect) get(ByteData data, ByteOffset o) {
    final typeInfo = data.getUint8(o.displace(1));
    final type = MeshType.values[typeInfo];

    final mesh = type == MeshType.rect
        ? OMeshRectPayloadType.instance.get(data, o)
        : throw UnimplementedError();

    return (type, mesh);
  }

  @override
  int length((MeshType, OMeshRect) value) {
    const typeLength = 1;
    final meshLength = OMeshRectPayloadType.instance.length(value.$2);
    return typeLength + meshLength;
  }

  @override
  void set((MeshType, OMeshRect) value, ByteData data, ByteOffset o) {
    data.setUint8(o.displace(1), value.$1.index);
    // ignore: unnecessary_type_check
    if (value.$2 is OMeshRect) {
      OMeshRectPayloadType.instance.set(value.$2, data, o);
    } else {
      throw UnimplementedError();
    }
  }
}
