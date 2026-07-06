import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web fullscreen. The button is a *native* DOM `<button>` (a platform view),
/// not a Flutter button — `requestFullscreen()` is only honored from inside a
/// real user-gesture DOM handler, and routing the click through Flutter's
/// pointer pipeline (and the PointerInterceptor sitting over the jar) drops
/// that activation, so the browser silently refuses it. A raw `onclick` keeps
/// the gesture, so the toggle actually works. It styles itself to match the
/// glass stage controls and tracks state via `fullscreenchange`.
bool get fullscreenSupported => true;

// Material fullscreen / fullscreen-exit glyphs (24×24 viewBox).
const _enterPath =
    'M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z';
const _exitPath =
    'M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z';

String _iconUrl() {
  final path = web.document.fullscreenElement != null ? _exitPath : _enterPath;
  final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="white" fill-opacity="0.85"><path d="$path"/></svg>';
  return 'url("data:image/svg+xml,${Uri.encodeComponent(svg)}")';
}

void _toggle() {
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  } else {
    web.document.documentElement?.requestFullscreen();
  }
}

var _registered = false;
const _viewType = 'live-tips-fullscreen-button';

void _register() {
  if (_registered) return;
  _registered = true;
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final btn = web.HTMLButtonElement()..type = 'button';
    btn.style.cssText = 'width:100%;height:100%;box-sizing:border-box;'
        'padding:0;margin:0;border-radius:50%;cursor:pointer;'
        'background-color:rgba(20,17,14,0.70);'
        'background-repeat:no-repeat;background-position:center;'
        'background-size:46% 46%;'
        'border:1px solid rgba(255,255,255,0.08);'
        '-webkit-tap-highlight-color:transparent;outline:none;';
    btn.style.backgroundImage = _iconUrl();
    // Native click → requestFullscreen synchronously, inside the real gesture.
    btn.addEventListener('click', ((web.Event _) => _toggle()).toJS);
    // Keep the icon in sync (Esc, F11, the OS chrome…); self-remove once gone.
    late final JSFunction onChange;
    onChange = ((web.Event _) {
      if (!btn.isConnected) {
        web.document.removeEventListener('fullscreenchange', onChange);
        return;
      }
      btn.style.backgroundImage = _iconUrl();
    }).toJS;
    web.document.addEventListener('fullscreenchange', onChange);
    return btn;
  });
}

Widget fullscreenButton({double size = 44}) {
  _register();
  return SizedBox(
    width: size,
    height: size,
    child: const HtmlElementView(viewType: _viewType),
  );
}
