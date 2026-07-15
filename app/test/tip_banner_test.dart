import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/rollover_math.dart';
import 'package:live_tips/features/live/stage/stage_chrome.dart';
import 'package:live_tips/features/live/stage/stage_hud.dart';
import 'helpers.dart';

JarTipAttribution tip(
  String id, {
  String? name,
  String? message,
  int amount = 500,
  double delta = 0.05,
  bool verified = true,
}) => JarTipAttribution(
  tip: Tip(
    id: id,
    amountMinor: amount,
    currency: 'eur',
    createdAt: DateTime.utc(2026, 7, 4),
    name: name,
    message: message,
    livemode: false,
    verified: verified,
  ),
  deltaPct: delta,
  jarPctAfter: 0.5,
  rollovers: 0,
  bankedJarsAfter: 0,
);

Widget host(List<JarTipAttribution> tips, int serial) => MaterialApp(
  localizationsDelegates: kTestL10nDelegates,

  locale: const Locale('en'),

  home: Scaffold(
    backgroundColor: Colors.black,
    body: TipBannerLayer(tips: tips, tipSerial: serial),
  ),
);

void main() {
  group('TipBannerLayer', () {
    testWidgets('a banner holds long enough to be read from the stage', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(host([tip('cs_1', name: 'Anna')], 1));
      await tester.pump(const Duration(milliseconds: 500)); // entrance

      expect(find.textContaining('Anna tipped'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(
        find.textContaining('Anna tipped'),
        findsOneWidget,
        reason: 'the old floats died at 2.7 s — banners must survive 5 s',
      );

      await tester.pump(const Duration(seconds: 2)); // past the 7 s hold
      await tester.pump(const Duration(milliseconds: 400)); // exit anim
      expect(find.textContaining('Anna tipped'), findsNothing);
    });

    testWidgets('a message extends the hold and is shown verbatim', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
        host([tip('cs_1', name: 'Maya', message: 'Great show!')], 1),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('“Great show!”'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8)); // past the plain hold
      expect(find.text('“Great show!”'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2)); // past the 10 s hold
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('“Great show!”'), findsNothing);
    });

    testWidgets('a burst queues — every fan gets their own moment', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
        host([tip('cs_1', name: 'Anna'), tip('cs_2', name: 'Marco')], 2),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Anna tipped'), findsOneWidget);
      expect(
        find.textContaining('Marco tipped'),
        findsNothing,
        reason: 'banners never overlap',
      );

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

    testWidgets('a tip arriving mid-banner wraps the current one up sooner', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
        host([tip('cs_1', name: 'Anna', message: 'hi!')], 1),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(host([tip('cs_2', name: 'Marco')], 2));
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining('Anna tipped'),
        findsOneWidget,
        reason: 'the current banner is never yanked away instantly',
      );

      await tester.pump(const Duration(seconds: 2)); // wrap-up + gap passed
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Marco tipped'), findsOneWidget);
    });

    testWidgets('re-pumping the same serial does not re-enqueue', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      final batch = [tip('cs_1', name: 'Anna')];
      await tester.pumpWidget(host(batch, 1));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(host(batch, 1)); // same batch re-delivered

      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.textContaining('Anna tipped'),
        findsNothing,
        reason: 'a duplicate would replay Anna after the first hold',
      );
    });

    testWidgets('a big tip (≥10% of goal) gets the crown treatment', (
      tester,
    ) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(
        host([tip('cs_1', name: 'Anna', amount: 5000, delta: 0.25)], 1),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('👑'), findsOneWidget);
    });

    testWidgets(
      'an unverified (fan-declared) tip shows ~ before the amount and '
      'NEVER gets the crown, however big',
      (tester) async {
        await tester.pumpWidget(host(const [], 0));
        await tester.pumpWidget(
          host([
            tip(
              'relay_1',
              name: 'Anna',
              amount: 5000,
              delta: 0.25,
              verified: false,
            ),
          ], 1),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.textContaining('👑'),
          findsNothing,
          reason: 'the crown must stay worth trusting',
        );
        expect(find.textContaining('tipped ~'), findsOneWidget);
      },
    );

    testWidgets('a verified tip shows the plain amount, no ~', (tester) async {
      await tester.pumpWidget(host(const [], 0));
      await tester.pumpWidget(host([tip('cs_1', name: 'Anna')], 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('~'), findsNothing);
    });
  });

  group('stageQrSize', () {
    test('fills the rail width (minus the card inset) when height allows', () {
      // Tall panel: width binds, so the code fills the inner width less the
      // white card's 24px inset.
      final size = stageQrSize(
        const BoxConstraints(maxWidth: 400, maxHeight: 1000),
        hasMessages: true,
      );
      expect(size, 376);
    });

    test('shrinks to leave the labels + one comment when the panel is short', () {
      // Short-and-wide: height binds. 500 - inset(24) - header(120) -
      // messagesHeader(48) - tile(84) = 224, well under the 576 the width offers.
      final size = stageQrSize(
        const BoxConstraints(maxWidth: 600, maxHeight: 500),
        hasMessages: true,
      );
      expect(size, 224);
    });

    test('with no comments the code may grow into the room they would take', () {
      const box = BoxConstraints(maxWidth: 600, maxHeight: 500);
      final withMessages = stageQrSize(box, hasMessages: true);
      final withoutMessages = stageQrSize(box, hasMessages: false);
      expect(withoutMessages, greaterThan(withMessages));
      expect(withoutMessages, 356); // 500 - inset(24) - header(120)
    });

    test('never collapses below the scannable floor', () {
      final size = stageQrSize(
        const BoxConstraints(maxWidth: 180, maxHeight: 200),
        hasMessages: true,
      );
      expect(size, 160);
    });
  });

  group('qrPanelMessageSlots', () {
    test('the QR always wins — messages only take the leftover height', () {
      // Consistent with a height-bound code: a 224px code in a 500px panel
      // leaves exactly one tile of room.
      expect(qrPanelMessageSlots(500, 224), 1);
      // A tighter fit leaves nothing.
      expect(qrPanelMessageSlots(500, 300), 0);
      // A tall panel with a width-bound code has room for the full three.
      expect(qrPanelMessageSlots(1000, 376), 3, reason: 'capped at 3');
      expect(qrPanelMessageSlots(600, 240), 2);
    });
  });
}
