import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web fullscreen via the Fullscreen API. [fullscreenState] tracks the live
/// state — kept in sync via the `fullscreenchange` event so pressing Esc flips
/// the button's icon back — and [toggleFullscreen] enters/exits.
bool get fullscreenSupported => true;

final ValueNotifier<bool> fullscreenState = ValueNotifier<bool>(false);

var _wired = false;
void _wire() {
  if (_wired) return;
  _wired = true;
  web.document.addEventListener(
    'fullscreenchange',
    ((web.Event _) {
      fullscreenState.value = web.document.fullscreenElement != null;
    }).toJS,
  );
}

void toggleFullscreen() {
  _wire();
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  } else {
    web.document.documentElement?.requestFullscreen();
  }
}
