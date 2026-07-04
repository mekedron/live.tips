import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/currencies.dart';
import '../../core/stripe_onboarding.dart';
import '../../data/stripe/stripe_client.dart';
import '../../domain/tip_jar.dart';
import '../../state/providers.dart';
import '../../widgets/qr_card.dart';
import '../settings/stage_preview_screen.dart';

/// Creates the artist's tip jar (Product + pay-what-you-want Price +
/// Payment Link) in their Stripe account.
///
/// Shown as the root screen right after connecting, and pushed from settings
/// with [recreate] to replace an existing link (the old one is deactivated).
class JarSetupScreen extends ConsumerStatefulWidget {
  const JarSetupScreen({super.key, this.recreate = false});

  final bool recreate;

  @override
  ConsumerState<JarSetupScreen> createState() => _JarSetupScreenState();
}

class _JarSetupScreenState extends ConsumerState<JarSetupScreen> {
  final _nameController = TextEditingController();
  final _thanksController = TextEditingController(
    text: 'Thank you for supporting live music! 🎶',
  );
  String _currency = 'usd';
  bool _busy = false;
  String? _error;
  TipJar? _created;
  TipJar? _previousJar;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appStateProvider);
    _previousJar = app.tipJar;
    if (widget.recreate && app.tipJar != null) {
      _nameController.text = app.tipJar!.displayName;
      _currency = app.tipJar!.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thanksController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your tip jar a name — fans will see it.');
      return;
    }
    final requests = ref.read(stripeRequestsProvider);
    if (requests == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final jar = await requests.createTipJar(
        currency: _currency,
        displayName: name,
        thankYouMessage: _thanksController.text.trim().isEmpty
            ? 'Thank you! 💛'
            : _thanksController.text.trim(),
      );
      setState(() => _created = jar);
    } on StripeApiException catch (e) {
      setState(() => _error = e.isPermissionError
          ? '${e.friendlyMessage}\n\nAdd the missing permission to your key '
              'in the Stripe dashboard, then try again.'
          : e.friendlyMessage);
    } on StripeNetworkException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final jar = _created;
    if (jar == null) return;
    // When recreating, retire the old link so stale QR codes stop working
    // predictably. Best effort — the artist can also do it in the dashboard.
    if (widget.recreate && _previousJar != null && !_previousJar!.isDemo) {
      try {
        await ref
            .read(stripeRequestsProvider)
            ?.deactivatePaymentLink(_previousJar!.paymentLinkId);
      } catch (_) {}
    }
    await ref.read(appStateProvider.notifier).setTipJar(jar);
    if (widget.recreate && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recreate ? 'New tip link' : 'Set up your tip jar'),
        automaticallyImplyLeading: widget.recreate,
        actions: [
          if (!widget.recreate)
            TextButton(
              onPressed: () =>
                  ref.read(appStateProvider.notifier).disconnect(),
              child: const Text('Disconnect'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _created != null ? _buildSuccess(theme) : _buildForm(theme),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'This creates a donation link in your Stripe account. '
          'Fans choose their own amount and can leave a name and message.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Artist / band name',
            hintText: 'The Midnight Foxes',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(labelText: 'Currency'),
          items: [
            for (final c in kSupportedCurrencies)
              DropdownMenuItem(value: c, child: Text(c.toUpperCase())),
          ],
          onChanged: (value) =>
              setState(() => _currency = value ?? _currency),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _thanksController,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Thank-you message after payment',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(kApiKeysDashboardUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Edit key permissions in Stripe'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Create my tip link'),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    final jar = _created!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.check_circle_rounded,
            size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Your tip link is live!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Print this QR, tape it to your case, put it on the merch table. '
          'Anyone who scans it can tip you in seconds.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TipLinkCard(url: jar.url),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _finish,
          child: const Text('Continue'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const StagePreviewScreen(),
          )),
          icon: const Icon(Icons.theater_comedy_rounded),
          label: const Text('Choose your stage look'),
        ),
      ],
    );
  }
}
