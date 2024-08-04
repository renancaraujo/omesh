// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;

import 'package:flutter/rendering.dart' show Size, VertexMode;
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/src/utils.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vector_math/vector_math.dart';

class TessellatedMesh {
  TessellatedMesh({
    required this.tessellation,
  });

  final int tessellation;
  late final _trianglesLength = (tessellation * tessellation) * 12;
  late final _verticesTriangles = Float32List(_trianglesLength);
  late final _textureTriangles = Float32List(_trianglesLength);

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
    final verticesTrianglesIterable = _getTriangles(
      size,
      cornerIndices,
      verticesMesh,
      tessellation,
      impellerCompatibilityMode: impellerCompatibilityMode,
    );

    final textureTrianglesIterable = _getTriangles(
      size,
      cornerIndices,
      textureMesh,
      tessellation,
      impellerCompatibilityMode: impellerCompatibilityMode,
    );

    final verticesIterator = verticesTrianglesIterable.iterator;
    final texturesIterator = textureTrianglesIterable.iterator;
    for (var i = 0; i < _trianglesLength; i++) {
      verticesIterator.moveNext();
      _verticesTriangles[i] = verticesIterator.current;

      texturesIterator.moveNext();
      _textureTriangles[i] = texturesIterator.current;
    }

    return Vertices.raw(
      VertexMode.triangles,
      _verticesTriangles,
      textureCoordinates: _textureTriangles,
    );
  }

  Iterable<double> _getTriangles(
    Size size,
    List<int> cornerIndices,
    RenderedOMeshRect renderedOMeshRect,
    int tessellation, {
    required bool impellerCompatibilityMode,
  }) sync* {
    var topLeft = renderedOMeshRect.vertices[cornerIndices[0]];
    var topRight = renderedOMeshRect.vertices[cornerIndices[1]];
    var bottomLeft = renderedOMeshRect.vertices[cornerIndices[2]];
    var bottomRight = renderedOMeshRect.vertices[cornerIndices[3]];

    if (impellerCompatibilityMode) {
      const displace = 2.0;

      topLeft = RenderedOVertex(
        p: Vector2(topLeft.p.x - displace, topLeft.p.y - displace),
        north: topLeft.north,
        east: topLeft.east,
        south: topLeft.south,
        west: topLeft.west,
      );

      topRight = RenderedOVertex(
        p: Vector2(topRight.p.x + displace, topRight.p.y - displace),
        north: topRight.north,
        east: topRight.east,
        south: topRight.south,
        west: topRight.west,
      );

      bottomLeft = RenderedOVertex(
        p: Vector2(bottomLeft.p.x - displace, bottomLeft.p.y + displace),
        north: bottomLeft.north,
        east: bottomLeft.east,
        south: bottomLeft.south,
        west: bottomLeft.west,
      );

      bottomRight = RenderedOVertex(
        p: Vector2(bottomRight.p.x + displace, bottomRight.p.y + displace),
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

        yield* _yieldVector(topLeft);
        yield* _yieldVector(topRight);
        yield* _yieldVector(bottomRight);
        yield* _yieldVector(topLeft);
        yield* _yieldVector(bottomLeft);
        yield* _yieldVector(bottomRight);
      }
    }
  }

  Iterable<double> _yieldVector(vm.Vector2 v) sync* {
    yield v.x;
    yield v.y;
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

  vm.Vector2 getPoint(double u, double v, {bool debug = false}) {
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

    final vcpt = vector2Lerp(vcptl, vcptr, u) + topEdge;

    final vcpbl = bottomLeft.north - bottomLeft.p;
    final vcpbr = bottomRight.north - bottomRight.p;

    final vcpb = vector2Lerp(vcpbl, vcpbr, u) + bottomEdge;

    return _bezierInterpolation(
      point1: topEdge,
      point2: bottomEdge,
      controlPoint1: vcpt,
      controlPoint2: vcpb,
      t: v,
    );
  }

  vm.Vector2 _bezierInterpolation({
    required vm.Vector2 point1,
    required vm.Vector2 controlPoint1,
    required vm.Vector2 controlPoint2,
    required vm.Vector2 point2,
    required double t,
  }) {
    final mt = 1.0 - t;
    var point = point1;
    point *= mt * mt * mt;
    point += controlPoint1 * mt * mt * t * 3;
    point += controlPoint2 * mt * t * t * 3;
    point += point2 * t * t * t;
    return point;
  }
}
