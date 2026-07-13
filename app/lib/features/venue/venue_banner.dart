import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/band_switcher.dart';

/// The always-on venue banner: "Public device · signed in as X · End session".
///
/// Mounted ABOVE the navigator (MaterialApp.builder), so no pushed route —
/// settings subscreens, the live stage, dialogs' barriers — can ever cover
/// it. On a device anyone can pick up, whose account is on it and how to end
/// that must never be more than a glance and a tap away.
class VenueBannerHost extends ConsumerWidget {
  const VenueBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(venueSessionProvider);
    final show = ref.watch(venueModeActiveProvider) &&
        session != null &&
        session.identityConfirmed;
    if (!show) return child;
    return Column(
      children: [
        _VenueBanner(uid: session.uid),
        // The banner consumed the top inset; the child must not re-apply it.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _VenueBanner extends ConsumerStatefulWidget {
  const _VenueBanner({required this.uid});

  final String uid;

  @override
  ConsumerState<_VenueBanner> createState() => _VenueBannerState();
}

class _VenueBannerState extends ConsumerState<_VenueBanner> {
  /// The confirm step lives inline in the banner — there is no navigator
  /// above this widget to host a dialog, and an expanding strip reads
  /// better on a tablet anyway.
  bool _confirming = false;
  bool _busy = false;

  Future<void> _end() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(venueSessionProvider.notifier).endSession();
    // No teardown of local state needed: the session flip unmounts us.
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final entry = ref
        .watch(accountsDirectoryProvider)
        .accounts
        .where((a) => a.id == widget.uid)
        .firstOrNull;
    final name = entry == null
        ? s.t('venue.identity.unknown_account')
        : accountDisplayName(context, entry);
    return Material(
      color: c.warningContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 18, color: c.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _confirming
                      ? s.t('venue.banner.confirm_end', {'name': name})
                      : s.t('venue.banner.label', {'name': name}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: outfitStyle(13, c.text, weight: FontWeight.w600),
                ),
              ),
              if (_confirming) ...[
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _confirming = false),
                  child: Text(s.t('venue.banner.keep_playing')),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.danger,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _busy ? null : () => unawaited(_end()),
                  child: Text(s.t('venue.banner.confirm_button')),
                ),
              ] else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: c.warning),
                  ),
                  onPressed: () => setState(() => _confirming = true),
                  child: Text(
                    s.t('venue.banner.end_session'),
                    style: outfitStyle(12.5, c.text, weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
