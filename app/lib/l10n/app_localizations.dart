import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_locale.dart';
import 'en_strings.g.dart';

/// Runtime string table for one locale. English — the base, default and
/// fallback locale — is embedded as a Dart const ([kEnStrings]) and resolves
/// synchronously; every other locale loads from `assets/i18n/<code>.json` (a
/// flat `key -> value` map with dot-namespaced keys, e.g. `welcome.title`) and
/// falls back to English for any missing key. A key missing everywhere renders
/// as itself, so a half-translated file degrades gracefully instead of throwing.
class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  /// English fallback shared by every non-English instance, so `of()` never
  /// returns null and any untranslated key still reads in English.
  static final AppLocalizations _englishFallback = AppLocalizations(
    const Locale(kFallbackLocaleCode),
    kEnStrings,
  );

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      _englishFallback;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<Map<String, String>> _loadJson(String code) async {
    final raw = await rootBundle.loadString('assets/i18n/$code.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, '$v'));
  }

  /// Resolves the table for [locale]. English is synchronous ([SynchronousFuture],
  /// so `MaterialApp` mounts its child in the same frame — no flash, no extra
  /// pump in tests). Other locales read their asset and merge over English.
  static Future<AppLocalizations> load(Locale locale) {
    final code = locale.languageCode;
    if (code == kFallbackLocaleCode) {
      return SynchronousFuture(_englishFallback);
    }
    return _loadJson(code).then(
      (strings) => AppLocalizations(locale, {...kEnStrings, ...strings}),
      onError: (Object e, StackTrace _) {
        // A missing/broken locale file must never blank the UI — fall back
        // wholesale to English.
        if (kDebugMode) debugPrint('i18n: failed to load "$code": $e');
        return _englishFallback;
      },
    );
  }

  /// Looks up [key], substituting `{name}` placeholders from [vars]. Falls back
  /// to English, then to the key itself.
  String t(String key, [Map<String, Object?>? vars]) {
    var value = _strings[key] ?? kEnStrings[key] ?? key;
    if (vars != null && vars.isNotEmpty) {
      vars.forEach((name, v) {
        value = value.replaceAll('{$name}', '$v');
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kAppLocales.any((l) => l.code == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// `context.s.t('key')` — the ergonomic accessor, mirroring `context.lt` for
/// theme colors.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get s => AppLocalizations.of(this);
}
