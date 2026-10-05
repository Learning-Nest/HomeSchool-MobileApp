import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/features/player/step_views/sequence_order_step_view.dart';
import 'package:homeschooling/models/steps.dart';

void main() {
  final SequenceOrderStep step = SequenceOrderStep(
    id: 's1',
    prompt: 'Put the story in order',
    items: const <Choice>[Choice('a', 'First'), Choice('b', 'Second'), Choice('c', 'Third')],
  );

  Widget host({List<String>? answer, required ValueChanged<List<String>> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SequenceOrderStepView(step: step, answer: answer, onChanged: onChanged),
        ),
      ),
    );
  }

  List<String> labelsTopToBottom(WidgetTester tester) {
    final List<String> labels = <String>['First', 'Second', 'Third'];
    labels.sort((String x, String y) => tester.getTopLeft(find.text(x)).dy.compareTo(tester.getTopLeft(find.text(y)).dy));
    return labels;
  }

  testWidgets('down arrow moves an item one place down and reports the new order', (WidgetTester tester) async {
    List<String>? last;
    await tester.pumpWidget(host(answer: const <String>['a', 'b', 'c'], onChanged: (List<String> v) => last = v));

    await tester.tap(find.byKey(const Key('seq-down-0')));
    await tester.pump();

    expect(last, <String>['b', 'a', 'c']);
    expect(labelsTopToBottom(tester), <String>['Second', 'First', 'Third']);
  });

  testWidgets('up arrow moves an item one place up', (WidgetTester tester) async {
    List<String>? last;
    await tester.pumpWidget(host(answer: const <String>['a', 'b', 'c'], onChanged: (List<String> v) => last = v));

    await tester.tap(find.byKey(const Key('seq-up-2')));
    await tester.pump();

    expect(last, <String>['a', 'c', 'b']);
  });

  testWidgets('the first item cannot move up and the last cannot move down', (WidgetTester tester) async {
    await tester.pumpWidget(host(answer: const <String>['a', 'b', 'c'], onChanged: (List<String> _) {}));

    expect(tester.widget<IconButton>(find.byKey(const Key('seq-up-0'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const Key('seq-down-2'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const Key('seq-down-0'))).onPressed, isNotNull);
  });

  testWidgets('dragging the handle with a plain touch reorders without a long press', (WidgetTester tester) async {
    List<String>? last;
    await tester.pumpWidget(host(answer: const <String>['a', 'b', 'c'], onChanged: (List<String> v) => last = v));

    // A normal, immediate drag on the handle of the first row, downwards past the second row.
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('seq-handle-0'))));
    await tester.pump(const Duration(milliseconds: 50));
    for (int i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(last, isNotNull, reason: 'the drag should have been accepted straight away');
    expect(last!.first, isNot('a'));
    expect(last!.toSet(), <String>{'a', 'b', 'c'});
  });

  testWidgets('without a saved answer the items are shuffled once and the order is reported', (WidgetTester tester) async {
    List<String>? last;
    await tester.pumpWidget(host(onChanged: (List<String> v) => last = v));
    await tester.pump();

    expect(last, isNotNull);
    expect(last!.toSet(), <String>{'a', 'b', 'c'});
    expect(last!.length, 3);
  });
}
