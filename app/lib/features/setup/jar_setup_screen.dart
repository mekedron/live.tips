import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/external_link.dart';

import '../../core/currencies.dart';
import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip_jar.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../settings/stage_preview_screen.dart';
import '../shell/app_shell.dart';

/// Creates the artist's tip jar (Product + pay-what-you-want Price +
/// Payment Link) in their Stripe account. Step number comes from the
/// onboarding draft (falls back to 2 of 2 when there is none).
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
  final _thanksController = TextEditingController();
  String _currency = 'usd';
  bool _busy = false;
  String? _error;
  TipJar? _created;
  TipJar? _previousJar;
  bool _appliedThanksDefault = false;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appStateProvider);
    _previousJar = app.tipJar;
    if (widget.recreate && app.tipJar != null) {
      _nameController.text = app.tipJar!.displayName;
      _currency = app.tipJar!.currency;
      _thanksController.text = app.tipJar!.thankYouMessage;
      _appliedThanksDefault = true;
    } else if (app.relayJar != null) {
      // Adding Stripe to a band that already has a relay jar: match its
      // currency so the two never diverge (e.g. relay in EUR, Stripe in USD).
      _currency = app.relayJar!.currency;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill the localized default thank-you message once (context isn't
    // available in initState). Skipped when recreating, which already loaded
    // the existing message above.
    if (!_appliedThanksDefault) {
      _appliedThanksDefault = true;
      _thanksController.text = context.s.t('setup.thanks_default');
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
      setState(() => _error = context.s.t('setup.error_name_required'));
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
            ? context.s.t('setup.thanks_fallback')
            : _thanksController.text.trim(),
      );
      setState(() => _created = jar);
    } on StripeApiException catch (e) {
      setState(
        () => _error = e.isPermissionError
            ? context.s.t('setup.error_permission', {
                'message': e.friendlyMessage,
              })
            : e.friendlyMessage,
      );
    } on StripeNetworkException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Commits the new jar to app state; when recreating, retires the old
  /// link first so stale QR codes stop working predictably.
  Future<void> _finish({ShellTab? thenOpen}) async {
    final jar = _created;
    if (jar == null) return;
    // Captured up front: setTipJar can swap RootGate's home away from this
    // screen (fresh onboarding), unmounting us before the pushes below.
    final navigator = Navigator.of(context);
    final app = ref.read(appStateProvider);
    if (widget.recreate && _previousJar != null && !_previousJar!.isDemo) {
      try {
        await ref
            .read(stripeRequestsProvider)
            ?.deactivatePaymentLink(_previousJar!.paymentLinkId);
      } catch (_) {}
    }
    await ref.read(appStateProvider.notifier).setTipJar(jar);
    // Connected mode: the donor page's card button must follow the new
    // Stripe link (and name). Best effort — never blocks the artist.
    final relayJar = app.relayJar;
    final relaySecret = app.relaySecret;
    if (relayJar != null && relaySecret != null) {
      unawaited(_syncRelayStripeUrl(relayJar, relaySecret, jar));
    }
    if (thenOpen != null) {
      ref.read(shellTabRequestProvider.notifier).request(thenOpen);
    }
    if (widget.recreate) {
      navigator.pop();
      return;
    }
    // Fresh (RootGate's hasStripe-but-no-jar fallback): setTipJar swaps
    // RootGate to the shell on its own — nothing more to push.
  }

  /// Backs out of Stripe setup: only the just-connected key goes away —
  /// the band, its other methods, and its history all stay.
  Future<void> _cancelSetup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s.t('setup.cancel_title')),
        content: Text(context.s.t('setup.cancel_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.t('setup.keep_setting_up')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.s.t('setup.remove_key')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(appStateProvider.notifier).cancelStripeSetup();
  }

  /// Tells the relay about the (re)created Stripe link so the donor page's
  /// card button never points at a retired payment link. Silent on failure:
  /// the page just keeps the old link until the next successful update.
  static Future<void> _syncRelayStripeUrl(
    RelayJar relayJar,
    String secret,
    TipJar jar,
  ) async {
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
      // Best effort only.
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _created != null
          ? null
          : AppBar(
              title: Text(
                widget.recreate
                    ? context.s.t('setup.recreate_title')
                    : context.s.t('setup.create_title'),
              ),
              automaticallyImplyLeading: widget.recreate,
              actions: [
                if (widget.recreate)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: LtPill(
                        label: context.s.t('setup.replaces_old_link'),
                      ),
                    ),
                  )
                else ...[
                  if (ref.watch(
                        appStateProvider.select((s) => s.accounts.length),
                      ) >
                      1)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Center(child: BandChip()),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: _cancelSetup,
                      child: Text(context.s.t('setup.cancel')),
                    ),
                  ),
                ],
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _created != null ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final c = context.lt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (widget.recreate) ...[
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
                    context.s.t('setup.recreate_warning'),
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
          const SizedBox(height: 16),
        ],
        Text(
          context.s.t('setup.intro'),
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 14,
            height: 1.5,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        LtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel(context.s.t('setup.name_label')),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: context.s.t('setup.name_hint'),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.s.t('setup.name_help'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(context.s.t('setup.currency')),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showLtPicker<String>(
                    context: context,
                    title: context.s.t('setup.currency'),
                    values: kSupportedCurrencies,
                    selected: _currency,
                    labelOf: currencyLabel,
                  );
                  if (picked != null) setState(() => _currency = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border.all(color: c.border, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currencyLabel(_currency),
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 15,
                            color: c.text,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(context.s.t('setup.thanks_label')),
              TextField(
                controller: _thanksController,
                maxLength: 200,
                maxLines: 2,
                minLines: 1,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.s.t('setup.thanks_help'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${_thanksController.text.characters.length}/200',
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => openExternal(kApiKeysDashboardUrl),
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: c.textSecondary,
            ),
            label: Text(context.s.t('setup.edit_key_permissions')),
          ),
        ],
        const SizedBox(height: 20),
        LtPrimaryButton(
          label: context.s.t('setup.create_button'),
          busy: _busy,
          onPressed: _create,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final c = context.lt;
    final jar = _created!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.successContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 34, color: c.success),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.s.t('setup.success_title'),
          textAlign: TextAlign.center,
          style: outfitStyle(26, c.text, weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          context.s.t('setup.success_body'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 14,
            height: 1.5,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        LtCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              QrBlock(data: jar.url, size: 180),
              const SizedBox(height: 16),
              _LinkPill(url: jar.url),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SoftAction(
                icon: Icons.ios_share_rounded,
                label: context.s.t('setup.share'),
                onTap: () =>
                    SharePlus.instance.share(ShareParams(text: jar.url)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SoftAction(
                icon: Icons.print_rounded,
                label: context.s.t('setup.poster'),
                onTap: () => _finish(thenOpen: ShellTab.poster),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SoftAction(
                icon: Icons.theater_comedy_rounded,
                label: context.s.t('setup.stage'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StagePreviewScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        LtPrimaryButton(
          label: widget.recreate
              ? context.s.t('setup.done')
              : context.s.t('setup.go_home'),
          onPressed: _finish,
        ),
      ],
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

class _LinkPill extends StatelessWidget {
  const _LinkPill({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => copyTipLink(context, url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                url.replaceFirst(RegExp('^https?://'), ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.content_copy_rounded, size: 16, color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _SoftAction extends StatelessWidget {
  const _SoftAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.accentSoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: c.onAccentSoft),
              const SizedBox(width: 6),
              Text(label, style: outfitStyle(13.5, c.onAccentSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
