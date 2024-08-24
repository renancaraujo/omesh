import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';
// import 'package:vector_math/vector_math.dart' as vm;

/// A version of [OMeshRect] after rendered into a rectangualar area.
///
/// Vertices are non-normalized to positions relative to a [ui.Rect].
///
/// Bezier control points are inferred from the positions of the
/// sorrounding vertices.

class RenderedOMeshRect {
  /// Creates a new [RenderedOMeshRect] from a [OMeshRect] and a [ui.Rect].
  RenderedOMeshRect({
    required this.mesh,
    required ui.Rect rect,
    List<OVertex>? normalizedVerticesOverride,
  }) {
    final denormalizedVertices = (normalizedVerticesOverride ?? mesh.vertices)
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
  final OMeshRect mesh;

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

    ui.Offset? vertexToTheNorth;
    final ovNorthIndex = index - meshWidth;
    if (ovNorthIndex >= 0) {
      vertexToTheNorth = denormalizedVertices[ovNorthIndex].toOffset();
    }

    ui.Offset? vertexToTheEast;
    final ovEastIndex = index + 1;
    if (ovEastIndex % meshWidth != 0) {
      vertexToTheEast = denormalizedVertices[ovEastIndex].toOffset();
    }

    ui.Offset? vertexToTheSouth;
    final ovSouthIndex = index + meshWidth;
    if (ovSouthIndex < denormalizedVertices.length) {
      vertexToTheSouth = denormalizedVertices[ovSouthIndex].toOffset();
    }

    ui.Offset? vertexToTheWest;
    final ovWestIndex = index - 1;
    if (ovWestIndex % meshWidth != meshWidth - 1) {
      vertexToTheWest = denormalizedVertices[ovWestIndex].toOffset();
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
    _DeNormalizedOVertex denormalizedVertex, {
    required ui.Offset? vertexToTheNorth,
    required ui.Offset? vertexToTheEast,
    required ui.Offset? vertexToTheSouth,
    required ui.Offset? vertexToTheWest,
    required double distanceFactor,
  }) {
    final positionOffset = denormalizedVertex.toOffset();

    ui.Offset inferCp({
      ({
        ui.Offset relativeVertexOffset,
        ui.Offset guide,
      })? relativeInfo,
    }) {
      if (relativeInfo == null) {
        return positionOffset;
      }

      final (:relativeVertexOffset, :guide) = relativeInfo;

      final ogRotationRad = _angleBetween(guide, positionOffset);
      final rotationRad = _angleBetween(relativeVertexOffset, positionOffset);
      final rotationRadLerp = _radiusLerp(rotationRad, ogRotationRad, 0.8);

      final distance = positionOffset.distanceTo(relativeVertexOffset);

      final rotatedRelativeVertex = ui.Offset(
        positionOffset.dx + cos(rotationRadLerp) * distance * distanceFactor,
        positionOffset.dy + sin(rotationRadLerp) * distance * distanceFactor,
      );

      return rotatedRelativeVertex;
    }

    final north = denormalizedVertex.north?.toOffset() ??
        inferCp(
          relativeInfo: vertexToTheNorth != null
              ? (
                  relativeVertexOffset: vertexToTheNorth,
                  guide: positionOffset - const ui.Offset(0, 1)
                )
              : null,
        );

    final east = denormalizedVertex.east?.toOffset() ??
        inferCp(
          relativeInfo: vertexToTheEast != null
              ? (
                  relativeVertexOffset: vertexToTheEast,
                  guide: positionOffset + const ui.Offset(1, 0)
                )
              : null,
        );

    final south = denormalizedVertex.south?.toOffset() ??
        inferCp(
          relativeInfo: vertexToTheSouth != null
              ? (
                  relativeVertexOffset: vertexToTheSouth,
                  guide: positionOffset + const ui.Offset(0, 1)
                )
              : null,
        );

    final west = denormalizedVertex.west?.toOffset() ??
        inferCp(
          relativeInfo: vertexToTheWest != null
              ? (
                  relativeVertexOffset: vertexToTheWest,
                  guide: positionOffset - const ui.Offset(1, 0)
                )
              : null,
        );

    return RenderedOVertex(
      p: positionOffset,
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

extension on OVertex {
  _DeNormalizedOVertex denormalize(ui.Rect rect) {
    final denormalized = _DeNormalizedOVertex(
      BezierOVertex(
        x * rect.width + rect.left,
        y * rect.height + rect.top,
      ),
    );
    final t = this;
    if (t is BezierOVertex) {
      denormalized
        ..north = t.north?.withinV(rect)
        ..east = t.east?.withinV(rect)
        ..south = t.south?.withinV(rect)
        ..west = t.west?.withinV(rect);
    }

    return denormalized;
  }
}

extension type _DeNormalizedOVertex(BezierOVertex vertex)
    implements BezierOVertex {}

extension on ui.Offset {
  /// Compute the euclidian distance between [other] and this.
  double distanceTo(ui.Offset other) {
    return sqrt(pow(other.dx - dx, 2) + pow(other.dy - dy, 2));
  }
}

extension on OVertex {
  OVertex withinV(ui.Rect rect) {
    return OVertex(
      x * rect.width + rect.left,
      y * rect.height + rect.top,
    );
  }
}
