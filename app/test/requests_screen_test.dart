import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/song_request_settings.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/requests/requests_screen.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';

import 'helpers.dart';

/// A transport-less coordinator: the tests below hand tips straight to the
/// controller through the captured [SessionEvents] — exactly what a real
/// feed does, minus the timers a widget test must not leave pending.
/// publishesRequests is false, so the (irrelevant here) fan-page publisher
/// stays silent and schedules nothing.
class _FakeCoordinator implements SessionCoordinator {
  @override
  RelayHealth? get relayHealthSeed => null;

  @override
  Future<void> start(LiveSession session,
      {String? resumeCursor,
      SessionStartMode mode = SessionStartMode.fresh}) async {}

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

Tip request(String id, int amount,
        {String songId = 'sng_1',
        String songTitle = 'Wonderwall',
        bool verified = true,
        String? name}) =>
    Tip(
      id: id,
      amountMinor: amount,
      currency: 'usd',
      createdAt: DateTime(2026, 7, 3, 21),
      livemode: false,
      verified: verified,
      songId: songId,
      songTitle: songTitle,
      name: name,
    );

void main() {
  late ProviderContainer container;
  late SessionEvents events;

  Future<void> pumpRequests(WidgetTester tester) async {
    final store = await seededStore();
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      sessionCoordinatorFactoryProvider.overrideWithValue((e) {
        events = e;
        return _FakeCoordinator();
      }),
    ]);
    addTearDown(container.dispose);
    container.read(appStateProvider.notifier).enterDemo();
    // The feature on, with a library entry so the card can name the artist.
    final app = container.read(appStateProvider);
    await container.read(appStateProvider.notifier).updateBand(app.band
        .copyWith(
            songRequests: const SongRequestSettings(enabled: true, songs: [
      SongEntry(id: 'sng_1', title: 'Wonderwall', artist: 'Oasis'),
    ])));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const Scaffold(body: RequestsScreen()),
      ),
    ));
    await tester.pump();
  }

  testWidgets('no live session → the explain-yourself empty state',
      (tester) async {
    await pumpRequests(tester);

    expect(find.text('No live set right now'), findsOneWidget);
    expect(find.textContaining('during a live set'), findsOneWidget);
    expect(find.byType(Switch), findsNothing,
        reason: 'nothing to pause without a session');
  });

  testWidgets('live with requests off → paused state, and Resume reopens',
      (tester) async {
    await pumpRequests(tester);
    await container
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 10000, requestsOpen: false);
    await tester.pump();

    expect(find.text('Requests are paused'), findsOneWidget);
    await tester.tap(find.text('Resume requests'));
    await tester.pump();

    expect(find.text('Requests are paused'), findsNothing);
    expect(container.read(liveSessionProvider)!.session.requestsOpen, isTrue);
    expect(find.text('No requests yet'), findsOneWidget,
        reason: 'open with an empty queue is the waiting state');
  });

  testWidgets('open session ranks the queue and the header switch pauses it',
      (tester) async {
    await pumpRequests(tester);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    events.onTips([
      request('a', 500),
      request('b', 300, name: 'Maya'),
      request('c', 700, songId: 'sng_2', songTitle: 'Hey Jude'),
    ]);
    await tester.pump();

    // Wonderwall ($8, 2 requests) outranks Hey Jude ($7, 1 request).
    expect(
      tester.getTopLeft(find.text('Wonderwall')).dy <
          tester.getTopLeft(find.text('Hey Jude')).dy,
      isTrue,
    );
    expect(find.text(r'$8'), findsOneWidget);
    expect(find.text(r'$7'), findsOneWidget);
    expect(find.textContaining('Oasis'), findsOneWidget,
        reason: 'the artist line comes from the library');
    expect(find.textContaining('2 requests'), findsOneWidget);
    expect(find.textContaining('1 request'), findsWidgets);

    // The header switch is the same pause lever as the paused state's.
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('Requests are paused'), findsOneWidget);
    expect(
        container.read(liveSessionProvider)!.session.requestsOpen, isFalse);
  });

  testWidgets('expanding shows the tips; Mark verified flips the relay tip',
      (tester) async {
    await pumpRequests(tester);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    events.onTips([
      request('relay_1', 500, verified: false, name: 'Maya'),
      request('b', 300),
    ]);
    await tester.pump();

    expect(find.text('1 unverified'), findsOneWidget);
    expect(find.text('Mark verified'), findsNothing,
        reason: 'per-tip actions live behind the expand');

    await tester.tap(find.text('Wonderwall'));
    await tester.pump();
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Mark verified'), findsOneWidget);

    await tester.tap(find.text('Mark verified'));
    await tester.pump();

    final session = container.read(liveSessionProvider)!.session;
    expect(
        session.tips.firstWhere((t) => t.id == 'relay_1').verified, isTrue);
    expect(find.text('Mark verified'), findsNothing);
    expect(find.text('1 unverified'), findsNothing);
  });

  testWidgets('Played sinks the card below the queue; Restore lifts it back',
      (tester) async {
    await pumpRequests(tester);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    events.onTips([
      request('a', 900),
      request('c', 200, songId: 'sng_2', songTitle: 'Hey Jude'),
    ]);
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Wonderwall')).dy <
          tester.getTopLeft(find.text('Hey Jude')).dy,
      isTrue,
      reason: 'the bigger total starts on top',
    );

    await tester.tap(find.text('Wonderwall'));
    await tester.pump();
    await tester.tap(find.text('Played'));
    await tester.pump();

    expect(container.read(liveSessionProvider)!.session.songStatuses,
        {'sng_1': LiveSession.statusPlayed});
    expect(
      tester.getTopLeft(find.text('Wonderwall')).dy >
          tester.getTopLeft(find.text('Hey Jude')).dy,
      isTrue,
      reason: 'played sinks below every active entry',
    );
    expect(find.text('Played'), findsWidgets); // the sunk card's chip

    // The way back: the expanded sunk card offers Restore.
    await tester.tap(find.text('Restore'));
    await tester.pump();
    expect(
        container.read(liveSessionProvider)!.session.songStatuses, isEmpty);
    expect(
      tester.getTopLeft(find.text('Wonderwall')).dy <
          tester.getTopLeft(find.text('Hey Jude')).dy,
      isTrue,
    );
  });
}
