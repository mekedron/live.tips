import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/stripe_onboarding.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../state/providers.dart';
import '../../widgets/qr_card.dart';
import 'key_guide_screen.dart';

/// Bring-your-own-key onboarding: the artist creates a *restricted* key in
/// their own dashboard, pastes it here, and we verify every permission
/// before letting them through.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _keyController = TextEditingController();
  bool _busy = false;
  String? _error;
  KeyCheckResult? _checks;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  String? _validateFormat(String key) {
    if (key.isEmpty) return 'Paste your restricted API key first.';
    if (key.startsWith('pk_')) {
      return 'That\'s a *publishable* key. You need the restricted key '
          '(starts with rk_) — see the guide below.';
    }
    if (key.startsWith('sk_live_')) {
      return 'That\'s your full live secret key — too powerful to put on a '
          'device. Create a *restricted* key (rk_live_…) instead; it takes '
          'two minutes and can only do what this app needs.';
    }
    if (!key.startsWith('rk_') && !key.startsWith('sk_test_')) {
      return 'This doesn\'t look like a Stripe restricted key '
          '(expected rk_live_… or rk_test_…).';
    }
    return null;
  }

  Future<void> _verifyAndConnect() async {
    final key = _keyController.text.trim();
    final formatError = _validateFormat(key);
    setState(() {
      _error = formatError;
      _checks = null;
    });
    if (formatError != null) return;

    setState(() => _busy = true);
    final client = StripeClient(key);
    try {
      final result = await StripeRequests(client).checkKeyPermissions();
      if (!mounted) return;
      setState(() => _checks = result);
      if (result.allOk) {
        await ref.read(appStateProvider.notifier).connect(key);
        if (!mounted) return;
        // RootGate now routes to tip jar setup.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _error = 'Some permissions are missing. Edit the key in Stripe, '
              'then verify again.';
        });
      }
    } on StripeApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on StripeNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = _keyController.text.trim();
    final isTest = key.startsWith('rk_test_') || key.startsWith('sk_test_');

    return Scaffold(
      appBar: AppBar(title: const Text('Connect Stripe')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How this works',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Open your Stripe dashboard and create a '
                        'restricted API key with the four permissions below.\n'
                        '2. Paste the key here — it\'s stored only in this '
                        'device\'s keychain and talks directly to Stripe.\n'
                        '3. We create your personal donation link. Done.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => launchUrl(
                              Uri.parse(kCreateKeyUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 18),
                            label: const Text(
                                'Create the key (pre-filled) in Stripe'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const KeyGuideScreen()),
                            ),
                            icon: const Icon(Icons.menu_book_rounded,
                                size: 18),
                            label: const Text('Step-by-step guide'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                showFullscreenQr(context, kCreateKeyUrl),
                            icon: const Icon(Icons.qr_code_rounded, size: 18),
                            label: const Text('QR for your laptop'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The pre-filled link selects exactly the five '
                        'permissions below — you just review and click '
                        '“Create key”.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Permissions the key needs',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Everything else stays “None” — the key can\'t touch '
                        'payouts, refunds or your balance.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      for (final p in kRequiredPermissions)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.access,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.resource,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(p.why,
                                        style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Restricted API key',
                  hintText: 'rk_live_…',
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                onChanged: (_) => setState(() {
                  _error = null;
                  _checks = null;
                }),
                onSubmitted: (_) => _verifyAndConnect(),
              ),
              if (key.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      isTest ? Icons.science_rounded : Icons.bolt_rounded,
                      size: 16,
                    ),
                    label: Text(isTest
                        ? 'Test / sandbox key — payments will be simulated'
                        : 'Live key — real payments'),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (_checks != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      for (final check in _checks!.checks)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            check.ok
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: check.ok
                                ? Colors.greenAccent
                                : theme.colorScheme.error,
                          ),
                          title: Text(check.label),
                          subtitle:
                              check.detail == null ? null : Text(check.detail!),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _verifyAndConnect,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Verify & connect'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
