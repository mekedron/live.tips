import 'dart:math';

/// One local band/act profile. Everything that makes a band a band — its
/// Stripe key, tip jar, relay jar, settings, history — lives in storage
/// slots namespaced by [id]; this record only names and orders them.
class BandAccount {
  const BandAccount({
    required this.id,
    required this.name,
    required this.createdAtMs,
  });

  /// Stable storage namespace, `acc_<epoch base36><random>`. Never reused.
  final String id;

  /// The band's label in the switcher. Kept in sync with the jars' own
  /// display names on rename/create; empty until the band is named.
  final String name;

  final int createdAtMs;

  static String newId() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = Random().nextInt(0x7fffffff).toRadixString(36);
    return 'acc_$now$rand';
  }

  BandAccount copyWith({String? name}) =>
      BandAccount(id: id, name: name ?? this.name, createdAtMs: createdAtMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAtMs': createdAtMs,
      };

  factory BandAccount.fromJson(Map<String, dynamic> json) => BandAccount(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}

/// The device's list of bands plus which one is active. Invariants (kept by
/// the notifier and the boot migration): never empty, [activeId] always
/// names an existing account.
class AccountsRegistry {
  const AccountsRegistry({required this.accounts, required this.activeId});

  /// Creation order — the switcher lists them in this order.
  final List<BandAccount> accounts;
  final String activeId;

  BandAccount get active => accounts.firstWhere(
        (a) => a.id == activeId,
        orElse: () => accounts.first,
      );

  bool contains(String id) => accounts.any((a) => a.id == id);

  AccountsRegistry withActive(String id) =>
      AccountsRegistry(accounts: accounts, activeId: id);

  AccountsRegistry withAccount(BandAccount account) => AccountsRegistry(
        accounts: [...accounts, account],
        activeId: activeId,
      );

  AccountsRegistry withoutAccount(String id) => AccountsRegistry(
        accounts: [
          for (final a in accounts)
            if (a.id != id) a,
        ],
        activeId: activeId,
      );

  AccountsRegistry withRenamed(String id, String name) => AccountsRegistry(
        accounts: [
          for (final a in accounts)
            if (a.id == id) a.copyWith(name: name) else a,
        ],
        activeId: activeId,
      );

  Map<String, dynamic> toJson() => {
        'activeId': activeId,
        'accounts': [for (final a in accounts) a.toJson()],
      };

  factory AccountsRegistry.fromJson(Map<String, dynamic> json) {
    final accounts = [
      if (json['accounts'] is List)
        for (final a in json['accounts'] as List)
          if (a is Map) BandAccount.fromJson(Map<String, dynamic>.from(a)),
    ];
    return AccountsRegistry(
      accounts: accounts,
      activeId: json['activeId'] as String? ??
          (accounts.isEmpty ? '' : accounts.first.id),
    );
  }
}
