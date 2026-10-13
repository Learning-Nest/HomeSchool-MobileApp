import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/features/parent/textbooks_screen.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/textbooks.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mock_repositories.dart';

const Child _kid = Child(
  id: 'k1',
  familyId: 'f1',
  displayName: 'Aarya',
  avatar: 'star',
  interests: <String>[],
  goals: <String>[],
  version: 1,
);

class _FakeFamily extends FamilyNotifier {
  @override
  FamilyState build() => const FamilyState(children: <Child>[_kid]);
}

const Book _marigold = Book(
  code: 'cbse-1-english-marigold',
  boardCode: 'CBSE',
  grade: '1',
  subjectCode: 'ENG',
  title: 'Marigold 1',
  lessonCount: 2,
  publisher: 'NCERT',
);

BookPath _path({bool canUnlock = false, int? next = 2}) => BookPath(
      book: _marigold,
      unlockedThrough: 1,
      passScore: 0.6,
      canUnlockNext: canUnlock,
      nextLessonPosition: next,
      lessons: const <PathLesson>[
        PathLesson(
          position: 1,
          title: 'A Happy Child',
          label: 'Unit 1',
          state: LessonState.open,
          activityCount: 1,
          activities: <PathActivity>[
            PathActivity(id: 'a1', title: 'Alphabet A to F', durationMin: 10, status: PathStatus.attempted, locked: false, bestScore: 0.4),
          ],
        ),
        PathLesson(
          position: 2,
          title: 'Three Little Pigs',
          state: LessonState.locked,
          activityCount: 1,
          activities: <PathActivity>[],
        ),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late TestEnvironment env;

  setUp(() {
    env = TestEnvironment();
    when(() => env.textbook.childBooks('k1')).thenAnswer(
      (_) async => const <ChildBook>[
        ChildBook(book: _marigold, unlockedThrough: 1, lessonsTotal: 2, lessonsComplete: 0, canUnlockNext: false),
      ],
    );
    when(() => env.textbook.boards()).thenAnswer(
      (_) async => const <Board>[Board(code: 'CBSE', name: 'CBSE'), Board(code: 'ICSE', name: 'ICSE')],
    );
    when(() => env.textbook.books(board: 'CBSE')).thenAnswer(
      (_) async => const <Book>[
        _marigold,
        Book(code: 'cbse-2-english-marigold', boardCode: 'CBSE', grade: '2', subjectCode: 'ENG', title: 'Marigold 2', lessonCount: 3),
      ],
    );
    when(() => env.textbook.path('k1', _marigold.code)).thenAnswer((_) async => _path());
  });

  Future<void> pump(WidgetTester tester, {String location = '/parent/textbooks'}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          environmentProvider.overrideWithValue(env.build()),
          familyProvider.overrideWith(_FakeFamily.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: location,
            routes: <RouteBase>[
              GoRoute(path: '/parent/textbooks', builder: (BuildContext c, GoRouterState s) => const TextbooksScreen()),
              GoRoute(
                path: '/parent/textbooks/:bookCode',
                builder: (BuildContext c, GoRouterState s) => TextbookPathScreen(bookCode: s.pathParameters['bookCode']!),
              ),
              GoRoute(path: '/parent/dashboard', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/parent/catalogue', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/parent/planner', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/parent/progress', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/parent/reviews', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/parent/settings', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
              GoRoute(path: '/profiles', builder: (BuildContext c, GoRouterState s) => const Scaffold()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the textbooks a child follows with progress', (WidgetTester tester) async {
    await pump(tester);
    expect(find.text('Class 1 · Marigold 1'), findsOneWidget);
    expect(find.text(Str.lessonsProgress(0, 2)), findsOneWidget);
  });

  testWidgets('shows a message when no textbook is chosen yet', (WidgetTester tester) async {
    when(() => env.textbook.childBooks('k1')).thenAnswer((_) async => const <ChildBook>[]);
    await pump(tester);
    expect(find.text(Str.textbooksNone), findsOneWidget);
  });

  testWidgets('adds a textbook: pick a board, then a book that is not already chosen', (WidgetTester tester) async {
    when(() => env.textbook.enrol('k1', 'cbse-2-english-marigold')).thenAnswer((_) async => _path());
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey<String>('textbooks-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('board-CBSE')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('book-cbse-1-english-marigold')), findsNothing); // already chosen
    expect(find.byKey(const ValueKey<String>('grade-1')), findsNothing); // only one class left, so no class filter
    await tester.tap(find.byKey(const ValueKey<String>('book-cbse-2-english-marigold')));
    await tester.pumpAndSettle();
    verify(() => env.textbook.enrol('k1', 'cbse-2-english-marigold')).called(1);
    expect(find.text(Str.textbooksAdded), findsOneWidget);
  });

  testWidgets('the lesson path shows states and scores', (WidgetTester tester) async {
    await pump(tester, location: '/parent/textbooks/${_marigold.code}');
    expect(find.text('Lesson 1: Unit 1 · A Happy Child'), findsOneWidget);
    expect(find.text(Str.lessonOpen), findsOneWidget);
    expect(find.text(Str.lessonLocked), findsOneWidget);
    expect(find.text('Alphabet A to F'), findsOneWidget); // the open lesson starts expanded
    expect(find.textContaining('Best score 40%'), findsOneWidget);
  });

  testWidgets('adds the next lesson straight away when the open lessons are finished', (WidgetTester tester) async {
    when(() => env.textbook.unlockNext('k1', _marigold.code, force: false)).thenAnswer((_) async => _path(next: null));
    await pump(tester, location: '/parent/textbooks/${_marigold.code}');
    await tester.tap(find.byKey(const ValueKey<String>('unlock-next')));
    await tester.pumpAndSettle();
    verify(() => env.textbook.unlockNext('k1', _marigold.code, force: false)).called(1);
    verifyNever(() => env.textbook.unlockNext('k1', _marigold.code, force: true));
  });

  testWidgets('asks before skipping ahead when a lesson is unfinished, then forces it', (WidgetTester tester) async {
    when(() => env.textbook.unlockNext('k1', _marigold.code, force: false))
        .thenThrow(const ServerException('lesson_incomplete', 'open', status: 409));
    when(() => env.textbook.unlockNext('k1', _marigold.code, force: true)).thenAnswer((_) async => _path(next: null));
    await pump(tester, location: '/parent/textbooks/${_marigold.code}');
    await tester.tap(find.byKey(const ValueKey<String>('unlock-next')));
    await tester.pumpAndSettle();
    expect(find.text(Str.unlockEarlyTitle), findsOneWidget);
    await tester.tap(find.text(Str.unlockEarlyCta));
    await tester.pumpAndSettle();
    verify(() => env.textbook.unlockNext('k1', _marigold.code, force: true)).called(1);
  });

  testWidgets('does not force when the parent cancels', (WidgetTester tester) async {
    when(() => env.textbook.unlockNext('k1', _marigold.code, force: false))
        .thenThrow(const ServerException('lesson_incomplete', 'open', status: 409));
    await pump(tester, location: '/parent/textbooks/${_marigold.code}');
    await tester.tap(find.byKey(const ValueKey<String>('unlock-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Str.cancel));
    await tester.pumpAndSettle();
    verifyNever(() => env.textbook.unlockNext('k1', _marigold.code, force: true));
  });
}
