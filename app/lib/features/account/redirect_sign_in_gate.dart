import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_providers.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../onboarding/account_name_screen.dart';
import '../onboarding/profile_pick_screen.dart';
import '../settings/settings_screen.dart';
import '../shell/app_shell.dart';
import '../../domain/device_kind.dart';
import '../../domain/pending_redirect.dart';

/// The return leg of a web sign-in.
///
/// On the web an Apple/Google sign-in leaves the page (see AuthController:
/// popups are blocked on iOS Safari and hang forever inside an installed PWA),
/// so the app that comes back is a NEW app: no navigation stack, no in-memory
/// state, no idea that a sign-in was ever in flight. This gate is the only
/// thing that remembers.
///
/// It runs before the user can touch anything: while a redirect is pending it
/// shows a boot spinner instead of the root screen — otherwise the first frame
/// is Welcome (nobody is signed in yet), which would flash a "you have no
/// account" pitch at somebody who just signed in. Then it hands the result to
/// [AuthController.consumePendingRedirect], which routes it through the same
/// slot/adopt path a native sign-in takes — so everything downstream of a
/// sign-in (the cloud-upload offer, the device registry, the switcher) fires
/// exactly as it always has.
///
/// The spinner is bounded on every path: a result, no result, an error, or the
/// consume's own timeout. A permanent spinner is the bug this gate replaces.
class RedirectSignInGate extends ConsumerStatefulWidget {
  const RedirectSignInGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RedirectSignInGate> createState() => _RedirectSignInGateState();
}

class _RedirectSignInGateState extends ConsumerState<RedirectSignInGate> {
  /// True from the FIRST frame when a redirect is waiting to be claimed — the
  /// read is synchronous (prefs are already loaded at boot), so the root screen
  /// is never built against the pre-sign-in world.
  late bool _resuming =
      ref.read(localStoreProvider).readPendingRedirect() != null;

  @override
  void initState() {
    super.initState();
    if (_resuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
    }
  }

  Future<void> _resume() async {
    RedirectResume? resume;
    try {
      resume = await ref.read(authControllerProvider.notifier)
          .consumePendingRedirect();
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
    if (!mounted || resume == null) return;
    final record = resume.record;

    // The onboarding work the reload would otherwise have eaten: the draft
    // (band name, currency, chosen methods) and the step counter. Restored
    // whatever the outcome — a cancelled sign-in must not cost it either.
    final draft = record.draft;
    if (draft != null) {
      ref
          .read(onboardingDraftProvider.notifier)
          .set(OnboardingDraft.fromJson(draft));
    }

    final error = resume.error;
    if (error != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final user = resume.user;
    if (user == null) return; // cancelled on the provider's page — stay put

    switch (record.origin) {
      case RedirectOrigin.onboarding:
        // Exactly what AccountStepScreen does after a native sign-in: name
        // the account if the provider didn't, then the profile fork — the
        // account's existing profiles, when it has any, come before band
        // creation here too.
        final unnamed = (user.displayName ?? '').trim().isEmpty;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => unnamed
              ? const AccountNameScreen()
              : const ProfilePickScreen(),
        ));
      case RedirectOrigin.settings:
        // Settings, the switcher and the sheet all live behind the Settings
        // tab — land there rather than on Home. Except when the account that
        // just signed in has no profile, or several and no answer: the root is
        // then the picker, no shell mounts, and the tab request was left on the
        // floor — the artist landed on a create/pick screen with no word about
        // the sign-in they had just completed (#40). The picker has a Settings
        // route of its own now, so ask for the screen rather than the tab.
        final render = ref.read(activeProfileRenderProvider);
        if (ref.read(deviceKindProvider) != DeviceKind.venue &&
            (render == ProfileRender.pick || render == ProfileRender.create)) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsRouteScreen()),
          );
        } else {
          ref.read(shellTabRequestProvider.notifier).request(ShellTab.settings);
        }
      case RedirectOrigin.app:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => _resuming
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : widget.child;
}
