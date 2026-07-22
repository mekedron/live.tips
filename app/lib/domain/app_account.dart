/// The device profile that exists on every install: fully local, no cloud
/// account behind it. It is one more row in the account switcher.
const String kLocalAccountId = 'local';

/// How a profile authenticates — [local] is the no-account device profile,
/// the rest are Firebase Auth users.
enum AccountKind { local, anonymous, apple, google }

AccountKind accountKindFromName(String? name) => switch (name) {
      'anonymous' => AccountKind.anonymous,
      'apple' => AccountKind.apple,
      'google' => AccountKind.google,
      _ => AccountKind.local,
    };

/// One profile this device knows: the local no-account profile or a Firebase
/// account that has signed in here at least once. Bands live UNDER a profile
/// — the local profile's bands in SharedPreferences, a cloud profile's in
/// its Firestore subtree.
class AppAccount {
  const AppAccount({
    required this.id,
    required this.name,
    required this.kind,
    this.email,
    this.lastUsedAtMs = 0,
  });

  /// [kLocalAccountId] for the device profile, else the Firebase uid.
  final String id;

  /// The user-chosen ACCOUNT name (not a band name) — what the switcher
  /// shows as the group header.
  final String name;

  final AccountKind kind;

  /// Shown on the collapsed switcher row so "which Google account was that"
  /// answers itself. Null for local/anonymous.
  final String? email;

  final int lastUsedAtMs;

  bool get isLocal => id == kLocalAccountId;

  AppAccount copyWith({
    String? name,
    AccountKind? kind,
    String? email,
    int? lastUsedAtMs,
  }) =>
      AppAccount(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        email: email ?? this.email,
        lastUsedAtMs: lastUsedAtMs ?? this.lastUsedAtMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        if (email != null) 'email': email,
        'lastUsedAtMs': lastUsedAtMs,
      };

  factory AppAccount.fromJson(Map<String, dynamic> json) => AppAccount(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        kind: accountKindFromName(json['kind'] as String?),
        email: json['email'] as String?,
        lastUsedAtMs: (json['lastUsedAtMs'] as num?)?.toInt() ?? 0,
      );

  static AppAccount localProfile() => const AppAccount(
        id: kLocalAccountId,
        name: '',
        kind: AccountKind.local,
      );
}

/// Every profile this device has used plus which one is active. Invariants
/// (kept by the notifier): always contains the local profile, and
/// [activeAccountId] always names an existing entry.
class AccountsDirectory {
  const AccountsDirectory({
    required this.accounts,
    required this.activeAccountId,
  });

  final List<AppAccount> accounts;
  final String activeAccountId;

  AppAccount get active => accounts.firstWhere(
        (a) => a.id == activeAccountId,
        orElse: AppAccount.localProfile,
      );

  bool contains(String id) => accounts.any((a) => a.id == id);

  AccountsDirectory withActive(String id) =>
      AccountsDirectory(accounts: accounts, activeAccountId: id);

  /// Adds or replaces the entry with [account]'s id.
  AccountsDirectory withAccount(AppAccount account) => AccountsDirectory(
        accounts: [
          for (final a in accounts)
            if (a.id != account.id) a,
          account,
        ],
        activeAccountId: activeAccountId,
      );

  AccountsDirectory withoutAccount(String id) {
    if (id == kLocalAccountId) return this; // the local profile is permanent
    return AccountsDirectory(
      accounts: [
        for (final a in accounts)
          if (a.id != id) a,
      ],
      activeAccountId: activeAccountId == id ? kLocalAccountId : activeAccountId,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeAccountId': activeAccountId,
        'accounts': [for (final a in accounts) a.toJson()],
      };

  factory AccountsDirectory.fromJson(Map<String, dynamic> json) {
    final accounts = [
      if (json['accounts'] is List)
        for (final a in json['accounts'] as List)
          if (a is Map) AppAccount.fromJson(Map<String, dynamic>.from(a)),
    ];
    if (!accounts.any((a) => a.isLocal)) {
      accounts.insert(0, AppAccount.localProfile());
    }
    final active = json['activeAccountId'] as String?;
    return AccountsDirectory(
      accounts: accounts,
      activeAccountId:
          active != null && accounts.any((a) => a.id == active)
              ? active
              : kLocalAccountId,
    );
  }

  static AccountsDirectory initial() => AccountsDirectory(
        accounts: [AppAccount.localProfile()],
        activeAccountId: kLocalAccountId,
      );
}

/// The one-account-per-email invariant, applied to the directory: given that
/// [winner] provably holds its email, every OTHER entry claiming the same
/// email is a corpse, and this names them.
///
/// The Firebase project refuses a second account under an email that already
/// has one (the app handles `auth/account-exists-with-different-credential`,
/// which only exists under that setting). So a signable account owns its email
/// outright — and a directory entry sharing [winner]'s email under a different
/// uid can only be an account that was DELETED (here or on another device) and
/// re-created under the same address. Its "Session ended — selecting it signs
/// in again" row is a promise the deleted uid cannot keep: the provider
/// resolves the email to the new uid, the artist lands in the other row's
/// account, and the corpse stays (#73).
///
/// One rule, two enforcement points — [AuthController._adopt] when the proof
/// is a sign-in that just succeeded, and the boot heal (healEmailTwinsAtBoot)
/// for devices already carrying the twin. Shared for the reason
/// forgetCloudAccountOnDevice is: two paths holding their own copy of a rule
/// is how they drift apart.
///
/// Conservative on purpose: emails compare case-insensitively, a null or
/// empty email never matches (guest accounts and the local profile are
/// untouchable here), and an Apple private-relay address differs from the
/// real one — so an Apple row and a Google row usually do not pair. When they
/// do, the invariant above still holds and purging is still right.
List<AppAccount> staleEmailTwins(AppAccount winner, List<AppAccount> accounts) {
  final email = winner.email?.toLowerCase();
  if (email == null || email.isEmpty) return const [];
  return [
    for (final a in accounts)
      if (!a.isLocal && a.id != winner.id && a.email?.toLowerCase() == email)
        a,
  ];
}
