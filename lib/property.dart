library property;

import 'dart:async';

import 'package:flutter/cupertino.dart';

/// [Property] class of type [T]
class Property<T> {
  /// [StreamController] for [_value] of [Property]
  late StreamController<T> _controller;

  /// Private value of [Property]
  /// Type of [_value] is define by [T]
  T _value;

  /// Getter for [_value]
  T get value => _value;

  /// Setter for [_value]
  /// setter add [newValue] to [StreamController]
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _controller.add(newValue);
    }
  }

  /// [Stream] getter of [StreamController]
  /// The type of stream value if define by [T]
  Stream<T> get stream => _controller.stream;

  /// Property constructor with initial value of [StreamController].
  ///
  /// Example:
  ///
  /// ```dart
  /// Property<int>(0);
  /// ```
  Property(T initialValue) : _value = initialValue {
    _controller = StreamController.broadcast(
      sync: true,
      onListen: () => _controller.add(_value),
    );
  }
}

/// This class is [StreamBuilder] for [Property]
///
/// Example:
///
/// ```dart
/// Property<int> property = Property<int>(0);
/// PropertyBuilder(
///   property: property,
///   builder: (context, value) {
///   return Text(value.toString());
/// });
/// ```
class PropertyBuilder<T> extends StreamBuilder<T> {
  PropertyBuilder({
    super.key,
    required Property<T> property,
    required Widget Function(BuildContext context, T? value) builder,
  }) : super(
          stream: property.stream,
          initialData: property.value,
          builder: (context, snapshot) {
            assert(!snapshot.hasError);
            return builder(context, snapshot.data);
          },
        );
}
