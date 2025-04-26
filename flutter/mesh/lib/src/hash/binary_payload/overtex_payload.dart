import 'package:binarize/binarize.dart'
    show ByteReader, ByteWriter, PayloadType;
import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';

/// {@template overtex_payload_type}
/// A [PayloadType] for [OVertex].
/// {@endtemplate}
class OVertexPayloadType extends PayloadType<OVertex> {
  const OVertexPayloadType._();

  /// {@macro overtex_payload_type}
  static const OVertexPayloadType instance = OVertexPayloadType._();

  @override
  OVertex get(ByteReader reader, [Endian? endian]) {
    final x = reader.float64(endian);
    final y = reader.float64(endian);
    final presenceOfControlPoints = reader.uint8();

    final north = presenceOfControlPoints & 0x1 != 0
        ? _PlainOVertexPayloadType.instance.get(reader, endian)
        : null;
    final east = presenceOfControlPoints & 0x2 != 0
        ? _PlainOVertexPayloadType.instance.get(reader, endian)
        : null;
    final south = presenceOfControlPoints & 0x4 != 0
        ? _PlainOVertexPayloadType.instance.get(reader, endian)
        : null;
    final west = presenceOfControlPoints & 0x8 != 0
        ? _PlainOVertexPayloadType.instance.get(reader, endian)
        : null;

    if (north == null && east == null && south == null && west == null) {
      return OVertex(x, y);
    }

    return BezierOVertex(
      x,
      y,
      north: north,
      east: east,
      south: south,
      west: west,
    );
  }

  @override
  void set(ByteWriter writer, OVertex value, [Endian? endian]) {
    writer
      ..float64(value.x, endian)
      ..float64(value.y, endian);

    var presenceOfControlPoints = 0;
    if (value is BezierOVertex) {
      if (value.north != null) {
        presenceOfControlPoints |= 0x1;
      }
      if (value.east != null) {
        presenceOfControlPoints |= 0x2;
      }
      if (value.south != null) {
        presenceOfControlPoints |= 0x4;
      }
      if (value.west != null) {
        presenceOfControlPoints |= 0x8;
      }
    }

    writer.uint8(presenceOfControlPoints);

    if (value is BezierOVertex) {
      if (value.north != null) {
        _PlainOVertexPayloadType.instance.set(writer, value.north!, endian);
      }
      if (value.east != null) {
        _PlainOVertexPayloadType.instance.set(writer, value.east!, endian);
      }
      if (value.south != null) {
        _PlainOVertexPayloadType.instance.set(writer, value.south!, endian);
      }
      if (value.west != null) {
        _PlainOVertexPayloadType.instance.set(writer, value.west!, endian);
      }
    }
  }
}

class _PlainOVertexPayloadType extends PayloadType<OVertex> {
  const _PlainOVertexPayloadType._();

  static const _PlainOVertexPayloadType instance = _PlainOVertexPayloadType._();

  @override
  OVertex get(ByteReader reader, [Endian? endian]) {
    final x = reader.float64(endian);
    final y = reader.float64(endian);

    return OVertex(x, y);
  }

  @override
  void set(ByteWriter writer, OVertex value, [Endian? endian]) {
    writer
      ..float64(value.x, endian)
      ..float64(value.y, endian);
  }
}
