import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mesh/mesh.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A version of [OMeshRect] after rendered into a rectangualar area.
///
/// Vertices are non-normalized to positions relative to a [Rect].
///
/// Bezier control points are inferred from the positions of the
/// sorrounding vertices.

class RenderedOMeshRect {
  /// Creates a new [RenderedOMeshRect] from a [OMeshRect] and a [Rect].
  RenderedOMeshRect({
    required this.mesh,
    required Rect rect,
    List<OVertex>? normalizedVertices,
  }) {
    final denormalizedVertices = (normalizedVertices ?? mesh.vertices)
        .map((ov) => ov.denormalize(rect))
        .toList();

    vertices = List.generate(
      denormalizedVertices.length,
      (index) => RenderedOVertex._fromVerticeOnMesh(
        index,
        mesh.width,
        denormalizedVertices,
      ),
    );
  }

  /// The mesh that was rendered.
  late final OMeshRect mesh;

  /// The vertices of the mesh after rendering.
  late final List<RenderedOVertex> vertices;
}

/// A vertex after being rendered into a rectangular area.
///
/// Control points are inferred from the positions of the sorrounding vertices
/// on a [RenderedOMeshRect].
///
/// The position of the vertex [p] is not normalized.
@immutable
class RenderedOVertex {
  /// Creates a new [RenderedOVertex] with the given
  /// [p], [north], [east], [south], and [west] values.
  const RenderedOVertex({
    required this.p,
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  factory RenderedOVertex._fromVerticeOnMesh(
    int index,
    int meshWidth,
    List<_DeNormalizedOVertex> denormalizedVertices,
  ) {
    final position = denormalizedVertices[index];

    _DeNormalizedOVertex? vertexToTheNorth;
    final ovNorthIndex = index - meshWidth;
    if (ovNorthIndex >= 0) {
      vertexToTheNorth = denormalizedVertices[ovNorthIndex];
    }

    _DeNormalizedOVertex? vertexToTheEast;
    final ovEastIndex = index + 1;
    if (ovEastIndex % meshWidth != 0) {
      vertexToTheEast = denormalizedVertices[ovEastIndex];
    }

    _DeNormalizedOVertex? vertexToTheSouth;
    final ovSouthIndex = index + meshWidth;
    if (ovSouthIndex < denormalizedVertices.length) {
      vertexToTheSouth = denormalizedVertices[ovSouthIndex];
    }

    _DeNormalizedOVertex? vertexToTheWest;
    final ovWestIndex = index - 1;
    if (ovWestIndex % meshWidth != meshWidth - 1) {
      vertexToTheWest = denormalizedVertices[ovWestIndex];
    }

    return RenderedOVertex._fromRelativeVertices(
      position,
      vertexToTheNorth: vertexToTheNorth,
      vertexToTheEast: vertexToTheEast,
      vertexToTheSouth: vertexToTheSouth,
      vertexToTheWest: vertexToTheWest,
      distanceFactor: 0.3,
    );
  }

  factory RenderedOVertex._fromRelativeVertices(
    OVertex position, {
    required _DeNormalizedOVertex? vertexToTheNorth,
    required _DeNormalizedOVertex? vertexToTheEast,
    required _DeNormalizedOVertex? vertexToTheSouth,
    required _DeNormalizedOVertex? vertexToTheWest,
    required double distanceFactor,
  }) {
    vm.Vector2 inferCp({
      vm.Vector2? cp,
      ({vm.Vector2 relativeVertex, vm.Vector2 guide})? relativeInfo,
    }) {
      if (cp != null) {
        return cp;
      } else if (relativeInfo != null) {
        final (:relativeVertex, :guide) = relativeInfo;

        final ogRotationRad = _angleBetween(guide, position);
        final rotationRad = _angleBetween(relativeVertex, position);
        final rotationRadLerp = _radiusLerp(rotationRad, ogRotationRad, 0.8);

        final distance = position.distanceTo(relativeVertex);

        final rotatedRelativeVertex = vm.Vector2(
          position.x + cos(rotationRadLerp) * distance * distanceFactor,
          position.y + sin(rotationRadLerp) * distance * distanceFactor,
        );

        return rotatedRelativeVertex;
      } else {
        return position;
      }
    }

    final north = inferCp(
      cp: position.northCp,
      relativeInfo: vertexToTheNorth != null
          ? (
              relativeVertex: vertexToTheNorth,
              guide: position - vm.Vector2(0, 1)
            )
          : null,
    );

    final east = inferCp(
      cp: position.eastCp,
      relativeInfo: vertexToTheEast != null
          ? (
              relativeVertex: vertexToTheEast,
              guide: position + vm.Vector2(1, 0)
            )
          : null,
    );

    final south = inferCp(
      cp: position.southCp,
      relativeInfo: vertexToTheSouth != null
          ? (
              relativeVertex: vertexToTheSouth,
              guide: position + vm.Vector2(0, 1)
            )
          : null,
    );

    final west = inferCp(
      cp: position.westCp,
      relativeInfo: vertexToTheWest != null
          ? (
              relativeVertex: vertexToTheWest,
              guide: position - vm.Vector2(1, 0)
            )
          : null,
    );

    return RenderedOVertex(
      p: position,
      north: north,
      east: east,
      south: south,
      west: west,
    );
  }

  static double _angleBetween(vm.Vector2 a, vm.Vector2 b) {
    return atan2(a.y - b.y, a.x - b.x);
  }

  static double _radiusLerp(double a, double b, double t) {
    final diff = b - a;
    if (diff > pi) {
      return a + (diff - 2 * pi) * t;
    } else if (diff < -pi) {
      return a + (diff + 2 * pi) * t;
    } else {
      return a + diff * t;
    }
  }

  /// The position of the vertex.
  final vm.Vector2 p;

  /// The control point for the north direction.
  final vm.Vector2 north;

  /// The control point for the east direction.
  final vm.Vector2 east;

  /// The control point for the south direction.
  final vm.Vector2 south;

  /// The control point for the west direction.
  final vm.Vector2 west;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RenderedOVertex &&
        other.p == p &&
        other.north == north &&
        other.east == east &&
        other.south == south &&
        other.west == west;
  }

  @override
  int get hashCode {
    return p.hashCode ^
        north.hashCode ^
        east.hashCode ^
        south.hashCode ^
        west.hashCode;
  }

  @override
  String toString() {
    return '''
RenderedOVertex(p: $p, north: $north, east: $east, south: $south, west: $west)''';
  }
}

extension type _DeNormalizedOVertex(OVertex vertex) implements OVertex {}

extension on OVertex {
  _DeNormalizedOVertex denormalize(Rect rect) {
    return _DeNormalizedOVertex(
      OVertex(
        x * rect.width + rect.left,
        y * rect.height + rect.top,
      )
        ..eastCp = eastCp?.withinV(rect)
        ..northCp = northCp?.withinV(rect)
        ..southCp = southCp?.withinV(rect)
        ..westCp = westCp?.withinV(rect),
    );
  }
}

extension on vm.Vector2 {
  vm.Vector2 withinV(Rect rect) {
    return vm.Vector2(
      x * rect.width + rect.left,
      y * rect.height + rect.top,
    );
  }
}
