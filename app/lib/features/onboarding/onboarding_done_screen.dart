import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../domain/app_settings.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';

/// The last onboarding step: register the connected-mode tip page from every
/// method the artist entered, then show the one QR they'll actually use.
///
/// The Stripe payment link was already created on its step (its QR would work
/// on its own). Here we build the live.tips donor page that fans open — the
/// "main" QR. If that fails (offline, relay hiccup) we fall back to the Stripe
/// link, which is always created reliably. With no relay methods at all, the
/// Stripe QR is the main QR outright.
class OnboardingDoneScreen extends ConsumerStatefulWidget {
  const OnboardingDoneScreen({super.key});

  @override
  ConsumerState<OnboardingDoneScreen> createState() =>
      _OnboardingDoneScreenState();
}

class _OnboardingDoneScreenState extends ConsumerState<OnboardingDoneScreen> {
  bool _working = true;
  String? _url;
  bool _connectedPage = false;
  bool _relayFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final app = ref.read(appStateProvider);
    final draft = ref.read(onboardingDraftProvider);
    final revolut = (draft?.revolutUsername?.trim().isNotEmpty ?? false)
        ? draft!.revolutUsername
        : null;
    final mobilepay = (draft?.mobilepayBoxId?.trim().isNotEmpty ?? false)
        ? draft!.mobilepayBoxId
        : null;
    final wantsRelay = revolut != null || mobilepay != null;

    if (wantsRelay && app.relayJar == null) {
      final client = RelayClient();
      try {
        final result = await client.createJar(
          artistName: draft!.name.isNotEmpty ? draft.name : app.displayName,
          message: draft.thankYouMessage.isEmpty ? null : draft.thankYouMessage,
          currency: draft.currency,
          stripeUrl: app.tipJar?.url,
          revolutUsername: revolut,
          mobilepayBoxId: mobilepay,
        );
        await ref
            .read(appStateProvider.notifier)
            .setRelayJar(result.jar, result.secret);
        if (!mounted) return;
        setState(() {
          _url = result.jar.donateUrl;
          _connectedPage = true;
          _working = false;
        });
        return;
      } catch (_) {
        // Fall back to the Stripe link (or nothing) below.
        if (!mounted) return;
        setState(() => _relayFailed = true);
      } finally {
        client.close();
      }
    }

    if (!mounted) return;
    // No relay methods, or the relay registration failed: fall back to
    // whatever QR the band already resolves to (the Stripe link, usually).
    setState(() {
      _url = ref.read(appStateProvider).activeQrUrl;
      _connectedPage =
          ref.read(appStateProvider).effectiveQrMode == QrMode.connected;
      _working = false;
    });
  }

  void _finish() {
    ref.read(onboardingDraftProvider.notifier).clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _working
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: c.successContainer, shape: BoxShape.circle),
                        child:
                            Icon(Icons.check_rounded, size: 34, color: c.success),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _url == null ? 'You\'re all set' : 'Your tip QR is ready!',
                      textAlign: TextAlign.center,
                      style: outfitStyle(26, c.text, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _url == null
                          ? 'You didn\'t add a payment method yet. Add one '
                              'anytime from Settings, then share your QR.'
                          : _connectedPage
                              ? 'One QR for every way you take tips. Print it, '
                                  'tape it to your case, put it on the merch '
                                  'table.'
                              : 'Print it, tape it to your case, put it on the '
                                  'merch table — anyone can tip you in seconds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 14,
                          height: 1.5,
                          color: c.textSecondary),
                    ),
                    if (_relayFailed && _url != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'We couldn\'t reach the live.tips relay to build your '
                          'all-methods page, so this is your Stripe QR for now. '
                          'Open Settings later to finish your tip page.',
                          style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 12.5,
                              height: 1.4,
                              color: c.text),
                        ),
                      ),
                    ],
                    if (_url != null) ...[
                      const SizedBox(height: 24),
                      LtCard(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            QrBlock(data: _url!, size: 180),
                            const SizedBox(height: 14),
                            Text(
                              _url!.replaceFirst(RegExp('^https?://'), ''),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    LtPrimaryButton(
                      label: _url == null ? 'Go to Home' : 'Done',
                      onPressed: _finish,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
