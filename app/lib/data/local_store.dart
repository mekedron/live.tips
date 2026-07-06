import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/live_session.dart';
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
