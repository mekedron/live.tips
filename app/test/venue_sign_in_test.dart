import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/link_codes.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/features/venue/venue_code_entry.dart';
import 'package:live_tips/features/venue/venue_identity_screen.dart';
import 'package:live_tips/features/venue/venue_sign_in_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A custom token whose payload claims [uid] — enough for the re-approval
/// check, and shaped like the real thing.
String fakeCustomToken(String uid) {
  final payload =
      base64Url.encode(utf8.encode(jsonEncode({'uid': uid}))).replaceAll('=', '');
  return 'eyJhbGciOiJSUzI1NiJ9.$payload.sig';
}

/// The tablet's half of the handshake, scripted: redeem hands back a nonce,
/// the first collect poll hands over the token. Arm [failWith] to model the
/// backend refusing the code (unknown, expired, offline) — it throws on the
/// redeem and clears itself, so a retry succeeds.
class FakeLinkCodeService extends LinkCodeService {
  FakeLinkCodeService({required this.token, this.failWith});

  final String token;
  LinkCodeError? failWith;
  final calls = <String>[];

  @override
  bool get available => true;

  @override
  Future<String> redeemLinkCode({
    required String code,
    required String deviceName,
    required String devicePlatform,
    String? deviceId,
  }) async {
    // The tablet names itself, so the artist's confirm can re-admit a device
    // they once revoked (#36).
    calls.add('redeem:$code:${deviceId ?? 'unnamed'}');
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      throw failure;
    }
    return 'nonce_1';
  }

  @override
  Future<String> awaitToken({
    required String code,
    required String nonce,
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    calls.add('collect:$nonce');
    return token;
  }
}

const _artistCode = 'AAAAAAAAAAAAAAAAAAAAAA'; // 22 chars, the real shape

void main() {
  Future<
      ({
        FakeAuthService auth,
        FakeLinkCodeService link,
        LocalStore store,
        FakeSecureStore secure,
      })> pumpVenueApp(
    WidgetTester tester, {
    required AuthUser artist,
  }) async {
    final store = await seededStore(
      values: {LocalStore.kDeviceKind: 'venue'},
    );
    final secure = FakeSecureStore(
        {'stripe_api_key_$kTestAccountId': 'rk_test_cached'});
    final auth = FakeAuthService(nextUser: artist);
    final link = FakeLinkCodeService(token: fakeCustomToken(artist.uid));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          authServiceProvider.overrideWithValue(auth),
          linkCodeServiceProvider.overrideWithValue(link),
          deviceRegistryProvider.overrideWithValue(
              DeviceRegistry(db: null, deviceId: 'dev_tablet')),
          // The host test platform claims android; there is no camera and
          // no device-info channel.
          venueCameraAvailableProvider.overrideWithValue(false),
          describeDeviceProvider.overrideWithValue(() async =>
              const DeviceDescription(
                  name: 'Bar iPad', platform: 'android')),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (auth: auth, link: link, store: store, secure: secure);
  }

  Future<void> typeCodeAndGo(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, _artistCode);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'venue sign-in: typed code → redeem → collect → signed in, '
      'identity confirmed, banner up', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await pumpVenueApp(
      tester,
      artist: const AuthUser(
          uid: 'uid_ana',
          kind: AccountKind.google,
          displayName: 'Ana',
          email: 'ana@example.com'),
    );

    // A venue install with no session opens on the front door — with the
    // typed-code path right there, not hidden behind a camera toggle.
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(find.text('Type the code instead'), findsOneWidget);

    await typeCodeAndGo(tester);
    expect(env.link.calls, ['redeem:$_artistCode:dev_tablet', 'collect:nonce_1']);

    // The token signed Ana in; the gate demands the identity check before
    // anything else — WHOSE account is on this tablet, said out loud.
    expect(find.byType(VenueIdentityScreen), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text("This isn't me — sign out"), findsOneWidget);

    // The 12-hour deadline was persisted the moment the session started.
    final session = env.store.readVenueSession();
    expect(session, isNotNull);
    expect(session!.uid, 'uid_ana');
    expect(session.expiresAtMs - session.startedAtMs,
        const Duration(hours: 12).inMilliseconds);
    expect(session.identityConfirmed, isFalse);

    await tester.tap(find.text("That's me — continue"));
    await tester.pumpAndSettle();

    // In the shell now, with the public-device banner above everything.
    expect(find.textContaining('Public device'), findsOneWidget);
    expect(find.text('End session'), findsOneWidget);
    expect(env.store.readVenueSession()!.identityConfirmed, isTrue);

    // The banner's End session asks once, inline, then actually ends it:
    // signed out, secrets wiped, session record gone, front door again.
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end it'));
    await tester.pumpAndSettle();

    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(env.auth.user, isNull);
    expect(env.secure.values, isEmpty);
    expect(env.store.readVenueSession(), isNull);
  });

  testWidgets(
      'a wrong account (mistyped or stranger-approved code) is caught by the '
      'identity screen, and "this isn\'t me" leaves nothing behind',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await pumpVenueApp(
      tester,
      artist: const AuthUser(
          uid: 'uid_mallory',
          kind: AccountKind.google,
          displayName: 'Mallory',
          email: 'mallory@example.com'),
    );

    await typeCodeAndGo(tester);

    // The tablet never slides silently into an account: the name is shown
    // and the artist must say "that's me" first.
    expect(find.byType(VenueIdentityScreen), findsOneWidget);
    expect(find.text('Mallory'), findsOneWidget);

    await tester.tap(find.text("This isn't me — sign out"));
    await tester.pumpAndSettle();

    // Back at the front door, signed out, session record gone, cached
    // secrets scrubbed, and no directory row remembering the account.
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(env.auth.user, isNull);
    expect(env.store.readVenueSession(), isNull);
    expect(env.secure.values, isEmpty);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueSignInScreen)));
    expect(
        container.read(accountsDirectoryProvider).contains('uid_mallory'),
        isFalse);
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
  });

  testWidgets(
      'the signed-out front door always offers a way out of venue mode — '
      'a mis-tapped device kind must never be a soft-lock', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await pumpVenueApp(
      tester,
      artist: const AuthUser(uid: 'uid_x', kind: AccountKind.google),
    );

    // Venue mode's front door has no Settings, no back button — the escape
    // must live ON this screen or nowhere.
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    final escape = find.text("This isn't a venue device");
    await tester.scrollUntilVisible(escape, 80,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(escape);
    await tester.pumpAndSettle();

    // Same blunt warning as the Settings kind change — it IS that wipe.
    expect(find.text('Wipe this device?'), findsOneWidget);

    // Backing out leaves venue mode untouched.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(env.store.readDeviceKind(), DeviceKind.venue);
    expect(find.byType(VenueSignInScreen), findsOneWidget);

    // Going through wipes the device kind and returns to onboarding.
    await tester.tap(escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe and start over'));
    await tester.pumpAndSettle();

    expect(env.store.readDeviceKind(), isNull,
        reason: 'the kind is cleared — the device chooses again');
    expect(find.byType(VenueSignInScreen), findsNothing,
        reason: 'the gate must fall away, not re-render the locked door');
  });

  testWidgets('a random QR payload is refused with a clear message',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final env = await pumpVenueApp(
      tester,
      artist: const AuthUser(uid: 'uid_x', kind: AccountKind.google),
    );

    await tester.enterText(
        find.byType(TextField).first, 'https://example.com/poster');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining("doesn't look like a live.tips code"),
        findsOneWidget);
    expect(env.link.calls, isEmpty,
        reason: 'nothing that fails the shape check may reach the backend');
  });
}
