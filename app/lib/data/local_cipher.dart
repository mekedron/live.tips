import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// At-rest encryption for a venue device's SharedPreferences values.
///
/// Be honest about what this buys: the key lives in the OS keystore, so this
/// protects against someone lifting the prefs FILE off the device (a backup,
/// a filesystem pull, a stolen SD card image) — and against nothing else.
/// Someone holding the unlocked tablet has the app, and the app has the key.
/// The real venue-mode controls are the 12-hour session ceiling, the
/// per-switch re-approval, and remote revoke; this is just the courtesy of
/// not leaving plaintext Stripe history in a flat file.
///
/// Construction: encrypt-then-MAC over a CTR keystream, both primitives
/// HMAC-SHA256 (the one cryptographic dependency this app already carries).
/// HMAC is a PRF, and PRF-in-counter-mode is the textbook stream cipher —
/// chosen over adding an AES dependency for a threat model this modest.
/// Independent keys for the two roles are derived from the stored root key.
class LocalCipher {
  LocalCipher(String rootKeyBase64)
      : _encKey = _derive(rootKeyBase64, 'enc'),
        _macKey = _derive(rootKeyBase64, 'mac');

  /// Envelope marker. A value without it is passthrough plaintext — the few
  /// keys written before the cipher attaches (the device kind itself), and
  /// anything left from before venue mode was chosen (the wipe removes those,
  /// but a reader must never crash on a straggler).
  static const prefix = 'enc1:';

  final List<int> _encKey;
  final List<int> _macKey;

  static List<int> _derive(String rootKeyBase64, String role) =>
      Hmac(sha256, base64.decode(rootKeyBase64)).convert(utf8.encode(role)).bytes;

  /// A fresh random root key, base64 — minted once per venue install and
  /// parked in the OS keystore ([SecureStore.readLocalCipherKey]).
  static String newRootKey() {
    final random = Random.secure();
    return base64.encode(
        Uint8List.fromList(List.generate(32, (_) => random.nextInt(256))));
  }

  List<int> _keystream(List<int> nonce, int length) {
    final out = <int>[];
    var counter = 0;
    while (out.length < length) {
      final block = Hmac(sha256, _encKey).convert([
        ...nonce,
        counter >> 24 & 0xff,
        counter >> 16 & 0xff,
        counter >> 8 & 0xff,
        counter & 0xff,
      ]).bytes;
      out.addAll(block);
      counter++;
    }
    return out.sublist(0, length);
  }

  String encrypt(String plaintext) {
    final random = Random.secure();
    final nonce = List<int>.generate(16, (_) => random.nextInt(256));
    final plain = utf8.encode(plaintext);
    final stream = _keystream(nonce, plain.length);
    final cipher = [for (var i = 0; i < plain.length; i++) plain[i] ^ stream[i]];
    final mac = Hmac(sha256, _macKey).convert([...nonce, ...cipher]).bytes;
    return '$prefix${base64.encode(nonce)}:${base64.encode(cipher)}:'
        '${base64.encode(mac)}';
  }

  /// Decrypts an envelope; a plain value passes through untouched. Returns
  /// null for an envelope that fails to authenticate or parse — a tampered or
  /// foreign-key value must read as "nothing stored", never as garbage data.
  String? decrypt(String stored) {
    if (!stored.startsWith(prefix)) return stored;
    try {
      final parts = stored.substring(prefix.length).split(':');
      if (parts.length != 3) return null;
      final nonce = base64.decode(parts[0]);
      final cipher = base64.decode(parts[1]);
      final mac = base64.decode(parts[2]);
      final expected = Hmac(sha256, _macKey).convert([...nonce, ...cipher]).bytes;
      if (!_constantTimeEquals(expected, mac)) return null;
      final stream = _keystream(nonce, cipher.length);
      return utf8.decode(
          [for (var i = 0; i < cipher.length; i++) cipher[i] ^ stream[i]]);
    } catch (_) {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
