import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wheel_choice/wheel_choice.dart';

void main() => runApp(const WheelChoiceExampleApp());

class WheelChoiceExampleApp extends StatelessWidget {
  const WheelChoiceExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'wheel_choice example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static final _minutes = List<int>.generate(60, (i) => i);
  static const _fruits = ['Apple', 'Banana', 'Cherry', 'Grape', 'Mango'];

  String _day = 'Wed';
  int _minute = 30;
  String _fruit = 'Banana';

  late final WheelController<int> _minuteController = WheelController<int>(
    options: _minutes,
    value: _minute,
    onChanged: (v) => setState(() => _minute = v),
    valueDisabled: (v) => v % 5 != 0, // only multiples of 5
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeOutCubic,
    loop: true,
  );

  @override
  Widget build(BuildContext context) {
    final section1 = _Section(
      title: 'Basic',
      subtitle: 'Pick a day',
      children: [
        WheelChoice<String>(
          options: _days,
          value: _day,
          onChanged: (v) => setState(() => _day = v),
          itemBuilder: WheelItem.delegate(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            selectedStyle: const TextStyle(fontSize: 18),
          ),
          itemVisible: 5,
          overlay: WheelOverlay.outlined(inset: 12),
          effect: const WheelEffect(useMagnifier: true, magnification: 1.05),
          header: const WheelHeader(child: Text('Day')),
        ),
        Text('Selected: $_day'),
      ],
    );

    final section2 = _Section(
      title: 'Numeric with disabled items',
      subtitle: 'Pick minutes',
      children: [
        SizedBox(
          height: 300,
          child: WheelChoice<int>(
            controller: _minuteController,
            itemLabel: (v) => v.toString().padLeft(2, '0'),
            overlay: WheelOverlay.filled(
              color: Colors.indigo.withValues(alpha: 0.06),
              cornerRadius: 8,
              inset: 12,
            ),
            effect: const WheelEffect.flat(
              useMagnifier: true,
              magnification: 1.12,
              perspective: 0.0025,
            ),
            header: const WheelHeader(child: Text('Minutes')),
            expanded: true,
            loop: true,
          ),
        ),
        Text('Selected: ${_minute.toString().padLeft(2, '0')}'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => _minuteController.animateToValue(45),
              child: const Text('Animate to 45'),
            ),
            ElevatedButton(
              onPressed: () => _minuteController.jumpToValue(0),
              child: const Text('Jump to 00'),
            ),
            ElevatedButton(
              onPressed: () {
                final next = _minuteController.selectedIndex + 1;
                _minuteController.animateToIndex(next);
              },
              child: const Text('Next index'),
            ),
          ],
        ),
      ],
    );

    final section3 = _Section(
      title: 'Custom layout + expanded',
      subtitle: 'Custom item builder and expanded wheel',
      children: [
        SizedBox(
          height: 180,
          child: WheelChoice<String>(
            options: _fruits,
            value: _fruit,
            onChanged: (v) => setState(() => _fruit = v),
            itemBuilder: (context, item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: item.selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: item.selected ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    if (item.selected) const Icon(Icons.check_circle, size: 18),
                  ],
                ),
              );
            },
            itemVisible: 5,
            overlay: WheelOverlay.outlined(inset: 8),
            effect: const WheelEffect(diameterRatio: 2.2, perspective: 0.003),
            expanded: true,
          ),
        ),
        Text('Selected: $_fruit'),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('wheel_choice example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(spacing: 16, children: [section1, section2, section3]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              minTileHeight: 0,
            ),
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}
