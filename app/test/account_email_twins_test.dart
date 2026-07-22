import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/account_sessions.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/migrations.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A slot [AuthService]: "signing in with a provider" signs the slot's mock
/// auth in and reports the scripted user — the shape a real Google/Apple
/// flow leaves a slot in (same harness as multi_account_switching_test).
class _SlotAuthService extends AuthService {
  _SlotAuthService(this._mock, this.user) : super(_mock);

  final MockFirebaseAuth _mock;
  final AuthUser user;

  Future<AuthUser?> _signIn() async {
    await _mock.signInWithCustomToken('t');
    return user;
  }

  @override
  Future<AuthUser?> signInWithGoogle({bool link = false}) => _signIn();

  @override
  Future<AuthUser?> signInWithApple({bool link = false}) => _signIn();
}

/// The one-account-per-email invariant (#73): an account deleted and
/// re-created under the same email gets a NEW uid, so the old uid's
/// directory row is a corpse — "Session ended — selecting it signs in
/// again" is a promise a deleted uid cannot keep. [staleEmailTwins] names
/// the corpses; _adopt and healEmailTwinsAtBoot purge them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const local = AppAccount(id: kLocalAccountId, name: '', kind: AccountKind.local);
  const winner = AppAccount(
      id: 'uid_new',
      name: 'Nikita',
      kind: AccountKind.google,
      email: 'ana@example.com',
      lastUsedAtMs: 200);

  group('staleEmailTwins', () {
    test('same email under a different uid is a twin; the winner is not',
        () {
      const corpse = AppAccount(
          id: 'uid_old',
          name: 'Mikita',
          kind: AccountKind.google,
          email: 'ana@example.com',
          lastUsedAtMs: 100);
      final twins = staleEmailTwins(winner, [local, corpse, winner]);
      expect(twins, [corpse]);
    });

    test('emails compare case-insensitively', () {
      const corpse = AppAccount(
          id: 'uid_old',
          name: 'Mikita',
          kind: AccountKind.google,
          email: 'Ana@Example.COM');
      expect(staleEmailTwins(winner, [corpse, winner]), [corpse]);
    });

    test('a different provider with the SAME email still pairs', () {
      // Apple private-relay addresses usually differ from the real one, so
      // an Apple row and a Google row usually do NOT match — but when the
      // emails are equal, one-account-per-email holds regardless of kind.
      const appleTwin = AppAccount(
          id: 'uid_apple',
          name: 'Ana',
          kind: AccountKind.apple,
          email: 'ana@example.com');
      expect(staleEmailTwins(winner, [appleTwin, winner]), [appleTwin]);
    });

    test('a null email never matches anything: guests are untouchable', () {
      const guest = AppAccount(
          id: 'uid_guest', name: 'Guest', kind: AccountKind.anonymous);
      const anonWinner = AppAccount(
          id: 'uid_anon', name: 'Also guest', kind: AccountKind.anonymous);
      // A winner without an email claims nothing…
      expect(staleEmailTwins(anonWinner, [guest, winner, anonWinner]),
          isEmpty);
      // …and an entry without an email can never be claimed.
      expect(staleEmailTwins(winner, [guest, local, winner]), isEmpty);
    });

    test('the local profile is never a twin', () {
      // Belt and braces: local has a null email anyway, but the rule also
      // refuses it by id — the local profile is permanent.
      expect(staleEmailTwins(winner, [local, winner]), isEmpty);
    });

    test('a different email is not a twin', () {
      const other = AppAccount(
          id: 'uid_ben',
          name: 'Ben',
          kind: AccountKind.google,
          email: 'ben@example.com');
      expect(staleEmailTwins(winner, [other, winner]), isEmpty);
    });
  });

  group('healEmailTwinsAtBoot', () {
    const corpse = AppAccount(
        id: 'uid_old',
        name: 'Mikita',
        kind: AccountKind.google,
        email: 'Ana@Example.com',
        lastUsedAtMs: 100);

    test('the reporter\'s device: two dead rows, the later one wins',
        () async {
      final store = await seededStore();
      await store.saveAccountsDirectory(const AccountsDirectory(
        accounts: [local, corpse, winner],
        activeAccountId: kLocalAccountId,
      ));
      await store.saveActiveCloudBand('uid_old', 'band_old');
      final removed = <String>[];

      await healEmailTwinsAtBoot(store,
          isAlive: (_) => false, removeSession: (uid) async => removed.add(uid));

      final healed = store.readAccountsDirectory()!;
      expect(healed.contains('uid_old'), isFalse,
          reason: 'the deleted uid\'s row must not survive the boot');
      expect(healed.contains('uid_new'), isTrue);
      expect(healed.contains(kLocalAccountId), isTrue);
      expect(store.readActiveCloudBand('uid_old'), isNull,
          reason: 'the corpse\'s band pointer goes with its row');
      expect(removed, isEmpty,
          reason: 'no slot was alive, so none is removed');
    });

    test('a live session beats recency when picking the winner', () async {
      final store = await seededStore();
      // The OLD row was used later — but only the new uid can still be
      // served, and serviceability is the closest thing to sign-in proof
      // boot has.
      await store.saveAccountsDirectory(AccountsDirectory(
        accounts: [
          local,
          corpse.copyWith(lastUsedAtMs: 900),
          winner,
        ],
        activeAccountId: kLocalAccountId,
      ));

      await healEmailTwinsAtBoot(store,
          isAlive: (uid) => uid == 'uid_new', removeSession: (_) async {});

      final healed = store.readAccountsDirectory()!;
      expect(healed.contains('uid_old'), isFalse);
      expect(healed.contains('uid_new'), isTrue);
    });

    test('a zombie loser slot is removed, not just its row', () async {
      final store = await seededStore();
      await store.saveAccountsDirectory(const AccountsDirectory(
        accounts: [local, corpse, winner],
        activeAccountId: kLocalAccountId,
      ));
      final removed = <String>[];

      // Both slots restored "alive" — Firebase restores from local
      // persistence, so a deleted uid's slot survives until the server
      // refuses its token. Recency breaks the tie; the loser's slot goes.
      await healEmailTwinsAtBoot(store,
          isAlive: (_) => true, removeSession: (uid) async => removed.add(uid));

      expect(removed, ['uid_old']);
      expect(store.readAccountsDirectory()!.contains('uid_old'), isFalse);
    });

    test('dropping an ACTIVE loser lands the device on the local profile',
        () async {
      final store = await seededStore();
      await store.saveAccountsDirectory(const AccountsDirectory(
        accounts: [local, corpse, winner],
        activeAccountId: 'uid_old',
      ));

      await healEmailTwinsAtBoot(store,
          isAlive: (_) => false, removeSession: (_) async {});

      expect(store.readAccountsDirectory()!.activeAccountId, kLocalAccountId,
          reason: 'the active pointer must never name a dropped row');
    });

    test('every corpse under one email goes, however many', () async {
      final store = await seededStore();
      await store.saveAccountsDirectory(AccountsDirectory(
        accounts: [
          local,
          corpse,
          const AppAccount(
              id: 'uid_older',
              name: 'Mikita 2',
              kind: AccountKind.google,
              email: 'ana@example.com',
              lastUsedAtMs: 150),
          winner,
        ],
        activeAccountId: kLocalAccountId,
      ));

      await healEmailTwinsAtBoot(store,
          isAlive: (_) => false, removeSession: (_) async {});

      final healed = store.readAccountsDirectory()!;
      expect(healed.contains('uid_old'), isFalse);
      expect(healed.contains('uid_older'), isFalse);
      expect(healed.contains('uid_new'), isTrue);
    });

    test('distinct emails and email-less guests are left exactly alone',
        () async {
      final store = await seededStore();
      const untouched = AccountsDirectory(
        accounts: [
          local,
          winner,
          AppAccount(
              id: 'uid_ben',
              name: 'Ben',
              kind: AccountKind.apple,
              email: 'ben@example.com'),
          AppAccount(
              id: 'uid_guest', name: 'Guest', kind: AccountKind.anonymous),
          AppAccount(
              id: 'uid_guest2', name: 'Guest 2', kind: AccountKind.anonymous),
        ],
        activeAccountId: 'uid_ben',
      );
      await store.saveAccountsDirectory(untouched);

      await healEmailTwinsAtBoot(store,
          isAlive: (_) => false, removeSession: (_) async {});

      final after = store.readAccountsDirectory()!;
      expect([for (final a in after.accounts) a.id],
          [for (final a in untouched.accounts) a.id]);
      expect(after.activeAccountId, 'uid_ben');
    });

    test('no directory at all is a no-op', () async {
      final store = await seededStore();
      await healEmailTwinsAtBoot(store,
          isAlive: (_) => false, removeSession: (_) async {});
      expect(store.readAccountsDirectory(), isNull);
    });
  });

  group('AuthController._adopt', () {
    test(
        'signing in as the re-created account purges the dead twin — and '
        'only it', () async {
      final store = await seededStore();
      var slots = <String, String>{};
      // Slot n hosts the nth sign-in: the OLD Ana (the account that will be
      // deleted elsewhere), Ben (a bystander), then the NEW Ana — the same
      // email under a fresh uid, which is what deleting and re-creating the
      // account produces.
      final users = [
        const AuthUser(
            uid: 'uid_old',
            kind: AccountKind.google,
            displayName: 'Mikita',
            email: 'Ana@Example.com'),
        const AuthUser(
            uid: 'uid_ben',
            kind: AccountKind.apple,
            displayName: 'Ben',
            email: 'ben@example.com'),
        const AuthUser(
            uid: 'uid_new',
            kind: AccountKind.google,
            displayName: 'Nikita',
            email: 'ana@example.com'),
      ];
      final auths = <String, MockFirebaseAuth>{};
      final userByAuth = <FirebaseAuth, AuthUser>{};

      final sessions = AccountSessions(
        readSlots: () => slots,
        saveSlots: (next) async => slots = Map.of(next),
        openApp: (name) async {
          final auth = auths.putIfAbsent(name, () {
            final slotIndex = auths.length;
            final mock = MockFirebaseAuth(
                mockUser: MockUser(
                    uid: users[slotIndex].uid,
                    displayName: users[slotIndex].displayName,
                    email: users[slotIndex].email));
            userByAuth[mock] = users[slotIndex];
            return mock;
          });
          return SessionHandles(
              auth: auth, firestore: FakeFirebaseFirestore());
        },
        closeApp: (_) async {},
      );

      final container = ProviderContainer(overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        accountSessionsProvider.overrideWithValue(sessions),
        slotAuthServiceFactoryProvider.overrideWith(
            (ref) => (auth) => _SlotAuthService(
                auth as MockFirebaseAuth, userByAuth[auth]!)),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // The old account signs in, remembers a band, and stays alive — the
      // zombie state a deleted uid's slot is in until the server refuses it.
      final old = await controller.signInWithGoogle();
      expect(old?.uid, 'uid_old');
      await store.saveActiveCloudBand('uid_old', 'band_old');

      // A bystander with a different email — must survive everything below.
      final ben = await controller.signInWithApple();
      expect(ben?.uid, 'uid_ben');

      // The re-created account: same email (case differs — Google reports
      // whatever casing it likes), NEW uid. This sign-in is PROOF under
      // one-account-per-email that uid_old no longer holds the address.
      final fresh = await controller.signInWithGoogle();
      expect(fresh?.uid, 'uid_new');

      final directory = container.read(accountsDirectoryProvider);
      expect(directory.contains('uid_old'), isFalse,
          reason: 'the dead twin\'s row must go the moment its email is '
              're-proven under a new uid');
      expect(directory.contains('uid_ben'), isTrue,
          reason: 'a dead-or-alive row under a DIFFERENT email is exactly '
              'the case the session-ended row exists for — untouched');
      expect(directory.contains('uid_new'), isTrue);
      expect(directory.activeAccountId, 'uid_new',
          reason: 'the purge runs after setActive and must not bounce it');

      expect(sessions.isAlive('uid_old'), isFalse,
          reason: 'the zombie slot goes with the row');
      expect(sessions.isAlive('uid_ben'), isTrue);
      expect(sessions.isAlive('uid_new'), isTrue);
      expect(slots.containsKey('uid_old'), isFalse,
          reason: 'the persisted slot must not restore the corpse next boot');

      expect(store.readActiveCloudBand('uid_old'), isNull,
          reason: 'the corpse\'s band pointer goes with it');
      expect(store.readAccountsDirectory()!.contains('uid_old'), isFalse,
          reason: 'the purge must be persisted, not just in-memory');
    });

    test('a guest row survives every sign-in: null emails never pair',
        () async {
      final store = await seededStore();
      var slots = <String, String>{};
      final users = [
        const AuthUser(
            uid: 'uid_new',
            kind: AccountKind.google,
            displayName: 'Nikita',
            email: 'ana@example.com'),
      ];
      final auths = <String, MockFirebaseAuth>{};
      final userByAuth = <FirebaseAuth, AuthUser>{};
      final sessions = AccountSessions(
        readSlots: () => slots,
        saveSlots: (next) async => slots = Map.of(next),
        openApp: (name) async {
          final auth = auths.putIfAbsent(name, () {
            final slotIndex = auths.length;
            final mock = MockFirebaseAuth(
                mockUser: MockUser(
                    uid: users[slotIndex].uid,
                    displayName: users[slotIndex].displayName,
                    email: users[slotIndex].email));
            userByAuth[mock] = users[slotIndex];
            return mock;
          });
          return SessionHandles(
              auth: auth, firestore: FakeFirebaseFirestore());
        },
        closeApp: (_) async {},
      );
      final container = ProviderContainer(overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        accountSessionsProvider.overrideWithValue(sessions),
        slotAuthServiceFactoryProvider.overrideWith(
            (ref) => (auth) => _SlotAuthService(
                auth as MockFirebaseAuth, userByAuth[auth]!)),
      ]);
      addTearDown(container.dispose);

      // An explicit guest account already on the device — no email, no
      // credential, and nothing a Google sign-in can prove about it.
      await container.read(accountsDirectoryProvider.notifier).upsert(
          const AppAccount(
              id: 'uid_guest', name: 'Guest', kind: AccountKind.anonymous));

      final fresh = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      expect(fresh?.uid, 'uid_new');

      expect(container.read(accountsDirectoryProvider).contains('uid_guest'),
          isTrue,
          reason: 'a guest has a null email and must never be purged');
    });
  });
}
