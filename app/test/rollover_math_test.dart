import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/live_session.dart';

Tip d(String id, int amountMinor) => Tip(
      id: id,
      amountMinor: amountMinor,
      currency: 'eur',
      createdAt: DateTime.utc(2026, 7, 3),
      livemode: false,
    );

LiveSession session({int goal = 10000}) => LiveSession(
      id: 'ses_test',
      startedAt: DateTime.utc(2026, 7, 3),
      currency: 'eur',
      goalMinor: goal,
    );

void main() {
  group('rollover accounting', () {
    test('conservation invariant holds through arbitrary tips', () {
      final s = session(goal: 10000);
      final amounts = [500, 12000, 900, 19999, 1, 20000, 333, 65000];
      var i = 0;
      for (final a in amounts) {
        s.addTipAttributed(d('cs_$i', a));
        i++;
        expect(s.bankedMinor + s.currentJarMinor, s.totalMinor,
            reason: 'banked + current == total after tip $i');
        expect(s.jarPct, lessThan(2.0),
            reason: 'eager banking keeps the jar under the brim');
        expect(s.bankedMinor, s.bankedJars * 2 * 10000,
            reason: 'each trophy banks exactly 2× goal');
      }
    });

    test('exact 2× goal rolls over and leaves an empty jar', () {
      final s = session(goal: 10000);
      final tip = s.addTipAttributed(d('cs_1', 20000))!;
      expect(tip.rollovers, 1);
      expect(tip.jarPctAfter, 0);
      expect(tip.bankedJarsAfter, 1);
      expect(s.bankedMinor, 20000);
      expect(s.currentJarMinor, 0);
    });

    test('a giant tip rolls multiple jars and keeps the overshoot', () {
      final s = session(goal: 10000);
      s.addTipAttributed(d('cs_1', 1500)); // 15% head start
      final tip = s.addTipAttributed(d('cs_2', 45000))!;
      // 1500 + 45000 = 46500 → two jars of 20000 + 6500 in the fresh one
      expect(tip.rollovers, 2);
      expect(s.bankedJars, 2);
      expect(s.bankedMinor, 40000);
      expect(s.currentJarMinor, 6500);
      expect(tip.jarPctAfter, closeTo(0.65, 1e-9));
    });

    test('lowering the goal mid-session owes rollovers immediately', () {
      final s = session(goal: 10000);
      s.addTipAttributed(d('cs_1', 15000)); // 150%, no rollover
      expect(s.bankedJars, 0);
      s.goalMinor = 3000; // "actually, tonight €30 is the goal"
      final rolled = s.applyRollovers();
      // 15000 ≥ 2×3000 twice: bank 6000 + 6000, keep 3000 (jarPct 1.0)
      expect(rolled, 2);
      expect(s.bankedMinor, 12000);
      expect(s.currentJarMinor, 3000);
      expect(s.jarPct, closeTo(1.0, 1e-9));
    });

    test('raising the goal never un-banks trophies', () {
      final s = session(goal: 5000);
      s.addTipAttributed(d('cs_1', 10000)); // exactly one trophy
      expect(s.bankedJars, 1);
      s.goalMinor = 100000;
      expect(s.applyRollovers(), 0);
      expect(s.bankedJars, 1);
      expect(s.bankedMinor, 10000);
    });

    test('zero/negative goal is guarded (no infinite loop, no attribution math)',
        () {
      final s = session(goal: 10000);
      s.goalMinor = 0;
      final tip = s.addTipAttributed(d('cs_1', 500))!;
      expect(s.applyRollovers(), 0);
      expect(tip.deltaPct, 0);
      expect(tip.jarPctAfter, 0);
      expect(s.jarPct, 0);
    });

    test('duplicate tips attribute null and change nothing', () {
      final s = session(goal: 10000);
      expect(s.addTipAttributed(d('cs_1', 500)), isNotNull);
      expect(s.addTipAttributed(d('cs_1', 500)), isNull);
      expect(s.count, 1);
      expect(s.totalMinor, 500);
    });

    test('attribution captures the fill fraction of the receiving jar', () {
      final s = session(goal: 10000);
      final t1 = s.addTipAttributed(d('cs_1', 5000))!;
      expect(t1.deltaPct, closeTo(0.5, 1e-9));
      expect(t1.jarPctAfter, closeTo(0.5, 1e-9));
      expect(t1.rollovers, 0);
      final t2 = s.addTipAttributed(d('cs_2', 12000))!;
      expect(t2.deltaPct, closeTo(1.2, 1e-9));
      expect(t2.jarPctAfter, closeTo(1.7, 1e-9));
      expect(t2.rollovers, 0);
    });

    test('banked fields survive a JSON round-trip and default for old blobs',
        () {
      final s = session(goal: 10000);
      s.addTipAttributed(d('cs_1', 25000));
      final revived = LiveSession.fromJson(s.toJson());
      expect(revived.bankedMinor, s.bankedMinor);
      expect(revived.bankedJars, s.bankedJars);
      expect(revived.currentJarMinor, s.currentJarMinor);

      // a pre-upgrade blob has no banked keys
      final legacy = s.toJson()
        ..remove('bankedMinor')
        ..remove('bankedJars');
      final old = LiveSession.fromJson(legacy);
      expect(old.bankedMinor, 0);
      expect(old.bankedJars, 0);
      // …and applyRollovers catches it up on resume
      expect(old.applyRollovers(), 1);
      expect(old.bankedMinor, 20000);
    });
  });
}
