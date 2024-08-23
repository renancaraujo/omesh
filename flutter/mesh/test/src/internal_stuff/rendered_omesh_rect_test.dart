import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

void main() {
  group('$RenderedOMeshRect', () {
    group('infer right positions', () {
      final mesh = OMeshRect(
        width: 3,
        height: 3,
        vertices: [
          (0, 0).v, (0.6, 0.1).v, (1, 0.0).v, //
          (0, 0.6).v, (0.4, 0.4).v, (1, 0.5).v, //
          (0.1, 1.0).v, (0.5, 1.1).v, (0.7, 1.0).v, //
        ],
        colors: const [
          null, null, null, //
          null, null, null, //
          null, null, null, //
        ],
      );

      final renderedMesh = RenderedOMeshRect(
        mesh: mesh,
        rect: Offset.zero & const Size(1000, 1000),
      );

      const epsilon = 0.002;

      test('keeps metsh', () {
        expect(renderedMesh.mesh, mesh);
      });

      test('vertex: 0', () {
        expect(renderedMesh.vertices[0].p.dx, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].p.dy, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].north.dx, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].north.dy, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].east.dx, closeTo(182.383, epsilon));
        expect(renderedMesh.vertices[0].east.dy, closeTo(6.026, epsilon));
        expect(renderedMesh.vertices[0].south.dx, closeTo(0.001, epsilon));
        expect(renderedMesh.vertices[0].south.dy, closeTo(180.0, epsilon));
      });

      test('vertex: 1', () {
        expect(renderedMesh.vertices[1].p.dx, closeTo(600, epsilon));
        expect(renderedMesh.vertices[1].p.dy, closeTo(100, epsilon));
        expect(renderedMesh.vertices[1].north.dx, closeTo(600.0, epsilon));
        expect(renderedMesh.vertices[1].north.dy, closeTo(100.0, epsilon));
        expect(renderedMesh.vertices[1].east.dx, closeTo(723.544, epsilon));
        expect(renderedMesh.vertices[1].east.dy, closeTo(93.941, epsilon));
        expect(renderedMesh.vertices[1].south.dx, closeTo(587.308, epsilon));
        expect(renderedMesh.vertices[1].south.dy, closeTo(207.419, epsilon));
      });

      test('vertex: 2', () {
        expect(renderedMesh.vertices[2].p.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].p.dy, closeTo(0, epsilon));
        expect(renderedMesh.vertices[2].north.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].north.dy, closeTo(0, epsilon));
        expect(renderedMesh.vertices[2].east.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].east.dy, closeTo(0.0, epsilon));
        expect(renderedMesh.vertices[2].south.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].south.dy, closeTo(150.0, epsilon));
      });

      test('vertex: 3', () {
        expect(renderedMesh.vertices[3].p.dx, closeTo(0, epsilon));
        expect(renderedMesh.vertices[3].p.dy, closeTo(600, epsilon));
        expect(renderedMesh.vertices[3].north.dx, closeTo(0, epsilon));
        expect(renderedMesh.vertices[3].north.dy, closeTo(420.0, epsilon));
        expect(renderedMesh.vertices[3].east.dx, closeTo(133.587, epsilon));
        expect(renderedMesh.vertices[3].east.dy, closeTo(587.576, epsilon));
        expect(renderedMesh.vertices[3].south.dx, closeTo(6.058, epsilon));
        expect(renderedMesh.vertices[3].south.dy, closeTo(723.544, epsilon));
      });

      test('vertex: 4', () {
        expect(renderedMesh.vertices[4].p.dx, closeTo(400, epsilon));
        expect(renderedMesh.vertices[4].p.dy, closeTo(400, epsilon));
        expect(renderedMesh.vertices[4].north.dx, closeTo(412.691, epsilon));
        expect(renderedMesh.vertices[4].north.dy, closeTo(292.580, epsilon));
        expect(renderedMesh.vertices[4].east.dx, closeTo(582.383, epsilon));
        expect(renderedMesh.vertices[4].east.dy, closeTo(406.026, epsilon));
        expect(renderedMesh.vertices[4].south.dx, closeTo(406.019, epsilon));
        expect(renderedMesh.vertices[4].south.dy, closeTo(612.046, epsilon));
      });

      test('vertex: 5', () {
        expect(renderedMesh.vertices[5].p.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].p.dy, closeTo(500, epsilon));
        expect(renderedMesh.vertices[5].north.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].north.dy, closeTo(350.0, epsilon));
        expect(renderedMesh.vertices[5].east.dx, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].east.dy, closeTo(500, epsilon));
        expect(renderedMesh.vertices[5].south.dx, closeTo(981.129, epsilon));
        expect(renderedMesh.vertices[5].south.dy, closeTo(673.907, epsilon));
      });

      test('vertex: 6', () {
        expect(renderedMesh.vertices[6].p.dx, closeTo(100, epsilon));
        expect(renderedMesh.vertices[6].p.dy, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[6].north.dx, closeTo(93.941, epsilon));
        expect(renderedMesh.vertices[6].north.dy, closeTo(876.455, epsilon));
        expect(renderedMesh.vertices[6].east.dx, closeTo(223.544, epsilon));
        expect(renderedMesh.vertices[6].east.dy, closeTo(1006.057, epsilon));
        expect(renderedMesh.vertices[6].south.dx, closeTo(100, epsilon));
        expect(renderedMesh.vertices[6].south.dy, closeTo(1000, epsilon));
      });

      test('vertex: 7', () {
        expect(renderedMesh.vertices[7].p.dx, closeTo(500, epsilon));
        expect(renderedMesh.vertices[7].p.dy, closeTo(1100, epsilon));
        expect(renderedMesh.vertices[7].north.dx, closeTo(493.980, epsilon));
        expect(renderedMesh.vertices[7].north.dy, closeTo(887.953, epsilon));
        expect(renderedMesh.vertices[7].east.dx, closeTo(566.793, epsilon));
        expect(renderedMesh.vertices[7].east.dy, closeTo(1093.788, epsilon));
        expect(renderedMesh.vertices[7].south.dx, closeTo(500, epsilon));
        expect(renderedMesh.vertices[7].south.dy, closeTo(1100, epsilon));
      });

      test('vertex: 8', () {
        expect(renderedMesh.vertices[8].p.dx, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].p.dy, closeTo(1000.0, epsilon));
        expect(renderedMesh.vertices[8].north.dx, closeTo(718.870, epsilon));
        expect(renderedMesh.vertices[8].north.dy, closeTo(826.092, epsilon));
        expect(renderedMesh.vertices[8].east.dx, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].east.dy, closeTo(1000.0, epsilon));
        expect(renderedMesh.vertices[8].south.dx, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].south.dy, closeTo(1000.0, epsilon));
      });
    });
  });
}
