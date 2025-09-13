import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  /// - [keyboard] (Experimental): When true, enables basic keyboard navigation
  ///   (↑/↓, PgUp/PgDn, Home/End). Focus the wheel to use. Defaults to `false`.
  /// - [focusNode] (Experimental): Optional focus node used when [keyboard] is true.
  /// - [haptics] (Experimental): When true, plays a selection click haptic on
  ///   selection change from user scroll. Defaults to `false`. Only effective on
  ///   supported devices; desktop/web/emulators typically do not vibrate.
  ///
  /// Ownership:
  /// - This constructor creates and owns an internal [WheelController]. The
  ///   widget disposes it on unmount. If you need to reuse or externally
  ///   control the controller, prefer [WheelChoice.raw].
  const WheelChoice({
    super.key,
    this.value,
    this.options,
    this.onChanged,
    this.loop,
    this.animationDuration,
    this.animationCurve,
    this.itemDisabled,
    this.itemLabel,
    this.itemBuilder,
    this.itemVisible,
    this.itemExtent,
    this.header,
    this.overlay,
    this.effect,
    this.physics,
    this.clipBehavior,
    this.keyboard,
    this.focusNode,
    this.haptics,
    this.expanded,
  }) : controller = null;

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
    required WheelController<T> this.controller,
    this.itemLabel,
    this.itemBuilder,
    this.itemVisible,
    this.itemExtent,
    this.header,
    this.overlay,
    this.effect,
    this.physics,
    this.clipBehavior,
    this.keyboard,
    this.focusNode,
    this.haptics,
    this.expanded,
  }) : value = null,
       options = null,
       onChanged = null,
       loop = null,
       animationDuration = null,
       animationCurve = null,
       itemDisabled = null;

  /// Scroll controller for programmatic control.
  ///
  /// Use [WheelController] to change selection by value and keep options
  /// in sync. When `null`, an internal controller is created and owned by
  /// this widget (default constructor variant).
  final WheelController<T>? controller;

  /// Initial selected value for the internal controller (default ctor).
  ///
  /// If present in [options], the wheel will start aligned to this value.
  /// Ignored by [WheelChoice.raw].
  final T? value;

  /// The list of selectable values (default ctor).
  /// Ignored by [WheelChoice.raw].
  final List<T>? options;

  /// Called when the selection changes (user or programmatic).
  /// Ignored by [WheelChoice.raw].
  final ValueChanged<T>? onChanged;

  /// Enables wrap-around semantics for programmatic moves and nearest-enabled
  /// snapping after settle (default ctor). Ignored by [WheelChoice.raw].
  final bool? loop;

  /// Default animation duration for animated moves in the internal controller
  /// (default ctor). Ignored by [WheelChoice.raw].
  final Duration? animationDuration;

  /// Default animation curve for animated moves in the internal controller
  /// (default ctor). Ignored by [WheelChoice.raw].
  final Curve? animationCurve;

  /// Predicate for disabled values (default ctor). Ignored by [WheelChoice.raw].
  final WheelItemDisable<T>? itemDisabled;

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

  /// (Experimental) Enables keyboard navigation (when focused).
  /// Defaults to `false`.
  final bool? keyboard;

  /// (Experimental) Focus node used when [keyboard] is true.
  final FocusNode? focusNode;

  /// (Experimental) Plays selection click haptic on user scroll.
  /// Defaults to `false`. Only effective on supported devices.
  final bool? haptics;

  /// Whether to automatically expand to parent height.
  final bool? expanded;

  @override
  State<WheelChoice<T>> createState() => _WheelChoiceState<T>();
}

/// State and behavior for [WheelChoice].
class _WheelChoiceState<T> extends State<WheelChoice<T>> {
  WheelController<T>? _defaultCtrl;
  WheelController<T> get _ctrl => widget.controller ?? _ensureCtrl();
  WheelController<T> _ensureCtrl() {
    return _defaultCtrl ??= WheelController(
      value: widget.value,
      options: widget.options,
      onChanged: widget.onChanged,
      itemDisabled: widget.itemDisabled,
      loop: widget.loop,
      animationDuration: widget.animationDuration,
      animationCurve: widget.animationCurve,
    );
  }

  bool? _defaultExpanded;
  bool _ensureExpanded() => _defaultExpanded ??= false;
  bool get _expanded => widget.expanded ?? _ensureExpanded();

  WheelEffect? _defaultEffect;
  WheelEffect _ensureEffect() => _defaultEffect ??= WheelEffect();
  WheelEffect get _effect => widget.effect ?? _ensureEffect();

  WheelItemBuilder<T>? _defaultItemBuilder;
  WheelItemBuilder<T> _ensureItemBuilder() =>
      _defaultItemBuilder ??= WheelItem.delegate();
  WheelItemBuilder<T> get _itemBuilder =>
      widget.itemBuilder ?? _ensureItemBuilder();

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
    final itemDelegate = _childDelegate(context, itemBuilder);
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
          keyboardEnabled: widget.keyboard ?? false,
          focusNode: widget.focusNode,
          hapticsEnabled: widget.haptics ?? false,
          itemExtent: itemExtent,
          childDelegate: itemDelegate,
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
        final itemDelegate = _childDelegate(context, itemBuilder);

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
              keyboardEnabled: widget.keyboard ?? false,
              focusNode: widget.focusNode,
              hapticsEnabled: widget.haptics ?? false,
              itemExtent: itemExtent,
              childDelegate: itemDelegate,
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
  }

  @override
  /// Keeps the controller position and effects in sync with widget updates.
  void didUpdateWidget(covariant WheelChoice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If switching from internal to external controller, dispose internal.
    if (oldWidget.controller == null && widget.controller != null) {
      _defaultCtrl?.dispose();
      _defaultCtrl = null;
    }

    // If using internal controller, update it based on param changes.
    if (widget.controller == null) {
      // Create internal if not yet created and needed later.
      // For value change, keep options stable and jump to the new date.
      if (widget.value != null && widget.value != oldWidget.value) {
        _defaultCtrl?.jumpToValue(widget.value as T, notify: false);
      }

      if (widget.onChanged != oldWidget.onChanged) {
        _defaultCtrl?.setOnChanged(widget.onChanged);
      }

      if (widget.itemDisabled != oldWidget.itemDisabled) {
        _defaultCtrl?.setItemDisabled(widget.itemDisabled);
      }

      if (widget.loop != oldWidget.loop) {
        _defaultCtrl?.setLoop(widget.loop);
      }

      if (widget.animationDuration != oldWidget.animationDuration ||
          widget.animationCurve != oldWidget.animationCurve) {
        _defaultCtrl?.setAnimationDefaults(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose internal controller if we created one.
    _defaultCtrl?.dispose();
    _defaultCtrl = null;
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
    this.keyboardEnabled = false,
    this.focusNode,
    this.hapticsEnabled = false,
  });

  final WheelController controller;
  final WheelEffect effect;
  final double itemExtent;
  final ListWheelChildDelegate childDelegate;
  final ScrollPhysics? physics;
  final Clip? clipBehavior;
  final bool keyboardEnabled;
  final FocusNode? focusNode;
  final bool hapticsEnabled;

  static const int _pageDelta = 3;

  @override
  Widget build(BuildContext context) {
    Widget wheel = NotificationListener<ScrollEndNotification>(
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
          if (hapticsEnabled) {
            HapticFeedback.selectionClick();
          }
        },
        childDelegate: childDelegate,
      ),
    );

    if (keyboardEnabled) {
      wheel = Focus(
        focusNode: focusNode,
        canRequestFocus: true,
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.arrowUp): const _WheelScrollIntent(-1),
            LogicalKeySet(LogicalKeyboardKey.arrowDown): const _WheelScrollIntent(1),
            LogicalKeySet(LogicalKeyboardKey.pageUp): const _WheelScrollIntent(-_pageDelta),
            LogicalKeySet(LogicalKeyboardKey.pageDown): const _WheelScrollIntent(_pageDelta),
            LogicalKeySet(LogicalKeyboardKey.home): const _WheelHomeEndIntent(true),
            LogicalKeySet(LogicalKeyboardKey.end): const _WheelHomeEndIntent(false),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _WheelScrollIntent: CallbackAction<_WheelScrollIntent>(
                onInvoke: (intent) {
                  final next = controller.selectedIndex + intent.delta;
                  controller.animateToIndex(next);
                  return null;
                },
              ),
              _WheelHomeEndIntent: CallbackAction<_WheelHomeEndIntent>(
                onInvoke: (intent) {
                  final idx = intent.home ? 0 : controller.options.length - 1;
                  controller.animateToIndex(idx);
                  return null;
                },
              ),
            },
            child: wheel,
          ),
        ),
      );
    }

    return wheel;
  }
}

class _WheelScrollIntent extends Intent {
  const _WheelScrollIntent(this.delta);
  final int delta;
}

class _WheelHomeEndIntent extends Intent {
  const _WheelHomeEndIntent(this.home);
  final bool home;
}
