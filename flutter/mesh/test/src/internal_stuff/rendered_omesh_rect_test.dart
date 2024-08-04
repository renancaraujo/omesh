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
        expect(renderedMesh.vertices[0].p.x, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].p.y, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].north.x, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].north.y, closeTo(0, epsilon));
        expect(renderedMesh.vertices[0].east.x, closeTo(182.383, epsilon));
        expect(renderedMesh.vertices[0].east.y, closeTo(6.026, epsilon));
        expect(renderedMesh.vertices[0].south.x, closeTo(0.001, epsilon));
        expect(renderedMesh.vertices[0].south.y, closeTo(180.0, epsilon));
      });

      test('vertex: 1', () {
        expect(renderedMesh.vertices[1].p.x, closeTo(600, epsilon));
        expect(renderedMesh.vertices[1].p.y, closeTo(100, epsilon));
        expect(renderedMesh.vertices[1].north.x, closeTo(600.0, epsilon));
        expect(renderedMesh.vertices[1].north.y, closeTo(100.0, epsilon));
        expect(renderedMesh.vertices[1].east.x, closeTo(723.544, epsilon));
        expect(renderedMesh.vertices[1].east.y, closeTo(93.941, epsilon));
        expect(renderedMesh.vertices[1].south.x, closeTo(587.308, epsilon));
        expect(renderedMesh.vertices[1].south.y, closeTo(207.419, epsilon));
      });

      test('vertex: 2', () {
        expect(renderedMesh.vertices[2].p.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].p.y, closeTo(0, epsilon));
        expect(renderedMesh.vertices[2].north.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].north.y, closeTo(0, epsilon));
        expect(renderedMesh.vertices[2].east.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].east.y, closeTo(0.0, epsilon));
        expect(renderedMesh.vertices[2].south.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[2].south.y, closeTo(150.0, epsilon));
      });

      test('vertex: 3', () {
        expect(renderedMesh.vertices[3].p.x, closeTo(0, epsilon));
        expect(renderedMesh.vertices[3].p.y, closeTo(600, epsilon));
        expect(renderedMesh.vertices[3].north.x, closeTo(0, epsilon));
        expect(renderedMesh.vertices[3].north.y, closeTo(420.0, epsilon));
        expect(renderedMesh.vertices[3].east.x, closeTo(133.587, epsilon));
        expect(renderedMesh.vertices[3].east.y, closeTo(587.576, epsilon));
        expect(renderedMesh.vertices[3].south.x, closeTo(6.058, epsilon));
        expect(renderedMesh.vertices[3].south.y, closeTo(723.544, epsilon));
      });

      test('vertex: 4', () {
        expect(renderedMesh.vertices[4].p.x, closeTo(400, epsilon));
        expect(renderedMesh.vertices[4].p.y, closeTo(400, epsilon));
        expect(renderedMesh.vertices[4].north.x, closeTo(412.691, epsilon));
        expect(renderedMesh.vertices[4].north.y, closeTo(292.580, epsilon));
        expect(renderedMesh.vertices[4].east.x, closeTo(582.383, epsilon));
        expect(renderedMesh.vertices[4].east.y, closeTo(406.026, epsilon));
        expect(renderedMesh.vertices[4].south.x, closeTo(406.019, epsilon));
        expect(renderedMesh.vertices[4].south.y, closeTo(612.046, epsilon));
      });

      test('vertex: 5', () {
        expect(renderedMesh.vertices[5].p.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].p.y, closeTo(500, epsilon));
        expect(renderedMesh.vertices[5].north.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].north.y, closeTo(350.0, epsilon));
        expect(renderedMesh.vertices[5].east.x, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[5].east.y, closeTo(500, epsilon));
        expect(renderedMesh.vertices[5].south.x, closeTo(981.129, epsilon));
        expect(renderedMesh.vertices[5].south.y, closeTo(673.907, epsilon));
      });

      test('vertex: 6', () {
        expect(renderedMesh.vertices[6].p.x, closeTo(100, epsilon));
        expect(renderedMesh.vertices[6].p.y, closeTo(1000, epsilon));
        expect(renderedMesh.vertices[6].north.x, closeTo(93.941, epsilon));
        expect(renderedMesh.vertices[6].north.y, closeTo(876.455, epsilon));
        expect(renderedMesh.vertices[6].east.x, closeTo(223.544, epsilon));
        expect(renderedMesh.vertices[6].east.y, closeTo(1006.057, epsilon));
        expect(renderedMesh.vertices[6].south.x, closeTo(100, epsilon));
        expect(renderedMesh.vertices[6].south.y, closeTo(1000, epsilon));
      });

      test('vertex: 7', () {
        expect(renderedMesh.vertices[7].p.x, closeTo(500, epsilon));
        expect(renderedMesh.vertices[7].p.y, closeTo(1100, epsilon));
        expect(renderedMesh.vertices[7].north.x, closeTo(493.980, epsilon));
        expect(renderedMesh.vertices[7].north.y, closeTo(887.953, epsilon));
        expect(renderedMesh.vertices[7].east.x, closeTo(566.793, epsilon));
        expect(renderedMesh.vertices[7].east.y, closeTo(1093.788, epsilon));
        expect(renderedMesh.vertices[7].south.x, closeTo(500, epsilon));
        expect(renderedMesh.vertices[7].south.y, closeTo(1100, epsilon));
      });

      test('vertex: 8', () {
        expect(renderedMesh.vertices[8].p.x, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].p.y, closeTo(1000.0, epsilon));
        expect(renderedMesh.vertices[8].north.x, closeTo(718.870, epsilon));
        expect(renderedMesh.vertices[8].north.y, closeTo(826.092, epsilon));
        expect(renderedMesh.vertices[8].east.x, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].east.y, closeTo(1000.0, epsilon));
        expect(renderedMesh.vertices[8].south.x, closeTo(700, epsilon));
        expect(renderedMesh.vertices[8].south.y, closeTo(1000.0, epsilon));
      });
    });
  });
}
