// ignore_for_file: implementation_imports, public_member_api_docs

import 'dart:typed_data';
import 'package:archive/src/zlib/_zlib_decoder_js.dart' as archive;
import 'package:archive/src/zlib_encoder.dart' as archive;

List<int> zlibCompress(Uint8List data) {
  return const archive.ZLibEncoder().encode(data);
}

List<int> zlibDecompress(Uint8List data) {
  return archive.platformZLibDecoder.decodeBytes(data);
}
