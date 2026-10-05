import 'package:flutter/material.dart';
import 'package:homeschooling/theme/kid_palette.dart';
import 'package:homeschooling/theme/theme_options.dart';

/// Material 3 themes. Parents and children each pick one of [kThemeOptions]; parents get a calm version of it,
/// child screens get the playful version (big rounded buttons, bright tiles, a backdrop painted by
/// `ChildThemed`).
class AppTheme {
  const AppTheme._();

  static ThemeData light() => parentLight(themeById(kDefaultParentThemeId));

  static ThemeData dark() => parentDark(themeById(kDefaultParentThemeId));

  static ThemeData parentLight(ThemeOption option) => _parent(option, Brightness.light);

  static ThemeData parentDark(ThemeOption option) => _parent(option, Brightness.dark);

  static ThemeData _parent(ThemeOption option, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: option.seed, brightness: brightness);
    return ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: scheme.surface);
  }

  /// The playful look used inside child-mode screens, so a child can tell at a glance that they are in "their"
  /// part of the app. The scaffold is transparent: `ChildThemed` paints the backdrop behind it.
  static ThemeData childTheme(ThemeOption option) {
    final Brightness brightness = option.dark ? Brightness.dark : Brightness.light;
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: option.seed, brightness: brightness);
    final TextTheme text = _scaleUp(ThemeData(brightness: brightness).textTheme, 1.1);
    const Color tileText = Color(0xFF1F1B3D);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: option.dark ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 60),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(96, 60),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.primary, width: 2),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        KidPalette(
          tiles: option.tiles,
          tileText: tileText,
          paper: const Color(0xFFF7F7FF),
          mascot: option.mascot,
          cheer: option.cheer,
        ),
      ],
    );
  }

  /// A font-size bump for child-mode, done manually instead of via TextTheme.apply(fontSizeFactor:), because
  /// that helper trips an assertion in text_style.dart on any style in the base TextTheme whose fontSize is
  /// null.
  static TextTheme _scaleUp(TextTheme t, double factor) => TextTheme(
        displayLarge: _scaleStyle(t.displayLarge, factor),
        displayMedium: _scaleStyle(t.displayMedium, factor),
        displaySmall: _scaleStyle(t.displaySmall, factor),
        headlineLarge: _scaleStyle(t.headlineLarge, factor),
        headlineMedium: _scaleStyle(t.headlineMedium, factor),
        headlineSmall: _scaleStyle(t.headlineSmall, factor),
        titleLarge: _scaleStyle(t.titleLarge, factor),
        titleMedium: _scaleStyle(t.titleMedium, factor),
        titleSmall: _scaleStyle(t.titleSmall, factor),
        bodyLarge: _scaleStyle(t.bodyLarge, factor),
        bodyMedium: _scaleStyle(t.bodyMedium, factor),
        bodySmall: _scaleStyle(t.bodySmall, factor),
        labelLarge: _scaleStyle(t.labelLarge, factor),
        labelMedium: _scaleStyle(t.labelMedium, factor),
        labelSmall: _scaleStyle(t.labelSmall, factor),
      );

  static TextStyle? _scaleStyle(TextStyle? style, double factor) {
    final double? size = style?.fontSize;
    return size == null ? style : style!.copyWith(fontSize: size * factor);
  }
}
