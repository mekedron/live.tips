import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/history/history_screen.dart';
import 'package:live_tips/features/history/session_detail_screen.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/widgets/tip_tile.dart';

import 'helpers.dart';

/// A plain donation — no songId, exactly what every pre-#64 archive holds.
Tip plain(String id, int amount, {String? name, int minute = 0}) => Tip(
      id: id,
      amountMinor: amount,
      currency: 'usd',
      createdAt: DateTime(2026, 7, 3, 21, minute),
      livemode: false,
      name: name,
    );

/// A song-request tip, same shape as test/request_queue_test.dart's fixtures.
Tip request(
  String id,
  int amount, {
  required String songId,
  String? songTitle,
  int minute = 0,
  bool verified = true,
  String? name,
}) =>
    Tip(
      id: id,
      amountMinor: amount,
      currency: 'usd',
      createdAt: DateTime(2026, 7, 3, 21, minute),
      livemode: false,
      songId: songId,
      songTitle: songTitle,
      verified: verified,
      name: name,
    );

/// A finalized archived session: started 20:00, stopped 23:00 (3:00:00).
LiveSession session({
  List<Tip> tips = const [],
  Map<String, String>? songStatuses,
  int goalMinor = 0,
}) =>
    LiveSession(
      id: 'ses_1',
      startedAt: DateTime(2026, 7, 3, 20),
      endedAt: DateTime(2026, 7, 3, 23),
      currency: 'usd',
      goalMinor: goalMinor,
      tips: tips,
      songStatuses: songStatuses,
    );

/// Pumps the page directly — the content tests; navigation gets its own
/// HistoryScreen pump below.
Future<void> pumpDetail(WidgetTester tester, LiveSession s) async {
  final store = await seededStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(SecureStore()),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: SessionDetailScreen(session: s),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'tapping a session card pushes the page (no bottom sheet), and back '
    'pops to History',
    (tester) async {
      final s = session(
        tips: [plain('a', 500, name: 'Maya'), plain('b', 300, minute: 5)],
        goalMinor: 10000,
      );
      final store = await seededStore(
        accountValues: {
          LocalStore.kHistoryBase: jsonEncode([s.toJson()]),
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            secureStoreProvider.overrideWithValue(SecureStore()),
          ],
          child: MaterialApp(
            localizationsDelegates: kTestL10nDelegates,
            locale: const Locale('en'),
            theme: buildLightTheme(),
            home: const Scaffold(body: HistoryScreen()),
          ),
        ),
      );
      await tester.pump();

      // The archived session's card, on the Sessions tab (its meta line —
      // the bare '$8' also lives in the all-time stat card above).
      expect(find.byType(SessionDetailScreen), findsNothing);
      await tester.tap(find.textContaining('2 tips'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing,
          reason: 'the sheet is gone from the codebase — one honest surface');
      expect(find.text('Maya'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SessionDetailScreen), findsNothing);
      expect(find.byType(HistoryScreen), findsOneWidget,
          reason: 'back pops to History, still mounted under the route');
    },
  );

  testWidgets('header carries the sheet story: total, meta line with the '
      'goal-reached suffix, and the goal chip', (tester) async {
    await pumpDetail(
      tester,
      session(
        tips: [plain('a', 8000), plain('b', 4000, minute: 10)],
        goalMinor: 10000,
      ),
    );

    expect(find.text(r'$120'), findsOneWidget);
    expect(find.textContaining('2 tips'), findsOneWidget);
    expect(find.textContaining('3:00:00'), findsOneWidget);
    expect(find.textContaining('goal reached'), findsOneWidget);
    expect(find.text('120%'), findsOneWidget, reason: 'the session card chip');
  });

  testWidgets('donations list the sheet showed: TipTiles, newest first',
      (tester) async {
    await pumpDetail(
      tester,
      session(tips: [
        plain('a', 500, name: 'Older'),
        plain('b', 300, name: 'Newer', minute: 30),
      ]),
    );

    expect(find.text('DONATIONS'), findsOneWidget);
    expect(find.byType(TipTile), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Newer')).dy <
          tester.getTopLeft(find.text('Older')).dy,
      isTrue,
      reason: 'newest first, as the sheet listed them',
    );
  });

  testWidgets(
    'requests section: RequestQueue ranking, requester counts, and the '
    'played badge on the sunk card',
    (tester) async {
      // The PRD acceptance: Angels ($25, never played) outranks Africa
      // (2 × $5, played) — money left on the table first, verdicts sunk.
      await pumpDetail(
        tester,
        session(
          tips: [
            request('a', 2500, songId: 'sng_angels', songTitle: 'Angels'),
            request('b', 500,
                songId: 'sng_africa', songTitle: 'Africa', minute: 1),
            request('c', 500,
                songId: 'sng_africa', songTitle: 'Africa', minute: 2),
            plain('d', 999),
          ],
          songStatuses: {'sng_africa': LiveSession.statusPlayed},
        ),
      );

      expect(find.text('REQUESTS'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Angels')).dy <
            tester.getTopLeft(find.text('Africa')).dy,
        isTrue,
        reason: 'active before sunk — the queue as the set ended',
      );
      expect(find.textContaining('2 requests'), findsOneWidget);
      expect(find.text('Played'), findsOneWidget,
          reason: 'the verdict chip, not a button — this page is read-only');
      expect(find.text('Skip'), findsNothing);
      expect(find.byType(Switch), findsNothing,
          reason: 'no pause lever on a closed set');
    },
  );

  testWidgets(
    'expanding a song shows its tips with unverified tags — and no '
    'mark-verified action',
    (tester) async {
      await pumpDetail(
        tester,
        session(tips: [
          request('r1', 500,
              songId: 'sng_1',
              songTitle: 'Wonderwall',
              verified: false,
              name: 'Maya'),
          request('r2', 300, songId: 'sng_1', songTitle: 'Wonderwall',
              minute: 5),
        ]),
      );

      expect(find.text('1 unverified'), findsOneWidget);

      await tester.tap(find.text('Wonderwall'));
      await tester.pump();

      // Maya appears twice: her donation row and her request row.
      expect(find.text('Maya'), findsNWidgets(2));
      expect(find.text('unverified'), findsWidgets,
          reason: 'the archive keeps the never-vouched-for tag forever');
      expect(find.text('Mark verified'), findsNothing,
          reason: 'history is a record, not a control surface');
    },
  );

  testWidgets(
    'a legacy / requests-off session gets no requests section at all',
    (tester) async {
      await pumpDetail(
        tester,
        session(tips: [plain('a', 500, name: 'Maya')]),
      );

      expect(find.text('DONATIONS'), findsOneWidget);
      expect(find.text('REQUESTS'), findsNothing,
          reason: 'pre-#64 archives read exactly like the sheet did, '
              'in page form — no empty-section noise');
    },
  );

  testWidgets('a session with no tips keeps the honest empty line',
      (tester) async {
    await pumpDetail(tester, session());

    expect(find.text('No tips in this session.'), findsOneWidget);
    expect(find.text('DONATIONS'), findsNothing);
    expect(find.text('REQUESTS'), findsNothing);
  });
}
