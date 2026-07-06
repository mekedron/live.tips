import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/widgets/donation_tile.dart';

Donation tip({String? paymentIntentId}) => Donation(
      id: 'cs_1',
      amountMinor: 500,
      currency: 'eur',
      createdAt: DateTime.utc(2026, 7, 4),
      name: 'Maya',
      paymentIntentId: paymentIntentId,
    );

Widget host(Widget child) =>
    MaterialApp(theme: buildLightTheme(), home: Scaffold(body: child));

void main() {
  testWidgets('a tappable tile fires onTap and shows the open-in-new hint',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(DonationTile(
      donation: tip(paymentIntentId: 'pi_1'),
      showTime: true,
      onTap: () => taps++,
    )));

    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    await tester.tap(find.byType(DonationTile));
    expect(taps, 1);
  });

  testWidgets('without onTap the tile is inert and shows no hint',
      (tester) async {
    await tester.pumpWidget(host(DonationTile(donation: tip(), showTime: true)));

    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });
}
