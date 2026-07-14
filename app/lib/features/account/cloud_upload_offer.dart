import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/cloud_migrator.dart';
import '../../data/repository/account_data_repository.dart';
import '../../domain/band_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/route_depth.dart';
import '../../widgets/profile_switcher.dart';

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
  Set<String>? selectedBandIds,
  void Function(String bandName, int done, int total)? onProgress,
});

final cloudUploadRunnerProvider = Provider<CloudUploadRunner?>((ref) {
  final ambient = ref.watch(firestoreProvider);
  if (ambient == null) return null;
  final sessions = ref.watch(accountSessionsProvider);
  return (uid, {selectedBandIds, onProgress}) => CloudMigrator(
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
      ).uploadLocalBands(uid,
          selectedBandIds: selectedBandIds, onProgress: onProgress);
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
    // created after the first answer is a new question. A profile already
    // answered (declined before) is silenced, not re-offered: the way to move
    // it after a "not now" is the permanent Settings door.
    final answered = local.readCloudUploadOfferedBands(uid).toSet();
    final unanswered = [
      for (final band in worthMoving)
        if (!answered.contains(band.id)) band,
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
    // The rows' methods summaries read the LOCAL band each is about — the
    // ambient repository may already be the cloud mirror this sign-in brought
    // up, which knows nothing of these bands and would print "not set up" for
    // every one of them.
    final localRepo =
        LocalStoreRepository(local, () => ref.read(secureStoreProvider));
    final selected = await showMoveProfilesDialog(
      context,
      ref,
      unanswered,
      dataSource: localRepo,
    );
    // Dismissed without an answer (barrier tap, back button): the question
    // stands, so nothing is recorded and the next chance asks it again. A
    // decline is an empty list — answered, moving nothing.
    if (selected == null) {
      _running = false;
      return;
    }
    _pending = null;
    await local
        .markCloudUploadOffered(uid, [for (final b in unanswered) b.id]);
    // A decline moves nothing; and the signed-in user may have changed while
    // the dialog sat open.
    if (selected.isEmpty ||
        !mounted ||
        ref.read(authControllerProvider).user?.uid != uid) {
      _running = false;
      return;
    }
    try {
      await runCloudUpload(context, ref, uid,
          selectedBandIds: selected.toSet());
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
  String uid, {
  Set<String>? selectedBandIds,
}) async {
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
    migratedBandId = await upload(uid, selectedBandIds: selectedBandIds,
        onProgress: (band, done, total) {
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

/// The move-in question, with a checkbox per profile when there is a choice to
/// make. Returns the ids to move — every profile ticked by default, so "move
/// everything" is still one confirm and the old all-or-nothing outcome is the
/// zero-effort one. An empty list is a decline ("Not now"): answered, moving
/// nothing. Null is a dismissal (barrier tap, Back): no answer, the question
/// stands. Those are the three outcomes the gate tells apart — a decline is
/// remembered per profile, a dismissal is not.
///
/// A single eligible profile gets no checkbox: there is nothing to choose
/// between, so it stays the plain confirm the offer has always been, and its
/// "Move profiles" button reads exactly as before.
///
/// [dataSource] overrides where each row's methods summary is read from — the
/// caller passes the local store's repository so a local band's payment
/// methods still render while a freshly signed-in cloud account is the active
/// profile (its mirror knows nothing of these bands).
Future<List<String>?> showMoveProfilesDialog(
  BuildContext context,
  WidgetRef ref,
  List<BandAccount> profiles, {
  AccountDataRepository? dataSource,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) =>
        _MoveProfilesDialog(profiles: profiles, dataSource: dataSource),
  );
}

class _MoveProfilesDialog extends StatefulWidget {
  const _MoveProfilesDialog({required this.profiles, this.dataSource});

  final List<BandAccount> profiles;
  final AccountDataRepository? dataSource;

  @override
  State<_MoveProfilesDialog> createState() => _MoveProfilesDialogState();
}

class _MoveProfilesDialogState extends State<_MoveProfilesDialog> {
  // All ticked by default — the artist who wants the old "move everything"
  // outcome does nothing but confirm.
  late final Set<String> _selected = {for (final b in widget.profiles) b.id};

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.lt;
    final single = widget.profiles.length == 1;
    final count = _selected.length;
    // Honest about the selection: one profile reads "profile", several read
    // "N profiles", and none disables the button (below) rather than lie.
    final moveLabel = count <= 1
        ? s.t('account.profile_upload.move_one')
        : s.t('account.profile_upload.move_selected', {'count': '$count'});
    return AlertDialog(
      scrollable: true,
      title: Text(s.t('account.profile_upload.title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.t('account.profile_upload.body'),
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          if (!single) ...[
            const SizedBox(height: 12),
            Text(
              s.t('account.profile_upload.pick_hint'),
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12.5,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            for (final band in widget.profiles)
              ProfileRow(
                band: band,
                enabled: true,
                dataSource: widget.dataSource,
                onTap: () => _toggle(band.id),
                trailing: Checkbox(
                  value: _selected.contains(band.id),
                  onChanged: (_) => _toggle(band.id),
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          // A decline: answered, moving nothing.
          onPressed: () => Navigator.of(context).pop(<String>[]),
          child: Text(s.t('account.profile_upload.decline')),
        ),
        FilledButton(
          // Nothing ticked has nothing to move — the button says so by being
          // dead rather than moving zero profiles and calling it a success.
          onPressed: count == 0
              ? null
              : () => Navigator.of(context).pop(
                    single
                        ? [widget.profiles.single.id]
                        : _selected.toList(),
                  ),
          child: Text(single ? s.t('account.profile_upload.accept') : moveLabel),
        ),
      ],
    );
  }
}
