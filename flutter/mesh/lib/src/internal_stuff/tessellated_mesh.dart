// Internal API, not meant to be used directly by package users.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;

import 'package:mesh/internal_stuff.dart';

class TessellatedMesh {
  TessellatedMesh({
    required this.tessellation,
  })  : assert(tessellation > 0, 'tessellation must be positive'),
        _weights = _BernsteinWeights(tessellation),
        _indices = _gridIndices(tessellation),
        _positions = Float32List((tessellation + 1) * (tessellation + 1) * 2),
        _textureCoordinates =
            Float32List((tessellation + 1) * (tessellation + 1) * 2);

  final int tessellation;

  final _BernsteinWeights _weights;
  final Uint16List? _indices;
  final Float32List _positions;
  final Float32List _textureCoordinates;

  int get floatsPerPatch => _positions.length;

  void writePatchGrid({
    required List<int> cornerIndices,
    required RenderedOMeshRect mesh,
    required Float32List output,
    int offset = 0,
  }) {
    final vertices = mesh.vertices;
    _writeGrid(
      vertices[cornerIndices[0]],
      vertices[cornerIndices[1]],
      vertices[cornerIndices[2]],
      vertices[cornerIndices[3]],
      output,
      offset,
    );
  }

  Vertices getVerticesForPatch({
    required List<int> cornerIndices,
    required RenderedOMeshRect verticesMesh,
    required Float32List textureCoordinates,
  }) {
    writePatchGrid(
      cornerIndices: cornerIndices,
      mesh: verticesMesh,
      output: _positions,
    );

    final indices = _indices;
    if (indices != null) {
      return Vertices.raw(
        VertexMode.triangles,
        _positions,
        textureCoordinates: textureCoordinates,
        indices: indices,
      );
    }

    return Vertices.raw(
      VertexMode.triangles,
      _expandTriangles(_positions),
      textureCoordinates: _expandTriangles(textureCoordinates),
    );
  }

  /// Returns a [Vertices] object with the given
  /// [cornerIndices], [verticesMesh], [textureMesh],
  /// and [tessellation].
  Vertices getTessellatedVerticesForPatch({
    required List<int> cornerIndices,
    required RenderedOMeshRect verticesMesh,
    required RenderedOMeshRect textureMesh,
    required int tessellation,
  }) {
    assert(
      tessellation == this.tessellation,
      'tessellation must match the one this mesh was created with',
    );
    writePatchGrid(
      cornerIndices: cornerIndices,
      mesh: textureMesh,
      output: _textureCoordinates,
    );
    return getVerticesForPatch(
      cornerIndices: cornerIndices,
      verticesMesh: verticesMesh,
      textureCoordinates: _textureCoordinates,
    );
  }

  // This is the hottest function in the animated mesh gradient example.
  void _writeGrid(
    RenderedOVertex topLeft,
    RenderedOVertex topRight,
    RenderedOVertex bottomLeft,
    RenderedOVertex bottomRight,
    Float32List output,
    int offset,
  ) {
    // Thanks mr Paul de Casteljau
    final tlx = topLeft.p.dx;
    final tly = topLeft.p.dy;
    final trx = topRight.p.dx;
    final try_ = topRight.p.dy;
    final blx = bottomLeft.p.dx;
    final bly = bottomLeft.p.dy;
    final brx = bottomRight.p.dx;
    final bry = bottomRight.p.dy;

    final tlex = topLeft.east.dx;
    final tley = topLeft.east.dy;
    final trwx = topRight.west.dx;
    final trwy = topRight.west.dy;
    final blex = bottomLeft.east.dx;
    final bley = bottomLeft.east.dy;
    final brwx = bottomRight.west.dx;
    final brwy = bottomRight.west.dy;

    final tlsx = topLeft.south.dx - tlx;
    final tlsy = topLeft.south.dy - tly;
    final trsx = topRight.south.dx - trx;
    final trsy = topRight.south.dy - try_;
    final blnx = bottomLeft.north.dx - blx;
    final blny = bottomLeft.north.dy - bly;
    final brnx = bottomRight.north.dx - brx;
    final brny = bottomRight.north.dy - bry;

    final w = _weights;
    final side = tessellation + 1;
    for (var col = 0; col < side; col++) {
      final u = w.t[col];
      final mu = 1.0 - u;
      final u0 = w.b0[col];
      final u1 = w.b1[col];
      final u2 = w.b2[col];
      final u3 = w.b3[col];

      final topX = u0 * tlx + u1 * tlex + u2 * trwx + u3 * trx;
      final topY = u0 * tly + u1 * tley + u2 * trwy + u3 * try_;
      final bottomX = u0 * blx + u1 * blex + u2 * brwx + u3 * brx;
      final bottomY = u0 * bly + u1 * bley + u2 * brwy + u3 * bry;
      final topControlX = tlsx * mu + trsx * u + topX;
      final topControlY = tlsy * mu + trsy * u + topY;
      final bottomControlX = blnx * mu + brnx * u + bottomX;
      final bottomControlY = blny * mu + brny * u + bottomY;

      for (var row = 0; row < side; row++) {
        final v0 = w.b0[row];
        final v1 = w.b1[row];
        final v2 = w.b2[row];
        final v3 = w.b3[row];
        final i = offset + (row * side + col) * 2;
        output[i] =
            v0 * topX + v1 * topControlX + v2 * bottomControlX + v3 * bottomX;
        output[i + 1] =
            v0 * topY + v1 * topControlY + v2 * bottomControlY + v3 * bottomY;
      }
    }
  }

  Float32List _expandTriangles(Float32List grid) {
    final side = tessellation + 1;
    final output = Float32List(tessellation * tessellation * 12);
    var o = 0;
    for (var row = 0; row < tessellation; row++) {
      for (var col = 0; col < tessellation; col++) {
        final topLeft = row * side + col;
        for (final point in [
          topLeft, topLeft + 1, topLeft + side + 1, //
          topLeft, topLeft + side, topLeft + side + 1, //
        ]) {
          output[o++] = grid[point * 2];
          output[o++] = grid[point * 2 + 1];
        }
      }
    }
    return output;
  }

  static Uint16List? _gridIndices(int tessellation) {
    final side = tessellation + 1;
    if (side * side > 1 << 16) return null;

    final indices = Uint16List(tessellation * tessellation * 6);
    var i = 0;
    for (var row = 0; row < tessellation; row++) {
      for (var col = 0; col < tessellation; col++) {
        final topLeft = row * side + col;
        indices
          ..[i++] = topLeft
          ..[i++] = topLeft + 1
          ..[i++] = topLeft + side + 1
          ..[i++] = topLeft
          ..[i++] = topLeft + side
          ..[i++] = topLeft + side + 1;
      }
    }
    return indices;
  }
}

class _BernsteinWeights {
  _BernsteinWeights(int tessellation)
      : t = Float64List(tessellation + 1),
        b0 = Float64List(tessellation + 1),
        b1 = Float64List(tessellation + 1),
        b2 = Float64List(tessellation + 1),
        b3 = Float64List(tessellation + 1) {
    for (var i = 0; i <= tessellation; i++) {
      final step = i / tessellation;
      final mt = 1.0 - step;
      t[i] = step;
      b0[i] = mt * mt * mt;
      b1[i] = mt * mt * step * 3;
      b2[i] = mt * step * step * 3;
      b3[i] = step * step * step;
    }
  }

  final Float64List t;
  final Float64List b0;
  final Float64List b1;
  final Float64List b2;
  final Float64List b3;
}
