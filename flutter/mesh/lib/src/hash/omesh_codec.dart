import 'dart:convert';

import 'package:binarize/binarize.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show
        MeshType,
        OMeshBinaryFormat,
        OMeshBinaryFormatPayloadType,
        kOMeshFingerprint;

export 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show
        MeshType,
        OMeshBinaryFormat,
        OMeshBinaryFormatPayloadType,
        kOMeshFingerprint;

class OMeshBinaryFormatCodec extends Codec<List<OMeshRect>, Uint8List> {
  const OMeshBinaryFormatCodec._({
    required this.fingerPrint,
    required this.specVersion,
  });

  static const v1 = OMeshBinaryFormatCodec._(
    fingerPrint: kOMeshFingerprint,
    specVersion: 1,
  );

  final String fingerPrint;
  final int specVersion;

  @override
  Converter<Uint8List, List<OMeshRect>> get decoder =>
      _OMeshBinaryFormatDecoder();

  @override
  Converter<List<OMeshRect>, Uint8List> get encoder =>
      _OMeshBinaryFormatEncoder(
        fingerPrint: fingerPrint,
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
    required this.fingerPrint,
    required this.specVersion,
  });

  final String fingerPrint;
  final int specVersion;

  @override
  Uint8List convert(List<OMeshRect> input) {
    final format = (
      fingerPrint: fingerPrint,
      specVersion: specVersion,
      layerCount: input.length,
      layers: input.map((e) => (MeshType.rect, e)).toList(),
    );

    final writer = Payload.write()
      ..set<OMeshBinaryFormat>(OMeshBinaryFormatPayloadType.instance, format);

    return binarize(writer);
  }
}
