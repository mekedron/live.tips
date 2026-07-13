import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/account_sessions.dart';

/// The slot registry itself: N accounts in N apps, each signed out alone,
/// the cap enforced, and dead slots scrubbed at restore.
void main() {
  late Map<String, String> slots;
  late Map<String, SessionHandles> apps;
  late List<String> closed;

  AccountSessions build({int max = 5}) => AccountSessions(
        readSlots: () => slots,
        saveSlots: (next) async => slots = Map.of(next),
        maxAccounts: max,
        openApp: (name) async => apps.putIfAbsent(
          name,
          () => SessionHandles(
            auth: MockFirebaseAuth(),
            firestore: FakeFirebaseFirestore(),
          ),
        ),
        closeApp: (name) async => closed.add(name),
      );

  setUp(() {
    slots = {};
    apps = {};
    closed = [];
  });

  Future<AccountSession> signIn(AccountSessions sessions, String uid) async {
    final pending = await sessions.begin();
    // Stand in for the provider flow: sign a user into the slot's auth.
    await (pending.auth as MockFirebaseAuth).signInWithCustomToken('t');
    return sessions.commit(pending, uid);
  }

  test('two accounts live in two apps; removing one leaves the other', () async {
    final sessions = build();
    final a = await signIn(sessions, 'uid_a');
    final b = await signIn(sessions, 'uid_b');

    expect(a.appName, isNot(b.appName),
        reason: 'each account gets its own FirebaseApp');
    expect(sessions.isAlive('uid_a'), isTrue);
    expect(sessions.isAlive('uid_b'), isTrue);
    expect(slots, {'uid_a': a.appName, 'uid_b': b.appName});

    await sessions.remove('uid_a');
    expect(sessions.isAlive('uid_a'), isFalse);
    expect(sessions.isAlive('uid_b'), isTrue,
        reason: 'signing one account out must not touch the rest');
    expect(a.auth.currentUser, isNull,
        reason: 'the removed slot was actually signed out');
    expect(b.auth.currentUser, isNotNull);
    expect(slots.keys, ['uid_b']);
    expect(closed, [a.appName]);
  });

  test('the cap refuses a sixth account with a typed exception', () async {
    final sessions = build(max: 2);
    await signIn(sessions, 'uid_a');
    await signIn(sessions, 'uid_b');
    expect(sessions.begin, throwsA(isA<AccountLimitException>()));
  });

  test('signing into an account that already has a slot keeps the slot',
      () async {
    final sessions = build();
    final first = await signIn(sessions, 'uid_a');
    final again = await signIn(sessions, 'uid_a');
    expect(again.appName, first.appName);
    expect(sessions.liveUids, ['uid_a']);
  });

  test('a cancelled sign-in returns its slot to the shelf', () async {
    final sessions = build();
    final pending = await sessions.begin();
    await sessions.abandon(pending);
    expect(closed, [pending.appName]);
    // The next sign-in reuses the freed slot name.
    final next = await sessions.begin();
    expect(next.appName, pending.appName);
  });

  test('restore revives live slots and scrubs dead ones', () async {
    // A previous run left two slots; only uid_a's auth still has its user.
    slots = {'uid_a': 'acct_slot_0', 'uid_b': 'acct_slot_1'};
    apps['acct_slot_0'] = SessionHandles(
      auth: MockFirebaseAuth(
          signedIn: true, mockUser: MockUser(uid: 'uid_a')),
      firestore: FakeFirebaseFirestore(),
    );
    apps['acct_slot_1'] = SessionHandles(
      auth: MockFirebaseAuth(), // token revoked / storage cleared
      firestore: FakeFirebaseFirestore(),
    );

    final sessions = build();
    await sessions.restore();

    expect(sessions.isAlive('uid_a'), isTrue);
    expect(sessions.isAlive('uid_b'), isFalse,
        reason: 'a slot that restored no user has no session to serve');
    expect(slots.keys, ['uid_a'],
        reason: 'the dead mapping is forgotten so it is not retried forever');
  });

  test('the unavailable degenerate refuses politely', () {
    final sessions = AccountSessions.unavailable();
    expect(sessions.available, isFalse);
    expect(sessions.isAlive('anyone'), isFalse);
    expect(sessions.begin, throwsA(isA<Object>()));
  });
}
