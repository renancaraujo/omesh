import 'dart:ui';

import 'package:cached_value/cached_value.dart';
import 'package:flutter/rendering.dart'
    show BlendMode, Canvas, Color, Paint, Rect;
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

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
    required this.impellerCompatibilityMode,
  })  : _debugMode = debugMode,
        _tessellation = tessellation,
        _meshRect = meshRect;

  /// The shader provider instance associated with this paint.
  final OMeshShaderProvider shaderProvider;

  /// Enable compatibility mode for impeller runtime.
  /// See [OMeshGradient.impellerCompatibilityMode] for more information.
  final bool impellerCompatibilityMode;

  /// The guiding mesh to be rendered.
  OMeshRect get meshRect => _meshRect;
  set meshRect(OMeshRect value) {
    if (value == _meshRect) return;
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
  late final textureVerticesCache = CachedValue(
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
  late final patchesCache = CachedValue(() {
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
          (x, y), (x + 1, y), //
          (x, y + 1), (x + 1, y + 1), //
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
  late final inferredColorsCache = CachedValue(() {
    final colorMixer = OMeshRectColorMixer(meshRect);

    final mw = meshRect.width;
    final mh = meshRect.height;

    return List.generate(
      growable: false,
      mw * mh,
      colorMixer.getVertexColor,
    );
  }).withDependency(() => meshRect);

  /// A [CachedValue] that holds the tessellated mesh.
  late final tessellatedMeshCache = CachedValue(
    () => TessellatedMesh(
      tessellation: tessellation,
    ),
  ).withDependency(() => tessellation);

  /// Paints the mesh into the given [canvas] and [rect].
  void paint(Canvas canvas, Rect rect) {
    _needsRepaint = false;

    // Background color
    if (meshRect.backgroundColor != null) {
      canvas.drawRect(
        rect,
        Paint()..color = meshRect.backgroundColor!,
      );
    }

    // some shorthan helpers
    final mw = meshRect.width;
    final mh = meshRect.height;

    // Extract the current texture vertices, patches and vertex colors
    // from the caches.
    final textureVertices = textureVerticesCache.value;
    final patches = patchesCache.value;
    final vertexColors = inferredColorsCache.value;

    // Denormalize the vertices and infer control points.
    final verticesMesh = RenderedOMeshRect(
      mesh: meshRect,
      rect: rect,
    );
    final textureMesh = RenderedOMeshRect(
      mesh: meshRect,
      normalizedVertices: textureVertices,
      rect: rect,
    );

    canvas.saveLayer(
      rect,
      Paint(),
    );

    // Draw each patch one at a time.
    for (final tuple in patches.reversed.indexed) {
      final (patchIndex, patch) = tuple;

      // tl
      final index00 = patch[0].onGrid(mw, mh);
      // tr
      final index01 = patch[1].onGrid(mw, mh);
      // bl
      final index10 = patch[2].onGrid(mw, mh);
      // br
      final index11 = patch[3].onGrid(mw, mh);

      final patchIndices = [
        index00, index01, //
        index10, index11, //
      ];

      final (colors, biases) = [
        vertexColors[index00], vertexColors[index01], //
        vertexColors[index10], vertexColors[index11], //
      ].fold<(List<Color>, List<bool>)>(([], []), (acc, el) {
        acc.$1.add(el.$1);
        acc.$2.add(el.$2);
        return acc;
      });

      final paintShader = Paint()
        ..shader = (shaderProvider.getShaderFor(patchIndex)
          ..setFloatUniforms(
            (s) => s
              ..setSize(rect.size)
              ..setVector(textureVertices[index00])
              ..setVector(textureVertices[index11])
              ..setColorsWide(colors)
              ..setBools(biases)
              ..setColorSpace(meshRect.colorSpace)
              ..setFloat(
                debugMode?.enableDots ?? false ? tessellation.toDouble() : 0.0,
              ),
          ));

      final vertices =
          tessellatedMeshCache.value.getTessellatedVerticesForPatch(
        size: rect.size,
        cornerIndices: patchIndices,
        verticesMesh: verticesMesh,
        textureMesh: textureMesh,
        tessellation: tessellation,
        impellerCompatibilityMode: impellerCompatibilityMode,
      );

      canvas.drawVertices(
        vertices,
        BlendMode.srcOver,
        paintShader,
      );
    }
    canvas.restore();
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

  void setColorWide(Color color) {
    final multiplier = color.opacity;

    setFloat(color.red / 255 * multiplier);
    setFloat(color.green / 255 * multiplier);
    setFloat(color.blue / 255 * multiplier);
    setFloat(color.opacity);
  }

  void setColorsWide(List<Color> colors) {
    for (final color in colors) {
      setColorWide(color);
    }
  }
}
