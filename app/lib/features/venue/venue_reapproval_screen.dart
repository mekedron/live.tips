import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/firebase/custom_token.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import 'venue_code_entry.dart';

/// The owner's rule: touching profiles ON the venue device needs a fresh
/// nod from the personal device — so this gate runs one more add-device
/// confirm cycle before the switcher does anything.
///
/// Returns true only when the SAME account approved: the collected token's
/// uid claim is compared against the account on the tablet, and a different
/// approver is refused with a clear message (nothing is signed in with that
/// token; the sign-in is where Firebase would verify it, and it never runs).
///
/// What it guards is a CHANGE to what the tablet is showing. The stint's first
/// profile choice is not one: with no profile open ([ProfileRender.pick] /
/// [ProfileRender.create] — the picker VenueGate lands on), the artist is
/// finishing the ceremony they just walked through on their phone, not
/// altering it. Demanding a second code to answer the question the session
/// itself asks is how the venue path ended up inviting the artist to mint a
/// third profile instead (#43) — and it protects nothing: whoever holds the
/// tablet already holds the signed-in account, which is precisely what the
/// intro's warning says out loud.
Future<bool> ensureVenueReapproval(BuildContext context, WidgetRef ref) async {
  if (ref.read(deviceKindProvider) != DeviceKind.venue) return true;
  final session = ref.read(venueSessionProvider);
  if (session == null) return true; // nobody's data on the device to protect
  if (ref.read(activeProfileRenderProvider) != ProfileRender.band) return true;
  final approved = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VenueReapprovalScreen(expectedUid: session.uid),
    ),
  );
  return approved == true;
}

class VenueReapprovalScreen extends ConsumerWidget {
  const VenueReapprovalScreen({super.key, required this.expectedUid});

  /// The account already on this tablet — the only one whose approval counts.
  final String expectedUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('venue.reapprove.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                s.t('venue.reapprove.body'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              VenueCodeEntry(
                onToken: (token) async {
                  final uid = uidOfCustomToken(token);
                  if (uid != expectedUid) {
                    return s.t('venue.reapprove.wrong_account');
                  }
                  if (context.mounted) Navigator.of(context).pop(true);
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
