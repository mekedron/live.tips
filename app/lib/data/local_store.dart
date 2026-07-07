import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/donation.dart';
import '../domain/live_session.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';

/// Non-secret local persistence: tip jar config, settings, session history,
/// and the active session (for crash/restart recovery).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> init() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _kTipJar = 'tip_jar_v1';
  static const _kSettings = 'settings_v1';
  static const _kHistory = 'session_history_v1';
  static const _kActiveSession = 'active_session_v1';
  static const _kActiveCursor = 'active_session_cursor_v1';
  static const _kRelayJar = 'relay_jar_v1';
  static const _kRelaySeenAt = 'relay_seen_at_v1';
  static const _kRelayHistory = 'relay_history_v1';

  /// Relay tips are small, but SharedPreferences is not a database — beyond
  /// this many archived tips the oldest fall off.
  static const relayHistoryCap = 1000;

  // --- Tip jar ---

  TipJar? readTipJar() {
    final raw = _prefs.getString(_kTipJar);
    if (raw == null) return null;
    try {
      return TipJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTipJar(TipJar jar) =>
      _prefs.setString(_kTipJar, jsonEncode(jar.toJson()));

  Future<void> clearTipJar() async {
    await _prefs.remove(_kTipJar);
  }

  // --- Relay jar (connected mode) ---

  RelayJar? readRelayJar() {
    final raw = _prefs.getString(_kRelayJar);
    if (raw == null) return null;
    try {
      return RelayJar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRelayJar(RelayJar jar) =>
      _prefs.setString(_kRelayJar, jsonEncode(jar.toJson()));

  Future<void> clearRelayJar() async {
    await _prefs.remove(_kRelayJar);
    await _prefs.remove(_kRelaySeenAt);
  }

  /// When (ms since epoch) the relay was last told the artist had seen
  /// everything — the keep-alive/seen marker.
  int? readRelaySeenAt() => _prefs.getInt(_kRelaySeenAt);

  Future<void> writeRelaySeenAt(int ms) => _prefs.setInt(_kRelaySeenAt, ms);

  // --- Relay tip history (device-local tip-page archive) ---

  /// Donor-declared tip-page (Revolut/MobilePay) tips recorded on this
  /// device, newest first. These exist nowhere else — the relay keeps no
  /// ledger — so History serves them from here. Deliberately untouched by
  /// [purgeSimulatedData]: only real (livemode) tips are ever written (the
  /// session controller filters demo tips out at the write site), so there
  /// is nothing simulated to purge.
  List<Donation> readRelayHistory() {
    final raw = _prefs.getString(_kRelayHistory);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((d) => Donation.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Prepends [donations] to the archive, skipping ids already stored (the
  /// relay redelivers and resumed sessions replay — same tip, same id),
  /// capped at [relayHistoryCap] with the oldest dropped beyond it.
  Future<void> appendRelayHistory(List<Donation> donations) async {
    if (donations.isEmpty) return;
    final existing = readRelayHistory();
    final ids = existing.map((d) => d.id).toSet();
    final fresh = [
      for (final d in donations)
        if (ids.add(d.id)) d,
    ];
    if (fresh.isEmpty) return;
    // A batch arrives oldest→newest; the archive is newest-first.
    final merged = [...fresh.reversed, ...existing];
    final capped = merged.length > relayHistoryCap
        ? merged.sublist(0, relayHistoryCap)
        : merged;
    await _prefs.setString(
      _kRelayHistory,
      jsonEncode([for (final d in capped) d.toJson()]),
    );
  }

  // --- Settings ---

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

  // --- Session history ---

  List<LiveSession> readSessionHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((s) => LiveSession.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendSessionToHistory(LiveSession session) async {
    final history = readSessionHistory()..add(session);
    await _prefs.setString(
      _kHistory,
      jsonEncode(history.map((s) => s.toJson()).toList()),
    );
  }

  // --- Active session (crash recovery) ---

  LiveSession? readActiveSession() {
    final raw = _prefs.getString(_kActiveSession);
    if (raw == null) return null;
    try {
      return LiveSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? readActiveCursor() => _prefs.getString(_kActiveCursor);

  Future<void> saveActiveSession(LiveSession session, String? cursor) async {
    await _prefs.setString(_kActiveSession, jsonEncode(session.toJson()));
    if (cursor != null) {
      await _prefs.setString(_kActiveCursor, cursor);
    }
  }

  Future<void> clearActiveSession() async {
    await _prefs.remove(_kActiveSession);
    await _prefs.remove(_kActiveCursor);
  }

  // --- Demo/test cleanup ---

  /// A session that never took real (live) money — pure demo play or a
  /// test-mode set. Empty sessions count as real: we can't prove they're
  /// fake, and would rather keep a genuine zero-tip live set than delete it.
  static bool _isSimulated(LiveSession s) =>
      s.donations.isNotEmpty && s.donations.every((d) => !d.livemode);

  /// Scrubs locally cached demo/test sessions so a real (live) Stripe account
  /// never shows tips that weren't real money. Called when a real account
  /// connects, and once at startup for an already-connected live account.
  Future<void> purgeSimulatedData() async {
    final real =
        readSessionHistory().where((s) => !_isSimulated(s)).toList();
    await _prefs.setString(
      _kHistory,
      jsonEncode(real.map((s) => s.toJson()).toList()),
    );
    final active = readActiveSession();
    if (active != null && _isSimulated(active)) {
      await clearActiveSession();
    }
  }

  Future<void> wipeAll() async {
    await _prefs.clear();
  }
}
