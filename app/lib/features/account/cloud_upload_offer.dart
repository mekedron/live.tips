import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_migrator.dart';
import '../../domain/band_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/route_depth.dart';

/// Moves this device's local profiles into [uid]'s account, reporting each
/// profile as it lands, and returning the id of the band the profile should
/// open on (the locally-active migrated one) — or null when nothing moved.
/// Throws [CloudUploadException] when it cannot: the caller owes the artist a
/// sentence that is true, which means it has to know what went wrong.
/// The provider itself is null where there is no cloud to move them to (no
/// Firebase) — the offer then never comes up at all.
///
/// A provider so the gate's decisions (when to ask, when to record the
/// answer) can be tested without a live Firestore behind them.
typedef CloudUploadRunner = Future<String?> Function(
  String uid, {
  void Function(String bandName, int done, int total)? onProgress,
});

final cloudUploadRunnerProvider = Provider<CloudUploadRunner?>((ref) {
  final ambient = ref.watch(firestoreProvider);
  if (ambient == null) return null;
  final sessions = ref.watch(accountSessionsProvider);
  return (uid, {onProgress}) => CloudMigrator(
        local: ref.read(localStoreProvider),
        secure: ref.read(secureStoreProvider),
        // The TARGET account's OWN Firestore, not the ambient one. The ambient
        // handle is keyed on the ACTIVE profile, and a move can perfectly well
        // run while the local profile is still active — that is what a move is
        // — in which case the ambient instance is the default app, whose signed
        // -in uid is the relay's transport credential and not this account at
        // all. Every write into users/{uid}/… would then be denied by a rule
        // that is doing its job. main() resolves the resumed upload the same
        // way, for the same reason.
        db: sessions.sessionFor(uid)?.firestore ?? ambient,
      ).uploadLocalBands(uid, onProgress: onProgress);
});

/// Invisible wrapper that watches for a sign-in and offers to move this
/// device's local profiles (jars, settings, history, secrets) into it. Sits
/// at the app root because the sign-in sheets pop themselves before the
/// offer could run from their own contexts.
///
/// Three invariants, all learned the hard way:
///
/// * The offer waits until the navigator is back on the root screen. A
///   sign-in mid-onboarding pushes the next step in the same beat, and a
///   dialog raised then lands UNDER that opaque route — shown, never seen.
/// * The "offered" flag is written only once the user ANSWERED. Marking it up
///   front burned the single chance to ask, and the local profiles stayed
///   stranded on the device with no way to bring them over.
/// * The answer is remembered per PROFILE, not per account. "This uid was
///   asked, ever" welded the door shut from the other side: a local profile
///   created after the first answer was never mentioned again, and it too
///   stayed stranded. Declining still silences the profiles it was about —
///   nobody gets nagged on every profile switch — but a new profile is a
///   new question.
///
/// A crashed upload resumes from main() without asking again; and this
/// dialog is a convenience, not the only door — Settings carries a
/// permanent "move profiles into this account" row (see [runCloudUpload]).
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

  /// Whether [_pending] came from a genuine SIGN-IN rather than a switch to
  /// an account this device already knew. The controller publishes the user
  /// BEFORE the directory adopts it, so at listen time a fresh sign-in is
  /// the uid the directory doesn't have yet. Only a fresh sign-in owes the
  /// artist a word when there is nothing left to ask (see [_maybeOffer]) —
  /// a deliberate account switch is not a relocation to explain.
  bool _pendingIsFreshSignIn = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.user?.uid),
        (previous, uid) {
      if (uid != null && uid != previous) {
        _pending = uid;
        _pendingIsFreshSignIn =
            !ref.read(accountsDirectoryProvider).contains(uid);
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
    final freshSignIn = _pendingIsFreshSignIn;
    final upload = ref.read(cloudUploadRunnerProvider);
    final local = ref.read(localStoreProvider);
    if (upload == null) {
      _pending = null;
      return;
    }
    // Anything worth moving? A profile counts once it was named or holds any
    // data — pristine placeholder profiles travel as noise, not value.
    final registry = local.readAccountsRegistry();
    final worthMoving = [
      for (final band in registry?.accounts ?? const <BandAccount>[])
        if (band.name.trim().isNotEmpty || local.accountHasData(band.id))
          band,
    ];
    // …and anything left to ASK about? The flag means "this account
    // answered about THESE profiles", never "answered, ever" — a profile
    // created after the first answer is a new question.
    final answered = local.readCloudUploadOfferedBands(uid).toSet();
    final unanswered = [
      for (final band in worthMoving)
        if (!answered.contains(band.id)) band.id,
    ];
    if (unanswered.isEmpty) {
      _pending = null;
      // Nothing to ask — but a fresh sign-in still just relocated the
      // artist onto this account's bands. When local profiles remain
      // (asked before, declined), the switch owes them a word: silence
      // here reads as "my band is gone".
      if (freshSignIn && worthMoving.isNotEmpty && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(context.s.t('account.profile_upload.kept_local')),
        ));
      }
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
    await local.markCloudUploadOffered(uid, unanswered);
    // The signed-in user may have changed while the dialog sat open.
    if (accepted != true ||
        !mounted ||
        ref.read(authControllerProvider).user?.uid != uid) {
      _running = false;
      return;
    }
    try {
      await runCloudUpload(context, ref, uid);
    } finally {
      _running = false;
    }
  }
}

/// Runs the move itself: the progress dialog, the upload, the outcome
/// snackbar, and landing the artist on the profile they just moved in.
/// Shared by the sign-in offer above and the permanent Settings row ("Move
/// profiles into this account") — the one-shot dialog must never be the
/// only door to the migrator. The caller has already asked; this only does.
Future<void> runCloudUpload(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  final upload = ref.read(cloudUploadRunnerProvider);
  if (upload == null) return;
  final s = context.s;
  final progress = ValueNotifier<String>('');
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
  CloudUploadException? failure;
  String? migratedBandId;
  try {
    migratedBandId = await upload(uid, onProgress: (band, done, total) {
      progress.value = s.t('account.profile_upload.progress_profile', {
        'profile': band,
        'done': '$done',
        'total': '$total',
      });
    });
  } on CloudUploadException catch (e) {
    // Kept, not swallowed. The migrator has already logged it and — when the
    // failure is permanent — dropped the pending flag, so this is the last
    // time the artist hears about it until they ask again.
    failure = e;
  } catch (e, st) {
    // A runner that is not the migrator (a stub, a future provider): still a
    // failure, and still not something to say "it will resume" about.
    failure = CloudUploadException(e, st, transient: false);
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // the progress dialog
  // Three different things happened; the artist is told which. Only a
  // transient failure keeps the pending flag, so only it may promise a resume
  // — a permanent one says what broke and leaves the profiles where they are.
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    duration: Duration(seconds: failure == null ? 4 : 10),
    content: Text(switch (failure) {
      null => s.t('account.profile_upload.done'),
      final f when f.transient => s.t('account.profile_upload.failed_offline'),
      final f => s.t('account.profile_upload.failed', {'reason': f.message}),
    }),
  ));
  if (failure == null && migratedBandId != null) {
    await _activateMigrated(context, ref, uid, migratedBandId);
  }
}

/// Lands the artist on the profile they just moved in. The user's mental
/// model is "I moved MY band here" — without this, the uploaded bands
/// arrive through the snapshot listener, the current (unrelated,
/// pre-existing) cloud band stays valid, and the app dumps the artist on
/// it: reads as data loss. The uploaded band reaches the mirror through
/// that listener, so give it a moment to be switchable-to.
Future<void> _activateMigrated(
  BuildContext context,
  WidgetRef ref,
  String uid,
  String bandId,
) async {
  for (var i = 0; i < 40; i++) {
    if (!context.mounted) return;
    // The signed-in account may have changed while we waited — the band
    // is not this profile's to switch to any more.
    if (ref.read(authControllerProvider).user?.uid != uid) return;
    if (ref.read(appStateProvider).accounts.any((a) => a.id == bandId)) {
      await ref.read(appStateProvider.notifier).switchAccount(bandId);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
