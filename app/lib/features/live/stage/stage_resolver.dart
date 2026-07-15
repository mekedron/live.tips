import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/stage_settings.dart';

/// Whether this platform can host the JS-driven jar stage at all — either
/// via webview_flutter (Android/iOS/macOS) or, on Flutter Web, a same-origin
/// `<iframe>` transport (see web_stage/iframe_stage_transport_web.dart).
/// Windows/Linux still resolve to classic.
final stageCapabilityProvider = Provider<bool>((ref) {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
});

/// Runtime health of the WebView stage, reported by WebStage's watchdog.
/// Reset at every session start so a transient failure doesn't banish the
/// jar forever. The PERSISTED style preference is never mutated by this.
class StageHealth {
  const StageHealth({this.webViewBroken = false});

  /// The WebView never became ready / kept dying → both jar styles unusable.
  final bool webViewBroken;

  StageHealth copyWith({bool? webViewBroken}) => StageHealth(
        webViewBroken: webViewBroken ?? this.webViewBroken,
      );
}

class StageHealthController extends Notifier<StageHealth> {
  @override
  StageHealth build() => const StageHealth();

  void reportWebViewFailure() =>
      state = state.copyWith(webViewBroken: true);

  /// Called on session start — every session gets a fresh chance at 3D.
  void reset() => state = const StageHealth();
}

final stageHealthProvider =
    NotifierProvider<StageHealthController, StageHealth>(
        StageHealthController.new);

/// The style that actually renders, given the user's wish and reality.
/// Fallback chain: jar → classic (no/broken WebView). The 3D jar never steps
/// itself down to 2D — a 3D scene that runs a little slow still beats the flat
/// 2D jar, and the performer's quality pick (High/Low) is honored as-is.
StageStyle resolveEffectiveStyle(
  StageStyle requested, {
  required bool webViewSupported,
  required StageHealth health,
}) {
  if (requested == StageStyle.classic) return StageStyle.classic;
  if (!webViewSupported || health.webViewBroken) return StageStyle.classic;
  return requested;
}
