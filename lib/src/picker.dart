import 'package:flutter/material.dart';
import 'item.dart';
import 'header.dart';
import 'effect.dart';
import 'overlay.dart';

/// A customizable picker widget that mimics a wheel or "slot machine"-like scroll selector.
///
/// Useful for building things like time selectors, value choosers, or
/// any dropdown-like vertical list with better UX.
class WheelPicker<T> extends StatefulWidget {
  /// Creates a [WheelPicker] with various customization options.
  const WheelPicker({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.controller,
    this.itemLabel,
    this.itemDisabled,
    this.itemBuilder,
    this.itemVisible,
    this.itemExtent,
    this.header,
    this.overlay,
    this.effect,
    this.loop,
    this.expanded,
  });

  /// The currently selected value.
  final T? value;

  /// The available selectable options.
  final List<T> options;

  /// Called when a different item is selected.
  final ValueChanged<T>? onChanged;

  /// Resolves a string label from a value for default item rendering.
  /// If not provided, `value.toString()` is used.
  final WheelItemLabel<T>? itemLabel;

  /// A function used to mark specific items as disabled.
  final WheelItemDisable<T>? itemDisabled;

  /// A builder for customizing how each item is displayed.
  final WheelItemBuilder<T>? itemBuilder;

  /// Number of visible items (should be odd).
  final int? itemVisible;

  /// The height of each item in the picker.
  final double? itemExtent;

  /// Optional header displayed above the wheel.
  final WheelHeader? header;

  /// An optional overlay builder displayed on top of the picker.
  final WidgetBuilder? overlay;

  /// Visual effects configuration for the wheel's 3D appearance.
  final WheelEffect? effect;

  /// Whether the picker should loop infinitely.
  final bool? loop;

  /// Whether to automatically expand to parent height.
  final bool? expanded;

  /// Scroll controller for programmatic control.
  final FixedExtentScrollController? controller;

  @override
  State<WheelPicker<T>> createState() => _WheelPickerState<T>();
}

/// State and behavior for [WheelPicker].
class _WheelPickerState<T> extends State<WheelPicker<T>> {
  late FixedExtentScrollController _internalController;
  /// Resolved scroll controller (external or internal fallback).
  FixedExtentScrollController get _controller =>
      widget.controller ?? _internalController;

  late T? _currentValue;
  late WheelEffect _effect;
  double _viewportHeight = 0;

  bool get _loop => widget.loop ?? false;
  bool get _expanded => widget.expanded ?? false;

  final _defaultItemBuilder = WheelItem.delegate();
  WheelItemBuilder<T> get _itemBuilder =>
      widget.itemBuilder ?? _defaultItemBuilder;

  List<T> get _options => widget.options;
  double get _itemExtent => widget.itemExtent ?? WheelItem.defaultExtent;
  int get _itemVisible => widget.itemVisible ?? 5;

  /// Index of the current value within [_options].
  int get _selectedIndex {
    final value = _currentValue;
    if (value == null || !_options.contains(value)) return 0;
    return _options.indexOf(value);
  }

  double get _fixedHeight => _itemExtent * _itemVisible;

  /// Resolved squeeze value accounting for expanded layout.
  double get _squeeze {
    if (_expanded && widget.itemVisible != null && _viewportHeight > 0) {
      return (widget.itemVisible! * _itemExtent) / _viewportHeight;
    }
    return _effect.squeezeX;
  }

  /// Whether the given [item] is disabled.
  bool _isDisabled(T item) => widget.itemDisabled?.call(item) ?? false;

  /// Wraps an item with semantics and tap-to-select behavior.
  Widget _wrapWithSemanticsAndTap({
    required T item,
    required Widget child,
    required bool disabled,
    required bool selected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (!disabled) {
          _controller.animateToItem(
            _loop ? _controller.selectedItem + (index - _selectedIndex) : index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      child: Semantics(
        button: true,
        selected: selected,
        enabled: !disabled,
        child: child,
      ),
    );
  }

  /// Resolves the string label for an [item].
  String _resolveLabel(T item) {
    return widget.itemLabel?.call(item) ?? item.toString();
  }

  /// Builds the list wheel child delegate (looping or finite).
  ListWheelChildDelegate get _childDelegate {
    if (_loop) {
      return ListWheelChildLoopingListDelegate(
        children: List.generate(_options.length, (index) {
          final item = _options[index];
          final disabled = _isDisabled(item);
          final selected = item == _currentValue;
          final label = _resolveLabel(item);
          final built = _itemBuilder(
            context,
            WheelItem(
              data: item,
              label: label,
              selected: selected && !disabled,
              disabled: disabled,
            ),
          );
          return SizedBox(
            height: _itemExtent,
            child: _wrapWithSemanticsAndTap(
              item: item,
              child: built,
              disabled: disabled,
              selected: selected,
              index: index,
            ),
          );
        }),
      );
    }

    return ListWheelChildBuilderDelegate(
      childCount: _options.length,
      builder: (context, index) {
        final item = _options[index];
        final disabled = _isDisabled(item);
        final selected = item == _currentValue;
        final label = _resolveLabel(item);
        final built = _itemBuilder(
          context,
          WheelItem(
            data: item,
            label: label,
            selected: selected && !disabled,
            disabled: disabled,
          ),
        );
        return SizedBox(
          height: _itemExtent,
          child: _wrapWithSemanticsAndTap(
            item: item,
            child: built,
            disabled: disabled,
            selected: selected,
            index: index,
          ),
        );
      },
    );
  }

  /// The configured wheel view with selection/disable handling.
  Widget get _wheelView {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        final index = _controller.selectedItem;
        final actualIndex = _loop ? index % _options.length : index;
        final item = _options[actualIndex];

        if (_isDisabled(item)) {
          final nearestIndex = _loop
              ? _findNearestEnabledIndexLoop(actualIndex)
              : _findNearestEnabledIndex(actualIndex);
          if (nearestIndex != actualIndex) {
            Future.microtask(() {
              _controller.animateToItem(
                _loop ? index + (nearestIndex - actualIndex) : nearestIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        }
        return false;
      },
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        useMagnifier: _effect.useMagnifierX,
        magnification: _effect.magnificationX,
        diameterRatio: _effect.diameterRatioX,
        perspective: _effect.perspectiveX,
        offAxisFraction: _effect.offAxisFractionX,
        overAndUnderCenterOpacity: _effect.overAndUnderCenterOpacityX,
        squeeze: _squeeze,
        onSelectedItemChanged: _onChanged,
        childDelegate: _childDelegate,
      ),
    );
  }

  /// Finds the nearest enabled index around [fromIndex] in loop mode.
  int _findNearestEnabledIndexLoop(int fromIndex) {
    final len = _options.length;
    int? bestIndex;
    int bestDistance = len;

    for (int offset = 1; offset < len; offset++) {
      final downIndex = (fromIndex + offset) % len;
      final upIndex = (fromIndex - offset + len) % len;

      if (!_isDisabled(_options[downIndex])) {
        final wraps = fromIndex > downIndex;
        final effectiveDistance = offset + (wraps ? len : 0);
        if (effectiveDistance < bestDistance) {
          bestDistance = effectiveDistance;
          bestIndex = downIndex;
        }
      }

      if (!_isDisabled(_options[upIndex])) {
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

  /// Finds the nearest enabled index around [fromIndex] in finite mode.
  int _findNearestEnabledIndex(int fromIndex) {
    int distance = 1;
    while (fromIndex - distance >= 0 ||
        fromIndex + distance < _options.length) {
      final down = fromIndex + distance;
      if (down < _options.length && !_isDisabled(_options[down])) {
        return down;
      }
      final up = fromIndex - distance;
      if (up >= 0 && !_isDisabled(_options[up])) {
        return up;
      }
      distance++;
    }
    return fromIndex;
  }

  /// Handles selection changes from the wheel.
  void _onChanged(int index) {
    final actualIndex = _loop ? index % _options.length : index;
    final newValue = _options[actualIndex];

    if (!_isDisabled(newValue) && _currentValue != newValue) {
      setState(() => _currentValue = newValue);
      widget.onChanged?.call(newValue);
    }
  }

  @override
  /// Initializes the internal state and controller.
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _effect = const WheelEffect().merge(widget.effect);
    _internalController =
        widget.controller ??
        FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  /// Keeps the controller position and effects in sync with widget updates.
  void didUpdateWidget(covariant WheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue) {
      _currentValue = widget.value;
      final newIndex = _selectedIndex;
      if (_controller.selectedItem != newIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.jumpToItem(newIndex);
        });
      }
    }
    if (widget.effect != oldWidget.effect) {
      _effect = const WheelEffect().merge(widget.effect);
    }
  }

  @override
  /// Lays out the wheel (and header when provided) with an optional overlay.
  Widget build(BuildContext context) {
    final picker = LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = _expanded ? constraints.maxHeight : _fixedHeight;
        return SizedBox(
          height: _viewportHeight,
          child: WheelOverlay(
            builder: widget.overlay,
            offset: widget.header?.extent,
            extent: _itemExtent,
            child: _wheelView,
          ),
        );
      },
    );

    if (widget.header != null) {
      return Column(children: [widget.header!, picker]);
    }
    return picker;
  }
}
