import 'dart:convert';

import 'package:binarize/binarize.dart'
    show ByteData, Bytes, Payload, PayloadType, binarize, uint8;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/hash/binary_payload/omesh_payload_type.dart';
import 'package:mesh/src/hash/binary_payload/omesh_rect_payload.dart';

const kOMeshFingerprint = 'OM';

typedef OMeshBinaryFormat = ({
  String fingerPrint,
  int specVersion,
  int layerCount,
  List<(MeshType, OMeshRect)> layers,
});

class OMeshBinaryFormatPayloadType extends PayloadType<OMeshBinaryFormat> {
  const OMeshBinaryFormatPayloadType._();

  static const OMeshBinaryFormatPayloadType instance =
      OMeshBinaryFormatPayloadType._();

  @override
  OMeshBinaryFormat get(ByteData data, int offset) {
    final o = ByteOffset(offset);

    final fingerPrint = _FingerPrintPayloadType.instance.get(data, o);

    if (fingerPrint != kOMeshFingerprint) {
      throw const FormatException('Invalid fingerprint');
    }

    final specVersion = data.getUint8(o.displace(1));
    final layerCount = data.getUint8(o.displace(1));

    final layers = List.generate(
      layerCount,
      (_) => _LayerInfoPayloadType.instance.get(data, o),
    );

    return (
      fingerPrint: fingerPrint,
      specVersion: specVersion,
      layerCount: layerCount,
      layers: layers,
    );
  }

  @override
  int length(OMeshBinaryFormat value) {
    final fingerPrintLength =
        _FingerPrintPayloadType.instance.length(value.fingerPrint);
    const specVersionLength = 1;
    const layerCountLength = 1;
    final layersLength = value.layers.fold<int>(
      0,
      (previousValue, element) =>
          previousValue + _LayerInfoPayloadType.instance.length(element),
    );

    return fingerPrintLength +
        specVersionLength +
        layerCountLength +
        layersLength;
  }

  @override
  void set(OMeshBinaryFormat value, ByteData data, int offset) {
    final o = ByteOffset(offset);

    _FingerPrintPayloadType.instance.set(value.fingerPrint, data, o);
    data
      ..setUint8(o.displace(1), value.specVersion)
      ..setUint8(o.displace(1), value.layerCount);

    for (var i = 0; i < value.layers.length; i++) {
      _LayerInfoPayloadType.instance.set(value.layers[i], data, o);
    }
  }
}

class _FingerPrintPayloadType extends OMeshPayloadType<String> {
  const _FingerPrintPayloadType();

  static const _FingerPrintPayloadType instance = _FingerPrintPayloadType();

  @override
  int length(String value) {
    const lenghtLenght = 1;
    final length = utf8.encode(value).length;
    return lenghtLenght + length;
  }

  @override
  String get(ByteData data, ByteOffset o) {
    final length = data.getUint8(o.displace(1));
    final payload = Payload.read(
      data.buffer.asUint8List(o.displace(length), length),
    );
    return utf8.decode(payload.get(Bytes(length)));
  }

  @override
  void set(String value, ByteData data, ByteOffset o) {
    final encoded = utf8.encode(value);
    final bytes = binarize(
      Payload.write()
        ..set(uint8, encoded.length)
        ..set(Bytes(encoded.length), encoded),
    );

    for (var i = 0; i < bytes.length; i++) {
      data.setUint8(o.displace(1), bytes[i]);
    }
  }
}

enum MeshType {
  rect,
}

class _LayerInfoPayloadType extends OMeshPayloadType<(MeshType, OMeshRect)> {
  const _LayerInfoPayloadType._();

  static const _LayerInfoPayloadType instance = _LayerInfoPayloadType._();

  @override
  (MeshType, OMeshRect) get(ByteData data, ByteOffset o) {
    final typeInfo = data.getUint8(o.displace(1));
    final type = MeshType.values[typeInfo];

    final mesh = type == MeshType.rect
        ? OMeshRectPayloadType.instance.get(data, o)
        : throw UnimplementedError();

    return (type, mesh);
  }

  @override
  int length((MeshType, OMeshRect) value) {
    const typeLength = 1;
    final meshLength = OMeshRectPayloadType.instance.length(value.$2);
    return typeLength + meshLength;
  }

  @override
  void set((MeshType, OMeshRect) value, ByteData data, ByteOffset o) {
    data.setUint8(o.displace(1), value.$1.index);
    // ignore: unnecessary_type_check
    if (value.$2 is OMeshRect) {
      OMeshRectPayloadType.instance.set(value.$2, data, o);
    } else {
      throw UnimplementedError();
    }
  }
}
