import 'dart:convert';
import 'dart:typed_data';

import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/compression/zlib/zlib.dart' as zlib;
import 'package:mesh/src/hash/omesh_codec.dart';

const _kPrefix = 'OM:';

/// A function that encodes a mesh gradient into a hash string.
///
/// Useful for sharing mesh gradients between different platforms, appllications
/// and contexts without the need to share the entire mesh data explcitly.
///
/// The hash is a base64 encoded string that contains the compressed binary
/// representation of the mesh gradient. The hash is prefixed with `OM:` to
/// indicate that it is an O'Mesh hash.
///
/// The hash is generated by first encoding the mesh gradient into a binary
/// format using the [OMeshBinaryFormatCodec], then compressing the binary
/// data using zlib compression, and finally encoding the compressed data
/// into a unpadded base64 string.
String getHashFromMesh(OMeshRect mesh) {
  final bytes = OMeshBinaryFormatCodec.v1.encoder.convert(mesh);
  final compressed = zlib.zlibCompress(Uint8List.fromList(bytes));
  final hash = base64Url.encode(compressed);
  final unpaded = _removePadding(hash);
  final prefixed = '$_kPrefix$unpaded';
  return prefixed;
}

/// A function that decodes a hash string generated by [getHashFromMesh]
/// back into a mesh gradient.
///
/// The hash is a base64 encoded string that contains the compressed binary
/// representation of the mesh gradient. The hash is prefixed with `OM:` to
/// indicate that it is an O'Mesh hash.
///
/// The hash is decoded by first removing the prefix, then adding padding
/// to the base64 string, then decoding the base64 string into a compressed
/// binary representation, and finally decompressing the binary data using
/// zlib decompression.
///
/// The hash is generated by first encoding the mesh gradient into a binary
/// format using the [OMeshBinaryFormatCodec], then compressing the binary
/// data using zlib compression, and finally encoding the compressed data
/// into a unpadded base64 string.
OMeshRect getMeshFromHash(String hash) {
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
  final paddingNeeded = (4 - base64String.length % 4) % 4;
  return base64String + ('=' * paddingNeeded);
}
