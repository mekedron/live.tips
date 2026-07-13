/// Native builds sign in natively (see AuthService); nothing should ever
/// reach for the bridge there.
Future<void> launchAuthBridge(Uri uri) =>
    throw UnsupportedError('The sign-in bridge is web-only.');
