import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _parentKey = 'theme.parent';
const String _childKeyPrefix = 'theme.child.';

/// The theme each person picked: one for the parent screens and one per child profile. Stored on this device
/// only (shared_preferences); it holds a theme id and a child id, nothing else.
class ThemeSettings {
  const ThemeSettings({this.parentId = kDefaultParentThemeId, this.childIds = const <String, String>{}});

  final String parentId;

  /// Child id -> theme id.
  final Map<String, String> childIds;

  ThemeOption get parent => themeById(parentId);

  /// The theme for [childId]; [kDefaultChildThemeId] until that child picks one.
  ThemeOption forChild(String? childId) => themeById(childId == null ? null : (childIds[childId] ?? kDefaultChildThemeId));

  ThemeSettings copyWith({String? parentId, Map<String, String>? childIds}) {
    return ThemeSettings(parentId: parentId ?? this.parentId, childIds: childIds ?? this.childIds);
  }
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    Future<void>.microtask(_load);
    return const ThemeSettings();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, String> children = <String, String>{};
      for (final String key in prefs.getKeys()) {
        if (!key.startsWith(_childKeyPrefix)) continue;
        final String? value = prefs.getString(key);
        if (value != null) children[key.substring(_childKeyPrefix.length)] = value;
      }
      state = ThemeSettings(parentId: prefs.getString(_parentKey) ?? kDefaultParentThemeId, childIds: children);
    } catch (_) {
      // No storage (for example in a widget test): keep the defaults.
    }
  }

  Future<void> setParent(String themeId) async {
    state = state.copyWith(parentId: themeId);
    await _save(_parentKey, themeId);
  }

  Future<void> setChild(String childId, String themeId) async {
    state = state.copyWith(childIds: <String, String>{...state.childIds, childId: themeId});
    await _save('$_childKeyPrefix$childId', themeId);
  }

  Future<void> _save(String key, String value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // The choice still applies for this run even if it could not be saved.
    }
  }
}

final NotifierProvider<ThemeSettingsNotifier, ThemeSettings> themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(ThemeSettingsNotifier.new);
