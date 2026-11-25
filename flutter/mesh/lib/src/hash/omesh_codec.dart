import 'dart:convert';

import 'package:binarize/binarize.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

export 'package:mesh/src/hash/binary_payload/omesh_binary_format_payload.dart'
    show OMeshBinaryFormat, OMeshBinaryFormatPayloadType;

/// a [Codec] for [OMeshRect] to/from binary format.
///
/// This codec is used to encode and decode the mesh data in a binary format
/// that can be used to store the mesh data in a file or send it over the
/// network.
/// The binary format is a compact representation of the mesh data that
/// can be easily serialized and deserialized.
///
/// The binary format is defined by the [OMeshBinaryFormatPayloadType]
/// and is used to encode and decode the mesh data.
///
/// The codecs differ only on how they encode. Every codec decodes every
/// known spec version, so data encoded by [v1] or [v2] can be decoded by
/// either.
class OMeshBinaryFormatCodec extends Codec<OMeshRect, Uint8List> {
  const OMeshBinaryFormatCodec._({
    required this.specVersion,
  }) : maxDecimalPlaces = null;

  /// A [v2] codec that rounds coordinates to [decimalPlaces] fractional
  /// digits when they need more than that.
  ///
  /// Coordinates are relative to the size of the mesh, so with the default
  /// of 3 decimal places they snap to steps of 1/1000 of the painted area.
  /// Coordinates that already fit within [decimalPlaces] are kept exactly,
  /// and colors are always kept exactly.
  ///
  /// This is lossy: a mesh with coordinates that need more precision is not
  /// equal to itself after encoding and decoding.
  ///
  /// Encoding throws an [ArgumentError] when [decimalPlaces] is not between
  /// 0 and 9.
  const OMeshBinaryFormatCodec.v2Rounded({int decimalPlaces = 3})
      : specVersion = 2,
        maxDecimalPlaces = decimalPlaces;

  /// The original binary format.
  ///
  /// Only supports meshes up to 15 vertices in each dimension, and stores
  /// sRGB and extended sRGB colors with 8 bits per component.
  ///
  /// Prefer [v2] unless the data must be read by versions of this package
  /// prior to the introduction of [v2].
  static const v1 = OMeshBinaryFormatCodec._(
    specVersion: 1,
  );

  /// A compact and lossless binary format.
  ///
  /// Supports meshes up to 255 vertices in each dimension and preserves
  /// every coordinate and color exactly, including the color space of each
  /// color.
  static const v2 = OMeshBinaryFormatCodec._(
    specVersion: 2,
  );

  /// The spec version written by this codec.
  final int specVersion;

  /// The maximum amount of fractional digits kept for coordinates, or `null`
  /// when coordinates are kept exactly.
  ///
  /// See also:
  /// * [OMeshBinaryFormatCodec.v2Rounded], the codec that sets this.
  final int? maxDecimalPlaces;

  @override
  Converter<Uint8List, OMeshRect> get decoder => _OMeshBinaryFormatDecoder();

  @override
  Converter<OMeshRect, Uint8List> get encoder => _OMeshBinaryFormatEncoder(
        specVersion: specVersion,
        maxDecimalPlaces: maxDecimalPlaces,
      );
}

class _OMeshBinaryFormatDecoder extends Converter<Uint8List, OMeshRect> {
  @override
  OMeshRect convert(Uint8List input) {
    final reader = Payload.read(input);
    try {
      final format = reader.get(OMeshBinaryFormatPayloadType.instance);
      return format.mesh;
      // Reading past the end of the data throws a different error on each
      // platform, each of them an ArgumentError.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      throw FormatException("O'Mesh data is truncated or invalid: $error");
    }
  }
}

class _OMeshBinaryFormatEncoder extends Converter<OMeshRect, Uint8List> {
  _OMeshBinaryFormatEncoder({
    required this.specVersion,
    required this.maxDecimalPlaces,
  });

  final int specVersion;

  final int? maxDecimalPlaces;

  @override
  Uint8List convert(OMeshRect input) {
    final format = (
      specVersion: specVersion,
      mesh: input,
    );

    final writer = Payload.write()
      ..set<OMeshBinaryFormat>(
        OMeshBinaryFormatPayloadType(maxDecimalPlaces: maxDecimalPlaces),
        format,
      );

    return binarize(writer);
  }
}
