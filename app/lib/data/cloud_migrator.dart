import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/band_account.dart';
import 'local_store.dart';
import 'secure_store.dart';

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
///    overwrites its own partial work rather than duplicating it.
/// 3. Commit point: [FirebaseFirestore.waitForPendingWrites] — reached only
///    online, so the local wipe below can never outrun the upload.
/// 4. Wipe each local band, reset the local registry to one fresh empty
///    band (the same last-band-removed shape the notifier keeps), clear the
///    flag. Keychain entries stay put: they are now the cloud profile's
///    keychain cache under the same band ids.
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

  /// Uploads every local band into [uid]'s Firestore subtree, or resumes a
  /// crashed upload. Safe to call when there is nothing to do.
  ///
  /// Returns the id of the band that should be ACTIVE in the cloud profile —
  /// the band that was active locally when several moved, else the first
  /// moved one; null when nothing moved. The id is also persisted as the
  /// cloud profile's active band here (at the commit point), so even a
  /// crash-resumed upload lands the artist on the band they migrated: "I
  /// moved MY band here" must never open on some unrelated pre-existing
  /// profile — that reads as data loss.
  Future<String?> uploadLocalBands(
    String uid, {
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
    // anything newer in the registry (the fresh empty band a nearly-finished
    // run already created) is not pre-sign-in data to move.
    final claimed = pending?.bandIds.toSet();
    final bands = [
      for (final band in registry.accounts)
        if (claimed == null || claimed.contains(band.id)) band,
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
    if (remaining.isEmpty) {
      // The local profile never has zero bands — it gets one fresh empty
      // band, mirroring removeAccount's last-band behavior.
      final fresh = BandAccount(
        id: BandAccount.newId(),
        name: '',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _local.saveAccountsRegistry(
          AccountsRegistry(accounts: [fresh], activeId: fresh.id));
    } else {
      await _local.saveAccountsRegistry(AccountsRegistry(
        accounts: remaining,
        activeId: remaining.any((b) => b.id == registry.activeId)
            ? registry.activeId
            : remaining.first.id,
      ));
    }
    await _local.clearCloudUploadPending();
    return migratedActiveId;
  }

  Future<void> _uploadBand(String uid, BandAccount band) async {
    final bandDoc =
        _db.collection('users').doc(uid).collection('bands').doc(band.id);
    final now = DateTime.now().millisecondsSinceEpoch;

    final tipJar = _local.readTipJar(band.id);
    final relayJar = _local.readRelayJar(band.id);
    await bandDoc.set({
      'name': band.name,
      'createdAtMs': band.createdAtMs,
      if (tipJar != null) 'tipJar': tipJar.toJson(),
      if (relayJar != null) 'relayJar': relayJar.toJson(),
      'bandSettings': _local.readBandSettings(band.id).toJson(),
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
