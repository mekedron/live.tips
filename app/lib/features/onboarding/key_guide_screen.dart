import 'package:flutter/material.dart';
import '../../core/external_link.dart';

import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../widgets/lt_ui.dart';

/// In-app version of docs/onboarding/create-restricted-key.md — the full
/// walkthrough with screenshots lives in the repository.
class KeyGuideScreen extends StatelessWidget {
  const KeyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create the key'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: LtPill(label: '~2 min', soft: false)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 22, color: c.onAccentSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shortcut: the pre-filled form selects everything '
                        'for you — review and click “Create key”.',
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.45,
                          color: c.onAccentSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: outfitStyle(12, Colors.white),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () =>
                          openExternal(kCreateKeyUrl, safari: true),
                      child: const Text('Open form'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _StepCard(
                number: 1,
                title: 'Sign in to your Stripe dashboard',
                body: 'On a laptop is easiest — dashboard.stripe.com, the '
                    'account that should receive the tips.',
              ),
              const SizedBox(height: 12),
              const _StepCard(
                number: 2,
                title: 'Open API keys',
                body: '“Developers” (bottom-left) → “API keys”, or '
                    'dashboard.stripe.com/apikeys directly.',
              ),
              const SizedBox(height: 12),
              const _StepCard(
                number: 3,
                title: 'Create a restricted key',
                body: '“Create restricted key” → “Providing this key to a '
                    'third-party application” → name it live.tips → '
                    '“Customize permissions”.',
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 4,
                title: 'Grant exactly these permissions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    for (final p in kRequiredPermissions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.resource,
                              style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                            Text(
                              p.access,
                              style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.access == 'Write'
                                    ? c.onAccentSoft
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Everything else stays “None”.',
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _StepCard(
                number: 5,
                title: 'Create, reveal & copy',
                body: 'Starts with rk_live_ (or rk_test_ in a sandbox). '
                    'AirDrop or a password manager gets it to the tablet '
                    'safely. Rehearse with test card 4242 4242 4242 4242.',
              ),
              const SizedBox(height: 12),
              const _StepCard(
                number: 6,
                title: 'Good to know',
                body: 'The key lives in this device\'s secure keychain and '
                    'is only ever sent to api.stripe.com. Revoke it any time '
                    'in the dashboard — the app simply stops working until '
                    'you connect a new one.',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    openExternal(kApiKeysDashboardUrl, safari: true),
                icon: Icon(Icons.open_in_new_rounded,
                    size: 18, color: c.textSecondary),
                label: const Text('Open dashboard.stripe.com/apikeys'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    this.body,
    this.child,
  });

  final int number;
  final String title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LtStepNumber(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: outfitStyle(14.5, c.text)),
                if (body != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    body!,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      height: 1.45,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                ?child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
