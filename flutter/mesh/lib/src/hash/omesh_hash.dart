import 'dart:convert';
import 'dart:typed_data';

import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/compression/zlib/zlib.dart' as zlib;
import 'package:mesh/src/hash/omesh_codec.dart';

String getHashFromMesh(List<OMeshRect> mesh) {
  final bytes = OMeshBinaryFormatCodec.v1.encoder.convert(mesh);
  final compressed = zlib.zlibCompress(Uint8List.fromList(bytes));
  final hash = base64Url.encode(compressed);
  return hash;
}

List<OMeshRect> getMeshFromHash(String hash) {
  final compressed = base64Url.decode(hash);
  final bytes = zlib.zlibDecompress(compressed);
  final layers = OMeshBinaryFormatCodec.v1.decoder.convert(
    Uint8List.fromList(bytes),
  );
  return layers;
}
