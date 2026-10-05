import 'package:flutter/material.dart';

/// One selectable look for the app. To add a theme, add an entry to [kThemeOptions]; the picker, the saved
/// choice and the child screens all read this list, so nothing else needs to change.
class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.name,
    required this.emoji,
    required this.seed,
    required this.dark,
    required this.backdropTop,
    required this.backdropBottom,
    required this.scatter,
    required this.tiles,
    required this.mascot,
    required this.cheer,
  });

  /// Stable key saved on the device. Never rename an id once it has shipped.
  final String id;

  /// Shown in the picker.
  final String name;
  final String emoji;

  /// Seed for the Material colour scheme.
  final Color seed;

  /// True when the child screens use a dark scheme (light text on a dark backdrop).
  final bool dark;

  /// Top and bottom colours of the child-screen backdrop.
  final Color backdropTop;
  final Color backdropBottom;

  /// Emoji sprinkled faintly over the child-screen backdrop.
  final List<String> scatter;

  /// Bright colours for answer tiles, cards and progress segments, cycled in order.
  final List<Color> tiles;

  /// Character shown on the finish screen.
  final String mascot;

  /// Cheer shown on the finish screen.
  final String cheer;
}

const ThemeOption kSpaceTheme = ThemeOption(
  id: 'space',
  name: 'Space adventure',
  emoji: '🚀',
  seed: Color(0xFF6C5CE7),
  dark: true,
  backdropTop: Color(0xFF0B1033),
  backdropBottom: Color(0xFF2A1B6B),
  scatter: <String>['⭐', '🪐', '🚀', '🌙', '✨', '☄️'],
  tiles: <Color>[Color(0xFFFFC857), Color(0xFFFF7AA2), Color(0xFF4DD0E1), Color(0xFF9CCC65), Color(0xFFFF8A50)],
  mascot: '🚀',
  cheer: 'Blast off! Great work!',
);

const ThemeOption kJungleTheme = ThemeOption(
  id: 'jungle',
  name: 'Jungle friends',
  emoji: '🦁',
  seed: Color(0xFF2E9E5B),
  dark: false,
  backdropTop: Color(0xFFEFFAD9),
  backdropBottom: Color(0xFFB9E5A1),
  scatter: <String>['🌿', '🦜', '🐒', '🍃', '🦋', '🌴'],
  tiles: <Color>[Color(0xFFFFD54F), Color(0xFFFF8A65), Color(0xFF4DB6AC), Color(0xFFAED581), Color(0xFFBA68C8)],
  mascot: '🦁',
  cheer: 'Roar! Great work!',
);

const ThemeOption kCandyTheme = ThemeOption(
  id: 'candy',
  name: 'Candy rainbow',
  emoji: '🌈',
  seed: Color(0xFFE91E8C),
  dark: false,
  backdropTop: Color(0xFFFFF0F8),
  backdropBottom: Color(0xFFDDEBFF),
  scatter: <String>['🍭', '🌈', '🍬', '🧁', '🎈', '🦄'],
  tiles: <Color>[Color(0xFFFF80AB), Color(0xFF82B1FF), Color(0xFFFFD180), Color(0xFFB388FF), Color(0xFF80E5C4)],
  mascot: '🦄',
  cheer: 'Sweet! Great work!',
);

/// Every theme the picker offers, in display order. Add new themes here.
const List<ThemeOption> kThemeOptions = <ThemeOption>[kSpaceTheme, kJungleTheme, kCandyTheme];

/// Theme used on child screens until a child picks one.
const String kDefaultChildThemeId = 'space';

/// Theme used on parent screens until a parent picks one.
const String kDefaultParentThemeId = 'jungle';

/// The option with [id], or the first option when [id] is null or no longer exists (for example after a
/// theme was removed in an update).
ThemeOption themeById(String? id) {
  for (final ThemeOption o in kThemeOptions) {
    if (o.id == id) return o;
  }
  return kThemeOptions.first;
}
