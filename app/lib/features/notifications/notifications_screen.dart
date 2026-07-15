import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/notification_item.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/notifications_providers.dart';
import '../../widgets/lt_ui.dart';

/// The bell's page: every tip and song request that arrived while no set was
/// running, newest first. Opening it IS marking it read — the watermark write
/// happens as soon as the first snapshot is on screen, so the badge clears
/// here and on every other device at once. No per-row read state, no swipe
/// actions: the feed is glass over the server's own collection (rules deny
/// client writes), and History remains the place where tips are acted on.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _marked = false;

  /// Once, on the first frame that actually SHOWED the feed: marking read on
  /// initState would clear a badge for entries the artist never saw drawn.
  void _markRead() {
    if (_marked) return;
    _marked = true;
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsServiceProvider).markAllRead(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final feed = ref.watch(notificationsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('notifications.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Text(
                s.t('notifications.error'),
                style: TextStyle(fontFamily: kFontBody, color: c.textSecondary),
              ),
            ),
            data: (items) {
              _markRead();
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 40,
                          color: c.textFaint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.t('notifications.empty'),
                          style: outfitStyle(16, c.text, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.t('notifications.empty_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13,
                            height: 1.45,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  LtRowGroup(
                    children: [
                      for (final item in items) _NotificationRow(item: item),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final amount = formatAmount(item.amountMinor, item.currency);
    final title = switch ((item.kind, item.name)) {
      (NotificationKind.songRequest, final name?) =>
        s.t('notifications.request_row_title', {'name': name, 'amount': amount}),
      (NotificationKind.songRequest, null) =>
        s.t('notifications.request_row_title_anon', {'amount': amount}),
      (NotificationKind.tip, final name?) =>
        s.t('notifications.tip_row_title', {'name': name, 'amount': amount}),
      (NotificationKind.tip, null) =>
        s.t('notifications.tip_row_title_anon', {'amount': amount}),
    };
    final when = _when(context, DateTime.fromMillisecondsSinceEpoch(item.createdAtMs));

    return LtRow(
      icon: item.kind == NotificationKind.songRequest
          ? Icons.queue_music_rounded
          : Icons.volunteer_activism_rounded,
      title: title,
      subtitle: item.kind == NotificationKind.songRequest && item.songTitle != null
          ? '${item.songTitle} · $when'
          : when,
    );
  }

  /// history_screen's clock: the time today, the date otherwise.
  String _when(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return sameDay
        ? context.s.t('history.today_at', {
            'time': DateFormat('HH:mm').format(time),
          })
        : DateFormat('MMM d, HH:mm').format(time);
  }
}
