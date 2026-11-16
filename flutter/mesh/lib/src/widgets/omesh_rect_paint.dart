import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_value/cached_value.dart';

import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

/// Must match `MAX_VERTICES` in `shaders/omesh_batched.frag`.
const int _kMaxBatchedVertices = 128;

/// A class that draws a [OMeshRect] into a [Canvas].
///
/// Useful to render mesh gradients outside of widget contexts, such as
/// custom paints, flame engine components, and render objects.
class OMeshRectPaint {
  /// Creates a new [OMeshRectPaint] with the given [shaderProvider]
  /// and [meshRect],
  OMeshRectPaint({
    required this.shaderProvider,
    required OMeshRect meshRect,
    required int tessellation,
    required DebugMode? debugMode,
  })  : _debugMode = debugMode,
        _tessellation = tessellation,
        _meshRect = meshRect;

  /// The shader provider instance associated with this paint.
  final OMeshShaderProvider shaderProvider;

  /// The guiding mesh to be rendered.
  OMeshRect get meshRect => _meshRect;
  set meshRect(OMeshRect value) {
    if (value == _meshRect) {
      return;
    }
    _meshRect = value.clone();
    _needsRepaint = true;
  }

  OMeshRect _meshRect;

  /// The tessellation level of the mesh.
  int get tessellation => _tessellation;
  set tessellation(int value) {
    if (value == _tessellation) return;
    _tessellation = value;
    _needsRepaint = true;
  }

  int _tessellation;

  /// The enabled debug features.
  DebugMode? get debugMode => _debugMode;
  set debugMode(DebugMode? value) {
    if (value == _debugMode) return;
    _debugMode = value;
    _needsRepaint = true;
  }

  DebugMode? _debugMode;

  /// Whether the mesh needs to be repainted.
  bool get needsRepaint => _needsRepaint;
  bool _needsRepaint = true;

  /// Marks the mesh as needing to be repainted.
  void markNeedsRepaint() {
    _needsRepaint = true;
  }

  /// A [CachedValue] that holds the undistorted vertices of the mesh.
  ///
  /// It is dependent on the [meshRect]'s width and height.
  late final CachedValue<List<OVertex>> _textureVerticesCache = CachedValue(
    () {
      return List.generate(
        growable: false,
        meshRect.width * meshRect.height,
        (index) {
          final x = index % meshRect.width / (meshRect.width - 1);
          final y = index ~/ meshRect.width / (meshRect.height - 1);
          return OVertex(x, y);
        },
      );
    },
  ).withDependency(
    () => (
      meshRect.width,
      meshRect.height,
    ),
  );

  /// A [CachedValue] that holds the indices of vertices in groups
  /// of 4 that form a patch  of the mesh.
  ///
  /// It is dependent on the [meshRect]'s width and height.
  late final CachedValue<List<List<int>>> _patchesCache = CachedValue(() {
    final mw = meshRect.width;
    final mh = meshRect.height;
    final nRectX = mw - 1;
    final nRectY = mh - 1;

    return List.generate(
      growable: false,
      nRectX * nRectY,
      (index) {
        final y = index ~/ nRectX;
        final x = index % nRectX;

        return [
          (x, y).onGrid(mw, mh), (x + 1, y).onGrid(mw, mh), //
          (x, y + 1).onGrid(mw, mh), (x + 1, y + 1).onGrid(mw, mh), //
        ];
      },
    );
  }).withDependency(
    () => (
      meshRect.width,
      meshRect.height,
    ),
  );

  /// A [CachedValue] that holds the vertex colors of the mesh.
  ///
  /// It is dependent on the [meshRect].
  late final CachedValue<(Float32List shaderColors, List<bool> biases)>
      _inferredColorsCache =
      CachedValue<(Float32List shaderColors, List<bool> biases)>(() {
    final colorMixer = OMeshRectColorMixer(meshRect);
    final colorSpace = meshRect.colorSpace;
    final length = meshRect.width * meshRect.height;

    final shaderColors = Float32List(length * 4);
    final biases = List<bool>.filled(length, false);
    for (var index = 0; index < length; index++) {
      final (color, bias) = colorMixer.getVertexColor(index);
      colorSpace.writeShaderColor(color, shaderColors, index * 4);
      biases[index] = bias;
    }
    return (shaderColors, biases);
  })
          .withDependency(() => meshRect.colors)
          .withDependency(() => meshRect.smoothColors)
          .withDependency(() => meshRect.colorSpace)
          .withDependency(() => (meshRect.width, meshRect.height));

  /// A [CachedValue] that holds the tessellated mesh.
  late final CachedValue<TessellatedMesh> _tessellatedMeshCache = CachedValue(
    () => TessellatedMesh(
      tessellation: tessellation,
    ),
  ).withDependency(() => tessellation);

  Rect _paintRect = Rect.zero;

  /// A [CachedValue] that holds the texture coordinates of every patch.
  late final CachedValue<Float32List> _textureGridCache = CachedValue(() {
    final tessellated = _tessellatedMeshCache.value;
    final floatsPerPatch = tessellated.floatsPerPatch;
    final textureMesh = RenderedOMeshRect(
      mesh: meshRect,
      normalizedVerticesOverride: _textureVerticesCache.value,
      rect: _paintRect,
    );
    final patches = _patchesCache.value;
    final grid = Float32List(patches.length * floatsPerPatch);
    for (final (index, cornerIndices) in patches.indexed) {
      tessellated.writePatchGrid(
        cornerIndices: cornerIndices,
        mesh: textureMesh,
        output: grid,
        offset: index * floatsPerPatch,
      );
    }
    return grid;
  }).withDependency(
    () => (meshRect.width, meshRect.height, _paintRect, tessellation),
  );

  /// A [CachedValue] that holds the buffers for drawing the mesh in one call.
  late final CachedValue<_Batch> _batchCache = CachedValue(() {
    final tessellated = _tessellatedMeshCache.value;
    final floatsPerPatch = tessellated.floatsPerPatch;
    final pointsPerPatch = tessellated.pointsPerPatch;
    final patchIndices = tessellated.indices!;
    final textureGrid = _textureGridCache.value;
    final patchCount = _patchesCache.value.length;

    final textureCoordinates = Float32List(patchCount * floatsPerPatch);
    final indices = Uint16List(patchCount * patchIndices.length);
    for (var drawIndex = 0; drawIndex < patchCount; drawIndex++) {
      final patchIndex = patchCount - 1 - drawIndex;
      textureCoordinates.setRange(
        drawIndex * floatsPerPatch,
        (drawIndex + 1) * floatsPerPatch,
        textureGrid,
        patchIndex * floatsPerPatch,
      );
      final base = drawIndex * pointsPerPatch;
      final offset = drawIndex * patchIndices.length;
      for (var i = 0; i < patchIndices.length; i++) {
        indices[offset + i] = base + patchIndices[i];
      }
    }
    return (
      positions: Float32List(patchCount * floatsPerPatch),
      textureCoordinates: textureCoordinates,
      indices: indices,
    );
  }).withDependency(
    () => (meshRect.width, meshRect.height, _paintRect, tessellation),
  );

  bool get _canDrawInOneCall {
    if (shaderProvider.batchedShader == null) return false;
    if (meshRect.width * meshRect.height > _kMaxBatchedVertices) return false;
    final tessellated = _tessellatedMeshCache.value;
    if (tessellated.indices == null) return false;
    final patchCount = (meshRect.width - 1) * (meshRect.height - 1);
    return patchCount * tessellated.pointsPerPatch <= 1 << 16;
  }

  /// Paints the mesh into the given [canvas] and [rect].
  void paint(Canvas canvas, Rect rect) {
    _needsRepaint = false;
    _paintRect = rect;

    // Background color
    if (meshRect.backgroundColor != null) {
      canvas.drawRect(
        rect,
        Paint()..color = meshRect.backgroundColor!,
      );
    }

    if (_canDrawInOneCall) {
      _paintInOneCall(canvas, rect);
      return;
    }

    // Extract the current texture vertices, patches and vertex colors
    // from the caches.
    final textureVertices = _textureVerticesCache.value;
    final patches = _patchesCache.value;
    final vertexColors = _inferredColorsCache.value;

    // Denormalize the vertices and infer control points.
    final verticesMesh = RenderedOMeshRect(
      mesh: meshRect,
      rect: rect,
    );
    final tessellated = _tessellatedMeshCache.value;
    final textureGrid = _textureGridCache.value;
    final floatsPerPatch = tessellated.floatsPerPatch;

    // Draw each patch one at a time.
    for (final tuple in patches.reversed.indexed) {
      final (patchIndex, [index00, index01, index10, index11]) = tuple;

      final (shaderColors, biases) = vertexColors;
      final cornerIndices = [
        index00, index01, //
        index10, index11, //
      ];

      final gradientPaint = _getShaderPaint(
        patchIndex: patchIndex,
        textureTopLeft: textureVertices[index00],
        textureBottomRight: textureVertices[index11],
        cornerIndices: cornerIndices,
        shaderColors: shaderColors,
        biases: biases,
        rect: rect,
      );

      final gridOffset = (patches.length - 1 - patchIndex) * floatsPerPatch;
      final vertices = tessellated.getVerticesForPatch(
        cornerIndices: cornerIndices,
        verticesMesh: verticesMesh,
        textureCoordinates: Float32List.sublistView(
          textureGrid,
          gridOffset,
          gridOffset + floatsPerPatch,
        ),
      );

      canvas.drawVertices(
        vertices,
        BlendMode.srcOver,
        gradientPaint,
      );
      vertices.dispose();
    }
  }

  void _paintInOneCall(Canvas canvas, Rect rect) {
    final tessellated = _tessellatedMeshCache.value;
    final floatsPerPatch = tessellated.floatsPerPatch;
    final patches = _patchesCache.value;
    final (shaderColors, biases) = _inferredColorsCache.value;
    final batch = _batchCache.value;

    final verticesMesh = RenderedOMeshRect(mesh: meshRect, rect: rect);
    for (var drawIndex = 0; drawIndex < patches.length; drawIndex++) {
      tessellated.writePatchGrid(
        cornerIndices: patches[patches.length - 1 - drawIndex],
        mesh: verticesMesh,
        output: batch.positions,
        offset: drawIndex * floatsPerPatch,
      );
    }

    const biasesStart = _kMaxBatchedVertices * 4;
    const scalarsStart = biasesStart + _kMaxBatchedVertices;
    final colorSpaceIndex = switch (meshRect.colorSpace) {
      OMeshColorSpace.lab => 0.0,
      OMeshColorSpace.linear => 1.0,
      OMeshColorSpace.xyY => 2.0,
    };
    final shader = shaderProvider.batchedShader!;
    for (var i = 0; i < shaderColors.length; i++) {
      shader.setFloat(i, shaderColors[i]);
    }
    for (var i = 0; i < biases.length; i++) {
      shader.setFloat(biasesStart + i, biases[i] ? 1.0 : 0.0);
    }
    shader
      ..setFloat(scalarsStart, rect.width)
      ..setFloat(scalarsStart + 1, rect.height)
      ..setFloat(scalarsStart + 2, meshRect.width.toDouble())
      ..setFloat(scalarsStart + 3, meshRect.height.toDouble())
      ..setFloat(scalarsStart + 4, colorSpaceIndex)
      ..setFloat(
        scalarsStart + 5,
        debugMode?.enableDots ?? false ? tessellation.toDouble() : 0.0,
      );

    final vertices = Vertices.raw(
      VertexMode.triangles,
      batch.positions,
      textureCoordinates: batch.textureCoordinates,
      indices: batch.indices,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, Paint()..shader = shader);
    vertices.dispose();
  }

  Paint _getShaderPaint({
    required int patchIndex,
    required OVertex textureTopLeft,
    required OVertex textureBottomRight,
    required List<int> cornerIndices,
    required Float32List shaderColors,
    required List<bool> biases,
    required Rect rect,
  }) {
    return Paint()
      ..shader = (shaderProvider.getShaderFor(patchIndex)
        ..setFloatUniforms(
          (s) => s
            ..setSize(rect.size)
            ..setFloats([
              textureTopLeft.x,
              textureTopLeft.y,
            ])
            ..setFloats([
              textureBottomRight.x,
              textureBottomRight.y,
            ])
            ..setShaderColors(shaderColors, cornerIndices)
            ..setBools([for (final index in cornerIndices) biases[index]])
            ..setColorSpace(meshRect.colorSpace)
            ..setFloat(
              debugMode?.enableDots ?? false ? tessellation.toDouble() : 0.0,
            ),
        ));
  }
}

extension on (int, int) {
  int onGrid(int gridWidth, int gridHeight) {
    return $2 * gridWidth + $1;
  }
}

extension on UniformsSetter {
  void setBools(List<bool> bools) {
    for (final b in bools) {
      setFloat(b ? 1.0 : 0.0);
    }
  }

  void setColorSpace(OMeshColorSpace colorSpace) {
    setFloat(
      switch (colorSpace) {
        OMeshColorSpace.lab => 0.0,
        OMeshColorSpace.linear => 1.0,
        OMeshColorSpace.xyY => 2.0,
      },
    );
  }

  void setShaderColors(Float32List shaderColors, List<int> indices) {
    for (final index in indices) {
      for (var component = 0; component < 4; component++) {
        setFloat(shaderColors[index * 4 + component]);
      }
    }
  }
}

typedef _Batch = ({
  Float32List positions,
  Float32List textureCoordinates,
  Uint16List indices,
});
