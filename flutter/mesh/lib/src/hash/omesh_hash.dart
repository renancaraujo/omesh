import 'dart:convert';
import 'dart:typed_data';

import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/compression/zlib/zlib.dart' as zlib;
import 'package:mesh/src/hash/omesh_codec.dart';

const _kPrefix = 'OM';

String getHashFromMesh(List<OMeshRect> mesh) {
  final bytes = OMeshBinaryFormatCodec.v1.encoder.convert(mesh);
  final compressed = zlib.zlibCompress(Uint8List.fromList(bytes));
  final hash = base64Url.encode(compressed);
  final unpaded =  _removePadding(hash);
  final prefixed = '$_kPrefix$unpaded';
  return prefixed;
}


List<OMeshRect> getMeshFromHash(String hash) {
  final unprefixied = hash.substring(_kPrefix.length);
  final paddedHash = _addPadding(unprefixied);
  final compressed = base64Url.decode(paddedHash);
  final bytes = zlib.zlibDecompress(compressed);
  final layers = OMeshBinaryFormatCodec.v1.decoder.convert(
    Uint8List.fromList(bytes),
  );
  return layers;
}


String _removePadding(String base64String) {
  // Remove trailing '=' characters
  return base64String.replaceAll(RegExp(r'=+$'), '');
}

String _addPadding(String base64String) {
 // Calculate the padding needed to make the length a multiple of 4
  int paddingNeeded = (4 - base64String.length % 4) % 4;
  return base64String + ('=' * paddingNeeded);
}