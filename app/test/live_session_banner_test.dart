import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:live_tips/widgets/live_session_banner.dart';

import 'helpers.dart';

/// Records what the controller asked of it and succeeds at everything —
/// the banner test cares about the handoff, not the transport.
class FakeCoordinator implements SessionCoordinator {
  LiveSession? startedSession;
  SessionStartMode? startedMode;

  @override
  RelayHealth? get relayHealthSeed => null;

  @override
  bool get replaysTips => false;

  @override
  Future<void> start(
    LiveSession session, {
    String? resumeCursor,
    SessionStartMode mode = SessionStartMode.fresh,
  }) async {
    startedSession = session;
    startedMode = mode;
  }

  @override
  void onTipsIngested(LiveSession session, List<Tip> fresh) {}

  @override
  void onGoalEdited(LiveSession session) {}

  @override
  void onRequestsEdited(LiveSession session) {}

  @override
  void onTipVerified(LiveSession session, Tip tip) {}

  @override
  bool get publishesRequests => false;

  @override
  Future<void> stop(LiveSession session, {bool durable = false}) async {}

  @override
  void reconnectNow() {}

  @override
  Future<void> dispose() async {}
}

const _info = ActiveSessionInfo(
  active: true,
  bandId: 'acc_other',
  sessionId: 'ses_remote',
  startedAtMs: 1751500000000,
  currency: 'usd',
  goalMinor: 12000,
  goalUpdatedAtMs: 1751500000000,
  leaderDeviceId: 'dev_far_away',
  leaderLeaseUntilMs: 9999999999999,
);

void main() {
  testWidgets(
      'a session active on ANOTHER band shows the banner; Join switches '
      'bands, attaches as a follower, and opens the stage', (tester) async {
    final store = await seededStore();
    // A second band — the one the remote session runs in.
    await store.saveAccountsRegistry(AccountsRegistry(
      accounts: [
        BandAccount(id: kTestAccountId, name: 'Home Band', createdAtMs: 0),
        BandAccount(id: 'acc_other', name: 'The Other Band', createdAtMs: 1),
      ],
      activeId: kTestAccountId,
    ));
    final coordinator = FakeCoordinator();
    var opened = false;

    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      activeSessionProvider
          .overrideWith((ref) => Stream.value(_info)),
      sessionCoordinatorFactoryProvider
          .overrideWithValue((events) => coordinator),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: Scaffold(
          body: Column(children: [
            LiveSessionBanner(onJoined: (_) => opened = true),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('The Other Band'), findsOneWidget,
        reason: 'the banner names the band the session runs in');
    expect(find.text('Join'), findsOneWidget);
    expect(container.read(appStateProvider).accountId, kTestAccountId);

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(container.read(appStateProvider).accountId, 'acc_other',
        reason: 'joining a session in another band switches to it first');
    expect(coordinator.startedMode, SessionStartMode.join,
        reason: 'the device attaches as a follower, it does not start');
    expect(coordinator.startedSession?.id, 'ses_remote');
    expect(coordinator.startedSession?.goalMinor, 12000);
    expect(container.read(liveSessionProvider)?.session.id, 'ses_remote');
    expect(opened, isTrue, reason: 'the stage opens after attaching');

    // Attached now — the banner has nothing left to offer.
    await tester.pumpAndSettle();
    expect(find.text('Join'), findsNothing);
  });

  testWidgets('no remote session — the banner renders nothing',
      (tester) async {
    final store = await seededStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      activeSessionProvider
          .overrideWith((ref) => Stream<ActiveSessionInfo?>.value(null)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: const Scaffold(
            body: Column(children: [LiveSessionBanner()])),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Join'), findsNothing);
    expect(find.byIcon(Icons.sensors_rounded), findsNothing);
  });

  testWidgets('a session already ended (active:false) shows no banner',
      (tester) async {
    final store = await seededStore();
    const ended = ActiveSessionInfo(
      active: false,
      bandId: kTestAccountId,
      sessionId: 'ses_over',
      startedAtMs: 1751500000000,
      currency: 'usd',
      goalMinor: 12000,
      goalUpdatedAtMs: 1751500000000,
      leaderDeviceId: 'dev_far_away',
      leaderLeaseUntilMs: 0,
      endedAtMs: 1751500009999,
    );
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      activeSessionProvider.overrideWith((ref) => Stream.value(ended)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: const Scaffold(
            body: Column(children: [LiveSessionBanner()])),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Join'), findsNothing);
  });
}
