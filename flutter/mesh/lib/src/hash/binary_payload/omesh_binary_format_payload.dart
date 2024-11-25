import 'package:binarize/binarize.dart' show ByteData, PayloadType;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_payload.dart';

/// The whole information contained on a omesh binary file
typedef OMeshBinaryFormat = ({
  int specVersion,
  OMeshRect mesh,
});

/// A [PayloadType] for [OMeshBinaryFormat]
class OMeshBinaryFormatPayloadType extends PayloadType<OMeshBinaryFormat> {
  const OMeshBinaryFormatPayloadType._();

  /// The singleton instance
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