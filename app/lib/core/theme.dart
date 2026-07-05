import 'package:flutter/material.dart';

/// live.tips 2.0 — warm paper neutrals, one coral accent, Outfit for
/// headings & money, Noto Sans for body. Light + dark schemes; the live
/// stage stays always-dark and uses the glass tokens below.

/// Kept for the always-dark stage: banked-jar trophies stay warm gold so
/// they read as "money in the bank" against any scene.
const kGold = Color(0xFFFFC24D);

/// The stage void behind the 3D renderer.
const kStageBlack = Color(0xFF0B0A0F);

/// Heading / money font. Body text stays Noto Sans (theme default).
const kFontOutfit = 'Outfit';
const kFontBody = 'Noto Sans';

/// Design tokens that Material's [ColorScheme] has no slot for.
/// Reach them via `context.lt`.
@immutable
class LtColors extends ThemeExtension<LtColors> {
  const LtColors({
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.bg,
    required this.card,
    required this.border,
    required this.divider,
    required this.chip,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.danger,
  });

  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color bg;
  final Color card;
  final Color border;
  final Color divider;
  final Color chip;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color danger;

  static const light = LtColors(
    accent: Color(0xFFE8542F),
    onAccent: Colors.white,
    accentSoft: Color(0xFFFDE7DF),
    onAccentSoft: Color(0xFF8A2E14),
    bg: Color(0xFFFAF6F1),
    card: Colors.white,
    border: Color(0xFFE9E1D6),
    divider: Color(0xFFF3EDE5),
    chip: Color(0xFFF3EDE5),
    text: Color(0xFF221D18),
    textSecondary: Color(0xFF70685D),
    textMuted: Color(0xFF9C948A),
    textFaint: Color(0xFFC9C1B5),
    success: Color(0xFF1E9E62),
    successContainer: Color(0xFFDFF3E7),
    onSuccessContainer: Color(0xFF136A41),
    danger: Color(0xFFC43C2A),
  );

  static const dark = LtColors(
    accent: Color(0xFFFF7C55),
    onAccent: Color(0xFF40160A),
    accentSoft: Color(0xFF3E2018),
    onAccentSoft: Color(0xFFFFB79F),
    bg: Color(0xFF14110E),
    card: Color(0xFF1E1A16),
    border: Color(0xFF322C26),
    divider: Color(0xFF272219),
    chip: Color(0xFF272219),
    text: Color(0xFFF5F0E8),
    textSecondary: Color(0xFFA79E92),
    textMuted: Color(0xFF7E766B),
    textFaint: Color(0xFF57504A),
    success: Color(0xFF4FCB8D),
    successContainer: Color(0xFF173226),
    onSuccessContainer: Color(0xFF4FCB8D),
    danger: Color(0xFFFF6B5E),
  );

  @override
  LtColors copyWith() => this;

  @override
  LtColors lerp(LtColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return LtColors(
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccentSoft: mix(onAccentSoft, other.onAccentSoft),
      bg: mix(bg, other.bg),
      card: mix(card, other.card),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      chip: mix(chip, other.chip),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      danger: mix(danger, other.danger),
    );
  }
}

extension LtColorsX on BuildContext {
  LtColors get lt => Theme.of(this).extension<LtColors>()!;
}

/// Outfit extra-bold — the money style. Size varies per surface.
TextStyle moneyStyle(double size, Color color, {double height = 1.0}) =>
    TextStyle(
      fontFamily: kFontOutfit,
      fontWeight: FontWeight.w800,
      fontSize: size,
      color: color,
      height: height,
    );

/// Outfit label — buttons, chips, tab labels, section headers.
TextStyle outfitStyle(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w600,
  double? letterSpacing,
  double? height,
}) =>
    TextStyle(
      fontFamily: kFontOutfit,
      fontWeight: weight,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextTheme _textTheme(LtColors c) => TextTheme(
      displayLarge: outfitStyle(52, c.text, weight: FontWeight.w800),
      displayMedium: outfitStyle(40, c.text, weight: FontWeight.w800),
      displaySmall: outfitStyle(34, c.text, weight: FontWeight.w800),
      headlineLarge: outfitStyle(32, c.text, weight: FontWeight.w800),
      headlineMedium: outfitStyle(26, c.text, weight: FontWeight.w800),
      headlineSmall: outfitStyle(24, c.text, weight: FontWeight.w700),
      titleLarge: outfitStyle(20, c.text, weight: FontWeight.w700),
      titleMedium: outfitStyle(16, c.text, weight: FontWeight.w700),
      titleSmall: outfitStyle(14.5, c.text, weight: FontWeight.w600),
      bodyLarge: TextStyle(
          fontFamily: kFontBody, fontSize: 15, color: c.text, height: 1.5),
      bodyMedium: TextStyle(
          fontFamily: kFontBody, fontSize: 14, color: c.text, height: 1.45),
      bodySmall: TextStyle(
          fontFamily: kFontBody,
          fontSize: 12.5,
          color: c.textSecondary,
          height: 1.45),
      labelLarge: outfitStyle(15, c.text),
      labelMedium: outfitStyle(13, c.textSecondary),
      labelSmall: outfitStyle(11, c.textMuted,
          weight: FontWeight.w700, letterSpacing: 1.2),
    );

ThemeData _buildTheme(LtColors c, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.onAccentSoft,
    secondary: c.textSecondary,
    onSecondary: c.card,
    // FilledButton.tonal picks these up → the design's "soft" button.
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.onAccentSoft,
    tertiary: c.success,
    onTertiary: Colors.white,
    tertiaryContainer: c.successContainer,
    onTertiaryContainer: c.onSuccessContainer,
    error: c.danger,
    onError: Colors.white,
    errorContainer: c.accentSoft,
    onErrorContainer: c.danger,
    surface: c.bg,
    onSurface: c.text,
    surfaceContainerLowest: c.card,
    surfaceContainerLow: c.card,
    surfaceContainer: c.card,
    surfaceContainerHigh: c.chip,
    surfaceContainerHighest: c.chip,
    onSurfaceVariant: c.textSecondary,
    outline: c.border,
    outlineVariant: c.divider,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: c.text,
    onInverseSurface: c.bg,
    inversePrimary: c.accentSoft,
  );

  final textTheme = _textTheme(c);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: kFontBody,
    textTheme: textTheme,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    dividerColor: c.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: outfitStyle(18, c.text),
      iconTheme: IconThemeData(color: c.text, size: 24),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: outfitStyle(16, Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        backgroundColor: c.card,
        side: BorderSide(color: c.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: outfitStyle(15, c.text),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        textStyle: outfitStyle(13.5, c.accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.danger, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 1.5),
      ),
      labelStyle: TextStyle(fontFamily: kFontBody, color: c.textSecondary),
      hintStyle: TextStyle(fontFamily: kFontBody, color: c.textMuted),
      helperStyle: TextStyle(
          fontFamily: kFontBody, color: c.textMuted, fontSize: 12),
    ),
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSecondary,
      titleTextStyle: TextStyle(
        fontFamily: kFontBody,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: kFontBody,
        fontSize: 12.5,
        color: c.textSecondary,
        height: 1.4,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.accent : c.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.chip,
      selectedColor: c.accent,
      labelStyle: outfitStyle(13, c.textSecondary),
      secondaryLabelStyle: outfitStyle(13, c.onAccent),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      showCheckmark: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: outfitStyle(20, c.text, weight: FontWeight.w700),
      contentTextStyle: TextStyle(
          fontFamily: kFontBody, fontSize: 14, color: c.text, height: 1.5),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: TextStyle(
          fontFamily: kFontBody, fontSize: 14, color: c.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      textStyle: TextStyle(
          fontFamily: kFontBody, fontSize: 14, color: c.text),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.divider,
      circularTrackColor: Colors.transparent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
          fontFamily: kFontBody, fontSize: 14.5, color: c.text),
    ),
  );
}

ThemeData buildLightTheme() => _buildTheme(LtColors.light, Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(LtColors.dark, Brightness.dark);
