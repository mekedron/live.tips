import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/device_registry.dart';
import '../../data/firebase/link_codes.dart';
import '../../domain/app_account.dart';
import '../../domain/pending_redirect.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../widgets/lt_ui.dart';
import 'add_device_screen.dart';
import 'scan_device_screen.dart';
import 'sign_in_methods_screen.dart';

/// The account's devices, and the two things you can do about them: ask one
/// to sign out (cooperative), or end every other session for real.
///
/// Only ever reached from a signed-in cloud profile — the local profile has
/// no account to have devices on.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _busy = false;

  Future<void> _confirmRevoke(DeviceInfo device) async {
    // THE device in your hand never gets the foreign-revoke path: revoking
    // yourself wipes every profile's cached keys and dumps you to the
    // sign-in screen, from a dialog that promised to ask "that device" to
    // sign out. The row normally shows a pill instead of the button, but
    // this guard holds even if the list's isCurrent marker ever drifts
    // (a rotated device id, a failed registration) — the id comparison is
    // against what THIS device calls itself right now.
    if (device.isCurrent ||
        device.id == ref.read(deviceRegistryProvider).deviceId) {
      return _confirmSignOutSelf();
    }
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.security.revoke_title', {
          'name': device.name.isEmpty
              ? s.t('settings.security.unnamed_device')
              : device.name,
        })),
        content: Text(s.t('settings.security.revoke_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('settings.security.revoke')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(linkCodeServiceProvider).revokeDevice(device.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.t('settings.security.revoke_sent')),
      ));
    } on LinkCodeError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.t('settings.security.revoke_failed')),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Leaving the account on THIS device is an ordinary sign-out, and the
  /// dialog says exactly that — never the revoke wording, which describes
  /// doing something to a device somewhere else.
  Future<void> _confirmSignOutSelf() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.security.sign_out_self_title')),
        content: Text(s.t('settings.security.sign_out_self_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('settings.account.sign_out')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // The same door Settings' Sign out uses — the account leaves this device
    // (#31), not just its session.
    await ref.read(signOutProvider)();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// The real kill switch. It takes THIS device's refresh token down with the
  /// rest (that's what makes it real), so the moment it returns we sign back
  /// in with the same provider — otherwise the artist would have locked
  /// themselves out by tidying up.
  Future<void> _signOutOthers(AccountKind kind) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.security.sign_out_others_title')),
        content: Text(s.t('settings.security.sign_out_others_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('settings.security.sign_out_others_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final deviceId = ref.read(deviceRegistryProvider).deviceId;
    int count;
    try {
      count = await ref
          .read(linkCodeServiceProvider)
          .revokeAllOtherDevices(deviceId);
    } on LinkCodeError {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.t('settings.security.sign_out_others_failed')),
      ));
      return;
    }

    // Our own refresh token is gone. Re-run the same provider sign-in: same
    // uid, fresh auth_time (which the rules' watermark now demands).
    final auth = ref.read(authControllerProvider.notifier);
    // On the WEB that re-auth is a redirect: it returns null because the page
    // is leaving for the provider, NOT because it failed. Treating that null as
    // a failure would sign the artist out on their way to the sign-in page —
    // and the redirect would come back to a signed-out app.
    final redirecting = ref.read(webRedirectSignInProvider) &&
        (kind == AccountKind.apple || kind == AccountKind.google);
    AuthUser? refreshed;
    try {
      refreshed = switch (kind) {
        AccountKind.apple =>
          await auth.signInWithApple(origin: RedirectOrigin.settings),
        AccountKind.google =>
          await auth.signInWithGoogle(origin: RedirectOrigin.settings),
        _ => null,
      };
    } catch (_) {
      refreshed = null;
    }
    // The page is on its way to the provider — unless the redirect could not
    // even start, which the controller reports as an error and which IS a
    // failure to re-authenticate.
    if (redirecting && ref.read(authControllerProvider).error == null) return;
    if (!mounted) return;
    if (refreshed == null) {
      // We cut our own session and could not restore it — land on the local
      // profile and say so plainly, rather than leaving a zombie UI signed
      // into an account it can no longer read.
      await auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.t('settings.security.reauth_failed')),
      ));
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.t('settings.security.sign_out_others_done', {
        'count': '$count',
      })),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final user = ref.watch(authControllerProvider).user;
    final devices = ref.watch(devicesProvider);
    final anonymous = user?.kind == AccountKind.anonymous;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.security.title'))),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.t('settings.security.signed_out'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: kFontBody, color: c.textSecondary),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      s.t('settings.security.intro'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ------------------------------------------- devices ---
                    devices.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => LtRowGroup(
                        header: s.t('settings.security.devices_header'),
                        children: [
                          LtRow(
                            icon: Icons.error_outline_rounded,
                            title: s.t('settings.security.devices_error'),
                          ),
                        ],
                      ),
                      data: (list) => LtRowGroup(
                        header: s.t('settings.security.devices_header'),
                        children: [
                          if (list.isEmpty)
                            LtRow(
                              icon: Icons.devices_other_rounded,
                              title: s.t('settings.security.devices_empty'),
                            )
                          else
                            for (final device in list)
                              _DeviceRow(
                                device: device,
                                busy: _busy,
                                onRevoke: () => _confirmRevoke(device),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // -------------------------------------- add a device ---
                    Row(
                      children: [
                        Expanded(
                          child: LtPrimaryButton(
                            label: s.t('settings.security.add_device'),
                            icon: Icons.qr_code_rounded,
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AddDeviceScreen(),
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const ScanDeviceScreen(),
                                      ),
                                    ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                size: 20),
                            label: Text(s.t('settings.security.scan_qr')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ------------------------------- sign out everywhere ---
                    LtCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LtSectionLabel(
                              s.t('settings.security.sign_out_others_header')),
                          const SizedBox(height: 8),
                          Text(
                            anonymous
                                ? s.t('settings.security.sign_out_others_anonymous')
                                : s.t('settings.security.sign_out_others_subtitle'),
                            style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 12.5,
                              height: 1.45,
                              color: c.textSecondary,
                            ),
                          ),
                          // The instruction, made into a door (#32): telling a
                          // guest to "link Apple or Google first" and leaving
                          // them to hunt for a control that did not exist is
                          // how this screen used to end.
                          if (anonymous)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const SignInMethodsScreen(),
                                          ),
                                        ),
                                child: Text(
                                    s.t('settings.security.link_method')),
                              ),
                            ),
                          const SizedBox(height: 12),
                          LtDangerButton(
                            label: s.t('settings.security.sign_out_others'),
                            icon: Icons.gpp_bad_rounded,
                            busy: _busy,
                            onPressed: anonymous || _busy
                                ? null
                                : () => _signOutOthers(user.kind),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.busy,
    required this.onRevoke,
  });

  final DeviceInfo device;
  final bool busy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final name = device.name.isEmpty
        ? s.t('settings.security.unnamed_device')
        : device.name;
    final subtitle = device.revoked
        ? s.t('settings.security.revoked')
        : lastSeenLabel(context, device.lastSeenAtMs);
    return LtRow(
      icon: devicePlatformIcon(device.platform),
      iconColor: device.revoked ? c.textFaint : null,
      title: name,
      titleColor: device.revoked ? c.textMuted : null,
      subtitle: subtitle,
      trailing: device.isCurrent
          ? LtPill(label: s.t('settings.security.this_device'))
          : device.revoked
              ? null
              : IconButton(
                  // Names its device to the a11y tree, not just visually by
                  // adjacency: a bare "Revoke" is a safety hazard when a
                  // screen-reader user cannot tell WHOSE session the button
                  // ends. The icon's semanticLabel is what TalkBack and
                  // VoiceOver read; the tooltip matches it for sighted
                  // long-pressers.
                  tooltip:
                      s.t('settings.security.revoke_named', {'name': name}),
                  onPressed: busy ? null : onRevoke,
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: c.danger,
                    semanticLabel:
                        s.t('settings.security.revoke_named', {'name': name}),
                  ),
                ),
    );
  }
}

IconData devicePlatformIcon(String platform) => switch (platform) {
      'ios' => Icons.phone_iphone_rounded,
      'android' => Icons.phone_android_rounded,
      'macos' => Icons.laptop_mac_rounded,
      'web' => Icons.language_rounded,
      _ => Icons.devices_other_rounded,
    };

/// "Last seen 3h ago" — coarse on purpose: the exact minute an old phone
/// phoned home is nobody's business, including the owner's.
String lastSeenLabel(BuildContext context, int lastSeenAtMs, {DateTime? now}) {
  final s = context.s;
  if (lastSeenAtMs <= 0) return s.t('settings.security.last_seen_never');
  final at = DateTime.fromMillisecondsSinceEpoch(lastSeenAtMs);
  final delta = (now ?? DateTime.now()).difference(at);
  final when = switch (delta) {
    final d when d.inMinutes < 2 => s.t('settings.security.when_now'),
    final d when d.inHours < 1 =>
      s.t('settings.security.when_minutes', {'n': '${d.inMinutes}'}),
    final d when d.inDays < 1 =>
      s.t('settings.security.when_hours', {'n': '${d.inHours}'}),
    final d => s.t('settings.security.when_days', {'n': '${d.inDays}'}),
  };
  return s.t('settings.security.last_seen', {'when': when});
}
