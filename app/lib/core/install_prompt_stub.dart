/// Non-web stub: adding to the Home Screen is a browser-only affordance, so the
/// native builds (which already run full-window) never suggest it.
bool get shouldSuggestInstall => false;

/// Unused off the web; defaults to the Android wording.
bool get installGuideIsApple => false;
