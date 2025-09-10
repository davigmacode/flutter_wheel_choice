import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wheel_choice/wheel_choice.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('WheelChoice builds and shows header and overlay', (
    tester,
  ) async {
    final controller = WheelController<String>(
      options: const ['A', 'B', 'C'],
      value: 'A',
    );
    await tester.pumpWidget(
      _wrap(
        WheelChoice<String>(
          controller: controller,
          options: const ['A', 'B', 'C'],
          value: 'A',
          header: const WheelHeader(child: Text('Header')),
          overlay: (_) => Container(key: const Key('overlay')),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.byKey(const Key('overlay')), findsOneWidget);
  });

  testWidgets('WheelChoice onChanged fires when selecting enabled item', (
    tester,
  ) async {
    String? changed;
    final controller = WheelController<String>(
      options: const ['One', 'Two', 'Three'],
      value: 'One',
    );
    await tester.pumpWidget(
      _wrap(
        WheelChoice<String>(
          controller: controller,
          options: const ['One', 'Two', 'Three'],
          value: 'One',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    // Drag up roughly one item extent to move selection to 'Two'.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(changed, equals('Two'));
    expect(controller.selectedItem % 3, 1);
  });

  testWidgets('WheelChoice skips disabled item after scroll end (finite)', (
    tester,
  ) async {
    final controller = WheelController<String>(
      options: const ['A', 'B', 'C'],
      value: 'A',
    );
    final calls = <String>[];
    await tester.pumpWidget(
      _wrap(
        WheelChoice<String>(
          controller: controller,
          options: const ['A', 'B', 'C'],
          value: 'A',
          itemDisabled: (v) => v == 'B',
          onChanged: calls.add,
        ),
      ),
    );

    // Attempt to land on disabled 'B'. The picker should settle on 'C'.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -40));
    await tester.pumpAndSettle();

    // Should not call with 'B'; final selection should be 'C'.
    expect(calls.contains('B'), isFalse);
    expect(calls.contains('C'), isTrue);
    expect(controller.selectedItem, 2);
  });

  testWidgets('WheelChoice loop mode: disabled snaps to nearest enabled', (
    tester,
  ) async {
    final controller = WheelController<String>(
      options: const ['A', 'B', 'C'],
      value: 'B', // Start at 'B'
    );
    final calls = <String>[];
    await tester.pumpWidget(
      _wrap(
        WheelChoice<String>(
          controller: controller,
          options: const ['A', 'B', 'C'],
          value: 'B',
          loop: true,
          itemDisabled: (v) => v == 'A',
          onChanged: calls.add,
        ),
      ),
    );

    // Try to go to disabled 'A' (drag down to move selection up by -1 index)
    // Use a slightly larger drag to ensure boundary crossing on all platforms.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, 50));
    await tester.pumpAndSettle();

    // In loop, landing on disabled 'A' should snap to a non-disabled option.
    // onChanged may not fire if it snaps back to the original value ('B').
    expect(calls.contains('A'), isFalse);
    expect(controller.selectedItem % 3, isNot(0));
  });

  testWidgets('WheelEffect props are applied to ListWheelScrollView', (
    tester,
  ) async {
    const effect = WheelEffect(
      useMagnifier: true,
      magnification: 1.2,
      diameterRatio: 2.5,
      perspective: 0.004,
      offAxisFraction: 0.1,
      overAndUnderCenterOpacity: 0.6,
      squeeze: 0.9,
    );

    await tester.pumpWidget(
      _wrap(
        const WheelChoice<String>(
          options: ['X', 'Y', 'Z'],
          value: 'X',
          effect: effect,
        ),
      ),
    );

    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView),
    );
    expect(wheel.useMagnifier, isTrue);
    expect(wheel.magnification, equals(1.2));
    expect(wheel.diameterRatio, equals(2.5));
    expect(wheel.perspective, equals(0.004));
    expect(wheel.offAxisFraction, equals(0.1));
    expect(wheel.overAndUnderCenterOpacity, equals(0.6));
    expect(wheel.squeeze, equals(0.9));
  });
}
