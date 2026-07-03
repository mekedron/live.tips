import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/stripe_onboarding.dart';

/// In-app version of docs/onboarding/create-restricted-key.md — the full
/// walkthrough with screenshots lives in the repository.
class KeyGuideScreen extends StatelessWidget {
  const KeyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create your restricted key')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Takes about two minutes. You only do this once.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shortcut: the button below opens the create-key '
                        'form with everything pre-selected — you just review '
                        'and click “Create key”. The steps that follow are '
                        'the manual path.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => launchUrl(
                          Uri.parse(kCreateKeyUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Open pre-filled key form'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _Step(
                number: 1,
                title: 'Sign in to your Stripe dashboard',
                body: 'On a laptop is easiest. Go to dashboard.stripe.com '
                    'and sign in to the account that should receive the tips.',
              ),
              const _Step(
                number: 2,
                title: 'Open API keys',
                body: 'Click “Developers” (bottom-left corner), then the '
                    '“API keys” tab. Or open '
                    'dashboard.stripe.com/apikeys directly.',
              ),
              const _Step(
                number: 3,
                title: 'Create a restricted key',
                body: 'Click “Create restricted key”. When Stripe asks how '
                    'you\'ll use it, choose “Providing this key to a '
                    'third-party application” and enter live.tips as the '
                    'name. Tick “Customize permissions for this key”.',
              ),
              const _Step(
                number: 4,
                title: 'Grant exactly these permissions',
                body: 'Leave every other permission on “None”:',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in kRequiredPermissions)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• ${p.resource}  →  ${p.access}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),
              const _Step(
                number: 5,
                title: 'Create & copy the key',
                body: 'Click “Create key”, then “Reveal key” and copy it. It '
                    'starts with rk_live_ (or rk_test_ in a sandbox). Paste '
                    'it into the app — AirDrop, a password manager, or a '
                    'synced clipboard gets it from laptop to tablet safely.',
              ),
              const _Step(
                number: 6,
                title: 'Good to know',
                body: '• The key is stored in this device\'s secure keychain '
                    'and is only ever sent to api.stripe.com.\n'
                    '• You can revoke it any time in the dashboard — the app '
                    'simply stops working until you connect a new one.\n'
                    '• To rehearse without real money, create the key inside '
                    'a Stripe sandbox and use test card 4242 4242 4242 4242.',
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => launchUrl(
                  Uri.parse(kApiKeysDashboardUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open dashboard.stripe.com/apikeys'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
