import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('increments without setState', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('that number is even'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('that number is odd'), findsOneWidget);
    expect(find.text('from the stream: 1'), findsOneWidget);
  });

  testWidgets('rebuilds on either property', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ada pressed it 0 times'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Grace');
    await tester.pump();

    expect(find.text('Grace pressed it 0 times'), findsOneWidget);
  });

  testWidgets('leaving the screen disposes cleanly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
