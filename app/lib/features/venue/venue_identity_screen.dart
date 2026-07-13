import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/profile_switcher.dart';
import '../../widgets/lt_ui.dart';

/// The moment after a venue sign-in: WHOSE account just landed on this
/// tablet, said prominently, with a one-tap way out.
///
/// This is the safety net for a mistyped code, a mis-scanned QR, and the
/// artist who approved the wrong request on their phone — the tablet must
/// never slide silently into someone's account. Nothing proceeds until a
/// human looks at the name and says "that's me".
class VenueIdentityScreen extends ConsumerStatefulWidget {
  const VenueIdentityScreen({super.key});

  @override
  ConsumerState<VenueIdentityScreen> createState() =>
      _VenueIdentityScreenState();
}

class _VenueIdentityScreenState extends ConsumerState<VenueIdentityScreen> {
  bool _busy = false;

  Future<void> _notMe() async {
    if (_busy) return;
    setState(() => _busy = true);
    // endSession wipes the just-cached secrets and signs the account out —
    // the same broom every other exit uses.
    await ref.read(venueSessionProvider.notifier).endSession();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(venueSessionProvider.notifier).confirmIdentity();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final session = ref.watch(venueSessionProvider);
    final directory = ref.watch(accountsDirectoryProvider);
    final auth = ref.watch(authControllerProvider);
    final entry = directory.accounts
            .where((a) => a.id == session?.uid)
            .firstOrNull ??
        (auth.user != null && auth.user!.uid == session?.uid
            ? AppAccount(
                id: auth.user!.uid,
                name: auth.user!.displayName ?? '',
                kind: auth.user!.kind,
                email: auth.user!.email,
              )
            : null);
    final name = entry == null
        ? s.t('venue.identity.unknown_account')
        : accountDisplayName(context, entry);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                LtCard(
                  child: Column(
                    children: [
                      InitialAvatar(
                        name: name,
                        anonymous: entry == null ||
                            entry.kind == AccountKind.anonymous,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.t('venue.identity.signed_in_as'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: outfitStyle(26, c.text, weight: FontWeight.w800),
                      ),
                      if (entry != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            accountProviderLabel(context, entry.kind),
                            if (entry.email != null) entry.email!,
                          ].join(' · '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        s.t('venue.identity.check_body'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LtPrimaryButton(
                        label: s.t('venue.identity.confirm'),
                        icon: Icons.check_rounded,
                        busy: _busy,
                        onPressed: () => unawaited(_confirm()),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => unawaited(_notMe()),
                        icon: Icon(Icons.logout_rounded,
                            size: 18, color: c.danger),
                        label: Text(
                          s.t('venue.identity.not_me'),
                          style: outfitStyle(14, c.danger,
                              weight: FontWeight.w600),
                        ),
                      ),
                    ],
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
