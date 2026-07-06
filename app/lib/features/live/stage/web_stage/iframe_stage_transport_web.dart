// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'stage_bridge_codec.dart';
import 'stage_transport.dart';

/// The shape bridge.js's `createBridge()` installs as `window.__stage`
/// (renderer/src/bridge.js) — a typed wrapper around an unsafely obtained
/// cross-window reference.
extension type _StageBridge(JSObject _) implements JSObject {
  external void dispatch(JSAny? raw);
}

/// Real transport for Flutter Web. Hosts the SAME JS bundle webview_flutter
/// loads on Android/iOS/macOS, inside a same-origin `<iframe>` embedded as a
/// Flutter Web platform view — no nested browser engine, just a real DOM node
/// in the page's own browsing-context tree.
///
/// Host → JS is a direct same-origin call (`contentWindow.__stage.dispatch`):
/// safe because the host never dispatches before it has already received
/// `hello`, by which point the bundle has long since assigned `window.__stage`
/// (renderer/src/main.js loads via a plain blocking `<script>`, and
/// `window.__stage` is set synchronously before `hello` is ever emitted).
/// JS → host has no such ordering guarantee, so it goes over `postMessage`
/// (bridge.js's additive fallback branch) instead of a matching direct call.
class IframeStageTransport extends StageTransport {
  IframeStageTransport() {
    _iframe = web.HTMLIFrameElement()
      ..src = 'assets/assets/stage/index.html'
      ..allow = 'autoplay'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    _viewType = 'live-tips-stage-iframe-${_nextInstanceId++}';
    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int viewId) => _iframe);
    _onWindowMessage = _handleWindowMessage.toJS;
    web.window.addEventListener('message', _onWindowMessage);
  }

  static int _nextInstanceId = 0;

  late final web.HTMLIFrameElement _iframe;
  late final String _viewType;
  late final JSFunction _onWindowMessage;

  /// Fed to `HtmlElementView` by WebStage.build().
  String get viewType => _viewType;

  void _handleWindowMessage(web.MessageEvent event) {
    if (event.source != _iframe.contentWindow) return; // not our iframe
    final data = event.data;
    if (!data.isA<JSObject>()) return;
    final payload = (data as JSObject).getProperty('liveTipsStage'.toJS);
    if (!payload.isA<JSString>()) return;
    final raw = (payload as JSString).toDart;
    if (kDebugMode) debugPrint('stage ⇐ $raw');
    final msg = StageInMessage.decode(raw);
    if (msg != null) onMessage?.call(msg);
  }

  @override
  Future<void> send(StageOutMessage msg) async {
    final encoded = msg.encode();
    if (kDebugMode) debugPrint('stage ⇒ $encoded');
    try {
      final stage = _iframe.contentWindow
          ?.getProperty<_StageBridge?>('__stage'.toJS);
      stage?.dispatch(encoded.toJS);
    } catch (e) {
      debugPrint('stage send failed: $e');
    }
  }

  @override
  void setInteractive(bool interactive) {
    _iframe.style.setProperty('pointer-events', interactive ? 'auto' : 'none');
  }

  @override
  Future<void> reload() async {
    final win = _iframe.contentWindow;
    if (win != null) {
      win.location.reload();
    } else {
      _iframe.src = _iframe.src; // pathological fallback
    }
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _onWindowMessage);
    super.dispose();
  }
}
