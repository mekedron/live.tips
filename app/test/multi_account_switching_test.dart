import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/account_sessions.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/repository/firestore_repository.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A slot [AuthService]: "signing in with a provider" signs the slot's mock
/// auth in and reports the scripted user — the shape a real Google/Apple
/// flow leaves a slot in.
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

/// The whole point of per-account apps: two accounts signed in at once, a
/// switch is a directory flip, both sessions stay alive, and the repository
/// stack resolves to the ACTIVE account's own Firestore.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two accounts, one-tap switch, both sessions alive, repository follows',
      () async {
    final store = await seededStore();
    var slots = <String, String>{};
    // Slot n hosts the nth sign-in of this test: first Ana, then Ben.
    final users = [
      const AuthUser(
          uid: 'uid_ana',
          kind: AccountKind.google,
          displayName: 'Ana',
          email: 'ana@example.com'),
      const AuthUser(
          uid: 'uid_ben',
          kind: AccountKind.apple,
          displayName: 'Ben',
          email: 'ben@example.com'),
    ];
    final auths = <String, MockFirebaseAuth>{};
    final dbs = <String, FakeFirebaseFirestore>{};
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
        final db = dbs.putIfAbsent(name, FakeFirebaseFirestore.new);
        return SessionHandles(auth: auth, firestore: db);
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

    // Ana signs in — her own app, her own Firestore.
    final ana = await controller.signInWithGoogle();
    expect(ana?.uid, 'uid_ana');
    expect(sessions.isAlive('uid_ana'), isTrue);
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        'uid_ana');
    final dbAna = container.read(firestoreProvider);
    expect(dbAna, same(sessions.sessionFor('uid_ana')!.firestore));

    // Ben signs in — Ana's session is untouched.
    final ben = await controller.signInWithApple();
    expect(ben?.uid, 'uid_ben');
    expect(sessions.isAlive('uid_ana'), isTrue,
        reason: 'adding an account must not disturb the others');
    expect(sessions.isAlive('uid_ben'), isTrue);
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        'uid_ben');
    expect(container.read(firestoreProvider),
        same(sessions.sessionFor('uid_ben')!.firestore));
    final repoBen = container.read(accountDataRepositoryProvider);
    expect(repoBen, isA<FirestoreRepository>());
    expect((repoBen as FirestoreRepository).uid, 'uid_ben');

    // Switching back to Ana is ONE directory flip — no re-auth of any kind.
    await container
        .read(accountsDirectoryProvider.notifier)
        .setActive('uid_ana');
    expect(container.read(firestoreProvider), same(dbAna));
    final repoAna = container.read(accountDataRepositoryProvider);
    expect(repoAna, isA<FirestoreRepository>());
    expect((repoAna as FirestoreRepository).uid, 'uid_ana');
    expect(container.read(authControllerProvider).user?.uid, 'uid_ana');
    expect(sessions.isAlive('uid_ben'), isTrue,
        reason: 'the account switched away from keeps its session');

    // Signing Ana out removes only her slot; Ben remains one tap away.
    await container.read(signOutProvider)();
    expect(sessions.isAlive('uid_ana'), isFalse);
    expect(sessions.isAlive('uid_ben'), isTrue);
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
    // And it takes Ana OFF this device: the switcher must not keep offering
    // the account — and the email address — she deliberately left (#31).
    expect(container.read(accountsDirectoryProvider).contains('uid_ana'),
        isFalse);
    expect(container.read(accountsDirectoryProvider).contains('uid_ben'),
        isTrue,
        reason: 'signing one account out must not touch the others');
  });
}
