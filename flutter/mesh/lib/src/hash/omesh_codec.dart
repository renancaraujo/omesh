import 'dart:convert';

import 'package:binarize/binarize.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show MeshType, OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

export 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show MeshType, OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

class OMeshBinaryFormatCodec extends Codec<List<OMeshRect>, Uint8List> {
  const OMeshBinaryFormatCodec._({
    required this.specVersion,
  });

  static const v1 = OMeshBinaryFormatCodec._(
    specVersion: 1,
  );

  final int specVersion;

  @override
  Converter<Uint8List, List<OMeshRect>> get decoder =>
      _OMeshBinaryFormatDecoder();

  @override
  Converter<List<OMeshRect>, Uint8List> get encoder =>
      _OMeshBinaryFormatEncoder(
        specVersion: specVersion,
      );
}

class _OMeshBinaryFormatDecoder extends Converter<Uint8List, List<OMeshRect>> {
  @override
  List<OMeshRect> convert(Uint8List input) {
    final reader = Payload.read(input);
    final format = reader.get(OMeshBinaryFormatPayloadType.instance);
    return format.layers.map((e) => e.$2).toList();
  }
}

class _OMeshBinaryFormatEncoder extends Converter<List<OMeshRect>, Uint8List> {
  _OMeshBinaryFormatEncoder({
    required this.specVersion,
  });

  final int specVersion;

  @override
  Uint8List convert(List<OMeshRect> input) {
    final format = (
      specVersion: specVersion,
      layerCount: input.length,
      layers: input.map((e) => (MeshType.rect, e)).toList(),
    );

    final writer = Payload.write()
      ..set<OMeshBinaryFormat>(OMeshBinaryFormatPayloadType.instance, format);

    return binarize(writer);
  }
}
