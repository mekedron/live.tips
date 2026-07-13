import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/repository/account_data_repository.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// An [AuthService] whose userChanges stream is live, like the real one: a
/// sign-in anywhere — including the relay's out-of-band one — pushes the new
/// user at every listener. That is the whole hazard being tested.
class StreamingAuthService extends AuthService {
  StreamingAuthService() : super(null);

  final _users = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  var anonymousSignIns = 0;

  @override
  bool get available => true;

  @override
  Stream<AuthUser?> userChanges() => _users.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<AuthUser?> signInAnonymously() async {
    anonymousSignIns++;
    return _emit(AuthUser(
        uid: 'uid_anon_$anonymousSignIns', kind: AccountKind.anonymous));
  }

  @override
  Future<AuthUser?> signInWithGoogle({bool link = false}) async => _emit(
        const AuthUser(
            uid: 'uid_google', kind: AccountKind.google, displayName: 'Casey'),
      );

  AuthUser? _emit(AuthUser user) {
    _current = user;
    _users.add(user);
    return user;
  }
}

Future<ProviderContainer> _container(StreamingAuthService auth) async {
  final store = await seededStore();
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(store),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(auth),
    // Firebase is fully present — the isolation must not depend on its
    // absence.
    firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the relay signs in anonymously WITHOUT creating an account', () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);
    // Wake the controller so its userChanges listener is attached — the
    // whole point is that it hears the transport sign-in and ignores it.
    expect(container.read(authControllerProvider).user, isNull);
    final directoryBefore = container.read(accountsDirectoryProvider);

    final uid = await container.read(relayAuthProvider).ensureRelayUid();
    await settle();

    expect(uid, 'uid_anon_1', reason: 'the relay got its transport identity');
    expect(auth.anonymousSignIns, 1);

    // …and nothing about the app's idea of "who is signed in" moved.
    expect(container.read(authControllerProvider).user, isNull,
        reason: 'a transport uid is not an account');
    final directory = container.read(accountsDirectoryProvider);
    expect(directory.accounts.map((a) => a.id),
        directoryBefore.accounts.map((a) => a.id),
        reason: 'no directory entry — it must never reach the switcher');
    expect(directory.activeAccountId, kLocalAccountId,
        reason: 'the active profile is untouched');
    expect(container.read(accountDataRepositoryProvider),
        isA<LocalStoreRepository>(),
        reason: 'the local profile keeps its local repository');
  });

  test('a jar created on a transport uid is never pinned to it', () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);
    final relayAuth = container.read(relayAuthProvider);

    await relayAuth.ensureRelayUid();
    expect(relayAuth.ownsJars, isFalse,
        reason: 'a throwaway uid must not become the jar ownerUid');
  });

  test('concurrent relay calls mint ONE transport identity', () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);
    final relayAuth = container.read(relayAuthProvider);

    final uids = await Future.wait([
      relayAuth.ensureRelayUid(),
      relayAuth.ensureRelayUid(),
      relayAuth.ensureRelayUid(),
    ]);

    expect(auth.anonymousSignIns, 1, reason: 'no stranded uids');
    expect(uids, ['uid_anon_1', 'uid_anon_1', 'uid_anon_1']);
  });

  test('an already signed-in account is reused as the transport identity',
      () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);

    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await settle();

    final relayAuth = container.read(relayAuthProvider);
    expect(await relayAuth.ensureRelayUid(), 'uid_google');
    expect(auth.anonymousSignIns, 0, reason: 'no need for a second identity');
    expect(relayAuth.ownsJars, isTrue, reason: 'a real account owns its jar');
  });

  test('an EXPLICIT sign-in still becomes an account (the guard is not a wall)',
      () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);

    final user = await container
        .read(authControllerProvider.notifier)
        .signInAnonymously();
    await settle();

    expect(user, isNotNull);
    expect(container.read(authControllerProvider).user?.uid, user!.uid,
        reason: 'the artist asked for this one');
    final directory = container.read(accountsDirectoryProvider);
    expect(directory.contains(user.uid), isTrue);
    expect(directory.activeAccountId, user.uid);
  });

  test('a transport sign-in after an explicit one leaves the account alone',
      () async {
    final auth = StreamingAuthService();
    final container = await _container(auth);

    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await settle();
    // The relay reuses the signed-in user — but even a stray userChanges
    // replay of it must not disturb the account.
    await container.read(relayAuthProvider).ensureRelayUid();
    await settle();

    expect(container.read(authControllerProvider).user?.uid, 'uid_google');
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        'uid_google');
  });
}
