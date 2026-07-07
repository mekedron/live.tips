import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/relay_jar.dart';

void main() {
  const jar = RelayJar(
    jarId: 'jar_abc',
    donateUrl: 'https://live.tips/t/jar_abc',
    artistName: 'Maya',
    currency: 'eur',
    revolutUsername: 'mayamusic',
    mobilepayBoxId: '12345',
    createdAtMs: 1751500000000,
  );

  test('json round trip', () {
    final restored = RelayJar.fromJson(jar.toJson());
    expect(restored.jarId, jar.jarId);
    expect(restored.donateUrl, jar.donateUrl);
    expect(restored.artistName, jar.artistName);
    expect(restored.currency, jar.currency);
    expect(restored.revolutUsername, jar.revolutUsername);
    expect(restored.mobilepayBoxId, jar.mobilepayBoxId);
    expect(restored.createdAtMs, jar.createdAtMs);
  });

  test('null methods stay null through json', () {
    final bare = RelayJar.fromJson(jar
        .copyWith(revolutUsername: null, mobilepayBoxId: null)
        .toJson());
    // copyWith can't null a field — build directly instead.
    expect(bare.revolutUsername, 'mayamusic',
        reason: 'copyWith(null) keeps the old value by design');

    const none = RelayJar(
      jarId: 'j',
      donateUrl: 'https://live.tips/t/j',
      artistName: 'A',
      currency: 'usd',
      createdAtMs: 0,
    );
    final restored = RelayJar.fromJson(none.toJson());
    expect(restored.revolutUsername, isNull);
    expect(restored.mobilepayBoxId, isNull);
  });

  test('hasRevolut / hasMobilePay reflect configured methods', () {
    expect(jar.hasRevolut, isTrue);
    expect(jar.hasMobilePay, isTrue);

    const none = RelayJar(
      jarId: 'j',
      donateUrl: 'https://live.tips/t/j',
      artistName: 'A',
      currency: 'usd',
      revolutUsername: '  ',
      mobilepayBoxId: null,
      createdAtMs: 0,
    );
    expect(none.hasRevolut, isFalse, reason: 'blank username does not count');
    expect(none.hasMobilePay, isFalse);
  });

  test('demo jar is safe and secret-free', () {
    expect(RelayJar.demo.jarId, 'demo');
    expect(RelayJar.demo.donateUrl, 'https://live.tips/t/demo');
    expect(RelayJar.demo.hasRevolut, isTrue);
    expect(RelayJar.demo.hasMobilePay, isFalse);
  });
}
