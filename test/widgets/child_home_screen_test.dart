import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/child_home/child_home_screen.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/state/child_mode_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme.dart';
import 'package:homeschooling/theme/kid_palette.dart';
import 'package:homeschooling/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Child _kid = Child(
  id: 'k1',
  familyId: 'f1',
  displayName: 'Aarya',
  avatar: 'star',
  interests: <String>[],
  goals: <String>[],
  version: 1,
);

PlanItem _item(String id, String title, String status) => PlanItem(
      id: id,
      childId: 'k1',
      activity: ActivitySummary(
        id: 'act-$id',
        slug: id,
        title: title,
        subjectCode: 'LNG',
        levelFrom: 'L1',
        levelTo: 'L2',
        durationMin: 15,
        materials: const <String>[],
        interestTags: const <String>[],
        version: 1,
      ),
      scheduledDate: dateOnly(DateTime.now()),
      position: 0,
      status: status,
      version: 1,
    );

class _FakeActiveChild extends ActiveChildNotifier {
  @override
  ActiveChildState build() => const ActiveChildState(mode: AppMode.child, child: _kid);
}

class _FakeToday extends TodayNotifier {
  _FakeToday(this.items);

  final List<PlanItem> items;

  @override
  TodayState build() => TodayState(childId: 'k1', items: items);

  @override
  Future<void> load(String childId, {AuthKind auth = AuthKind.parent}) async {}
}

class _FakeThemes extends ThemeSettingsNotifier {
  _FakeThemes(this.themeId);

  final String themeId;

  @override
  ThemeSettings build() => ThemeSettings(childIds: <String, String>{'k1': themeId});
}

/// WCAG contrast ratio between two colours (4.5 is the usual minimum for body text).
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The colour a [Text] is actually painted with.
Color? _paintedColor(WidgetTester tester, Finder finder) {
  final Text text = tester.widget<Text>(finder);
  return DefaultTextStyle.of(tester.element(finder)).style.merge(text.style).color;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const String longTitle = 'Story retelling in pictures';

  group('Child home activity cards', () {
    for (final ThemeOption option in kThemeOptions) {
      testWidgets('are readable and not squeezed on a narrow phone (${option.name} theme)', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              activeChildProvider.overrideWith(_FakeActiveChild.new),
              todayProvider.overrideWith(() => _FakeToday(<PlanItem>[
                    _item('done1', longTitle, 'completed'),
                    _item('todo1', 'Phonics fun with sounds', 'planned'),
                  ])),
              themeSettingsProvider.overrideWith(() => _FakeThemes(option.id)),
            ],
            child: const MaterialApp(home: ChildHomeScreen()),
          ),
        );
        await tester.pump();

        // Both titles are laid out as normal lines of text: wide enough, and no more than two lines tall.
        // (The bug: a long cheer message beside the title squeezed it to one letter per line.)
        for (final String key in <String>['done1', 'todo1']) {
          final Finder title = find.byKey(ValueKey<String>('activity-title-$key'));
          expect(title, findsOneWidget);
          final Size size = tester.getSize(title);
          expect(size.width, greaterThan(150), reason: 'title for $key is squeezed');
          // The test font (Ahem) is much wider than real fonts, so allow a few lines; the bug gave one letter per
          // line (about 27 lines, 600+ px).
          expect(size.height, lessThan(130), reason: 'title for $key wraps into a tall column');
        }

        // The finished card shows a short "Well done" label, never the long cheer sentence from the theme.
        expect(find.textContaining(Str.activityDone), findsOneWidget);
        expect(find.textContaining('Great work!'), findsNothing);

        // Only the unfinished activity has a Start button.
        expect(find.byKey(const ValueKey<String>('activity-start-todo1')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('activity-start-done1')), findsNothing);

        // Text must be dark enough to read on the light card, in light and dark themes alike.
        final KidPalette palette = KidPalette.of(tester.element(find.byKey(const ValueKey<String>('activity-title-todo1'))));
        for (final String key in <String>['done1', 'todo1']) {
          final Color? ink = _paintedColor(tester, find.byKey(ValueKey<String>('activity-title-$key')));
          expect(ink, isNotNull);
          expect(_contrast(ink!, palette.paper), greaterThanOrEqualTo(4.5), reason: 'title for $key is hard to read');
        }
        final Color? minutes = _paintedColor(tester, find.text('15 min').first);
        expect(_contrast(minutes!, palette.paper), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('OnPaper', () {
    testWidgets('keeps text readable on a paper card even in the dark Space theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.childTheme(kSpaceTheme),
          home: Builder(
            builder: (BuildContext context) {
              final KidPalette p = KidPalette.of(context);
              return Scaffold(
                body: Card(
                  color: p.paper,
                  child: const OnPaper(child: KidPrompt('What did the boy plant?')),
                ),
              );
            },
          ),
        ),
      );

      final Finder prompt = find.text('What did the boy plant?');
      final KidPalette p = KidPalette.of(tester.element(prompt));
      expect(_contrast(_paintedColor(tester, prompt)!, p.paper), greaterThanOrEqualTo(4.5));
    });
  });
}
