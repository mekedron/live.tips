/// A sign-in that handed the browser to the auth bridge and expects to come
/// back.
///
/// On the web the app does NOT open a popup, and it does not run the Firebase
/// redirect flow on its own origin either (Safari partitions the storage that
/// flow needs — see auth_bridge.dart). It navigates away to the bridge page on
/// auth.live.tips, which tears the whole Flutter app down. Everything the
/// return leg needs — whether it was a LINK (an anonymous account upgrading
/// itself, not a new account), where the user was, the nonce that pairs the
/// bridge's answer with this attempt, and the onboarding work in progress —
/// must therefore survive a full page reload, so it is written to local
/// storage BEFORE the navigation and consumed exactly once on the way back.
class PendingRedirect {
  const PendingRedirect({
    required this.appName,
    required this.provider,
    required this.link,
    this.origin = RedirectOrigin.app,
    this.prelude = 0,
    this.draft,
    this.uid,
    this.startedAtMs = 0,
    this.nonce = '',
  });

  /// The [FirebaseApp] name the sign-in was started on — a fresh slot for a
  /// new account, the account's own app for a link. The custom token the
  /// bridge brings back is redeemed on this same app, so the new session lands
  /// in the slot that was reserved for it.
  final String appName;

  /// 'google' | 'apple' — kept for diagnostics and for a retry.
  final String provider;

  /// True when this was `linkWithRedirect`: the CURRENT (anonymous) user is
  /// upgrading in place. Getting this wrong on the way back would open a new
  /// slot for a uid that already has a session and strand the guest account.
  final bool link;

  /// For a link: the uid being upgraded (a sanity check on the return leg).
  final String? uid;

  /// Where the user was when they tapped sign-in, so the return leg can put
  /// them back rather than dumping them on the app root.
  final RedirectOrigin origin;

  /// The onboarding step-indicator prelude counter (in-memory state that the
  /// reload would otherwise reset — see OnboardingPreludeNotifier).
  final int prelude;

  /// The in-flight onboarding draft, serialized. In-memory only in the running
  /// app; without this a redirect started mid-onboarding would silently eat a
  /// half-filled band setup.
  final Map<String, dynamic>? draft;

  final int startedAtMs;

  /// The `state` the bridge request carried (see auth_bridge.dart). Only a
  /// response echoing this exact value answers THIS attempt; anything else —
  /// a stale fragment, a crafted one — is ignored.
  final String nonce;

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'provider': provider,
        'link': link,
        if (uid != null) 'uid': uid,
        'origin': origin.name,
        'prelude': prelude,
        if (draft != null) 'draft': draft,
        'startedAtMs': startedAtMs,
        'nonce': nonce,
      };

  static PendingRedirect fromJson(Map<String, dynamic> json) => PendingRedirect(
        appName: json['appName'] as String,
        provider: json['provider'] as String? ?? 'google',
        link: json['link'] as bool? ?? false,
        uid: json['uid'] as String?,
        origin: RedirectOrigin.values
                .where((o) => o.name == json['origin'])
                .firstOrNull ??
            RedirectOrigin.app,
        prelude: (json['prelude'] as num?)?.toInt() ?? 0,
        draft: json['draft'] == null
            ? null
            : Map<String, dynamic>.from(json['draft'] as Map),
        startedAtMs: (json['startedAtMs'] as num?)?.toInt() ?? 0,
        nonce: json['nonce'] as String? ?? '',
      );
}

/// Where a sign-in was started from — the only thing the return leg has to go
/// on, since the navigation stack does not survive the reload.
enum RedirectOrigin {
  /// The first-run account question (AccountStepScreen): onboarding continues
  /// on the way back, at the naming step or the band setup.
  onboarding,

  /// Settings, the account switcher, the sign-in sheet, a re-auth: land back
  /// on the Settings tab.
  settings,

  /// Anywhere else: the app root is fine.
  app,
}
