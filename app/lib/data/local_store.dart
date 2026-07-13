import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_account.dart';
import '../domain/app_settings.dart';
import '../domain/band_account.dart';
import '../domain/band_settings.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/live_session.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';

/// Non-secret local persistence. Two kinds of keys live here: device-wide
/// ones (the accounts registry, device settings) and per-band ones — every
/// band-owned blob (jars, histories, the active session, band settings) is
/// stored under `<base>_<accountId>`, so bands never see each other's data.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> init() async =>
      LocalStore(await SharedPreferences.getInstance());

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
    final raw = _prefs.getString(kAccounts);
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
      _prefs.setString(kAccounts, jsonEncode(registry.toJson()));

  // --- Accounts directory (device profiles: local + signed-in accounts) ---

  AccountsDirectory? readAccountsDirectory() {
    final raw = _prefs.getString(kAccountsDirectory);
    if (raw == null) return null;
    try {
      return AccountsDirectory.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccountsDirectory(AccountsDirectory directory) =>
      _prefs.setString(kAccountsDirectory, jsonEncode(directory.toJson()));

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

  // --- Cloud profile: device-local prefs ---
  //
  // A signed-in account's band LIST lives in Firestore, but which band this
  // device is looking at does not: two devices on the same account can be on
  // different bands, and syncing the choice would make them fight.

  static const kActiveCloudBandBase = 'active_band_v1';

  String? readActiveCloudBand(String uid) =>
      _prefs.getString('${kActiveCloudBandBase}_$uid');

  Future<void> saveActiveCloudBand(String uid, String bandId) =>
      _prefs.setString('${kActiveCloudBandBase}_$uid', bandId);

  // --- Pending local→cloud upload ---
  //
  // Set BEFORE the first byte of a local-bands upload leaves the device, so
  // a crash mid-upload is visible at the next boot and the upload resumes
  // instead of stranding half the bands in the cloud. Cleared only after
  // the upload committed AND the local copies were wiped.

  static const _kCloudUploadPending = 'cloud_upload_pending_v1';

  ({String uid, List<String> bandIds})? readCloudUploadPending() {
    final raw = _prefs.getString(_kCloudUploadPending);
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
      _prefs.setString(
          _kCloudUploadPending, jsonEncode({'uid': uid, 'bandIds': bandIds}));

  Future<void> clearCloudUploadPending() async {
    await _prefs.remove(_kCloudUploadPending);
  }

  /// Whether [uid] was already offered the local→cloud band upload —
  /// declining is an answer, and re-asking on every sign-in is nagging.
  bool readCloudUploadOffered(String uid) =>
      _prefs.getBool('cloud_upload_offered_v1_$uid') ?? false;

  Future<void> markCloudUploadOffered(String uid) =>
      _prefs.setBool('cloud_upload_offered_v1_$uid', true);

  // --- Tip jar ---

  TipJar? readTipJar(String accountId) {
    final raw = _prefs.getString(accountKey(kTipJarBase, accountId));
    if (raw == null) return null;
    try {
      return TipJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTipJar(String accountId, TipJar jar) => _prefs.setString(
      accountKey(kTipJarBase, accountId), jsonEncode(jar.toJson()));

  Future<void> clearTipJar(String accountId) async {
    await _prefs.remove(accountKey(kTipJarBase, accountId));
  }

  // --- Relay jar (connected mode) ---

  RelayJar? readRelayJar(String accountId) {
    final raw = _prefs.getString(accountKey(kRelayJarBase, accountId));
    if (raw == null) return null;
    try {
      return RelayJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRelayJar(String accountId, RelayJar jar) =>
      _prefs.setString(
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
      _prefs.getString(accountKey(kRelayLinkReplacedBase, accountId));

  Future<void> writeRelayLinkReplaced(String accountId, String oldTipUrl) =>
      _prefs.setString(
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
    final raw = _prefs.getString(accountKey(kRelayHistoryBase, accountId));
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
    await _prefs.setString(
      accountKey(kRelayHistoryBase, accountId),
      jsonEncode([for (final d in capped) d.toJson()]),
    );
  }

  // --- Device settings ---

  AppSettings readSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_kSettings, jsonEncode(settings.toJson()));

  // --- Exchange rates (device-wide) ---
  //
  // Cached so a stage with no signal can still total a mixed-currency set from
  // the last rates it saw, and so we hit the rates service once a day, not once
  // a session.

  FxRates? readFxRates() {
    final raw = _prefs.getString(_kFxRates);
    if (raw == null) return null;
    try {
      return FxRates.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFxRates(FxRates rates) =>
      _prefs.setString(_kFxRates, jsonEncode(rates.toJson()));

  // --- Band settings ---

  BandSettings readBandSettings(String accountId) {
    final raw = _prefs.getString(accountKey(kBandSettingsBase, accountId));
    if (raw == null) return const BandSettings();
    try {
      return BandSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const BandSettings();
    }
  }

  Future<void> saveBandSettings(String accountId, BandSettings band) =>
      _prefs.setString(
          accountKey(kBandSettingsBase, accountId), jsonEncode(band.toJson()));

  // --- Session history ---

  List<LiveSession> readSessionHistory(String accountId) {
    final raw = _prefs.getString(accountKey(kHistoryBase, accountId));
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
    await _prefs.setString(
      accountKey(kHistoryBase, accountId),
      jsonEncode(history.map((s) => s.toJson()).toList()),
    );
  }

  // --- Active session (crash recovery) ---

  LiveSession? readActiveSession(String accountId) {
    final raw = _prefs.getString(accountKey(kActiveSessionBase, accountId));
    if (raw == null) return null;
    try {
      return LiveSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? readActiveCursor(String accountId) =>
      _prefs.getString(accountKey(kActiveCursorBase, accountId));

  Future<void> saveActiveSession(
      String accountId, LiveSession session, String? cursor) async {
    await _prefs.setString(
      accountKey(kActiveSessionBase, accountId),
      jsonEncode(session.toJson()),
    );
    if (cursor != null) {
      await _prefs.setString(accountKey(kActiveCursorBase, accountId), cursor);
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
      await _prefs.setString(
        accountKey(kHistoryBase, accountId),
        jsonEncode(real.map((s) => s.toJson()).toList()),
      );
    }
    final active = readActiveSession(accountId);
    if (active != null && _isSimulated(active)) {
      await clearActiveSession(accountId);
    }
  }

  Future<void> wipeAll() async {
    await _prefs.clear();
  }

  /// Raw prefs access for the boot migration only — everything else goes
  /// through the typed readers above.
  SharedPreferences get prefs => _prefs;
}
