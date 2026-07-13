import 'package:web/web.dart' as web;

/// Web: a plain top-level navigation, same tab. assign(), not replace() — the
/// page the user left stays one Back-press behind the provider's, which is
/// how a change of heart gets home.
Future<void> launchAuthBridge(Uri uri) async {
  web.window.location.assign(uri.toString());
}
