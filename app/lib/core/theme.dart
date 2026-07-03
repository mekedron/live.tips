import 'package:flutter/material.dart';

/// Warm gold on near-black: readable from a distance on a dark stage.
const kGold = Color(0xFFFFC24D);
const kStageBlack = Color(0xFF0D0E12);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGold,
    brightness: Brightness.dark,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kStageBlack,
  );
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: kStageBlack,
      centerTitle: false,
    ),
    cardTheme: base.cardTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}
