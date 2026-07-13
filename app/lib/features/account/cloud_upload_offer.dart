import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_migrator.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/route_depth.dart';

/// Moves this device's local profiles into [uid]'s account, reporting each
/// profile as it lands. Null where there is no cloud to move them to (no
/// Firebase) — the offer then never comes up at all.
///
/// A provider so the gate's decisions (when to ask, when to record the
/// answer) can be tested without a live Firestore behind them.
typedef CloudUploadRunner = Future<void> Function(
  String uid, {
  void Function(String bandName, int done, int total)? onProgress,
});

final cloudUploadRunnerProvider = Provider<CloudUploadRunner?>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db == null) return null;
  return (uid, {onProgress}) => CloudMigrator(
        local: ref.read(localStoreProvider),
        secure: ref.read(secureStoreProvider),
        db: db,
      ).uploadLocalBands(uid, onProgress: onProgress);
});

/// Invisible wrapper that watches for a sign-in and offers — once per
/// account — to move this device's local profiles (jars, settings, history,
/// secrets) into it. Sits at the app root because the sign-in sheets pop
/// themselves before the offer could run from their own contexts.
///
/// Two invariants, both learned the hard way:
///
/// * The offer waits until the navigator is back on the root screen. A
///   sign-in mid-onboarding pushes the next step in the same beat, and a
///   dialog raised then lands UNDER that opaque route — shown, never seen.
/// * The "offered" flag is written only once the user ANSWERED. Marking it up
///   front burned the single chance to ask, and the local profiles stayed
///   stranded on the device with no way to bring them over.
///
/// A crashed upload resumes from main() without asking again; declining is
/// remembered per uid, so nobody gets nagged on every profile switch.
class CloudUploadOfferGate extends ConsumerStatefulWidget {
  const CloudUploadOfferGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudUploadOfferGate> createState() =>
      _CloudUploadOfferGateState();
}

class _CloudUploadOfferGateState extends ConsumerState<CloudUploadOfferGate> {
  bool _running = false;

  /// The account that signed in and hasn't answered yet — held until the user
  /// is back on the root screen, where the question can actually be seen.
  String? _pending;

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.user?.uid),
        (previous, uid) {
      if (uid != null && uid != previous) {
        _pending = uid;
        _offerWhenVisible();
      }
    });
    ref.listen(routeDepthProvider, (previous, depth) {
      if (depth == 0) _offerWhenVisible();
    });
    return widget.child;
  }

  void _offerWhenVisible() {
    if (_pending == null || _running) return;
    if (ref.read(routeDepthProvider) != 0) return; // something is on top
    // Next frame, not this instant: the depth reaches zero in the MIDDLE of
    // the pop that got us there (onboarding ends with popUntil), and a dialog
    // pushed then is simply popped along with everything else. Let the
    // navigator finish, then ask.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = _pending;
      if (uid == null || _running) return;
      if (ref.read(routeDepthProvider) != 0) return;
      unawaited(_maybeOffer(uid));
    });
  }

  Future<void> _maybeOffer(String uid) async {
    if (_running) return;
    final upload = ref.read(cloudUploadRunnerProvider);
    final local = ref.read(localStoreProvider);
    if (upload == null || local.readCloudUploadOffered(uid)) {
      _pending = null;
      return;
    }
    // Anything worth moving? A profile counts once it was named or holds any
    // data — pristine placeholder profiles travel as noise, not value.
    final registry = local.readAccountsRegistry();
    final hasData = registry != null &&
        registry.accounts.any(
            (a) => a.name.trim().isNotEmpty || local.accountHasData(a.id));
    if (!hasData) {
      _pending = null;
      return;
    }
    if (!mounted) return;

    // Held across the awaits: another route settling must not stack a second
    // dialog on top of the offer already asking.
    _running = true;
    final s = context.s;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('account.profile_upload.title')),
        content: Text(s.t('account.profile_upload.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('account.profile_upload.decline')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('account.profile_upload.accept')),
          ),
        ],
      ),
    );
    // Dismissed without an answer (barrier tap, back button): the question
    // stands, so nothing is recorded and the next chance asks it again.
    if (accepted == null) {
      _running = false;
      return;
    }
    _pending = null;
    await local.markCloudUploadOffered(uid);
    // The signed-in user may have changed while the dialog sat open.
    if (accepted != true ||
        !mounted ||
        ref.read(authControllerProvider).user?.uid != uid) {
      _running = false;
      return;
    }

    final progress = ValueNotifier<String>('');
    if (mounted) {
      // Fire-and-forget: the upload below pops it when done.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: progress,
                    builder: (context, value, child) => Text(value.isEmpty
                        ? s.t('account.profile_upload.progress')
                        : value),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    var failed = false;
    try {
      await upload(uid, onProgress: (band, done, total) {
        progress.value = s.t('account.profile_upload.progress_profile', {
          'profile': band,
          'done': '$done',
          'total': '$total',
        });
      });
    } catch (_) {
      // The pending flag survives — the next boot resumes the upload.
      failed = true;
    } finally {
      _running = false;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // the progress dialog
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(s.t(failed
          ? 'account.profile_upload.failed'
          : 'account.profile_upload.done')),
    ));
  }
}
