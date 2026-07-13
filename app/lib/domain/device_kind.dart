/// What this INSTALL is for — a property of the device, not of any account.
///
/// A performer's own phone, a shared tablet living in a venue, and a demo
/// kiosk have different trust models, and the difference must survive
/// sign-ins and sign-outs: whoever's account is on the screen, a venue
/// tablet stays a venue tablet. That is why this is chosen before the
/// account question in onboarding, and why changing it wipes the device —
/// data written under one trust model must never be inherited by another.
enum DeviceKind {
  /// The artist's own device: today's flow, unchanged.
  performer,

  /// A shared device (bar tablet). Artists sign in from their own phones,
  /// sessions expire after 12 hours, and ending a session scrubs the
  /// account's cached secrets from this device.
  venue,

  /// Demo play — simulated tips, no real account.
  demo,
}

DeviceKind? deviceKindFromName(String? name) => switch (name) {
      'performer' => DeviceKind.performer,
      'venue' => DeviceKind.venue,
      'demo' => DeviceKind.demo,
      _ => null,
    };

/// One artist's stint on a venue device: whose account, and the instant it
/// dies. The deadline is fixed at sign-in and persisted immediately — a
/// restart re-reads it, so nothing a tablet does can stretch the 12 hours.
class VenueSession {
  const VenueSession({
    required this.uid,
    required this.startedAtMs,
    required this.expiresAtMs,
    this.identityConfirmed = false,
  });

  final String uid;
  final int startedAtMs;
  final int expiresAtMs;

  /// Whether the artist has looked at "signed in as …" and said "that's me".
  /// Kept on the persisted record so a restart mid-confirmation asks again
  /// rather than waving a possibly-wrong account through.
  final bool identityConfirmed;

  bool expiredAt(DateTime now) =>
      now.millisecondsSinceEpoch >= expiresAtMs;

  VenueSession copyWith({bool? identityConfirmed}) => VenueSession(
        uid: uid,
        startedAtMs: startedAtMs,
        expiresAtMs: expiresAtMs,
        identityConfirmed: identityConfirmed ?? this.identityConfirmed,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'startedAtMs': startedAtMs,
        'expiresAtMs': expiresAtMs,
        'identityConfirmed': identityConfirmed,
      };

  factory VenueSession.fromJson(Map<String, dynamic> json) => VenueSession(
        uid: json['uid'] as String,
        startedAtMs: (json['startedAtMs'] as num?)?.toInt() ?? 0,
        expiresAtMs: (json['expiresAtMs'] as num?)?.toInt() ?? 0,
        identityConfirmed: json['identityConfirmed'] == true,
      );
}
