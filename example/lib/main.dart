import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('wheel_choice example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Basic',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Pick a day'),
                const SizedBox(height: 8),
                WheelPicker<String>(
                  options: _days,
                  value: _day,
                  onChanged: (v) => setState(() => _day = v),
                  itemBuilder: WheelItem.delegate(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    selectedStyle: const TextStyle(fontSize: 18),
                  ),
                  itemVisible: 5,
                  overlay: WheelOverlay.outlined(inset: 12),
                  effect: const WheelEffect(
                    useMagnifier: true,
                    magnification: 1.05,
                  ),
                  header: const WheelHeader(child: Text('Day')),
                ),
                const SizedBox(height: 8),
                Text('Selected: $_day'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Numeric with disabled items',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Pick minutes'),
                const SizedBox(height: 8),
                WheelPicker<int>(
                  options: _minutes,
                  value: _minute,
                  onChanged: (v) => setState(() => _minute = v),
                  itemLabel: (v) => v.toString().padLeft(2, '0'),
                  itemDisabled: (v) => v % 5 != 0, // only multiples of 5
                  itemVisible: 7,
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
                  loop: true,
                ),
                const SizedBox(height: 8),
                Text('Selected: ${_minute.toString().padLeft(2, '0')}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Custom layout + expanded',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Custom item builder and expanded wheel'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: WheelPicker<String>(
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
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: item.selected
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            if (item.selected)
                              const Icon(Icons.check_circle, size: 18),
                          ],
                        ),
                      );
                    },
                    itemVisible: 5,
                    overlay: WheelOverlay.outlined(inset: 8),
                    effect: const WheelEffect(
                      diameterRatio: 2.2,
                      perspective: 0.003,
                    ),
                    expanded: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Selected: $_fruit'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
