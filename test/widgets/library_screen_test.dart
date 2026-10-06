import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/parent/catalogue_screen.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/curriculum.dart';
import 'package:homeschooling/models/library.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_repositories.dart';

Child kid(String id, String name, {String? level}) => Child(
      id: id,
      familyId: 'f1',
      displayName: name,
      avatar: 'star',
      levelCode: level,
      interests: const <String>[],
      goals: const <String>[],
      version: 1,
    );

ActivitySummary summary(String id, String title) => ActivitySummary(
      id: id,
      slug: id,
      title: title,
      subjectCode: 'MAT',
      levelFrom: 'L1',
      levelTo: 'L3',
      durationMin: 15,
      materials: const <String>[],
      interestTags: const <String>[],
      version: 1,
    );

class _FakeFamily extends FamilyNotifier {
  _FakeFamily(this.kids);

  final List<Child> kids;

  @override
  FamilyState build() => FamilyState(children: kids);
}

void main() {
  setUpAll(() {
    registerFallbackValue('x');
    registerFallbackValue(DateTime(2020));
  });

  late TestEnvironment env;
  final DateTime today = dateOnly(DateTime.now());

  setUp(() {
    env = TestEnvironment();
    when(() => env.curriculum.subjects()).thenAnswer(
      (_) async => const <Subject>[
        Subject(code: 'MAT', name: 'Maths', displayOrder: 1),
        Subject(code: 'ENG', name: 'English', displayOrder: 2),
      ],
    );
    when(() => env.catalogue.library(any(), subject: any(named: 'subject'), query: any(named: 'query'), offset: any(named: 'offset')))
        .thenAnswer(
      (_) async => <LibraryActivity>[
        LibraryActivity(activity: summary('a1', 'Counting to ten')),
        LibraryActivity(activity: summary('a2', 'Shapes around us'), timesDone: 2, lastDoneAt: DateTime.now()),
        LibraryActivity(activity: summary('a3', 'Number bonds'), plannedFor: addDays(today, 1)),
      ],
    );
    when(() => env.planning.addItem(childId: any(named: 'childId'), activityId: any(named: 'activityId'), date: any(named: 'date')))
        .thenAnswer(
      (_) async => PlanItem(
        id: 'p1',
        childId: 'k1',
        activity: summary('a1', 'Counting to ten'),
        scheduledDate: today,
        position: 0,
        status: 'planned',
        version: 1,
      ),
    );
  });

  Future<void> pump(WidgetTester tester, List<Child> kids) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          environmentProvider.overrideWithValue(env.build()),
          familyProvider.overrideWith(() => _FakeFamily(kids)),
        ],
        // The screen navigates with go_router (the snackbar's "View planner" link), so host it in a router like the app does.
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: <RouteBase>[
              GoRoute(path: '/', builder: (BuildContext c, GoRouterState s) => const CatalogueScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickMaths(WidgetTester tester) async {
    // The subject is a dropdown: open it, then choose the entry in the menu.
    await tester.tap(find.byKey(const ValueKey<String>('library-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🔢 Maths').last);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing is listed until a subject is picked', (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2')]);

    expect(find.text('For Mia · level L2'), findsOneWidget);
    expect(find.text(Str.libraryPickSubject('Mia')), findsOneWidget);
    expect(find.text('Counting to ten'), findsNothing);
    verifyNever(() => env.catalogue.library(any(), subject: any(named: 'subject'), query: any(named: 'query'), offset: any(named: 'offset')));
  });

  testWidgets("picking a subject shows that child's activities", (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2')]);
    await pickMaths(tester);

    verify(() => env.catalogue.library('k1', subject: 'MAT', query: '', offset: 0)).called(1);
    expect(find.text('Counting to ten'), findsOneWidget);
    expect(find.text('Shapes around us'), findsOneWidget);
    expect(find.text('Number bonds'), findsOneWidget);
  });

  testWidgets('each activity says whether the child has done it and whether it is planned', (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2')]);
    await pickMaths(tester);

    // never done
    expect(find.byKey(const ValueKey<String>('library-new-a1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('library-done-a1')), findsNothing);
    // done twice
    expect(find.byKey(const ValueKey<String>('library-done-a2')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey<String>('library-done-a2')), matching: find.textContaining('Done 2 times')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('library-new-a2')), findsNothing);
    // planned for tomorrow
    expect(find.descendant(of: find.byKey(const ValueKey<String>('library-planned-a3')), matching: find.text('Planned Tomorrow')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('library-planned-a1')), findsNothing);
  });

  testWidgets('titles are not squeezed on a narrow phone', (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2')]);
    await pickMaths(tester);

    final Size size = tester.getSize(find.byKey(const ValueKey<String>('library-title-a2')));
    expect(size.width, greaterThan(150));
    expect(size.height, lessThan(130));
  });

  testWidgets('add to plan from the library plans it for this child and refreshes the list', (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2'), kid('k2', 'Leo', level: 'L4')]);
    await pickMaths(tester);

    await tester.tap(find.byKey(const ValueKey<String>('add-to-plan-a1')));
    await tester.pumpAndSettle();
    // The library is already about Mia, so the sheet does not ask who it is for.
    expect(find.text(Str.planAddForChild('Mia')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('plan-child-k2')), findsNothing);

    // The sheet scrolls on a 360x800 phone, so bring the button into view first.
    await tester.ensureVisible(find.byKey(const ValueKey<String>('plan-add-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('plan-add-confirm')));
    await tester.pumpAndSettle();

    verify(() => env.planning.addItem(childId: 'k1', activityId: 'a1', date: today)).called(1);
    verify(() => env.catalogue.library('k1', subject: 'MAT', query: '', offset: 0)).called(2); // opened + refreshed
    expect(find.textContaining('Added "Counting to ten" for Mia'), findsOneWidget);
  });

  testWidgets('a child without a level sees a hint that every level is shown', (WidgetTester tester) async {
    await pump(tester, <Child>[kid('k1', 'Mia')]);

    expect(find.text('For Mia · all levels'), findsOneWidget);
    expect(find.text(Str.libraryNoLevel('Mia')), findsOneWidget);
  });

  testWidgets('says so when a subject has nothing at the childs level', (WidgetTester tester) async {
    when(() => env.catalogue.library(any(), subject: any(named: 'subject'), query: any(named: 'query'), offset: any(named: 'offset')))
        .thenAnswer((_) async => <LibraryActivity>[]);
    await pump(tester, <Child>[kid('k1', 'Mia', level: 'L2')]);
    await pickMaths(tester);

    expect(find.text(Str.libraryNoResults), findsOneWidget);
  });
}
