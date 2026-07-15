import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/notifications_providers.dart';
import '../../state/root_world.dart';
import 'notifications_screen.dart';

/// The home header's bell: what arrived while nobody was watching. Wears the
/// unread count from [unreadNotificationsProvider] and opens the feed page.
///
/// Cloud accounts only — the feed is server-written into the account, so on
/// the local profile (or signed out) there is nothing to ring about and the
/// bell isn't drawn at all, matching how the rest of the header treats
/// cloud-only affordances: absent, not disabled.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
    if (uid == null) return const SizedBox.shrink();
    final c = context.lt;
    final unread = ref.watch(unreadNotificationsProvider);
    // Two digits is a badge; more is a smear. The page itself shows the rest.
    final label = unread > 99 ? '99+' : '$unread';

    return Semantics(
      button: true,
      label: context.s.t('notifications.bell_label'),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          RootBoundRoute<void>(
            builder: (_) => const NotificationsScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: c.textSecondary,
              ),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: outfitStyle(10.5, c.onAccent, weight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
