import 'package:binarize/binarize.dart' show ByteData;
import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';

class OVertexPayloadType extends OMeshPayloadType<OVertex> {
  const OVertexPayloadType._();

  static const OVertexPayloadType instance = OVertexPayloadType._();

  @override
  OVertex get(ByteData data, ByteOffset o) {
    final x = data.getFloat64(o.displace(8));
    final y = data.getFloat64(o.displace(8));
    final presenceOfControlPoints = data.getUint8(o.displace(1));

    final north = presenceOfControlPoints & 0x1 != 0
        ? _PlainOVertexPayloadType.instance.get(data, o)
        : null;
    final east = presenceOfControlPoints & 0x2 != 0
        ? _PlainOVertexPayloadType.instance.get(data, o)
        : null;
    final south = presenceOfControlPoints & 0x4 != 0
        ? _PlainOVertexPayloadType.instance.get(data, o)
        : null;
    final west = presenceOfControlPoints & 0x8 != 0
        ? _PlainOVertexPayloadType.instance.get(data, o)
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
  int length(OVertex value) {
    const xyLength = 16;
    const presenceOfControlPointsLength = 1;
    final int northLength;
    final int eastLength;
    final int southLength;
    final int westLength;

    if (value is BezierOVertex) {
      northLength = value.north != null
          ? _PlainOVertexPayloadType.instance.length(value.north!)
          : 0;
      eastLength = value.east != null
          ? _PlainOVertexPayloadType.instance.length(value.east!)
          : 0;
      southLength = value.south != null
          ? _PlainOVertexPayloadType.instance.length(value.south!)
          : 0;
      westLength = value.west != null
          ? _PlainOVertexPayloadType.instance.length(value.west!)
          : 0;
    } else {
      northLength = 0;
      eastLength = 0;
      southLength = 0;
      westLength = 0;
    }

    return xyLength +
        presenceOfControlPointsLength +
        northLength +
        eastLength +
        southLength +
        westLength;
  }

  @override
  void set(OVertex value, ByteData data, ByteOffset o) {
    data
      ..setFloat64(o.displace(8), value.x)
      ..setFloat64(o.displace(8), value.y);

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

    data.setUint8(o.displace(1), presenceOfControlPoints);

    if (value is BezierOVertex) {
      if (value.north != null) {
        _PlainOVertexPayloadType.instance.set(value.north!, data, o);
      }
      if (value.east != null) {
        _PlainOVertexPayloadType.instance.set(value.east!, data, o);
      }
      if (value.south != null) {
        _PlainOVertexPayloadType.instance.set(value.south!, data, o);
      }
      if (value.west != null) {
        _PlainOVertexPayloadType.instance.set(value.west!, data, o);
      }
    }
  }
}

class _PlainOVertexPayloadType extends OMeshPayloadType<OVertex> {
  const _PlainOVertexPayloadType._();

  static const _PlainOVertexPayloadType instance = _PlainOVertexPayloadType._();

  @override
  OVertex get(ByteData data, ByteOffset o) {
    final x = data.getFloat64(o.displace(8));
    final y = data.getFloat64(o.displace(8));

    return OVertex(x, y);
  }

  @override
  int length(OVertex value) {
    const xyLength = 16;
    return xyLength;
  }

  @override
  void set(OVertex value, ByteData data, ByteOffset o) {
    data
      ..setFloat64(o.displace(8), value.x)
      ..setFloat64(o.displace(8), value.y);
  }
}
