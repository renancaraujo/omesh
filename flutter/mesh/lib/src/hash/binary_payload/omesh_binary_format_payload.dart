import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, Endian, PayloadType;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/number_encoding.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_payload.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_v2_payload.dart';

/// The whole information contained on a omesh binary file
typedef OMeshBinaryFormat = ({
  int specVersion,
  OMeshRect mesh,
});

/// A [PayloadType] for [OMeshBinaryFormat]
///
/// Reading accepts every known spec version. Writing uses the spec version
/// of the given [OMeshBinaryFormat].
class OMeshBinaryFormatPayloadType extends PayloadType<OMeshBinaryFormat> {
  /// Creates a [PayloadType] for [OMeshBinaryFormat].
  ///
  /// [maxDecimalPlaces] only affects writing spec version 2 and above,
  /// see [OMeshRectV2PayloadType.maxDecimalPlaces]. Writing throws an
  /// [ArgumentError] when it is not between 0 and [kMaxDecimalDigits].
  const OMeshBinaryFormatPayloadType({this.maxDecimalPlaces});

  /// The singleton instance
  static const OMeshBinaryFormatPayloadType instance =
      OMeshBinaryFormatPayloadType();

  /// The maximum amount of fractional digits to keep for coordinates when
  /// writing spec version 2, or `null` to write them losslessly.
  final int? maxDecimalPlaces;

  @override
  OMeshBinaryFormat get(ByteReader reader, [Endian? endian]) {
    final specVersion = reader.uint8();

    final mesh = switch (specVersion) {
      1 => OMeshRectPayloadType.instance.get(reader, endian),
      2 => OMeshRectV2PayloadType.lossless.get(reader, endian),
      _ => throw FormatException(
          "Unsupported O'Mesh binary format version $specVersion",
        ),
    };
    return (
      specVersion: specVersion,
      mesh: mesh,
    );
  }

  @override
  void set(ByteWriter writer, OMeshBinaryFormat value, [Endian? endian]) {
    final maxDecimalPlaces = this.maxDecimalPlaces;
    if (maxDecimalPlaces != null &&
        (maxDecimalPlaces < 0 || maxDecimalPlaces > kMaxDecimalDigits)) {
      throw ArgumentError.value(
        maxDecimalPlaces,
        'maxDecimalPlaces',
        'must be between 0 and $kMaxDecimalDigits',
      );
    }

    final meshPayloadType = switch (value.specVersion) {
      1 => OMeshRectPayloadType.instance,
      2 => OMeshRectV2PayloadType(maxDecimalPlaces: maxDecimalPlaces),
      _ => throw ArgumentError.value(
          value.specVersion,
          'specVersion',
          "Unsupported O'Mesh binary format version",
        ),
    };

    writer.uint8(value.specVersion);
    meshPayloadType.set(writer, value.mesh, endian);
  }
}
