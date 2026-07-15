import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/notification_item.dart';

/// The bell feed and its settings doc, `users/{uid}/notifications` and
/// `users/{uid}/settings/notifications` — [DeviceRegistry]'s mold: built with
/// a null [FirebaseFirestore] wherever Firebase isn't (local mode,
/// Windows/Linux, tests), and then every call no-ops and every stream is
/// empty, so callers need no platform branches.
///
/// The feed itself is read-only glass on this side: rules deny every client
/// write, the tip paths append and the trigger trims (server-side
/// notifications.ts). The one thing the app writes is its own settings doc —
/// the kind toggles and the mark-all-read watermark.
class NotificationsService {
  NotificationsService({required FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  /// How much feed the bell page shows. Deliberately below the server's
  /// 100-doc cap: "what did I miss" is a page, not an archive — History is
  /// where the full ledger lives.
  static const feedLimit = 50;

  DocumentReference<Map<String, dynamic>>? _prefsDoc(String uid) =>
      _db?.doc('users/$uid/settings/notifications');

  /// Newest first, capped at [feedLimit].
  Stream<List<NotificationItem>> watchFeed(String uid) {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection('users/$uid/notifications')
        .orderBy('createdAtMs', descending: true)
        .limit(feedLimit)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs) NotificationItem.fromJson(d.id, d.data()),
            ])
        .handleError((Object e) {
      debugPrint('notifications feed watch failed: $e');
    });
  }

  /// The account's choices; an absent doc is the all-default prefs, exactly
  /// as the server reads it.
  Stream<NotificationPrefs> watchPrefs(String uid) {
    final doc = _prefsDoc(uid);
    if (doc == null) return Stream.value(const NotificationPrefs());
    return doc
        .snapshots()
        .map((snap) => NotificationPrefs.fromJson(snap.data()))
        .handleError((Object e) {
      debugPrint('notification prefs watch failed: $e');
    });
  }

  /// Merge-writes one kind flag; the other flag and the watermark stay put.
  Future<void> saveKind(String uid, {bool? tips, bool? songRequests}) async {
    final doc = _prefsDoc(uid);
    if (doc == null) return;
    try {
      await doc.set({
        'tips': ?tips,
        'songRequests': ?songRequests,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('notification prefs save failed: $e');
    }
  }

  /// The bell's mark-all-read: everything the page SHOWED counts as seen —
  /// on this device and, because the watermark syncs, on every other one.
  ///
  /// [newestSeenMs] is the newest createdAtMs on screen, and the watermark is
  /// max(now, that): "now" alone left a badge that would not die — the
  /// server stamps createdAtMs with ITS clock, so a device running even a
  /// second behind marked everything read and still counted the newest
  /// entry as unread.
  Future<void> markAllRead(String uid, {int newestSeenMs = 0}) async {
    final doc = _prefsDoc(uid);
    if (doc == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await doc.set({
        'lastSeenAtMs': now > newestSeenMs ? now : newestSeenMs,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('notifications mark-read failed: $e');
    }
  }
}
