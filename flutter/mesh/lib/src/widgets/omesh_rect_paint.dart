import 'dart:ui';

import 'package:cached_value/cached_value.dart';

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
    OMeshGrain? grain,
    double devicePixelRatio = 1.0,
  })  : _debugMode = debugMode,
        _tessellation = tessellation,
        _meshRect = meshRect,
        _grain = grain,
        _devicePixelRatio = devicePixelRatio;

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

  /// The grain, scatter and dither applied to the mesh.
  ///
  /// Null, or [OMeshGrain.none], draws the mesh exactly as without grain.
  OMeshGrain? get grain => _grain;
  set grain(OMeshGrain? value) {
    if (value == _grain) return;
    _grain = value;
    _needsRepaint = true;
  }

  OMeshGrain? _grain;

  /// The number of physical pixels per logical pixel of the target canvas.
  ///
  /// Used to draw [OMeshGrain.amount] grain at one cell per physical pixel.
  /// A canvas does not carry this value, so widgets pass
  /// `MediaQuery.devicePixelRatioOf(context)`. Defaults to 1.
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    _needsRepaint = true;
  }

  double _devicePixelRatio;

  /// The offscreen image of the mesh used to draw grain over it.
  Image? _grainImage;

  /// Releases the offscreen image used for grain.
  ///
  /// Call it when this paint is no longer used.
  void dispose() {
    _grainImage?.dispose();
    _grainImage = null;
  }

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
      tessellation: tessellation,
    ),
  ).withDependency(() => tessellation);

  /// Paints the mesh into the given [canvas] and [rect].
  void paint(Canvas canvas, Rect rect) {
    final grain = this.grain;
    final grainShader = shaderProvider.grainShader;
    final dpr = devicePixelRatio;
    final width = (rect.width * dpr).ceil();
    final height = (rect.height * dpr).ceil();
    if (grain == null ||
        grain.amount <= 0 ||
        grainShader == null ||
        width <= 0 ||
        height <= 0) {
      _paintMesh(canvas, rect);
      return;
    }

    // Visible grain: render the mesh into an image at physical resolution,
    // then draw that image through the grain shader.
    final recorder = PictureRecorder();
    _paintMesh(Canvas(recorder)..scale(dpr), Offset.zero & rect.size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    _grainImage?.dispose();
    _grainImage = image;

    grainShader
      ..setFloat(0, rect.width)
      ..setFloat(1, rect.height)
      ..setFloat(2, rect.left)
      ..setFloat(3, rect.top)
      ..setFloat(4, dpr)
      ..setFloat(5, grain.amount)
      ..setFloat(6, grain.shadows)
      ..setFloat(7, grain.midtones)
      ..setFloat(8, grain.highlights)
      ..setFloat(9, (grain.seed % 997).toDouble())
      ..setImageSampler(0, image);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = grainShader
        ..isAntiAlias = false,
    );
  }

  /// Paints the mesh itself, without visible grain, into [canvas] at [rect].
  void _paintMesh(Canvas canvas, Rect rect) {
    _needsRepaint = false;

    // With dither on, the background is drawn inside the layer, so the
    // dithered patches are blended onto it before the only rounding to
    // 8 bits. Drawn under the layer, the layer's restore rounds a second
    // time without dither and the bands come back.
    final backgroundInLayer = grain?.dither ?? false;
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
    final textureMesh = RenderedOMeshRect(
      mesh: meshRect,
      normalizedVerticesOverride: textureVertices,
      rect: rect,
    );

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

      final vertices =
          _tessellatedMeshCache.value.getTessellatedVerticesForPatch(
        cornerIndices: [
          index00, index01, //
          index10, index11, //
        ],
        verticesMesh: verticesMesh,
        textureMesh: textureMesh,
        tessellation: tessellation,
      );

      canvas.drawVertices(
        vertices,
        BlendMode.srcOver,
        gradientPaint,
      );
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
              debugMode?.enableDots ?? false ? tessellation.toDouble() : 0.0,
            )
            // Grain uniforms, in omesh.frag order: scatter, dither, seed.
            ..setFloat(grain?.scatter ?? 0)
            ..setFloat(grain?.dither ?? false ? 1.0 : 0.0)
            ..setFloat(((grain?.seed ?? 0) % 997).toDouble()),
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
