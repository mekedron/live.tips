import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/link_codes.dart';
import 'package:live_tips/features/settings/add_device_screen.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/widgets/qr_card.dart';

import 'helpers.dart';

const _code = 'AbCd1234_-ZzYyXxWwVvQq'; // 22 chars, like the server mints

/// A scriptable [LinkCodeService]: the code it hands out, the doc updates it
/// pushes, and whether the confirm ever landed.
class FakeLinkCodeService extends LinkCodeService {
  FakeLinkCodeService({this.failWith}) : super();

  /// When set, createLinkCode throws this instead of minting a code.
  final LinkCodeErrorKind? failWith;

  final _states = StreamController<LinkCodeState>.broadcast();
  String? confirmed;
  int created = 0;

  void push(LinkCodeState state) => _states.add(state);

  @override
  Future<LinkCode> createLinkCode() async {
    created++;
    final kind = failWith;
    if (kind != null) throw LinkCodeError(kind);
    return LinkCode(
      code: _code,
      expiresAtMs:
          DateTime.now().add(const Duration(minutes: 2)).millisecondsSinceEpoch,
    );
  }

  @override
  Stream<LinkCodeState> watchLinkCode(String code) => _states.stream;

  @override
  Future<void> confirmLinkCode(String code) async => confirmed = code;
}

Future<FakeLinkCodeService> _pump(
  WidgetTester tester, {
  LinkCodeErrorKind? failWith,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore();
  final service = FakeLinkCodeService(failWith: failWith);
  addTearDown(service._states.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        linkCodeServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const AddDeviceScreen(),
      ),
    ),
  );
  // Not pumpAndSettle: the expiry countdown ticks forever by design.
  await tester.pump();
  await tester.pump();
  return service;
}

void main() {
  testWidgets('a fresh code renders as a QR of the universal link', (
    tester,
  ) async {
    await _pump(tester);

    final qr = tester.widget<QrBlock>(find.byType(QrBlock));
    expect(qr.data, 'https://tip.live.tips/link#c=$_code');
    // The code is also readable for anyone who'd rather type it.
    expect(find.text(_code), findsOneWidget);
    expect(find.textContaining('Expires in'), findsOneWidget);
  });

  testWidgets('a scan (claimed) shows the requester and asks to confirm', (
    tester,
  ) async {
    final service = await _pump(tester);

    service.push(const LinkCodeState(
      status: LinkCodeStatus.claimed,
      requesterName: "Casey's iPad",
      requesterPlatform: 'ios',
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text("Sign in Casey's iPad?"), findsOneWidget);
    expect(find.textContaining('is waiting to be let in'), findsOneWidget);
    // The QR is gone — nobody else gets to scan this code now.
    expect(find.byType(QrBlock), findsNothing);
    expect(service.confirmed, isNull);

    await tester.tap(find.text('Sign it in'));
    await tester.pump();
    expect(service.confirmed, _code);
  });

  testWidgets('denying kills the code and offers a fresh one', (tester) async {
    final service = await _pump(tester);

    service.push(const LinkCodeState(
      status: LinkCodeStatus.claimed,
      requesterName: 'Someone else',
      requesterPlatform: 'android',
    ));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text("That's not me"));
    await tester.pump();

    expect(service.confirmed, isNull);
    expect(find.textContaining('Denied.'), findsOneWidget);

    await tester.tap(find.text('New code'));
    await tester.pump();
    await tester.pump();
    expect(service.created, 2);
    expect(find.byType(QrBlock), findsOneWidget);
  });

  testWidgets('once used, the screen says the device is in', (tester) async {
    final service = await _pump(tester);

    service.push(const LinkCodeState(
      status: LinkCodeStatus.used,
      requesterName: "Casey's iPad",
      requesterPlatform: 'ios',
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Device signed in'), findsOneWidget);
    expect(find.text("Casey's iPad is on your account now."), findsOneWidget);
  });

  testWidgets('a guest account is told to link a provider, with no retry', (
    tester,
  ) async {
    await _pump(tester, failWith: LinkCodeErrorKind.failedPrecondition);

    expect(find.textContaining("Guest accounts can't add devices"),
        findsOneWidget);
    expect(find.text('New code'), findsNothing);
  });

  testWidgets('too many open codes is a retryable message', (tester) async {
    await _pump(tester, failWith: LinkCodeErrorKind.resourceExhausted);

    expect(find.textContaining('Too many codes open'), findsOneWidget);
    expect(find.text('New code'), findsOneWidget);
  });
}
