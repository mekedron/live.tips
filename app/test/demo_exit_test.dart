import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// "Exit demo" must not be able to land the artist back in demo (#45).
///
/// RootGate re-enters demo whenever the install says `demo` and the in-memory
/// flag is off — that is how a demo device comes back after a restart. Exit
/// demo turned the flag off SYNCHRONOUSLY and cleared the persisted kind
/// WITHOUT awaiting it, so between those two facts sat a frame: if the frame
/// won, RootGate saw exactly the condition it re-enters demo on and put the
/// artist straight back into demo play.
///
/// [_SlowStore] is the whole point of this file. `setMockInitialValues` makes
/// every prefs write complete synchronously, so in the suite the clear was
/// effectively instantaneous and the interleaving could not occur — the
/// fakes-are-kinder-than-reality trap in a new dress. On iOS/Android the write
/// is a platform-channel round trip with no such guarantee. A store that takes
/// one frame to answer is the honest one, and it is what makes the race real
/// here: against the shipped code these tests land back in demo.
class _SlowStore extends LocalStore {
  _SlowStore(super.prefs);

  @override
  Future<void> clearDeviceKind() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await super.clearDeviceKind();
  }
}

Future<void> _pumpDemoApp(WidgetTester tester, LocalStore store) async {
  await tester.binding.setSurfaceSize(const Size(700, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<LocalStore> _demoStore() async {
  await seededStore(values: {LocalStore.kDeviceKind: 'demo'});
  return _SlowStore(await SharedPreferences.getInstance());
}

Future<void> _exitDemo(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Exit demo'));
  // The frames the race lives in — pumped at ZERO duration, because
  // pumpAndSettle advances the fake clock 100ms a frame and would hand the
  // prefs write a head start no real device promises. This is the interleaving
  // the shipped code loses: the flag is already off, the kind is still on disk,
  // and RootGate is about to look at both.
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'exit demo cannot re-enter demo, even when the prefs write takes a frame '
      '(#45)', (tester) async {
    final store = await _demoStore();
    await _pumpDemoApp(tester, store);

    // Booted into demo: the install says demo, RootGate turns the flag on.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(container.read(appStateProvider).demo, isTrue);

    await _exitDemo(tester);

    // Out, and staying out. The clear is awaited before the flag is dropped, so
    // no frame can ever see "the install says demo, the flag is off" — the one
    // state RootGate answers by re-entering demo.
    expect(store.readDeviceKind(), isNull);
    expect(container.read(deviceKindProvider), isNull);
    expect(container.read(appStateProvider).demo, isFalse);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    // And it holds past the frame the race used to live in — nothing lands late
    // and drags the artist back in.
    await tester.pump(const Duration(milliseconds: 32));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).demo, isFalse);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('and the demo device it left behind boots on Welcome (#45)',
      (tester) async {
    final store = await _demoStore();
    await _pumpDemoApp(tester, store);
    await _exitDemo(tester);

    // The kind is what survives a restart; a device that exited demo must not
    // come back into it on the next boot.
    expect(store.readDeviceKind(), isNull);
    await _pumpDemoApp(tester, LocalStore(await SharedPreferences.getInstance()));
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
