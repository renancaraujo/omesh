import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh/src/internal_stuff/color_mixer.dart';

void main() {
  group('$OMeshRectColorMixer', () {
    test('getVertexColor', () {
      final mesh = OMeshRect(
        width: 3,
        height: 3,
        vertices: [
          (0, 0).v, (.5, 0).v, (1, 0).v, //
          (0, .5).v, (.5, .5).v, (1, .5).v, //
          (0, 1).v, (.5, 1).v, (1, 1).v, //
        ],
        colors: const [
          Color(0xFF00FF00), null, Color(0xFFFFFF00), //
          null, null, null, //
          Color(0xFF00FFFF), null, null, //
        ],
        fallbackColor: const Color(0xFF000000),
      );

      final mixer = OMeshRectColorMixer(mesh);
      expect(
        mixer.getVertexColor(0),
        (const Color.from(alpha: 1, red: 0, green: 1, blue: 0), true),
      );
      expect(
        mixer.getVertexColor(1),
        (const Color.from(alpha: 1, red: .5, green: 1, blue: 0), false),
      );
      expect(
        mixer.getVertexColor(2),
        (const Color.from(alpha: 1, red: 1, green: 1, blue: 0), true),
      );

      expect(
        mixer.getVertexColor(3),
        (const Color.from(alpha: 1, red: 0, green: 1, blue: .5), false),
      );
      expect(
        mixer.getVertexColor(4),
        (const Color.from(alpha: 1, red: .25, green: .75, blue: .25), false),
      );
      expect(
        mixer.getVertexColor(5),
        (const Color.from(alpha: 1, red: .5, green: .5, blue: 0), false),
      );

      expect(
        mixer.getVertexColor(6),
        (const Color.from(alpha: 1, red: 0, green: 1, blue: 1), true),
      );
      expect(
        mixer.getVertexColor(7),
        (const Color.from(alpha: 1, red: 0, green: .5, blue: 0.5), false),
      );
      expect(
        mixer.getVertexColor(8),
        (const Color.from(alpha: 1, red: 0, green: 0, blue: 0), false),
      );
    });
  });
}
