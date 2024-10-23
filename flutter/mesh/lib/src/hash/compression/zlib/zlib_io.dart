import 'dart:io';
import 'dart:typed_data';

List<int> zlibCompress(Uint8List data) {
  return zlib.encode(data);
}

List<int> zlibDecompress(Uint8List data) {
  return zlib.decode(data);
}
