import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/live/live_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/live_session_controller.dart';
import '../state/providers.dart';
import '../state/session_coordinator.dart';

/// "Live session running in {band} — Join": shown across the shell when the
/// signed-in ACCOUNT runs a session on another device and this one isn't
/// attached to it. Join switches to the session's band first when needed
/// (same profile — allowed), attaches as a follower, and opens the stage.
/// Renders nothing in local mode, with no remote session, or while this
/// device is in the session already.
class LiveSessionBanner extends ConsumerStatefulWidget {
  const LiveSessionBanner({super.key, this.onJoined});

  /// What Join does once attached — defaults to opening the live stage the
  /// same way Home does. A seam for widget tests, which must not mount the
  /// real stage (wakelock, immersive chrome).
  final void Function(BuildContext context)? onJoined;

  @override
  ConsumerState<LiveSessionBanner> createState() =>
      _LiveSessionBannerState();
}

class _LiveSessionBannerState extends ConsumerState<LiveSessionBanner> {
  bool _joining = false;

  Future<void> _join(ActiveSessionInfo info) async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      final app = ref.read(appStateProvider);
      if (info.bandId != app.accountId) {
        final switched = await ref
            .read(appStateProvider.notifier)
            .switchAccount(info.bandId);
        if (!switched) return;
      }
      final joined =
          await ref.read(liveSessionProvider.notifier).join(info);
      if (!joined || !mounted) return;
      final onJoined = widget.onJoined;
      if (onJoined != null) {
        onJoined(context);
      } else {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LiveScreen()));
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(activeSessionProvider).value;
    if (info == null || !info.active) return const SizedBox.shrink();
    // A session on THIS device — attached to the remote one or running its
    // own — means the stage (or its Return button) owns the situation.
    if (ref.watch(liveSessionProvider) != null) {
      return const SizedBox.shrink();
    }

    final c = context.lt;
    final accounts = ref.watch(appStateProvider.select((s) => s.accounts));
    final bandName = accounts
            .where((a) => a.id == info.bandId)
            .map((a) => a.name.trim())
            .firstOrNull ??
        '';
    final band = bandName.isEmpty
        ? context.s.t('widgets.band_switcher.unnamed_account')
        : bandName;

    return Material(
      color: c.accentSoft,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.sensors_rounded, size: 20, color: c.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.s.t('widgets.live_banner.running', {'band': band}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: outfitStyle(13.5, c.onAccentSoft),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: _joining ? null : () => _join(info),
              child: Text(context.s.t('widgets.live_banner.join')),
            ),
          ],
        ),
      ),
    );
  }
}
