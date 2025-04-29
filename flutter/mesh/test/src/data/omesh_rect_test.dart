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
            // Converted from Color(0xFF000000)
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          // Converted from Color(0xFF0000FF)
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
          // Converted from Color(0xFF00FF00)
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
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
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
        ]);
        expect(
          mesh.fallbackColor,
          const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
        );
        expect(
          mesh.backgroundColor,
          const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
        );
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
        );
        // Converted from Color(0x00000000)
        expect(
          mesh.fallbackColor,
          null,
        );
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
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
        ],
        fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
        backgroundColor: const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
          colorSpace: OMeshColorSpace.xyY,
          // smoothColors not provided defaults to true in this case.
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
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
        ],
        fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
        backgroundColor: const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
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
            Color.from(alpha: 1, red: 1, green: 1, blue: 1),
            Color.from(alpha: 1, red: 1, green: 1, blue: 1),
            Color.from(alpha: 1, red: 1, green: 1, blue: 1),
            Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          backgroundColor:
              const Color.from(alpha: 1, red: 1, green: 1, blue: 0),
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
          // Converted from Color(0xff7f7f7f)
          Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
          Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
          Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
          Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
        ]);
        // Converted from Color(0xff7f7fff)
        expect(
          lerp.fallbackColor,
          const Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 1),
        );
        // Converted from Color(0xff7fff00)
        expect(
          lerp.backgroundColor,
          const Color.from(alpha: 1, red: 0.5, green: 1, blue: 0),
        );
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
        );

        final changed = mesh.setFallbackColor(
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );

        expect(
          changed.fallbackColor,
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
        );

        final changed = mesh.setBackgroundColor(
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );

        expect(
          changed.backgroundColor,
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        );
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        final changed = mesh.setColors([
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        ]);

        expect(changed.colors, const [
          Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          Color.from(alpha: 1, red: 1, green: 1, blue: 1),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          fallbackColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 1),
          backgroundColor:
              const Color.from(alpha: 1, red: 0, green: 1, blue: 0),
          colorSpace: OMeshColorSpace.xyY,
          smoothColors: false,
        );

        final changed = mesh.setColor(
          const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          onIndex: 0,
        );

        expect(changed.colors, const [
          Color.from(alpha: 1, red: 1, green: 1, blue: 1),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          Color.from(alpha: 1, red: 0, green: 0, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
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
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
            Color.from(alpha: 1, red: 0, green: 0, blue: 0),
          ],
          smoothColors: false,
        );

        final changed = mesh.setSmoothColors(true);

        expect(changed.smoothColors, true);
      });
    });
  });
}
