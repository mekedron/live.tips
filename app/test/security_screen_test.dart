import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/link_codes.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/security_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A [LinkCodeService] over no Firebase that records what the UI asked for.
class RecordingLinkCodeService extends LinkCodeService {
  RecordingLinkCodeService() : super();

  final revoked = <String>[];
  String? revokedAllFor;

  @override
  Future<void> revokeDevice(String deviceId) async => revoked.add(deviceId);

  @override
  Future<int> revokeAllOtherDevices(String currentDeviceId) async {
    revokedAllFor = currentDeviceId;
    return 2;
  }
}

DeviceInfo _device({
  required String id,
  required String name,
  String platform = 'ios',
  bool isCurrent = false,
  bool revoked = false,
  int lastSeenAtMs = 0,
}) =>
    DeviceInfo(
      id: id,
      name: name,
      platform: platform,
      isCurrent: isCurrent,
      revoked: revoked,
      lastSeenAtMs: lastSeenAtMs == 0
          ? DateTime.now().millisecondsSinceEpoch
          : lastSeenAtMs,
    );

Future<RecordingLinkCodeService> _pump(
  WidgetTester tester, {
  required List<DeviceInfo> devices,
  AccountKind kind = AccountKind.google,
  String? ownDeviceId,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore();
  // An anonymous uid only counts as an ACCOUNT once the directory says so —
  // the relay's transport sign-in is anonymous too, and must never surface
  // here. An explicit sign-in is adopted, so the fixture records it.
  await localStore.saveAccountsDirectory(
    AccountsDirectory.initial().withAccount(
      AppAccount(id: 'uid_1', name: 'Casey', kind: kind),
    ),
  );
  final service = RecordingLinkCodeService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(
          FakeAuthService(
            user: AuthUser(uid: 'uid_1', kind: kind, displayName: 'Casey'),
          ),
        ),
        linkCodeServiceProvider.overrideWithValue(service),
        devicesProvider.overrideWith((ref) => Stream.value(devices)),
        if (ownDeviceId != null)
          deviceRegistryProvider.overrideWithValue(
              DeviceRegistry(db: null, deviceId: ownDeviceId)),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const SecurityScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('the device list renders, with this device marked', (
    tester,
  ) async {
    await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(
        id: 'dev_b',
        name: 'MacBook Pro',
        platform: 'macos',
        lastSeenAtMs: DateTime.now()
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
      ),
    ]);

    expect(find.text("Casey's iPhone"), findsOneWidget);
    expect(find.text('MacBook Pro'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Last seen 3 h ago'), findsOneWidget);
    // The current device offers no revoke button — you don't kick yourself out
    // from here (that's "Sign out"), and the other one does.
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('revoking asks first, then calls revokeDevice', (tester) async {
    final service = await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    // The dialog is honest about what revoking can and cannot do.
    expect(find.text('Revoke Old Pixel?'), findsOneWidget);
    expect(find.textContaining('asks that device to sign out'), findsOneWidget);
    expect(service.revoked, isEmpty); // nothing happened yet

    await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
    await tester.pumpAndSettle();

    expect(service.revoked, ['dev_b']);
    expect(find.text('That device was asked to sign out.'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog revokes nothing', (tester) async {
    final service = await _pump(tester, devices: [
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(service.revoked, isEmpty);
    expect(find.text('Revoke Old Pixel?'), findsNothing);
  });

  testWidgets(
      'the revoke button names its device to the a11y tree — a screen-reader '
      'user must know WHOSE session they are ending', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    // A bare "Revoke" is exactly the production bug: one unlabeled tap with
    // no way to tell which device it kills.
    expect(find.bySemanticsLabel('Revoke'), findsNothing);
    expect(find.bySemanticsLabel('Revoke Old Pixel'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
      'the device in your hand never gets the foreign-revoke path — even '
      'when the isCurrent marker has drifted', (tester) async {
    // The production shape: registration failed / the device id rotated, so
    // the list's isCurrent flag marks nothing — but a row still carries the
    // id this device calls itself. Tapping its Revoke must NOT run
    // revokeDevice (which wipes this device's own keys); it is a sign-out,
    // and must say so.
    final service = await _pump(
      tester,
      ownDeviceId: 'dev_self',
      devices: [
        _device(id: 'dev_self', name: 'This very phone', isCurrent: false),
      ],
    );

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Sign out this device?'), findsOneWidget,
        reason: 'an honest dialog: this is the device being held');
    expect(find.textContaining('asks that device to sign out'), findsNothing,
        reason: 'never the foreign-revoke wording for yourself');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(service.revoked, isEmpty,
        reason: 'revokeDevice must never be sent this device\'s own id');
  });

  testWidgets('a guest account cannot sign out everywhere else', (
    tester,
  ) async {
    await _pump(
      tester,
      kind: AccountKind.anonymous,
      devices: [_device(id: 'dev_a', name: 'Guest phone', isCurrent: true)],
    );

    expect(
      find.textContaining('Link Apple or Google first'),
      findsOneWidget,
    );
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Sign out everywhere else'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('an empty account still renders its (empty) list', (
    tester,
  ) async {
    await _pump(tester, devices: const []);
    expect(find.text('No devices listed yet.'), findsOneWidget);
  });
}
