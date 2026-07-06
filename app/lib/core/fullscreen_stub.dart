import 'package:flutter/widgets.dart';

/// Non-web stub: fullscreen is only offered in the browser (native platforms
/// already run the stage immersive/full-window), so nothing is exposed here.
bool get fullscreenSupported => false;

/// iPhone Safari has no Fullscreen API; the web build offers an "Add to Home
/// Screen" hint there instead. Never applies off the web.
bool get fullscreenNeedsInstall => false;

/// Whether to show the stage fullscreen control at all.
bool get fullscreenAvailable => false;

Widget fullscreenButton({double size = 44}) => const SizedBox.shrink();
