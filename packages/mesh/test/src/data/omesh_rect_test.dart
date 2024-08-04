import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

void main() {
  group('$OMeshRect', () {
    group('constructors', () {
      test('creates an OMeshRect instance', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
          backgroundColor: const Color(0xFF00FF00),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        expect(mesh.width, 2);
        expect(mesh.height, 2);
        expect(mesh.vertices, [
          OVertex(0, 0),
          OVertex(1, 0),
          OVertex(0, 1),
          OVertex(1, 1),
        ]);
        expect(mesh.colors, const [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
        ]);
        expect(mesh.fallbackColor, const Color(0xFF0000FF));
        expect(mesh.backgroundColor, const Color(0xFF00FF00));
        expect(mesh.colorSpace, OMeshColorSpace.xyY);
        expect(mesh.smoothColors, false);
      });

      test('default values', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
        );
        expect(mesh.fallbackColor, const Color(0x00000000));
        expect(mesh.backgroundColor, null);
        expect(mesh.colorSpace, OMeshColorSpace.lab);
        expect(mesh.smoothColors, true);
      });
    });

    group('equals', () {
      final mesh = OMeshRect(
        width: 2,
        height: 2,
        vertices: [
          OVertex(0, 0),
          OVertex(1, 0),
          OVertex(0, 1),
          OVertex(1, 1),
        ],
        colors: const [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
        ],
        fallbackColor: const Color(0xFF0000FF),
        backgroundColor: const Color(0xFF00FF00),
        colorSpace: OMeshColorSpace.xyY,
        smoothColors: false,
      );

      test('returns true if the meshes are equal', () {
        final mesh2 = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
          backgroundColor: const Color(0xFF00FF00),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        expect(mesh == mesh2, true);
      });

      test('returns false if the meshes are not equal', () {
        final mesh2 = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
          backgroundColor: const Color(0xFF00FF00),
          colorSpace: OMeshColorSpace.xyY,
        );

        expect(mesh == mesh2, false);
      });
    });

    group('lerp', () {
      final mesh = OMeshRect(
        width: 2,
        height: 2,
        vertices: [
          OVertex(0, 0),
          OVertex(1, 0),
          OVertex(0, 1),
          OVertex(1, 1),
        ],
        colors: const [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
        ],
        fallbackColor: const Color(0xFF0000FF),
        backgroundColor: const Color(0xFF00FF00),
        colorSpace: OMeshColorSpace.xyY,
        smoothColors: false,
      );

      test('returns a mesh with the interpolated values', () {
        final mesh2 = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(1, 1),
            OVertex(2, 1),
            OVertex(1, 2),
            OVertex(2, 2),
          ],
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
          fallbackColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFFFFFF00),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        final lerp = OMeshRect.lerp(mesh, mesh2, 0.5);

        expect(lerp.width, 2);
        expect(lerp.height, 2);
        expect(lerp.vertices, [
          OVertex(0.5, 0.5),
          OVertex(1.5, 0.5),
          OVertex(0.5, 1.5),
          OVertex(1.5, 1.5),
        ]);
        expect(lerp.colors, const [
          Color(0xff7f7f7f),
          Color(0xff7f7f7f),
          Color(0xff7f7f7f),
          Color(0xff7f7f7f),
        ]);
        expect(lerp.fallbackColor, const Color(0xff7f7fff));
        expect(lerp.backgroundColor, const Color(0xff7fff00));
        expect(lerp.colorSpace, OMeshColorSpace.xyY);
        expect(lerp.smoothColors, false);
      });
    });

    group('setters', () {
      test('setVertices', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
        );

        final changed = mesh.setVertices([
          OVertex(1, 1),
          OVertex(2, 1),
          OVertex(1, 2),
          OVertex(2, 2),
        ]);

        expect(changed.vertices, [
          OVertex(1, 1),
          OVertex(2, 1),
          OVertex(1, 2),
          OVertex(2, 2),
        ]);
      });

      test('setVertex', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
        );

        final changed = mesh.setVertex(OVertex(1, 1), onIndex: 0);

        expect(changed.vertices, [
          OVertex(1, 1),
          OVertex(1, 0),
          OVertex(0, 1),
          OVertex(1, 1),
        ]);
      });

      test('setFallbackColor', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
        );

        final changed = mesh.setFallbackColor(const Color(0xFFFFFFFF));

        expect(changed.fallbackColor, const Color(0xFFFFFFFF));
      });

      test('setBackgroundColor', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          backgroundColor: const Color(0xFF00FF00),
        );

        final changed = mesh.setBackgroundColor(const Color(0xFFFFFFFF));

        expect(changed.backgroundColor, const Color(0xFFFFFFFF));
      });

      test('setColors', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
          backgroundColor: const Color(0xFF00FF00),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        final changed = mesh.setColors([
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
        ]);

        expect(changed.colors, const [
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ]);
      });

      test('setColor', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          fallbackColor: const Color(0xFF0000FF),
          backgroundColor: const Color(0xFF00FF00),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        final changed = mesh.setColor(const Color(0xFFFFFFFF), onIndex: 0);

        expect(changed.colors, const [
          Color(0xFFFFFFFF),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFF000000),
        ]);
      });

      test('setColorSpace', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          colorSpace: OMeshColorSpace.xyY,
        );

        final changed = mesh.setColorSpace(OMeshColorSpace.lab);

        expect(changed.colorSpace, OMeshColorSpace.lab);
      });

      test('setSmoothColors', () {
        final mesh = OMeshRect(
          width: 2,
          height: 2,
          vertices: [
            OVertex(0, 0),
            OVertex(1, 0),
            OVertex(0, 1),
            OVertex(1, 1),
          ],
          colors: const [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          smoothColors: false,
        );

        final changed = mesh.setSmoothColors(true);

        expect(changed.smoothColors, true);
      });
    });
  });
}
