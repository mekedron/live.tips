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
/// Only the server APPENDS to the feed (the tip paths write, the trigger
/// trims — server-side notifications.ts); the app never creates or edits an
/// entry, but it may DELETE — the trash and Clear all silence nobody but
/// their owner. The settings doc holds the app-written state: the kind
/// toggles and the mark-all-read watermark.
class NotificationsService {
  NotificationsService({required FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  /// One screenful. The page starts here and grows by the same step as the
  /// artist scrolls — never the whole feed up front.
  static const pageSize = 25;

  /// The server's trim cap (functions/src/notifications.ts
  /// MAX_NOTIFICATIONS): past this there is nothing more to page in, and
  /// Clear all can trust one query to see everything.
  static const serverCap = 100;

  CollectionReference<Map<String, dynamic>>? _col(String uid) =>
      _db?.collection('users/$uid/notifications');

  DocumentReference<Map<String, dynamic>>? _prefsDoc(String uid) =>
      _db?.doc('users/$uid/settings/notifications');

  /// Newest first, at most [limit] — the page's window, grown on scroll.
  Stream<List<NotificationItem>> watchFeed(String uid, {required int limit}) {
    final col = _col(uid);
    if (col == null) return Stream.value(const []);
    return col
        .orderBy('createdAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs) NotificationItem.fromJson(d.id, d.data()),
            ])
        .handleError((Object e) {
      debugPrint('notifications feed watch failed: $e');
    });
  }

  /// How many entries are newer than the watermark — the bell's number. Only
  /// the unread docs travel (usually none), so the badge does not drag the
  /// whole feed over the wire on every app start.
  Stream<int> watchUnreadCount(String uid, int sinceMs) {
    final col = _col(uid);
    if (col == null) return Stream.value(0);
    return col
        .where('createdAtMs', isGreaterThan: sinceMs)
        .limit(serverCap)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((Object e) {
      debugPrint('notifications unread watch failed: $e');
    });
  }

  /// The row's trash. Deleting is the one client write the rules allow.
  Future<void> delete(String uid, String id) async {
    final col = _col(uid);
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (e) {
      debugPrint('notification delete failed: $e');
    }
  }

  /// Clear all: everything, not just the page — one query sees the whole
  /// feed because the server caps it at [serverCap], comfortably inside a
  /// single batch's 500 writes.
  Future<void> clearAll(String uid) async {
    final db = _db;
    final col = _col(uid);
    if (db == null || col == null) return;
    try {
      final snap = await col.limit(serverCap).get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('notifications clear-all failed: $e');
    }
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
