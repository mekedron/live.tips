import 'package:flutter/foundation.dart';

/// Whether this build can host cloud accounts (Firebase Auth + Firestore).
/// Windows and Linux have no Firebase SDK — they run local mode only, and
/// every cloud-account surface (sign-in buttons, the Security section,
/// QR add-device) hides behind this flag.
bool get platformSupportsCloudAccounts =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.android =>
        true,
      _ => false,
    };
