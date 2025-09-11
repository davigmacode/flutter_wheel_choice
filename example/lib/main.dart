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
  static final _hours = List<int>.generate(12, (i) => i + 1);
  static final _minutes = List<int>.generate(60, (i) => i);
  static const _periods = ['AM', 'PM'];
  static const _fruits = ['Apple', 'Banana', 'Cherry', 'Grape', 'Mango'];

  String _day = 'Wed';
  int _hour = 10;
  int _minute = 30;
  String _period = 'AM';
  String _fruit = 'Banana';

  late final _hourController = WheelController<int>(
    options: _hours,
    value: _hour,
    onChanged: (v) => setState(() => _hour = v),
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeOutCubic,
  );

  late final _minuteController = WheelController<int>(
    options: _minutes,
    value: _minute,
    onChanged: (v) => setState(() => _minute = v),
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeOutCubic,
  );

  late final _periodController = WheelController<String>(
    options: _periods,
    value: _period,
    onChanged: (v) => setState(() => _period = v),
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeOutCubic,
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
      title: 'Time picker',
      subtitle: 'Pick hour, minute, and AM/PM',
      children: [
        SizedBox(
          height: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: WheelChoice<int>.raw(
                  controller: _hourController,
                  itemLabel: (v) => v.toString().padLeft(2, '0'),
                  overlay: WheelOverlay.outlined(inset: 0),
                  effect: WheelEffect.flat(),
                  header: const WheelHeader(child: Text('Hour')),
                  expanded: true,
                  // loop: true,
                ),
              ),
              Expanded(
                child: WheelChoice<int>.raw(
                  controller: _minuteController,
                  itemLabel: (v) => v.toString().padLeft(2, '0'),
                  overlay: WheelOverlay.outlined(inset: 0),
                  effect: WheelEffect.flat(),
                  header: const WheelHeader(child: Text('Minute')),
                  expanded: true,
                  // loop: true,
                ),
              ),
              Expanded(
                child: WheelChoice<String>.raw(
                  controller: _periodController,
                  overlay: WheelOverlay.outlined(inset: 0),
                  effect: WheelEffect.flat(),
                  header: const WheelHeader(child: Text('AM/PM')),
                  expanded: true,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Selected: ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $_period',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () async {
                await Future.wait([
                  _hourController.animateToValue(7),
                  _minuteController.animateToValue(45),
                  _periodController.animateToValue('PM'),
                ]);
              },
              child: const Text('Animate to 07:45 PM'),
            ),
            ElevatedButton(
              onPressed: () {
                _hourController.jumpToValue(2);
                _minuteController.jumpToValue(11);
                _periodController.jumpToValue('AM');
              },
              child: const Text('Jump to 02:11 AM'),
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
