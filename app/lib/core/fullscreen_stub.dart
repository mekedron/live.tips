import 'package:flutter/foundation.dart';

/// Non-web stub: fullscreen is only offered in the browser (native platforms
/// already run the stage immersive/full-window), so nothing to toggle here.
bool get fullscreenSupported => false;

/// Never changes off web.
final ValueNotifier<bool> fullscreenState = ValueNotifier<bool>(false);

void toggleFullscreen() {}
