import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, Endian, PayloadType;
import 'package:mesh/mesh.dart';
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
  OMeshBinaryFormat get(ByteReader reader, [Endian? endian]) {
    final specVersion = reader.uint8();

    final mesh = OMeshRectPayloadType.instance.get(reader, endian);
    return (
      specVersion: specVersion,
      mesh: mesh,
    );
  }

  @override
  void set(ByteWriter writer, OMeshBinaryFormat value, [Endian? endian]) {
    writer.uint8(value.specVersion);
    OMeshRectPayloadType.instance.set(writer, value.mesh, endian);
  }
}
