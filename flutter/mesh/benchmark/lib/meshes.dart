import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:mesh/mesh.dart';

OMeshRect exampleMesh(double t) {
  OVertex v(double x0, double y0, double x1, double y1, [double? at]) {
    return OVertex(x0, y0).lerpTo(OVertex(x1, y1), at ?? t);
  }

  Color? c(Color a, Color b) => Color.lerp(a, b, t);
  final t2 = t * t;

  return OMeshRect(
    width: 3,
    height: 4,
    fallbackColor: const Color(0x00000000),
    vertices: [
      v(0, 0.3, 0, 0), v(0.5, 0.15, 0.5, 0.1, t2), v(1, -0.1, 1, 0.3, t2), //
      v(-0.05, 0.68, 0, 0.45), v(0.63, 0.3, 0.48, 0.54), v(1, 0.1, 1, 0.6), //
      v(-0.2, 0.92, 0, 0.58), v(0.32, 0.72, 0.58, 0.69, t2), v(1, 0.3, 1, 0.8),
      v(0, 1.2, 0, 0.86), v(0.5, 0.88, 0.5, 0.95), v(1, 0.82, 1, 1), //
    ],
    colors: [
      null, null, null, //
      c(const Color(0xCCFF9800), const Color(0xFF0A217A)),
      c(const Color(0xCCFFCC80), const Color(0xFC6730CD)),
      c(const Color(0xE6FFA726), const Color(0xFC673580)), //
      c(const Color(0xFFE65100), const Color(0xE0353536)),
      c(const Color(0xFAEF6C00), const Color(0xFF6730CD)),
      c(const Color(0xFFE65100), const Color(0xFF53007C)), //
      null, null, null, //
    ],
  );
}

OMeshRect denseMesh(
  double t, {
  int size = 10,
  OMeshColorSpace colorSpace = OMeshColorSpace.lab,
}) {
  final phase = t * 2 * math.pi;
  final step = 1 / (size - 1);
  return OMeshRect(
    width: size,
    height: size,
    colorSpace: colorSpace,
    vertices: [
      for (var row = 0; row < size; row++)
        for (var col = 0; col < size; col++)
          _denseVertex(row, col, size, step, phase),
    ],
    colors: [
      for (var row = 0; row < size; row++)
        for (var col = 0; col < size; col++)
          HSVColor.fromAHSV(
            1,
            (col * 25 + row * 15 + t * 360) % 360,
            0.75,
            0.95,
          ).toColor(),
    ],
  );
}

OVertex _denseVertex(int row, int col, int size, double step, double phase) {
  final edge = row == 0 || col == 0 || row == size - 1 || col == size - 1;
  final x = col * step + (edge ? 0 : math.sin(phase + row * 0.7) * step / 4);
  final y = row * step + (edge ? 0 : math.cos(phase + col * 0.9) * step / 4);
  final vertex = OVertex(x, y);
  if (edge || (row * size + col).isOdd) return vertex;
  return vertex.bezier(
    east: OVertex(x + step / 2, y + step / 8),
    west: OVertex(x - step / 2, y - step / 8),
  );
}

OMeshRect transparentMesh({OMeshColorSpace colorSpace = OMeshColorSpace.xyY}) {
  return OMeshRect(
    width: 4,
    height: 4,
    colorSpace: colorSpace,
    fallbackColor: const Color(0x00000000),
    backgroundColor: const Color(0xFFFFFFFF),
    vertices: [
      for (var i = 0; i < 16; i++) OVertex(i % 4 / 3, i ~/ 4 / 3),
    ],
    colors: const [
      null, Color(0xFF2196F3), Color(0x802196F3), null, //
      Color(0xFF000000), Color(0xFFE91E63), Color(0xFFFFEB3B), null,
      Color(0x00FF0000), Color(0xFF4CAF50), Color(0xFF000000), null, //
      null, Color(0x00000000), Color(0xFF9C27B0), null, //
    ],
  );
}
