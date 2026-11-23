import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_value/cached_value.dart';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter/rendering.dart'
    show BlendMode, Canvas, Color, Paint, Rect;

import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

/// A class that draws a [OMeshRect] into a [Canvas].
///
/// Useful to render mesh gradients outside of widget contexts, such as
/// custom paints, flame engine components, and render objects.
///
/// A tessellation below [minTessellation] fails an assertion in debug mode.
/// In release mode it is painted with [minTessellation]. A tessellation above
/// [maxTessellation] is painted with [maxTessellation], and warns once per
/// value in debug mode.
///
/// Dither works as on [OMeshGradient]:
///
/// ```dart
/// final provider = await OMeshShaderProvider.load();
/// final meshPaint = OMeshRectPaint(
///   shaderProvider: provider,
///   meshRect: mesh,
///   tessellation: 12,
///   debugMode: null,
///   dither: true,
/// );
///
/// // In a paint method:
/// meshPaint.paint(canvas, Offset.zero & size);
/// ```
class OMeshRectPaint {
  /// Creates a new [OMeshRectPaint] with the given [shaderProvider]
  /// and [meshRect],
  OMeshRectPaint({
    required this.shaderProvider,
    required OMeshRect meshRect,
    required int tessellation,
    required DebugMode? debugMode,
    bool dither = false,
  })  : assert(
          tessellation >= minTessellation,
          'tessellation must be at least $minTessellation',
        ),
        _debugMode = debugMode,
        _tessellation = tessellation,
        _meshRect = meshRect,
        _dither = dither {
    _debugWarnAboveMax(tessellation);
  }

  /// The smallest tessellation a mesh can be painted with.
  static const minTessellation = 1;

  /// The largest tessellation a mesh is painted with. Higher values are
  /// painted with this one.
  static const maxTessellation = 30;

  /// The tessellation a mesh is painted with when given [tessellation].
  @visibleForTesting
  static int clampTessellation(int tessellation) =>
      tessellation.clamp(minTessellation, maxTessellation);

  static final _warnedTessellations = <int>{};

  static void _debugWarnAboveMax(int tessellation) {
    if (kDebugMode &&
        tessellation > maxTessellation &&
        _warnedTessellations.add(tessellation)) {
      debugPrint(
        'OMesh: tessellation $tessellation is above the maximum of '
        '$maxTessellation. Painting with $maxTessellation.',
      );
    }
  }

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

  /// The tessellation level of the mesh, from [minTessellation] up.
  ///
  /// Values above [maxTessellation] are painted with [maxTessellation].
  int get tessellation => _tessellation;
  set tessellation(int value) {
    assert(
      value >= minTessellation,
      'tessellation must be at least $minTessellation',
    );
    if (value == _tessellation) return;
    _debugWarnAboveMax(value);
    _tessellation = value;
    _needsRepaint = true;
  }

  int _tessellation;

  int get _paintedTessellation => clampTessellation(_tessellation);

  /// The enabled debug features.
  DebugMode? get debugMode => _debugMode;
  set debugMode(DebugMode? value) {
    if (value == _debugMode) return;
    _debugMode = value;
    _needsRepaint = true;
  }

  DebugMode? _debugMode;

  /// Whether to add a plus or minus one color step dither that removes
  /// banding.
  ///
  /// {@macro omesh-dither}
  bool get dither => _dither;
  set dither(bool value) {
    if (value == _dither) return;
    _dither = value;
    _needsRepaint = true;
  }

  bool _dither;

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
  late final CachedValue<(List<Color>, List<bool>)> _inferredColorsCache =
      CachedValue<(List<Color>, List<bool>)>(() {
    final colorMixer = OMeshRectColorMixer(meshRect);

    final mw = meshRect.width;
    final mh = meshRect.height;

    return Iterable.generate(
      mw * mh,
      colorMixer.getVertexColor,
    ).fold(([], []), (acc, el) {
      acc.$1.add(el.$1);
      acc.$2.add(el.$2);
      return acc;
    });
  })
          .withDependency(() => meshRect.colors)
          .withDependency(() => meshRect.smoothColors)
          .withDependency(() => meshRect.colorSpace)
          .withDependency(() => (meshRect.width, meshRect.height));

  /// A [CachedValue] that holds the tessellated mesh.
  late final CachedValue<TessellatedMesh> _tessellatedMeshCache = CachedValue(
    () => TessellatedMesh(
      tessellation: _paintedTessellation,
    ),
  ).withDependency(() => _paintedTessellation);

  Rect _paintRect = Rect.zero;

  /// How many times the texture grid was built.
  @visibleForTesting
  int debugTextureGridBuilds = 0;

  late final CachedValue<Float32List> _textureGridCache = CachedValue(() {
    debugTextureGridBuilds++;
    final tessellated = _tessellatedMeshCache.value;
    final floatsPerPatch = tessellated.floatsPerPatch;
    final textureMesh = RenderedOMeshRect(
      mesh: meshRect,
      normalizedVerticesOverride: _textureVerticesCache.value,
      rect: Rect.fromLTWH(0, 0, _paintRect.width, _paintRect.height),
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
    () => (meshRect.width, meshRect.height, _paintRect, _paintedTessellation),
  );

  /// Paints the mesh into the given [canvas] and [rect].
  void paint(Canvas canvas, Rect rect) {
    _needsRepaint = false;
    _paintRect = rect;

    // With dither on, the background is drawn inside the layer, so the
    // dithered patches are blended onto it before the only rounding to
    // 8 bits. Drawn under the layer, the layer's restore rounds a second
    // time without dither and the bands come back.
    final backgroundInLayer = dither;
    final backgroundColor = meshRect.backgroundColor;
    if (backgroundColor != null && !backgroundInLayer) {
      canvas.drawRect(rect, Paint()..color = backgroundColor);
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

    canvas.saveLayer(
      rect,
      Paint(),
    );
    if (backgroundColor != null && backgroundInLayer) {
      canvas.drawRect(rect, Paint()..color = backgroundColor);
    }

    // Draw each patch one at a time.
    for (final tuple in patches.reversed.indexed) {
      final (patchIndex, [index00, index01, index10, index11]) = tuple;

      final (colors, biases) = vertexColors;
      final patchColors = [
        colors[index00], colors[index01], //
        colors[index10], colors[index11], //
      ];
      final patchBiases = [
        biases[index00], biases[index01], //
        biases[index10], biases[index11], //
      ];

      final gradientPaint = _getShaderPaint(
        patchIndex: patchIndex,
        textureTopLeft: textureVertices[index00],
        textureBottomRight: textureVertices[index11],
        patchColors: patchColors,
        patchBiases: patchBiases,
        rect: rect,
      );

      final gridOffset = (patches.length - 1 - patchIndex) * floatsPerPatch;
      final vertices = tessellated.getVerticesForPatch(
        cornerIndices: [
          index00, index01, //
          index10, index11, //
        ],
        verticesMesh: verticesMesh,
        textureCoordinates: Float32List.sublistView(
          textureGrid,
          gridOffset,
          gridOffset + floatsPerPatch,
        ),
      );

      try {
        canvas.drawVertices(
          vertices,
          BlendMode.srcOver,
          gradientPaint,
        );
      } finally {
        vertices.dispose();
      }
    }
    canvas.restore();
  }

  Paint _getShaderPaint({
    required int patchIndex,
    required OVertex textureTopLeft,
    required OVertex textureBottomRight,
    required List<Color> patchColors,
    required List<bool> patchBiases,
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
            ..setColorsWide(patchColors)
            ..setBools(patchBiases)
            ..setColorSpace(meshRect.colorSpace)
            ..setFloat(
              debugMode?.enableDots ?? false
                  ? _paintedTessellation.toDouble()
                  : 0.0,
            )
            ..setFloat(dither ? 1.0 : 0.0),
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

  void setColor(Color color) {
    final multiplier = color.a;

    setFloat(color.r * multiplier);
    setFloat(color.g * multiplier);
    setFloat(color.b * multiplier);
    setFloat(color.a);
  }

  void setColorsWide(List<Color> colors) {
    colors.forEach(setColor);
  }
}
