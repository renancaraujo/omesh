import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// Film grain and scatter applied to a mesh gradient.
///
/// Two independent effects, each turned off by its zero value:
///
/// * [scatter] moves the point where each pixel looks up its color by a
///   small random offset, giving a sandy edge between colors without adding
///   new colors.
/// * [amount] adds visible, brightness-weighted grain over the finished
///   mesh, one grain cell per physical pixel. [shadows], [midtones] and
///   [highlights] weight the grain by the brightness of each pixel. Near
///   black and white each color channel gets less grain, and none at 0 or
///   1, so the grain never changes the average color.
///
/// The grain ([amount] above zero) is drawn by rendering the mesh into an
/// offscreen image first, so it costs one offscreen image and one extra
/// full-size pass per paint. [scatter] runs inside the mesh shader and costs
/// almost nothing.
///
/// Pass it to the `grain` option of `OMeshGradient`,
/// `AnimatedOMeshGradient` or `OMeshRectPaint`:
///
/// ```dart
/// // Both effects, with the default strength.
/// OMeshGradient(mesh: mesh, grain: const OMeshGrain());
///
/// // Heavy grain only.
/// OMeshGradient(
///   mesh: mesh,
///   grain: const OMeshGrain(amount: 0.15, scatter: 0),
/// );
///
/// // Scatter only, with no extra pass.
/// OMeshGradient(
///   mesh: mesh,
///   grain: const OMeshGrain(amount: 0, scatter: 24),
/// );
///
/// // Grain mostly in the shadows.
/// OMeshGradient(
///   mesh: mesh,
///   grain: const OMeshGrain(shadows: 1, midtones: 0.5, highlights: 0),
/// );
/// ```
///
/// See also:
/// * [OMeshGrain.none], with every effect off.
@immutable
class OMeshGrain {
  /// Creates a grain setting. The defaults turn on both effects.
  const OMeshGrain({
    this.amount = 0.05,
    this.scatter = 12,
    this.shadows = 0.6,
    this.midtones = 1,
    this.highlights = 0.5,
    this.seed = 0,
  })  : assert(amount >= 0, 'amount must not be negative'),
        assert(scatter >= 0, 'scatter must not be negative'),
        assert(seed >= 0, 'seed must not be negative');

  /// Every effect off. Renders exactly like no grain at all.
  static const none = OMeshGrain(amount: 0, scatter: 0);

  /// Strength of the visible grain, as a fraction of full scale.
  ///
  /// 0 turns the grain off. Around 0.05 is subtle; 0.2 is heavy.
  final double amount;

  /// Maximum random offset of each pixel's color lookup, in logical pixels.
  ///
  /// 0 turns scatter off.
  final double scatter;

  /// Grain weight in the shadows, toward brightness 0.
  ///
  /// Pure black gets no grain whatever this weight.
  final double shadows;

  /// Grain weight in the midtones (brightness 0.5).
  final double midtones;

  /// Grain weight in the highlights, toward brightness 1.
  ///
  /// Pure white gets no grain whatever this weight.
  final double highlights;

  /// Picks a different random pattern. Seeds 997 apart give the same
  /// pattern.
  final int seed;

  /// Whether any of the effects is on.
  bool get isActive => amount > 0 || scatter > 0;

  /// Returns a copy of this grain with the given fields replaced.
  OMeshGrain copyWith({
    double? amount,
    double? scatter,
    double? shadows,
    double? midtones,
    double? highlights,
    int? seed,
  }) {
    return OMeshGrain(
      amount: amount ?? this.amount,
      scatter: scatter ?? this.scatter,
      shadows: shadows ?? this.shadows,
      midtones: midtones ?? this.midtones,
      highlights: highlights ?? this.highlights,
      seed: seed ?? this.seed,
    );
  }

  /// Linearly interpolates between two grain settings.
  ///
  /// [amount], [scatter] and the brightness weights interpolate. [seed]
  /// switches at the halfway point. A null value counts as
  /// [OMeshGrain.none].
  static OMeshGrain? lerp(OMeshGrain? a, OMeshGrain? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    final from = a ?? none;
    final to = b ?? none;
    double mix(double x, double y) => lerpDouble(x, y, t)!;
    return OMeshGrain(
      amount: mix(from.amount, to.amount).clamp(0, double.infinity),
      scatter: mix(from.scatter, to.scatter).clamp(0, double.infinity),
      shadows: mix(from.shadows, to.shadows),
      midtones: mix(from.midtones, to.midtones),
      highlights: mix(from.highlights, to.highlights),
      seed: t < 0.5 ? from.seed : to.seed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OMeshGrain &&
        other.amount == amount &&
        other.scatter == scatter &&
        other.shadows == shadows &&
        other.midtones == midtones &&
        other.highlights == highlights &&
        other.seed == seed;
  }

  @override
  int get hashCode => Object.hash(
        amount,
        scatter,
        shadows,
        midtones,
        highlights,
        seed,
      );

  @override
  String toString() {
    return 'OMeshGrain('
        'amount: $amount, '
        'scatter: $scatter, '
        'shadows: $shadows, '
        'midtones: $midtones, '
        'highlights: $highlights, '
        'seed: $seed'
        ')';
  }
}
