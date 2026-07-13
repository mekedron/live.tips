import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/app_settings.dart';
import '../../domain/band_account.dart';
import '../../domain/band_settings.dart';
import '../../domain/live_session.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip.dart';
import '../../domain/tip_jar.dart';
import '../local_store.dart';
import '../secure_store.dart';
import 'account_data_repository.dart';

/// A signed-in account's bands, served from `users/{uid}/**` in Firestore
/// under the same contract as [LocalStoreRepository].
///
/// The contract's synchronous reads are the crux: cloud_firestore has none,
/// so every non-secret read is served from in-memory mirrors fed by snapshot
/// listeners. Offline persistence (on by default) makes the first snapshot
/// after a restart arrive from cache immediately, so the mirrors are warm by
/// the time anything meaningful reads them. Three mirror rules keep the
/// contract honest:
///
/// * Writes update the mirror BEFORE the network ack — a sync read-back
///   right after a write must see the new value, exactly like prefs. The
///   listener echo (which on a real client includes latency-compensated
///   local writes) then confirms it.
/// * [onChanged] fires on every snapshot that updated a mirror — the wiring
///   layer's cue to re-read, which is how another device's edits reach the
///   UI.
/// * A cache snapshot proves what EXISTS, never what doesn't: an offline
///   boot with a cold cache (or a disabled one — venue mode turns
///   persistence off) raises an EMPTY from-cache snapshot first, and
///   believing it once seeded a junk band over an artist's real ones.
///   Emptiness is only ever the server's word — [isWarm] and
///   [accountHasData] both wait for it.
///
/// Secrets stay keychain-first: the keychain is the fast path and the only
/// store trusted while offline-and-signed-out, and the `secrets/v1` doc is
/// the sync channel behind it. A remote secrets snapshot is written through
/// to the keychain under the SAME key names the local profile uses, so the
/// keychain doubles as the cloud profile's cache and everything downstream
/// of [SecureStore] keeps working unchanged. Deletions travel too: a
/// disconnect stamps a tombstone next to the deleted field, and a snapshot
/// carrying one clears the keychain entry — a revocation must revoke on
/// every device, not just the one that tapped the button.
///
/// The active-session crash snapshot and the relay-link-replaced notice
/// delegate to [LocalStore] verbatim: both are device-local by contract —
/// two devices' in-flight sessions must never overwrite each other.
class FirestoreRepository implements AccountDataRepository {
  FirestoreRepository({
    required this.uid,
    required FirebaseFirestore db,
    required LocalStore local,
    required SecureStore Function() resolveSecure,
    this.onChanged,
  })  : _db = db,
        _local = local,
        _resolveSecure = resolveSecure {
    _bandsSub = _bandsCol.snapshots().listen(_onBandsSnapshot, onError: _ignore);
    _settingsSub =
        _settingsDoc.snapshots().listen(_onSettingsSnapshot, onError: _ignore);
  }

  final String uid;
  final FirebaseFirestore _db;
  final LocalStore _local;
  final SecureStore Function() _resolveSecure;

  /// Fired after every remote snapshot that changed a mirror.
  final void Function()? onChanged;

  // Keychain resolved lazily, like the local profile: consumers that never
  // touch a secret must work without a keychain wired up at all.
  SecureStore? _secureCache;
  SecureStore get _secure => _secureCache ??= _resolveSecure();

  // --- Mirrors. Presence of a subscription (not of a mirror entry) marks a
  // --- lazy listener as started; a wipe can drop the mirror entry while the
  // --- listener stays alive to deliver the post-delete emptiness.
  final Map<String, _BandMirror> _bands = {};
  final Map<String, _SecretsMirror> _secrets = {};
  final Map<String, List<LiveSession>> _sessions = {};
  final Map<String, List<Tip>> _relayTips = {};
  AppSettings? _settings;

  /// Flipped by the first bands snapshot that can be BELIEVED: any server
  /// snapshot, or a cache snapshot that actually carries bands. The empty
  /// from-cache snapshot an offline boot raises first flips nothing — until
  /// the server speaks, the empty mirror means "I don't know yet", and every
  /// caller that would otherwise read it as "this account has no bands"
  /// must hold off.
  ///
  /// One-way, and it means exactly one thing: the server has spoken. It used
  /// to be flipped BACK by the device-local band removal, which left the mirror
  /// deliberately out of step with the account — the operation is gone, and so
  /// is the caveat (#37).
  bool _warm = false;

  // "Has heard from the server", per mirror: the bands flag plus one entry
  // per band whose sessions/relayTips listener delivered a server snapshot.
  // A cache snapshot proves presence, never absence, so [accountHasData]
  // refuses to confirm "empty" before the relevant flags are set.
  bool _bandsSettled = false;
  final Set<String> _sessionsSettled = {};
  final Set<String> _relayTipsSettled = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bandsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _secretSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _sessionSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _relayTipSubs = {};

  /// Cancels every listener. The repository must not be used afterwards.
  Future<void> dispose() async {
    final subs = [
      _bandsSub,
      _settingsSub,
      ..._secretSubs.values,
      ..._sessionSubs.values,
      ..._relayTipSubs.values,
    ];
    _bandsSub = null;
    _settingsSub = null;
    _secretSubs.clear();
    _sessionSubs.clear();
    _relayTipSubs.clear();
    for (final sub in subs) {
      await sub?.cancel();
    }
  }

  // --- Firestore refs ---

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _bandsCol =>
      _userDoc.collection('bands');
  DocumentReference<Map<String, dynamic>> _bandDoc(String id) =>
      _bandsCol.doc(id);
  DocumentReference<Map<String, dynamic>> _secretsDoc(String id) =>
      _bandDoc(id).collection('secrets').doc('v1');
  CollectionReference<Map<String, dynamic>> _sessionsCol(String id) =>
      _bandDoc(id).collection('sessions');
  CollectionReference<Map<String, dynamic>> _relayTipsCol(String id) =>
      _bandDoc(id).collection('relayTips');
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _userDoc.collection('settings').doc('app');

  static int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  void _notify() => onChanged?.call();

  // A listener error (revoked rules after sign-out, network teardown) must
  // never take the app down; the mirrors simply stop updating.
  static void _ignore(Object _) {}

  // --- Snapshot handlers ---

  void _onBandsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) =>
      applyBandsSnapshot(
        {for (final doc in snap.docs) doc.id: doc.data()},
        fromCache: snap.metadata.isFromCache,
      );

  /// The bands listener's body, split from the [QuerySnapshot] so tests can
  /// feed it the one snapshot fake_cloud_firestore can never raise: the
  /// EMPTY from-cache snapshot an offline boot starts with.
  @visibleForTesting
  void applyBandsSnapshot(
    Map<String, Map<String, dynamic>> docs, {
    required bool fromCache,
  }) {
    final next = <String, _BandMirror>{};
    for (final entry in docs.entries) {
      final band = _decodeBand(entry.key, entry.value);
      if (band == null) continue; // a malformed doc costs itself, not the boot
      next[entry.key] = band;
      // Secrets listeners are eager per band: the keychain write-through has
      // to happen before anyone asks for the key, not after.
      _ensureSecretsListener(entry.key);
    }
    _bands
      ..clear()
      ..addAll(next);
    // A server snapshot is always an answer; a cache snapshot only vouches
    // for the bands it carries. The empty from-cache snapshot of an offline
    // boot is SILENCE — warming on it read as "this account has no bands",
    // and a junk band got minted over the real ones and synced everywhere.
    if (!fromCache) {
      _warm = true;
      _bandsSettled = true;
    } else if (next.isNotEmpty) {
      _warm = true;
    }
    _notify();
  }

  void _onSettingsSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      _settings = null; // no cloud settings yet — reads fall back to local
    } else {
      try {
        _settings = AppSettings.fromJson(data);
      } catch (_) {
        // Keep the last good value over a malformed doc.
      }
    }
    _notify();
  }

  // No band is active yet (a cold mirror has none to offer): every read is
  // asked for the empty id, and Firestore refuses an empty document path.
  // Answer such reads from the — necessarily empty — mirror instead.
  static bool _noBand(String bandId) => bandId.isEmpty;

  void _ensureSecretsListener(String bandId) {
    if (_noBand(bandId) || _secretSubs.containsKey(bandId)) return;
    _secretSubs[bandId] = _secretsDoc(bandId).snapshots().listen((snap) {
      final data = snap.data() ?? const <String, dynamic>{};
      final stripeKey = data['stripeKey'];
      final relaySecret = data['relaySecret'];
      final mirror = _secrets.putIfAbsent(bandId, _SecretsMirror.new);
      final nextKey = stripeKey is String ? stripeKey : null;
      final nextSecret = relaySecret is String ? relaySecret : null;
      // A tombstone (stamped by the delete path, cleared by the write path)
      // is what tells "disconnected on another device" apart from "never
      // uploaded". A present value always outranks it: write and delete
      // touch both fields in one doc write, so a snapshot carrying both is
      // a pair mid-replacement — trust the key.
      final keyTombstoned =
          nextKey == null && data['stripeKeyDeletedAtMs'] is num;
      final secretTombstoned =
          nextSecret == null && data['relaySecretDeletedAtMs'] is num;
      final keyChanged = mirror.stripeKey != nextKey;
      final secretChanged = mirror.relaySecret != nextSecret;
      // Edge-triggered: a fresh mirror starts untombstoned, so a device that
      // slept through the disconnect still revokes on its first snapshot,
      // while later echoes of the same tombstone don't re-delete.
      final keyRevoked = keyTombstoned && !mirror.stripeKeyTombstoned;
      final secretRevoked = secretTombstoned && !mirror.relaySecretTombstoned;
      mirror
        ..stripeKey = nextKey
        ..stripeKeyTombstoned = keyTombstoned
        ..relaySecret = nextSecret
        ..relaySecretTombstoned = secretTombstoned;
      // Write-through to the keychain so what another device configured is
      // there before anyone asks. Additions and tombstones only — a doc
      // with no key AND no tombstone says nothing about a keychain that has
      // one (a migration may have skipped secrets), so bare absence must
      // never delete; an explicit disconnect elsewhere must.
      if (keyChanged && nextKey != null) {
        _keychainBestEffort(() => _secure.writeApiKey(bandId, nextKey));
      }
      if (keyRevoked) {
        _keychainBestEffort(() => _secure.deleteApiKey(bandId));
      }
      if (secretChanged && nextSecret != null) {
        _keychainBestEffort(() => _secure.writeRelaySecret(bandId, nextSecret));
      }
      if (secretRevoked) {
        _keychainBestEffort(() => _secure.deleteRelaySecret(bandId));
      }
      _notify();
    }, onError: _ignore);
  }

  void _ensureSessionsListener(String bandId) {
    if (_noBand(bandId) || _sessionSubs.containsKey(bandId)) return;
    _sessionSubs[bandId] = _sessionsCol(bandId)
        .orderBy('startedAt')
        .snapshots()
        .listen((snap) {
      applySessionsSnapshot(
        bandId,
        [for (final doc in snap.docs) doc.data()],
        fromCache: snap.metadata.isFromCache,
      );
    }, onError: _ignore);
  }

  /// Split out and test-visible for the same reason as [applyBandsSnapshot].
  @visibleForTesting
  void applySessionsSnapshot(
    String bandId,
    List<Map<String, dynamic>> docs, {
    required bool fromCache,
  }) {
    final decoded = <LiveSession>[];
    for (final data in docs) {
      final session = _decodeField(data, LiveSession.fromJson);
      if (session != null) decoded.add(session);
    }
    _sessions[bandId] = decoded;
    if (!fromCache) _sessionsSettled.add(bandId);
    _notify();
  }

  void _ensureRelayTipsListener(String bandId) {
    if (_noBand(bandId) || _relayTipSubs.containsKey(bandId)) return;
    // Newest first, capped like the local archive so both profiles show the
    // same window of tips.
    _relayTipSubs[bandId] = _relayTipsCol(bandId)
        .orderBy('createdAt', descending: true)
        .limit(LocalStore.relayHistoryCap)
        .snapshots()
        .listen((snap) {
      applyRelayTipsSnapshot(
        bandId,
        [for (final doc in snap.docs) doc.data()],
        fromCache: snap.metadata.isFromCache,
      );
    }, onError: _ignore);
  }

  /// Split out and test-visible for the same reason as [applyBandsSnapshot].
  @visibleForTesting
  void applyRelayTipsSnapshot(
    String bandId,
    List<Map<String, dynamic>> docs, {
    required bool fromCache,
  }) {
    final decoded = <Tip>[];
    for (final data in docs) {
      final tip = _decodeField(data, Tip.fromJson);
      if (tip != null) decoded.add(tip);
    }
    _relayTips[bandId] = decoded;
    if (!fromCache) _relayTipsSettled.add(bandId);
    _notify();
  }

  // --- Lenient decoding ---

  _BandMirror? _decodeBand(String id, Map<String, dynamic> data) {
    try {
      return _BandMirror(BandAccount(
        id: id,
        name: data['name'] as String? ?? '',
        createdAtMs: (data['createdAtMs'] as num?)?.toInt() ?? 0,
      ))
        ..tipJar = _decodeField(data['tipJar'], TipJar.fromJson)
        ..relayJar = _decodeField(data['relayJar'], RelayJar.fromJson)
        ..bandSettings =
            _decodeField(data['bandSettings'], BandSettings.fromJson);
    } catch (_) {
      return null;
    }
  }

  static T? _decodeField<T>(
      Object? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! Map) return null;
    try {
      return fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null; // a malformed field costs itself, not its siblings
    }
  }

  /// The mirror entry a write lands in — created on the spot for a band the
  /// listener hasn't delivered yet, so the sync read-back a caller does
  /// right after a write never misses.
  _BandMirror _mirrorFor(String accountId) => _bands.putIfAbsent(
      accountId,
      () => _BandMirror(
          BandAccount(id: accountId, name: '', createdAtMs: 0)));

  void _keychainBestEffort(Future<void> Function() op) {
    unawaited(() async {
      try {
        await op();
      } catch (_) {
        // Locked keychain / denied prompt — the mirror still serves reads.
      }
    }());
  }

  // --- The band list ---

  @override
  bool get isWarm => _warm;

  @override
  List<BandAccount> listBands() {
    final bands = [for (final m in _bands.values) m.account];
    // Creation order, like the registry. A doc written by a jar-save before
    // its upsert decodes with createdAtMs 0 — break ties on id so the order
    // is at least stable.
    bands.sort((a, b) {
      final byCreated = a.createdAtMs.compareTo(b.createdAtMs);
      return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
    });
    return bands;
  }

  @override
  String? readActiveBandId() => _local.readActiveCloudBand(uid);

  @override
  Future<void> saveActiveBandId(String bandId) =>
      _local.saveActiveCloudBand(uid, bandId);

  @override
  Future<void> upsertBandEntry(BandAccount band) {
    _mirrorFor(band.id).account = band;
    return _bandDoc(band.id).set({
      'name': band.name,
      'createdAtMs': band.createdAtMs,
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeBandEntry(String bandId) {
    // The band doc IS the registry entry; the jars and settings ride on it
    // as fields, so removing the entry removes them with it (the notifier
    // wipes data before removing anyway). Subcollections are
    // [wipeAccountData]'s job.
    _bands.remove(bandId);
    return _bandDoc(bandId).delete();
  }

  // --- Stripe tip jar ---

  @override
  TipJar? readTipJar(String accountId) => _bands[accountId]?.tipJar;

  @override
  Future<void> saveTipJar(String accountId, TipJar jar) {
    _mirrorFor(accountId).tipJar = jar;
    return _bandDoc(accountId).set({
      'tipJar': jar.toJson(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearTipJar(String accountId) {
    _bands[accountId]?.tipJar = null;
    return _bandDoc(accountId).set({
      'tipJar': FieldValue.delete(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  // --- Relay jar (connected mode) ---

  @override
  RelayJar? readRelayJar(String accountId) => _bands[accountId]?.relayJar;

  @override
  Future<void> saveRelayJar(String accountId, RelayJar jar) {
    _mirrorFor(accountId).relayJar = jar;
    // toJson omits unset optionals, and a merge deep-merges nested maps —
    // left alone, clearing your fan-page message would "unclear" itself on
    // the next snapshot. Spell every absence out as a deletion so the field
    // is replaced wholesale.
    final json = jar.toJson();
    return _bandDoc(accountId).set({
      'relayJar': {
        ...json,
        for (final key in const [
          'message',
          'revolutUsername',
          'mobilepayBoxId',
          'monzoUsername',
        ])
          if (!json.containsKey(key)) key: FieldValue.delete(),
      },
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearRelayJar(String accountId) {
    _bands[accountId]?.relayJar = null;
    return _bandDoc(accountId).set({
      'relayJar': FieldValue.delete(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  // The replaced-link notice is a device-local nag, not synced state: the
  // device that watched the jar die is the one that owes the reprint notice.
  @override
  String? readRelayLinkReplaced(String accountId) =>
      _local.readRelayLinkReplaced(accountId);

  @override
  Future<void> writeRelayLinkReplaced(String accountId, String oldTipUrl) =>
      _local.writeRelayLinkReplaced(accountId, oldTipUrl);

  @override
  Future<void> clearRelayLinkReplaced(String accountId) =>
      _local.clearRelayLinkReplaced(accountId);

  // --- Band settings ---

  @override
  BandSettings readBandSettings(String accountId) =>
      _bands[accountId]?.bandSettings ?? const BandSettings();

  @override
  Future<void> saveBandSettings(String accountId, BandSettings band) {
    _mirrorFor(accountId).bandSettings = band;
    // BandSettings serializes every key unconditionally, so a nested merge
    // IS a wholesale replace here — no deletion bookkeeping needed.
    return _bandDoc(accountId).set({
      'bandSettings': band.toJson(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  // --- Histories ---

  @override
  List<LiveSession> readSessionHistory(String accountId) {
    _ensureSessionsListener(accountId);
    return List.of(_sessions[accountId] ?? const []);
  }

  @override
  Future<void> appendSessionToHistory(String accountId, LiveSession session) {
    _ensureSessionsListener(accountId);
    final mirror = _sessions.putIfAbsent(accountId, () => []);
    if (!mirror.any((s) => s.id == session.id)) mirror.add(session);
    return _sessionsCol(accountId).doc(session.id).set({
      ...session.toJson(),
      'updatedAtMs': _nowMs,
    });
  }

  @override
  List<Tip> readRelayHistory(String accountId) {
    _ensureRelayTipsListener(accountId);
    return List.of(_relayTips[accountId] ?? const []);
  }

  @override
  Future<void> appendRelayHistory(String accountId, List<Tip> tips) async {
    if (tips.isEmpty) return;
    _ensureRelayTipsListener(accountId);
    final existing = _relayTips[accountId] ?? const <Tip>[];
    final ids = existing.map((t) => t.id).toSet();
    final fresh = [
      for (final t in tips)
        if (ids.add(t.id)) t,
    ];
    if (fresh.isEmpty) return;
    // A batch arrives oldest→newest; the mirror is newest-first and capped
    // like the local archive. The docs themselves are keyed by tip id, so
    // redelivered tips overwrite themselves instead of duplicating.
    final merged = [...fresh.reversed, ...existing];
    _relayTips[accountId] = merged.length > LocalStore.relayHistoryCap
        ? merged.sublist(0, LocalStore.relayHistoryCap)
        : merged;
    final now = _nowMs;
    await _commitChunked(_db, [
      for (final t in fresh)
        (batch) => batch.set(_relayTipsCol(accountId).doc(t.id),
            {...t.toJson(), 'updatedAtMs': now}),
    ]);
  }

  // --- Active session (crash recovery; device-local by contract) ---

  @override
  LiveSession? readActiveSession(String accountId) =>
      _local.readActiveSession(accountId);

  @override
  String? readActiveCursor(String accountId) =>
      _local.readActiveCursor(accountId);

  @override
  Future<void> saveActiveSession(
          String accountId, LiveSession session, String? cursor) =>
      _local.saveActiveSession(accountId, session, cursor);

  @override
  Future<void> clearActiveSession(String accountId) =>
      _local.clearActiveSession(accountId);

  // --- Secrets ---

  @override
  Future<String?> readApiKey(String accountId) async {
    String? cached;
    try {
      cached = await _secure.readApiKey(accountId);
    } catch (_) {
      // Locked keychain — the mirror below still answers, which is exactly
      // why the secrets doc exists.
    }
    if (cached != null) return cached;
    final mirrored = _secrets[accountId]?.stripeKey;
    if (mirrored != null) {
      // Backfill so the next read takes the fast path (a fresh install, or
      // a keychain that was locked when the write-through ran).
      _keychainBestEffort(() => _secure.writeApiKey(accountId, mirrored));
    }
    return mirrored;
  }

  @override
  Future<void> writeApiKey(String accountId, String key) async {
    // Keychain first, and a failure propagates exactly like the local
    // profile's: the caller must never believe a key exists that the fast
    // path can't produce.
    await _secure.writeApiKey(accountId, key);
    final trimmed = key.trim();
    _secrets.putIfAbsent(accountId, _SecretsMirror.new)
      ..stripeKey = trimmed
      ..stripeKeyTombstoned = false;
    await _secretsDoc(accountId).set({
      'stripeKey': trimmed,
      // A reconnect after a disconnect: the fresh key must win everywhere,
      // so the tombstone leaves in the same write.
      'stripeKeyDeletedAtMs': FieldValue.delete(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteApiKey(String accountId) async {
    await _secure.deleteApiKey(accountId);
    _secrets.putIfAbsent(accountId, _SecretsMirror.new)
      ..stripeKey = null
      ..stripeKeyTombstoned = true;
    await _secretsDoc(accountId).set({
      'stripeKey': FieldValue.delete(),
      // Not a bare deletion: the tombstone is how every OTHER device's
      // snapshot handler tells "disconnected" apart from "never uploaded"
      // and clears its keychain too — without it the disconnect only ever
      // revoked the key on the device that tapped it.
      'stripeKeyDeletedAtMs': _nowMs,
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<String?> readRelaySecret(String accountId) async {
    String? cached;
    try {
      cached = await _secure.readRelaySecret(accountId);
    } catch (_) {}
    if (cached != null) return cached;
    final mirrored = _secrets[accountId]?.relaySecret;
    if (mirrored != null) {
      _keychainBestEffort(() => _secure.writeRelaySecret(accountId, mirrored));
    }
    return mirrored;
  }

  @override
  Future<void> writeRelaySecret(String accountId, String secret) async {
    await _secure.writeRelaySecret(accountId, secret);
    final trimmed = secret.trim();
    _secrets.putIfAbsent(accountId, _SecretsMirror.new)
      ..relaySecret = trimmed
      ..relaySecretTombstoned = false;
    await _secretsDoc(accountId).set({
      'relaySecret': trimmed,
      // Same reconnect rule as the Stripe key: the fresh secret evicts the
      // tombstone in the same write.
      'relaySecretDeletedAtMs': FieldValue.delete(),
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteRelaySecret(String accountId) async {
    await _secure.deleteRelaySecret(accountId);
    _secrets.putIfAbsent(accountId, _SecretsMirror.new)
      ..relaySecret = null
      ..relaySecretTombstoned = true;
    await _secretsDoc(accountId).set({
      'relaySecret': FieldValue.delete(),
      // Same mechanism as the Stripe key: forgetting the relay jar here
      // must forget its secret on every device.
      'relaySecretDeletedAtMs': _nowMs,
      'updatedAtMs': _nowMs,
    }, SetOptions(merge: true));
  }

  // --- Whole-band lifecycle ---

  @override
  bool? accountHasData(String accountId) {
    // Kick the lazy history listeners so the answer improves on the next
    // ask — the first call may run before the histories have mirrored.
    _ensureSessionsListener(accountId);
    _ensureRelayTipsListener(accountId);
    final band = _bands[accountId];
    if (band?.tipJar != null ||
        band?.relayJar != null ||
        (_sessions[accountId]?.isNotEmpty ?? false) ||
        (_relayTips[accountId]?.isNotEmpty ?? false)) {
      return true;
    }
    // Nothing in the mirrors — which is only an ANSWER once every mirror
    // has heard from the server. Before that it is silence: history synced
    // from another device but never opened here would read as "empty", and
    // both callers of this method delete on "empty".
    return _bandsSettled &&
            _sessionsSettled.contains(accountId) &&
            _relayTipsSettled.contains(accountId)
        ? false
        : null;
  }

  /// Same predicate as the local store's: a session that never took real
  /// money. Empty sessions count as real — we can't prove they're fake.
  static bool _isSimulated(LiveSession s) =>
      s.tips.isNotEmpty && s.tips.every((d) => !d.livemode);

  @override
  Future<void> purgeSimulatedData(String accountId) async {
    // Query the collection directly rather than the mirror: purging runs at
    // connect time, possibly before any history listener ever started.
    final snap = await _sessionsCol(accountId).get();
    final doomed = <DocumentReference<Map<String, dynamic>>>[];
    final doomedIds = <String>{};
    for (final doc in snap.docs) {
      final session = _decodeField(doc.data(), LiveSession.fromJson);
      if (session != null && _isSimulated(session)) {
        doomed.add(doc.reference);
        doomedIds.add(doc.id);
      }
    }
    if (doomed.isNotEmpty) {
      _sessions[accountId]?.removeWhere((s) => doomedIds.contains(s.id));
      await _commitChunked(
          _db, [for (final ref in doomed) (batch) => batch.delete(ref)]);
    }
    // The crash snapshot is device-local; a simulated one goes with the rest.
    final active = _local.readActiveSession(accountId);
    if (active != null && _isSimulated(active)) {
      await _local.clearActiveSession(accountId);
    }
  }

  /// Stands in for [wipeAccountData]'s server-sourced listing in tests.
  /// fake_cloud_firestore serves the truth for every get and so cannot
  /// model the one condition the wipe must refuse to run under: an offline
  /// device whose cache holds only part of a collection. Tests swap this in
  /// to raise the `unavailable` the real client throws offline.
  @visibleForTesting
  Future<QuerySnapshot<Map<String, dynamic>>> Function(
      Query<Map<String, dynamic>> query)? serverGetOverride;

  Future<QuerySnapshot<Map<String, dynamic>>> _serverGet(
          Query<Map<String, dynamic>> query) =>
      serverGetOverride != null
          ? serverGetOverride!(query)
          : query.get(const GetOptions(source: Source.server));

  @override
  Future<void> wipeAccountData(String accountId) async {
    // Queried, not mirrored: the wipe must catch docs the lazy listeners
    // never got around to (and the relay-tip query beyond the mirror's cap).
    // And queried from the SERVER: offline, a plain get answers from the
    // cache, which only knows what this device happened to sync — docs it
    // never cached would survive the batch and strand an unreachable,
    // undeletable history under the deleted band doc. A wipe that must be
    // complete enumerates authoritatively or throws before deleting
    // anything; the caller keeps the band and reports failure instead of
    // half-deleting it.
    final refs = <DocumentReference<Map<String, dynamic>>>[
      ...(await _serverGet(_sessionsCol(accountId)))
          .docs
          .map((d) => d.reference),
      ...(await _serverGet(_relayTipsCol(accountId)))
          .docs
          .map((d) => d.reference),
      _secretsDoc(accountId),
      _bandDoc(accountId),
    ];
    _bands.remove(accountId);
    _secrets.remove(accountId);
    _sessions.remove(accountId);
    _relayTips.remove(accountId);
    await _commitChunked(
        _db, [for (final ref in refs) (batch) => batch.delete(ref)]);
    // The device-local crash snapshot and notices go too.
    await _local.wipeAccount(accountId);
  }

  @override
  Future<void> wipeAccountSecrets(String accountId) =>
      // Keychain only — the secrets DOC belongs to [wipeAccountData]. This
      // keeps the local contract: may throw, the caller tombstones and
      // retries at boot.
      _secure.wipeAccount(accountId);

  // --- Device settings ---

  @override
  AppSettings readSettings() =>
      // Local fallback until the first snapshot, so theme and locale don't
      // flash defaults on a cold start.
      _settings ?? _local.readSettings();

  @override
  Future<void> saveSettings(AppSettings settings) {
    _settings = settings;
    // Whole-doc replace, not merge: toJson drops localeCode when the user
    // goes back to the device language, and a merge would keep the old one.
    return _settingsDoc.set({...settings.toJson(), 'updatedAtMs': _nowMs});
  }
}

/// One band's slice of the mirror: the switcher entry plus the blobs that
/// live as fields on its Firestore doc.
class _BandMirror {
  _BandMirror(this.account);

  BandAccount account;
  TipJar? tipJar;
  RelayJar? relayJar;
  BandSettings? bandSettings;
}

/// The `secrets/v1` doc, mirrored so a locked keychain still has a fallback.
/// The tombstone flags remember that the last snapshot said "explicitly
/// disconnected" (not merely absent), so the keychain is cleared once per
/// disconnect instead of on every echo.
class _SecretsMirror {
  String? stripeKey;
  bool stripeKeyTombstoned = false;
  String? relaySecret;
  bool relaySecretTombstoned = false;
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
