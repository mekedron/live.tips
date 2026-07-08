import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/l10n/app_locale.dart';
import 'package:live_tips/l10n/app_localizations.dart';

/// Exercises the async asset-loading path — non-English locales load their
/// `assets/i18n/<code>.json` — which the synchronous English default doesn't
/// cover. Uses [WidgetTester.runAsync] so the real rootBundle read completes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every shipped locale loads from its asset with all keys',
      (tester) async {
    await tester.runAsync(() async {
      // English is the key baseline (embedded const).
      final en = await AppLocalizations.load(const Locale('en'));
      for (final loc in kAppLocales) {
        final l = await AppLocalizations.load(Locale(loc.code));
        // A representative translated key resolves (non-empty).
        expect(l.t('welcome.get_started').trim(), isNotEmpty,
            reason: '${loc.code}: welcome.get_started empty');
        // Fallback: every locale can resolve any English key (missing keys
        // fall back to English rather than showing the raw key).
        expect(l.t('settings.main.title'), isNot('settings.main.title'),
            reason: '${loc.code}: settings.main.title unresolved');
      }
      // Spot-check a few actual translations landed.
      final de = await AppLocalizations.load(const Locale('de'));
      final fr = await AppLocalizations.load(const Locale('fr'));
      final ru = await AppLocalizations.load(const Locale('ru'));
      expect(de.t('welcome.get_started'), 'Loslegen');
      expect(fr.t('live.live_badge'), 'EN DIRECT');
      expect(ru.t('settings.main.title'), 'Настройки');
      // Placeholder interpolation still works on a loaded locale.
      expect(de.t('settings.main.box', {'id': 'abc'}), contains('abc'));
      // An unknown key passes through unchanged (never throws).
      expect(en.t('no.such.key'), 'no.such.key');
    });
  });
}
