# Property

[Property] is a solution when you need easy support for updating widgets values without setState using streams

## Usage

```dart
import 'package:property/property.dart';

final Property<int> _counter = Property(0);

void _incrementCounter() {
    _counter.value++;
}

Scaffold(
    appBar: AppBar(
    title: Text(widget.title),
    ),
    body: Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
        const Text(
            'You have pushed the button this many times:',
        ),
        PropertyBuilder(
            property: _counter,
            builder: (context, value) => Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
            ),
            ),
        ),
        ],
    ),
    ),
    floatingActionButton: FloatingActionButton(
    onPressed: _incrementCounter,
    tooltip: 'Increment',
    child: const Icon(Icons.add),
    ),
);
```
## Example project

Example usage in `/example` folder.