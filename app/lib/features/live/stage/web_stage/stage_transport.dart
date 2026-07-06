import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'iframe_stage_transport_stub.dart'
    if (dart.library.js_interop) 'iframe_stage_transport_web.dart';
import 'stage_bridge_codec.dart';

export 'iframe_stage_transport_stub.dart'
    if (dart.library.js_interop) 'iframe_stage_transport_web.dart';

/// Test seam: overriding this provider swaps the WebView for a fake, so all
/// WebStage logic (handshake, diffing, watchdog) runs in plain widget tests.
final stageTransportFactoryProvider = Provider<StageTransport Function()>(
    (ref) => kIsWeb ? IframeStageTransport.new : WebViewStageTransport.new);

/// The wire between WebStage and the renderer — seam for tests: the widget
/// logic (handshake, watchdog, diffing) runs against a fake transport with
/// no WebView anywhere near.
abstract class StageTransport {
  /// Receives every decoded renderer message (unknown types already dropped).
  void Function(StageInMessage msg)? onMessage;

  Future<void> send(StageOutMessage msg);

  /// Full page reload — the recovery path after a render-process death.
  Future<void> reload();

  /// Web only: toggle whether the embedded stage receives pointer events. The
  /// host flips this off while a modal covers the stage, so sheets and dialogs
  /// stay clickable over the <iframe> platform view (which on Flutter Web would
  /// otherwise swallow every tap). No-op on native — platform-view hit-testing
  /// already lets widgets above the WebView receive gestures there.
  void setInteractive(bool interactive) {}

  void dispose() {}
}

/// Real transport over webview_flutter. Owns the [WebViewController].
class WebViewStageTransport extends StageTransport {
  WebViewStageTransport() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LiveTips',
        onMessageReceived: (m) {
          if (kDebugMode) debugPrint('stage ⇐ ${m.message}');
          final msg = StageInMessage.decode(m.message);
          if (msg != null) onMessage?.call(msg);
        },
      );
    // NOTE: no setBackgroundColor — unimplemented on macOS; the page paints
    // its own full-bleed stage background instead.
    if (kDebugMode) {
      controller.setOnConsoleMessage(
          (m) => debugPrint('stage console[${m.level.name}]: ${m.message}'));
    }
    controller.setNavigationDelegate(NavigationDelegate(
      onWebResourceError: (e) => debugPrint(
          'stage resource error: ${e.errorCode} ${e.description} ${e.url}'),
    ));
    controller.loadFlutterAsset('assets/stage/index.html');
  }

  late final WebViewController controller;

  @override
  Future<void> send(StageOutMessage msg) async {
    final encoded = msg.encode();
    if (kDebugMode) debugPrint('stage ⇒ $encoded');
    try {
      // jsonEncode of the STRING yields a safely quoted/escaped JS literal.
      await controller
          .runJavaScript('window.__stage.dispatch(${jsonEncode(encoded)})');
    } catch (e) {
      debugPrint('stage send failed: $e');
    }
  }

  @override
  Future<void> reload() => controller.reload();
}
