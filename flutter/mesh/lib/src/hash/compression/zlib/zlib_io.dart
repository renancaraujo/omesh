import 'dart:io';
import 'dart:typed_data';

/// Compresses the given [data] using zlib compression.
List<int> zlibCompress(Uint8List data) {
  return zlib.encode(data);
}

/// Decompresses the given [data] using zlib decompression.
List<int> zlibDecompress(Uint8List data) {
  return zlib.decode(data);
}
