import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/relay/relay_client.dart';
import '../domain/relay_jar.dart';
import 'providers.dart';

/// Tells the relay the artist is still around — at most once per 24 h. The
/// ping doubles as the jar's keep-alive (unused jars expire after 90 days)
/// and resets its unseen-tips marker.
class SeenPingService {
  static const gap = Duration(hours: 24);

  /// Pings when the last successful ping is older than [gap] (or never
  /// happened). Every failure is swallowed and leaves the timestamp
  /// untouched, so the next launch/resume simply retries.
  Future<void> maybePing({
    required LocalStore store,
    required RelayJar jar,
    required String secret,
    required RelayClient client,
    DateTime Function()? now,
  }) async {
    final current = (now ?? DateTime.now)();
    final lastMs = store.readRelaySeenAt();
    if (lastMs != null &&
        current.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) <
            gap) {
      return;
    }
    try {
      await client.markSeen(jarId: jar.jarId, secret: secret);
      await store.writeRelaySeenAt(current.millisecondsSinceEpoch);
    } catch (_) {
      // Offline, rotated secret, expired jar — retry on the next resume.
    }
  }
}

/// Invisible wrapper that fires [SeenPingService.maybePing] once after launch
/// and on every return to the foreground. Uses the *stored* jar (not the demo
/// substitute) so a real jar stays alive even while playing with demo mode.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _ping());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _ping();
  }

  Future<void> _ping() async {
    final app = ref.read(appStateProvider);
    final jar = app.relayJar;
    final secret = app.relaySecret;
    if (jar == null || secret == null) return;
    final client = RelayClient();
    try {
      await _service.maybePing(
        store: ref.read(localStoreProvider),
        jar: jar,
        secret: secret,
        client: client,
      );
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
