import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../state/notifications_providers.dart';
import '../../state/root_world.dart';
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

  /// A tapped push opens `…/app/?open=notifications` — the boot URL is that
  /// tap's whole message, so land the artist on the feed. One shot, and only
  /// once a cloud session is actually up: at a cold start the slot restores
  /// after the first frame, hence the uid listener below retries.
  void _maybeOpenBootLink() {
    if (_bootLinkHandled || !mounted) return;
    final boot = ref.read(bootLinkUrlProvider);
    if (boot == null) return;
    if (Uri.tryParse(boot)?.queryParameters['open'] != 'notifications') {
      _bootLinkHandled = true; // not ours; stop checking
      return;
    }
    if (ref.read(authControllerProvider).user?.uid == null) return;
    _bootLinkHandled = true;
    Navigator.of(context).push(
      RootBoundRoute<void>(builder: (_) => const NotificationsScreen()),
    );
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
