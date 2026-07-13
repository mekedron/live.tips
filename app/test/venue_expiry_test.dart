import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The 12-hour ceiling: fixed at sign-in, honoured by a timer while the app
/// runs, and honoured at boot from the persisted record — a restart can only
/// shorten the wait, never extend it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const artist = AuthUser(
      uid: 'uid_v', kind: AccountKind.google, displayName: 'Vera');

  Future<
      ({
        ProviderContainer container,
        LocalStore store,
        FakeSecureStore secure,
        FakeAuthService auth,
      })> makeEnv({DateTime Function()? clock, LocalStore? reuse}) async {
    final store = reuse ??
        await seededStore(values: {LocalStore.kDeviceKind: 'venue'});
    final secure =
        FakeSecureStore({'stripe_api_key_$kTestAccountId': 'rk_live_x'});
    final auth = FakeAuthService(user: artist);
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
      authServiceProvider.overrideWithValue(auth),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ]);
    addTearDown(container.dispose);
    return (container: container, store: store, secure: secure, auth: auth);
  }

  test('the timer ends the session exactly at the 12-hour mark', () async {
    final store =
        await seededStore(values: {LocalStore.kDeviceKind: 'venue'});
    fakeAsync((async) {
      final secure =
          FakeSecureStore({'stripe_api_key_$kTestAccountId': 'rk_live_x'});
      final auth = FakeAuthService(user: artist);
      final container = ProviderContainer(overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(secure),
        authServiceProvider.overrideWithValue(auth),
      ]);

      final notifier = container.read(venueSessionProvider.notifier);
      // The artist's account is the active profile, as after a venue sign-in.
      container
          .read(accountsDirectoryProvider.notifier)
          .upsert(const AppAccount(
              id: 'uid_v', name: 'Vera', kind: AccountKind.google));
      container.read(accountsDirectoryProvider.notifier).setActive('uid_v');
      notifier.start('uid_v');
      async.flushMicrotasks();
      expect(container.read(venueSessionProvider)?.uid, 'uid_v');

      // One minute short of the ceiling: still on.
      async.elapse(const Duration(hours: 11, minutes: 59));
      expect(container.read(venueSessionProvider), isNotNull);

      // The ceiling: session over, secrets gone, account signed out and
      // forgotten, nothing persisted to resume from.
      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();
      expect(container.read(venueSessionProvider), isNull);
      expect(secure.values, isEmpty);
      expect(auth.user, isNull);
      expect(store.readVenueSession(), isNull);
      expect(container.read(accountsDirectoryProvider).contains('uid_v'),
          isFalse);
      container.dispose();
    });
  });

  test('a restart cannot extend the deadline: an overdue record dies at boot',
      () async {
    // A previous run persisted a session that expired while the tablet was
    // off. The fresh notifier must execute the expiry, not re-arm 12 hours.
    SharedPreferences.setMockInitialValues({});
    final store = await seededStore(
      values: {LocalStore.kDeviceKind: 'venue'},
    );
    final started = DateTime.now()
        .subtract(const Duration(hours: 13))
        .millisecondsSinceEpoch;
    await store.saveVenueSession(VenueSession(
      uid: 'uid_v',
      startedAtMs: started,
      expiresAtMs: started + const Duration(hours: 12).inMilliseconds,
      identityConfirmed: true,
    ));

    final env = await makeEnv(reuse: store);
    env.container
        .read(accountsDirectoryProvider.notifier)
        .upsert(const AppAccount(
            id: 'uid_v', name: 'Vera', kind: AccountKind.google));
    await env.container
        .read(accountsDirectoryProvider.notifier)
        .setActive('uid_v');

    // Building the notifier arms a zero-length timer for the overdue record.
    expect(env.container.read(venueSessionProvider), isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(env.container.read(venueSessionProvider), isNull);
    expect(env.store.readVenueSession(), isNull);
    expect(env.secure.values, isEmpty);
    expect(env.auth.user, isNull);
  });

  test('the persisted deadline is written at start, before anything else',
      () async {
    final env = await makeEnv(
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000000));
    await env.container.read(venueSessionProvider.notifier).start('uid_v');
    final record = env.store.readVenueSession()!;
    expect(record.expiresAtMs,
        1000000 + const Duration(hours: 12).inMilliseconds);
  });
}
