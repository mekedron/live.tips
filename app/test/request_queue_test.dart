import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/fx_rates.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/request_queue.dart';
import 'package:live_tips/domain/tip.dart';

Tip request(
  String id,
  int amount, {
  required String songId,
  String? songTitle,
  String currency = 'usd',
  int minute = 0,
  bool verified = true,
}) =>
    Tip(
      id: id,
      amountMinor: amount,
      currency: currency,
      createdAt: DateTime(2026, 7, 3, 21, minute),
      songId: songId,
      songTitle: songTitle,
      verified: verified,
    );

LiveSession session({List<Tip>? tips}) => LiveSession(
      id: 'ses_1',
      startedAt: DateTime(2026, 7, 3, 20),
      currency: 'usd',
      goalMinor: 10000,
      tips: tips,
    );

void main() {
  test('groups by songId over request tips only; plain tips stay out', () {
    final s = session(tips: [
      Tip(
        id: 'plain',
        amountMinor: 9999,
        currency: 'usd',
        createdAt: DateTime(2026, 7, 3, 21),
      ),
      request('a', 500, songId: 'sng_1', songTitle: 'Wonderwall'),
      request('b', 300, songId: 'sng_1', songTitle: 'Wonderwall', minute: 5),
      request('c', 700, songId: 'sng_2', songTitle: 'Hey Jude'),
    ]);

    final queue = RequestQueue.fromSession(s);
    expect(queue.entries, hasLength(2));
    final wonderwall =
        queue.entries.firstWhere((e) => e.songId == 'sng_1');
    expect(wonderwall.totalMinor, 800);
    expect(wonderwall.requesterCount, 2);
    expect(wonderwall.tips.map((t) => t.id), ['b', 'a'],
        reason: 'per-entry tips are newest first');
  });

  test('title comes from the NEWEST tip that carries one', () {
    final s = session(tips: [
      request('a', 500, songId: 'sng_1', songTitle: 'Wonderwal (typo era)'),
      request('b', 300, songId: 'sng_1', songTitle: 'Wonderwall', minute: 9),
      request('c', 100, songId: 'sng_1', minute: 12), // no title stored
    ]);
    expect(RequestQueue.fromSession(s).entries.single.title, 'Wonderwall',
        reason: 'a titleless newest tip falls through to the newest titled');
  });

  test('ranking: total desc, then requester count, then newest-first', () {
    final s = session(tips: [
      // sng_rich: 1000 total, 1 requester
      request('a', 1000, songId: 'sng_rich', songTitle: 'Rich'),
      // sng_crowd: 800 via 2 requesters
      request('b', 400, songId: 'sng_crowd', songTitle: 'Crowd', minute: 1),
      request('c', 400, songId: 'sng_crowd', songTitle: 'Crowd', minute: 2),
      // sng_solo: 800 via 1 requester, older than crowd's newest
      request('d', 800, songId: 'sng_solo', songTitle: 'Solo', minute: 1),
      // sng_late ties sng_solo on every count but is newer
      request('e', 800, songId: 'sng_late', songTitle: 'Late', minute: 30),
    ]);

    expect(
      RequestQueue.fromSession(s).entries.map((e) => e.songId),
      ['sng_rich', 'sng_crowd', 'sng_late', 'sng_solo'],
    );
  });

  test('played and skipped sink below every active entry', () {
    final s = session(tips: [
      request('a', 5000, songId: 'sng_played', songTitle: 'Big but done'),
      request('b', 100, songId: 'sng_small', songTitle: 'Small but live'),
      request('c', 900, songId: 'sng_skipped', songTitle: 'Skipped'),
    ]);
    s.setSongStatus('sng_played', LiveSession.statusPlayed);
    s.setSongStatus('sng_skipped', LiveSession.statusSkipped);

    final entries = RequestQueue.fromSession(s).entries;
    expect(entries.map((e) => e.songId),
        ['sng_small', 'sng_played', 'sng_skipped'],
        reason: 'the sunk pile keeps the money order among itself');
    expect(entries[0].active, isTrue);
    expect(entries[1].status, LiveSession.statusPlayed);
    expect(entries[2].status, LiveSession.statusSkipped);
  });

  test('foreign-currency requests convert with fx, or count raw without it',
      () {
    final s = session(tips: [
      request('a', 500, songId: 'sng_1', songTitle: 'W'),
      request('b', 100, songId: 'sng_1', songTitle: 'W', currency: 'gbp'),
    ]);
    // No rates: the GBP tip counts at its raw minor amount — a rough rank
    // beats a vanished request (totalMinor would fold it as 0).
    expect(RequestQueue.fromSession(s).entries.single.totalMinor, 600);

    s.fx = FxRates(
      base: 'usd',
      rates: const {'gbp': 0.5},
      fetchedAt: DateTime(2026, 7, 3),
    );
    expect(RequestQueue.fromSession(s).entries.single.totalMinor, 700,
        reason: '£1.00 at 0.5/USD is \$2.00');
  });

  test('unverifiedCount counts the fan-declared tips in the group', () {
    final s = session(tips: [
      request('a', 500, songId: 'sng_1', songTitle: 'W', verified: false),
      request('b', 300, songId: 'sng_1', songTitle: 'W'),
    ]);
    expect(RequestQueue.fromSession(s).entries.single.unverifiedCount, 1);
  });

  group('toWirePayload', () {
    test('flat songId → {t, c, s} map, statuses on the wire', () {
      final s = session(tips: [
        request('a', 500, songId: 'sng_1', songTitle: 'W'),
        request('b', 300, songId: 'sng_1', songTitle: 'W', minute: 1),
        request('c', 700, songId: 'sng_2', songTitle: 'H'),
      ]);
      s.setSongStatus('sng_2', LiveSession.statusPlayed);

      expect(RequestQueue.fromSession(s).toWirePayload(), {
        'sng_1': {'t': 800, 'c': 2, 's': 'q'},
        'sng_2': {'t': 700, 'c': 1, 's': 'p'},
      });
    });

    test('caps at 150 entries BY RANK and clamps t/c to server bounds', () {
      final s = session(tips: [
        for (var i = 0; i < 160; i++)
          request('tip_$i', 160 - i, songId: 'sng_$i', songTitle: 'S$i'),
        // An absurd total and a requester horde, to hit both clamps.
        request('whale', 999999999, songId: 'sng_whale', songTitle: 'Whale'),
        for (var i = 0; i < 10001; i++)
          request('crowd_$i', 200, songId: 'sng_crowd', songTitle: 'Crowd'),
      ]);

      final wire = RequestQueue.fromSession(s).toWirePayload();
      expect(wire, hasLength(RequestQueue.maxWireEntries));
      expect(wire.containsKey('sng_whale'), isTrue,
          reason: 'the cap keeps the TOP of the ranking');
      expect(wire.containsKey('sng_159'), isFalse,
          reason: 'the cheapest requests are the ones dropped');
      expect((wire['sng_whale'] as Map)['t'], 100000000);
      expect((wire['sng_crowd'] as Map)['c'], 10000);
    });
  });
}
