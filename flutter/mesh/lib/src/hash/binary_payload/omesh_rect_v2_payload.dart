import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, Endian, PayloadType;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/color_v2_payload.dart';
import 'package:mesh/src/hash/binary_payload/number_encoding.dart';

/// Value of the number mode byte when coordinates are stored as float64.
///
/// Values `0..kMaxDecimalDigits` mean coordinates are stored as zigzag
/// varints with that amount of fractional digits.
const int _kNumberModeFloat64 = 0xFF;

/// The bits of the flags byte that hold the mesh color space.
const int _kColorSpaceMask = 0x07;

const int _kFlagSmoothColors = 0x08;
const int _kFlagFallbackColor = 0x10;
const int _kFlagBackgroundColor = 0x20;

const int _kNorth = 0x1;
const int _kEast = 0x2;
const int _kSouth = 0x4;
const int _kWest = 0x8;

/// The bits of a control point presence byte that hold its first vertex.
const int _kPresenceMask = 0x0F;

/// {@template omesh_rect_v2_payload_type}
/// A [PayloadType] for [OMeshRect] in the v2 binary format.
///
/// Coordinates are stored as short decimals relative to the regular grid
/// (vertices) or to their vertex (control points) whenever that is lossless,
/// falling back to float64 otherwise.
///
/// When [maxDecimalPlaces] is set, coordinates that would need more
/// fractional digits than that are rounded instead of falling back to
/// float64, trading precision for size.
/// {@endtemplate}
class OMeshRectV2PayloadType extends PayloadType<OMeshRect> {
  /// {@macro omesh_rect_v2_payload_type}
  const OMeshRectV2PayloadType({this.maxDecimalPlaces})
      : assert(
          maxDecimalPlaces == null ||
              (maxDecimalPlaces >= 0 && maxDecimalPlaces <= kMaxDecimalDigits),
          'maxDecimalPlaces must be between 0 and $kMaxDecimalDigits',
        );

  /// The lossless instance.
  static const OMeshRectV2PayloadType lossless = OMeshRectV2PayloadType();

  /// The maximum amount of fractional digits to keep for coordinates, or
  /// `null` to always encode them losslessly.
  final int? maxDecimalPlaces;

  @override
  OMeshRect get(ByteReader reader, [Endian? endian]) {
    final width = reader.uint8();
    final height = reader.uint8();
    if (!_isValidDimension(width) || !_isValidDimension(height)) {
      throw FormatException('Invalid mesh size ${width}x$height');
    }

    final flags = reader.uint8();
    final colorSpaceIndex = flags & _kColorSpaceMask;
    if (colorSpaceIndex >= OMeshColorSpace.values.length) {
      throw FormatException('Unknown mesh color space $colorSpaceIndex');
    }

    final numberMode = reader.uint8();
    if (numberMode != _kNumberModeFloat64 && numberMode > kMaxDecimalDigits) {
      throw FormatException('Unknown number mode $numberMode');
    }

    final count = width * height;
    final presence = Uint8List(count);
    for (var i = 0; i < count; i += 2) {
      final byte = reader.uint8();
      presence[i] = byte & _kPresenceMask;
      if (i + 1 < count) {
        presence[i + 1] = byte >> 4;
      }
    }

    final vertices = <OVertex>[];
    if (numberMode == _kNumberModeFloat64) {
      OVertex readPoint() =>
          OVertex(reader.float64(endian), reader.float64(endian));
      for (var i = 0; i < count; i++) {
        final position = readPoint();
        vertices.add(_buildVertex(position, presence[i], readPoint));
      }
    } else {
      final digits = numberMode;
      for (var i = 0; i < count; i++) {
        final x = _gridPoint(i % width, width, digits) + reader.zigzag();
        final y = _gridPoint(i ~/ width, height, digits) + reader.zigzag();
        final position = OVertex(
          fromScaledInt(x, digits),
          fromScaledInt(y, digits),
        );
        vertices.add(
          _buildVertex(
            position,
            presence[i],
            () => OVertex(
              fromScaledInt(x + reader.zigzag(), digits),
              fromScaledInt(y + reader.zigzag(), digits),
            ),
          ),
        );
      }
    }

    final paletteLength = reader.varint();
    if (paletteLength > count) {
      throw FormatException('Palette length $paletteLength out of range');
    }
    final palette = List<Color>.generate(
      paletteLength,
      (_) => ColorV2PayloadType.instance.get(reader, endian),
    );
    final colors = List<Color?>.generate(count, (_) {
      final index = reader.varint();
      if (index == 0) return null;
      if (index > paletteLength) {
        throw FormatException('Color index $index out of range');
      }
      return palette[index - 1];
    });

    final fallbackColor = flags & _kFlagFallbackColor != 0
        ? ColorV2PayloadType.instance.get(reader, endian)
        : null;
    final backgroundColor = flags & _kFlagBackgroundColor != 0
        ? ColorV2PayloadType.instance.get(reader, endian)
        : null;

    return OMeshRect(
      width: width,
      height: height,
      vertices: vertices,
      colors: colors,
      colorSpace: OMeshColorSpace.values[colorSpaceIndex],
      smoothColors: flags & _kFlagSmoothColors != 0,
      fallbackColor: fallbackColor,
      backgroundColor: backgroundColor,
    );
  }

  @override
  void set(ByteWriter writer, OMeshRect value, [Endian? endian]) {
    final width = value.width;
    final height = value.height;
    if (!_isValidDimension(width) || !_isValidDimension(height)) {
      throw ArgumentError.value(
        '${width}x$height',
        'mesh',
        'width and height must be between 2 and $_kMaxDimension',
      );
    }

    final count = width * height;
    if (value.vertices.length < count || value.colors.length < count) {
      throw ArgumentError.value(
        value,
        'mesh',
        'vertices and colors must have at least $count elements',
      );
    }
    final vertices = value.vertices.sublist(0, count);
    final colors = value.colors.sublist(0, count);

    writer
      ..uint8(width)
      ..uint8(height)
      ..uint8(
        value.colorSpace.index |
            (value.smoothColors ? _kFlagSmoothColors : 0) |
            (value.fallbackColor != null ? _kFlagFallbackColor : 0) |
            (value.backgroundColor != null ? _kFlagBackgroundColor : 0),
      );

    final digits = _chooseDecimalDigits(vertices);
    writer.uint8(digits ?? _kNumberModeFloat64);

    for (var i = 0; i < count; i += 2) {
      final low = _presenceOf(vertices[i]);
      final high = i + 1 < count ? _presenceOf(vertices[i + 1]) : 0;
      writer.uint8(low | high << 4);
    }

    if (digits == null) {
      for (final vertex in vertices) {
        writer
          ..float64(vertex.x, endian)
          ..float64(vertex.y, endian);
        for (final controlPoint in _controlPointsOf(vertex)) {
          writer
            ..float64(controlPoint.x, endian)
            ..float64(controlPoint.y, endian);
        }
      }
    } else {
      for (var i = 0; i < count; i++) {
        final vertex = vertices[i];
        final x = toScaledInt(vertex.x, digits);
        final y = toScaledInt(vertex.y, digits);
        writer
          ..zigzag(x - _gridPoint(i % width, width, digits))
          ..zigzag(y - _gridPoint(i ~/ width, height, digits));
        for (final controlPoint in _controlPointsOf(vertex)) {
          writer
            ..zigzag(toScaledInt(controlPoint.x, digits) - x)
            ..zigzag(toScaledInt(controlPoint.y, digits) - y);
        }
      }
    }

    final palette = <Color, int>{};
    for (final color in colors) {
      if (color != null) {
        palette.putIfAbsent(color, () => palette.length);
      }
    }
    writer.varint(palette.length);
    for (final color in palette.keys) {
      ColorV2PayloadType.instance.set(writer, color, endian);
    }
    for (final color in colors) {
      writer.varint(color == null ? 0 : palette[color]! + 1);
    }

    if (value.fallbackColor case final fallbackColor?) {
      ColorV2PayloadType.instance.set(writer, fallbackColor, endian);
    }
    if (value.backgroundColor case final backgroundColor?) {
      ColorV2PayloadType.instance.set(writer, backgroundColor, endian);
    }
  }

  /// Picks the amount of fractional digits used to store the coordinates of
  /// [vertices], or `null` to store them as float64.
  ///
  /// Prefers the smallest amount that is lossless. When [maxDecimalPlaces]
  /// is set and no lossless amount fits within it, rounds to
  /// [maxDecimalPlaces].
  int? _chooseDecimalDigits(List<OVertex> vertices) {
    final values = <double>[
      for (final vertex in vertices) ...[
        vertex.x,
        vertex.y,
        for (final controlPoint in _controlPointsOf(vertex)) ...[
          controlPoint.x,
          controlPoint.y,
        ],
      ],
    ];

    final limit = maxDecimalPlaces ?? kMaxDecimalDigits;
    for (var digits = 0; digits <= limit; digits++) {
      if (values.every((value) => isExactDecimal(value, digits))) {
        return digits;
      }
    }

    final rounded = maxDecimalPlaces;
    if (rounded != null &&
        values.every((value) => fitsDecimal(value, rounded))) {
      return rounded;
    }
    return null;
  }
}

/// The largest width or height that fits in the byte that stores it.
const _kMaxDimension = 0xFF;

bool _isValidDimension(int value) => value >= 2 && value <= _kMaxDimension;

/// The position of the regular grid point at [index] along an axis with
/// [size] vertices, scaled by 10^[digits] and rounded half up.
///
/// Computed with integers only, so encoder and decoder always agree.
int _gridPoint(int index, int size, int digits) =>
    (2 * index * kPow10[digits] + (size - 1)) ~/ (2 * (size - 1));

int _presenceOf(OVertex vertex) {
  if (vertex is! BezierOVertex) return 0;
  return (vertex.north != null ? _kNorth : 0) |
      (vertex.east != null ? _kEast : 0) |
      (vertex.south != null ? _kSouth : 0) |
      (vertex.west != null ? _kWest : 0);
}

/// The control points of [vertex] in north, east, south, west order.
List<OVertex> _controlPointsOf(OVertex vertex) {
  if (vertex is! BezierOVertex) return const [];
  return [
    if (vertex.north case final north?) north,
    if (vertex.east case final east?) east,
    if (vertex.south case final south?) south,
    if (vertex.west case final west?) west,
  ];
}

/// Builds a vertex at [position], reading one control point with
/// [readControlPoint] for each bit set in [presence], in north, east, south,
/// west order.
OVertex _buildVertex(
  OVertex position,
  int presence,
  OVertex Function() readControlPoint,
) {
  if (presence == 0) return position;

  final north = presence & _kNorth != 0 ? readControlPoint() : null;
  final east = presence & _kEast != 0 ? readControlPoint() : null;
  final south = presence & _kSouth != 0 ? readControlPoint() : null;
  final west = presence & _kWest != 0 ? readControlPoint() : null;

  return BezierOVertex(
    position.x,
    position.y,
    north: north,
    east: east,
    south: south,
    west: west,
  );
}
