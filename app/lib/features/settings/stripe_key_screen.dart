import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/external_link.dart';
import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';

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

  static const _defaultThanks = 'Thank you! 💛';

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

  Future<void> _save() async {
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

      // Build the link with the new key BEFORE mutating any state — a failure
      // here leaves the band exactly as it was. Details come from what's
      // already configured (Account details), never re-asked here.
      final jar = await StripeRequests(probe).createTipJar(
        currency: oldJar?.currency ?? app.currency,
        displayName: app.displayName.isEmpty ? 'My tips' : app.displayName,
        thankYouMessage: oldJar?.thankYouMessage ??
            app.relayJar?.message ??
            _defaultThanks,
      );

      await notifier.connect(key);
      await notifier.setTipJar(jar);

      // Retire the previous link with the previous key (best effort — it may
      // live in a different account the new key can't touch).
      if (oldJar != null && oldKey != null && !oldJar.isDemo) {
        final oldClient = StripeClient(oldKey);
        try {
          await StripeRequests(oldClient)
              .deactivatePaymentLink(oldJar.paymentLinkId);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(oldKey == null
                ? 'Stripe connected'
                : 'Stripe key replaced — new tip link created')));
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
  /// retired and dropped from the connected-mode donor page (both best
  /// effort). The Stripe account itself is untouched.
  Future<void> _disconnect() async {
    final app = ref.read(appStateProvider);
    final oldJar = app.tipJar;
    final relayJar = app.relayJar;
    final relaySecret = app.relaySecret;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Stripe?'),
        content: const Text(
          'Removes the Stripe key and tip link from this account on this device. '
          'Your Stripe account and its payments stay in Stripe — you can '
          'reconnect a key any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
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
      // Drop the card button from the connected-mode donor page.
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
            const SnackBar(content: Text('Stripe disconnected')));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Stripe')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                connected
                    ? 'Card tips settle straight to your Stripe account. '
                        'Paste a new key to move accounts or rotate the key.'
                    : 'Card tips settle straight to your Stripe account. Your '
                        'name, currency and thank-you message come from '
                        'Account details — just paste your restricted key.',
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    height: 1.5,
                    color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              if (connected) ...[
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
                    border:
                        Border.all(color: c.danger.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 20, color: c.danger),
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
              ] else ...[
                LtCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Need a key? Create a restricted key in your Stripe '
                          'dashboard — it takes two minutes.',
                          style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 13,
                              height: 1.4,
                              color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => openExternal(kCreateKeyUrl),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open'),
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
                    Text(connected ? 'Paste a new key' : 'Paste your key',
                        style:
                            outfitStyle(16, c.text, weight: FontWeight.w700)),
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
                      onSubmitted: (_) => _save(),
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
                      label: connected ? 'Verify & replace' : 'Verify & connect',
                      busy: _busy && !_removing,
                      onPressed: _busy ? null : _save,
                    ),
                  ],
                ),
              ),
              if (connected) ...[
                const SizedBox(height: 12),
                LtDangerButton(
                  label: 'Disconnect Stripe',
                  onPressed: _busy ? null : _disconnect,
                  busy: _removing,
                ),
              ],
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
