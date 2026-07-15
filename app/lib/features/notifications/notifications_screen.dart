import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/firebase/notifications_service.dart';
import '../../domain/notification_item.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/notifications_providers.dart';
import '../../widgets/copy_song_title.dart';
import '../../widgets/lt_ui.dart';

/// The bell's page: every tip and song request that arrived while no set was
/// running — newest first, grouped by day, windowed (one screenful at a
/// time, more as you scroll; some accounts have the full server cap sitting
/// here and opening the page must not fetch it all).
///
/// Opening it IS marking it read — the watermark write happens as soon as
/// the first snapshot is on screen — but the entries that were new when the
/// page opened keep their unread dot for the whole visit: the mark is for
/// the NEXT visit's badge, the dot is for this one's "which of these have I
/// not seen". Each row carries its trash, the app bar carries Clear all;
/// deleting is the one client write the rules allow here, and the durable
/// record stays the tip docs in History.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _markedUpToMs = -1;

  /// The watermark as it stood when this page opened — what "new" means for
  /// the whole visit. Captured BEFORE the first mark-read write moves the
  /// real watermark, and never updated after: the dots must not vanish
  /// under the reader's eyes.
  int? _unreadSinceMs;

  /// On every frame that actually SHOWED the feed (marking on initState
  /// would clear a badge for entries never drawn), watermarked at the newest
  /// entry on screen: an entry arriving WHILE the page is open is read the
  /// moment it renders, and one stamped ahead of this device's clock cannot
  /// leave a badge that refuses to die.
  void _markRead(List<NotificationItem> items) {
    // The dots' baseline first, and only once prefs actually loaded —
    // capturing after the mark-read write landed would mark nothing as new.
    final prefs = ref.read(notificationPrefsProvider).value;
    if (prefs == null) return; // stream warming up; next build retries
    _unreadSinceMs ??= prefs.lastSeenAtMs;

    final newest = items.isEmpty ? 0 : items.first.createdAtMs;
    if (_markedUpToMs >= newest) return;
    _markedUpToMs = newest;
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationsServiceProvider)
          .markAllRead(uid, newestSeenMs: newest);
    });
  }

  Future<void> _clearAll() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.t('notifications.clear_all_title')),
        content: Text(s.t('notifications.clear_all_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.t('notifications.clear_all_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.t('notifications.clear_all_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return;
    await ref.read(notificationsServiceProvider).clearAll(uid);
  }

  /// Nearing the bottom grows the window; the stream re-emits with more.
  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) {
      ref.read(notificationsFeedLimitProvider.notifier).grow();
    }
    return false;
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
              _markRead(items);
              if (items.isEmpty) return _EmptyFeed(c: c, s: s);
              return NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    // In the content column, not the app bar: on a wide
                    // window an app-bar action floats in empty space a
                    // screen-width away from the list it acts on.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => unawaited(_clearAll()),
                        icon: Icon(Icons.delete_sweep_rounded,
                            size: 18, color: c.textSecondary),
                        label: Text(
                          s.t('notifications.clear_all'),
                          style: outfitStyle(13, c.textSecondary,
                              weight: FontWeight.w600),
                        ),
                      ),
                    ),
                    ..._dayGroups(context, items),
                    // The window is full to its edge: assume there is more
                    // until a grown window proves otherwise. (A feed exactly
                    // the size of the window shows one quiet spinner-row
                    // that the next emission removes.)
                    if (items.length >=
                            ref.watch(notificationsFeedLimitProvider) &&
                        items.length < NotificationsService.serverCap)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// One [LtRowGroup] per calendar day, newest day first — the list arrives
  /// already sorted, so a single pass splits it.
  List<Widget> _dayGroups(BuildContext context, List<NotificationItem> items) {
    final groups = <Widget>[];
    var groupStart = 0;
    DateTime? day;
    void flush(int end) {
      final flushDay = day;
      if (flushDay == null || groupStart >= end) return;
      groups.add(Padding(
        padding: EdgeInsets.only(top: groups.isEmpty ? 0 : 14),
        child: LtRowGroup(
          header: _dayLabel(context, flushDay),
          children: [
            for (final item in items.sublist(groupStart, end))
              _NotificationRow(
                item: item,
                unread: item.createdAtMs > (_unreadSinceMs ?? 0),
                onDelete: () {
                  final uid = ref.read(authControllerProvider).user?.uid;
                  if (uid == null) return;
                  unawaited(ref
                      .read(notificationsServiceProvider)
                      .delete(uid, item.id));
                },
              ),
          ],
        ),
      ));
    }

    for (var i = 0; i < items.length; i++) {
      final t = DateTime.fromMillisecondsSinceEpoch(items[i].createdAtMs);
      final itemDay = DateTime(t.year, t.month, t.day);
      if (day != itemDay) {
        flush(i);
        day = itemDay;
        groupStart = i;
      }
    }
    flush(items.length);
    return groups;
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return context.s.t('notifications.today');
    if (day == today.subtract(const Duration(days: 1))) {
      return context.s.t('notifications.yesterday');
    }
    return DateFormat('EEEE, MMM d').format(day);
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.c, required this.s});

  final LtColors c;
  final AppLocalizations s;

  @override
  Widget build(BuildContext context) {
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
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.unread,
    required this.onDelete,
  });

  final NotificationItem item;

  /// Newer than the watermark the page OPENED with — this visit's "you
  /// haven't seen this one yet", worn as a dot on the kind icon.
  final bool unread;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
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
    // The day lives in the group header; the row keeps only the clock.
    final when = DateFormat('HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(item.createdAtMs));
    final icon = item.kind == NotificationKind.songRequest
        ? Icons.queue_music_rounded
        : Icons.volunteer_activism_rounded;

    return LtRow(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 22, color: c.textSecondary),
          if (unread)
            Positioned(
              top: -2,
              right: -3,
              child: Container(
                key: ValueKey('unread-dot-${item.id}'),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.card, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: title,
      subtitle: item.kind == NotificationKind.songRequest &&
              item.songTitle != null
          ? '${item.songTitle} · $when'
          : when,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The artist is reading this on the phone their chords live on:
          // the title's one tap away from the clipboard.
          if (item.songTitle case final songTitle?)
            CopySongButton(title: songTitle),
          IconButton(
            tooltip: s.t('notifications.delete_label'),
            icon:
                Icon(Icons.delete_outline_rounded, size: 20, color: c.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
