import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../widgets/lt_ui.dart';
import 'onboarding_flow.dart';

/// Names the ACCOUNT — not a band. Shown right after a sign-in whose
/// provider handed over no display name (anonymous always, Apple/Google
/// sometimes). One field, prefilled if the provider knew anything, and
/// Continue with it empty simply skips naming.
class AccountNameScreen extends ConsumerStatefulWidget {
  const AccountNameScreen({super.key});

  @override
  ConsumerState<AccountNameScreen> createState() => _AccountNameScreenState();
}

class _AccountNameScreenState extends ConsumerState<AccountNameScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(authControllerProvider).user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();
    // Empty = skip: the account stays unnamed (the switcher falls back to
    // the email or provider label) and can be named later in Settings.
    if (name.isNotEmpty) {
      await ref.read(authControllerProvider.notifier).setAccountName(name);
    }
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(title: Text(context.s.t('onboarding.account_name.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                context.s.t('onboarding.account_name.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                context.s.t('onboarding.account_name.explain'),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        context.s.t('onboarding.account_name.label'),
                        style: outfitStyle(13, c.text),
                      ),
                    ),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: context.s.t('onboarding.account_name.hint'),
                      ),
                      onSubmitted: (_) => _continue(),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.s.t('onboarding.account_name.skip_hint'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: context.s.t('onboarding.account_name.continue'),
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
