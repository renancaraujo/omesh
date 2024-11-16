import 'dart:convert';

import 'package:binarize/binarize.dart'
    show ByteData, PayloadType, binarize;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_payload.dart';

typedef OMeshBinaryFormat = ({
  int specVersion,
  OMeshRect mesh,
});

class OMeshBinaryFormatPayloadType extends PayloadType<OMeshBinaryFormat> {
  const OMeshBinaryFormatPayloadType._();

  static const OMeshBinaryFormatPayloadType instance =
      OMeshBinaryFormatPayloadType._();

  @override
  OMeshBinaryFormat get(ByteData data, int offset) {
    final o = ByteOffset(offset);

    final specVersion = data.getUint8(o.displace(1));

    final mesh = OMeshRectPayloadType.instance.get(data, o);
    return (
      specVersion: specVersion,
      mesh: mesh,
    );
  }

  @override
  int length(OMeshBinaryFormat value) {
    const metadataLength = 1;
    final meshLength = OMeshRectPayloadType.instance.length(value.mesh);
    return metadataLength + meshLength;
  }

  @override
  void set(OMeshBinaryFormat value, ByteData data, int offset) {
    final o = ByteOffset(offset);
    data.setUint8(o.displace(1), value.specVersion);
    OMeshRectPayloadType.instance.set(value.mesh, data, o);
  }
}
