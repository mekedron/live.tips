// Issue #11: "Resume session" was a dead button when another device holds
// the session. The coordinator throws SessionAlreadyActiveException and
// neither resumeStored() call site caught it — the exception escaped the
// button's async handler and the tap did nothing. Home must absorb it into
// the same "already running — join it from the banner" snackbar Go live
// shows.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';

import 'helpers.dart';

const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Midnight Foxes',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

/// A coordinator whose start() always refuses: the account already runs a
/// session on another device — exactly what the cloud coordinator throws
/// when a different device holds a fresh lease.
class _AlreadyActiveCoordinator implements SessionCoordinator {
  @override
  RelayHealth? get relayHealthSeed => null;

  @override
  bool get replaysTips => false;

  @override
  Future<void> start(LiveSession session,
      {String? resumeCursor, SessionStartMode mode = SessionStartMode.fresh}) {
    throw const SessionAlreadyActiveException(kTestAccountId);
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
  bool get serverComputesRequestTotals => false;

  @override
  Future<void> stop(LiveSession session, {bool durable = false}) async {}

  @override
  void reconnectNow() {}

  @override
  Future<void> dispose() async {}
}

Future<LocalStore> _pumpHomeWithStoredSession(WidgetTester tester) async {
  final stored = LiveSession(
    id: 'ses_stored',
    startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    currency: 'eur',
    goalMinor: 10000,
  );
  final localStore = await seededStore(accountValues: {
    LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
    LocalStore.kActiveSessionBase: jsonEncode(stored.toJson()),
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        sessionCoordinatorFactoryProvider
            .overrideWithValue((events) => _AlreadyActiveCoordinator()),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return localStore;
}

void main() {
  testWidgets(
      'Resume session row: the refusal surfaces as the already-live '
      'snackbar instead of escaping the tap handler', (tester) async {
    final localStore = await _pumpHomeWithStoredSession(tester);

    expect(find.text('Resume session'), findsOneWidget);
    await tester.tap(find.text('Resume session'));
    await tester.pumpAndSettle();

    // The one outcome that teaches the artist nothing is silence — the tap
    // must say who holds the session and point at the Join banner. (Before
    // the fix this line was never reached: the uncaught exception failed
    // the test zone.)
    expect(
      find.text('A live session is already running in Unnamed profile '
          '— join it from the banner above.'),
      findsOneWidget,
    );

    // Nothing half-started, and the snapshot survives for a later resume
    // (the session may still end elsewhere and become resumable-as-archive).
    expect(find.text('Resume session'), findsOneWidget);
    expect(localStore.readActiveSession(kTestAccountId), isNotNull);
  });

  testWidgets(
      'Go live → stored-session dialog → Resume it: same snackbar, '
      'no unhandled exception', (tester) async {
    await _pumpHomeWithStoredSession(tester);

    await tester.tap(find.text('Go live'));
    await tester.pumpAndSettle();
    expect(find.text('Unfinished session found'), findsOneWidget);

    await tester.tap(find.text('Resume it'));
    await tester.pumpAndSettle();

    expect(
      find.text('A live session is already running in Unnamed profile '
          '— join it from the banner above.'),
      findsOneWidget,
    );
  });
}
