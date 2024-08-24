import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:mesh/mesh.dart';

/// A [Widget] that renders a multi-color gradient over a
/// tessellated Two-Dimensional mesh of vertices.
///
/// Each vertex of the [mesh] has a color that is interpolated
/// trough a [OMeshRect.colorSpace] color space.
///
/// This widget is useful for creating complex gradients with multiple colors.
///
/// The [mesh] is tessellated into a grid of [OMeshRect.width]
/// * [OMeshRect.height] vertices, where each vertex is interpolated \
/// from the surrounding vertices.
///
/// Example of usage:
///
/// ```dart
/// OMeshGradient(
///  mesh: OMeshRect(
///   width: 2,
///   height: 2,
///   vertices: [
///     (0.0, 0.0).v,
///     (1.0, 0.0).v,
///     (0.0, 1.0).v,
///     (1.0, 1.0).v,
///   ],
///   colors: [
///     Colors.red,
///     Colors.green,
///     Colors.blue,
///     Colors.yellow,
///   ],
///   colorSpace: OMeshColorSpace.lab,
///   smoothColors: true,
///  ),
/// )
/// ```
/// {@template tessellation-explanation}
/// Use [tessellation] to control the number of vertices that will be
/// interpolated between each vertex of the mesh. The higher the value,
/// the smoother the gradient will be, with some performance cost.
/// Lower values will result in a more blocky gradient, but with better
/// performance. The default value is 12.
/// {@endtemplate}
///
/// Use [debugMode] to enable visual cues to assist the visualization of a
/// mesh gradient.
///
/// As for sizing, the widget has a default expanding behavior, meaning that if
/// no size is provided via the [size] parameter, the widget will expand to the
/// maximum size of the parent constraints. To change to a growing behavior,
/// either wrap the widget in a [SizedBox.expand] or provide a size via the
/// [size] parameter to a specific size or [double.infinity] to expand.
///
/// See also:
/// * [OMeshRect], a class that describes a mesh of vertices with colors.
/// * [OMeshRectTween], a class that interpolates between two [OMeshRect].
/// * [AnimatedOMeshGradient], an implicitly animated widget that animates
/// whenever the [mesh] changes.
class OMeshGradient extends StatelessWidget {
  /// Creates a new [OMeshGradient] with the given [mesh].
  const OMeshGradient({
    required this.mesh,
    super.key,
    this.debugMode,
    this.tessellation,
    this.size,
    this.addRepaintBoundary,
  });

  /// The mesh that will be rendered.
  final OMeshRect mesh;

  /// The number of vertices that will be interpolated between each
  /// passed vertex.
  ///
  /// {@macro tessellation-explanation}
  final int? tessellation;

  /// Whether to enable visual cues to assist the visualization of a
  /// mesh gradient.
  final DebugMode? debugMode;

  /// The preferred size of the widget. If null, it will sized according to
  /// the maximum size of the parent's [BoxConstraints].
  final Size? size;

  /// Whether to add a [RepaintBoundary] around the mesh widget
  /// to avoid repainting the whole widget tree when the mesh changes.
  ///
  /// Read more about [RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
  ///
  /// Default is true
  final bool? addRepaintBoundary;

  @override
  Widget build(BuildContext context) {
    return _ShaderPreloader(
      (context, shaderProvider) {
        Widget child = _OMeshGradient(
          shaderProvider: shaderProvider,
          mesh: mesh,
          debugMode: debugMode,
          tessellation: tessellation ?? 12,
          size: size,
        );

        if (addRepaintBoundary ?? true) {
          child = RepaintBoundary(child: child);
        }

        return child;
      },
    );
  }
}

/// An implicitly animated widget that animates the [mesh] of an
/// [OMeshGradient].
///
/// A change in the [mesh] will be animated over the [duration] with the given
/// [curve].
///
/// Usage example:
///
/// ```dart
///
/// // state value
/// double center = 0.0;
///
/// // in the build method
///
/// return GestureDetector(
///   onTap: () {
///     setState(() {
///       center = center == 0.5 ? 0.7 : 0.5;
///     });
///   },
///   child: AnimatedOMeshGradient(
///     mesh: OMeshRect(
///       width: 3,
///       height: 3,
///       vertices: [
///        (0.0, 0.0).v,
///        (0.5, 0.0).v,
///        (1.0, 0.0).v, // top row
///
///        (0.0, 0.5).v,
///        (center, center).v,
///        (1.0, 0.5).v, // middle row
///
///        (0.0, 1.0).v,
///        (0.5, 1.0).v,
///        (1.0, 1.0).v, // bottom row
///       ],
///       colors: [
///         Colors.red,
///         Colors.green,
///         Colors.blue,
///         Colors.yellow,
///         Colors.purple,
///         Colors.orange,
///         Colors.pink,
///         Colors.teal,
///         Colors.cyan,
///       ],
///       colorSpace: OMeshColorSpace.lab,
///     ),
///     duration: const Duration(seconds: 1),
///     curve: Curves.easeInOut,
///   ),
/// );
/// ```
///
/// In the above example, the mesh will animate between two states when the
/// widget is tapped.
///
/// See also:
/// * [OMeshGradient], The non implicitly animated version of this widget.
/// * [OMeshRect], a class that describes a mesh of vertices with colors.
/// * [OMeshRectTween], a class that interpolates between two [OMeshRect].
/// * [AnimatedContainer], a widget that animates changes in its properties.
class AnimatedOMeshGradient extends StatelessWidget {
  /// Creates a new [AnimatedOMeshGradient] with the given [mesh].
  const AnimatedOMeshGradient({
    required this.mesh,
    required this.duration,
    this.curve,
    this.tessellation,
    this.debugMode,
    this.size,
    super.key,
  });

  /// The mesh that will be rendered.
  final OMeshRect mesh;

  /// The duration of the animation.
  final Duration duration;

  /// The curve to apply when animating the [mesh].
  final Curve? curve;

  /// The number of vertices that will be interpolated between each
  /// passed vertex.
  ///
  /// {@macro tessellation-explanation}
  final int? tessellation;

  /// Whether to enable visual cues to assist
  /// the visualization of a mesh gradient.
  final DebugMode? debugMode;

  /// The preferred size of the widget. If null, it will sized according to
  /// the minimum size of the parent constraints.
  final Size? size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder(
        tween: OMeshRectTween(begin: mesh, end: mesh),
        duration: duration,
        curve: curve ?? Curves.linear,
        builder: (context, OMeshRect mesh, _) {
          return OMeshGradient(
            size: size,
            mesh: mesh,
            debugMode: debugMode,
            tessellation: tessellation,
            addRepaintBoundary: false,
          );
        },
      ),
    );
  }
}

/// A class responsible for loading and caching the fragment shader
/// responsible for interpolation the colors of the mesh.
///
/// This class is used internally by the [OMeshGradient]
/// and [AnimatedOMeshGradient] and should be used directly only
/// if you want to render a mesn on canvas  directly (eg. by using
/// [OMeshRectPaint]).
///
/// Should be loaded via [OMeshShaderProvider.load] and disposed
/// when no longer needed.
///
/// Avoid sharing instances of this class between different
/// mesh gradient areas.
class OMeshShaderProvider {
  OMeshShaderProvider._(this._program);

  /// Loads the shader provider. It will resolve after
  /// the [FragmentProgram] is loaded.
  static Future<OMeshShaderProvider> load() async {
    return OMeshShaderProvider._(await _loadProgram());
  }

  static FragmentProgram? _programCache;

  static Future<FragmentProgram> _loadProgram() async {
    final p = _programCache;
    if (p != null) {
      return p;
    }

    try {
      final program =
          await FragmentProgram.fromAsset('packages/mesh/shaders/omesh.frag');
      _programCache = program;
      return program;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      rethrow;
    }
  }

  final FragmentProgram _program;

  final Map<int, FragmentShader> _shaders = {};

  /// Returns the shader for the given patch index.
  FragmentShader getShaderFor(int index) {
    return _shaders[index] = _shaders[index] ?? _program.fragmentShader();
  }

  /// Disposes the shader provider and all the shaders.
  void dispose() {
    for (final shader in _shaders.values) {
      shader.dispose();
    }
  }
}

class _ShaderPreloader extends StatefulWidget {
  const _ShaderPreloader(this.builder);

  final Widget Function(BuildContext, OMeshShaderProvider) builder;

  @override
  State<_ShaderPreloader> createState() => _ShaderPreloaderState();
}

class _ShaderPreloaderState extends State<_ShaderPreloader> {
  OMeshShaderProvider? shaderProvider;

  @override
  void initState() {
    super.initState();
    OMeshShaderProvider.load().then((provider) {
      if (mounted) {
        setState(() {
          shaderProvider = provider;
        });
      }
    });
  }

  @override
  void dispose() {
    shaderProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (shaderProvider == null) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, shaderProvider!);
  }
}

class _OMeshGradient extends StatefulWidget {
  const _OMeshGradient({
    required this.mesh,
    required this.tessellation,
    required this.debugMode,
    required this.shaderProvider,
    this.size,
  });

  final OMeshShaderProvider shaderProvider;
  final OMeshRect mesh;
  final int tessellation;
  final DebugMode? debugMode;
  final Size? size;

  @override
  State<_OMeshGradient> createState() => _OMeshGradientState();
}

class _OMeshGradientState extends State<_OMeshGradient> {
  late final draw = OMeshRectPaint(
    shaderProvider: widget.shaderProvider,
    meshRect: widget.mesh,
    debugMode: widget.debugMode,
    tessellation: widget.tessellation,
  );

  @override
  void reassemble() {
    super.reassemble();
    draw.markNeedsRepaint();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: _OMeshRectPainter(
          draw: draw
            ..meshRect = widget.mesh
            ..tessellation = widget.tessellation
            ..debugMode = widget.debugMode,
        ),
        isComplex: draw.tessellation > 2,
        willChange: draw.needsRepaint,
        size: widget.size ?? Size.infinite,
      ),
    );
  }
}

class _OMeshRectPainter extends CustomPainter {
  _OMeshRectPainter({
    required this.draw,
  });

  final OMeshRectPaint draw;

  @override
  void paint(Canvas canvas, Size size) {
    draw.paint(canvas, Offset.zero & size);
  }

  @override
  bool shouldRepaint(_OMeshRectPainter oldDelegate) {
    return draw.needsRepaint;
  }
}
