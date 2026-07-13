import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_account.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../setup/jar_setup_screen.dart';
import '../shell/app_shell.dart';
import 'venue_identity_screen.dart';
import 'venue_sign_in_screen.dart';

/// Top-level routing for a venue-kind install: the sign-in front door, the
/// "whose account is this" check, then the ordinary shell.
///
/// Also the self-healing spot: if the venue account leaves by any OTHER door
/// (the phone revokes this tablet, a sign-out buried in Settings), the venue
/// session record is still here promising secrets were wiped — so this gate
/// notices the mismatch and runs the same end-of-session broom.
class VenueGate extends ConsumerWidget {
  const VenueGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(venueSessionProvider);
    final active = ref
        .watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
    if (session == null) {
      // No venue session, yet a cloud profile is active: something signed
      // in around the ceremony. Evict it — an account on a public tablet
      // without the ceiling and the banner is exactly what must not exist.
      // (Unless the ceremony is mid-flight: the sign-in screen flips the
      // directory a beat before it writes the session record.)
      if (active != kLocalAccountId &&
          !ref.watch(venueSignInPendingProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
              ref.read(venueSessionProvider.notifier).evictStray(active));
        });
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      return const VenueSignInScreen();
    }

    final sessions = ref.watch(accountSessionsProvider);
    ref.watch(accountSessionsChangesProvider);
    final orphaned = active != session.uid ||
        (sessions.available && !sessions.isAlive(session.uid));
    if (orphaned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(ref.read(venueSessionProvider.notifier).endSession());
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!session.identityConfirmed) return const VenueIdentityScreen();

    final app = ref.watch(appStateProvider);
    final screen = (app.hasStripe && app.effectiveTipJar == null)
        ? const JarSetupScreen()
        : const AppShell();
    // Keyed by band, exactly like RootGate: a switch remounts the subtree so
    // no widget-local cache survives across bands.
    return KeyedSubtree(key: ValueKey(app.accountId), child: screen);
  }
}
