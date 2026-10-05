import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every theme has a unique id and the defaults exist', () {
    final Set<String> ids = kThemeOptions.map((ThemeOption o) => o.id).toSet();
    expect(ids.length, kThemeOptions.length);
    expect(ids, containsAll(<String>['space', 'jungle', 'candy']));
    expect(ids, contains(kDefaultChildThemeId));
    expect(ids, contains(kDefaultParentThemeId));
  });

  test('an unknown theme id falls back instead of crashing', () {
    expect(themeById('no-such-theme'), kThemeOptions.first);
    expect(themeById(null), kThemeOptions.first);
  });

  test('defaults: parent Jungle, each child Space until they choose', () {
    const ThemeSettings s = ThemeSettings();
    expect(s.parent.id, 'jungle');
    expect(s.forChild('kid-1').id, 'space');
    expect(s.forChild(null).id, 'space');
  });

  test('parent and each child keep their own choice, saved on the device', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ThemeSettingsNotifier notifier = container.read(themeSettingsProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await notifier.setParent('candy');
    await notifier.setChild('kid-1', 'jungle');

    final ThemeSettings s = container.read(themeSettingsProvider);
    expect(s.parent.id, 'candy');
    expect(s.forChild('kid-1').id, 'jungle');
    expect(s.forChild('kid-2').id, 'space');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme.parent'), 'candy');
    expect(prefs.getString('theme.child.kid-1'), 'jungle');
  });

  test('saved choices are loaded when the app starts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'theme.parent': 'space', 'theme.child.kid-9': 'candy'});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeSettingsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final ThemeSettings s = container.read(themeSettingsProvider);
    expect(s.parent.id, 'space');
    expect(s.forChild('kid-9').id, 'candy');
  });
}
