import 'package:flutter/material.dart';
import 'package:property/property.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'property example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Property<int> _counter = Property<int>(0);
  final Property<String> _name = Property<String>('Ada');
  late final Property<String> _label = _counter.map(
    (int value) => value.isEven ? 'even' : 'odd',
  );

  @override
  void dispose() {
    _label.dispose();
    _counter.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('property')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),

            // Rebuilds only this Text, without setState.
            PropertyBuilder<int>(
              property: _counter,
              builder: (BuildContext context, int value, Widget? child) => Text(
                '$value',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 8),

            // A derived, read-only property that follows the counter.
            PropertyBuilder<String>(
              property: _label,
              builder: (BuildContext context, String value, Widget? child) =>
                  Text('that number is $value'),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: 240,
              child: TextField(
                decoration: const InputDecoration(labelText: 'name'),
                onChanged: (String value) => _name.value = value,
              ),
            ),
            const SizedBox(height: 16),

            // Rebuilds when either property changes.
            MultiPropertyBuilder(
              properties: <Listenable>[_counter, _name],
              builder: (BuildContext context, Widget? child) =>
                  Text('${_name.value} pressed it ${_counter.value} times'),
            ),
            const SizedBox(height: 32),

            // The same property as a stream.
            StreamBuilder<int>(
              stream: _counter.stream,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) =>
                  Text('from the stream: ${snapshot.data ?? '-'}'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _counter.update((int value) => value + 1),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
