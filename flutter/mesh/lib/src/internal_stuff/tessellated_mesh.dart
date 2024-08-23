// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;
import 'dart:ui' as ui show Offset;

import 'package:flutter/rendering.dart' show Size, VertexMode;
import 'package:mesh/internal_stuff.dart';

class TessellatedMesh {
  TessellatedMesh({
    required int tessellation,
  })  : _vertexData = Float32List((tessellation * tessellation) * 24);

  final Float32List _vertexData;

  /// Returns a [Vertices] object with the given
  /// [size], [cornerIndices], [verticesMesh], [textureMesh],
  /// and [tessellation].
  Vertices getTessellatedVerticesForPatch({
    required Size size,
    required List<int> cornerIndices,
    required RenderedOMeshRect verticesMesh,
    required RenderedOMeshRect textureMesh,
    required int tessellation,
  }) {
    final lengthInF32 = _vertexData.length ~/ 2;
    final offsetInBytes = lengthInF32 * 4;
    final verticesTriangles = Float32List.view(_vertexData.buffer, 0, lengthInF32);
    final textureTriangles = Float32List.view(_vertexData.buffer, offsetInBytes, lengthInF32);

    _writeTriangles(
      size,
      cornerIndices,
      verticesMesh,
      tessellation,
      verticesTriangles,
    );

    _writeTriangles(
      size,
      cornerIndices,
      textureMesh,
      tessellation,
      textureTriangles,
    );

    return Vertices.raw(
      VertexMode.triangles,
      verticesTriangles,
      textureCoordinates: textureTriangles,
    );
  }

  void _writeTriangles(
    Size size,
    List<int> cornerIndices,
    RenderedOMeshRect renderedOMeshRect,
    int tessellation,
    Float32List output,
  ) {
    final topLeft = renderedOMeshRect.vertices[cornerIndices[0]];
    final topRight = renderedOMeshRect.vertices[cornerIndices[1]];
    final bottomLeft = renderedOMeshRect.vertices[cornerIndices[2]];
    final bottomRight = renderedOMeshRect.vertices[cornerIndices[3]];
    final surface = _BezierPatch(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    );

    var offset = 0;
    for (var tRow = 0; tRow < tessellation; tRow++) {
      for (var tCol = 0; tCol < tessellation; tCol++) {
        final uLeft = tCol / tessellation;
        final uRight = (tCol + 1) / tessellation;
        final vTop = tRow / tessellation;
        final vBottom = (tRow + 1) / tessellation;

        final topLeft = surface.getPoint(uLeft, vTop);
        final topRight = surface.getPoint(uRight, vTop);
        final bottomLeft = surface.getPoint(uLeft, vBottom);
        final bottomRight = surface.getPoint(uRight, vBottom);

        output[offset++] = topLeft.dx;
        output[offset++] = topLeft.dy;
        output[offset++] = topRight.dx;
        output[offset++] = topRight.dy;
        output[offset++] = bottomRight.dx;
        output[offset++] = bottomRight.dy;

        output[offset++] = topLeft.dx;
        output[offset++] = topLeft.dy;
        output[offset++] = bottomLeft.dx;
        output[offset++] = bottomLeft.dy;
        output[offset++] = bottomRight.dx;
        output[offset++] = bottomRight.dy;
      }
    }
  }
}

class _BezierPatch {
  _BezierPatch({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final RenderedOVertex topLeft;
  final RenderedOVertex topRight;
  final RenderedOVertex bottomLeft;
  final RenderedOVertex bottomRight;

  /// Linearly interpolate between two doubles.
  static ui.Offset _lerpDouble(ui.Offset a, ui.Offset b, double t) {
    return a * (1.0 - t) + b * t;
  }

  // This is the hottest function in the animated mesh gradient
  // example
  ui.Offset getPoint(double u, double v) {
    // Thanks mr Paul de Casteljau
    final topEdge = _bezierInterpolation(
      point1: topLeft.p,
      point2: topRight.p,
      controlPoint1: topLeft.east,
      controlPoint2: topRight.west,
      t: u,
    );

    final bottomEdge = _bezierInterpolation(
      point1: bottomLeft.p,
      point2: bottomRight.p,
      controlPoint1: bottomLeft.east,
      controlPoint2: bottomRight.west,
      t: u,
    );

    final vcptl = topLeft.south - topLeft.p;
    final vcptr = topRight.south - topRight.p;

    final vcpt = _lerpDouble(vcptl, vcptr, u) + topEdge;

    final vcpbl = bottomLeft.north - bottomLeft.p;
    final vcpbr = bottomRight.north - bottomRight.p;

    final vcpb = _lerpDouble(vcpbl, vcpbr, u) + bottomEdge;

    return _bezierInterpolation(
      point1: topEdge,
      point2: bottomEdge,
      controlPoint1: vcpt,
      controlPoint2: vcpb,
      t: v,
    );
  }

  ui.Offset _bezierInterpolation({
    required ui.Offset point1,
    required ui.Offset controlPoint1,
    required ui.Offset controlPoint2,
    required ui.Offset point2,
    required double t,
  }) {
    final mt = 1.0 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t3 = t * t * t;
    final dx = (mt3 * point1.dx) +
        (controlPoint1.dx * mt2 * t * 3) +
        (controlPoint2.dx * mt * t * t * 3) +
        (point2.dx * t3);
    final dy = (mt3 * point1.dy) +
        (controlPoint1.dy * mt2 * t * 3) +
        (controlPoint2.dy * mt * t * t * 3) +
        (point2.dy * t3);

    return ui.Offset(dx, dy);
  }
}
