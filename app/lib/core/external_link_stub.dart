import 'package:url_launcher/url_launcher.dart';

/// Native builds: the OS already routes an external launch to the default
/// browser, so nothing special is needed and [safari] is irrelevant (there's
/// no in-app-Safari trap off the web).
Future<void> openExternal(String url, {bool safari = false}) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
