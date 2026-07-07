import 'package:web/web.dart' as web;

/// Open [url] in the browser from the web build.
///
/// `url_launcher` opens web links with `window.open`, and inside an iOS
/// Home-Screen PWA that scripted call is swallowed: the link navigates *within*
/// the standalone window, leaving the visitor with no address bar and no Back
/// button. A real, user-clicked `<a target="_blank" rel="noopener">` behaves
/// differently — iOS hands it to the in-app Safari view (the sheet with a Done
/// button and an open-in-Safari control), the closest a web app can get to the
/// browser, since iOS exposes no API to jump to the standalone Safari app.
/// Everywhere else it simply opens a normal new tab.
///
/// The click has to fire synchronously inside the tap gesture that called us —
/// so this does no `await` before `.click()`, or iOS drops the user activation
/// and falls back to the trapped-in-PWA behaviour.
Future<void> openExternal(String url) async {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
