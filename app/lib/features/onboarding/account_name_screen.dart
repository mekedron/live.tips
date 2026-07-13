import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/onboarding_draft.dart';
import '../../widgets/lt_ui.dart';
import 'onboarding_flow.dart';

/// Names the ACCOUNT — not a profile. Shown right after a sign-in whose
/// provider handed over no display name (anonymous always, Apple/Google
/// sometimes). One field, prefilled if the provider knew anything, and
/// Continue with it empty simply skips naming.
///
/// [rename] is the same screen reached from Settings › Cloud account, which
/// is the "later" the sign-up step promises ("you can name the account later
/// in Settings"). It saves and pops instead of walking on into profile setup —
/// without it a guest account read "Guest" forever, and two of them were
/// indistinguishable.
class AccountNameScreen extends ConsumerStatefulWidget {
  const AccountNameScreen({super.key, this.rename = false});

  /// Standalone rename (Settings) rather than a step of onboarding.
  final bool rename;

  @override
  ConsumerState<AccountNameScreen> createState() => _AccountNameScreenState();
}

class _AccountNameScreenState extends ConsumerState<AccountNameScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // The name the account already answers to wins: the directory holds the
    // one chosen in the app, and only a provider name stands in for it. A
    // rename that opens on an empty field looks like the name is gone.
    final user = ref.read(authControllerProvider).user;
    final entry = ref
        .read(accountsDirectoryProvider)
        .accounts
        .where((a) => a.id == user?.uid)
        .firstOrNull;
    _nameController = TextEditingController(
      text: entry != null && entry.name.isNotEmpty
          ? entry.name
          : (user?.displayName ?? ''),
    );
    // As an onboarding step this counts in the indicator; the Settings
    // rename is the same screen but not a step of anything.
    if (!widget.rename) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(onboardingPreludeProvider.notifier).markNameStep();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.s.t('settings.account.renamed_snack');
    final name = _nameController.text.trim();
    // Empty = skip: the account stays unnamed (Settings falls back to the
    // email or provider label) and can be named later.
    if (name.isNotEmpty) {
      await ref.read(authControllerProvider.notifier).setAccountName(name);
    }
    if (!mounted) return;
    if (widget.rename) {
      navigator.pop();
      if (name.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(saved)));
      }
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final rename = widget.rename;
    // Step 2 of the run (after the account question). The prelude may not
    // have caught up with this screen on the first frame — count it as if
    // it had, so the pill never dips below what the previous screen showed.
    final prelude = ref.watch(onboardingPreludeProvider);
    final total = (prelude < 2 ? 2 : prelude) +
        (ref.watch(onboardingDraftProvider)?.totalSteps ?? 3);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.t(rename
            ? 'settings.account.rename_title'
            : 'onboarding.account_name.title')),
        actions: [
          if (!rename)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: LtPill(
                  label: context.s.t('onboarding.account_name.step_pill', {
                    'step': 2,
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
              if (!rename) ...[
                LtProgressSegments(total: total, filled: 2),
                const SizedBox(height: 16),
              ],
              Text(
                context.s.t(rename
                    ? 'settings.account.rename_heading'
                    : 'onboarding.account_name.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                context.s.t(rename
                    ? 'settings.account.rename_explain'
                    : 'onboarding.account_name.explain_profiles'),
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
                    if (!rename)
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
                label: context.s.t(rename
                    ? 'settings.account.rename_save'
                    : 'onboarding.account_name.continue'),
                trailingIcon:
                    rename ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
