import 'package:flutter/material.dart';

/// An overlay shown on top of the wheel viewport, typically to
/// highlight the currently selected row.
class WheelOverlay extends StatelessWidget {
  const WheelOverlay({
    super.key,
    this.builder,
    this.extent,
    this.offset,
    required this.child,
  });

  /// Optional builder that paints the overlay content.
  /// If `null`, only [child] is displayed.
  final WidgetBuilder? builder;

  /// Height of the overlay box. Usually matches the item extent.
  final double? extent;

  /// Vertical offset applied to the overlay (e.g. to account for headers).
  final double? offset;

  /// The underlying wheel view.
  final Widget child;

  /// Creates a default overlay box with optional border and background color.
  static WidgetBuilder delegate({
    Color? color,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? margin,
  }) {
    return (context) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          border: border,
          borderRadius: borderRadius,
          color: color,
        ),
      );
    };
  }

  /// Creates an overlay with horizontal border lines.
  static WidgetBuilder outlined({
    Color? borderColor,
    double? inset,
  }) {
    return (context) {
      final theme = Theme.of(context);
      return WheelOverlay.delegate(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: borderColor ?? theme.colorScheme.outlineVariant,
          ),
        ),
        margin: EdgeInsets.symmetric(horizontal: inset ?? 0),
      )(context);
    };
  }

  /// Creates an overlay with a rounded background and margin inset.
  static WidgetBuilder filled({
    Color? color,
    double? cornerRadius,
    double? inset,
  }) {
    return WheelOverlay.delegate(
      color: color ?? Colors.black12,
      borderRadius: BorderRadius.circular(cornerRadius ?? 6),
      margin: EdgeInsets.symmetric(horizontal: inset ?? 16),
    );
  }

  @override
  /// Builds the wheel with the overlay stacked on top when [builder] is set.
  Widget build(BuildContext context) {
    if (builder != null) {
      Widget overlay = IgnorePointer(
        child: SizedBox(
          height: extent,
          child: builder!(context),
        ),
      );
      if (offset != null) {
        overlay = Transform.translate(
          offset: Offset(0, offset! / 2),
          child: overlay,
        );
      }
      return Stack(
        alignment: Alignment.center,
        children: [child, overlay],
      );
    }
    return child;
  }
}
