import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/features/settings/song_requests_screen.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

const _tipJar = TipJar(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/test_requests',
  currency: 'eur',
  displayName: 'The Midnight Foxes',
  livemode: false,
);

/// A EUR jar offering Revolut and MobilePay; Monzo is not set up, so its
/// checkbox must not appear at all.
const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Midnight Foxes',
  currency: 'eur',
  revolutUsername: 'foxy',
  mobilepayBoxId: 'box-1234',
  createdAtMs: 1,
);

Future<({LocalStore store, FakeCallables backend})> _pump(
  WidgetTester tester, {
  RelayJar jar = _relayJar,
  bool withStripe = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = await seededStore(accountValues: {
    LocalStore.kRelayJarBase: jsonEncode(jar.toJson()),
    if (withStripe) LocalStore.kTipJarBase: jsonEncode(_tipJar.toJson()),
  });
  final backend = FakeCallables();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(
          withStripe ? 'rk_test_0123456789abcd' : null,
        ),
        initialRelaySecretProvider.overrideWithValue('sec'),
        relayClientProvider.overrideWithValue(fakeRelayClient(backend)),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const SongRequestsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (store: store, backend: backend);
}

void main() {
  testWidgets('toggling enable persists via updateBand and publishes to the '
      'jar', (tester) async {
    final (store: store, backend: backend) = await _pump(tester);

    expect(store.readBandSettings(kTestAccountId).songRequests.enabled,
        isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
        store.readBandSettings(kTestAccountId).songRequests.enabled, isTrue);
    // The save is also published — the whole config, at the band's jar,
    // with its secret.
    expect(backend.names, ['setJarRequests']);
    final args = backend.argsFor('setJarRequests');
    expect(args['jarId'], 'jar_1');
    expect(args['secret'], 'sec');
    expect((args['config'] as Map)['enabled'], isTrue);
  });

  testWidgets('adding a song shows it in the library and persists it',
      (tester) async {
    final (store: store, backend: backend) = await _pump(tester);

    await tester.tap(find.text('Add a song'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Song title'), 'Wonderwall');
    await tester.enterText(
        find.widgetWithText(TextField, 'Artist (optional)'), 'Oasis');
    await tester.tap(find.text('Save song'));
    await tester.pumpAndSettle();
    // Let the sheet's deferred controller disposal fire before teardown.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Wonderwall'), findsOneWidget);
    expect(find.text('Oasis'), findsOneWidget);
    final stored =
        store.readBandSettings(kTestAccountId).songRequests.songs.single;
    expect(stored.title, 'Wonderwall');
    expect(stored.artist, 'Oasis');
    expect(stored.priceMinor, isNull, reason: 'no override typed');
    // Published with the app-minted id, and the enforcing fake vouches for
    // its shape (it refuses foreign ids).
    final config = backend.argsFor('setJarRequests')['config'] as Map;
    final song = (config['songs'] as List).single as Map;
    expect(song['title'], 'Wonderwall');
    expect(song['id'], stored.id);
  });

  testWidgets('a song title over 60 code points is refused in the editor',
      (tester) async {
    final (store: store, backend: backend) = await _pump(tester);

    await tester.tap(find.text('Add a song'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Song title'), 'X' * 61);
    await tester.tap(find.text('Save song'));
    await tester.pumpAndSettle();

    expect(find.text('Song titles fit in 60 characters.'), findsOneWidget);
    expect(store.readBandSettings(kTestAccountId).songRequests.songs,
        isEmpty);
    expect(backend.calls, isEmpty);
  });

  testWidgets('method checkboxes list only what the jar offers, and the '
      'currency rule disables what it must', (tester) async {
    // No Stripe → no Card row. Monzo isn't configured → no Monzo row.
    // MobilePay is configured and the jar is EUR → enabled.
    await _pump(tester);
    expect(find.text('Card'), findsNothing);
    expect(find.text('Monzo'), findsNothing);
    expect(find.text('Revolut'), findsOneWidget);
    expect(find.text('MobilePay'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((box) => box.onChanged != null),
        isTrue);
  });

  testWidgets('with Stripe connected the Card checkbox appears too',
      (tester) async {
    await _pump(tester, withStripe: true);
    expect(find.text('Card'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('a non-EUR jar offers MobilePay disabled, with the reason',
      (tester) async {
    await _pump(tester,
        jar: _relayJar.copyWith(currency: 'dkk'));

    expect(find.text('MobilePay'), findsOneWidget);
    expect(
        find.text('MobilePay requests need a EUR tip page.'), findsOneWidget);
    final boxes =
        tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes, hasLength(2));
    // Revolut stays tickable; MobilePay is the disabled one.
    expect(boxes.where((b) => b.onChanged == null), hasLength(1));
  });

  testWidgets('ticking a relay method persists it and raises the unverified '
      'warning', (tester) async {
    final (store: store, backend: backend) = await _pump(tester);

    const warning =
        "Revolut, MobilePay and Monzo payments are unverified — the app "
        "can't confirm a fan actually paid. Verify each request yourself "
        "during the set.";
    expect(find.text(warning), findsNothing);

    // The first checkbox is Revolut (offered order: revolut, mobilepay).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text(warning), findsOneWidget);
    expect(store.readBandSettings(kTestAccountId).songRequests.methods,
        ['revolut']);
    final config = backend.argsFor('setJarRequests')['config'] as Map;
    expect(config['methods'], ['revolut']);
  });
}
