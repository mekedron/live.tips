import 'package:url_launcher/url_launcher.dart';

/// Native builds: the OS already routes an external launch to the default
/// browser, so nothing special is needed.
Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
