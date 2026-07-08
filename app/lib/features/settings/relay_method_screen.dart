import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip_method.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../onboarding/relay_setup_screen.dart'
    show extractMobilePayBoxId, mobilePayCurrencyError;

/// Edits a single connected-mode payment method — Revolut or MobilePay — on
/// its own full-page screen (back arrow), mirroring the Stripe key editor.
/// The band's name and currency are set in Account Details, so they don't
/// appear here. The red trash button clears the field and saves, which is how
/// an artist removes a method; clearing the last one disconnects the tip page.
class RelayMethodScreen extends ConsumerStatefulWidget {
  const RelayMethodScreen({super.key, required this.method})
      : assert(method != TipMethod.stripe);

  final TipMethod method;

  @override
  ConsumerState<RelayMethodScreen> createState() => _RelayMethodScreenState();
}

class _RelayMethodScreenState extends ConsumerState<RelayMethodScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _isRevolut => widget.method == TipMethod.revolut;

  @override
  void initState() {
    super.initState();
    final jar = ref.read(appStateProvider).relayJar;
    _controller.text =
        (_isRevolut ? jar?.revolutUsername : jar?.mobilepayBoxId) ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Clears the field and immediately saves — the removal affordance.
  void _clearAndSave() {
    _controller.clear();
    _save();
  }

  Future<void> _save() async {
    final app = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final jar = app.relayJar;

    // Resolve this method's new value from the field.
    String? value;
    if (_isRevolut) {
      final raw = _controller.text.trim().replaceFirst(RegExp(r'^@+'), '');
      if (raw.isNotEmpty &&
          !RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(raw)) {
        setState(() => _error = 'That doesn\'t look like a Revolut username.');
        return;
      }
      value = raw.isEmpty ? null : raw;
    } else {
      final raw = _controller.text.trim();
      if (raw.isNotEmpty) {
        final box = extractMobilePayBoxId(raw);
        if (box == null) {
          setState(() => _error = 'That doesn\'t look like a Box link or id — '
              'paste the share link from MobilePay.');
          return;
        }
        final curErr = mobilePayCurrencyError(app.currency);
        if (curErr != null) {
          setState(() => _error = curErr);
          return;
        }
        value = box;
      } else {
        value = null;
      }
    }

    // The resulting method set after this edit — the other method is untouched.
    final revolut = _isRevolut
        ? value
        : (jar?.hasRevolut ?? false ? jar!.revolutUsername : null);
    final mobilepay = _isRevolut
        ? (jar?.hasMobilePay ?? false ? jar!.mobilepayBoxId : null)
        : value;
    final bothEmpty = (revolut == null || revolut.isEmpty) &&
        (mobilepay == null || mobilepay.isEmpty);

    // Nothing to add for a band with no tip page and an empty field.
    if (jar == null && value == null) {
      Navigator.of(context).pop();
      return;
    }

    // Clearing the last method retires the whole tip page — confirm first.
    if (jar != null && bothEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect tip page?'),
          content: const Text(
            'This is your last tip-page method, so clearing it disconnects '
            'your tip page. Its QR stops working immediately. Tips history '
            'stays on this device.',
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
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final client = RelayClient();
    try {
      if (jar == null) {
        // First tip-page method for this band: register a fresh jar. Name,
        // currency and message ride along from what's already configured.
        final result = await client.createJar(
          artistName: app.displayName,
          currency: app.currency,
          message: app.tipJar?.thankYouMessage,
          stripeUrl: app.tipJar?.url,
          revolutUsername: revolut,
          mobilepayBoxId: mobilepay,
        );
        await notifier.setRelayJar(result.jar, result.secret);
        _finish('Tip page created');
      } else if (bothEmpty) {
        final secret = app.relaySecret;
        if (secret != null) {
          try {
            await client.deleteJar(jarId: jar.jarId, secret: secret);
          } catch (_) {
            // Offline or already gone — the local forget still proceeds.
          }
        }
        await notifier.clearRelayJar();
        _finish('Tip page disconnected');
      } else {
        // Build the jar explicitly so a cleared method becomes null (copyWith
        // can't null a field), then push the full profile to the relay.
        final updated = RelayJar(
          jarId: jar.jarId,
          donateUrl: jar.donateUrl,
          artistName: jar.artistName,
          currency: jar.currency,
          message: jar.message,
          revolutUsername: revolut,
          mobilepayBoxId: mobilepay,
          createdAtMs: jar.createdAtMs,
        );
        await client.updateJar(
          jar: updated,
          secret: app.relaySecret!,
          artistName: jar.artistName,
          message: jar.message,
          stripeUrl: app.tipJar?.url,
        );
        await notifier.updateRelayJarLocal(updated);
        _finish(value == null
            ? '${widget.method.label} removed'
            : '${widget.method.label} saved');
      }
    } on RelayApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on RelayNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(title: Text(widget.method.label)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                _isRevolut
                    ? 'Fans who pick Revolut on your tip page are sent to '
                        'your @username.'
                    : 'Fans who pick MobilePay on your tip page are sent to '
                        'your Box.',
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    height: 1.5,
                    color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(
                        _isRevolut ? 'Revolut username' : 'MobilePay Box'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _isRevolut
                              ? TextField(
                                  controller: _controller,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: InputDecoration(
                                    prefixText: '@',
                                    hintText: 'username',
                                    errorText: _error,
                                    errorMaxLines: 3,
                                  ),
                                  onChanged: (_) {
                                    if (_error != null) {
                                      setState(() => _error = null);
                                    }
                                  },
                                )
                              : TextField(
                                  controller: _controller,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 13.5),
                                  decoration: InputDecoration(
                                    hintText: 'https://qr.mobilepay.fi/box/…',
                                    errorText: _error,
                                    errorMaxLines: 3,
                                  ),
                                  onChanged: (_) {
                                    if (_error != null) {
                                      setState(() => _error = null);
                                    }
                                  },
                                ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton(
                            tooltip: 'Clear & remove this method',
                            onPressed: _busy ? null : _clearAndSave,
                            style: IconButton.styleFrom(
                              backgroundColor: c.danger.withValues(alpha: 0.10),
                              foregroundColor: c.danger,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRevolut
                          ? 'In the Revolut app: tap your profile → your '
                              '@username is under your name. Clear the field '
                              'to remove Revolut.'
                          : 'In MobilePay: open your Box → Share → paste the '
                              'whole link or just the code. MobilePay Boxes '
                              'are EUR only. Clear the field to remove '
                              'MobilePay.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          height: 1.4,
                          color: c.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: 'Save',
                busy: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: outfitStyle(13, context.lt.text)),
    );
  }
}
