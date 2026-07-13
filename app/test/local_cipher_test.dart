import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_cipher.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The venue at-rest cipher: round trips, refuses tampering and foreign
/// keys, and passes pre-cipher plaintext through untouched.
void main() {
  test('round trip, unique envelopes per encryption', () {
    final cipher = LocalCipher(LocalCipher.newRootKey());
    const secret = '{"apiKey":"rk_live_abc","band":"The Foxes"}';
    final a = cipher.encrypt(secret);
    final b = cipher.encrypt(secret);
    expect(a, startsWith(LocalCipher.prefix));
    expect(a, isNot(b), reason: 'a fresh nonce every time');
    expect(cipher.decrypt(a), secret);
    expect(cipher.decrypt(b), secret);
  });

  test('tampering and foreign keys read as nothing, never as garbage', () {
    final cipher = LocalCipher(LocalCipher.newRootKey());
    final envelope = cipher.encrypt('payload');
    final tampered = '${envelope.substring(0, envelope.length - 4)}AAAA';
    expect(cipher.decrypt(tampered), isNull);
    final other = LocalCipher(LocalCipher.newRootKey());
    expect(other.decrypt(envelope), isNull);
    expect(cipher.decrypt('enc1:not:even:close'), isNull);
  });

  test('plaintext passes through — values from before the cipher attached',
      () {
    final cipher = LocalCipher(LocalCipher.newRootKey());
    expect(cipher.decrypt('{"plain":"json"}'), '{"plain":"json"}');
  });

  test('LocalStore writes envelopes at rest and reads them back', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final key = LocalCipher.newRootKey();
    final store = LocalStore(prefs)..cipher = LocalCipher(key);

    const jar = TipJar(
      paymentLinkId: 'plink_1',
      url: 'https://buy.stripe.com/x',
      productId: 'prod_1',
      priceId: 'price_1',
      displayName: 'The Foxes',
      currency: 'eur',
      livemode: true,
    );
    await store.saveTipJar('band1', jar);

    // On disk: an envelope, not the artist's data.
    final raw = prefs.getString(LocalStore.accountKey(
        LocalStore.kTipJarBase, 'band1'))!;
    expect(raw, startsWith(LocalCipher.prefix));
    expect(raw.contains('Foxes'), isFalse);

    // Through the store: the jar, transparently.
    expect(store.readTipJar('band1')!.displayName, 'The Foxes');

    // Without the key (fresh install, wiped keystore): nothing stored —
    // never ciphertext handed to a JSON parser.
    final blind = LocalStore(prefs);
    expect(blind.readTipJar('band1'), isNull);

    // The device kind stays plaintext on purpose: it decides whether the
    // cipher attaches at all, so even a keyless reader must see it.
    await store.saveDeviceKind(DeviceKind.venue);
    expect(blind.readDeviceKind(), DeviceKind.venue);
  });
}
