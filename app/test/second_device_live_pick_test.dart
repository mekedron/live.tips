import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/widgets/profile_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// THE flagship two-device flow: the artist's phone runs the set, the venue
/// tablet (or the artist's second device) signs into the SAME account and
/// joins it. Signing in fresh lands on the "Welcome back" chooser — and the
/// chooser used to refuse EVERY pick with "Stop the live session before
/// switching." while the account was live anywhere. A device that had not
/// even chosen a profile yet was told to stop a session it was not in, from
/// a screen with no session to stop: a soft lock on exactly the flow the
/// Join banner (and the Requests tab, #64) exists for.
///
/// The guard's job is real, and stays: a device whose OWN session runs must
/// not swap profiles under it (the coordinator, key and relay socket are the
/// band's). But picking a profile is a DEVICE-LOCAL act — the stored answer
/// (activeBandId) never leaves this device — so the account being live on
/// ANOTHER device refuses nothing here. The chooser lets the second device
/// land, and the shell's Join banner takes it from there.
const _uid = 'uid_test'; // FakeAuthService's default user
const _liveBand = 'acc_live';
const _otherBand = 'acc_other';

/// The account: two profiles, and a session running on the artist's phone
/// ("device_a") — `live/current` active, lease fresh.
Future<FakeFirebaseFirestore> _liveAccount() async {
  final db = FakeFirebaseFirestore();
  final bands = db.collection('users').doc(_uid).collection('bands');
  await bands.doc(_liveBand).set({'name': 'The Foxes', 'createdAtMs': 1});
  await bands.doc(_otherBand).set({'name': 'Duo Sundays', 'createdAtMs': 2});
  await db.collection('users').doc(_uid).collection('live').doc('current').set({
    'active': true,
    'bandId': _liveBand,
    'sessionId': 'sess_1',
    'startedAtMs': DateTime.now().millisecondsSinceEpoch,
    'currency': 'eur',
    'goalMinor': 10000,
    'goalUpdatedAtMs': 0,
    'leaderDeviceId': 'device_a',
    'leaderLeaseUntilMs': DateTime.now().millisecondsSinceEpoch +
        CloudSessionCoordinator.leaseMs,
  });
  return db;
}

/// Device B: signed into the account, no profile opened yet — the state a
/// fresh sign-in (or a boot mid-question) leaves it in. RootGate lands it on
/// the chooser.
Future<LocalStore> _deviceB() async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(const AppAccount(
          id: _uid,
          name: 'Casey',
          kind: AccountKind.google,
          email: 'casey@example.com',
        ))
        .withActive(_uid),
  );
  return store;
}

Future<ProviderContainer> _boot(
  WidgetTester tester,
  LocalStore store,
  FakeFirebaseFirestore db,
) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        firestoreProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(FakeAuthService(
          user: const AuthUser(
            uid: _uid,
            kind: AccountKind.google,
            displayName: 'Casey',
          ),
        )),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(LiveTipsApp)),
      listen: false);
}

void main() {
  testWidgets('the chooser says WHICH profile is live', (tester) async {
    final db = await _liveAccount();
    await _boot(tester, await _deviceB(), db);

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    // The live band's row carries the badge; nobody else's does. This is how
    // the second device knows which profile to pick to join the set.
    expect(
      find.descendant(
        of: find.ancestor(
            of: find.text('The Foxes'), matching: find.byType(ProfileRow)),
        matching: find.text('LIVE'),
      ),
      findsOneWidget,
    );
    expect(find.text('LIVE'), findsOneWidget,
        reason: 'one session, one badge — not one per row');
  });

  testWidgets('picking the LIVE profile lands the second device in the '
      'shell, with the Join banner up', (tester) async {
    final db = await _liveAccount();
    final container = await _boot(tester, await _deviceB(), db);

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    await tester.tap(find.text('The Foxes'));
    await tester.pumpAndSettle();

    // THE SOFT LOCK: this pick was refused with "Stop the live session
    // before switching." — on a device with no session to stop.
    expect(find.text('Stop the live session before switching.'), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(container.read(appStateProvider).accountId, _liveBand);
    // The normal join flow takes it from here — the affordance is on screen.
    expect(find.text('Join'), findsOneWidget,
        reason: 'the running session is one tap away, as the banner promises');
  });

  testWidgets('picking ANOTHER profile of the live account is refused '
      'nothing either — the pick is this device\'s own business',
      (tester) async {
    final db = await _liveAccount();
    final container = await _boot(tester, await _deviceB(), db);

    await tester.tap(find.text('Duo Sundays'));
    await tester.pumpAndSettle();

    expect(find.text('Stop the live session before switching.'), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(container.read(appStateProvider).accountId, _otherBand);
    // The banner still points at the session the account runs elsewhere.
    expect(find.text('Join'), findsOneWidget);
  });
}
