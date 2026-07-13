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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
