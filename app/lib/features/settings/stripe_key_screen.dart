import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/external_link.dart';
import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../onboarding/key_guide_screen.dart';
import '../shell/app_shell.dart' show kRailBreakpoint;

/// Connects or replaces the Stripe restricted key for the active band, from
/// Settings. It's deliberately minimal: the name, currency and thank-you
/// message already live in Account details, so this screen only takes the
/// key. Saving verifies it and builds the tip jar (Product + Price + Payment
/// Link) in that account — reusing the band's details — so a first connect, a
/// rotated key, or a moved account all end with a working link. No QR here:
/// the artist lands back on Settings with a green "connected" dot. Full-page
/// with a back arrow, mirroring the Revolut / MobilePay editors.
class StripeKeyScreen extends ConsumerStatefulWidget {
  const StripeKeyScreen({super.key});

  @override
  ConsumerState<StripeKeyScreen> createState() => _StripeKeyScreenState();
}

class _StripeKeyScreenState extends ConsumerState<StripeKeyScreen> {
  final _keyController = TextEditingController();
  bool _busy = false;
  bool _removing = false;
  String? _error;
  KeyCheckResult? _checks;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  String _maskedKey(String? key) {
    if (key == null) return '—';
    if (key.length <= 12) return '••••';
    return '${key.substring(0, 8)}…${key.substring(key.length - 4)}';
  }

  String? _validateFormat(BuildContext context, String key) {
    if (key.isEmpty) return context.s.t('settings.stripe_key.error_empty');
    if (key.startsWith('pk_')) {
      return context.s.t('settings.stripe_key.error_publishable');
    }
    if (key.startsWith('sk_live_')) {
      return context.s.t('settings.stripe_key.error_secret');
    }
    if (!key.startsWith('rk_') && !key.startsWith('sk_test_')) {
      return context.s.t('settings.stripe_key.error_format');
    }
    return null;
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _keyController.text = text;
        _error = null;
        _checks = null;
      });
    }
  }

  /// Mobile "?" affordance: the same permission table as the desktop card,
  /// surfaced on demand so it doesn't push the paste field down.
  void _showKeyPermissions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final c = context.lt;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              children: [
                Text(
                  context.s.t('settings.stripe_key.key_permissions_title'),
                  style: outfitStyle(18, c.text, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const _KeyPermissionsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final key = _keyController.text.trim();
    final formatError = _validateFormat(context, key);
    setState(() {
      _error = formatError;
      _checks = null;
    });
    if (formatError != null) return;

    final app = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final oldJar = app.tipJar;
    final oldKey = app.apiKey;

    setState(() => _busy = true);
    final probe = StripeClient(key);
    try {
      final result = await StripeRequests(probe).checkKeyPermissions();
      if (!mounted) return;
      setState(() => _checks = result);
      if (!result.allOk) {
        setState(
          () => _error = context.s.t('settings.stripe_key.error_permissions'),
        );
        return;
      }

      // Build the link with the new key BEFORE mutating any state — a failure
      // here leaves the band exactly as it was. Details come from what's
      // already configured (Account details), never re-asked here.
      final jar = await StripeRequests(probe).createTipJar(
        currency: oldJar?.currency ?? app.currency,
        displayName: app.displayName.isEmpty
            ? context.s.t('settings.stripe_key.default_display_name')
            : app.displayName,
        thankYouMessage:
            oldJar?.thankYouMessage ??
            app.relayJar?.message ??
            context.s.t('settings.stripe_key.default_thanks'),
      );

      await notifier.connect(key);
      await notifier.setTipJar(jar);

      // Retire the previous link with the previous key (best effort — it may
      // live in a different account the new key can't touch).
      if (oldJar != null && oldKey != null && !oldJar.isDemo) {
        final oldClient = StripeClient(oldKey);
        try {
          await StripeRequests(
            oldClient,
          ).deactivatePaymentLink(oldJar.paymentLinkId);
        } catch (_) {
        } finally {
          oldClient.close();
        }
      }

      // Re-point the connected-mode tip page's card button at the new link.
      final relayJar = app.relayJar;
      final secret = app.relaySecret;
      if (relayJar != null && secret != null) {
        final client = RelayClient();
        try {
          await client.updateJar(
            jar: relayJar,
            secret: secret,
            artistName: jar.displayName,
            message: relayJar.message,
            stripeUrl: jar.url,
          );
        } catch (_) {
          // Best effort — the page keeps the old URL until the next sync.
        } finally {
          client.close();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              oldKey == null
                  ? context.s.t('settings.stripe_key.connected_snack')
                  : context.s.t('settings.stripe_key.replaced_snack'),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on StripeApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on StripeNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      probe.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Forgets the Stripe key + tip jar for this band. The payment link is
  /// retired and dropped from the connected-mode fan page (both best
  /// effort). The Stripe account itself is untouched.
  Future<void> _disconnect() async {
    final app = ref.read(appStateProvider);
    final oldJar = app.tipJar;
    final relayJar = app.relayJar;
    final relaySecret = app.relaySecret;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.t('settings.stripe_key.disconnect_title')),
        content: Text(context.s.t('settings.stripe_key.disconnect_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.t('settings.stripe_key.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.s.t('settings.stripe_key.disconnect_confirm')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _busy = true;
      _removing = true;
      _error = null;
    });
    try {
      // Retire the payment link while the key is still on the device.
      final requests = ref.read(stripeRequestsProvider);
      if (oldJar != null && !oldJar.isDemo) {
        try {
          await requests?.deactivatePaymentLink(oldJar.paymentLinkId);
        } catch (_) {
          // Best effort — forgetting the key locally matters more.
        }
      }
      // Drop the card button from the connected-mode fan page.
      if (relayJar != null && relaySecret != null) {
        final client = RelayClient();
        try {
          await client.updateJar(
            jar: relayJar,
            secret: relaySecret,
            artistName: relayJar.artistName,
            message: relayJar.message,
            stripeUrl: null,
          );
        } catch (_) {
        } finally {
          client.close();
        }
      }
      await ref.read(appStateProvider.notifier).disconnectStripe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.s.t('settings.stripe_key.disconnected_snack'),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _removing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final connected = app.hasStripe;
    final key = _keyController.text.trim();
    final isTest = key.startsWith('rk_test_') || key.startsWith('sk_test_');
    // On phones the permissions live behind a "?" so the paste field isn't
    // buried below the fold; wide layouts keep the full card visible.
    final wide = MediaQuery.sizeOf(context).width >= kRailBreakpoint;

    return Scaffold(
      appBar: AppBar(title: Text(context.s.t('settings.stripe_key.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                connected
                    ? context.s.t('settings.stripe_key.intro_connected')
                    : context.s.t('settings.stripe_key.intro_new'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (connected) ...[
                LtRowGroup(
                  children: [
                    LtRow(
                      icon: Icons.key_rounded,
                      title: _maskedKey(app.apiKey),
                      subtitle: context.s.t(
                        'settings.stripe_key.key_row_subtitle',
                      ),
                      trailing: StatusPill(
                        status: app.isTestMode
                            ? LtKeyStatus.test
                            : LtKeyStatus.live,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.danger.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: c.danger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.s.t('settings.stripe_key.replace_warning'),
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13,
                            height: 1.4,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.s.t('settings.stripe_key.create_key_heading'),
                      style: outfitStyle(16, c.text, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.s.t('settings.stripe_key.create_key_subtitle'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NumberedLine(1, context.s.t('settings.stripe_key.step1')),
                    const SizedBox(height: 10),
                    _NumberedLine(2, context.s.t('settings.stripe_key.step2')),
                    const SizedBox(height: 10),
                    _NumberedLine(3, context.s.t('settings.stripe_key.step3')),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => openExternal(kCreateKeyUrl),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: Text(
                              context.s.t('settings.stripe_key.open_form'),
                            ),
                          ),
                        ),
                        // Phones drop the permissions card; this reveals the
                        // same table on demand right at the call to action.
                        if (!wide) ...[
                          const SizedBox(width: 8),
                          LtIconCircleButton(
                            icon: Icons.help_outline_rounded,
                            tooltip: context.s.t(
                              'settings.stripe_key.key_permissions_title',
                            ),
                            size: 48,
                            onTap: () => _showKeyPermissions(context),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KeyGuideScreen(),
                            ),
                          ),
                          child: Text(
                            context.s.t('settings.stripe_key.guide_button'),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              showFullscreenQr(context, kCreateKeyUrl),
                          child: Text(
                            context.s.t('settings.stripe_key.qr_button'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (wide) ...[
                const SizedBox(height: 14),
                LtCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.s.t(
                          'settings.stripe_key.key_permissions_title',
                        ),
                        style: outfitStyle(16, c.text, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const _KeyPermissionsList(),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      connected
                          ? context.s.t(
                              'settings.stripe_key.paste_title_connected',
                            )
                          : context.s.t('settings.stripe_key.paste_title_new'),
                      style: outfitStyle(16, c.text, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'rk_live_…',
                        suffixIcon: IconButton(
                          tooltip: context.s.t(
                            'settings.stripe_key.paste_tooltip',
                          ),
                          icon: Icon(
                            Icons.content_paste_rounded,
                            size: 20,
                            color: c.accent,
                          ),
                          onPressed: _pasteFromClipboard,
                        ),
                      ),
                      onChanged: (_) => setState(() {
                        _error = null;
                        _checks = null;
                      }),
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.s.t('settings.stripe_key.storage_note'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        height: 1.5,
                        color: c.textMuted,
                      ),
                    ),
                    if (key.isNotEmpty && isTest) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LtPill(
                          label: context.s.t(
                            'settings.stripe_key.test_key_pill',
                          ),
                          icon: Icons.science_rounded,
                          soft: false,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.45,
                          color: c.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Button lives below the card — matching the Revolut / MobilePay
              // editors and the onboarding connect step — so the layout reads
              // the same across every method.
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: connected
                    ? context.s.t('settings.stripe_key.verify_update')
                    : context.s.t('settings.stripe_key.verify_connect'),
                busy: _busy && !_removing,
                onPressed: _busy ? null : _save,
              ),
              if (connected) ...[
                const SizedBox(height: 12),
                LtDangerButton(
                  label: context.s.t('settings.stripe_key.disconnect_button'),
                  onPressed: _busy ? null : _disconnect,
                  busy: _removing,
                ),
              ],
              if (_checks != null) ...[
                const SizedBox(height: 14),
                LtCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _checks!.checks.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: c.divider),
                        _CheckRow(check: _checks!.checks[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      children: [
        LtStepNumber(number, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 14,
              color: c.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// The permission table plus the "everything else is None" caveat — shared
/// by the desktop card and the mobile "?" bottom sheet.
class _KeyPermissionsList extends StatelessWidget {
  const _KeyPermissionsList();

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < kRequiredPermissions.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.divider),
          _PermissionRow(permission: kRequiredPermissions[i]),
        ],
        const SizedBox(height: 8),
        Text(
          context.s.t('settings.stripe_key.permissions_caveat'),
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 12,
            height: 1.5,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.permission});

  final RequiredPermission permission;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final write = permission.access == 'Write';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.resource,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                Text(
                  context.s.t('enum.perm_why.${permission.slug}'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12,
                    height: 1.35,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: write ? c.accentSoft : c.chip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              permission.access,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: write ? c.onAccentSoft : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final PermissionCheck check;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            check.ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: check.ok ? c.success : c.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              check.label,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
