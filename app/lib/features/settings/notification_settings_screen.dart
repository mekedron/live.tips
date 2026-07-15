import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/notification_item.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/notifications_providers.dart';
import '../../widgets/install_steps.dart';
import '../../widgets/lt_ui.dart';

/// Settings → Notifications: what this account gets pushed about, and whether
/// THIS device is one of the places it lands.
///
/// Two groups, two owners. The kind toggles are the ACCOUNT's (synced through
/// settings/notifications, read by the send trigger); the permission widget
/// and its device toggle are THIS DEVICE's — permission is the browser/OS's
/// per-device fact and the token lives on this device's doc. The widget walks
/// the whole ladder honestly: not supported here, install the app first (iOS
/// Safari), ask me, blocked in settings, or on — each with the one action
/// that actually helps at that rung.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the browser/OS settings the blocked state sent them
    // to: the permission may have changed out from under the cached status.
    if (state == AppLifecycleState.resumed) ref.invalidate(pushStatusProvider);
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome =
          await ref.read(pushRegistrationProvider).enableThisDevice();
      if (!mounted) return;
      if (outcome == PushEnableOutcome.failed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.t('settings.notifications.enable_failed')),
        ));
      }
    } finally {
      // Denied included: the status row flips to "blocked" by re-reading.
      ref.invalidate(pushStatusProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setThisDevice(bool on) async {
    if (on) return _enable(); // _enable owns the busy flag
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(pushRegistrationProvider).disableThisDevice();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final status = ref.watch(pushStatusProvider);
    final prefs =
        ref.watch(notificationPrefsProvider).value ?? const NotificationPrefs();
    final uid = ref.watch(authControllerProvider.select((st) => st.user?.uid));

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.notifications.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // ------------------------------------------- this device ---
              LtRowGroup(
                header: s.t('settings.notifications.device_header'),
                children: [
                  ...switch (status.value) {
                    null => [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ],
                    PushStatus.granted => [
                        LtRow(
                          icon: Icons.notifications_active_rounded,
                          title: s.t('settings.notifications.this_device'),
                          subtitle:
                              s.t('settings.notifications.this_device_subtitle'),
                          trailing: Switch(
                            value: ref.watch(thisDevicePushEnabledProvider),
                            onChanged:
                                _busy ? null : (v) => unawaited(_setThisDevice(v)),
                          ),
                        ),
                      ],
                    PushStatus.canRequest => [
                        LtRow(
                          icon: Icons.notifications_none_rounded,
                          title: s.t('settings.notifications.status_can_request'),
                          subtitle: s.t(
                              'settings.notifications.status_can_request_subtitle'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                          child: LtPrimaryButton(
                            label: s.t('settings.notifications.enable_button'),
                            icon: Icons.notifications_active_rounded,
                            busy: _busy,
                            onPressed: () => unawaited(_enable()),
                          ),
                        ),
                      ],
                    PushStatus.blocked => [
                        LtRow(
                          icon: Icons.notifications_off_rounded,
                          title: s.t('settings.notifications.status_blocked'),
                          subtitle: s.t('settings.notifications.blocked_help'),
                        ),
                      ],
                    PushStatus.needsPwaInstall => [
                        LtRow(
                          icon: Icons.install_mobile_rounded,
                          title: s.t('settings.notifications.status_install'),
                          subtitle:
                              s.t('settings.notifications.status_install_subtitle'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                          child: InstallStepList(
                            steps: installSteps(context, apple: true),
                            numberBg: c.accentSoft,
                            numberFg: c.onAccentSoft,
                            iconColor: c.textSecondary,
                            textColor: c.textSecondary,
                          ),
                        ),
                      ],
                    PushStatus.unsupported => [
                        LtRow(
                          icon: Icons.notifications_off_rounded,
                          title: s.t('settings.notifications.status_unsupported'),
                        ),
                      ],
                  },
                ],
              ),
              const SizedBox(height: 14),
              // ------------------------------------------ what to send ---
              LtRowGroup(
                header: s.t('settings.notifications.kinds_header'),
                children: [
                  LtRow(
                    icon: Icons.volunteer_activism_rounded,
                    title: s.t('settings.notifications.kind_tips'),
                    subtitle: s.t('settings.notifications.kind_tips_subtitle'),
                    trailing: Switch(
                      value: prefs.tips,
                      onChanged: uid == null
                          ? null
                          : (v) => unawaited(ref
                              .read(notificationsServiceProvider)
                              .saveKind(uid, tips: v)),
                    ),
                  ),
                  LtRow(
                    icon: Icons.queue_music_rounded,
                    title: s.t('settings.notifications.kind_requests'),
                    subtitle:
                        s.t('settings.notifications.kind_requests_subtitle'),
                    trailing: Switch(
                      value: prefs.songRequests,
                      onChanged: uid == null
                          ? null
                          : (v) => unawaited(ref
                              .read(notificationsServiceProvider)
                              .saveKind(uid, songRequests: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  s.t('settings.notifications.footnote'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    height: 1.45,
                    color: c.textMuted,
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
