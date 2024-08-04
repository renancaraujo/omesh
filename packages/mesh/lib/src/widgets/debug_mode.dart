import 'package:flutter/foundation.dart';

/// A class to describe visual cues to assist
/// the visualization of a mesh gradient.
///
/// Beware that some of these features may cause
/// significant performance issues and it should not
/// be used in production code.
@immutable
class DebugMode {
  /// Creates a new [DebugMode] with the given [enableDots] value.
  const DebugMode({
    this.enableDots = false,
  });

  /// Disable all debug features.
  static const none = DebugMode();

  /// Only [enableDots] is set to true.
  static const dots = DebugMode(enableDots: true);

  /// Enable dots to be drawn on the mesh gradient.
  ///
  /// Each dot represents a vertex on the tessellated mesh.
  ///
  /// This has a low performance cost.
  final bool enableDots;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebugMode && other.enableDots == enableDots;
  }

  @override
  int get hashCode => enableDots.hashCode;
}
