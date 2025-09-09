import 'package:flutter/foundation.dart';

/// A configuration class that defines the visual effects for [WheelChoice].
///
/// Controls 3D look-and-feel such as perspective, magnifier, and wheel shape.
///
/// Usage:
/// ```dart
/// final effect = const WheelEffect(
///   useMagnifier: true,
///   magnification: 1.15,
///   diameterRatio: 2.0,
///   perspective: 0.003,
///   overAndUnderCenterOpacity: 0.6,
/// );
/// ```
///
/// Tips:
/// - Use [WheelEffect.flat] for a near-flat list look (very large diameter).
/// - Prefer [merge] to combine defaults with overrides; use [copyWith] for tweaks.
@immutable
class WheelEffect implements Comparable<WheelEffect> {
  const WheelEffect({
    this.useMagnifier,
    this.magnification,
    this.diameterRatio,
    this.perspective,
    this.offAxisFraction,
    this.overAndUnderCenterOpacity,
    this.squeeze,
  });

  /// A convenience constructor that produces a near-flat wheel by
  /// using a very large [diameterRatio].
  const WheelEffect.flat({
    this.useMagnifier,
    this.magnification,
    this.diameterRatio = 100.0,
    this.perspective,
    this.offAxisFraction,
    this.overAndUnderCenterOpacity,
    this.squeeze,
  });

  /// Whether to use magnifier effect.
  final bool? useMagnifier;

  /// The scale factor of the magnifier.
  final double? magnification;

  /// The diameter ratio of the wheel.
  final double? diameterRatio;

  /// The 3D perspective of the wheel.
  final double? perspective;

  /// The horizontal offset for 3D effect.
  final double? offAxisFraction;

  /// The opacity for items not centered.
  final double? overAndUnderCenterOpacity;

  /// The vertical compression factor.
  final double? squeeze;

  /// Resolved value for [useMagnifier] (defaults to `false`).
  bool get useMagnifierX => useMagnifier ?? false;

  /// Resolved value for [magnification] (defaults to `1.0`).
  double get magnificationX => magnification ?? 1.0;

  /// Resolved value for [diameterRatio] (defaults to `2.0`).
  double get diameterRatioX => diameterRatio ?? 2.0;

  /// Resolved value for [perspective] (defaults to `0.003`).
  double get perspectiveX => perspective ?? 0.003;

  /// Resolved value for [offAxisFraction] (defaults to `0.0`).
  double get offAxisFractionX => offAxisFraction ?? 0.0;

  /// Resolved value for [overAndUnderCenterOpacity] (defaults to `1.0`).
  double get overAndUnderCenterOpacityX => overAndUnderCenterOpacity ?? 1.0;

  /// Resolved value for [squeeze] (defaults to `1.0`).
  double get squeezeX => squeeze ?? 1.0;

  /// Creates a new [WheelEffect] with some properties replaced.
  WheelEffect copyWith({
    bool? useMagnifier,
    double? magnification,
    double? diameterRatio,
    double? perspective,
    double? offAxisFraction,
    double? overAndUnderCenterOpacity,
    double? squeeze,
  }) {
    return WheelEffect(
      useMagnifier: useMagnifier ?? this.useMagnifier,
      magnification: magnification ?? this.magnification,
      diameterRatio: diameterRatio ?? this.diameterRatio,
      perspective: perspective ?? this.perspective,
      offAxisFraction: offAxisFraction ?? this.offAxisFraction,
      overAndUnderCenterOpacity:
          overAndUnderCenterOpacity ?? this.overAndUnderCenterOpacity,
      squeeze: squeeze ?? this.squeeze,
    );
  }

  /// Merges another [WheelEffect] into this one.
  ///
  /// Useful for layering a base effect with per-instance overrides.
  /// When [other] is `null`, returns `this` unchanged.
  ///
  /// ```dart
  /// final base = const WheelEffect(useMagnifier: true);
  /// final merged = base.merge(const WheelEffect(magnification: 1.1));
  /// ```
  WheelEffect merge(WheelEffect? other) {
    if (other == null) return this;
    return copyWith(
      useMagnifier: other.useMagnifier ?? useMagnifier,
      magnification: other.magnification ?? magnification,
      diameterRatio: other.diameterRatio ?? diameterRatio,
      perspective: other.perspective ?? perspective,
      offAxisFraction: other.offAxisFraction ?? offAxisFraction,
      overAndUnderCenterOpacity:
          other.overAndUnderCenterOpacity ?? overAndUnderCenterOpacity,
      squeeze: other.squeeze ?? squeeze,
    );
  }

  @override
  String toString() {
    return 'WheelEffect('
        'useMagnifier: $useMagnifier, '
        'magnification: $magnification, '
        'diameterRatio: $diameterRatio, '
        'perspective: $perspective, '
        'offAxisFraction: $offAxisFraction, '
        'overAndUnderCenterOpacity: $overAndUnderCenterOpacity, '
        'squeeze: $squeeze)';
  }

  @override
  /// Equality operator comparing all effect properties.
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WheelEffect &&
            runtimeType == other.runtimeType &&
            useMagnifier == other.useMagnifier &&
            magnification == other.magnification &&
            diameterRatio == other.diameterRatio &&
            perspective == other.perspective &&
            offAxisFraction == other.offAxisFraction &&
            overAndUnderCenterOpacity == other.overAndUnderCenterOpacity &&
            squeeze == other.squeeze;
  }

  @override
  /// Hash code combining all configurable fields.
  int get hashCode => Object.hash(
        useMagnifier,
        magnification,
        diameterRatio,
        perspective,
        offAxisFraction,
        overAndUnderCenterOpacity,
        squeeze,
      );

  @override
  /// Provides a stable, deterministic ordering based on [toString].
  int compareTo(WheelEffect other) => toString().compareTo(other.toString());
}
