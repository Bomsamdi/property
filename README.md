# property

[![Pub Version](https://img.shields.io/pub/v/property)](https://pub.dev/packages/property)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![pub points](https://img.shields.io/pub/points/property)](https://pub.dev/packages/property/score)
[![likes](https://img.shields.io/pub/likes/property)](https://pub.dev/packages/property/score)

An observable value holder. Update widgets without `setState`, rebuilding only
the part of the tree that reads the value.

A `Property` is a `ValueListenable`, so it works with `PropertyBuilder` and with
everything the framework already has — `ValueListenableBuilder`,
`ListenableBuilder`, `AnimatedBuilder` — and it also exposes a `Stream` for code
that prefers streams.

## Installation

```yaml
dependencies:
  property: ^1.0.0
```

Requires Dart 3.8 / Flutter 3.32 or newer.

## Usage

```dart
import 'package:property/property.dart';

final Property<int> counter = Property<int>(0);

PropertyBuilder<int>(
  property: counter,
  builder: (BuildContext context, int value, Widget? child) => Text('$value'),
)

counter.value++;              // or
counter.update((int v) => v + 1);
```

Dispose it with the widget that owns it:

```dart
@override
void dispose() {
  counter.dispose();
  super.dispose();
}
```

### Several properties at once

```dart
MultiPropertyBuilder(
  properties: <Listenable>[firstName, lastName],
  builder: (BuildContext context, Widget? child) =>
      Text('${firstName.value} ${lastName.value}'),
)
```

### Derived values

`map` returns a read-only property that follows the source. Dispose it too.

```dart
final Property<String> label = counter.map((int v) => v.isEven ? 'even' : 'odd');
```

### As a stream

```dart
StreamBuilder<int>(
  stream: counter.stream,
  builder: (context, snapshot) => Text('${snapshot.data}'),
)
```

Every listener receives the current value immediately, then each change.

### Mutable values

A list edited in place is still equal to itself, so assigning it back notifies
nobody. `forceValue` notifies regardless:

```dart
items.value.add(newItem);
items.forceValue(items.value);
```

## API

| Member | Description |
|---|---|
| `Property(initialValue)` | Creates the property. |
| `value` | Get, or set to notify listeners when the value changed. |
| `update(transform)` | Sets the value from the current one. |
| `forceValue(v)` | Notifies even when the value is equal. |
| `stream` | The current value, then every change, per listener. |
| `map(transform)` | A read-only property following this one. |
| `addListener` / `removeListener` | From `ValueListenable`. |
| `dispose()` / `isDisposed` | Releases listeners and closes the stream. |
| `PropertyBuilder` | Rebuilds on change; takes an optional `child`. |
| `MultiPropertyBuilder` | Rebuilds when any of several listenables changes. |

## Migrating from 0.0.3

- **`Property` must be disposed.** It never released its `StreamController`
  before, so every property leaked one.
- **`PropertyBuilder`'s builder takes `(context, value, child)`** and the value
  is non-nullable. A callback written as `(context, value)` needs the extra
  parameter; the value no longer needs a `!`.
- **`stream` gives every listener the current value.** Previously only the first
  listener did, because the value was pushed from the broadcast controller's
  `onListen`.
- `Property` is now a `ChangeNotifier` / `ValueListenable`.

## License

MIT.
