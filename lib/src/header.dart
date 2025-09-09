import 'package:flutter/material.dart';
import 'item.dart';

class WheelHeader extends StatelessWidget {
  const WheelHeader({
    super.key,
    this.extent,
    this.align,
    this.decoration,
    this.textStyle,
    this.child,
  });

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

  final double? extent;
  final AlignmentGeometry? align;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Widget? child;

  double get extentX => extent ?? WheelItem.defaultExtent;
  AlignmentGeometry get alignX => align ?? Alignment.center;

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
