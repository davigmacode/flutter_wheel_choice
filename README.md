[![Pub Version](https://img.shields.io/pub/v/wheel_choice)](https://pub.dev/packages/wheel_choice) ![GitHub](https://img.shields.io/github/license/davigmacode/flutter_wheel_choice) [![GitHub](https://badgen.net/badge/icon/buymeacoffee?icon=buymeacoffee&color=yellow&label)](https://www.buymeacoffee.com/davigmacode) [![GitHub](https://badgen.net/badge/icon/ko-fi?icon=kofi&color=red&label)](https://ko-fi.com/davigmacode)

Wheel-shaped picker widget for Flutter. Scroll and select items with customizable header, overlays, magnifier and 3D effects, disabled items, looping, and custom item builders.

Demo: https://davigmacode.github.io/flutter_wheel_choice

## Features

- Customizable wheel/slot-style picker (`WheelChoice<T>`)
- Optional header (`WheelHeader`) aligned with the wheel viewport
- Overlays to highlight selection (outlined or filled via `WheelOverlay`)
- 3D look and magnifier (`WheelEffect`) with tunable perspective and diameter
- Item builder and label resolver (`WheelItem.delegate`, `itemLabel`)
- Disable items and optionally loop the list (`itemDisabled`, `loop`)
- Programmatic control with `WheelController`
- Reactive listeners: `valueListenable`, `indexListenable`
- Custom scroll `physics` and `clipBehavior`
- Adaptive height with `expanded` and `itemVisible`

## Installation

```sh
flutter pub add wheel_choice
```

Import:

```dart
import 'package:wheel_choice/wheel_choice.dart';
```

## Quick start

```dart
final picker = WheelChoice<String>(
  options: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  value: 'Wed',
  onChanged: (v) => debugPrint('Selected: $v'),
  itemVisible: 5, // should be odd
  header: const WheelHeader(child: Text('Day')),
  overlay: WheelOverlay.outlined(inset: 12),
  effect: const WheelEffect(useMagnifier: true, magnification: 1.1),
);
```

### Programmatic control

Use `WheelController` to change selection by value and keep options in sync.

```dart
final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
final controller = WheelController<String>(
  options: days,
  value: 'Wed',
  onChanged: (v) => debugPrint('Selected: $v'),
);

WheelChoice<String>.raw(controller: controller);

// Programmatically select a value later
await controller.setValue('Fri', animate: true);

// If your options list changes, update the controller too
controller.setOptions(const ['Tue', 'Wed', 'Thu']);
```

### Reactive listeners (no onChanged)

React to selection changes using `ValueListenableBuilder` without wiring `onChanged`:

```dart
final controller = WheelController<String>(options: days, value: 'Wed');

Column(
  children: [
    WheelChoice<String>.raw(controller: controller),
    const SizedBox(height: 8),
    ValueListenableBuilder<String?>(
      valueListenable: controller.valueListenable,
      builder: (context, v, _) => Text('Selected: ${v ?? '-'}'),
    ),
  ],
);
```

### Keyboard & haptics

Enable keyboard navigation (↑/↓, PgUp/PgDn, Home/End) and haptics:

```dart
WheelChoice<String>(
  options: days,
  value: 'Wed',
  keyboard: true, // focus the wheel to use keys
  haptics: true,  // selection click on scroll
)
```

Note (experimental):
- Keyboard and haptic feedback are experimental. APIs may evolve.
- Keyboard requires the wheel to be focused (click it or provide a FocusNode and request focus).
- Haptics are only felt on real devices; desktop/web/emulators typically do not vibrate.

## Examples

This package ships with a runnable example that demonstrates:

- Month + day pickers side-by-side (month loops)
- Time picker: hour, minute, AM/PM in a row, with programmatic controls
- Custom item builder with icons and expanded layout

Run locally:

```sh
cd example
flutter run
```

On desktop/web, enable mouse-drag scrolling by setting a `ScrollBehavior`:

```dart
MaterialApp(
  scrollBehavior: const MaterialScrollBehavior().copyWith(
    dragDevices: {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.stylus,
      PointerDeviceKind.trackpad,
    },
  ),
  // ...
)
```

## API Reference

See full docs on pub.dev: https://pub.dev/documentation/wheel_choice/latest/

Key exports:

- `WheelChoice<T>` — the main widget
- `WheelHeader` — header above the viewport
- `WheelOverlay` — selection overlays (outlined/filled)
- `WheelEffect` — magnifier, perspective, diameter, opacity, squeeze
- `WheelItem.delegate` — default item renderer

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Sponsoring

<a href="https://www.buymeacoffee.com/davigmacode" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45"></a>
<a href="https://ko-fi.com/davigmacode" target="_blank"><img src="https://storage.ko-fi.com/cdn/brandasset/kofi_s_tag_white.png" alt="Ko-Fi" height="45"></a>

If this package or any other package I created is helping you, please consider to sponsor me so that I can take time to read the issues, fix bugs, merge pull requests and add features to these packages.

