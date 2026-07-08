import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currencies.dart';
import '../../core/theme.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import 'method_select_screen.dart';

/// First onboarding step: the band's details — name, currency, and the
/// thank-you message fans see. Collected once, up front, so the later method
/// steps never re-ask; they reuse these when building the Stripe link and the
/// tip page.
class OnboardingDetailsScreen extends ConsumerStatefulWidget {
  const OnboardingDetailsScreen({super.key});

  @override
  ConsumerState<OnboardingDetailsScreen> createState() =>
      _OnboardingDetailsScreenState();
}

class _OnboardingDetailsScreenState
    extends ConsumerState<OnboardingDetailsScreen> {
  final _nameController = TextEditingController();
  final _thanksController = TextEditingController(
    text: 'Thank you for supporting live music! 🎶',
  );
  String _currency = 'eur';
  String? _error;

  @override
  void initState() {
    super.initState();
    // Coming back to this step (or re-adding a band) — prefill from the draft.
    final draft = ref.read(onboardingDraftProvider);
    if (draft != null) {
      if (draft.name.isNotEmpty) _nameController.text = draft.name;
      if (draft.thankYouMessage.isNotEmpty) {
        _thanksController.text = draft.thankYouMessage;
      }
      _currency = draft.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thanksController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Add your artist or band name — fans will see it.');
      return;
    }
    final thankYou = _thanksController.text.trim();
    // Preserve any methods already picked (back-navigation), just refresh the
    // details.
    final existing = ref.read(onboardingDraftProvider);
    ref.read(onboardingDraftProvider.notifier).set(
          (existing ?? const OnboardingDraft()).copyWith(
            name: name,
            currency: _currency,
            thankYouMessage: thankYou,
          ),
        );
    // The registry name is what the switcher and home show — set it now so a
    // half-finished band never reads "Unnamed band".
    await ref.read(appStateProvider.notifier).renameBand(name);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MethodSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: LtPill(label: 'Step 1')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Let\'s set up your tip jar',
                  style: outfitStyle(22, c.text, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Tell us who you are and how you want to be paid. You can '
                'change all of this later in Settings.',
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
                    const _FieldLabel('Artist or band name'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          hintText: 'The Midnight Foxes'),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Fans see this on your tip page, the stage and posters.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          color: c.textMuted),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Currency'),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showLtPicker<String>(
                          context: context,
                          title: 'Currency',
                          values: kSupportedCurrencies,
                          selected: _currency,
                          labelOf: currencyLabel,
                        );
                        if (picked != null) setState(() => _currency = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
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
                                    color: c.text),
                              ),
                            ),
                            Icon(Icons.expand_more_rounded,
                                size: 22, color: c.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Thank-you message'),
                    TextField(
                      controller: _thanksController,
                      maxLength: 200,
                      maxLines: 2,
                      minLines: 1,
                      buildCounter: (context,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Shown after a Stripe tip and on your tip page.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          color: c.textMuted),
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
                      color: c.danger),
                ),
              ],
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _continue,
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
