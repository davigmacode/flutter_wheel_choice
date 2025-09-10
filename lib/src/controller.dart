import 'package:flutter/widgets.dart';
import 'item.dart';

/// Controller for [FixedExtentScrollController] that understands the picker
/// options and current value, enabling programmatic selection by value.
class WheelController<T> extends FixedExtentScrollController {
  WheelController({
    required List<T> options,
    T? value,
    int? initialIndex,
    WheelItemDisable<T>? itemDisabled,
    ValueChanged<T>? onChanged,
  }) : _options = List<T>.from(options),
       _value = value,
       _itemDisabled = itemDisabled,
       _onChanged = onChanged,
       super(
         initialItem: initialIndex ?? _initialIndex(options, value),
       );

  static int _initialIndex<T>(List<T> options, T? value) {
    if (value != null) {
      final idx = options.indexOf(value);
      if (idx >= 0) return idx;
    }
    return 0;
  }

  List<T> _options;
  T? _value;
  WheelItemDisable<T>? _itemDisabled;
  ValueChanged<T>? _onChanged;

  /// Current options used to resolve indices.
  List<T> get options => List.unmodifiable(_options);

  /// Currently selected value tracked by this controller.
  T? get value => _value;

  /// Index of the current [value] in [options], or 0 when unknown.
  int get selectedIndex {
    final v = _value;
    if (v == null) return 0;
    final i = _options.indexOf(v);
    return i >= 0 ? i : 0;
  }

  /// Predicate to check whether an item is disabled.
  bool isDisabled(T item) => _itemDisabled?.call(item) ?? false;

  /// Replaces the options list. When [alignToValue] is true and the
  /// current [value] exists in the new list, scrolls to its index.
  void setOptions(
    List<T> options, {
    bool alignToValue = true,
    bool animate = false,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.ease,
  }) {
    _options = List<T>.from(options);
    if (alignToValue && _value != null) {
      final idx = _options.indexOf(_value as T);
      if (idx >= 0) {
        if (animate) {
          animateToItem(idx, duration: duration, curve: curve);
        } else {
          jumpToItem(idx);
        }
      }
    }
  }

  /// Updates the itemDisabled resolver.
  void setItemDisabled(WheelItemDisable<T>? f) => _itemDisabled = f;

  /// Updates the onChanged callback.
  void setOnChanged(ValueChanged<T>? f) => _onChanged = f;

  /// Sets the current value by scrolling to its index in [options].
  /// Returns true when the value was found and applied.
  Future<bool> setValue(
    T value, {
    bool animate = false,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.ease,
    bool notify = true,
  }) async {
    final idx = _options.indexOf(value);
    if (idx < 0) return false;
    _value = value;
    if (selectedItem != idx) {
      if (animate) {
        await animateToItem(idx, duration: duration, curve: curve);
      } else {
        jumpToItem(idx);
      }
    }
    if (notify) _onChanged?.call(value);
    return true;
  }

  /// Synchronizes the tracked [value] from a selected index.
  void syncValueFromIndex(int index) {
    if (index >= 0 && index < _options.length) {
      _value = _options[index];
    }
  }

  /// Handles selection change from the wheel at [index].
  void handleChanged(int index, {required bool loop}) {
    if (_options.isEmpty) return;
    final actualIndex = loop ? index % _options.length : index;
    final newValue = _options[actualIndex];
    if (!isDisabled(newValue) && _value != newValue) {
      _value = newValue;
      _onChanged?.call(newValue);
    }
  }

  /// Ensures that when landing on a disabled item, the wheel snaps to the
  /// nearest enabled item according to [loop] mode.
  void handleScrollEnd({
    required bool loop,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    if (_options.isEmpty) return;
    final index = selectedItem;
    final actualIndex = loop ? index % _options.length : index;
    final item = _options[actualIndex];
    if (isDisabled(item)) {
      final nearestIndex = loop
          ? _findNearestEnabledIndexLoop(actualIndex)
          : _findNearestEnabledIndex(actualIndex);
      if (nearestIndex != actualIndex) {
        final target = loop
            ? index + (nearestIndex - actualIndex)
            : nearestIndex;
        Future.microtask(() {
          animateToItem(target, duration: duration, curve: curve);
        });
      }
    }
  }

  int _findNearestEnabledIndexLoop(int fromIndex) {
    final len = _options.length;
    int? bestIndex;
    int bestDistance = len;
    for (int offset = 1; offset < len; offset++) {
      final downIndex = (fromIndex + offset) % len;
      final upIndex = (fromIndex - offset + len) % len;
      if (!isDisabled(_options[downIndex])) {
        final wraps = fromIndex > downIndex;
        final effectiveDistance = offset + (wraps ? len : 0);
        if (effectiveDistance < bestDistance) {
          bestDistance = effectiveDistance;
          bestIndex = downIndex;
        }
      }
      if (!isDisabled(_options[upIndex])) {
        final wraps = fromIndex < upIndex;
        final effectiveDistance = offset + (wraps ? len : 0);
        if (effectiveDistance < bestDistance) {
          bestDistance = effectiveDistance;
          bestIndex = upIndex;
        }
      }
      if (bestIndex != null && bestDistance == offset) break;
    }
    return bestIndex ?? fromIndex;
  }

  int _findNearestEnabledIndex(int fromIndex) {
    int distance = 1;
    while (fromIndex - distance >= 0 ||
        fromIndex + distance < _options.length) {
      final down = fromIndex + distance;
      if (down < _options.length && !isDisabled(_options[down])) {
        return down;
      }
      final up = fromIndex - distance;
      if (up >= 0 && !isDisabled(_options[up])) {
        return up;
      }
      distance++;
    }
    return fromIndex;
  }
}
