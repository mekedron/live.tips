import 'package:flutter/material.dart';

/// Warm gold on near-black: readable from a distance on a dark stage.
const kGold = Color(0xFFFFC24D);
const kStageBlack = Color(0xFF0D0E12);

/// Shape and typography rules shared by both brightnesses — only the
/// [ColorScheme] and background differ between [buildLightTheme] and
/// [buildDarkTheme].
ThemeData _polish(ThemeData base) => base.copyWith(
  appBarTheme: base.appBarTheme.copyWith(
    backgroundColor: base.scaffoldBackgroundColor,
    centerTitle: false,
  ),
  cardTheme: base.cardTheme.copyWith(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
  snackBarTheme: base.snackBarTheme.copyWith(
    behavior: SnackBarBehavior.floating,
  ),
);

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGold,
    brightness: Brightness.dark,
  );
  return _polish(
    ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: kStageBlack,
    ),
  );
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGold,
    brightness: Brightness.light,
  );
  return _polish(
    ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    ),
  );
}
