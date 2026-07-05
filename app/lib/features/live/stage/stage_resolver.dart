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
  const StageHealth({this.webViewBroken = false, this.jar3dUnfit = false});

  /// The WebView never became ready / kept dying → both jar styles unusable.
  final bool webViewBroken;

  /// 3D specifically can't hold a frame rate here → step down to the 2D jar.
  final bool jar3dUnfit;

  StageHealth copyWith({bool? webViewBroken, bool? jar3dUnfit}) => StageHealth(
        webViewBroken: webViewBroken ?? this.webViewBroken,
        jar3dUnfit: jar3dUnfit ?? this.jar3dUnfit,
      );
}

class StageHealthController extends Notifier<StageHealth> {
  @override
  StageHealth build() => const StageHealth();

  void reportWebViewFailure() =>
      state = state.copyWith(webViewBroken: true);

  void reportJar3dUnfit() => state = state.copyWith(jar3dUnfit: true);

  /// Called on session start — every session gets a fresh chance at 3D.
  void reset() => state = const StageHealth();
}

final stageHealthProvider =
    NotifierProvider<StageHealthController, StageHealth>(
        StageHealthController.new);

/// The style that actually renders, given the user's wish and reality.
/// Fallback chain: jar3d → jar2d (perf) → classic (no/na WebView).
StageStyle resolveEffectiveStyle(
  StageStyle requested, {
  required bool webViewSupported,
  required StageHealth health,
}) {
  if (requested == StageStyle.classic) return StageStyle.classic;
  if (!webViewSupported || health.webViewBroken) return StageStyle.classic;
  if (requested == StageStyle.jar3d && health.jar3dUnfit) {
    return StageStyle.jar2d;
  }
  return requested;
}
