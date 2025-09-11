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
    this.value,
    this.options,
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
  final List<T>? options;

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
  late bool _expanded;
  late WheelEffect _effect;
  late WheelItemBuilder<T> _itemBuilder;
  late WheelController<T> _internalCtrl;

  /// Resolved scroll controller (external or internal fallback).
  WheelController<T> get _ctrl => widget.controller ?? _internalCtrl;

  IndexedWidgetBuilder _childBuilder(double extent) {
    return (context, i) {
      final item = _ctrl.options[i];
      final disabled = _ctrl.isDisabled(item);
      final selected = item == _ctrl.value;
      final label = widget.itemLabel?.call(item) ?? item.toString();
      final built = _itemBuilder(
        context,
        WheelItem(
          data: item,
          label: label,
          selected: selected && !disabled,
          disabled: disabled,
        ),
      );

      // Wraps an item with semantics and tap-to-select behavior.
      return SizedBox(
        height: extent,
        child: GestureDetector(
          onTap: () {
            if (!disabled) _ctrl.animateToIndex(i);
          },
          child: Semantics(
            button: true,
            selected: selected,
            enabled: !disabled,
            child: built,
          ),
        ),
      );
    };
  }

  /// Builds the list wheel child delegate (looping or finite).
  ListWheelChildDelegate _childDelegate(
    BuildContext context,
    IndexedWidgetBuilder builder,
  ) {
    if (_ctrl.loop) {
      return ListWheelChildLoopingListDelegate(
        children: List.generate(
          _ctrl.options.length,
          (i) => builder(context, i),
        ),
      );
    }
    return ListWheelChildBuilderDelegate(
      childCount: _ctrl.options.length,
      builder: builder,
    );
  }

  Widget _fixedPicker(BuildContext context) {
    final itemExtent = widget.itemExtent ?? WheelItem.defaultExtent;
    final itemVisible = widget.itemVisible ?? 5;
    final itemBuilder = _childBuilder(itemExtent);
    final viewportHeight = itemExtent * itemVisible;
    return SizedBox(
      height: viewportHeight,
      child: WheelOverlay(
        builder: widget.overlay,
        offset: widget.header?.extent,
        extent: itemExtent,
        child: _WheelView(
          controller: _ctrl,
          effect: _effect,
          itemExtent: itemExtent,
          childDelegate: _childDelegate(context, itemBuilder),
        ),
      ),
    );
  }

  Widget _expandedPicker(BuildContext context) {
    final itemExtent = widget.itemExtent ?? WheelItem.defaultExtent;
    final itemBuilder = _childBuilder(itemExtent);
    final itemVisible = widget.itemVisible;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;

        /// Resolved squeeze value accounting for expanded layout.
        double? squeeze;

        if (_expanded && itemVisible != null && viewportHeight > 0) {
          squeeze = (itemVisible * itemExtent) / viewportHeight;
        }

        return SizedBox(
          height: viewportHeight,
          child: WheelOverlay(
            builder: widget.overlay,
            offset: widget.header?.extent,
            extent: itemExtent,
            child: _WheelView(
              controller: _ctrl,
              effect: _effect.copyWith(squeeze: squeeze),
              itemExtent: itemExtent,
              childDelegate: _childDelegate(context, itemBuilder),
            ),
          ),
        );
      },
    );
  }

  @override
  /// Initializes the internal state and controller.
  void initState() {
    super.initState();
    final ctrl = widget.controller;

    _internalCtrl =
        ctrl ??
        WheelController<T>(
          options: widget.options,
          value: widget.value,
          valueDisabled: widget.itemDisabled,
          onChanged: widget.onChanged,
          loop: widget.loop,
        );

    if (ctrl != null) {
      if (widget.options != null) {
        _internalCtrl.setOptions(
          widget.options,
          alignToValue: true,
          animate: false,
        );
      }
      if (widget.itemDisabled != null) {
        _internalCtrl.setItemDisabled(widget.itemDisabled);
      }
      if (widget.onChanged != null) {
        _internalCtrl.setOnChanged(widget.onChanged);
      }
      if (widget.loop != null) {
        _internalCtrl.setLoop(widget.loop);
      }
      if (widget.value != null) {
        _internalCtrl.setValue(
          widget.value as T,
          animate: false,
          notify: false,
        );
      }
    }

    _expanded = widget.expanded ?? false;
    _effect = const WheelEffect().merge(widget.effect);
    _itemBuilder = widget.itemBuilder ?? WheelItem.delegate();
  }

  @override
  /// Keeps the controller position and effects in sync with widget updates.
  void didUpdateWidget(covariant WheelChoice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = widget.controller;
    if (ctrl != null) {
      if (!identical(widget.options, oldWidget.options) ||
          widget.options != oldWidget.options ||
          widget.options?.length != oldWidget.options?.length) {
        ctrl.setOptions(widget.options, alignToValue: true, animate: false);
      }
      if (widget.itemDisabled != oldWidget.itemDisabled) {
        ctrl.setItemDisabled(widget.itemDisabled);
      }
      if (widget.onChanged != oldWidget.onChanged) {
        ctrl.setOnChanged(widget.onChanged);
      }
      if (widget.loop != oldWidget.loop) {
        ctrl.setLoop(widget.loop);
      }
    }
    if (widget.value != _ctrl.value && widget.value != null) {
      ctrl?.setValue(widget.value as T, animate: false, notify: false);
    }
    if (widget.expanded != oldWidget.expanded) {
      _expanded = widget.expanded ?? false;
    }
    if (widget.effect != oldWidget.effect) {
      _effect = const WheelEffect().merge(widget.effect);
    }
    if (widget.itemBuilder != oldWidget.itemBuilder) {
      _itemBuilder = widget.itemBuilder ?? WheelItem.delegate();
    }
  }

  @override
  void dispose() {
    // Dispose only when using the internal controller we created.
    if (widget.controller == null) {
      _internalCtrl.dispose();
    }
    super.dispose();
  }

  @override
  /// Lays out the wheel (and header when provided) with an optional overlay.
  Widget build(BuildContext context) {
    final picker = _expanded ? _expandedPicker(context) : _fixedPicker(context);
    if (widget.header != null) {
      return Column(children: [widget.header!, picker]);
    }
    return picker;
  }
}

class _WheelView extends StatelessWidget {
  const _WheelView({
    required this.controller,
    required this.effect,
    required this.itemExtent,
    required this.childDelegate,
  });

  final WheelController controller;
  final WheelEffect effect;
  final double itemExtent;
  final ListWheelChildDelegate childDelegate;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        controller.handleScrollEnd();
        return false;
      },
      child: ListWheelScrollView.useDelegate(
        physics: const FixedExtentScrollPhysics(),
        controller: controller,
        itemExtent: itemExtent,
        useMagnifier: effect.useMagnifierX,
        magnification: effect.magnificationX,
        diameterRatio: effect.diameterRatioX,
        perspective: effect.perspectiveX,
        offAxisFraction: effect.offAxisFractionX,
        overAndUnderCenterOpacity: effect.overAndUnderCenterOpacityX,
        squeeze: effect.squeezeX,
        onSelectedItemChanged: (i) {
          controller.handleIndexChanged(i);
        },
        childDelegate: childDelegate,
      ),
    );
  }
}
