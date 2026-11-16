import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

Offset _referencePoint(List<RenderedOVertex> corners, double u, double v) {
  final [topLeft, topRight, bottomLeft, bottomRight] = corners;
  Offset lerp(Offset a, Offset b, double t) => a * (1.0 - t) + b * t;
  Offset bezier(Offset p1, Offset c1, Offset c2, Offset p2, double t) {
    final mt = 1.0 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t3 = t * t * t;
    return Offset(
      mt3 * p1.dx + c1.dx * mt2 * t * 3 + c2.dx * mt * t * t * 3 + p2.dx * t3,
      mt3 * p1.dy + c1.dy * mt2 * t * 3 + c2.dy * mt * t * t * 3 + p2.dy * t3,
    );
  }

  final top = bezier(topLeft.p, topLeft.east, topRight.west, topRight.p, u);
  final bottom = bezier(
    bottomLeft.p,
    bottomLeft.east,
    bottomRight.west,
    bottomRight.p,
    u,
  );
  final topControl =
      lerp(topLeft.south - topLeft.p, topRight.south - topRight.p, u) + top;
  final bottomControl = lerp(
        bottomLeft.north - bottomLeft.p,
        bottomRight.north - bottomRight.p,
        u,
      ) +
      bottom;
  return bezier(top, topControl, bottomControl, bottom, v);
}

final _mesh = OMeshRect(
  width: 3,
  height: 3,
  vertices: [
    (0.0, 0.0).v, (0.5, 0.1).v, (1.0, 0.0).v, //
    (0.1, 0.5).v,
    (0.6, 0.4).v.bezier(east: (0.9, 0.5).v, west: (0.2, 0.3).v),
    (1.0, 0.6).v, //
    (0.0, 1.0).v, (0.4, 0.9).v, (1.0, 1.0).v, //
  ],
  colors: List.filled(9, null),
);

void main() {
  group('$TessellatedMesh', () {
    final rendered = RenderedOMeshRect(
      mesh: _mesh,
      rect: const Rect.fromLTWH(10, 20, 300, 200),
    );

    for (final tessellation in [1, 2, 7, 12]) {
      test('matches the reference evaluation at tessellation $tessellation',
          () {
        final tessellated = TessellatedMesh(tessellation: tessellation);
        final side = tessellation + 1;
        for (final cornerIndices in const [
          [0, 1, 3, 4],
          [4, 5, 7, 8],
        ]) {
          final grid = Float32List(tessellated.floatsPerPatch);
          tessellated.writePatchGrid(
            cornerIndices: cornerIndices,
            mesh: rendered,
            output: grid,
          );
          final corners = [
            for (final index in cornerIndices) rendered.vertices[index],
          ];
          for (var row = 0; row < side; row++) {
            for (var col = 0; col < side; col++) {
              final expected = _referencePoint(
                corners,
                col / tessellation,
                row / tessellation,
              );
              final i = (row * side + col) * 2;
              expect(grid[i], closeTo(expected.dx, 1e-3));
              expect(grid[i + 1], closeTo(expected.dy, 1e-3));
            }
          }
        }
      });
    }

    test('writes at the given offset', () {
      final tessellated = TessellatedMesh(tessellation: 2);
      final grid = Float32List(tessellated.floatsPerPatch * 2);
      tessellated.writePatchGrid(
        cornerIndices: const [0, 1, 3, 4],
        mesh: rendered,
        output: grid,
        offset: tessellated.floatsPerPatch,
      );
      expect(grid.take(tessellated.floatsPerPatch), everyElement(0));
      expect(grid[tessellated.floatsPerPatch], rendered.vertices[0].p.dx);
    });

    test('builds vertices with and without 16 bit indices', () {
      for (final tessellation in [12, 300]) {
        final tessellated = TessellatedMesh(tessellation: tessellation);
        expect(
          () => tessellated.getTessellatedVerticesForPatch(
            cornerIndices: const [0, 1, 3, 4],
            verticesMesh: rendered,
            textureMesh: rendered,
            tessellation: tessellation,
          ).dispose(),
          returnsNormally,
        );
      }
    });
  });
}
