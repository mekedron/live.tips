import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/widgets/tip_tile.dart';
import 'helpers.dart';

Tip tip({String? paymentIntentId}) => Tip(
  id: 'cs_1',
  amountMinor: 500,
  currency: 'eur',
  createdAt: DateTime.utc(2026, 7, 4),
  name: 'Maya',
  paymentIntentId: paymentIntentId,
);

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: kTestL10nDelegates,

  locale: const Locale('en'),
  theme: buildLightTheme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a tappable tile fires onTap and shows the open-in-new hint', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        TipTile(
          tip: tip(paymentIntentId: 'pi_1'),
          showTime: true,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    await tester.tap(find.byType(TipTile));
    expect(taps, 1);
  });

  testWidgets('without onTap the tile is inert and shows no hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(TipTile(tip: tip(), showTime: true)),
    );

    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a relay tip carries the method badge and the unverified pill', (
    tester,
  ) async {
    final tip = Tip(
      id: 'relay_1',
      amountMinor: 500,
      currency: 'eur',
      createdAt: DateTime.utc(2026, 7, 4),
      name: 'Maya',
      method: TipMethod.mobilepay,
      verified: false,
    );
    await tester.pumpWidget(host(TipTile(tip: tip)));

    expect(find.text('MobilePay'), findsOneWidget);
    expect(find.byIcon(Icons.smartphone), findsOneWidget);
    expect(find.text('unverified'), findsOneWidget);
  });

  testWidgets(
      'an in-person tap shows the in-person pill — anonymous, but never '
      '"unverified": Stripe saw the card', (tester) async {
    final tip = Tip(
      id: 'ch_tap',
      amountMinor: 700,
      currency: 'eur',
      createdAt: DateTime.utc(2026, 7, 4),
      inPerson: true,
    );
    await tester.pumpWidget(host(TipTile(tip: tip)));

    expect(find.text('in person'), findsOneWidget);
    expect(find.byIcon(Icons.contactless_rounded), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget);
    expect(find.text('unverified'), findsNothing);
  });

  testWidgets('an ordinary Stripe tip shows neither badge', (tester) async {
    await tester.pumpWidget(host(TipTile(tip: tip())));

    expect(find.text('unverified'), findsNothing);
    expect(find.byIcon(Icons.smartphone), findsNothing);
    expect(
      find.byIcon(Icons.credit_card),
      findsNothing,
      reason: 'card is the norm — only the exceptions get badged',
    );
  });
}
