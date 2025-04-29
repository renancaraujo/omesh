// ignore_for_file: implementation_imports, public_member_api_docs

import 'dart:typed_data';
import 'package:archive/src/codecs/zlib/_zlib_decoder_web.dart' as archive;
import 'package:archive/src/codecs/zlib_encoder.dart' as archive;

List<int> zlibCompress(Uint8List data) {
  return const archive.ZLibEncoder().encode(data);
}

List<int> zlibDecompress(Uint8List data) {
  return archive.platformZLibDecoder.decodeBytes(data);
}
