import 'package:url_launcher/url_launcher.dart';

/// Native builds: the OS already routes an external launch to the default
/// browser, so nothing special is needed.
Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

// Off the web there is no in-app-Safari trap, so the Safari-escape workaround
// never applies and its toggle stays hidden. See external_link_web.dart.
bool get safariEscapeApplicable => false;
bool get preferSafariEscape => false;
set preferSafariEscape(bool value) {}
