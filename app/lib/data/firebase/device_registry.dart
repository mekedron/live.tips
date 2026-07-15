import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// One device signed into a cloud account, as `users/{uid}/devices/{id}`.
///
/// The app owns the descriptive fields (name, platform, model, timestamps);
/// `revoked` is function-owned — rules reject any client write that touches
/// it, so a revoked device cannot launder itself back to trusted. [isCurrent]
/// is not stored: it's this device's id compared with the doc's, decided at
/// read time.
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    this.model,
    this.createdAtMs = 0,
    this.lastSeenAtMs = 0,
    this.revoked = false,
    this.fcmToken,
    this.fcmTokenAtMs,
    this.isCurrent = false,
  });

  final String id;
  final String name;

  /// 'ios' | 'android' | 'macos' | 'web' | 'unknown'.
  final String platform;
  final String? model;
  final int createdAtMs;
  final int lastSeenAtMs;
  final bool revoked;

  /// This device's push registration, present exactly while push is enabled
  /// here for this account (PushRegistration owns the writes; the send
  /// trigger and the revocation paths clear it server-side).
  final String? fcmToken;

  /// When [fcmToken] last landed — the settings page's "registered since".
  final int? fcmTokenAtMs;
  final bool isCurrent;

  factory DeviceInfo.fromJson(
    String id,
    Map<String, dynamic> json, {
    bool isCurrent = false,
  }) =>
      DeviceInfo(
        id: id,
        name: (json['name'] as String?) ?? '',
        platform: (json['platform'] as String?) ?? 'unknown',
        model: json['model'] as String?,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
        lastSeenAtMs: (json['lastSeenAtMs'] as num?)?.toInt() ?? 0,
        revoked: json['revoked'] == true,
        fcmToken: json['fcmToken'] as String?,
        fcmTokenAtMs: (json['fcmTokenAtMs'] as num?)?.toInt(),
        isCurrent: isCurrent,
      );

  /// The doc as the app writes it. `revoked` is included only on CREATE (the
  /// rules demand `revoked == false` there and forbid changing it after) —
  /// see [DeviceRegistry.registerThisDevice].
  Map<String, dynamic> toJson() => {
        'name': name,
        'platform': platform,
        if (model != null) 'model': model,
        'createdAtMs': createdAtMs,
        'lastSeenAtMs': lastSeenAtMs,
        'revoked': revoked,
      };

  DeviceInfo copyWith({bool? isCurrent}) => DeviceInfo(
        id: id,
        name: name,
        platform: platform,
        model: model,
        createdAtMs: createdAtMs,
        lastSeenAtMs: lastSeenAtMs,
        revoked: revoked,
        fcmToken: fcmToken,
        fcmTokenAtMs: fcmTokenAtMs,
        isCurrent: isCurrent ?? this.isCurrent,
      );
}

/// What this device calls itself in somebody's device list.
class DeviceDescription {
  const DeviceDescription({
    required this.name,
    required this.platform,
    this.model,
  });

  final String name;
  final String platform;
  final String? model;
}

/// Reads the human name of THIS device — "Nikita's iPhone", "MacBook Pro",
/// "Chrome on macOS". Every platform channel is best-effort: a plugin that
/// isn't there (tests, an unsupported build) falls back to the platform name
/// rather than failing the sign-in that asked for it.
Future<DeviceDescription> describeThisDevice([DeviceInfoPlugin? plugin]) async {
  final info = plugin ?? DeviceInfoPlugin();
  try {
    if (kIsWeb) {
      final web = await info.webBrowserInfo;
      final browser = web.browserName.name;
      final os = _webOsName(web.platform ?? '');
      final pretty = browser.isEmpty
          ? 'Browser'
          : '${browser[0].toUpperCase()}${browser.substring(1)}';
      return DeviceDescription(
        name: os == null ? pretty : '$pretty on $os',
        platform: 'web',
        model: web.userAgent,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        final ios = await info.iosInfo;
        // iOS 16+ hands out the generic model name unless the app carries the
        // user-assigned-device-name entitlement — either way it reads fine.
        return DeviceDescription(
          name: ios.name.isNotEmpty ? ios.name : ios.model,
          platform: 'ios',
          model: ios.utsname.machine,
        );
      case TargetPlatform.macOS:
        final mac = await info.macOsInfo;
        return DeviceDescription(
          name: mac.computerName.isNotEmpty ? mac.computerName : 'Mac',
          platform: 'macos',
          model: mac.model,
        );
      case TargetPlatform.android:
        final android = await info.androidInfo;
        final brand = android.manufacturer.trim();
        final model = android.model.trim();
        final name = [
          if (brand.isNotEmpty) '${brand[0].toUpperCase()}${brand.substring(1)}',
          if (model.isNotEmpty) model,
        ].join(' ').trim();
        return DeviceDescription(
          name: name.isEmpty ? 'Android device' : name,
          platform: 'android',
          model: model.isEmpty ? null : model,
        );
      default:
        return DeviceDescription(
          name: defaultTargetPlatform.name,
          platform: defaultTargetPlatform.name.toLowerCase(),
        );
    }
  } catch (e) {
    debugPrint('device description unavailable: $e');
    return DeviceDescription(
      name: kIsWeb ? 'Browser' : defaultTargetPlatform.name,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
    );
  }
}

String? _webOsName(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('mac')) return 'macOS';
  if (p.contains('win')) return 'Windows';
  if (p.contains('linux')) return 'Linux';
  if (p.contains('iphone') || p.contains('ipad')) return 'iOS';
  if (p.contains('android')) return 'Android';
  return null;
}

/// The account's device list, `users/{uid}/devices`. Constructed with a null
/// [FirebaseFirestore] wherever Firebase isn't (local mode, Windows/Linux,
/// tests) — then every call is a no-op and every stream is empty, so the
/// callers need no platform branches.
class DeviceRegistry {
  DeviceRegistry({
    required FirebaseFirestore? db,
    required this.deviceId,
    Future<DeviceDescription> Function()? describe,
  })  : _db = db,
        _describe = describe ?? describeThisDevice;

  final FirebaseFirestore? _db;

  /// This device's stable id (`LocalStore.deviceId()`).
  final String deviceId;

  final Future<DeviceDescription> Function() _describe;

  CollectionReference<Map<String, dynamic>>? _devices(String uid) =>
      _db?.collection('users/$uid/devices');

  /// Writes (or freshens) THIS device's doc under [uid]. `revoked: false` is
  /// only ever sent on the create path: the rules demand it there and forbid
  /// it changing later, so an update that merged it in would be rejected —
  /// and would be a revocation-laundering hole if it weren't.
  ///
  /// Returns whether the doc actually landed. Callers memoize registration
  /// on SUCCESS ONLY: at boot this can run before the account slot's session
  /// has restored, so the write goes through the DEFAULT (unauthenticated)
  /// handle and the rules deny it — memoizing that failure left the account
  /// with no device doc for the whole app run, the Security list with an
  /// orphan row, and the "This device" pill with nothing to match.
  Future<bool> registerThisDevice(String uid) async {
    final devices = _devices(uid);
    if (devices == null) return false;
    final ref = devices.doc(deviceId);
    final description = await _describe();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final existing = await ref.get();
      if (existing.exists) {
        await ref.update({
          'name': description.name,
          'platform': description.platform,
          if (description.model != null) 'model': description.model,
          'lastSeenAtMs': now,
        });
        return true;
      }
      await ref.set({
        'name': description.name,
        'platform': description.platform,
        if (description.model != null) 'model': description.model,
        'createdAtMs': now,
        'lastSeenAtMs': now,
        'revoked': false,
      });
      return true;
    } catch (e) {
      // Offline, a not-yet-authenticated handle, or a session revoked out
      // from under us. The guard retries when the handle changes and on its
      // heartbeat; nothing in the app blocks on this.
      debugPrint('device registration failed: $e');
      return false;
    }
  }

  /// Bumps `lastSeenAtMs` — the heartbeat behind an honest "last seen".
  /// A doc that is missing (registration never landed, or the doc was
  /// deleted server-side) is re-registered through [registerThisDevice] —
  /// the only writer that knows to stamp `revoked: false` — instead of
  /// letting `update()` fail silently forever.
  Future<void> touch(String uid) async {
    final devices = _devices(uid);
    if (devices == null) return;
    final ref = devices.doc(deviceId);
    try {
      await ref.update({
        'lastSeenAtMs': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('device touch failed, re-registering: $e');
      await registerThisDevice(uid);
    }
  }

  /// Every device on the account that is still ON the account, newest-seen
  /// first, this device flagged.
  ///
  /// A revoked device's doc STAYS (it is the tombstone that device reads to
  /// sign itself out, and deleting it would let an offline one re-register as
  /// trusted) — but its row goes (#35). The list is where the artist reads
  /// "who can see my tips and my keys", and a headstone for every phone they
  /// ever sold makes that answer harder to read, not more honest. The one
  /// exception is THIS device: if it is revoked and the guard has not signed
  /// it out yet, hiding the row the artist is sitting on would be the lie.
  Stream<List<DeviceInfo>> watchDevices(String uid) {
    final devices = _devices(uid);
    if (devices == null) return Stream.value(const []);
    return devices.snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              DeviceInfo.fromJson(d.id, d.data(), isCurrent: d.id == deviceId))
          .where((device) => !device.revoked || device.isCurrent)
          .toList()
        ..sort((a, b) {
          // This device pins to the top; the rest by recency.
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return b.lastSeenAtMs.compareTo(a.lastSeenAtMs);
        });
      return list;
    });
  }

  /// True once THIS device's doc says revoked — the cooperative signal the
  /// app honours by signing itself out. A doc that was never created (or is
  /// unreadable because the session is already dead) reads as "not revoked":
  /// the guard must never sign out over a transient miss.
  Stream<bool> watchOwnRevocation(String uid, String deviceId) {
    final db = _db;
    if (db == null) return Stream.value(false);
    return db
        .doc('users/$uid/devices/$deviceId')
        .snapshots()
        .map((snap) => snap.data()?['revoked'] == true)
        .handleError((Object e) {
      debugPrint('revocation watch failed: $e');
    });
  }
}
