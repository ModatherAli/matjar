import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

/// Matjar luxury design system: charcoal + ivory + antique gold + emerald.
abstract final class MatjarColors {
  static const Color charcoal = Color(0xFF121212);
  static const Color onyx = Color(0xFF1C1C1E);
  static const Color ivory = Color(0xFFFAF7F0);
  static const Color sand = Color(0xFFEFE7D8);
  static const Color gold = Color(0xFFC6A15B);
  static const Color goldDeep = Color(0xFF9A7A3B);
  static const Color emerald = Color(0xFF0E3B2E);
  static const Color danger = Color(0xFFB3261E);
}

ThemeData _baseTheme({
  required Brightness brightness,
  required Color scaffold,
  required Color surface,
  required Color onSurface,
  required Color muted,
}) {
  final display = GoogleFonts.playfairDisplayTextTheme().apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );
  final body = GoogleFonts.interTextTheme().apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );
  final textTheme = display.copyWith(
    bodyLarge: body.bodyLarge,
    bodyMedium: body.bodyMedium,
    bodySmall: body.bodySmall,
    labelLarge: body.labelLarge,
    labelMedium: body.labelMedium,
    labelSmall: body.labelSmall?.copyWith(letterSpacing: 1.4),
  );

  final goldScheme = ColorScheme.fromSeed(
    seedColor: MatjarColors.gold,
    brightness: brightness,
  ).copyWith(
    primary: MatjarColors.gold,
    onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
    secondary: MatjarColors.emerald,
    surface: surface,
    onSurface: onSurface,
    error: MatjarColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: goldScheme,
    scaffoldBackgroundColor: scaffold,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MatjarColors.gold,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MatjarColors.gold,
        side: const BorderSide(color: MatjarColors.gold, width: 1.2),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark
          ? MatjarColors.onyx
          : Colors.white,
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: muted.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: MatjarColors.gold, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: MatjarColors.danger),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: muted.withValues(alpha: 0.25)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: MatjarColors.gold.withValues(alpha: 0.4),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

ThemeData buildDarkTheme() => _baseTheme(
      brightness: Brightness.dark,
      scaffold: MatjarColors.charcoal,
      surface: MatjarColors.onyx,
      onSurface: MatjarColors.ivory,
      muted: Colors.grey,
    );

ThemeData buildLightTheme() => _baseTheme(
      brightness: Brightness.light,
      scaffold: MatjarColors.ivory,
      surface: Colors.white,
      onSurface: MatjarColors.charcoal,
      muted: const Color(0xFF8A8A8A),
    );

