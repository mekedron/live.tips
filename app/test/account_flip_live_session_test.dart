import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:live_tips/widgets/profile_switcher.dart';

import 'helpers.dart';

/// Two halves of one failure: flipping the cloud account around a live
/// session. The reload half: `_reloadForProfile` bails out on a live set,
/// and the directory listener fires exactly once per flip — so a flip that
/// landed mid-session left AppState rendering the departed account until an
/// app restart. The teardown half: the venue ceiling (and revocation, see
/// device_session_guard_test) signed out AROUND the running coordinator,
/// which kept polling Stripe with the wiped account's in-memory key. And
/// the doors that let an interactive flip land mid-session at all — the
/// account switcher and Settings sign-out — now refuse, like the band
/// switcher always has. There is ONE switcher since #29, and one refusal:
/// switching profiles and switching accounts say the same sentence.

/// A tip source that remembers being disposed — "the poll timer is dead"
/// made observable.
class _RecordingSource extends TipSource {
  bool disposed = false;

  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];

  @override
  String? get cursor => null;

  @override
  void dispose() => disposed = true;
}

const _casey = AuthUser(
  uid: 'uid_1',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

/// Lets the unawaited microtasks (the directory listener's deferred reload,
/// the reload's keychain awaits) run to completion.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a flip mid-session holds the profile reload — and the session\'s '
      'end runs it', () async {
    final store = await seededStore();
    final secure = FakeSecureStore(
        {'${SecureStore.kApiKeyBase}_$kTestAccountId': 'rk_live_x'});
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
      initialApiKeyProvider.overrideWithValue(null),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              _RecordingSource()),
    ]);
    addTearDown(container.dispose);

    container.read(appStateProvider.notifier).enterDemo();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);
    expect(container.read(appStateProvider).apiKey, isNull,
        reason: 'booted without the keychain read — fetching the key is '
            'exactly what the held reload will do');

    // The account flips mid-set (a sign-out, a revocation, a switch). The
    // reload is skipped — never yank a live set — but it must be HELD, not
    // dropped: the directory listener will not fire for this flip again.
    final directory = container.read(accountsDirectoryProvider.notifier);
    await directory.upsert(const AppAccount(
        id: 'uid_a', name: 'Ana', kind: AccountKind.google));
    await directory.setActive('uid_a');
    await _settle();
    expect(container.read(liveSessionProvider), isNotNull,
        reason: 'the flip must not end the set');
    expect(container.read(appStateProvider).apiKey, isNull,
        reason: 'and must not reload state under it either');

    // The set ends: the held reload runs NOW. It used to take an app
    // restart — stop() only refreshed the archives, and AppState kept the
    // departed account's id, bands and key for the rest of the run.
    await container.read(liveSessionProvider.notifier).stop();
    await _settle();
    expect(container.read(appStateProvider).apiKey, 'rk_live_x',
        reason: 'the profile reload must run once the session is over');
    expect(container.read(appStateProvider).switching, isFalse);
  });

  test('the venue broom stops the live set before the wipe and sign-out',
      () async {
    final store =
        await seededStore(values: {LocalStore.kDeviceKind: 'venue'});
    final secure = FakeSecureStore(
        {'${SecureStore.kApiKeyBase}_$kTestAccountId': 'rk_live_x'});
    final auth = FakeAuthService(
        user: const AuthUser(
            uid: 'uid_v', kind: AccountKind.google, displayName: 'Vera'));
    final source = _RecordingSource();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
      initialApiKeyProvider.overrideWithValue(null),
      authServiceProvider.overrideWithValue(auth),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) => source),
    ]);
    addTearDown(container.dispose);

    // The artist's account owns the tablet, as after a venue sign-in, and
    // the profile reload has adopted their Stripe key. AppState is read
    // once first: its directory listener must exist BEFORE the flip.
    container.read(appStateProvider);
    final directory = container.read(accountsDirectoryProvider.notifier);
    await directory.upsert(const AppAccount(
        id: 'uid_v', name: 'Vera', kind: AccountKind.google));
    await directory.setActive('uid_v');
    await container.read(venueSessionProvider.notifier).start('uid_v');
    await _settle();
    expect(container.read(appStateProvider).apiKey, 'rk_live_x');

    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);

    // The stint ends — "End session", "This isn't me", and the 12-hour
    // ceiling all run this same method.
    await container.read(venueSessionProvider.notifier).endSession();

    expect(container.read(liveSessionProvider), isNull,
        reason: 'the previous artist\'s set must not keep running '
            'invisibly behind the next artist\'s sign-in screen');
    expect(source.disposed, isTrue,
        reason: 'the poll timer dies with the coordinator — no more Stripe '
            'calls with the in-memory key of a wiped account');
    expect(auth.user, isNull);
    expect(secure.values, isEmpty);
  });

  testWidgets(
      'the account sheet refuses an account flip mid-session, and says why',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // A profile on the device itself, beside the signed-in account and its own
    // (cloud) profiles — the account flip under test is the tap on it.
    final store = await seededStore(bandName: 'Home Sessions');
    await store.saveAccountsDirectory(AccountsDirectory.initial()
        .withAccount(const AppAccount(
            id: 'uid_1', name: 'Casey', kind: AccountKind.google))
        .withActive('uid_1'));
    final db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('uid_1')
        .collection('bands')
        .doc('acc_cloud')
        .set({'name': 'Duo Sundays', 'createdAtMs': 1});
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore(
          {'${SecureStore.kApiKeyBase}_$kTestAccountId': 'rk_live_x'})),
      initialApiKeyProvider.overrideWithValue('rk_live_x'),
      firestoreProvider.overrideWithValue(db),
      authServiceProvider.overrideWithValue(FakeAuthService(user: _casey)),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              _RecordingSource()),
    ]);
    addTearDown(container.dispose);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showAccountSheet(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Leaving this account for the device's own mode is one tap — the tap that
    // used to flip the directory under the running set. (The old BAND sheet
    // always refused it; the old ACCOUNT screen did not. Two sheets again (#49),
    // and still ONE guard and one sentence — whichever of the two things moved.
    // The account flip is asked HERE, on the sheet whose label says account: the
    // merged sheet made it by tapping a profile of the local mode, which is the
    // confusion this split ends.)
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Home Sessions'), findsNothing,
        reason: 'a profile of a mode this device is not in is not this sheet\'s '
            'business');
    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();

    // Said ON the sheet, not behind it (#53): a snackbar posted from a modal
    // bottom sheet is painted under it, and `find.text` cannot tell.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Stop the live session before switching.'),
      ).hitTestable(),
      findsOneWidget,
    );
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        'uid_1',
        reason: 'the flip must not have happened');
    expect(container.read(liveSessionProvider), isNotNull);

    // End the set so its poll timer (and the snackbar's) can drain.
    await container.read(liveSessionProvider.notifier).stop();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Settings sign-out refuses mid-session, and says why',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await seededStore();
    await store.saveAccountsDirectory(AccountsDirectory.initial()
        .withAccount(const AppAccount(
            id: 'uid_1', name: 'Casey', kind: AccountKind.google))
        .withActive('uid_1'));
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore(
          {'${SecureStore.kApiKeyBase}_$kTestAccountId': 'rk_live_x'})),
      initialApiKeyProvider.overrideWithValue('rk_live_x'),
      authServiceProvider.overrideWithValue(FakeAuthService(user: _casey)),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              _RecordingSource()),
    ]);
    addTearDown(container.dispose);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const Scaffold(body: SettingsScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    // Sign out lives one level in now, behind the signed-in account row —
    // opening that page is mere navigation and is not refused.
    await tester.tap(find.byIcon(Icons.account_circle_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Stop the live session before signing out.'),
        findsOneWidget);
    expect(find.text('Sign out?'), findsNothing,
        reason: 'not even the dialog — the refusal comes first');
    expect(container.read(authControllerProvider).user, isNotNull);
    expect(container.read(liveSessionProvider), isNotNull);

    await container.read(liveSessionProvider.notifier).stop();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
