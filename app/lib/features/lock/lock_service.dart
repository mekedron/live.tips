import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Stage lock: while the tablet sits on stage, all input is blocked until the
/// artist re-authenticates with the device itself — Face ID / Touch ID / the
/// device passcode (local_auth). There is no app-managed PIN: a forgotten app
/// PIN strands the artist with no recovery, whereas device auth always has the
/// OS fallback (the passcode on iPhone, account recovery on Android).
///
/// Honest limitation, also spelled out in the docs: an app cannot block the
/// OS home gesture. For a fully sealed kiosk, combine this with iOS Guided
/// Access or Android app pinning — the lock here protects against casual
/// taps, not a determined thief.
class LockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether this device can lock the stage at all — it has Face ID / Touch ID
  /// or a device passcode. False on the web and on passcode-less devices,
  /// where the lock button simply isn't shown.
  Future<bool> deviceAuthAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Runs the device's own authentication to unlock the stage. Returns true
  /// when the artist proved it's them (the OS shows its native prompt).
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock the stage screen',
        biometricOnly: false, // the device passcode is an acceptable factor
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final lockServiceProvider = Provider<LockService>((ref) => LockService());

/// Resolved once: whether the stage can be locked on this device (see
/// [LockService.deviceAuthAvailable]). The live stage and its preview hide
/// the lock button when this is false — e.g. in the browser.
final deviceAuthAvailableProvider = FutureProvider<bool>(
    (ref) => ref.read(lockServiceProvider).deviceAuthAvailable());
