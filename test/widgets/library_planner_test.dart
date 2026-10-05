import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/parent/add_to_plan_sheet.dart';
import 'package:homeschooling/features/parent/planner_screen.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_repositories.dart';

Child kid(String id, String name) => Child(
      id: id,
      familyId: 'f1',
      displayName: name,
      avatar: 'star',
      interests: const <String>[],
      goals: const <String>[],
      version: 1,
    );

ActivitySummary activity(String id, String title) => ActivitySummary(
      id: id,
      slug: id,
      title: title,
      subjectCode: 'MAT',
      levelFrom: 'L1',
      levelTo: 'L2',
      durationMin: 15,
      materials: const <String>[],
      interestTags: const <String>[],
      version: 1,
    );

PlanItem planItem(String id, String status, {String title = 'Counting to ten'}) => PlanItem(
      id: id,
      childId: 'k1',
      activity: activity('act-$id', title),
      scheduledDate: dateOnly(DateTime.now()),
      position: 0,
      status: status,
      version: 1,
    );

class _FakeFamily extends FamilyNotifier {
  _FakeFamily(this.kids);

  final List<Child> kids;

  @override
  FamilyState build() => FamilyState(children: kids);
}

class _FakeWeekPlan extends WeekPlanNotifier {
  _FakeWeekPlan(this.initial);

  final List<PlanItem> initial;
  final List<String> removed = <String>[];

  @override
  WeekPlanState build() =>
      WeekPlanState(childId: 'k1', weekStart: weekStartOf(DateTime.now()), items: initial);

  @override
  Future<void> loadWeek(String childId, DateTime anyDayInWeek) async {}

  @override
  Future<bool> deleteItem(String itemId) async {
    removed.add(itemId);
    state = state.copyWith(items: state.items.where((PlanItem i) => i.id != itemId).toList());
    return true;
  }
}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2020)));

  group('Add to plan sheet (Activity library)', () {
    late TestEnvironment env;
    AddedToPlan? result;

    setUp(() {
      env = TestEnvironment();
      result = null;
      when(
        () => env.planning.addItem(
          childId: any(named: 'childId'),
          activityId: any(named: 'activityId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => planItem('new', 'planned'));
    });

    Future<void> openSheet(WidgetTester tester, List<Child> kids) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            environmentProvider.overrideWithValue(env.build()),
            familyProvider.overrideWith(() => _FakeFamily(kids)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async => result = await showAddToPlanSheet(context, activity('act1', 'Weather diary')),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('adds the activity for the chosen day with one confirm', (WidgetTester tester) async {
      await openSheet(tester, <Child>[kid('k1', 'Mia')]);

      expect(find.textContaining('Weather diary'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('plan-day-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('plan-add-confirm')));
      await tester.pumpAndSettle();

      final DateTime tomorrow = addDays(dateOnly(DateTime.now()), 1);
      verify(() => env.planning.addItem(childId: 'k1', activityId: 'act1', date: tomorrow)).called(1);
      expect(result, isNotNull);
      expect(result!.child.id, 'k1');
      expect(isSameDay(result!.date, tomorrow), isTrue);
    });

    testWidgets('defaults to today', (WidgetTester tester) async {
      await openSheet(tester, <Child>[kid('k1', 'Mia')]);

      await tester.tap(find.byKey(const ValueKey<String>('plan-add-confirm')));
      await tester.pumpAndSettle();

      final DateTime today = dateOnly(DateTime.now());
      verify(() => env.planning.addItem(childId: 'k1', activityId: 'act1', date: today)).called(1);
    });

    testWidgets('with several children the parent picks who it is for', (WidgetTester tester) async {
      await openSheet(tester, <Child>[kid('k1', 'Mia'), kid('k2', 'Leo')]);

      await tester.tap(find.byKey(const ValueKey<String>('plan-child-k2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('plan-add-confirm')));
      await tester.pumpAndSettle();

      verify(() => env.planning.addItem(childId: 'k2', activityId: 'act1', date: any(named: 'date'))).called(1);
    });
  });

  group('Planner (remove only)', () {
    Future<_FakeWeekPlan> pumpPlanner(WidgetTester tester, List<PlanItem> items) async {
      final _FakeWeekPlan fake = _FakeWeekPlan(items);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            familyProvider.overrideWith(() => _FakeFamily(<Child>[kid('k1', 'Mia')])),
            weekPlanProvider.overrideWith(() => fake),
          ],
          child: const MaterialApp(home: PlannerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('a planned activity can be removed after confirming', (WidgetTester tester) async {
      final _FakeWeekPlan fake = await pumpPlanner(tester, <PlanItem>[planItem('p1', 'planned')]);

      expect(find.text('Counting to ten'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('planner-remove-p1')));
      await tester.pumpAndSettle();
      expect(find.text(Str.plannerRemoveConfirmTitle), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('planner-remove-confirm')));
      await tester.pumpAndSettle();

      expect(fake.removed, <String>['p1']);
      expect(find.text('Counting to ten'), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps the activity', (WidgetTester tester) async {
      final _FakeWeekPlan fake = await pumpPlanner(tester, <PlanItem>[planItem('p1', 'planned')]);

      await tester.tap(find.byKey(const ValueKey<String>('planner-remove-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Str.cancel));
      await tester.pumpAndSettle();

      expect(fake.removed, isEmpty);
      expect(find.text('Counting to ten'), findsOneWidget);
    });

    testWidgets('a finished activity has no remove button', (WidgetTester tester) async {
      await pumpPlanner(tester, <PlanItem>[planItem('p2', 'completed')]);

      expect(find.byKey(const ValueKey<String>('planner-remove-p2')), findsNothing);
      expect(find.text('Counting to ten'), findsOneWidget);
    });

    testWidgets('there is no add button; an empty plan points to the Activity library', (WidgetTester tester) async {
      await pumpPlanner(tester, <PlanItem>[]);

      expect(find.byTooltip(Str.plannerAddActivity), findsNothing);
      expect(find.byKey(const ValueKey<String>('planner-open-library')), findsOneWidget);
      expect(find.text(Str.plannerEmptyWeek), findsOneWidget);
    });

    testWidgets('bottom navigation order is Dashboard, Activity library, Planner', (WidgetTester tester) async {
      await pumpPlanner(tester, <PlanItem>[]);

      final List<String> labels =
          tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((NavigationDestination d) => d.label).toList();
      expect(labels.take(3).toList(), <String>[Str.dashboardTitle, Str.catalogueTitle, Str.plannerTitle]);
    });
  });
}
