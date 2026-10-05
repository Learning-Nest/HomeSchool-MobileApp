import 'package:flutter/material.dart';

/// Bright colours and characters that the child-friendly widgets read from the current theme. Widgets built
/// outside a child theme (for example in tests) fall back to [KidPalette.fallback].
@immutable
class KidPalette extends ThemeExtension<KidPalette> {
  const KidPalette({
    required this.tiles,
    required this.tileText,
    required this.paper,
    required this.mascot,
    required this.cheer,
  });

  final List<Color> tiles;

  /// Text colour that is readable on every colour in [tiles].
  final Color tileText;

  /// Near-white fill for tiles that are not selected.
  final Color paper;
  final String mascot;
  final String cheer;

  Color tile(int index) => tiles[index % tiles.length];

  static const KidPalette fallback = KidPalette(
    tiles: <Color>[Color(0xFFFFC857), Color(0xFFFF7AA2), Color(0xFF4DD0E1), Color(0xFF9CCC65), Color(0xFFFF8A50)],
    tileText: Color(0xFF1F1B3D),
    paper: Color(0xFFF7F7FF),
    mascot: '⭐',
    cheer: 'Great work!',
  );

  static KidPalette of(BuildContext context) => Theme.of(context).extension<KidPalette>() ?? fallback;

  @override
  KidPalette copyWith({List<Color>? tiles, Color? tileText, Color? paper, String? mascot, String? cheer}) {
    return KidPalette(
      tiles: tiles ?? this.tiles,
      tileText: tileText ?? this.tileText,
      paper: paper ?? this.paper,
      mascot: mascot ?? this.mascot,
      cheer: cheer ?? this.cheer,
    );
  }

  @override
  KidPalette lerp(ThemeExtension<KidPalette>? other, double t) {
    if (other is! KidPalette) return this;
    return t < 0.5 ? this : other;
  }
}
