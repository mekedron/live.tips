import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/relay/relay_client.dart';
import '../domain/relay_jar.dart';
import 'providers.dart';

/// Tells the relay the artist is still around — at most once per 24 h per
/// band. The ping doubles as the jar's keep-alive (unused jars expire after
/// 90 days) and resets its unseen-tips marker.
class SeenPingService {
  static const gap = Duration(hours: 24);

  /// Whether [accountId]'s jar is due a ping — a pure prefs check, so the
  /// caller never touches the keychain for jars pinged within [gap].
  bool isDue({
    required LocalStore store,
    required String accountId,
    DateTime Function()? now,
  }) {
    final lastMs = store.readRelaySeenAt(accountId);
    if (lastMs == null) return true;
    final current = (now ?? DateTime.now)();
    return current.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) >=
        gap;
  }

  /// Pings when the last successful ping is older than [gap] (or never
  /// happened). Every failure is swallowed and leaves the timestamp
  /// untouched, so the next launch/resume simply retries.
  Future<void> maybePing({
    required LocalStore store,
    required String accountId,
    required RelayJar jar,
    required String secret,
    required RelayClient client,
    DateTime Function()? now,
  }) async {
    if (!isDue(store: store, accountId: accountId, now: now)) return;
    try {
      await client.markSeen(jarId: jar.jarId, secret: secret);
      await store.writeRelaySeenAt(
          accountId, (now ?? DateTime.now)().millisecondsSinceEpoch);
    } catch (_) {
      // Offline, rotated secret, expired jar — retry on the next resume.
    }
  }
}

/// Invisible wrapper that fires [SeenPingService.maybePing] once after launch
/// and on every return to the foreground — for EVERY band with a relay jar,
/// not just the active one, so an idle band's donor page (and its printed QR
/// posters) never expires while the artist plays with another band. Uses the
/// *stored* jars (not the demo substitute) so real jars stay alive even
/// while playing with demo mode.
class RelayKeepalive extends ConsumerStatefulWidget {
  const RelayKeepalive({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RelayKeepalive> createState() => _RelayKeepaliveState();
}

class _RelayKeepaliveState extends ConsumerState<RelayKeepalive>
    with WidgetsBindingObserver {
  final _service = SeenPingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pingAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _pingAll();
  }

  Future<void> _pingAll() async {
    final app = ref.read(appStateProvider);
    final store = ref.read(localStoreProvider);
    // Prefs first, keychain last: jars and seen-markers are cheap local
    // reads, so bands pinged within 24 h cost zero keychain roundtrips (the
    // keychain is the one store that prompts and fails transiently). Each
    // band gets its own try/catch — one locked read must not starve the
    // rest, or their public pages quietly expire at 90 days.
    RelayClient? client;
    try {
      for (final account in app.accounts) {
        try {
          final jar = store.readRelayJar(account.id);
          if (jar == null) continue;
          if (!_service.isDue(store: store, accountId: account.id)) continue;
          final secret = account.id == app.accountId
              ? app.relaySecret
              : await ref
                  .read(secureStoreProvider)
                  .readRelaySecret(account.id);
          if (secret == null) continue;
          client ??= RelayClient();
          await _service.maybePing(
            store: store,
            accountId: account.id,
            jar: jar,
            secret: secret,
            client: client,
          );
        } catch (_) {
          // Keychain hiccup or network failure — this band retries on the
          // next launch/resume.
        }
      }
    } finally {
      client?.close();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
