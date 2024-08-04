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
          (0, 0).v, (0.5, 0).v, (1, 0).v, //
          (0, 0.5).v, (0.5, 0.5).v, (1, 0.5).v, //
          (0, 1).v, (0.5, 1).v, (1, 1).v, //
        ],
        colors: const [
          Color(0xFF00FF00), null, Color(0xFFFFFF00), //
          null, null, null, //
          Color(0xFF00FFFF), null, null, //
        ],
        fallbackColor: const Color(0xFF000000),
      );

      final mixer = OMeshRectColorMixer(mesh);
      expect(mixer.getVertexColor(0), (const Color(0xFF00FF00), true));
      expect(mixer.getVertexColor(1), (const Color(0xff80ff00), false));
      expect(mixer.getVertexColor(2), (const Color(0xFFFFFF00), true));

      expect(mixer.getVertexColor(3), (const Color(0xff00ff80), false));
      expect(mixer.getVertexColor(4), (const Color(0xff40c040), false));
      expect(mixer.getVertexColor(5), (const Color(0xff808000), false));

      expect(mixer.getVertexColor(6), (const Color(0xFF00FFFF), true));
      expect(mixer.getVertexColor(7), (const Color(0xff008080), false));
      expect(mixer.getVertexColor(8), (const Color(0xff000000), false));
    });
  });
}
