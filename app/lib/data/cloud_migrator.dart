import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/band_account.dart';
import 'local_store.dart';
import 'secure_store.dart';

/// A move that could not finish — with the reason KEPT, and with the one fact
/// the artist actually needs: whether waiting can still make it come true.
///
/// The upload used to catch its exception and throw it away, so a failure that
/// could never succeed ("your writes are denied") and one that certainly would
/// ("you are offline") were told to the artist in the same reassuring sentence
/// — "it will resume on the next launch" — and neither we nor they could ever
/// see what threw. Every failure now carries [cause] (logged), and [transient]
/// decides both the sentence and whether the pending flag survives to try again.
class CloudUploadException implements Exception {
  CloudUploadException(this.cause, this.stackTrace, {required this.transient});

  final Object cause;
  final StackTrace stackTrace;

  /// True when a later attempt could plausibly win — the network dropped, the
  /// backend was unreachable. False for everything else: a rejected write, a
  /// value Firestore refuses, a bug of ours. Those repeat forever, and a
  /// promise to resume them is a lie told once per launch.
  final bool transient;

  /// One line, fit to show a human: the SDK's own sentence when it has one.
  String get message {
    final e = cause;
    if (e is FirebaseException) {
      final text = e.message;
      return text == null || text.isEmpty ? e.code : text;
    }
    return '$e';
  }

  @override
  String toString() =>
      'CloudUploadException(${transient ? 'transient' : 'permanent'}): $cause';
}

/// Only the reasons a later attempt could actually clear count as transient.
/// Everything unrecognised is PERMANENT on purpose: an unknown failure that
/// re-arms itself every launch is precisely the bug this file is fixing, and
/// the artist is better served by "this could not be moved" plus the reason
/// than by a resume that never comes.
bool _isTransient(Object e) {
  if (e is TimeoutException) return true;
  if (e is FirebaseException) {
    return const {
      'unavailable',
      'deadline-exceeded',
      'cancelled',
      'aborted',
      'internal',
      'resource-exhausted',
      'network-request-failed',
    }.contains(e.code);
  }
  return false;
}

/// One-shot, crash-safe upload of the LOCAL profile's bands into a
/// signed-in account — the cloud counterpart of the boot migration in
/// migrations.dart, built on the same two rules: a pending flag persisted
/// BEFORE any data moves, and a commit point after which cleanup is safe.
///
/// The run, in order:
///
/// 1. Persist `cloud_upload_pending_v1` ({uid, bandIds}) before the first
///    Firestore write, so a crash mid-upload is visible at the next boot
///    and resumes instead of stranding half the bands in the cloud.
/// 2. Per band, idempotently: set the band doc (name, jars, settings),
///    batch-set the history docs, merge the keychain secrets into
///    `secrets/v1`. Every doc id is the stable local id, so a resumed run
///    overwrites its own partial work rather than duplicating it — and it
///    skips bands whose local data is already gone (step 4 ran before the
///    crash): those are uploaded whole, and re-reading their wiped blobs
///    would push default settings over the cloud copy.
/// 3. Commit point: [FirebaseFirestore.waitForPendingWrites] — reached only
///    online, so the local wipe below can never outrun the upload.
/// 4. Wipe each local band, leave the local registry holding whatever did NOT
///    move (nothing, when everything did — an empty local profile is a legal,
///    routable state, and no placeholder band is minted to stand in for it),
///    clear the flag. Keychain entries stay put: they are now the cloud
///    profile's keychain cache under the same band ids.
///
/// A locked keychain skips step 2's secrets for the affected band and
/// nothing else. The secret is not lost — it stays in the keychain, which
/// doubles as the cloud profile's cache under the same band id — so this
/// device keeps working and the cloud copy appears whenever the key is
/// next written.
class CloudMigrator {
  CloudMigrator({
    required LocalStore local,
    required SecureStore secure,
    required FirebaseFirestore db,
  })  : _local = local,
        _secure = secure,
        _db = db;

  final LocalStore _local;
  final SecureStore _secure;
  final FirebaseFirestore _db;

  /// True when a crashed upload needs resuming (pending flag set).
  bool get hasPendingUpload => _local.readCloudUploadPending() != null;

  /// Uploads this device's local bands into [uid]'s Firestore subtree, or
  /// resumes a crashed upload. Safe to call when there is nothing to do.
  ///
  /// [selectedBandIds] scopes a FRESH run to a subset — the artist ticked some
  /// profiles and left the rest local. Null means every local band, which is
  /// what the permanent Settings door and the crash-resume path both pass. A
  /// band left out is not touched: it is not uploaded, not wiped, and stays in
  /// the local registry exactly as it was (see [_upload]'s `remaining`). A
  /// RESUME ignores this argument outright — the crashed run already wrote its
  /// chosen set into the pending flag, and that flag, not a new selection, is
  /// what a resume is allowed to move.
  ///
  /// Returns the id of the band that should be ACTIVE in the cloud profile —
  /// the band that was active locally when several moved, else the first
  /// moved one; null when nothing moved. The id is also persisted as the
  /// cloud profile's active band here (at the commit point), so even a
  /// crash-resumed upload lands the artist on the band they migrated: "I
  /// moved MY band here" must never open on some unrelated pre-existing
  /// profile — that reads as data loss.
  ///
  /// Throws [CloudUploadException] when it cannot: the reason is logged and
  /// carried out to the caller (which owes the artist a true sentence), and a
  /// PERMANENT failure clears the pending flag on its way out — see [_upload].
  Future<String?> uploadLocalBands(
    String uid, {
    Set<String>? selectedBandIds,
    void Function(String bandName, int done, int total)? onProgress,
  }) async {
    try {
      return await _upload(uid,
          selectedBandIds: selectedBandIds, onProgress: onProgress);
    } catch (e, st) {
      final transient = _isTransient(e);
      debugPrint(
          'cloud upload failed (${transient ? 'transient' : 'permanent'}): $e');
      if (!transient) {
        // Nothing a next boot can do about this one. Leaving the flag set
        // would re-arm the identical attempt on every launch — the same
        // failure, the same reassuring lie, forever. The local data is
        // untouched (the wipe lives past the commit point), so the profiles
        // are still there, and the Settings row can still try again once
        // whatever denied the write is fixed.
        await _local.clearCloudUploadPending();
      }
      throw CloudUploadException(e, st, transient: transient);
    }
  }

  Future<String?> _upload(
    String uid, {
    Set<String>? selectedBandIds,
    void Function(String bandName, int done, int total)? onProgress,
  }) async {
    var pending = _local.readCloudUploadPending();
    if (pending != null && pending.uid != uid) {
      // A stale flag from a different sign-in: that upload cannot be
      // resumed under this uid. Clear it and start fresh — whatever the old
      // run had already committed lives safely under the old uid.
      await _local.clearCloudUploadPending();
      pending = null;
    }

    final registry = _local.readAccountsRegistry();
    if (registry == null || registry.accounts.isEmpty) {
      // Nothing local to move — a fresh profile, or a resumed run that had
      // already wiped. Either way, done.
      await _local.clearCloudUploadPending();
      return null;
    }

    // A resumed run only re-uploads the bands the crashed run had claimed:
    // anything newer in the registry is not pre-sign-in data to move. A FRESH
    // run moves the bands the artist selected ([selectedBandIds]) — or every
    // band when the caller named none. The resume path wins over a selection:
    // once a flag exists, its list is the truth, and a new pick cannot widen
    // or narrow a move already half-committed.
    final claimed = pending?.bandIds.toSet();
    final bands = [
      for (final band in registry.accounts)
        if (claimed != null
            ? claimed.contains(band.id)
            : (selectedBandIds == null || selectedBandIds.contains(band.id)))
          band,
    ];
    if (bands.isEmpty) {
      await _local.clearCloudUploadPending();
      return null;
    }

    await _local.saveCloudUploadPending(uid, [for (final b in bands) b.id]);

    final total = bands.length;
    var done = 0;
    for (final band in bands) {
      onProgress?.call(band.name, done, total);
      await _uploadBand(uid, band);
      done++;
      onProgress?.call(band.name, done, total);
    }

    // Commit point — nothing below runs until the server has everything.
    await _awaitPendingWrites();

    // The just-migrated bands' new home should open ON one of them.
    final migratedActiveId = bands.any((b) => b.id == registry.activeId)
        ? registry.activeId
        : bands.first.id;
    await _local.saveActiveCloudBand(uid, migratedActiveId);

    for (final band in bands) {
      await _local.wipeAccount(band.id);
    }
    final uploadedIds = {for (final b in bands) b.id};
    final remaining = [
      for (final band in registry.accounts)
        if (!uploadedIds.contains(band.id)) band,
    ];
    // Every local band moved: the local registry is left EMPTY. It used to be
    // left with one fresh unnamed band — a deliberate placeholder, so that
    // switching back to the local profile landed on a ready band rather than
    // on a picker, "because a move is not a removal". Its own comment carried
    // the refutation: *with an empty registry routable now*. It is. An empty
    // local profile lands on the create step, with the switcher and Settings on
    // it (#38/#40) — the local profile is switchable-to whether or not it holds
    // a band. What the placeholder actually did was hand the artist a profile
    // they never made: unnamed, dataless, and indistinguishable from the one
    // main() used to mint at boot (#50). It is gone, and nothing takes its
    // place: a band is born from a name (#44).
    await _local.saveAccountsRegistry(AccountsRegistry(
      accounts: remaining,
      activeId: remaining.any((b) => b.id == registry.activeId)
          ? registry.activeId
          : (remaining.isEmpty ? '' : remaining.first.id),
    ));
    await _local.clearCloudUploadPending();
    return migratedActiveId;
  }

  Future<void> _uploadBand(String uid, BandAccount band) async {
    final bandDoc =
        _db.collection('users').doc(uid).collection('bands').doc(band.id);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Every local blob is null-guarded, settings included: a resumed run can
    // reach here AFTER the crashed run's local wipe, when readBandSettings
    // would answer defaults — and writing those would overwrite the real
    // settings the crashed run had already committed to the cloud. An absent
    // blob is always right to skip: absent means "already uploaded and wiped"
    // or "never configured", and the merge below leaves the cloud doc as it
    // should be either way. (Skipping the whole band instead was wrong: "no
    // local data" cannot tell a wiped band from a named-but-never-configured
    // one, whose name still has to move.)
    final tipJar = _local.readTipJar(band.id);
    final relayJar = _local.readRelayJar(band.id);
    final bandSettings = _local.readBandSettingsOrNull(band.id);
    await bandDoc.set({
      'name': band.name,
      'createdAtMs': band.createdAtMs,
      if (tipJar != null) 'tipJar': tipJar.toJson(),
      if (relayJar != null) 'relayJar': relayJar.toJson(),
      if (bandSettings != null) 'bandSettings': bandSettings.toJson(),
      'updatedAtMs': now,
    }, SetOptions(merge: true));

    await _commitChunked(_db, [
      for (final session in _local.readSessionHistory(band.id))
        (batch) => batch.set(bandDoc.collection('sessions').doc(session.id),
            {...session.toJson(), 'updatedAtMs': now}),
      for (final tip in _local.readRelayHistory(band.id))
        (batch) => batch.set(bandDoc.collection('relayTips').doc(tip.id),
            {...tip.toJson(), 'updatedAtMs': now}),
    ]);

    try {
      final stripeKey = await _secure.readApiKey(band.id);
      final relaySecret = await _secure.readRelaySecret(band.id);
      if (stripeKey != null || relaySecret != null) {
        await bandDoc.collection('secrets').doc('v1').set({
          'stripeKey': ?stripeKey,
          'relaySecret': ?relaySecret,
          'updatedAtMs': now,
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Locked keychain: skip this band's secrets, never the migration.
      // The secret stays local-only in the keychain — which doubles as the
      // cloud profile's cache under the same band id — so nothing breaks
      // on this device, and the user can re-enter it to sync elsewhere.
    }
  }

  Future<void> _awaitPendingWrites() async {
    try {
      await _db.waitForPendingWrites();
    } on UnimplementedError {
      // A platform stub without it has no offline queue to drain.
    } on NoSuchMethodError {
      // fake_cloud_firestore: writes commit synchronously, nothing pends.
    }
  }
}

/// Firestore caps a batch at 500 writes; stay under it with headroom.
const _batchLimit = 400;

Future<void> _commitChunked(
    FirebaseFirestore db, List<void Function(WriteBatch)> ops) async {
  for (var i = 0; i < ops.length; i += _batchLimit) {
    final end = i + _batchLimit > ops.length ? ops.length : i + _batchLimit;
    final batch = db.batch();
    for (final op in ops.sublist(i, end)) {
      op(batch);
    }
    await batch.commit();
  }
}
