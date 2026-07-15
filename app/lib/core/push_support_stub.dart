/// Non-web stub: only iOS Safari gates push behind a PWA install.
bool get pushNeedsPwaInstall => false;

/// Non-web stub: native platforms have no browser push subscription to cut
/// loose — the SDK's own deleteToken is the whole story there.
Future<bool> pushBrowserUnsubscribe() async => false;
