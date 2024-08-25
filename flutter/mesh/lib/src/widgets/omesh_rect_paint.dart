import 'dart:ui';

import 'package:cached_value/cached_value.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/rendering.dart'
    show
        Alignment,
        BlendMode,
        BoxConstraints,
        Canvas,
        Color,
        Matrix4,
        Paint,
        Rect,
        SingleChildLayoutDelegate;
import 'package:flutter/widgets.dart' show WidgetsBinding;

import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:mesh/internal_stuff.dart';
import 'package:mesh/mesh.dart';

/// Global flag that defines if O'Mesh will try to be compatible with
/// the Impeller rendering engine.
///
/// True by default.
///
/// Set to false if you are opting out of impeller completely.
///
/// See also:
/// - [enableOMeshImpellerCompatibilityOnAndroid] to enable on Android if
/// ou are opting in on Impeller on Android.
bool enableOMeshImpellerCompatibility = true;

/// When [enableOMeshImpellerCompatibility] is true, this flag will enable
/// Impeller compatibility on Android.
///
/// False by default.
///
/// Set to true if you are opting in on Impeller on Android.
bool enableOMeshImpellerCompatibilityOnAndroid = false;

// Check if the current graphic backend is impeller
bool get _enableImpellerCompatibility {
  // disable checks if the feature is disabled
  if (!enableOMeshImpellerCompatibility) {
    return false;
  }

  // Impeller is not supported on web
  if (kIsWeb) {
    return false;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return true;
  }

  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return true;
  }

  //  Impeller on android is only supported if the feature is enabled
  if (defaultTargetPlatform == TargetPlatform.android) {
    return enableOMeshImpellerCompatibilityOnAndroid;
  }

  return false;
}

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
  late final _textureVerticesCache = CachedValue(
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
  late final _patchesCache = CachedValue(() {
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
  late final _inferredColorsCache = CachedValue<(List<Color>, List<bool>)>(() {
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
  late final _tessellatedMeshCache = CachedValue(
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

      final gradeintPaint = _enableImpellerCompatibility
          ? _getPrerenderedPaint(rect)
          : _getShaderPaint(
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
        gradeintPaint,
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
            ),
        ));
  }

  // Impeller is quite unstable when rendering fragment shaders with the
  // vertices API.
  // To work around this, we prerender the gradient into an image, call
  // toImageSync
  // and return a paint with a ImageShader instead of a fragment shader.
  Paint _getPrerenderedPaint(Rect rect) {
    _rect = rect;
    final image = _impellerColorCache.value;
    return Paint()
      ..shader = ImageShader(
        image,
        TileMode.decal,
        TileMode.decal,
        Matrix4.identity().storage,
      );
  }

  late Rect _rect;
  late final _impellerColorCache = CachedValue<Image>(() {
    final patches = _patchesCache.value;
    final textureVertices = _textureVerticesCache.value;
    final vertexColors = _inferredColorsCache.value;

    // pixel density
    final scale =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (final tuple in patches.indexed) {
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

      var textureTopLeft = textureVertices[index00];
      var textureBottomRight = textureVertices[index11];

      final paintShader = _getShaderPaint(
        patchIndex: patchIndex,
        textureTopLeft: textureTopLeft,
        textureBottomRight: textureBottomRight,
        patchColors: patchColors,
        patchBiases: patchBiases,
        rect: _rect,
      );

      canvas.drawRect(
        _rect,
        paintShader
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.high,
      );
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(
      (scale * _rect.size.width).round(),
      (scale * _rect.size.height).round(),
    );
  })
      .withDependency(() => _rect)
      .withDependency(() => debugMode)
      .withDependency(() => meshRect.fallbackColor)
      .withDependency(() => meshRect.colors)
      .withDependency(() => meshRect.smoothColors)
      .withDependency(() => meshRect.colorSpace)
      .withDependency(() => (meshRect.width, meshRect.height));
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
