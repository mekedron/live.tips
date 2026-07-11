import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/state/providers.dart';

const _tipJar = TipJar(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/test_state',
  currency: 'eur',
  displayName: 'The Midnight Foxes',
  livemode: true,
);

const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'Foxy Live',
  currency: 'dkk',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

AppState _state({
  String? apiKey,
  TipJar? tipJar,
  RelayJar? relayJar,
  QrMode qrMode = QrMode.connected,
  bool demo = false,
  String accountId = '',
  List<BandAccount> accounts = const [],
}) =>
    AppState(
      accountId: accountId,
      accounts: accounts,
      apiKey: apiKey,
      tipJar: tipJar,
      relayJar: relayJar,
      settings: const AppSettings(),
      band: BandSettings(qrMode: qrMode),
      demo: demo,
    );

void main() {
  group('connected / hasStripe / hasRelay', () {
    test('nothing configured → not connected', () {
      final s = _state();
      expect(s.hasStripe, isFalse);
      expect(s.hasRelay, isFalse);
      expect(s.connected, isFalse);
    });

    test('a Stripe key alone connects (today\'s behavior)', () {
      final s = _state(apiKey: 'rk_live_x', tipJar: _tipJar);
      expect(s.hasStripe, isTrue);
      expect(s.hasRelay, isFalse);
      expect(s.connected, isTrue);
    });

    test('a relay jar alone connects — no Stripe key needed', () {
      final s = _state(relayJar: _relayJar);
      expect(s.hasStripe, isFalse);
      expect(s.hasRelay, isTrue);
      expect(s.connected, isTrue);
    });

    test('demo alone connects', () {
      expect(_state(demo: true).connected, isTrue);
    });
  });

  group('effectiveQrMode clamps the setting to what exists', () {
    test('both configured → the setting wins, both ways', () {
      expect(
        _state(tipJar: _tipJar, relayJar: _relayJar, qrMode: QrMode.connected)
            .effectiveQrMode,
        QrMode.connected,
      );
      expect(
        _state(tipJar: _tipJar, relayJar: _relayJar, qrMode: QrMode.stripe)
            .effectiveQrMode,
        QrMode.stripe,
      );
    });

    test('only Stripe → always stripe, even when the setting says connected',
        () {
      expect(
        _state(tipJar: _tipJar, qrMode: QrMode.connected).effectiveQrMode,
        QrMode.stripe,
      );
      expect(
        _state(tipJar: _tipJar, qrMode: QrMode.stripe).effectiveQrMode,
        QrMode.stripe,
      );
    });

    test('only relay → always connected, even when the setting says stripe',
        () {
      expect(
        _state(relayJar: _relayJar, qrMode: QrMode.connected).effectiveQrMode,
        QrMode.connected,
      );
      expect(
        _state(relayJar: _relayJar, qrMode: QrMode.stripe).effectiveQrMode,
        QrMode.connected,
      );
    });

    test('neither configured → stripe, both ways', () {
      expect(_state(qrMode: QrMode.connected).effectiveQrMode, QrMode.stripe);
      expect(_state(qrMode: QrMode.stripe).effectiveQrMode, QrMode.stripe);
    });
  });

  group('activeQrUrl', () {
    test('follows the effective mode when both jars exist', () {
      expect(
        _state(tipJar: _tipJar, relayJar: _relayJar, qrMode: QrMode.connected)
            .activeQrUrl,
        _relayJar.tipUrl,
      );
      expect(
        _state(tipJar: _tipJar, relayJar: _relayJar, qrMode: QrMode.stripe)
            .activeQrUrl,
        _tipJar.url,
      );
    });

    test('Stripe-only resolves to the payment link whatever the setting', () {
      expect(
          _state(tipJar: _tipJar, qrMode: QrMode.connected).activeQrUrl,
          _tipJar.url);
    });

    test('relay-only resolves to the fan page whatever the setting', () {
      expect(_state(relayJar: _relayJar, qrMode: QrMode.stripe).activeQrUrl,
          _relayJar.tipUrl);
    });

    test('nothing configured → null (surfaces hide, never crash)', () {
      expect(_state().activeQrUrl, isNull);
    });
  });

  group('demo substitutes the demo jars', () {
    test('effective jars are the demo singletons', () {
      final s = _state(demo: true);
      expect(s.effectiveTipJar, same(TipJar.demo));
      expect(s.effectiveRelayJar, same(RelayJar.demo));
      expect(s.hasBothQrModes, isTrue);
    });

    test('demo QR follows the setting like a fully configured install', () {
      expect(_state(demo: true, qrMode: QrMode.connected).activeQrUrl,
          RelayJar.demo.tipUrl);
      expect(_state(demo: true, qrMode: QrMode.stripe).activeQrUrl,
          TipJar.demo.url);
    });
  });

  group('displayName precedence: Stripe jar → relay jar → empty', () {
    test('Stripe jar name wins when present', () {
      expect(_state(tipJar: _tipJar, relayJar: _relayJar).displayName,
          _tipJar.displayName);
    });

    test('relay-only uses the relay artist name', () {
      expect(_state(relayJar: _relayJar).displayName, _relayJar.artistName);
    });

    test('an empty Stripe jar name falls through to the relay jar', () {
      final blankName = _tipJar.copyWith(displayName: '');
      expect(_state(tipJar: blankName, relayJar: _relayJar).displayName,
          _relayJar.artistName);
    });

    test('nothing configured → empty string', () {
      expect(_state().displayName, '');
    });
  });

  group('registry-name precedence: active account name beats the jars', () {
    test('the active account\'s registry name wins over both jar names', () {
      final s = _state(
        tipJar: _tipJar,
        relayJar: _relayJar,
        accountId: 'a',
        accounts: const [BandAccount(id: 'a', name: 'Foxes', createdAtMs: 0)],
      );
      expect(s.displayName, 'Foxes');
    });

    test('an empty registry name falls through to the jar chain', () {
      const unnamed = [BandAccount(id: 'a', name: '', createdAtMs: 0)];
      expect(
        _state(
          tipJar: _tipJar,
          relayJar: _relayJar,
          accountId: 'a',
          accounts: unnamed,
        ).displayName,
        _tipJar.displayName,
      );
      expect(
        _state(relayJar: _relayJar, accountId: 'a', accounts: unnamed)
            .displayName,
        _relayJar.artistName,
      );
    });
  });

  group('currency precedence: Stripe jar → relay jar → usd', () {
    test('Stripe jar wins', () {
      expect(_state(tipJar: _tipJar, relayJar: _relayJar).currency, 'eur');
    });

    test('relay-only uses the relay jar currency', () {
      expect(_state(relayJar: _relayJar).currency, 'dkk');
    });

    test('nothing configured falls back to usd', () {
      expect(_state().currency, 'usd');
    });
  });

  test('hasBothQrModes only with both jars', () {
    expect(_state(tipJar: _tipJar, relayJar: _relayJar).hasBothQrModes,
        isTrue);
    expect(_state(tipJar: _tipJar).hasBothQrModes, isFalse);
    expect(_state(relayJar: _relayJar).hasBothQrModes, isFalse);
  });
}
