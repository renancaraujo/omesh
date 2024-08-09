// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;
import 'dart:ui' as ui show Offset;

import 'package:flutter/rendering.dart' show Size, VertexMode;
import 'package:mesh/internal_stuff.dart';

class TessellatedMesh {
  TessellatedMesh({
    required this.tessellation,
  })  : _verticesTriangles = Float32List((tessellation * tessellation) * 12),
        _textureTriangles = Float32List((tessellation * tessellation) * 12);

  final int tessellation;
  final Float32List _verticesTriangles;
  final Float32List _textureTriangles;

  /// Returns a [Vertices] object with the given
  /// [size], [cornerIndices], [verticesMesh], [textureMesh],
  /// and [tessellation].
  Vertices getTessellatedVerticesForPatch({
    required Size size,
    required List<int> cornerIndices,
    required RenderedOMeshRect verticesMesh,
    required RenderedOMeshRect textureMesh,
    required int tessellation,
    required bool impellerCompatibilityMode,
  }) {
    _writeTriangles(
      size,
      cornerIndices,
      verticesMesh,
      tessellation,
      _verticesTriangles,
      impellerCompatibilityMode: impellerCompatibilityMode,
    );

    _writeTriangles(
      size,
      cornerIndices,
      textureMesh,
      tessellation,
      _textureTriangles,
      impellerCompatibilityMode: impellerCompatibilityMode,
    );

    return Vertices.raw(
      VertexMode.triangles,
      _verticesTriangles,
      textureCoordinates: _textureTriangles,
    );
  }

  void _writeTriangles(
    Size size,
    List<int> cornerIndices,
    RenderedOMeshRect renderedOMeshRect,
    int tessellation,
    Float32List output, {
    required bool impellerCompatibilityMode,
  }) {
    var topLeft = renderedOMeshRect.vertices[cornerIndices[0]];
    var topRight = renderedOMeshRect.vertices[cornerIndices[1]];
    var bottomLeft = renderedOMeshRect.vertices[cornerIndices[2]];
    var bottomRight = renderedOMeshRect.vertices[cornerIndices[3]];

    if (impellerCompatibilityMode) {
      const displace = 2.0;

      topLeft = RenderedOVertex(
        p: ui.Offset(topLeft.p.dx - displace, topLeft.p.dy - displace),
        north: topLeft.north,
        east: topLeft.east,
        south: topLeft.south,
        west: topLeft.west,
      );

      topRight = RenderedOVertex(
        p: ui.Offset(topRight.p.dx + displace, topRight.p.dy - displace),
        north: topRight.north,
        east: topRight.east,
        south: topRight.south,
        west: topRight.west,
      );

      bottomLeft = RenderedOVertex(
        p: ui.Offset(bottomLeft.p.dx - displace, bottomLeft.p.dy + displace),
        north: bottomLeft.north,
        east: bottomLeft.east,
        south: bottomLeft.south,
        west: bottomLeft.west,
      );

      bottomRight = RenderedOVertex(
        p: ui.Offset(bottomRight.p.dx + displace, bottomRight.p.dy + displace),
        north: bottomRight.north,
        east: bottomRight.east,
        south: bottomRight.south,
        west: bottomRight.west,
      );
    }

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

        final ui.Offset(dx: topLeftX, dy: topLeftY) =
            surface.getPoint(uLeft, vTop);
        final ui.Offset(dx: topRightX, dy: topRightY) =
            surface.getPoint(uRight, vTop);
        final ui.Offset(dx: bottomLeftX, dy: bottomLeftY) =
            surface.getPoint(uLeft, vBottom);
        final ui.Offset(dx: bottomRightX, dy: bottomRightY) =
            surface.getPoint(uRight, vBottom);

        output[offset++] = topLeftX;
        output[offset++] = topLeftY;
        output[offset++] = topRightX;
        output[offset++] = topRightY;
        output[offset++] = bottomLeftX;
        output[offset++] = bottomLeftY;

        output[offset++] = topLeftX;
        output[offset++] = topLeftY;
        output[offset++] = bottomLeftX;
        output[offset++] = bottomLeftY;
        output[offset++] = bottomRightX;
        output[offset++] = bottomRightY;
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
