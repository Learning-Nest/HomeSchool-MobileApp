import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/features/player/step_views/numeric_input_step_view.dart';
import 'package:homeschooling/models/steps.dart';

void main() {
  final NumericInputStep step = NumericInputStep(id: 'n1', prompt: 'How many apples?');

  Widget host({num? answer, required ValueChanged<num?> onChanged}) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: NumericInputStepView(step: step, answer: answer, onChanged: onChanged))),
    );
  }

  Future<void> press(WidgetTester tester, List<String> keys) async {
    for (final String k in keys) {
      final Finder key = find.byKey(Key('pad-$k'));
      // The pad is taller than the 600px test screen: scroll the key into view first, as a child would.
      await tester.ensureVisible(key);
      await tester.pump();
      await tester.tap(key);
      await tester.pump();
    }
  }

  testWidgets('the number pad builds a multi-digit answer', (WidgetTester tester) async {
    num? last;
    await tester.pumpWidget(host(onChanged: (num? v) => last = v));

    await press(tester, <String>['4', '2']);

    expect(last, 42);
    expect(find.descendant(of: find.byKey(const Key('number-display')), matching: find.text('42')), findsOneWidget);
  });

  testWidgets('backspace removes the last digit and clearing reports null', (WidgetTester tester) async {
    num? last = -1;
    await tester.pumpWidget(host(onChanged: (num? v) => last = v));

    await press(tester, <String>['4', '2', 'back']);
    expect(last, 4);
    await press(tester, <String>['back']);
    expect(last, isNull);
  });

  testWidgets('decimal point is allowed once', (WidgetTester tester) async {
    num? last;
    await tester.pumpWidget(host(onChanged: (num? v) => last = v));

    await press(tester, <String>['.', '5', '.', '2']);

    expect(last, 0.52);
  });

  testWidgets('shows a saved answer', (WidgetTester tester) async {
    await tester.pumpWidget(host(answer: 7, onChanged: (num? _) {}));

    expect(find.descendant(of: find.byKey(const Key('number-display')), matching: find.text('7')), findsOneWidget);
  });
}
