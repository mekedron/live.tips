import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_account.dart';
import '../domain/app_settings.dart';
import '../domain/band_account.dart';
import '../domain/band_settings.dart';
import '../domain/device_kind.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/live_session.dart';
import '../domain/pending_redirect.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';
import 'local_cipher.dart';

/// Non-secret local persistence. Two kinds of keys live here: device-wide
/// ones (the accounts registry, device settings) and per-band ones — every
/// band-owned blob (jars, histories, the active session, band settings) is
/// stored under `<base>_<accountId>`, so bands never see each other's data.
///
/// On a VENUE device every string value goes through [LocalCipher] — see the
/// honesty note there about what that does and does not protect. Ints, bools
/// and string lists stay plain: they are timestamps, flags and band-id
/// tombstones, not profile data.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> init() async =>
      LocalStore(await SharedPreferences.getInstance());

  /// Set on venue devices before anything reads (boot) or right after the
  /// wipe that entering venue mode performs — so no venue-written value ever
  /// exists in plaintext. Null everywhere else.
  LocalCipher? _cipher;

  // ignore: avoid_setters_without_getters — write-only by design: nothing
  // downstream may branch on whether encryption is on.
  set cipher(LocalCipher? cipher) => _cipher = cipher;

  String? _getString(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    final cipher = _cipher;
    if (cipher == null) {
      // An encrypted leftover read without the key is "nothing stored" —
      // never garbage handed to a JSON parser.
      return raw.startsWith(LocalCipher.prefix) ? null : raw;
    }
    return cipher.decrypt(raw);
  }

  Future<bool> _setString(String key, String value) {
    final cipher = _cipher;
    return _prefs.setString(key, cipher == null ? value : cipher.encrypt(value));
  }

  // Device-wide keys.
  static const kAccounts = 'accounts_v1';
  static const kAccountsDirectory = 'accounts_directory_v1';
  static const _kSettings = 'settings_v1';
  static const _kPendingSecretWipes = 'pending_secret_wipes_v1';
  static const _kFxRates = 'fx_rates_v1';

  // Per-band key bases — suffixed with `_<accountId>`. The unsuffixed names
  // are the pre-multi-band slots; the boot migration moves them.
  static const kTipJarBase = 'tip_jar_v1';
  static const kHistoryBase = 'session_history_v1';
  static const kActiveSessionBase = 'active_session_v1';
  static const kActiveCursorBase = 'active_session_cursor_v1';
  static const kRelayJarBase = 'relay_jar_v1';
  static const kRelaySeenAtBase = 'relay_seen_at_v1';
  static const kRelayHistoryBase = 'relay_history_v1';
  static const kRelayLinkReplacedBase = 'relay_link_replaced_v1';
  static const kBandSettingsBase = 'band_settings_v1';

  /// Every per-band key base — the definition of "a band's local data" for
  /// wipes, emptiness checks, and the migration.
  static const accountKeyBases = [
    kTipJarBase,
    kHistoryBase,
    kActiveSessionBase,
    kActiveCursorBase,
    kRelayJarBase,
    kRelaySeenAtBase,
    kRelayHistoryBase,
    kRelayLinkReplacedBase,
    kBandSettingsBase,
  ];

  static String accountKey(String base, String accountId) =>
      '${base}_$accountId';

  /// Relay tips are small, but SharedPreferences is not a database — beyond
  /// this many archived tips the oldest fall off.
  static const relayHistoryCap = 1000;

  // --- Accounts registry ---

  AccountsRegistry? readAccountsRegistry() {
    final raw = _getString(kAccounts);
    if (raw == null) return null;
    try {
      final registry = AccountsRegistry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      return registry.accounts.isEmpty ? null : registry;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccountsRegistry(AccountsRegistry registry) =>
      _setString(kAccounts, jsonEncode(registry.toJson()));

  // --- Accounts directory (device profiles: local + signed-in accounts) ---

  AccountsDirectory? readAccountsDirectory() {
    final raw = _getString(kAccountsDirectory);
    if (raw == null) return null;
    try {
      return AccountsDirectory.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccountsDirectory(AccountsDirectory directory) =>
      _setString(kAccountsDirectory, jsonEncode(directory.toJson()));

  /// Whether this band has any local data at all — used by the switcher's
  /// garbage collection of abandoned, never-configured bands. Deliberately
  /// checks every per-band key (including the relay-tip archive, which is
  /// the only record of those tips anywhere) so "empty" can never eat data.
  bool accountHasData(String accountId) => accountKeyBases
      .any((base) => _prefs.containsKey(accountKey(base, accountId)));

  /// Removes every local blob belonging to [accountId].
  Future<void> wipeAccount(String accountId) async {
    for (final base in accountKeyBases) {
      await _prefs.remove(accountKey(base, accountId));
    }
  }

  /// Account ids whose keychain secrets still need deleting — recorded when
  /// a band was removed while the keychain was locked, retried at boot.
  /// Explicit tombstones, never inferred from registry absence: the keychain
  /// outlives prefs across reinstalls, and inferring would destroy secrets a
  /// fresh install merely doesn't know about yet.
  List<String> readPendingSecretWipes() =>
      _prefs.getStringList(_kPendingSecretWipes) ?? const [];

  Future<void> addPendingSecretWipe(String accountId) async {
    final wipes = readPendingSecretWipes();
    if (wipes.contains(accountId)) return;
    await _prefs.setStringList(_kPendingSecretWipes, [...wipes, accountId]);
  }

  Future<void> removePendingSecretWipe(String accountId) async {
    final wipes =
        readPendingSecretWipes().where((id) => id != accountId).toList();
    if (wipes.isEmpty) {
      await _prefs.remove(_kPendingSecretWipes);
    } else {
      await _prefs.setStringList(_kPendingSecretWipes, wipes);
    }
  }

  // --- Device identity ---

  static const _kDeviceId = 'device_id_v1';

  /// Stable per-device id, minted on first ask and never rotated — how the
  /// multi-device session coordination tells "my lease" from "someone
  /// else's". setString updates the in-memory cache synchronously, so the
  /// read-back is immediate; only the disk write is deferred.
  String deviceId() {
    final existing = _getString(_kDeviceId);
    if (existing != null) return existing;
    final random = Random.secure();
    final id = 'dev_${List.generate(
      20,
      (_) => random.nextInt(16).toRadixString(16),
    ).join()}';
    _setString(_kDeviceId, id);
    return id;
  }

  // --- Cloud profile: device-local prefs ---
  //
  // A signed-in account's band LIST lives in Firestore, but which band this
  // device is looking at does not: two devices on the same account can be on
  // different bands, and syncing the choice would make them fight.

  static const kActiveCloudBandBase = 'active_band_v1';

  String? readActiveCloudBand(String uid) =>
      _getString('${kActiveCloudBandBase}_$uid');

  Future<void> saveActiveCloudBand(String uid, String bandId) =>
      _setString('${kActiveCloudBandBase}_$uid', bandId);

  /// Ending a venue session forgets even WHICH band the artist was on —
  /// nothing of theirs stays behind on a public device.
  Future<void> clearActiveCloudBand(String uid) async {
    await _prefs.remove('${kActiveCloudBandBase}_$uid');
  }

  // --- Pending local→cloud upload ---
  //
  // Set BEFORE the first byte of a local-bands upload leaves the device, so
  // a crash mid-upload is visible at the next boot and the upload resumes
  // instead of stranding half the bands in the cloud. Cleared only after
  // the upload committed AND the local copies were wiped.

  static const _kCloudUploadPending = 'cloud_upload_pending_v1';

  ({String uid, List<String> bandIds})? readCloudUploadPending() {
    final raw = _getString(_kCloudUploadPending);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        uid: json['uid'] as String,
        bandIds: [
          for (final id in json['bandIds'] as List? ?? const [])
            if (id is String) id,
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCloudUploadPending(String uid, List<String> bandIds) =>
      _setString(
          _kCloudUploadPending, jsonEncode({'uid': uid, 'bandIds': bandIds}));

  Future<void> clearCloudUploadPending() async {
    await _prefs.remove(_kCloudUploadPending);
  }

  // --- Pending web redirect sign-in ---
  //
  // Written BEFORE the browser is handed to Apple/Google and consumed exactly
  // once on the way back (see PendingRedirect). The reload destroys every bit
  // of in-memory state, so this is the only thread connecting the two halves
  // of a web sign-in.

  static const _kPendingRedirect = 'pending_redirect_v1';

  PendingRedirect? readPendingRedirect() {
    final raw = _getString(_kPendingRedirect);
    if (raw == null) return null;
    try {
      return PendingRedirect.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePendingRedirect(PendingRedirect pending) =>
      _setString(_kPendingRedirect, jsonEncode(pending.toJson()));

  Future<void> clearPendingRedirect() async {
    await _prefs.remove(_kPendingRedirect);
  }

  /// Whether [uid] was already offered the local→cloud band upload —
  /// declining is an answer, and re-asking on every sign-in is nagging.
  bool readCloudUploadOffered(String uid) =>
      _prefs.getBool('cloud_upload_offered_v1_$uid') ?? false;

  Future<void> markCloudUploadOffered(String uid) =>
      _prefs.setBool('cloud_upload_offered_v1_$uid', true);

  // --- Tip jar ---

  TipJar? readTipJar(String accountId) {
    final raw = _getString(accountKey(kTipJarBase, accountId));
    if (raw == null) return null;
    try {
      return TipJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTipJar(String accountId, TipJar jar) => _setString(
      accountKey(kTipJarBase, accountId), jsonEncode(jar.toJson()));

  Future<void> clearTipJar(String accountId) async {
    await _prefs.remove(accountKey(kTipJarBase, accountId));
  }

  // --- Relay jar (connected mode) ---

  RelayJar? readRelayJar(String accountId) {
    final raw = _getString(accountKey(kRelayJarBase, accountId));
    if (raw == null) return null;
    try {
      return RelayJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRelayJar(String accountId, RelayJar jar) =>
      _setString(
          accountKey(kRelayJarBase, accountId), jsonEncode(jar.toJson()));

  Future<void> clearRelayJar(String accountId) async {
    await _prefs.remove(accountKey(kRelayJarBase, accountId));
    await _prefs.remove(accountKey(kRelaySeenAtBase, accountId));
  }

  /// When (ms since epoch) the relay was last told the artist had seen
  /// everything — the keep-alive/seen marker for this band's jar.
  int? readRelaySeenAt(String accountId) =>
      _prefs.getInt(accountKey(kRelaySeenAtBase, accountId));

  Future<void> writeRelaySeenAt(String accountId, int ms) =>
      _prefs.setInt(accountKey(kRelaySeenAtBase, accountId), ms);

  /// The tip URL of a jar that stopped working and was auto-replaced, kept
  /// until the artist dismisses the "please reprint" notice. Null when there
  /// is nothing to warn about.
  String? readRelayLinkReplaced(String accountId) =>
      _getString(accountKey(kRelayLinkReplacedBase, accountId));

  Future<void> writeRelayLinkReplaced(String accountId, String oldTipUrl) =>
      _setString(
          accountKey(kRelayLinkReplacedBase, accountId), oldTipUrl);

  Future<void> clearRelayLinkReplaced(String accountId) =>
      _prefs.remove(accountKey(kRelayLinkReplacedBase, accountId));

  // --- Relay tip history (device-local tip-page archive) ---

  /// Fan-declared tip-page (Revolut/MobilePay) tips recorded on this
  /// device, newest first. These exist nowhere else — the relay keeps no
  /// ledger — so History serves them from here. Deliberately untouched by
  /// [purgeSimulatedData]: only real (livemode) tips are ever written (the
  /// session controller filters demo tips out at the write site), so there
  /// is nothing simulated to purge.
  List<Tip> readRelayHistory(String accountId) {
    final raw = _getString(accountKey(kRelayHistoryBase, accountId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((d) => Tip.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Prepends [tips] to the archive, skipping ids already stored (the
  /// relay redelivers and resumed sessions replay — same tip, same id),
  /// capped at [relayHistoryCap] with the oldest dropped beyond it.
  Future<void> appendRelayHistory(
      String accountId, List<Tip> tips) async {
    if (tips.isEmpty) return;
    final existing = readRelayHistory(accountId);
    final ids = existing.map((d) => d.id).toSet();
    final fresh = [
      for (final d in tips)
        if (ids.add(d.id)) d,
    ];
    if (fresh.isEmpty) return;
    // A batch arrives oldest→newest; the archive is newest-first.
    final merged = [...fresh.reversed, ...existing];
    final capped = merged.length > relayHistoryCap
        ? merged.sublist(0, relayHistoryCap)
        : merged;
    await _setString(
      accountKey(kRelayHistoryBase, accountId),
      jsonEncode([for (final d in capped) d.toJson()]),
    );
  }

  // --- Device settings ---

  AppSettings readSettings() {
    final raw = _getString(_kSettings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      _setString(_kSettings, jsonEncode(settings.toJson()));

  // --- Exchange rates (device-wide) ---
  //
  // Cached so a stage with no signal can still total a mixed-currency set from
  // the last rates it saw, and so we hit the rates service once a day, not once
  // a session.

  FxRates? readFxRates() {
    final raw = _getString(_kFxRates);
    if (raw == null) return null;
    try {
      return FxRates.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFxRates(FxRates rates) =>
      _setString(_kFxRates, jsonEncode(rates.toJson()));

  // --- Band settings ---

  BandSettings readBandSettings(String accountId) {
    final raw = _getString(accountKey(kBandSettingsBase, accountId));
    if (raw == null) return const BandSettings();
    try {
      return BandSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const BandSettings();
    }
  }

  Future<void> saveBandSettings(String accountId, BandSettings band) =>
      _setString(
          accountKey(kBandSettingsBase, accountId), jsonEncode(band.toJson()));

  // --- Session history ---

  List<LiveSession> readSessionHistory(String accountId) {
    final raw = _getString(accountKey(kHistoryBase, accountId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((s) => LiveSession.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendSessionToHistory(
      String accountId, LiveSession session) async {
    final history = readSessionHistory(accountId)..add(session);
    await _setString(
      accountKey(kHistoryBase, accountId),
      jsonEncode(history.map((s) => s.toJson()).toList()),
    );
  }

  // --- Active session (crash recovery) ---

  LiveSession? readActiveSession(String accountId) {
    final raw = _getString(accountKey(kActiveSessionBase, accountId));
    if (raw == null) return null;
    try {
      return LiveSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? readActiveCursor(String accountId) =>
      _getString(accountKey(kActiveCursorBase, accountId));

  Future<void> saveActiveSession(
      String accountId, LiveSession session, String? cursor) async {
    await _setString(
      accountKey(kActiveSessionBase, accountId),
      jsonEncode(session.toJson()),
    );
    if (cursor != null) {
      await _setString(accountKey(kActiveCursorBase, accountId), cursor);
    }
  }

  Future<void> clearActiveSession(String accountId) async {
    await _prefs.remove(accountKey(kActiveSessionBase, accountId));
    await _prefs.remove(accountKey(kActiveCursorBase, accountId));
  }

  // --- Demo/test cleanup ---

  /// A session that never took real (live) money — pure demo play or a
  /// test-mode set. Empty sessions count as real: we can't prove they're
  /// fake, and would rather keep a genuine zero-tip live set than delete it.
  static bool _isSimulated(LiveSession s) =>
      s.tips.isNotEmpty && s.tips.every((d) => !d.livemode);

  /// Scrubs locally cached demo/test sessions so a real (live) Stripe account
  /// never shows tips that weren't real money. Called when a real account
  /// connects, and once at startup for an already-connected live account.
  Future<void> purgeSimulatedData(String accountId) async {
    final all = readSessionHistory(accountId);
    final real = all.where((s) => !_isSimulated(s)).toList();
    // Write only when something actually changes: materializing an empty
    // history key on a pristine band would make it look like it has data,
    // which keeps the abandoned-band garbage collection from ever firing.
    if (real.length != all.length ||
        _prefs.containsKey(accountKey(kHistoryBase, accountId))) {
      await _setString(
        accountKey(kHistoryBase, accountId),
        jsonEncode(real.map((s) => s.toJson()).toList()),
      );
    }
    final active = readActiveSession(accountId);
    if (active != null && _isSimulated(active)) {
      await clearActiveSession(accountId);
    }
  }

  // --- Device kind (performer / venue / demo) ---
  //
  // Raw prefs on purpose, never the cipher helpers: the kind decides WHETHER
  // the cipher attaches, so it must be readable before one exists — and it is
  // the one value that means nothing to an attacker anyway.

  static const kDeviceKind = 'device_kind_v1';

  DeviceKind? readDeviceKind() =>
      deviceKindFromName(_prefs.getString(kDeviceKind));

  Future<void> saveDeviceKind(DeviceKind kind) =>
      _prefs.setString(kDeviceKind, kind.name);

  Future<void> clearDeviceKind() async {
    await _prefs.remove(kDeviceKind);
  }

  // --- Venue session (the shared tablet's current artist) ---

  static const _kVenueSession = 'venue_session_v1';

  VenueSession? readVenueSession() {
    final raw = _getString(_kVenueSession);
    if (raw == null) return null;
    try {
      return VenueSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Persisted the moment the session starts, deadline included, so a
  /// restart can only ever HONOUR the 12-hour ceiling — never extend it.
  Future<void> saveVenueSession(VenueSession session) =>
      _setString(_kVenueSession, jsonEncode(session.toJson()));

  Future<void> clearVenueSession() async {
    await _prefs.remove(_kVenueSession);
  }

  // --- Account session slots (uid → FirebaseApp name) ---
  //
  // Which per-account FirebaseApp instances to revive at boot. The uid can't
  // be the app name itself: a sign-in needs an app BEFORE the uid is known,
  // so apps are named by slot and the mapping is recorded on success.

  static const _kAccountSessionSlots = 'account_session_slots_v1';

  Map<String, String> readAccountSessionSlots() {
    final raw = _getString(_kAccountSessionSlots);
    if (raw == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveAccountSessionSlots(Map<String, String> slots) async {
    if (slots.isEmpty) {
      await _prefs.remove(_kAccountSessionSlots);
    } else {
      await _setString(_kAccountSessionSlots, jsonEncode(slots));
    }
  }

  Future<void> wipeAll() async {
    await _prefs.clear();
  }

  /// Raw prefs access for the boot migration only — everything else goes
  /// through the typed readers above.
  SharedPreferences get prefs => _prefs;
}
