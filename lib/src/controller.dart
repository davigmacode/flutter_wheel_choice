import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'item.dart';

/// Controller for [FixedExtentScrollController] that understands the picker
/// options and current value, enabling programmatic selection by value.
class WheelController<T> extends FixedExtentScrollController {
  /// Creates a value-aware controller for a wheel.
  ///
  /// Parameters:
  /// - [options]: The ordered list of selectable values. Used to resolve
  ///   indices and map between wheel positions and semantic values.
  /// - [value]: Initial selected value. When present and found in [options],
  ///   it determines the starting position.
  /// - [itemDisabled]: Predicate to mark values as disabled. Disabled values
  ///   do not trigger [onChanged] and are skipped by settle logic.
  /// - [onChanged]: Callback invoked when the selection changes, either via
  ///   user scroll or programmatic methods like [setValue], [jumpToValue],
  ///   [animateToValue], [jumpToIndex], or [animateToIndex].
  /// - [loop]: Enables wrap-around semantics for programmatic moves and
  ///   nearest-enabled snapping during settle.
  /// - [animationDuration]: Default duration used by [animateToValue] and
  ///   [animateToIndex] when a duration isn’t supplied.
  /// - [animationCurve]: Default curve used by [animateToValue] and
  ///   [animateToIndex] when a curve isn’t supplied.
  WheelController({
    List<T>? options,
    T? value,
    WheelItemDisable<T>? itemDisabled,
    ValueChanged<T>? onChanged,
    bool? loop,
    Duration? animationDuration,
    Curve? animationCurve,
  }) : _options = List<T>.from(options ?? []),
       _value = value,
       _itemDisabled = itemDisabled,
       _onChanged = onChanged,
       _loop = loop ?? false,
       _animationDuration =
           animationDuration ?? const Duration(milliseconds: 250),
       _animationCurve = animationCurve ?? Curves.easeOut,
       _indexNotifier = ValueNotifier<int>(_initialIndex(options ?? [], value)),
       _valueNotifier = ValueNotifier<T?>(value),
       super(initialItem: _initialIndex(options ?? [], value));

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
  bool _loop;
  Duration _animationDuration;
  Curve _animationCurve;
  final ValueNotifier<int> _indexNotifier;
  final ValueNotifier<T?> _valueNotifier;

  /// Current options used to resolve indices.
  List<T> get options => List.unmodifiable(_options);

  /// Currently selected value tracked by this controller.
  T? get value => _value;

  /// Read-only listenable for the current base index (0..options.length-1).
  ///
  /// Emits updates whenever selection changes (user or programmatic). Pairs
  /// with [valueListenable] for reactive integrations without rebuilding
  /// parent widgets.
  ValueListenable<int> get indexListenable => _indexNotifier;

  /// Read-only listenable for the current [value].
  ValueListenable<T?> get valueListenable => _valueNotifier;

  /// Index of the current [value] in [options], or 0 when unknown.
  int get selectedIndex {
    final v = _value;
    if (v == null) return 0;
    final i = _options.indexOf(v);
    return i >= 0 ? i : 0;
  }

  /// Predicate to check whether an item is disabled.
  bool isDisabled(T item) => _itemDisabled?.call(item) ?? false;

  /// Whether the wheel should wrap around when scrolling by index.
  bool get loop => _loop;
  void setLoop(bool? value) => _loop = value ?? false;

  /// Default animation duration/curve used when not provided to animate* calls.
  Duration get animationDuration => _animationDuration;
  Curve get animationCurve => _animationCurve;
  void setAnimationDefaults({Duration? duration, Curve? curve}) {
    _animationDuration = duration ?? _animationDuration;
    _animationCurve = curve ?? _animationCurve;
  }

  /// Replaces the options list. When [alignToValue] is true and the
  /// current [value] exists in the new list, scrolls to its index.
  void setOptions(
    List<T>? options, {
    bool alignToValue = true,
    bool animate = false,
    Duration? duration,
    Curve? curve,
  }) {
    if (options == null) return;
    _options = List<T>.from(options);
    if (alignToValue && _value != null) {
      final idx = _options.indexOf(_value as T);
      if (idx >= 0) {
        if (animate) {
          final d = duration ?? _animationDuration;
          final c = curve ?? _animationCurve;
          animateToItem(idx, duration: d, curve: c);
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
    Duration? duration,
    Curve? curve,
    bool notify = true,
  }) async {
    if (animate) {
      return await animateToValue(
        value,
        duration: duration,
        curve: curve,
        notify: notify,
      );
    }
    return jumpToValue(value);
  }

  /// Sets the current index, optionally animating to it.
  ///
  /// Disabled-awareness:
  /// - When [animate] is true, this method is disabled-aware (uses
  ///   [animateToIndex], which snaps to nearest enabled when needed).
  /// - When [animate] is false, it jumps directly via [jumpToIndex] (not
  ///   disabled-aware).
  Future<bool> setIndex(
    int index, {
    bool animate = false,
    Duration? duration,
    Curve? curve,
    bool notify = true,
  }) async {
    if (animate) {
      return await animateToIndex(
        index,
        duration: duration,
        curve: curve,
        notify: notify,
      );
    }
    return jumpToIndex(index, notify: notify);
  }

  /// Synchronizes the tracked [value] from a selected index.
  void syncValueFromIndex(int index) {
    if (index >= 0 && index < _options.length) {
      _value = _options[index];
      _valueNotifier.value = _value;
      _indexNotifier.value = index;
    }
  }

  /// Handles selection change from the wheel at [index].
  void handleIndexChanged(int index) {
    if (_options.isEmpty) return;
    final actualIndex = _loop ? index % _options.length : index;
    final newValue = _options[actualIndex];
    if (!isDisabled(newValue) && _value != newValue) {
      _value = newValue;
      _valueNotifier.value = _value;
      _indexNotifier.value = actualIndex;
      _onChanged?.call(newValue);
    }
  }

  /// Ensures that when landing on a disabled item, the wheel snaps to the
  /// nearest enabled item according to [loop] mode.
  void handleScrollEnd({
    Duration? duration,
    Curve? curve,
  }) {
    if (_options.isEmpty) return;
    final index = selectedItem;
    final actualIndex = _loop ? index % _options.length : index;
    final item = _options[actualIndex];
    if (isDisabled(item)) {
      final nearestIndex = _loop
          ? _findNearestEnabledIndexLoop(actualIndex)
          : _findNearestEnabledIndex(actualIndex);
      if (nearestIndex != actualIndex) {
        final target = _loop
            ? index + (nearestIndex - actualIndex)
            : nearestIndex;
        Future.microtask(() {
          final d = duration ?? _animationDuration;
          final c = curve ?? _animationCurve;
          animateToItem(target, duration: d, curve: c);
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

  // Programmatic navigation helpers

  int _clampIndex(int index) {
    if (_options.isEmpty) return 0;
    if (index < 0) return 0;
    if (index >= _options.length) return _options.length - 1;
    return index;
  }

  int _normalizeMod(int value, int mod) {
    if (mod == 0) return 0;
    final r = value % mod;
    return r < 0 ? r + mod : r;
  }

  /// Computes the target absolute item index when looping is enabled,
  /// choosing the shortest path from the current position to [baseIndex].
  int _loopTargetForBaseIndex(int baseIndex) {
    final len = _options.length;
    if (len == 0) return 0;
    final current = selectedItem;
    final currentBase = _normalizeMod(current, len);
    int delta = baseIndex - currentBase; // could be negative or positive
    // Choose the minimal wrap distance
    if (delta.abs() > len / 2) {
      delta += (delta > 0) ? -len : len;
    }
    return current + delta;
  }

  /// Jumps to an item by its index and updates [value].
  ///
  /// Disabled-awareness: Not disabled-aware; it jumps to the exact
  /// index (if found), even if that index is disabled.
  bool jumpToIndex(int index, {bool notify = true}) {
    if (_options.isEmpty) return false;
    final baseIndex = _clampIndex(index);
    final targetIndex = _loop ? _loopTargetForBaseIndex(baseIndex) : baseIndex;
    _value = _options[baseIndex];
    _valueNotifier.value = _value;
    _indexNotifier.value = baseIndex;
    if (selectedItem != targetIndex) {
      jumpToItem(targetIndex);
    }
    if (notify) _onChanged?.call(_value as T);
    return true;
  }

  /// Animates to an item by its index and updates [value].
  ///
  /// Disabled-awareness: Yes. If the index points to a disabled value, it
  /// animates to the nearest enabled value (loop-aware).
  Future<bool> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
    bool notify = true,
  }) async {
    if (_options.isEmpty) return false;
    int baseIndex = _clampIndex(index);
    if (isDisabled(_options[baseIndex])) {
      baseIndex = _loop
          ? _findNearestEnabledIndexLoop(baseIndex)
          : _findNearestEnabledIndex(baseIndex);
    }
    final targetIndex = _loop ? _loopTargetForBaseIndex(baseIndex) : baseIndex;
    _value = _options[baseIndex];
    _valueNotifier.value = _value;
    _indexNotifier.value = baseIndex;
    if (selectedItem != targetIndex) {
      final d = duration ?? _animationDuration;
      final c = curve ?? _animationCurve;
      await animateToItem(targetIndex, duration: d, curve: c);
    }
    if (notify) _onChanged?.call(_value as T);
    return true;
  }

  /// Jumps to an item by its value. Returns `true` if found.
  ///
  /// Disabled-awareness: Not disabled-aware; it jumps to the exact value's
  /// index (if found), even if that value is disabled.
  bool jumpToValue(T value, {bool notify = true}) {
    final baseIndex = _options.indexOf(value);
    if (baseIndex < 0) return false;
    jumpToIndex(baseIndex, notify: notify);
    return true;
  }

  /// Animates to an item by its value. Returns `true` if found.
  /// Animates to an item by its value. Returns `true` if found.
  ///
  /// Disabled-awareness: Yes. Delegates to [animateToIndex] which is
  /// disabled-aware.
  Future<bool> animateToValue(
    T value, {
    Duration? duration,
    Curve? curve,
    bool notify = true,
  }) async {
    final baseIndex = _options.indexOf(value);
    if (baseIndex < 0) return false;
    await animateToIndex(
      baseIndex,
      duration: duration,
      curve: curve,
      notify: notify,
    );
    return true;
  }

  @override
  void dispose() {
    _indexNotifier.dispose();
    _valueNotifier.dispose();
    super.dispose();
  }
}
