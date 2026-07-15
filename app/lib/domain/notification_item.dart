/// The bell feed: what arrived while no set was running.
///
/// One entry per tip the server delivered off-session — written ONLY by the
/// tip paths in Firebase Functions (functions/src/notifications.ts), read
/// here. The doc id is the tip's own id, so an entry can always be traced
/// back to the money it announces; the feed itself is capped server-side and
/// is never the donation history (relayTips is).
library;

enum NotificationKind { tip, songRequest }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.bandId,
    required this.amountMinor,
    required this.currency,
    this.name,
    this.songTitle,
    required this.createdAtMs,
  });

  /// == the tip's doc id (relay_… / cs_… / ch_…).
  final String id;
  final NotificationKind kind;
  final String bandId;
  final int amountMinor;

  /// Lowercase ISO-4217 — the currency the fan actually paid in.
  final String currency;

  /// The fan's name, absent when they left none (never '').
  final String? name;

  /// The bought song on request tips (#64).
  final String? songTitle;
  final int createdAtMs;

  factory NotificationItem.fromJson(String id, Map<String, dynamic> json) =>
      NotificationItem(
        id: id,
        kind: json['kind'] == 'songRequest'
            ? NotificationKind.songRequest
            : NotificationKind.tip,
        bandId: (json['bandId'] as String?) ?? '',
        amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
        currency: (json['currency'] as String?) ?? 'eur',
        name: json['name'] as String?,
        songTitle: json['songTitle'] as String?,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}

/// users/{uid}/settings/notifications — the account's notification choices,
/// synced across its devices like every other settings doc.
///
/// The kind flags are OPT-OUT and default to true: the real opt-in is
/// granting OS permission on a device (without a token there is nothing to
/// send to), and the server treats an absent doc exactly like this default
/// (functions/src/notifications.ts agrees — change one, change both).
/// [lastSeenAtMs] is the bell's mark-all-read watermark: everything at or
/// before it counts as seen, on every device at once.
class NotificationPrefs {
  const NotificationPrefs({
    this.tips = true,
    this.songRequests = true,
    this.lastSeenAtMs = 0,
  });

  final bool tips;
  final bool songRequests;
  final int lastSeenAtMs;

  factory NotificationPrefs.fromJson(Map<String, dynamic>? json) =>
      NotificationPrefs(
        tips: json?['tips'] != false,
        songRequests: json?['songRequests'] != false,
        lastSeenAtMs: (json?['lastSeenAtMs'] as num?)?.toInt() ?? 0,
      );

  NotificationPrefs copyWith({bool? tips, bool? songRequests, int? lastSeenAtMs}) =>
      NotificationPrefs(
        tips: tips ?? this.tips,
        songRequests: songRequests ?? this.songRequests,
        lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
      );
}
