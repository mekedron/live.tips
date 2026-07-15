import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_account.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../state/notifications_providers.dart';
import '../../state/providers.dart';
import '../../state/root_world.dart';
import '../../state/venue_providers.dart';
import '../../widgets/profile_switcher.dart';
import 'notifications_screen.dart';

/// Invisible root widget that keeps this device's push registration honest —
/// [DeviceSessionGuard]'s little sibling, for the fcmToken field instead of
/// the device doc itself.
///
/// It never turns push ON (that is the settings toggle's job, inside the
/// user's tap); it only re-asserts what an account already chose here — the
/// doc's `pushEnabled` intent, which survives the token itself being pruned
/// as dead by the send trigger, so a lost registration is quietly re-minted
/// instead of the toggle drifting off:
///  - launch, sign-in and account switches re-run [PushRegistration.maintain]
///    so a rotated/lost/pruned token or a changed language is re-written
///    (switches especially: that is when the functions SDK used to murder
///    the token — see data/firebase/callables.dart);
///  - FCM's own onTokenRefresh does the same the moment it fires;
///  - a resume re-checks the OS permission (the user may have flipped it in
///    browser/OS settings while we were backgrounded) by invalidating
///    [pushStatusProvider], and heals the token if it survived.
class PushTokenGuard extends ConsumerStatefulWidget {
  const PushTokenGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushTokenGuard> createState() => _PushTokenGuardState();
}

class _PushTokenGuardState extends ConsumerState<PushTokenGuard>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _refresh;
  bool _bootLinkHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maintain();
      _maybeOpenBootLink();
    });
    _refresh = ref
        .read(pushServiceProvider)
        .onTokenRefresh
        .listen((_) => _maintain());
  }

  /// A tapped push opens `…/app/?open=notifications&account=…&band=…` — the
  /// boot URL is that tap's whole message: land on the feed, and land on the
  /// RIGHT feed. The notification belongs to one account and one band
  /// (functions/src/notifications.ts writes both onto the link), and a phone
  /// holding three accounts must not show account A's banner over the tip
  /// account B just received.
  ///
  /// One shot. A link that names an account this device can seat needs no
  /// signed-in ACTIVE session to proceed — the directory is on disk, and the
  /// flip is what brings that account's own session up; everything else
  /// still waits for a uid (at a cold start the slot restores after the
  /// first frame, hence the listener in [build] retries).
  void _maybeOpenBootLink() {
    if (_bootLinkHandled || !mounted) return;
    final boot = ref.read(bootLinkUrlProvider);
    if (boot == null) return;
    final uri = Uri.tryParse(boot);
    if (uri?.queryParameters['open'] != 'notifications') {
      _bootLinkHandled = true; // not ours; stop checking
      return;
    }
    final target = _bootTarget(uri!);
    if (target == null &&
        ref.read(authControllerProvider).user?.uid == null) {
      return;
    }
    _bootLinkHandled = true;
    unawaited(_openNotifications(target));
  }

  /// The account (and band) the tapped notification belongs to, IF this
  /// device can seat it: a cloud account the directory knows. Anything else
  /// answers null and the feed opens over whatever profile is showing — an
  /// account never signed in here (or signed out since), a payload from
  /// before the parameters existed, and a VENUE tablet, which auto-activates
  /// nothing, ever: whose gig a shared screen shows is asked, not deep-linked.
  ({String uid, String? band})? _bootTarget(Uri uri) {
    final uid = uri.queryParameters['account'];
    if (uid == null || uid.isEmpty || uid == kLocalAccountId) return null;
    if (ref.read(deviceKindProvider) == DeviceKind.venue) return null;
    if (!ref.read(accountsDirectoryProvider).contains(uid)) return null;
    final band = uri.queryParameters['band'];
    return (uid: uid, band: (band == null || band.isEmpty) ? null : band);
  }

  /// Seats the notification's context, then opens the feed page on it.
  Future<void> _openNotifications(({String uid, String? band})? target) async {
    var moved = false;
    if (target == null) {
      // Nothing to seat — but the page must still stand on a SETTLED world:
      // a cold boot's root flips when the mirror first speaks, and a route
      // pushed before that flip dies with the world it described.
      await _settled(ref.read(accountsDirectoryProvider).activeAccountId);
    } else {
      moved = await _activate(target);
    }
    if (!mounted) return;
    Navigator.of(context).push(
      RootBoundRoute<void>(builder: (_) => const NotificationsScreen()),
    );
    if (moved) _announceContext();
  }

  /// Makes the target account+band the active profile. The band memory is
  /// written FIRST, exactly like the switcher's `_enterAccount`: the reload
  /// the directory flip schedules reads it back and lands on the tapped
  /// notification's band — including the cold-boot case, where the mirror
  /// speaks long after this method returned and the seated memory is what
  /// that late reload finds. Returns whether the artist actually landed
  /// somewhere new — the caption's cue, so it must be the LANDING, never the
  /// attempt.
  Future<bool> _activate(({String uid, String? band}) target) async {
    final band = target.band;
    if (band != null) {
      await ref.read(localStoreProvider).saveActiveCloudBand(target.uid, band);
    }
    var moved = false;
    if (ref.read(accountsDirectoryProvider).activeAccountId != target.uid) {
      await ref
          .read(accountsDirectoryProvider.notifier)
          .setActive(target.uid);
      moved = true;
    } else if (band != null &&
        ref.read(appStateProvider).accountId != band) {
      final app = ref.read(appStateProvider);
      if (app.accounts.any((a) => a.id == band)) {
        // Same account, other band, and the band is on the shelf: the
        // ordinary switch. A refusal (a live set on this device) opens the
        // feed where the artist stands.
        moved = await ref.read(appStateProvider.notifier).switchAccount(band);
      } else {
        // The mirror has not listed the band yet — a cold boot straight off
        // the notification tap. The seated memory IS the switch here: the
        // warm reload reads it back, and the wait below spans that landing.
        moved = true;
      }
    }
    if (!moved) return false;
    await _settled(target.uid);
    // The landing, checked: a band that never arrived (deleted since the
    // push) lands on the picker, and a caption naming it would be a lie.
    return band == null || ref.read(appStateProvider).accountId == band;
  }

  /// Waits for the flip's reload to land before the page is pushed over it:
  /// a [RootBoundRoute] describes the world it was pushed over, and one
  /// pushed mid-flip dies with the world it never meant to describe. On a
  /// cold boot the wait spans the mirror's first snapshot (`isWarm`), whose
  /// own reload is what opens the seated band. Bounded — a keychain that
  /// hangs must not hold the notification page hostage.
  Future<void> _settled(String uid) async {
    // One beat, so the directory listener's microtask reload has BEGUN and
    // its switching flag is up before the loop first reads it.
    await Future<void>.delayed(Duration.zero);
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (mounted && DateTime.now().isBefore(deadline)) {
      final app = ref.read(appStateProvider);
      if (ref.read(accountsDirectoryProvider).activeAccountId == uid &&
          !app.switching &&
          (app.accountId.isNotEmpty ||
              ref.read(accountDataRepositoryProvider).isWarm)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Says which interface the artist is now looking at — only when the tap
  /// MOVED them there: a feed opened over the profile they were already on
  /// needs no caption, and a landing whose band question is still open shows
  /// the picker, which names the account on the screen itself (#51).
  void _announceContext() {
    final app = ref.read(appStateProvider);
    if (app.accountId.isEmpty) return;
    final account = ref.read(accountsDirectoryProvider).active;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(context.s.t('notifications.switched_profile', {
        'profile': app.displayName,
        'account': accountDisplayName(context, account),
      })),
    ));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(pushStatusProvider);
    _maintain();
  }

  void _maintain() {
    if (!mounted) return;
    unawaited(ref.read(pushRegistrationProvider).maintain());
  }

  @override
  Widget build(BuildContext context) {
    // The uid flip covers sign-in AND account switches; the service rebuild
    // covers "Firebase finished booting after us" (a restored slot session
    // resolves the messaging instance where there was none).
    ref.listen(authControllerProvider.select((s) => s.user?.uid),
        (previous, uid) {
      if (uid != null) {
        _maintain();
        _maybeOpenBootLink();
      }
    });
    ref.listen(pushServiceProvider, (previous, next) {
      _refresh?.cancel();
      _refresh = next.onTokenRefresh.listen((_) => _maintain());
      _maintain();
    });
    return widget.child;
  }
}
