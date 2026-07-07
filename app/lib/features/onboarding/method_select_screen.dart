import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/tip_method.dart';
import '../../state/onboarding_draft.dart';
import '../../widgets/lt_ui.dart';
import 'connect_screen.dart';
import 'relay_setup_screen.dart';

/// First onboarding step: pick how tips reach you. Nothing is preselected;
/// Stripe is recommended, and Revolut/MobilePay ride through the live.tips
/// relay and come with an honest warning about what "unverified" means.
class MethodSelectScreen extends ConsumerStatefulWidget {
  const MethodSelectScreen({super.key});

  @override
  ConsumerState<MethodSelectScreen> createState() =>
      _MethodSelectScreenState();
}

class _MethodSelectScreenState extends ConsumerState<MethodSelectScreen> {
  final Set<TipMethod> _selected = {};

  void _toggle(TipMethod method) {
    setState(() {
      if (!_selected.remove(method)) _selected.add(method);
    });
  }

  void _continue() {
    if (_selected.isEmpty) return;
    ref
        .read(onboardingDraftProvider.notifier)
        .set(OnboardingDraft(methods: Set.unmodifiable({..._selected})));
    final Widget next = _selected.contains(TipMethod.stripe)
        ? const ConnectScreen()
        : const RelaySetupScreen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final nonStripe = _selected.contains(TipMethod.revolut) ||
        _selected.contains(TipMethod.mobilepay);
    // The pill previews the flow length for the current selection.
    final draftPreview = OnboardingDraft(methods: _selected);
    final total = _selected.isEmpty ? 3 : draftPreview.totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get tipped'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: LtPill(label: 'Step 1 of $total')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              LtProgressSegments(total: total, filled: 1),
              const SizedBox(height: 16),
              Text('How do you want to get tipped?',
                  style: outfitStyle(22, c.text, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Pick everything you use — fans get one QR either way.',
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _MethodCard(
                method: TipMethod.stripe,
                selected: _selected.contains(TipMethod.stripe),
                dominant: true,
                title: 'Stripe',
                pill: 'Recommended',
                subtitle: 'Card, Apple Pay, Google Pay — verified payments '
                    'straight to your own Stripe account.',
                onTap: () => _toggle(TipMethod.stripe),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                method: TipMethod.revolut,
                selected: _selected.contains(TipMethod.revolut),
                title: 'Revolut',
                subtitle: 'Fans pay you in the Revolut app. Unverified — '
                    'see the note below.',
                onTap: () => _toggle(TipMethod.revolut),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                method: TipMethod.mobilepay,
                selected: _selected.contains(TipMethod.mobilepay),
                title: 'MobilePay',
                subtitle: 'Fans pay into your MobilePay Box. Unverified — '
                    'see the note below.',
                onTap: () => _toggle(TipMethod.mobilepay),
              ),
              if (nonStripe) ...[
                const SizedBox(height: 16),
                _RelayWarningCard(
                    stripeDropped: !_selected.contains(TipMethod.stripe)),
              ],
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _selected.isEmpty ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable method card. The Stripe card is [dominant]: bigger type
/// and a "Recommended" pill; every card gets the accent border + check when
/// selected.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pill,
    this.dominant = false,
  });

  final TipMethod method;
  final bool selected;
  final String title;
  final String subtitle;
  final String? pill;
  final bool dominant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dominant ? 20 : 16),
        side: BorderSide(
          color: selected ? c.accent : c.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(dominant ? 18 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: dominant ? 44 : 40,
                height: dominant ? 44 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: selected ? c.accentSoft : c.chip,
                    shape: BoxShape.circle),
                child: Icon(method.icon,
                    size: dominant ? 23 : 21,
                    color: selected ? c.accent : c.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: outfitStyle(dominant ? 17 : 15, c.text,
                                weight: FontWeight.w700)),
                        if (pill != null) ...[
                          const SizedBox(width: 8),
                          LtPill(label: pill!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 24,
                color: selected ? c.accent : c.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The honest amber note shown whenever Revolut/MobilePay is in the mix —
/// same container language as the recreate warning in jar_setup_screen.dart,
/// tinted gold instead of danger.
class _RelayWarningCard extends StatelessWidget {
  const _RelayWarningCard({required this.stripeDropped});

  /// Stripe was deselected: append the stronger "keep Stripe" plea.
  final bool stripeDropped;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final bodyStyle = TextStyle(
        fontFamily: kFontBody, fontSize: 13, height: 1.45, color: c.text);

    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: bodyStyle),
              Expanded(child: Text(text, style: bodyStyle)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: c.text),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Before you add Revolut or MobilePay',
                    style: outfitStyle(14, c.text, weight: FontWeight.w700)),
              ),
            ],
          ),
          bullet('Tips can\'t be verified. A tip shows up the moment a fan '
              'submits the form — whether or not they finish paying.'),
          bullet('Your QR points to a page on live.tips and tips reach your '
              'screen through the live.tips server. Stripe-only setups talk '
              'to no server at all.'),
          bullet('Your history stays on this device either way — live.tips '
              'stores nothing.'),
          if (stripeDropped) ...[
            const SizedBox(height: 8),
            Text(
              'Without Stripe there\'s no payment record anywhere except '
              'this device. We strongly recommend keeping Stripe — it\'s '
              'also the only method every fan can use.',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
