import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/features/account/cloud_upload_offer.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/route_depth.dart';

import 'helpers.dart';

/// The data-loss bug: the offer to move this device's profiles into a freshly
/// signed-in account marked itself "already offered" BEFORE the user answered
/// — and it was raised while onboarding was pushing its next screen, so it
/// landed under an opaque route and was never seen. One burned flag, and the
/// local profiles stayed stranded on the device forever.
///
/// The flag may only be written once an answer exists.
class _Harness {
  _Harness(this.local, this.uploads, this.container);

  final LocalStore local;

  /// Every uid the upload actually ran for.
  final List<String> uploads;
  final ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool alreadyOffered = false,
  bool signIn = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // A named profile is worth moving — that is what brings the offer up at all.
  final local = await seededStore(bandName: 'Solo Act');
  if (alreadyOffered) await local.markCloudUploadOffered('uid_test');
  final uploads = <String>[];

  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(FakeAuthService()),
    cloudUploadRunnerProvider.overrideWithValue((uid, {onProgress}) async {
      uploads.add(uid);
    }),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: kTestL10nDelegates,
      locale: const Locale('en'),
      theme: buildLightTheme(),
      navigatorObservers: [container.read(routeDepthObserverProvider)],
      home: CloudUploadOfferGate(
        child: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle(),
                child: const Text('sign in'),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();

  if (signIn) {
    await tester.tap(find.text('sign in'));
    await tester.pumpAndSettle();
  }
  return _Harness(local, uploads, container);
}

const _title = 'Move your profiles to this account?';

void main() {
  testWidgets('a sign-in raises the offer on the root screen', (tester) async {
    await _pump(tester);

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('dismissing without answering leaves the offer un-burned',
      (tester) async {
    final h = await _pump(tester);
    expect(find.text(_title), findsOneWidget);

    // Barrier tap — the question was never answered.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    // The whole bug in one line: nothing recorded, so the profiles can still
    // be offered a home.
    expect(h.local.readCloudUploadOffered('uid_test'), isFalse);
    expect(h.uploads, isEmpty);
  });

  testWidgets('declining records the answer and moves nothing', (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(h.local.readCloudUploadOffered('uid_test'), isTrue);
    expect(h.uploads, isEmpty);
  });

  testWidgets('accepting records the answer and moves the profiles',
      (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.text('Move profiles'));
    await tester.pumpAndSettle();

    expect(h.local.readCloudUploadOffered('uid_test'), isTrue);
    expect(h.uploads, ['uid_test']);
    expect(find.text('Your profiles now live in your account.'), findsOneWidget);
  });

  testWidgets('an account that already answered is never asked again',
      (tester) async {
    await _pump(tester, alreadyOffered: true);

    expect(find.text(_title), findsNothing);
  });

  testWidgets('a sign-in mid-onboarding waits for the flow to finish',
      (tester) async {
    // The reproduction: the user signs in from a pushed onboarding screen
    // (AccountStepScreen), which then pushes the next step. A dialog raised in
    // that moment lands under an opaque route — shown, never seen, gone.
    final h = await _pump(tester, signIn: false);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('onboarding step')),
    ));
    await tester.pumpAndSettle();

    await h.container
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    await tester.pumpAndSettle();

    expect(find.text('onboarding step'), findsOneWidget);
    expect(find.text(_title), findsNothing);
    expect(h.local.readCloudUploadOffered('uid_test'), isFalse);

    // Onboarding ends (popUntil isFirst) — now the question can be seen, and
    // it is still there to be asked.
    navigator.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
  });
}
