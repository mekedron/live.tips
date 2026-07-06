import 'package:flutter/widgets.dart';

/// Non-web stub: fullscreen is only offered in the browser (native platforms
/// already run the stage immersive/full-window), so the button hides itself.
bool get fullscreenSupported => false;

Widget fullscreenButton({double size = 44}) => const SizedBox.shrink();
