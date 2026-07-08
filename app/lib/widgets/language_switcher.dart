import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';

/// The active UI language, as an [AppLocale]: the user's explicit choice when
/// set, else whatever the device language resolved to. Reads the live
/// `Localizations` locale so it always matches what's actually on screen.
AppLocale activeAppLocale(BuildContext context) =>
    appLocaleFor(Localizations.localeOf(context).languageCode);

/// A compact flag pill that opens the language picker — for the top-right of
/// the very first (Welcome) screen, before any account exists.
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final active = activeAppLocale(context);
    return Material(
      color: c.chip,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showLanguageSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(active.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                active.code.toUpperCase(),
                style: outfitStyle(
                  13,
                  c.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 16, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the language picker sheet — every shipped language, in the same order
/// as the landing page, with the active one checked.
Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final activeCode = activeAppLocale(context).code;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                context.s.t('language.title'),
                style: outfitStyle(18, c.text, weight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final loc in kAppLocales)
                    _LanguageRow(
                      locale: loc,
                      active: loc.code == activeCode,
                      onTap: () {
                        final settings = ref.read(appStateProvider).settings;
                        ref
                            .read(appStateProvider.notifier)
                            .updateSettings(
                              settings.copyWith(localeCode: loc.code),
                            );
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.locale,
    required this.active,
    required this.onTap,
  });

  final AppLocale locale;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: active ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(locale.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  locale.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: outfitStyle(
                    15,
                    c.text,
                    weight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (active)
                Icon(Icons.check_circle_rounded, size: 22, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
