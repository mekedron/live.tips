import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../domain/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../poster/poster_screen.dart';

/// The last onboarding step: register the connected-mode tip page from every
/// method the artist entered, then show the one QR they'll actually use.
///
/// The Stripe payment link was already created on its step (its QR would work
/// on its own). Here we build the live.tips fan page that fans open — the
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

  /// Retry after a failed relay registration — the artist's entries are all
  /// still in the draft, so this is a second attempt at the same call.
  void _retry() {
    setState(() {
      _working = true;
      _relayFailed = false;
    });
    unawaited(_prepare());
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
    final monzo = (draft?.monzoUsername?.trim().isNotEmpty ?? false)
        ? draft!.monzoUsername
        : null;
    final wantsRelay = revolut != null || mobilepay != null || monzo != null;

    if (wantsRelay && app.relayJar == null) {
      try {
        final result = await ref.read(relayClientProvider).createJar(
          artistName: draft!.name.isNotEmpty ? draft.name : app.displayName,
          message: draft.thankYouMessage.isEmpty ? null : draft.thankYouMessage,
          currency: draft.currency,
          stripeUrl: app.tipJar?.url,
          revolutUsername: revolut,
          mobilepayBoxId: mobilepay,
          monzoUsername: monzo,
        );
        await ref
            .read(appStateProvider.notifier)
            .setRelayJar(result.jar, result.secret);
        if (!mounted) return;
        setState(() {
          _url = result.jar.tipUrl;
          _connectedPage = true;
          _working = false;
        });
        return;
      } catch (_) {
        // Fall back to the Stripe link (or nothing) below — but the failure
        // is NEVER swallowed: this screen may not show a green check and
        // "You're all set" over a tip page that was never created.
        if (!mounted) return;
        setState(() => _relayFailed = true);
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
    // The run is over; its account steps must not inflate the next one's
    // step counter (adding a band later starts at "Step 1").
    ref.read(onboardingPreludeProvider.notifier).reset();
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
                          color: _relayFailed
                              ? kGold.withValues(alpha: 0.18)
                              : c.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _relayFailed
                              ? Icons.warning_amber_rounded
                              : Icons.check_rounded,
                          size: 34,
                          color: _relayFailed ? c.text : c.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _relayFailed
                          ? context.s.t('onboarding.done.title_relay_failed')
                          : _url == null
                          ? context.s.t('onboarding.done.title_no_method')
                          : context.s.t('onboarding.done.title_ready'),
                      textAlign: TextAlign.center,
                      style: outfitStyle(26, c.text, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relayFailed
                          ? context.s
                              .t('onboarding.done.subtitle_relay_failed')
                          : _url == null
                          ? context.s.t('onboarding.done.subtitle_no_method')
                          : _connectedPage
                          ? context.s.t('onboarding.done.subtitle_connected')
                          : context.s.t('onboarding.done.subtitle_stripe'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 14,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    // A relay-only band has no fallback QR at all (_url is
                    // null), and THAT is exactly the case the old
                    // `_relayFailed && _url != null` guard hid: green check,
                    // "You're all set", and a band with no way to be tipped.
                    if (_relayFailed) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          [
                            context.s.t('onboarding.done.relay_failed_body'),
                            if (_url != null)
                              context.s
                                  .t('onboarding.done.relay_failed_stripe_note'),
                          ].join(' '),
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 12.5,
                            height: 1.4,
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LtPrimaryButton(
                        label: context.s.t('onboarding.done.retry'),
                        trailingIcon: Icons.refresh_rounded,
                        onPressed: _retry,
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
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // The same open / copy / share / poster row as Home.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LtIconCircleButton(
                            icon: Icons.open_in_new_rounded,
                            tooltip: context.s.t(
                              'onboarding.done.open_tooltip',
                            ),
                            onTap: () => openTipLink(_url!),
                          ),
                          const SizedBox(width: 12),
                          LtIconCircleButton(
                            icon: Icons.content_copy_rounded,
                            tooltip: context.s.t(
                              'onboarding.done.copy_tooltip',
                            ),
                            onTap: () => copyTipLink(context, _url!),
                          ),
                          const SizedBox(width: 12),
                          LtIconCircleButton(
                            icon: Icons.ios_share_rounded,
                            tooltip: context.s.t(
                              'onboarding.done.share_tooltip',
                            ),
                            onTap: () => SharePlus.instance.share(
                              ShareParams(text: _url!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          LtIconCircleButton(
                            icon: Icons.print_rounded,
                            tooltip: context.s.t(
                              'onboarding.done.poster_tooltip',
                            ),
                            onTap: () => openPoster(context),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    // A failure ends on the quiet exit, never on "Done" —
                    // the loud action above is the retry.
                    if (_relayFailed)
                      OutlinedButton(
                        onPressed: _finish,
                        child: Text(context.s.t('onboarding.done.go_home')),
                      )
                    else
                      LtPrimaryButton(
                        label: _url == null
                            ? context.s.t('onboarding.done.go_home')
                            : context.s.t('onboarding.done.done'),
                        onPressed: _finish,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
