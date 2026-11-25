import 'package:binarize/binarize.dart' show ByteReader, ByteWriter;

/// Powers of ten used by the decimal number encoding, indexed by the amount
/// of fractional digits.
const List<int> kPow10 = <int>[
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
  1000000000,
];

/// The maximum amount of fractional digits supported by the decimal number
/// encoding.
const int kMaxDecimalDigits = 9;

/// Scaled integers are kept within 2^50 so that deltas between them, once
/// zigzag encoded, stay below 2^53 and are exact on the web as well.
const int _kMaxScaledMagnitude = 1125899906842624;

/// The maximum amount of bytes a varint may take (7 bits each, 56 bits).
const int _kMaxVarintBytes = 8;

/// The exclusive upper bound of a varint, 2^53. Integers below it are exact
/// on every platform.
const int _kVarintLimit = 9007199254740992;

/// Whether [value] can be scaled by 10^[digits] and still be represented as
/// an integer that is safe on every platform.
bool fitsDecimal(double value, int digits) =>
    value.isFinite && (value * kPow10[digits]).abs() <= _kMaxScaledMagnitude;

/// Whether [value] is exactly `n / 10^digits` for some integer `n`, that is,
/// whether encoding it with [digits] fractional digits is lossless.
///
/// This is bit-exact: decoding computes `n / 10^digits`, which is the very
/// expression compared here.
bool isExactDecimal(double value, int digits) =>
    fitsDecimal(value, digits) &&
    toScaledInt(value, digits) / kPow10[digits] == value;

/// Scales [value] by 10^[digits] and rounds it to the nearest integer.
int toScaledInt(double value, int digits) => (value * kPow10[digits]).round();

/// Inverse of [toScaledInt].
double fromScaledInt(int value, int digits) => value / kPow10[digits];

/// Variable length integer helpers for [ByteWriter].
///
/// Uses arithmetic instead of bitwise operators on the value so that numbers
/// above 32 bits are handled correctly on the web.
extension VarintWriter on ByteWriter {
  /// Writes a non-negative [value] as an unsigned LEB128 varint.
  void varint(int value) {
    assert(value >= 0, 'varint must not be negative');
    var remaining = value;
    while (remaining >= 0x80) {
      uint8(remaining % 0x80 + 0x80);
      remaining = remaining ~/ 0x80;
    }
    uint8(remaining);
  }

  /// Writes a signed [value] as a zigzag encoded varint
  /// (0, -1, 1, -2, 2 => 0, 1, 2, 3, 4).
  void zigzag(int value) => varint(value >= 0 ? value * 2 : -value * 2 - 1);
}

/// Variable length integer helpers for [ByteReader].
extension VarintReader on ByteReader {
  /// Reads an unsigned LEB128 varint.
  int varint() {
    var result = 0;
    var multiplier = 1;
    for (var i = 0; i < _kMaxVarintBytes; i++) {
      final byte = uint8();
      result += (byte % 0x80) * multiplier;
      if (byte < 0x80) {
        if (result >= _kVarintLimit) {
          throw const FormatException('varint is too large');
        }
        return result;
      }
      multiplier *= 0x80;
    }
    throw const FormatException('varint is too long');
  }

  /// Reads a zigzag encoded varint.
  int zigzag() {
    final value = varint();
    return value.isEven ? value ~/ 2 : -(value + 1) ~/ 2;
  }
}
