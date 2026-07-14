import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/live_session.dart';

Tip tip(String id, int amount) => Tip(
      id: id,
      amountMinor: amount,
      currency: 'usd',
      createdAt: DateTime(2026, 7, 3, 21),
      name: 'Fan',
    );

void main() {
  LiveSession session({int goal = 10000}) => LiveSession(
        id: 'ses_1',
        startedAt: DateTime(2026, 7, 3, 20),
        currency: 'usd',
        goalMinor: goal,
      );

  test('accumulates totals and stats', () {
    final s = session();
    s.addTip(tip('a', 500));
    s.addTip(tip('b', 2500));
    s.addTip(tip('c', 1000));
    expect(s.totalMinor, 4000);
    expect(s.count, 3);
    expect(s.averageMinor, 1333);
    expect(s.biggest!.id, 'b');
    expect(s.progress, 0.4);
    expect(s.goalReached, isFalse);
  });

  test('ignores duplicate tip ids', () {
    final s = session();
    expect(s.addTip(tip('a', 500)), isTrue);
    expect(s.addTip(tip('a', 500)), isFalse);
    expect(s.count, 1);
  });

  test('progress clamps at 1.0 and goalReached flips', () {
    final s = session(goal: 1000);
    s.addTip(tip('a', 2500));
    expect(s.progress, 1.0);
    expect(s.goalReached, isTrue);
  });

  test('json round trip keeps tips and dedupe works after restore', () {
    final s = session();
    s.addTip(tip('a', 500));
    s.addTip(tip('b', 700));
    s.goalMinor = 20000;

    final restored = LiveSession.fromJson(s.toJson());
    expect(restored.totalMinor, 1200);
    expect(restored.goalMinor, 20000);
    expect(restored.count, 2);
    // restored sessions must still refuse duplicates (crash recovery path)
    expect(restored.addTip(tip('a', 500)), isFalse);
    expect(restored.addTip(tip('c', 300)), isTrue);
  });

  group('song requests (#64)', () {
    test('requestsOpen and songStatuses round-trip through json', () {
      final s = session()..requestsOpen = true;
      s.addTip(tip('a', 500));
      s.setSongStatus('sng_1', LiveSession.statusPlayed);
      s.setSongStatus('sng_2', LiveSession.statusSkipped);
      s.setSongStatus('sng_3', 'x'); // unknown status: dropped, not stored
      s.clearSongStatus('sng_2');

      final restored = LiveSession.fromJson(s.toJson());
      expect(restored.requestsOpen, isTrue);
      expect(restored.songStatuses, {'sng_1': LiveSession.statusPlayed});
      expect(restored.count, 1);
    });

    test('a pre-requests session serializes byte-identically — no new keys',
        () {
      final s = session();
      s.addTip(tip('a', 500));
      // The exact blob this session stored before song requests existed. A
      // single always-written key here would rewrite every crash snapshot
      // and every archived night on its next save.
      expect(s.toJson(), {
        'id': 'ses_1',
        'startedAt': DateTime(2026, 7, 3, 20).millisecondsSinceEpoch,
        'currency': 'usd',
        'goalMinor': 10000,
        'bankedMinor': 0,
        'bankedJars': 0,
        'tips': [tip('a', 500).toJson()],
      });
    });

    test('replaceSongStatuses swaps the whole map, dropping garbage', () {
      final s = session();
      s.setSongStatus('sng_old', LiveSession.statusPlayed);
      s.replaceSongStatuses(
          {'sng_new': LiveSession.statusSkipped, 'sng_bad': 'z'});
      expect(s.songStatuses, {'sng_new': LiveSession.statusSkipped});
    });

    test('replaceTip swaps in place by id, keeping order and dedupe', () {
      final s = session();
      s.addTip(tip('a', 500));
      s.addTip(tip('b', 700));

      final flipped = tip('a', 500).copyWith(verified: true, name: 'Maya');
      expect(s.replaceTip(flipped), isTrue);
      expect(s.tips.map((t) => t.id), ['a', 'b'], reason: 'order kept');
      expect(s.tips.first.name, 'Maya');
      expect(s.totalMinor, 1200);
      // _ids stays consistent: the replaced id still refuses re-ingest.
      expect(s.addTip(tip('a', 500)), isFalse);
    });

    test('replaceTip is a no-op for an unknown id — never an insert', () {
      final s = session();
      s.addTip(tip('a', 500));
      expect(s.replaceTip(tip('ghost', 900)), isFalse);
      expect(s.count, 1);
      expect(s.totalMinor, 500);
    });
  });

  test('a stored blob with no tips key loads empty instead of throwing', () {
    // A session written by a build that predates the tip rename carries its
    // list under a key we no longer read. That blob must degrade to an empty
    // session — never take the app down on boot.
    final stale = {
      'id': 's1',
      'startedAt': DateTime(2026, 7, 1).millisecondsSinceEpoch,
      'currency': 'usd',
      'goalMinor': 10000,
      'donations': [
        {
          'id': 'a',
          'amountMinor': 500,
          'currency': 'usd',
          'createdAt': DateTime(2026, 7, 1).millisecondsSinceEpoch,
        },
      ],
    };

    final restored = LiveSession.fromJson(stale);
    expect(restored.count, 0);
    expect(restored.totalMinor, 0);
    expect(restored.goalMinor, 10000);
    // and it is a perfectly usable session from there on
    expect(restored.addTip(tip('a', 500)), isTrue);
    expect(restored.totalMinor, 500);
  });
}
