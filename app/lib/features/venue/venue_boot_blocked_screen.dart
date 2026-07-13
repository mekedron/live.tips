import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/theme.dart';
import '../../data/venue_boot.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lt_ui.dart';

/// The app a blocked venue boot runs INSTEAD of [LiveTipsApp] (see
/// [attachVenueCipher]). Deliberately its own MaterialApp: a blocked boot
/// stops before providers, Firebase or the registry exist, so there is
/// nothing for the normal shell to stand on — and nothing it may touch.
class VenueBootBlockedApp extends StatelessWidget {
  const VenueBootBlockedApp({
    super.key,
    required this.block,
    required this.locale,
    required this.onRetry,
    required this.onErase,
  });

  final VenueBootBlock block;

  /// The device locale — the SAVED language sits inside the very envelopes
  /// this screen exists because it can't read.
  final Locale locale;

  /// Re-runs the whole boot from the top. A blocked boot returned before
  /// anything was initialized, so a retry is simply main() again.
  final VoidCallback onRetry;

  /// The confirmed erase-and-start-over — the restore state's only other
  /// way out.
  final Future<void> Function() onErase;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'live.tips',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: VenueBootBlockedScreen(
            block: block, onRetry: onRetry, onErase: onErase),
      );
}

/// Says exactly what stopped the boot and offers the honest exits: retry
/// for a locked keychain (transient), retry-or-erase for a restore whose
/// root key didn't come along (that data is unreadable here, and only a
/// deliberate, confirmed erase may remove it).
class VenueBootBlockedScreen extends StatelessWidget {
  const VenueBootBlockedScreen({
    super.key,
    required this.block,
    required this.onRetry,
    required this.onErase,
  });

  final VenueBootBlock block;
  final VoidCallback onRetry;
  final Future<void> Function() onErase;

  /// Same blunt shape as the Settings kind-change dialog — it IS that wipe,
  /// reached from the one screen where the data is already unreadable.
  Future<void> _confirmErase(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('venue.boot.erase_title')),
        content: Text(s.t('venue.boot.erase_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('venue.boot.erase_confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) await onErase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final restore = block == VenueBootBlock.rootKeyMissing;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: c.warningContainer, shape: BoxShape.circle),
                  child: Icon(
                    restore
                        ? Icons.settings_backup_restore_rounded
                        : Icons.lock_outline_rounded,
                    size: 30,
                    color: c.warning,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.t(restore
                    ? 'venue.boot.restore_title'
                    : 'venue.boot.locked_title'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                s.t(restore
                    ? 'venue.boot.restore_body'
                    : 'venue.boot.locked_body'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: s.t('venue.boot.retry'),
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              if (restore) ...[
                const SizedBox(height: 12),
                LtDangerButton(
                  label: s.t('venue.boot.erase_button'),
                  icon: Icons.delete_forever_rounded,
                  onPressed: () => unawaited(_confirmErase(context)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
