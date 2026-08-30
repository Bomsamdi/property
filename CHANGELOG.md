## 1.0.0

### Breaking

* `Property` is now a `ChangeNotifier` implementing `ValueListenable<T>`, and
  **must be disposed**. It previously created a `StreamController` in its
  constructor and offered no way to close it, so every property leaked one.
* `PropertyBuilder`'s builder signature is
  `(BuildContext context, T value, Widget? child)`. The value is no longer
  nullable - it never actually was - and the extra `child` parameter allows a
  subtree to be excluded from rebuilds.
* `PropertyBuilder` no longer extends `StreamBuilder`, and no longer asserts on
  a stream error.

### Added

* `update(transform)`, `forceValue(value)` for values mutated in place,
  `map(transform)` for a read-only derived property, and `isDisposed`.
* `MultiPropertyBuilder`, rebuilding when any of several listenables changes.
* An optional `child` on `PropertyBuilder`.
* Works with `ValueListenableBuilder`, `ListenableBuilder` and `AnimatedBuilder`
  out of the box.

### Fixed

* Every stream listener now receives the current value. The value was pushed
  from the broadcast controller's `onListen`, which fires only when the first
  listener arrives, so a second listener stayed empty until the next change.
* The stream controller is created lazily and closed on dispose.

### Other

* Requires Dart 3.8 / Flutter 3.32; `flutter_lints` 6.
* 18 tests, plus 3 in the example. There were two before.

## 0.0.3

* Small fixes

## 0.0.2

* Doc update

## 0.0.1

* Initial release.
