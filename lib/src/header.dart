import 'package:flutter/material.dart';
import 'item.dart';

/// A header widget shown above the [WheelPicker] viewport.
///
/// Useful for titles, units, or any leading widget aligned with
/// the wheel rows.
class WheelHeader extends StatelessWidget {
  const WheelHeader({
    super.key,
    this.extent,
    this.align,
    this.decoration,
    this.textStyle,
    this.child,
  });

  /// Creates a new [WheelHeader] from another instance, overriding
  /// any of the provided properties.
  WheelHeader.from(
    WheelHeader other, {
    super.key,
    double? extent,
    AlignmentGeometry? align,
    Decoration? decoration,
    TextStyle? textStyle,
    Widget? child,
  }) : extent = extent ?? other.extent,
       align = align ?? other.align,
       decoration = decoration ?? other.decoration,
       textStyle = textStyle ?? other.textStyle,
       child = child ?? other.child;

  /// Explicit height for the header row. Defaults to
  /// [WheelItem.defaultExtent] when not provided.
  final double? extent;

  /// Alignment for [child] within the header container. Defaults
  /// to [Alignment.center].
  final AlignmentGeometry? align;

  /// Optional decoration for the header container.
  final Decoration? decoration;

  /// Base text style merged into [DefaultTextStyle] for [child].
  final TextStyle? textStyle;

  /// The content to display inside the header.
  final Widget? child;

  /// Resolved header height.
  double get extentX => extent ?? WheelItem.defaultExtent;

  /// Resolved header alignment.
  AlignmentGeometry get alignX => align ?? Alignment.center;

  /// Returns a copy of this header used as a default for [other],
  /// letting [other]'s non-null properties take precedence.
  WheelHeader asDefaultFor(WheelHeader other) {
    return WheelHeader.from(
      this,
      extent: other.extent,
      align: other.align,
      decoration: other.decoration,
      textStyle: other.textStyle,
      child: other.child,
    );
  }

  @override
  /// Builds the header container with merged text style and decoration.
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DefaultTextStyle.merge(
      style: theme.labelLarge
          ?.copyWith(fontWeight: FontWeight.bold)
          .merge(textStyle),
      child: Container(
        height: extentX,
        alignment: alignX,
        decoration: decoration,
        child: child,
      ),
    );
  }
}
