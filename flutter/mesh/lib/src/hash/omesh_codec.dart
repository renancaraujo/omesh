import 'dart:convert';

import 'package:binarize/binarize.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

export 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

class OMeshBinaryFormatCodec extends Codec<OMeshRect, Uint8List> {
  const OMeshBinaryFormatCodec._({
    required this.specVersion,
  });

  static const v1 = OMeshBinaryFormatCodec._(
    specVersion: 1,
  );

  final int specVersion;

  @override
  Converter<Uint8List, OMeshRect> get decoder =>
      _OMeshBinaryFormatDecoder();

  @override
  Converter<OMeshRect, Uint8List> get encoder =>
      _OMeshBinaryFormatEncoder(
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
