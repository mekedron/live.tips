// Open a URL *outside* the app — in the device browser.
//
// Native platforms hand the link to the OS default browser, so the stub just
// defers to `url_launcher`. The web build can't: inside an iOS Home-Screen PWA
// the `window.open` that `url_launcher` calls is swallowed and navigates within
// the standalone window, trapping the visitor with no address bar or Back
// button. The web build synthesises a real, user-clicked `<a target="_blank">`
// instead, which iOS routes to the in-app Safari view.
export 'external_link_stub.dart'
    if (dart.library.js_interop) 'external_link_web.dart';
