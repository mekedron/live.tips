import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../state/providers.dart';

/// Stage lock: while the tablet sits on stage, all input is blocked.
/// Unlocking prefers the platform's own authentication (Face ID / Touch ID /
/// device passcode via local_auth) and falls back to an in-app PIN.
///
/// Honest limitation, also spelled out in the docs: an app cannot block the
/// OS home gesture. For a fully sealed kiosk, combine this with iOS Guided
/// Access or Android app pinning — the lock here protects against casual
/// taps, not a determined thief.
class LockService {
  LockService(this._ref);

  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> deviceAuthAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _authenticateWithDevice() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock the stage screen',
        biometricOnly: false, // device PIN/passcode is an acceptable factor
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// True when at least one unlock method exists (device auth or app PIN).
  /// If neither exists, prompts to create an app PIN and returns whether
  /// locking may proceed.
  Future<bool> ensureUnlockMethod(BuildContext context) async {
    final prefer = _ref.read(appStateProvider).settings.preferDeviceAuth;
    if (prefer && await deviceAuthAvailable()) return true;
    if (await _ref.read(secureStoreProvider).hasPin()) return true;
    if (!context.mounted) return false;
    final created = await promptCreatePin(context);
    return created;
  }

  /// Runs the unlock flow. Returns true when the artist proved it's them.
  Future<bool> unlock(BuildContext context) async {
    final prefer = _ref.read(appStateProvider).settings.preferDeviceAuth;
    if (prefer && await deviceAuthAvailable()) {
      if (await _authenticateWithDevice()) return true;
      // fall through to PIN so a failed Face ID doesn't strand the artist
    }
    if (await _ref.read(secureStoreProvider).hasPin()) {
      if (!context.mounted) return false;
      return await promptVerifyPin(context);
    }
    // No PIN set: retry device auth as the only option.
    if (await deviceAuthAvailable()) return _authenticateWithDevice();
    return false;
  }

  /// Two-step PIN creation (enter + confirm). Returns true when saved.
  Future<bool> promptCreatePin(BuildContext context) async {
    final first = await _askPin(context, 'Create a stage-lock PIN');
    if (first == null || first.length < 4) return false;
    if (!context.mounted) return false;
    final second = await _askPin(context, 'Repeat the PIN');
    if (second != first) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PINs didn't match — try again")),
        );
      }
      return false;
    }
    await _ref.read(secureStoreProvider).setPin(first);
    return true;
  }

  Future<bool> promptVerifyPin(BuildContext context) async {
    final pin = await _askPin(context, 'Enter your PIN');
    if (pin == null) return false;
    final ok = await _ref.read(secureStoreProvider).verifyPin(pin);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN')),
      );
    }
    return ok;
  }

  Future<String?> _askPin(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(counterText: '', hintText: '••••'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

final lockServiceProvider = Provider<LockService>((ref) => LockService(ref));
