import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/live_session.dart';

Donation tip(String id, int amount) => Donation(
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
    s.addDonation(tip('a', 500));
    s.addDonation(tip('b', 2500));
    s.addDonation(tip('c', 1000));
    expect(s.totalMinor, 4000);
    expect(s.count, 3);
    expect(s.averageMinor, 1333);
    expect(s.biggest!.id, 'b');
    expect(s.progress, 0.4);
    expect(s.goalReached, isFalse);
  });

  test('ignores duplicate donation ids', () {
    final s = session();
    expect(s.addDonation(tip('a', 500)), isTrue);
    expect(s.addDonation(tip('a', 500)), isFalse);
    expect(s.count, 1);
  });

  test('progress clamps at 1.0 and goalReached flips', () {
    final s = session(goal: 1000);
    s.addDonation(tip('a', 2500));
    expect(s.progress, 1.0);
    expect(s.goalReached, isTrue);
  });

  test('json round trip keeps donations and dedupe works after restore', () {
    final s = session();
    s.addDonation(tip('a', 500));
    s.addDonation(tip('b', 700));
    s.goalMinor = 20000;

    final restored = LiveSession.fromJson(s.toJson());
    expect(restored.totalMinor, 1200);
    expect(restored.goalMinor, 20000);
    expect(restored.count, 2);
    // restored sessions must still refuse duplicates (crash recovery path)
    expect(restored.addDonation(tip('a', 500)), isFalse);
    expect(restored.addDonation(tip('c', 300)), isTrue);
  });
}
