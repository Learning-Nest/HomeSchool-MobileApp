import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/features/player/step_views/match_pairs_step_view.dart';
import 'package:homeschooling/models/steps.dart';

void main() {
  final MatchPairsStep step = MatchPairsStep(
    id: 'm1',
    prompt: 'Match each animal to its sound',
    left: const <Choice>[Choice('l1', 'Cow'), Choice('l2', 'Dog')],
    right: const <Choice>[Choice('r1', 'Woof'), Choice('r2', 'Moo')],
  );

  Widget host({List<List<String>> answer = const <List<String>>[], required ValueChanged<List<List<String>>> onChanged}) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: MatchPairsStepView(step: step, answer: answer, onChanged: onChanged))),
    );
  }

  testWidgets('tap a left card, then a right card, to make a pair', (WidgetTester tester) async {
    List<List<String>>? last;
    await tester.pumpWidget(host(onChanged: (List<List<String>> v) => last = v));

    await tester.tap(find.text('Cow'));
    await tester.pump();
    await tester.tap(find.text('Moo'));
    await tester.pump();

    expect(last, <List<String>>[
      <String>['l1', 'r2'],
    ]);
  });

  testWidgets('tapping a right card first does nothing', (WidgetTester tester) async {
    List<List<String>>? last;
    await tester.pumpWidget(host(onChanged: (List<List<String>> v) => last = v));

    await tester.tap(find.text('Woof'));
    await tester.pump();

    expect(last, isNull);
  });

  testWidgets('tapping a matched card undoes that pair', (WidgetTester tester) async {
    List<List<String>>? last;
    await tester.pumpWidget(
      host(
        answer: const <List<String>>[
          <String>['l1', 'r2'],
          <String>['l2', 'r1'],
        ],
        onChanged: (List<List<String>> v) => last = v,
      ),
    );

    await tester.tap(find.text('Moo'));
    await tester.pump();

    expect(last, <List<String>>[
      <String>['l2', 'r1'],
    ]);
  });
}
