import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/features/home/home_screen.dart';

/// Regression for the live-mode gap: the home "Recent tips" card was fed by
/// the Stripe API alone, so tip-page (Revolut/MobilePay) tips — which Stripe
/// never sees — could not appear in it. The card now merges the device-local
/// archive in via [mergeRecentTips].
void main() {
  Tip stripe(String id, DateTime at) => Tip(
        id: id,
        amountMinor: 500,
        currency: 'eur',
        createdAt: at,
      );

  Tip relay(int serial, DateTime at) => Tip.relayTip(
        amountMinor: 700,
        currency: 'eur',
        method: TipMethod.revolut,
        name: 'Maya',
        message: null,
        ts: at.millisecondsSinceEpoch,
        serial: serial,
      );

  final base = DateTime.utc(2026, 7, 6, 20);

  test('relay tips interleave with Stripe tips, newest first', () {
    final merged = mergeRecentTips(
      [stripe('cs_2', base.add(const Duration(minutes: 20))), stripe('cs_1', base)],
      [relay(0, base.add(const Duration(minutes: 10)))],
    );
    expect(merged.map((d) => d.id), [
      'cs_2',
      'relay_${base.add(const Duration(minutes: 10)).millisecondsSinceEpoch}_0',
      'cs_1',
    ]);
  });

  test('the preview stays capped at its limit', () {
    final merged = mergeRecentTips(
      [for (var i = 0; i < 5; i++) stripe('cs_$i', base.add(Duration(minutes: i)))],
      [for (var i = 0; i < 5; i++) relay(i, base.add(Duration(minutes: 30 + i)))],
    );
    expect(merged, hasLength(5));
    expect(merged.every((d) => !d.verified), isTrue,
        reason: 'the five relay tips are the five newest');
  });

  test('relay-only installs (empty Stripe list) still get a preview', () {
    final merged = mergeRecentTips(const [], [relay(0, base)]);
    expect(merged, hasLength(1));
    expect(merged.single.method, TipMethod.revolut);
  });
}
