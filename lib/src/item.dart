import 'package:flutter/material.dart';

/// A class that represents a selectable and optionally disabled item
/// in a [WheelChoice].
///
/// Typically, you don't construct [WheelItem] directly; it's created internally
/// when building the list. Use [WheelItem.delegate] to provide a custom builder
/// for how each row is rendered.
class WheelItem<T> implements Comparable<WheelItem<T>> {
  /// Creates a wheel item with the given data and states.
  WheelItem({
    required this.data,
    required this.label,
    required this.selected,
    required this.disabled,
  });

  /// Creates a default item builder that renders the item text.
  ///
  /// Usage:
  /// ```dart
  /// itemBuilder: WheelItem.delegate(
  ///   alignment: Alignment.centerLeft,
  ///   padding: const EdgeInsets.symmetric(horizontal: 16),
  ///   style: const TextStyle(fontSize: 14),
  ///   selectedStyle: const TextStyle(fontWeight: FontWeight.bold),
  ///   disabledStyle: const TextStyle(color: Colors.grey),
  /// )
  /// ```
  static WheelItemBuilder<T> delegate<T>({
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    TextStyle? style,
    TextStyle? disabledStyle,
    TextStyle? selectedStyle,
  }) {
    return (context, item) {
      final theme = Theme.of(context);
      TextStyle? defaultStyle = theme.textTheme.bodyMedium;
      TextStyle? textStyle = style ?? defaultStyle;

      if (item.selected) {
        textStyle = textStyle
            ?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
            .merge(selectedStyle);
      }

      if (item.disabled) {
        textStyle = textStyle
            ?.copyWith(color: theme.disabledColor)
            .merge(disabledStyle);
      }

      return Container(
        padding: padding,
        alignment: alignment ?? Alignment.center,
        child: Text(item.label, style: textStyle),
      );
    };
  }

  /// The value associated with this item.
  final T data;

  /// The human-readable label shown for this item.
  final String label;

  /// Whether the item is currently selected.
  final bool selected;

  /// Whether the item is disabled and unselectable.
  final bool disabled;

  /// Default row height for items in the wheel.
  static const defaultExtent = 40.0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WheelItem<T> &&
            runtimeType == other.runtimeType &&
            data == other.data &&
            selected == other.selected &&
            disabled == other.disabled;
  }

  @override
  int get hashCode => Object.hash(data, selected, disabled);

  @override
  int compareTo(WheelItem other) {
    // You can customize how these should be ranked if needed.
    return toString().compareTo(other.toString());
  }

  @override
  String toString() =>
      'WheelItem(data: $data, label: $label, selected: $selected, disabled: $disabled)';
}

/// A function to resolve the label string from an item value.
typedef WheelItemLabel<T> = String Function(T value);

/// A function signature used to determine whether an item should be disabled.
typedef WheelItemDisable<T> = bool Function(T value);

/// A builder function for rendering each item in the [WheelChoice].
///
/// Usage:
/// ```dart
/// Widget buildItem(BuildContext context, WheelItem<int> item) {
///   return Row(
///     mainAxisAlignment: MainAxisAlignment.center,
///     children: [
///       Text(item.label),
///       if (item.selected) const Icon(Icons.check, size: 16),
///     ],
///   );
/// }
/// ```
typedef WheelItemBuilder<T> =
    Widget Function(BuildContext context, WheelItem<T> item);
