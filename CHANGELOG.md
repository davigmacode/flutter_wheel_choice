## 1.1.0
- New: `WheelController<T>` for programmatic control (set/jump/animate by
  value or index), plus `valueListenable` and `indexListenable` for reactive
  integrations.
- Behavior: Animated moves are disabled-aware (snap to nearest enabled);
  direct jumps can land on disabled by design.
- Widget: Added `physics` and `clipBehavior` props; improved expanded sizing
  (derives `itemExtent` from viewport and enforces odd `itemVisible`).
- UX: Better month/day and time pickers in example; mouse-drag scrolling in
  example; docs expanded with constructors and reactive listeners.
- Internal: Ownership model for controller (`WheelChoice(...)` owns and
  disposes; `WheelChoice.raw(...)` uses external controller).

## 1.0.1
- Fix: formatting to satisfy `dart format`/lints.

## 1.0.0
- Initial stable release.
- Core widgets and APIs:
  - `WheelChoice`: customizable wheel/slot-style picker.
  - `WheelHeader`: optional header row with styling.
  - `WheelItem.delegate`: default item renderer utilities.
  - `WheelOverlay`: outlined and filled selection overlays.
  - `WheelEffect`: 3D look, magnifier, and perspective settings.
- Example app:
  - Includes basic day picker, numeric minutes picker (multiples of 5), and a custom layout demo.
  - Desktop/web friendly: mouse drag scrolling enabled via `MaterialApp.scrollBehavior`.
- Metadata:
  - Package description updated (English).
