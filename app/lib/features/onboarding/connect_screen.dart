import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/external_link.dart';

import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../domain/tip_method.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../shell/app_shell.dart' show kRailBreakpoint;
import 'key_guide_screen.dart';
import 'onboarding_flow.dart';

/// Bring-your-own-key onboarding: the artist creates a *restricted* key in
/// their own dashboard, pastes it here, and we verify every permission
/// before letting them through. Step number comes from the onboarding draft
/// (falls back to 1 of 2 when opened standalone, e.g. from Settings).
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
    if (key.isEmpty) return context.s.t('onboarding.connect.key_empty');
    if (key.startsWith('pk_')) {
      return context.s.t('onboarding.connect.key_publishable');
    }
    if (key.startsWith('sk_live_')) {
      return context.s.t('onboarding.connect.key_secret');
    }
    if (!key.startsWith('rk_') && !key.startsWith('sk_test_')) {
      return context.s.t('onboarding.connect.key_unrecognized');
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
        // Build the tip link right here — reusing the details from step 1 —
        // and move on. No jar-setup page, no QR: onboarding just advances to
        // the next method (or the final QR screen).
        final draft = ref.read(onboardingDraftProvider);
        final app = ref.read(appStateProvider);
        final jar = await StripeRequests(client).createTipJar(
          currency: draft?.currency ?? app.currency,
          displayName: (draft?.name.trim().isNotEmpty ?? false)
              ? draft!.name.trim()
              : (app.displayName.isEmpty
                    ? context.s.t('onboarding.connect.default_display_name')
                    : app.displayName),
          thankYouMessage: (draft?.thankYouMessage.trim().isNotEmpty ?? false)
              ? draft!.thankYouMessage.trim()
              : context.s.t('onboarding.connect.default_thanks'),
        );
        await ref.read(appStateProvider.notifier).connect(key);
        await ref.read(appStateProvider.notifier).setTipJar(jar);
        if (!mounted) return;
        pushOnboardingStep(context, ref, after: TipMethod.stripe);
      } else {
        setState(() {
          _error = context.s.t('onboarding.connect.permissions_missing');
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
                  context.s.t('onboarding.connect.key_permissions_title'),
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

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final key = _keyController.text.trim();
    final isTest = key.startsWith('rk_test_') || key.startsWith('sk_test_');
    // On phones the permissions live behind a "?" so the paste field isn't
    // buried below the fold; wide layouts keep the full card visible.
    final wide = MediaQuery.sizeOf(context).width >= kRailBreakpoint;
    // Step numbering follows the onboarding draft (Stripe is a per-method
    // step) plus any account steps walked before it; standalone opens fall
    // back to a sensible count.
    final draft = ref.watch(onboardingDraftProvider);
    final prelude = ref.watch(onboardingPreludeProvider);
    final step = prelude + (draft?.stepOfMethod(TipMethod.stripe) ?? 3);
    final total = prelude + (draft?.totalSteps ?? 3);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.t('onboarding.connect.title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: LtPill(
                label: context.s.t('onboarding.connect.step_pill', {
                  'step': step,
                  'total': total,
                }),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              LtProgressSegments(total: total, filled: step),
              const SizedBox(height: 16),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.s.t('onboarding.connect.create_key_heading'),
                      style: outfitStyle(16, c.text, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.s.t('onboarding.connect.create_key_subtitle'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NumberedLine(1, context.s.t('onboarding.connect.step1')),
                    const SizedBox(height: 10),
                    _NumberedLine(2, context.s.t('onboarding.connect.step2')),
                    const SizedBox(height: 10),
                    _NumberedLine(3, context.s.t('onboarding.connect.step3')),
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
                              context.s.t('onboarding.connect.open_form'),
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
                              'onboarding.connect.key_permissions_title',
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
                            context.s.t('onboarding.connect.guide_button'),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              showFullscreenQr(context, kCreateKeyUrl),
                          child: Text(
                            context.s.t('onboarding.connect.qr_button'),
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
                        context.s.t('onboarding.connect.key_permissions_title'),
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
                      context.s.t('onboarding.connect.paste_heading'),
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
                        errorText: _error,
                        errorMaxLines: 4,
                        suffixIcon: IconButton(
                          tooltip: context.s.t(
                            'onboarding.connect.paste_tooltip',
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
                      onSubmitted: (_) => _verifyAndConnect(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.s.t('onboarding.connect.paste_help'),
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
                            'onboarding.connect.test_key_pill',
                          ),
                          icon: Icons.science_rounded,
                          soft: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Buttons live below the card — matching the Revolut / MobilePay
              // steps — so the layout reads the same across every method.
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: context.s.t('onboarding.connect.verify_button'),
                busy: _busy,
                onPressed: _verifyAndConnect,
              ),
              const SizedBox(height: 6),
              // Easy out if Stripe was a mis-tap on the method picker.
              TextButton(
                onPressed: _busy
                    ? null
                    : () => pushOnboardingStep(
                        context,
                        ref,
                        after: TipMethod.stripe,
                      ),
                child: Text(
                  context.s.t('onboarding.connect.skip'),
                  style: outfitStyle(14, c.textSecondary),
                ),
              ),
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
          context.s.t('onboarding.connect.permissions_caveat'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                if (check.detail != null)
                  Text(
                    check.detail!,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
