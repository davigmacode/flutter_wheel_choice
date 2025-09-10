import 'package:flutter/material.dart';
import 'item.dart';
import 'header.dart';
import 'effect.dart';
import 'overlay.dart';
import 'controller.dart';

/// A customizable picker widget that mimics a wheel or "slot machine"-like scroll selector.
///
/// Useful for building things like time selectors, value choosers, or
/// any dropdown-like vertical list with better UX.
///
/// Usage:
/// ```dart
/// final picker = WheelChoice<String>(
///   options: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
///   value: 'Wed',
///   onChanged: (v) => debugPrint('Selected: $v'),
///   itemLabel: (v) => 'Day: $v', // custom label resolver
///   itemDisabled: (v) => v == 'Thu', // disable certain items
///   itemBuilder: WheelItem.delegate(
///     selectedStyle: const TextStyle(fontSize: 18),
///   ),
///   itemVisible: 5, // should be odd
///   itemExtent: WheelItem.defaultExtent,
///   header: const WheelHeader(
///     child: Text('Pick a day'),
///   ),
///   overlay: WheelOverlay.outlined(inset: 12),
///   effect: const WheelEffect(
///     useMagnifier: true,
///     magnification: 1.1,
///   ),
///   loop: true,
/// );
/// ```
///
/// Notes:
/// - When `expanded` is true and `itemVisible` is set, the wheel adjusts `squeeze`
///   to fit the available height.
/// - If `value` is not in `options`, selection defaults to the first item.
/// - In `loop` mode, the picker wraps around; disabled items are skipped after scroll end.
class WheelChoice<T> extends StatefulWidget {
  /// Creates a [WheelChoice] with various customization options.
  const WheelChoice({
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
  ///
  /// Use [WheelController] to change selection by value and keep options
  /// in sync. When omitted, an internal controller is created.
  final WheelController<T>? controller;

  @override
  State<WheelChoice<T>> createState() => _WheelChoiceState<T>();
}

/// State and behavior for [WheelChoice].
class _WheelChoiceState<T> extends State<WheelChoice<T>> {
  late WheelEffect _effect;
  late WheelController<T> _internalController;

  /// Resolved scroll controller (external or internal fallback).
  WheelController<T> get _controller =>
      widget.controller ?? _internalController;

  double _viewportHeight = 0;

  bool get _expanded => widget.expanded ?? false;

  final _defaultItemBuilder = WheelItem.delegate();
  WheelItemBuilder<T> get _itemBuilder =>
      widget.itemBuilder ?? _defaultItemBuilder;
  double get _itemExtent => widget.itemExtent ?? WheelItem.defaultExtent;
  int get _itemVisible => widget.itemVisible ?? 5;

  double get _fixedHeight => _itemExtent * _itemVisible;

  /// Resolved squeeze value accounting for expanded layout.
  double get _squeeze {
    if (_expanded && widget.itemVisible != null && _viewportHeight > 0) {
      return (widget.itemVisible! * _itemExtent) / _viewportHeight;
    }
    return _effect.squeezeX;
  }

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
          _controller.animateToIndex(index);
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
    if (_controller.loop) {
      return ListWheelChildLoopingListDelegate(
        children: List.generate(_controller.options.length, (index) {
          final item = _controller.options[index];
          final disabled = _controller.isDisabled(item);
          final selected = item == _controller.value;
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
      childCount: _controller.options.length,
      builder: (context, index) {
        final item = _controller.options[index];
        final disabled = _controller.isDisabled(item);
        final selected = item == _controller.value;
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
        _controller.handleScrollEnd();
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
        onSelectedItemChanged: (i) {
          setState(() {
            _controller.handleIndexChanged(i);
          });
        },
        childDelegate: _childDelegate,
      ),
    );
  }

  @override
  /// Initializes the internal state and controller.
  void initState() {
    super.initState();
    _effect = const WheelEffect().merge(widget.effect);
    _internalController =
        widget.controller ??
        WheelController<T>(
          options: widget.options,
          value: widget.value,
          valueDisabled: widget.itemDisabled,
          onChanged: widget.onChanged,
          loop: widget.loop,
        );
    final ctrl = widget.controller;
    if (ctrl != null) {
      ctrl.setOptions(widget.options, alignToValue: true, animate: false);
      ctrl.setItemDisabled(widget.itemDisabled);
      ctrl.setOnChanged(widget.onChanged);
      ctrl.setLoop(widget.loop);
      final v = widget.value;
      if (v != null) {
        ctrl.setValue(v as T, animate: false, notify: false);
      }
    }
  }

  @override
  /// Keeps the controller position and effects in sync with widget updates.
  void didUpdateWidget(covariant WheelChoice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = widget.controller;
    if (ctrl != null) {
      if (!identical(widget.options, oldWidget.options) ||
          widget.options.length != oldWidget.options.length) {
        ctrl.setOptions(widget.options, alignToValue: true, animate: false);
      }
      if (widget.itemDisabled != oldWidget.itemDisabled) {
        ctrl.setItemDisabled(widget.itemDisabled);
      }
      if (widget.onChanged != oldWidget.onChanged) {
        ctrl.setOnChanged(widget.onChanged);
      }
      if ((widget.loop) != (oldWidget.loop)) {
        ctrl.setLoop(widget.loop);
      }
    }
    if (widget.value != _controller.value && widget.value != null) {
      ctrl?.setValue(widget.value as T, animate: false, notify: false);
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
