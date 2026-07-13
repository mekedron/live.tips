import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Universal-link handling for the QR add-device flow.
///
/// The link device A shows is `https://tip.live.tips/link#c=<code>`. The code
/// rides in the FRAGMENT on purpose: fragments never leave the browser, so the
/// code stays out of hosting/CDN access logs even when the QR is opened in a
/// browser rather than the app.

/// A link code as it comes off the wire: 22 chars of base64url (16 random
/// bytes) — the same shape `isValidLinkCode` enforces server-side.
final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

/// Pulls the link code out of whatever a QR scanner (or a deep link, or a
/// human pasting into the manual field) hands us: the full universal-link URL,
/// or a bare code. Returns null for anything else — a random QR on a poster
/// must not look like an add-device request.
///
/// Accepts the code in the fragment (`#c=…`, how the app mints it) or in the
/// query (`?c=…`, for anyone who copies it the obvious way), on any
/// `*.live.tips` host.
String? parseLinkCode(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;
  if (_codePattern.hasMatch(input)) return input;

  final uri = Uri.tryParse(input);
  if (uri == null) return null;
  // A URL from somewhere else is not ours to interpret.
  final host = uri.host.toLowerCase();
  if (host.isNotEmpty && host != 'live.tips' && !host.endsWith('.live.tips')) {
    return null;
  }

  for (final source in [uri.fragment, uri.query]) {
    if (source.isEmpty) continue;
    final Map<String, String> params;
    try {
      params = Uri.splitQueryString(source);
    } catch (_) {
      continue;
    }
    final code = params['c']?.trim();
    if (code != null && _codePattern.hasMatch(code)) return code;
  }
  return null;
}

/// The stream of link codes this app is asked to redeem: the URL the app was
/// cold-started with, plus every one it is handed while running.
///
/// Best effort by construction — a platform without the plugin (tests,
/// Windows/Linux) yields an empty stream instead of throwing, because a deep
/// link is a nice-to-have on top of the QR scanner, never a dependency of it.
class DeepLinks {
  DeepLinks({AppLinks? links, this.bootUrl}) : _links = links;

  final AppLinks? _links;

  /// The URL the app was OPENED with, captured in main() before anything can
  /// rewrite it. On the web this is the only chance to see it: Flutter's URL
  /// strategy normalizes the address bar during startup, so by the time this
  /// stream is first listened to, `Uri.base` has already lost the `#c=…`
  /// fragment the code rides in — and every scanned QR silently did nothing.
  final String? bootUrl;

  Stream<String> codes() async* {
    // The launch URL first, always — it is the one the plugin can't tell us
    // about on the web, and on native it costs nothing to honour.
    final boot = bootUrl == null ? null : parseLinkCode(bootUrl!);
    if (boot != null) yield boot;
    // On the web there is no plugin channel at all: the boot URL is the whole
    // of it, and a missing plugin must never swallow it.
    if (kIsWeb) return;
    final links = _links ?? _tryCreate();
    if (links == null) return;
    try {
      final initial = await links.getInitialLink();
      if (initial != null) {
        final code = parseLinkCode(initial.toString());
        if (code != null) yield code;
      }
      yield* links.uriLinkStream
          .map((uri) => parseLinkCode(uri.toString()))
          .where((code) => code != null)
          .cast<String>();
    } catch (e) {
      debugPrint('deep links unavailable: $e');
    }
  }

  static AppLinks? _tryCreate() {
    try {
      return AppLinks();
    } catch (e) {
      debugPrint('app_links unavailable: $e');
      return null;
    }
  }
}
