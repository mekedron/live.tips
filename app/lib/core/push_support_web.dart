import 'package:web/web.dart' as web;

/// True in an iOS/iPadOS *browser tab*: Safari there has no Push API at all —
/// web push exists only inside an installed Home Screen app (iOS 16.4+). The
/// permission widget turns this into "install first" steps instead of a dead
/// "not supported". Same sniffing as install_prompt_web.dart, including the
/// iPadOS-reports-as-Mac workaround.
bool get pushNeedsPwaInstall => _isIOS && !_isStandalone;

String get _ua => web.window.navigator.userAgent;

bool get _isIPad =>
    _ua.contains('iPad') ||
    (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

bool get _isIOS => _ua.contains('iPhone') || _ua.contains('iPod') || _isIPad;

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
