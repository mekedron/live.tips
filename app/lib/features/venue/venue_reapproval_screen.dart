import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/firebase/custom_token.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/venue_providers.dart';
import 'venue_code_entry.dart';

/// The owner's rule: touching profiles ON the venue device needs a fresh
/// nod from the personal device — so this gate runs one more add-device
/// confirm cycle before the band switcher does anything.
///
/// Returns true only when the SAME account approved: the collected token's
/// uid claim is compared against the account on the tablet, and a different
/// approver is refused with a clear message (nothing is signed in with that
/// token; the sign-in is where Firebase would verify it, and it never runs).
Future<bool> ensureVenueReapproval(BuildContext context, WidgetRef ref) async {
  if (ref.read(deviceKindProvider) != DeviceKind.venue) return true;
  final session = ref.read(venueSessionProvider);
  if (session == null) return true; // nobody's data on the device to protect
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
