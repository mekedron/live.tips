// Can THIS browser not push until the app is installed? iOS/iPadOS Safari
// only delivers web push to a Home Screen app (16.4+), so an iPhone browser
// tab must be told to install first — the web build sniffs the platform
// exactly like install_prompt does, and the non-web stub (native apps have
// real push channels) always says no.
export 'push_support_stub.dart'
    if (dart.library.js_interop) 'push_support_web.dart';
