import 'package:web/web.dart' as web;

/// Whether to nudge the visitor to add live.tips to their Home Screen. True only
/// in a phone or tablet *browser* — iPhone, iPad or Android — that isn't already
/// running as an installed PWA. False on desktop (a chrome-free launch buys
/// nothing there) and once installed (there's nothing left to install).
bool get shouldSuggestInstall => (_isIOS || _isAndroid) && !_isStandalone;

/// iOS/iPadOS installs through Safari's Share sheet; Android through the
/// browser menu. Picks which set of steps the hint screen spells out.
bool get installGuideIsApple => _isIOS;

String get _ua => web.window.navigator.userAgent;

// iPadOS 13+ Safari reports a desktop Mac user-agent, so a "Macintosh" that also
// reports touch points is really an iPad (a real Mac has no touchscreen).
bool get _isIPad =>
    _ua.contains('iPad') ||
    (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

bool get _isIOS => _ua.contains('iPhone') || _ua.contains('iPod') || _isIPad;

bool get _isAndroid => _ua.contains('Android');

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
