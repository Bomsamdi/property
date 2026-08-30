import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property/property.dart';

void main() {
  group('value', () {
    test('starts at the initial value', () {
      final Property<int> property = Property<int>(1);
      addTearDown(property.dispose);

      expect(property.value, 1);
    });

    test('notifies listeners on change', () {
      final Property<int> property = Property<int>(1);
      addTearDown(property.dispose);
      int calls = 0;
      property.addListener(() => calls++);

      property.value = 2;

      expect(property.value, 2);
      expect(calls, 1);
    });

    test('does not notify when the value is equal', () {
      final Property<int> property = Property<int>(1);
      addTearDown(property.dispose);
      int calls = 0;
      property.addListener(() => calls++);

      property.value = 1;

      expect(calls, 0);
    });

    test('forceValue notifies even for an equal value', () {
      // For values edited in place - a mutated list is still equal to itself.
      final List<int> list = <int>[1];
      final Property<List<int>> property = Property<List<int>>(list);
      addTearDown(property.dispose);
      int calls = 0;
      property.addListener(() => calls++);

      list.add(2);
      property.forceValue(list);

      expect(calls, 1);
    });

    test('update applies a transform', () {
      final Property<int> property = Property<int>(1);
      addTearDown(property.dispose);

      property.update((int value) => value + 41);

      expect(property.value, 42);
    });

    test('is a ValueListenable', () {
      final Property<int> property = Property<int>(1);
      addTearDown(property.dispose);

      expect(property, isA<ValueListenable<int>>());
    });
  });

  group('stream', () {
    test('gives every listener the current value', () async {
      // Regression: the value was pushed from the broadcast controller's
      // onListen, which only fires for the first listener - a second one sat
      // idle until the next change.
      final Property<int> property = Property<int>(7);
      addTearDown(property.dispose);
      final List<int> first = <int>[];
      final List<int> second = <int>[];

      final StreamSubscription<int> a = property.stream.listen(first.add);
      final StreamSubscription<int> b = property.stream.listen(second.add);
      await Future<void>.delayed(Duration.zero);

      expect(first, <int>[7]);
      expect(second, <int>[7]);

      await a.cancel();
      await b.cancel();
    });

    test('emits every change to every listener', () async {
      final Property<int> property = Property<int>(0);
      addTearDown(property.dispose);
      final List<int> first = <int>[];
      final List<int> second = <int>[];
      final StreamSubscription<int> a = property.stream.listen(first.add);
      final StreamSubscription<int> b = property.stream.listen(second.add);
      await Future<void>.delayed(Duration.zero);

      property.value = 1;
      property.value = 2;
      await Future<void>.delayed(Duration.zero);

      expect(first, <int>[0, 1, 2]);
      expect(second, <int>[0, 1, 2]);

      await a.cancel();
      await b.cancel();
    });

    test('closes when the property is disposed', () async {
      final Property<int> property = Property<int>(0);
      bool done = false;
      final StreamSubscription<int> sub = property.stream.listen(
        (_) {},
        onDone: () => done = true,
      );
      await Future<void>.delayed(Duration.zero);

      property.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(done, isTrue);
      await sub.cancel();
    });
  });

  group('dispose', () {
    test('marks the property as disposed', () {
      final Property<int> property = Property<int>(0);
      expect(property.isDisposed, isFalse);

      property.dispose();

      expect(property.isDisposed, isTrue);
    });

    test('rejects further writes', () {
      final Property<int> property = Property<int>(0);
      property.dispose();

      expect(() => property.value = 1, throwsA(isA<AssertionError>()));
    });
  });

  group('map', () {
    test('follows the source', () {
      final Property<int> source = Property<int>(1);
      addTearDown(source.dispose);
      final Property<String> derived = source.map(
        (int value) => 'value $value',
      );
      addTearDown(derived.dispose);

      expect(derived.value, 'value 1');

      source.value = 2;

      expect(derived.value, 'value 2');
    });

    test('is read-only', () {
      final Property<int> source = Property<int>(1);
      addTearDown(source.dispose);
      final Property<String> derived = source.map((int value) => '$value');
      addTearDown(derived.dispose);

      expect(() => derived.value = 'nope', throwsUnsupportedError);
    });

    test('stops following the source once disposed', () {
      final Property<int> source = Property<int>(1);
      addTearDown(source.dispose);
      final Property<String> derived = source.map((int value) => '$value');

      derived.dispose();
      source.value = 2;

      expect(derived.isDisposed, isTrue);
      expect(derived.value, '1');
    });
  });

  group('PropertyBuilder', () {
    testWidgets('rebuilds with a non-null value', (WidgetTester tester) async {
      final Property<int> property = Property<int>(5);
      addTearDown(property.dispose);
      final List<int> seen = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyBuilder<int>(
            property: property,
            builder: (BuildContext context, int value, Widget? child) {
              seen.add(value);
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);

      property.value = 6;
      await tester.pump();

      expect(find.text('6'), findsOneWidget);
      expect(seen, <int>[5, 6]);
    });

    testWidgets('passes child through without rebuilding it', (
      WidgetTester tester,
    ) async {
      final Property<int> property = Property<int>(0);
      addTearDown(property.dispose);
      int childBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyBuilder<int>(
            property: property,
            child: Builder(
              builder: (BuildContext context) {
                childBuilds++;
                return const Text('static');
              },
            ),
            builder: (BuildContext context, int value, Widget? child) =>
                Column(children: <Widget>[Text('$value'), child!]),
          ),
        ),
      );
      property.value = 1;
      await tester.pump();

      expect(find.text('static'), findsOneWidget);
      expect(childBuilds, 1);
    });

    testWidgets('works with the framework ValueListenableBuilder', (
      WidgetTester tester,
    ) async {
      final Property<int> property = Property<int>(3);
      addTearDown(property.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: property,
            builder: (BuildContext context, int value, Widget? child) =>
                Text('$value'),
          ),
        ),
      );
      property.value = 4;
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
    });
  });

  group('MultiPropertyBuilder', () {
    testWidgets('rebuilds when any property changes', (
      WidgetTester tester,
    ) async {
      final Property<String> first = Property<String>('Ada');
      final Property<String> last = Property<String>('Lovelace');
      addTearDown(first.dispose);
      addTearDown(last.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiPropertyBuilder(
            properties: <Listenable>[first, last],
            builder: (BuildContext context, Widget? child) =>
                Text('${first.value} ${last.value}'),
          ),
        ),
      );

      expect(find.text('Ada Lovelace'), findsOneWidget);

      last.value = 'Byron';
      await tester.pump();

      expect(find.text('Ada Byron'), findsOneWidget);
    });
  });
}
