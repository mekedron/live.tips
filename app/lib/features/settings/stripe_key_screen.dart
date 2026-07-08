import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';

/// Manages the Stripe restricted key for the active band. Pasting a new key
/// verifies it, then rebuilds the tip jar (Product + Price + Payment Link) in
/// that account — so a moved-account or rotated key always ends up with a
/// working link. The old link is retired and the connected-mode tip page is
/// re-pointed at the new Stripe URL. Full-page with a back arrow, mirroring
/// the Revolut / MobilePay editors.
class StripeKeyScreen extends ConsumerStatefulWidget {
  const StripeKeyScreen({super.key});

  @override
  ConsumerState<StripeKeyScreen> createState() => _StripeKeyScreenState();
}

class _StripeKeyScreenState extends ConsumerState<StripeKeyScreen> {
  final _keyController = TextEditingController();
  bool _busy = false;
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

  String? _validateFormat(String key) {
    if (key.isEmpty) return 'Paste your restricted API key first.';
    if (key.startsWith('pk_')) {
      return 'That\'s a *publishable* key. You need the restricted key '
          '(starts with rk_).';
    }
    if (key.startsWith('sk_live_')) {
      return 'That\'s your full live secret key — too powerful to put on a '
          'device. Create a *restricted* key (rk_live_…) instead.';
    }
    if (!key.startsWith('rk_') && !key.startsWith('sk_test_')) {
      return 'This doesn\'t look like a Stripe restricted key '
          '(expected rk_live_… or rk_test_…).';
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

  Future<void> _replace() async {
    final key = _keyController.text.trim();
    final formatError = _validateFormat(key);
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
        setState(() => _error =
            'Some permissions are missing. Edit the key in Stripe, then '
            'verify again.');
        return;
      }

      // Build the new link with the new key BEFORE mutating any state — a
      // failure here leaves the band on its old, working key.
      final jar = await StripeRequests(probe).createTipJar(
        currency: oldJar?.currency ?? app.currency,
        displayName: app.displayName.isEmpty ? 'My tips' : app.displayName,
        thankYouMessage: oldJar?.thankYouMessage ?? 'Thank you! 💛',
      );

      await notifier.connect(key);
      await notifier.setTipJar(jar);

      // Retire the previous link with the previous key (best effort — it may
      // live in a different account the new key can't touch).
      if (oldJar != null && oldKey != null && !oldJar.isDemo) {
        final oldClient = StripeClient(oldKey);
        try {
          await StripeRequests(oldClient).deactivatePaymentLink(
              oldJar.paymentLinkId);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stripe key replaced — new tip link created')));
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

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final key = _keyController.text.trim();
    final isTest = key.startsWith('rk_test_') || key.startsWith('sk_test_');

    return Scaffold(
      appBar: AppBar(title: const Text('Stripe')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              LtRowGroup(
                children: [
                  LtRow(
                    icon: Icons.key_rounded,
                    title: _maskedKey(app.apiKey),
                    subtitle: 'The restricted key on this device',
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
                    Icon(Icons.warning_amber_rounded, size: 20, color: c.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Replacing the key creates a fresh tip link. Printed '
                        'QR codes with the old Stripe link stop working.',
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13,
                            height: 1.4,
                            color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Paste a new key',
                        style: outfitStyle(16, c.text, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'rk_live_…',
                        suffixIcon: IconButton(
                          tooltip: 'Paste',
                          icon: Icon(Icons.content_paste_rounded,
                              size: 20, color: c.accent),
                          onPressed: _pasteFromClipboard,
                        ),
                      ),
                      onChanged: (_) => setState(() {
                        _error = null;
                        _checks = null;
                      }),
                      onSubmitted: (_) => _replace(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stored in this device\'s keychain. Only ever talks to '
                      'api.stripe.com.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          height: 1.5,
                          color: c.textMuted),
                    ),
                    if (key.isNotEmpty && isTest) ...[
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: LtPill(
                          label: 'Test / sandbox key — payments simulated',
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
                            color: c.danger),
                      ),
                    ],
                    const SizedBox(height: 14),
                    LtPrimaryButton(
                      label: 'Verify & replace',
                      busy: _busy,
                      onPressed: _replace,
                    ),
                  ],
                ),
              ),
              if (_checks != null) ...[
                const SizedBox(height: 14),
                LtCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
