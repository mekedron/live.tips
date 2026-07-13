import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/deep_links.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/link_codes.dart';

/// A real-shaped code: 22 chars of base64url (16 random bytes), exactly what
/// the server mints and validates.
const _code = 'AbCd1234_-ZzYyXxWwVv';
const _validCode = '${_code}Qq'; // 22 chars

void main() {
  group('parseLinkCode', () {
    test('accepts the universal link the QR actually carries', () {
      expect(
        parseLinkCode('https://tip.live.tips/link#c=$_validCode'),
        _validCode,
      );
    });

    test('accepts a bare code (the manual paste path)', () {
      expect(parseLinkCode(_validCode), _validCode);
      expect(parseLinkCode('  $_validCode\n'), _validCode);
    });

    test('accepts the code as a query param too', () {
      expect(
        parseLinkCode('https://tip.live.tips/link?c=$_validCode'),
        _validCode,
      );
    });

    test('reads the code out of a fragment with other params', () {
      expect(
        parseLinkCode('https://tip.live.tips/link#c=$_validCode&x=1'),
        _validCode,
      );
    });

    test('refuses a link from someone else\'s host', () {
      expect(parseLinkCode('https://evil.example/link#c=$_validCode'), isNull);
      // …but a staging host under live.tips is ours.
      expect(
        parseLinkCode('https://staging.live.tips/link#c=$_validCode'),
        _validCode,
      );
    });

    test('refuses anything that is not a code', () {
      expect(parseLinkCode(''), isNull);
      expect(parseLinkCode('   '), isNull);
      expect(parseLinkCode('https://tip.live.tips/t/some-jar'), isNull);
      expect(parseLinkCode('https://tip.live.tips/link'), isNull);
      // Wrong length / charset — a random QR must never look like a request.
      expect(parseLinkCode('short'), isNull);
      expect(parseLinkCode('https://tip.live.tips/link#c=short'), isNull);
      expect(parseLinkCode('https://tip.live.tips/link#c=${'a' * 23}'), isNull);
      expect(parseLinkCode('https://tip.live.tips/link#c=${'a' * 21}!'), isNull);
    });
  });

  group('LinkCode', () {
    test('the QR url keeps the code in the fragment (out of server logs)', () {
      const link = LinkCode(code: _validCode, expiresAtMs: 0);
      expect(link.url, 'https://tip.live.tips/link#c=$_validCode');
      expect(Uri.parse(link.url).query, isEmpty);
      expect(parseLinkCode(link.url), _validCode);
    });
  });

  group('LinkCodeState', () {
    test('reads status and requester off the doc', () {
      final state = LinkCodeState.fromData({
        'status': 'claimed',
        'requester': {'name': "Nikita's iPhone", 'platform': 'ios'},
      });
      expect(state.status, LinkCodeStatus.claimed);
      expect(state.requesterName, "Nikita's iPhone");
      expect(state.requesterPlatform, 'ios');
    });

    test('an unknown or missing status never masquerades as a live one', () {
      expect(LinkCodeState.fromData(null).status, LinkCodeStatus.unknown);
      expect(
        LinkCodeState.fromData({'status': 'weird'}).status,
        LinkCodeStatus.unknown,
      );
    });
  });

  group('DeviceInfo', () {
    test('json round-trips', () {
      const device = DeviceInfo(
        id: 'dev_abc123',
        name: "Nikita's iPhone",
        platform: 'ios',
        model: 'iPhone16,1',
        createdAtMs: 1700000000000,
        lastSeenAtMs: 1700000600000,
      );
      final round = DeviceInfo.fromJson('dev_abc123', device.toJson());

      expect(round.id, device.id);
      expect(round.name, device.name);
      expect(round.platform, device.platform);
      expect(round.model, device.model);
      expect(round.createdAtMs, device.createdAtMs);
      expect(round.lastSeenAtMs, device.lastSeenAtMs);
      expect(round.revoked, isFalse);
      // isCurrent is decided at read time, never stored.
      expect(device.toJson().containsKey('isCurrent'), isFalse);
      expect(round.isCurrent, isFalse);
    });

    test('a create payload always declares revoked:false (the rules demand it)',
        () {
      const device = DeviceInfo(id: 'dev_1', name: 'Mac', platform: 'macos');
      expect(device.toJson()['revoked'], false);
      expect(device.toJson().containsKey('revokedAtMs'), isFalse);
    });

    test('a doc missing every optional field still reads', () {
      final device = DeviceInfo.fromJson('dev_2', const {}, isCurrent: true);
      expect(device.name, '');
      expect(device.platform, 'unknown');
      expect(device.model, isNull);
      expect(device.revoked, isFalse);
      expect(device.isCurrent, isTrue);
    });

    test('revoked reads through', () {
      final device = DeviceInfo.fromJson('dev_3', const {
        'name': 'Old phone',
        'platform': 'android',
        'revoked': true,
        'revokedAtMs': 1700000000000,
      });
      expect(device.revoked, isTrue);
    });
  });
}
