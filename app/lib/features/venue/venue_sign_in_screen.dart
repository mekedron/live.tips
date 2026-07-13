import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import 'venue_code_entry.dart';

/// The venue tablet's front door — what a signed-out shared device shows.
///
/// The artist never types a password here and never sees a Google popup on
/// hardware they don't own: their PHONE mints an add-device code (Settings →
/// Security → Add device), this screen scans it or takes it typed, and the
/// phone's confirm tap is what lets the account in. On success the venue
/// session clock starts and [VenueGate] moves to the identity check.
class VenueSignInScreen extends ConsumerWidget {
  const VenueSignInScreen({super.key});

  /// The escape hatch for a mis-tapped device-kind choice. Venue mode shows
  /// no Settings, no back button and no app bar leading — without this, a
  /// signed-out venue install (QR flow down, or simply the wrong card tapped
  /// at onboarding) is a soft-lock whose only exit is clearing app storage.
  /// Runs the exact wipe-and-reset Settings' kind change runs, behind the
  /// same blunt confirmation — because it IS that wipe: data written under
  /// one trust model must not be inherited by the next.
  Future<void> _confirmNotVenue(BuildContext context, WidgetRef ref) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.device_kind.change_title')),
        content: Text(s.t('settings.device_kind.change_body')),
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
            child: Text(s.t('settings.device_kind.change_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Clearing the kind flips RootGate away from VenueGate — the device
    // lands back on onboarding and chooses what it is again.
    await ref.read(deviceKindProvider.notifier).wipeDevice();
  }

  Future<String?> _onToken(WidgetRef ref, AppLocalizations s, String token) async {
    // The flag holds the gate's stray-account eviction off while the
    // directory has flipped but the session record isn't written yet.
    ref.read(venueSignInPendingProvider.notifier).set(true);
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithCustomToken(token);
      if (user == null) {
        return ref.read(authControllerProvider).error ??
            s.t('venue.code_entry.error_generic');
      }
      await ref.read(venueSessionProvider.notifier).start(user.uid);
      // Take a place in the account's device list: the artist's phone must
      // be able to see — and revoke — this tablet. After the session start,
      // so no frame ever sees a signed-in account without a running clock.
      await ref.read(deviceRegistryProvider).registerThisDevice(user.uid);
      return null;
    } finally {
      ref.read(venueSignInPendingProvider.notifier).set(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguagePill()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 26, color: c.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.t('venue.sign_in.title'),
                        style: outfitStyle(24, c.text, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('venue.sign_in.subtitle'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    height: 1.5,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                LtCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.t('venue.sign_in.how_title'),
                        style: outfitStyle(14, c.text, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.t('venue.sign_in.how_body'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                VenueCodeEntry(
                  onToken: (token) => _onToken(ref, s, token),
                ),
                const SizedBox(height: 20),
                // Always reachable, even signed out: the one door out of a
                // mis-chosen venue mode (see [_confirmNotVenue]). Discreet
                // on purpose — a real venue tablet shouldn't invite taps,
                // and the wipe confirmation stands guard behind it.
                Center(
                  child: TextButton(
                    onPressed: () => _confirmNotVenue(context, ref),
                    child: Text(
                      s.t('venue.sign_in.not_venue'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
