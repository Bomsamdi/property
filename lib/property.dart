/// A small observable value holder and the widgets that rebuild with it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A value that widgets can watch without `setState`.
///
/// A [Property] is a [ValueListenable], so besides [PropertyBuilder] it works
/// with everything in the framework that takes one - [ValueListenableBuilder],
/// [AnimatedBuilder], [ListenableBuilder] - and it also exposes a [stream] for
/// code that prefers streams.
///
/// ### Example
///
/// ```dart
/// final Property<int> counter = Property<int>(0);
///
/// PropertyBuilder<int>(
///   property: counter,
///   builder: (BuildContext context, int value, Widget? child) =>
///       Text('$value'),
/// );
///
/// counter.value++;
/// ```
///
/// Call [dispose] when the property is no longer needed.
class Property<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a property holding [initialValue].
  Property(T initialValue) : _value = initialValue;

  T _value;

  /// Lazily created: a property that is only ever watched by widgets never
  /// allocates a controller.
  StreamController<T>? _controller;

  bool _disposed = false;

  @override
  T get value => _value;

  /// Sets the value and notifies listeners, unless the new value is equal to
  /// the current one.
  set value(T newValue) {
    assert(!_disposed, 'A disposed Property cannot be used.');
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
    _controller?.add(newValue);
  }

  /// Replaces the value with the result of [transform].
  ///
  /// ```dart
  /// counter.update((int value) => value + 1);
  /// ```
  void update(T Function(T value) transform) => value = transform(_value);

  /// Sets the value and notifies even when the new value is equal to the
  /// current one.
  ///
  /// Useful for mutable values - a list that was edited in place is still
  /// equal to itself, so a plain assignment would notify nobody.
  void forceValue(T newValue) {
    assert(!_disposed, 'A disposed Property cannot be used.');
    _value = newValue;
    notifyListeners();
    _controller?.add(newValue);
  }

  /// The values of this property over time.
  ///
  /// Every listener receives the current value immediately and then each
  /// change. Previously only the very first listener was given the current
  /// value, so a second one sat idle until the next change.
  Stream<T> get stream {
    final StreamController<T> source = _controller ??=
        StreamController<T>.broadcast(sync: true);
    final StreamController<T> out = StreamController<T>();
    StreamSubscription<T>? subscription;
    out
      ..onListen = () {
        out.add(_value);
        subscription = source.stream.listen(
          out.add,
          onError: out.addError,
          onDone: out.close,
        );
      }
      ..onCancel = () async {
        await subscription?.cancel();
        subscription = null;
      };
    return out.stream;
  }

  /// A read-only property holding [transform] of this one's value.
  ///
  /// The derived property follows this one until either is disposed.
  ///
  /// ```dart
  /// final Property<String> label = counter.map((int value) => 'count: $value');
  /// ```
  Property<R> map<R>(R Function(T value) transform) {
    final Property<R> derived = _DerivedProperty<T, R>(this, transform);
    return derived;
  }

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    // The stream controller used to be created in the constructor and never
    // closed, so every property leaked one.
    _disposed = true;
    unawaited(_controller?.close());
    _controller = null;
    super.dispose();
  }

  @override
  String toString() => 'Property<$T>($_value)';
}

class _DerivedProperty<S, T> extends Property<T> {
  _DerivedProperty(this._source, this._transform)
    : super(_transform(_source.value)) {
    _source.addListener(_onSourceChanged);
  }

  final Property<S> _source;
  final T Function(S value) _transform;

  void _onSourceChanged() {
    if (isDisposed) return;
    final T next = _transform(_source.value);
    if (next == value) return;
    super.value = next;
  }

  @override
  set value(T newValue) {
    throw UnsupportedError(
      'A derived property is read-only; set the value on the source instead.',
    );
  }

  @override
  void dispose() {
    _source.removeListener(_onSourceChanged);
    super.dispose();
  }
}

/// Rebuilds when [property] changes.
///
/// ```dart
/// PropertyBuilder<int>(
///   property: counter,
///   builder: (BuildContext context, int value, Widget? child) => Text('$value'),
/// )
/// ```
///
/// [child] is built once and handed to [builder], for the parts of the subtree
/// that do not depend on the value.
class PropertyBuilder<T> extends StatelessWidget {
  const PropertyBuilder({
    super.key,
    required this.property,
    required this.builder,
    this.child,
  });

  /// The property to watch.
  final Property<T> property;

  /// Called with the current value on every change.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// Passed to [builder] untouched, so it is not rebuilt with the value.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: property,
      builder: (BuildContext context, Widget? child) =>
          builder(context, property.value, child),
      child: child,
    );
  }
}

/// Rebuilds when any of [properties] changes.
///
/// ```dart
/// MultiPropertyBuilder(
///   properties: <Listenable>[firstName, lastName],
///   builder: (BuildContext context, Widget? child) =>
///       Text('${firstName.value} ${lastName.value}'),
/// )
/// ```
class MultiPropertyBuilder extends StatelessWidget {
  const MultiPropertyBuilder({
    super.key,
    required this.properties,
    required this.builder,
    this.child,
  });

  /// The properties to watch.
  final List<Listenable> properties;

  /// Called on every change of any of [properties].
  final Widget Function(BuildContext context, Widget? child) builder;

  /// Passed to [builder] untouched.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(properties),
      builder: builder,
      child: child,
    );
  }
}
