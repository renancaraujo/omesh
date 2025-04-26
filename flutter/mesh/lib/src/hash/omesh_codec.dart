import 'dart:convert';

import 'package:binarize/binarize.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

export 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

/// a [Codec] for [OMeshRect] to/from binary format.
///
/// This codec is used to encode and decode the mesh data in a binary format
/// that can be used to store the mesh data in a file or send it over the
/// network.
/// The binary format is a compact representation of the mesh data that
/// can be easily serialized and deserialized.
///
/// The binary format is defined by the [OMeshBinaryFormatPayloadType]
/// and is used to encode and decode the mesh data.
class OMeshBinaryFormatCodec extends Codec<OMeshRect, Uint8List> {
  const OMeshBinaryFormatCodec._({
    required this.specVersion,
  });

  /// The default codec for [OMeshRect] to/from binary format.
  static const v1 = OMeshBinaryFormatCodec._(
    specVersion: 1,
  );

  /// The codec for [OMeshRect] to/from binary format.
  final int specVersion;

  @override
  Converter<Uint8List, OMeshRect> get decoder => _OMeshBinaryFormatDecoder();

  @override
  Converter<OMeshRect, Uint8List> get encoder => _OMeshBinaryFormatEncoder(
        specVersion: specVersion,
      );
}

class _OMeshBinaryFormatDecoder extends Converter<Uint8List, OMeshRect> {
  @override
  OMeshRect convert(Uint8List input) {
    final reader = Payload.read(input);
    final format = reader.get(OMeshBinaryFormatPayloadType.instance);
    return format.mesh;
  }
}

class _OMeshBinaryFormatEncoder extends Converter<OMeshRect, Uint8List> {
  _OMeshBinaryFormatEncoder({
    required this.specVersion,
  });

  final int specVersion;

  @override
  Uint8List convert(OMeshRect input) {
    final format = (
      specVersion: specVersion,
      mesh: input,
    );

    final writer = Payload.write()
      ..set<OMeshBinaryFormat>(OMeshBinaryFormatPayloadType.instance, format);

    return binarize(writer);
  }
}
