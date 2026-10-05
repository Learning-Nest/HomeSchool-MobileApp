import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/features/child_home/child_home_screen.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/state/child_mode_providers.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/state/theme_providers.dart';
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

class _FakeActiveChild extends ActiveChildNotifier {
  @override
  ActiveChildState build() => const ActiveChildState(mode: AppMode.child, child: _kid);
}

class _FakeToday extends TodayNotifier {
  @override
  TodayState build() => const TodayState(childId: 'k1');

  @override
  Future<void> load(String childId, {AuthKind auth = AuthKind.parent}) async {}
}

class _FakeFamily extends FamilyNotifier {
  @override
  FamilyState build() => const FamilyState(children: <Child>[_kid]);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('a child can pick a theme from the labelled button on the home screen', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      activeChildProvider.overrideWith(_FakeActiveChild.new),
      todayProvider.overrideWith(_FakeToday.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: ChildHomeScreen())));
    await tester.pump();

    expect(container.read(themeSettingsProvider).forChild('k1').id, 'space', reason: 'Space is the child default');
    expect(find.text('Theme: ${kSpaceTheme.name}'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('child-theme-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kCandyTheme.name));
    await tester.pumpAndSettle();

    expect(container.read(themeSettingsProvider).forChild('k1').id, 'candy');
    expect(find.text('Theme: ${kCandyTheme.name}'), findsOneWidget, reason: 'the button shows the new theme');
  });

  testWidgets('the app bar palette button opens the same picker for the child', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      activeChildProvider.overrideWith(_FakeActiveChild.new),
      todayProvider.overrideWith(_FakeToday.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: ChildHomeScreen())));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('child-theme-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kJungleTheme.name));
    await tester.pumpAndSettle();

    expect(container.read(themeSettingsProvider).forChild('k1').id, 'jungle');
  });

  testWidgets('a parent can pick a theme from the app bar on any parent screen', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      familyProvider.overrideWith(_FakeFamily.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ParentScaffold(currentPath: '/parent/dashboard', title: 'Dashboard', body: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    expect(container.read(themeSettingsProvider).parent.id, 'jungle', reason: 'Jungle is the parent default');

    await tester.tap(find.byKey(const ValueKey<String>('parent-theme-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kCandyTheme.name));
    await tester.pumpAndSettle();

    expect(container.read(themeSettingsProvider).parent.id, 'candy');
    // A child's choice is separate from the parent's.
    expect(container.read(themeSettingsProvider).forChild('k1').id, 'space');
  });
}
