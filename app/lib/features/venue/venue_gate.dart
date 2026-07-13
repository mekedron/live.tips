import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_account.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../onboarding/profile_pick_screen.dart';
import '../setup/jar_setup_screen.dart';
import '../shell/app_shell.dart';
import 'venue_identity_screen.dart';
import 'venue_sign_in_screen.dart';

/// Top-level routing for a venue-kind install: the sign-in front door, the
/// "whose account is this" check, the "which profile is tonight's" question,
/// then the ordinary shell.
///
/// The last of those is RootGate's, asked with RootGate's provider
/// ([activeProfileRenderProvider]) and answered on RootGate's screen — because
/// a venue tablet is not a different app, it is the same app on hardware the
/// artist does not own. Every rule that keeps the app from opening the wrong
/// gig, or minting a gig nobody asked for, holds here too (#43).
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
    // The profile question, asked here exactly as RootGate asks it. This gate
    // used to go straight to the shell, so an artist whose account holds two
    // profiles got a shell built around `accountId == ''` — a band that does
    // not exist — and a "Set it up" button offering to create a THIRD one. The
    // rules #26 and #28 settled ("several ask, never guess"; "the app never
    // mints a profile") reached RootGate and never reached the venue path, and
    // the tablet on the merch table was the one device where guessing wrong is
    // public. Same provider, same two states, same screen (#43).
    final render = ref.watch(activeProfileRenderProvider);
    final screen =
        render == ProfileRender.pick || render == ProfileRender.create
            ? const ProfilePickScreen(asRoot: true)
            : (app.hasStripe && app.effectiveTipJar == null)
                ? const JarSetupScreen()
                : const AppShell();
    // Keyed by band, exactly like RootGate: a switch remounts the subtree so
    // no widget-local cache survives across bands.
    return KeyedSubtree(key: ValueKey(app.accountId), child: screen);
  }
}
