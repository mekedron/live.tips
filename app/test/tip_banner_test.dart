import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/rollover_math.dart';
import 'package:live_tips/features/live/stage/stage_chrome.dart';
import 'package:live_tips/features/live/stage/stage_hud.dart';

JarTipAttribution tip(
  String id, {
  String? name,
  String? message,
  int amount = 500,
  double delta = 0.05,
}) =>
    JarTipAttribution(
      donation: Donation(
        id: id,
        amountMinor: amount,
        currency: 'eur',
        createdAt: DateTime.utc(2026, 7, 4),
        name: name,
        message: message,
        livemode: false,
      ),
      deltaPct: delta,
      jarPctAfter: 0.5,
      rollovers: 0,
      bankedJarsAfter: 0,
    );

Widget host(List<JarTipAttribution> tips, int serial) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: TipBannerLayer(tips: tips, tipSerial: serial),
      ),
    );

void main() {
  group('TipBannerLayer', () {
    testWidgets('a banner holds long enough to be read from the stage',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(host([tip('cs_1', name: 'Anna')], 1));
      await tester.pump(const Duration(milliseconds: 500)); // entrance

      expect(find.textContaining('Anna tipped'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('Anna tipped'), findsOneWidget,
          reason: 'the old floats died at 2.7 s — banners must survive 5 s');

      await tester.pump(const Duration(seconds: 2)); // past the 7 s hold
      await tester.pump(const Duration(milliseconds: 400)); // exit anim
      expect(find.textContaining('Anna tipped'), findsNothing);
    });

    testWidgets('a message extends the hold and is shown verbatim',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
          host([tip('cs_1', name: 'Maya', message: 'Great show!')], 1));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('“Great show!”'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8)); // past the plain hold
      expect(find.text('“Great show!”'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2)); // past the 10 s hold
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('“Great show!”'), findsNothing);
    });

    testWidgets('a burst queues — every donor gets their own moment',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
          host([tip('cs_1', name: 'Anna'), tip('cs_2', name: 'Marco')], 2));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Anna tipped'), findsOneWidget);
      expect(find.textContaining('Marco tipped'), findsNothing,
          reason: 'banners never overlap');

      // crowded hold (4 s) + gap + entrance → the queue advances
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Anna tipped'), findsNothing);
      expect(find.textContaining('Marco tipped'), findsOneWidget);

      // the last one in the queue gets the full quiet-night hold
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Marco tipped'), findsNothing);
    });

    testWidgets('a tip arriving mid-banner wraps the current one up sooner',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
          host([tip('cs_1', name: 'Anna', message: 'hi!')], 1));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(host([tip('cs_2', name: 'Marco')], 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Anna tipped'), findsOneWidget,
          reason: 'the current banner is never yanked away instantly');

      await tester.pump(const Duration(seconds: 2)); // wrap-up + gap passed
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Marco tipped'), findsOneWidget);
    });

    testWidgets('re-pumping the same serial does not re-enqueue',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      final batch = [tip('cs_1', name: 'Anna')];
      await tester.pumpWidget(host(batch, 1));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(host(batch, 1)); // same batch re-delivered

      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Anna tipped'), findsNothing,
          reason: 'a duplicate would replay Anna after the first hold');
    });

    testWidgets('a big tip (≥10% of goal) gets the crown treatment',
        (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
          host([tip('cs_1', name: 'Anna', amount: 5000, delta: 0.25)], 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('👑'), findsOneWidget);
    });
  });

  group('qrPanelMessageSlots', () {
    test('the QR always wins — messages only take the leftover height', () {
      expect(qrPanelMessageSlots(300), 0);
      expect(qrPanelMessageSlots(500), 0);
      expect(qrPanelMessageSlots(560), 1);
      expect(qrPanelMessageSlots(660), 2);
      expect(qrPanelMessageSlots(900), 3, reason: 'capped at 3');
    });
  });
}
