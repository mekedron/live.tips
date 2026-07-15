import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

/// The test button's journey, drawn as one status line under it. The two
/// spinner states narrate; the rest are verdicts.
enum _TestState { idle, sending, repairing, sent, received, unreachable, failed }

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  _TestState _test = _TestState.idle;
  StreamSubscription<Object?>? _testEcho;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _testEcho?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _testRunning =>
      _test == _TestState.sending || _test == _TestState.repairing;

  /// One REAL push through the whole pipeline to this very device. With the
  /// app in the foreground the OS banner rightly stays away — so the page
  /// listens for the message itself and turns delivery into "received ✓"
  /// on the spot; backgrounded, the banner IS the confirmation. A stale
  /// registration is repaired mid-flight (the status line says so) rather
  /// than left to flip the toggle off.
  Future<void> _sendTest() async {
    if (_testRunning) return;
    setState(() => _test = _TestState.sending);
    _testEcho?.cancel();
    _testEcho = ref
        .read(pushServiceProvider)
        .onMessage
        .where((m) => m.data['kind'] == 'test')
        .listen((_) {
      if (mounted) setState(() => _test = _TestState.received);
    });
    final outcome = await ref.read(pushRegistrationProvider).testThisDevice(
      onRepair: () {
        if (mounted) setState(() => _test = _TestState.repairing);
      },
    );
    if (!mounted) return;
    setState(() => _test = switch (outcome) {
          // The echo listener may already have beaten the callable home.
          TestPushOutcome.sent =>
            _test == _TestState.received ? _TestState.received : _TestState.sent,
          TestPushOutcome.unreachable => _TestState.unreachable,
          TestPushOutcome.failed => _TestState.failed,
        });
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
    // A hand on the toggle starts a new chapter: whatever the last test
    // said no longer describes this registration (the stale-verdict-under-
    // a-green-panel screenshot).
    _testEcho?.cancel();
    if (_test != _TestState.idle) setState(() => _test = _TestState.idle);
    if (on) return _enable(); // _enable owns the busy flag
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(pushRegistrationProvider).disableThisDevice();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Registered Jul 15, 18:42" — the token write's own timestamp, so the
  /// panel speaks from the server's record, not the switch's mood.
  String _registeredSubtitle(AppLocalizations s) {
    final atMs = ref.watch(thisDeviceInfoProvider)?.fcmTokenAtMs;
    if (atMs == null) return s.t('settings.notifications.status_active_since_unknown');
    final when = DateFormat('MMM d, HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(atMs));
    return s.t('settings.notifications.status_active_since', {'when': when});
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
              // A guest account's jar is never claimed as owned, so its tips
              // never reach the notification service at all — say it HERE,
              // where the toggles would otherwise promise otherwise.
              if (ref.watch(pushAccountIsGuestProvider)) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 20, color: c.onWarningContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.t('settings.notifications.guest_title'),
                              style: outfitStyle(14, c.onWarningContainer,
                                  weight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.t('settings.notifications.guest_body'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.4,
                          color: c.onWarningContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // ------------------------------------------- this device ---
              // A venue tablet never carries a token — whose tips would it
              // announce, to whom at the counter? The toggle stays, dead
              // and off, with the honest reason and the one way out (the
              // device-kind change in Settings, which wipes the device).
              if (ref.watch(pushDeviceIsVenueProvider))
                LtRowGroup(
                  header: s.t('settings.notifications.device_header'),
                  children: [
                    LtRow(
                      icon: Icons.storefront_rounded,
                      title: s.t('settings.notifications.venue_title'),
                      subtitle: s.t('settings.notifications.venue_subtitle'),
                      trailing: const Switch(value: false, onChanged: null),
                    ),
                  ],
                )
              else
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
                        // The panel says what the toggle alone cannot: is
                        // this device actually REGISTERED (token on its doc,
                        // since when) — and the test button proves delivery
                        // instead of asking the artist to trust a switch.
                        if (ref.watch(thisDevicePushEnabledProvider)) ...[
                          LtRow(
                            leading: _ActiveDot(c: c),
                            title: s.t('settings.notifications.status_active'),
                            subtitle: _registeredSubtitle(s),
                            trailing: Switch(
                              value: true,
                              onChanged: _busy
                                  ? null
                                  : (v) => unawaited(_setThisDevice(v)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _testRunning
                                    ? null
                                    : () => unawaited(_sendTest()),
                                icon: Icon(Icons.send_rounded,
                                    size: 16, color: c.textSecondary),
                                label: Text(
                                  s.t('settings.notifications.send_test'),
                                  style: outfitStyle(13, c.textSecondary,
                                      weight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          LtRow(
                            icon: Icons.notifications_active_rounded,
                            title: s.t('settings.notifications.this_device'),
                            subtitle: s
                                .t('settings.notifications.this_device_subtitle'),
                            trailing: Switch(
                              value: false,
                              onChanged: _busy
                                  ? null
                                  : (v) => unawaited(_setThisDevice(v)),
                            ),
                          ),
                        // The verdict line sits OUTSIDE the on/off branch on
                        // purpose: when a failed repair deliberately switches
                        // this device off, the panel flips to its OFF row —
                        // and the explanation must survive that flip.
                        if (_test != _TestState.idle)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: _TestStatusLine(state: _test),
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

/// The test's one status line: a spinner while it works (sending, or
/// re-registering a stale token mid-flight), then a colored verdict —
/// green when the push physically arrived back, warning when even a fresh
/// registration was rejected and the device was switched off.
class _TestStatusLine extends StatelessWidget {
  const _TestStatusLine({required this.state});

  final _TestState state;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final running =
        state == _TestState.sending || state == _TestState.repairing;
    final (Color color, IconData? icon, String key) = switch (state) {
      _TestState.sending || _TestState.idle => (
          c.textSecondary,
          null,
          'settings.notifications.test_sending',
        ),
      _TestState.repairing => (
          c.textSecondary,
          null,
          'settings.notifications.test_repairing',
        ),
      _TestState.sent => (
          c.textSecondary,
          Icons.mark_email_read_rounded,
          'settings.notifications.test_sent',
        ),
      _TestState.received => (
          c.success,
          Icons.check_circle_rounded,
          'settings.notifications.test_received',
        ),
      _TestState.unreachable => (
          c.warning,
          Icons.error_outline_rounded,
          'settings.notifications.test_unreachable',
        ),
      _TestState.failed => (
          c.danger,
          Icons.error_outline_rounded,
          'settings.notifications.test_failed',
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: running
              ? Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.textSecondary,
                  ),
                )
              : Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.t(key),
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 12.5,
              height: 1.4,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// The bell wearing its green "registered" dot — the settings screen's
/// method-status-dot idea, for the push panel.
class _ActiveDot extends StatelessWidget {
  const _ActiveDot({required this.c});

  final LtColors c;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_active_rounded,
            size: 22, color: c.textSecondary),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: c.success,
              shape: BoxShape.circle,
              border: Border.all(color: c.card, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
