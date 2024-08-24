import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:mesh/mesh.dart';
// import 'package:vector_math/vector_math.dart' as vm;

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
    ui.Offset inferCp({
      ui.Offset? cp,
      ({OVertex relativeVertex, ui.Offset guide})? relativeInfo,
    }) {
      if (cp != null) {
        return cp;
      }

      if (relativeInfo != null) {
        final (:relativeVertex, :guide) = relativeInfo;

        final ogRotationRad =
            _angleBetween(guide, ui.Offset(position.x, position.y));
        final rotationRad = _angleBetween(
            ui.Offset(relativeVertex.x, relativeVertex.y),
            ui.Offset(position.x, position.y));
        final rotationRadLerp = _radiusLerp(rotationRad, ogRotationRad, 0.8);

        final distance = position.distanceTo(relativeVertex);

        final rotatedRelativeVertex = ui.Offset(
          position.x + cos(rotationRadLerp) * distance * distanceFactor,
          position.y + sin(rotationRadLerp) * distance * distanceFactor,
        );

        return rotatedRelativeVertex;
      }
      return ui.Offset(position.x, position.y);
    }

    final ui.Offset positionOffset = ui.Offset(position.x, position.y);

    final north = inferCp(
      cp: position.northCp,
      relativeInfo: vertexToTheNorth != null
          ? (
              relativeVertex: vertexToTheNorth,
              guide: positionOffset - const ui.Offset(0, 1)
            )
          : null,
    );

    final east = inferCp(
      cp: position.eastCp,
      relativeInfo: vertexToTheEast != null
          ? (
              relativeVertex: vertexToTheEast,
              guide: positionOffset + const ui.Offset(1, 0)
            )
          : null,
    );

    final south = inferCp(
      cp: position.southCp,
      relativeInfo: vertexToTheSouth != null
          ? (
              relativeVertex: vertexToTheSouth,
              guide: positionOffset + const ui.Offset(0, 1)
            )
          : null,
    );

    final west = inferCp(
      cp: position.westCp,
      relativeInfo: vertexToTheWest != null
          ? (
              relativeVertex: vertexToTheWest,
              guide: positionOffset - const ui.Offset(1, 0)
            )
          : null,
    );

    return RenderedOVertex(
      p: ui.Offset(position.x, position.y),
      north: north,
      east: east,
      south: south,
      west: west,
    );
  }

  static double _angleBetween(ui.Offset a, ui.Offset b) {
    return atan2(a.dy - b.dy, a.dx - b.dx);
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
  final ui.Offset p;

  /// The control point for the north direction.
  final ui.Offset north;

  /// The control point for the east direction.
  final ui.Offset east;

  /// The control point for the south direction.
  final ui.Offset south;

  /// The control point for the west direction.
  final ui.Offset west;

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
  int get hashCode => Object.hash(p, north, east, south, west);

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

extension on ui.Offset {
  ui.Offset withinV(Rect rect) {
    return ui.Offset(
      dx * rect.width + rect.left,
      dy * rect.height + rect.top,
    );
  }
}
