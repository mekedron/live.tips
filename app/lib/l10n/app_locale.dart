import 'package:flutter/widgets.dart';

/// One UI language the app ships. [code] is the locale/asset key
/// (assets/i18n/<code>.json), [name] the endonym shown in the switcher, and
/// [flag] the emoji flag beside it.
class AppLocale {
  const AppLocale(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  Locale get locale => Locale(code);
}

/// Every language the app is translated into — the SAME set and ORDER as the
/// landing page (website/i18n/locales.json), so the switcher reads identically
/// in both places. English is the source/base locale and the fallback.
const List<AppLocale> kAppLocales = [
  AppLocale('en', 'English', '🇬🇧'),
  AppLocale('de', 'Deutsch', '🇩🇪'),
  AppLocale('fr', 'Français', '🇫🇷'),
  AppLocale('es', 'Español', '🇪🇸'),
  AppLocale('it', 'Italiano', '🇮🇹'),
  AppLocale('pt', 'Português', '🇵🇹'),
  AppLocale('nl', 'Nederlands', '🇳🇱'),
  AppLocale('pl', 'Polski', '🇵🇱'),
  AppLocale('uk', 'Українська', '🇺🇦'),
  AppLocale('cs', 'Čeština', '🇨🇿'),
  AppLocale('hu', 'Magyar', '🇭🇺'),
  AppLocale('ro', 'Română', '🇷🇴'),
  AppLocale('el', 'Ελληνικά', '🇬🇷'),
  AppLocale('tr', 'Türkçe', '🇹🇷'),
  AppLocale('sv', 'Svenska', '🇸🇪'),
  AppLocale('da', 'Dansk', '🇩🇰'),
  AppLocale('no', 'Norsk', '🇳🇴'),
  AppLocale('fi', 'Suomi', '🇫🇮'),
  AppLocale('is', 'Íslenska', '🇮🇸'),
  AppLocale('ru', 'Русский', '🇷🇺'),
];

/// The base/fallback locale — its strings are the source of truth and are
/// used whenever a key is missing from another locale.
const String kFallbackLocaleCode = 'en';

/// Every supported [Locale], in landing-page order.
List<Locale> get kSupportedLocales =>
    kAppLocales.map((l) => l.locale).toList(growable: false);

/// The [AppLocale] for [code], or English when unknown.
AppLocale appLocaleFor(String? code) {
  for (final l in kAppLocales) {
    if (l.code == code) return l;
  }
  return kAppLocales.first;
}

/// Resolves the device/user locale to one we actually ship. Matches on the
/// language code alone (we key by language, not region), falling back to
/// English. Used as MaterialApp's localeResolutionCallback.
Locale resolveSupportedLocale(Locale? deviceLocale) {
  if (deviceLocale == null) return const Locale(kFallbackLocaleCode);
  for (final l in kAppLocales) {
    if (l.code == deviceLocale.languageCode) return l.locale;
  }
  return const Locale(kFallbackLocaleCode);
}
