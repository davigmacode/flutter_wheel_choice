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
  /// Creates a wheel chooser with a built-in [WheelController].
  ///
  /// This convenience constructor is ideal when you want a self-contained
  /// picker without managing a controller instance. It wires the provided
  /// configuration into an internal controller and the wheel view.
  ///
  /// Usage:
  /// ```dart
  /// WheelChoice<String>(
  ///   options: const ['Mon', 'Tue', 'Wed'],
  ///   value: 'Tue',
  ///   onChanged: (v) => debugPrint('Selected: $v'),
  ///   itemVisible: 5,
  ///   header: const WheelHeader(child: Text('Day')),
  ///   overlay: WheelOverlay.outlined(inset: 12),
  ///   effect: const WheelEffect(useMagnifier: true, magnification: 1.1),
  /// )
  /// ```
  ///
  /// Parameters (controller-related):
  /// - [options]: List of selectable values. Used by the internal controller
  ///   to resolve indices and values.
  /// - [value]: Initial selected value (if present in [options]).
  /// - [onChanged]: Invoked when selection changes (user or programmatic).
  /// - [itemDisabled]: Predicate to mark specific values as disabled.
  /// - [loop]: Enables wrap-around semantics and nearest-enabled snapping.
  /// - [animationDuration]/[animationCurve]: Defaults for animated moves
  ///   (e.g., when tapping an item or calling animate APIs).
  ///
  /// Parameters (view-related):
  /// - [itemLabel]: Optional label resolver; defaults to `value.toString()`.
  /// - [itemBuilder]: Optional custom row builder; defaults to
  ///   [WheelItem.delegate].
  /// - [itemVisible]: Visible row count (odd recommended for centering).
  /// - [itemExtent]: Row height. If omitted in expanded mode, it is derived
  ///   from the viewport height to fit exactly.
  /// - [header]: Optional header row above the wheel viewport.
  /// - [overlay]: Optional overlay over the viewport (e.g., selection lines).
  /// - [effect]: 3D look and magnifier configuration.
  /// - [physics]: Optional scroll physics.
  /// - [clipBehavior]: Optional viewport clipping.
  /// - [expanded]: If true, the wheel adapts to the parent height and adjusts
  ///   squeeze/itemExtent accordingly.
  ///
  /// Ownership:
  /// - This constructor creates and owns an internal [WheelController]. The
  ///   widget disposes it on unmount. If you need to reuse or externally
  ///   control the controller, prefer [WheelChoice.raw].
  WheelChoice({
    super.key,
    T? value,
    List<T>? options,
    ValueChanged<T>? onChanged,
    bool? loop,
    Duration? animationDuration,
    Curve? animationCurve,
    WheelItemDisable<T>? itemDisabled,
    this.itemLabel,
    this.itemBuilder,
    this.itemVisible,
    this.itemExtent,
    this.header,
    this.overlay,
    this.effect,
    this.physics,
    this.clipBehavior,
    this.expanded,
  }) : controller = WheelController(
         value: value,
         options: options,
         onChanged: onChanged,
         itemDisabled: itemDisabled,
         loop: loop,
         animationDuration: animationDuration,
         animationCurve: animationCurve,
       ),
       _ownsController = true;

  /// Creates a wheel chooser using an external [controller].
  ///
  /// Use this when you need to hold and reuse a [WheelController] across
  /// widgets, set the selection programmatically (e.g., `setValue`,
  /// `animateToIndex`), or listen reactively via `valueListenable`/
  /// `indexListenable`.
  ///
  /// The widget does not own the [controller]; you are responsible for
  /// disposing it when no longer needed.
  const WheelChoice.raw({
    super.key,
    required this.controller,
    this.itemLabel,
    this.itemBuilder,
    this.itemVisible,
    this.itemExtent,
    this.header,
    this.overlay,
    this.effect,
    this.physics,
    this.clipBehavior,
    this.expanded,
  }) : _ownsController = false;

  /// Resolves a string label from a value for default item rendering.
  /// If not provided, `value.toString()` is used.
  final WheelItemLabel<T>? itemLabel;

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

  /// Optional scroll physics to use for the wheel.
  final ScrollPhysics? physics;

  /// Optional clip behavior for the wheel viewport.
  final Clip? clipBehavior;

  /// Whether to automatically expand to parent height.
  final bool? expanded;

  /// Scroll controller for programmatic control.
  ///
  /// Use [WheelController] to change selection by value and keep options
  /// in sync. When omitted, an internal controller is created.
  final WheelController<T> controller;

  /// Whether this widget instance owns [controller] and should dispose it.
  final bool _ownsController;

  @override
  State<WheelChoice<T>> createState() => _WheelChoiceState<T>();
}

/// State and behavior for [WheelChoice].
class _WheelChoiceState<T> extends State<WheelChoice<T>> {
  late bool _expanded;
  late WheelEffect _effect;
  late WheelItemBuilder<T> _itemBuilder;
  late WheelController<T> _ctrl;

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
          physics: widget.physics,
          clipBehavior: widget.clipBehavior,
          itemExtent: itemExtent,
          childDelegate: _childDelegate(context, itemBuilder),
        ),
      ),
    );
  }

  Widget _expandedPicker(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final hasFiniteHeight = viewportHeight.isFinite && viewportHeight > 0;

        // Derive item extent and visible count from the available height.
        final baseExtent = widget.itemExtent ?? WheelItem.defaultExtent;
        int? desiredVisible = widget.itemVisible;
        double itemExtent;
        int itemVisible;

        if (hasFiniteHeight) {
          if (desiredVisible != null) {
            // Ensure odd count for a centered selection line
            if (desiredVisible % 2 == 0) desiredVisible += 1;
            itemVisible = desiredVisible;
            itemExtent = viewportHeight / itemVisible;
          } else {
            // Start from base extent, infer a suitable odd visible count
            itemExtent = baseExtent;
            itemVisible = (viewportHeight / itemExtent).round();
            if (itemVisible < 1) itemVisible = 1;
            if (itemVisible % 2 == 0) itemVisible += 1;
            // Recompute extent to perfectly fill the viewport
            itemExtent = viewportHeight / itemVisible;
          }
        } else {
          // Fallback when height is unknown or infinite
          itemExtent = baseExtent;
          itemVisible = desiredVisible ?? 5;
          if (itemVisible % 2 == 0) itemVisible += 1;
        }

        final effectiveHeight = hasFiniteHeight
            ? viewportHeight
            : itemExtent * itemVisible;

        final itemBuilder = _childBuilder(itemExtent);
        // Squeeze to make the wheel fill the viewport exactly when bounded.
        final double squeeze = hasFiniteHeight
            ? (itemVisible * itemExtent) / effectiveHeight
            : _effect.squeezeX;

        return SizedBox(
          height: effectiveHeight,
          child: WheelOverlay(
            builder: widget.overlay,
            offset: widget.header?.extent,
            extent: itemExtent,
            child: _WheelView(
              controller: _ctrl,
              effect: _effect.copyWith(squeeze: squeeze),
              physics: widget.physics,
              clipBehavior: widget.clipBehavior,
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

    _ctrl = widget.controller;
    _expanded = widget.expanded ?? false;
    _effect = const WheelEffect().merge(widget.effect);
    _itemBuilder = widget.itemBuilder ?? WheelItem.delegate();
  }

  @override
  /// Keeps the controller position and effects in sync with widget updates.
  void didUpdateWidget(covariant WheelChoice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller instance changed, update our reference and
    // dispose the old one if this widget owned it.
    if (!identical(widget.controller, oldWidget.controller)) {
      if (oldWidget._ownsController) {
        oldWidget.controller.dispose();
      }
      _ctrl = widget.controller;
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
    // Dispose only when WheelChoice owns the controller (default ctor).
    if (widget._ownsController) {
      widget.controller.dispose();
    }
    super.dispose();
  }

  @override
  /// Lays out the wheel (and header when provided) with an optional overlay.
  Widget build(BuildContext context) {
    final picker = _expanded ? _expandedPicker(context) : _fixedPicker(context);
    if (widget.header != null) {
      return Column(
        children: [
          widget.header!,
          _expanded ? Expanded(child: picker) : picker,
        ],
      );
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
    this.physics,
    this.clipBehavior,
  });

  final WheelController controller;
  final WheelEffect effect;
  final double itemExtent;
  final ListWheelChildDelegate childDelegate;
  final ScrollPhysics? physics;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        controller.handleScrollEnd();
        return false;
      },
      child: ListWheelScrollView.useDelegate(
        physics: physics ?? const FixedExtentScrollPhysics(),
        controller: controller,
        itemExtent: itemExtent,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
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
