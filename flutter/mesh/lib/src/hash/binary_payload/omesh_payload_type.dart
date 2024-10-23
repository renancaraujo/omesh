import 'dart:typed_data';

import 'package:binarize/binarize.dart' as binarize;

/// Just like [binarize.PayloadType], but for nested payload types.
abstract class OMeshPayloadType<T> {
  /// Created a new [OMeshPayloadType].
  const OMeshPayloadType();

  /// see [binarize.PayloadType.get]
  T get(ByteData data, ByteOffset o);

  /// see [binarize.PayloadType.length]
  int length(T value);

  /// see [binarize.PayloadType.set]
  void set(T value, ByteData data, ByteOffset o);
}

/// A class to keep track of the current offset in a byte array.
class ByteOffset {
  /// Creates a new [ByteOffset] with the given [offset].
  ByteOffset(this._offset);
  int _offset;

  int get offset => _offset;

  /// Returns the current offset and increments the offset by [displacement].
  int displace(int displacement) {
    final o = _offset;
    _offset += displacement;
    return o;
  }
}
