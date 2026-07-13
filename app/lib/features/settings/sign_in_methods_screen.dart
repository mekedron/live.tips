import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/firebase/account_service.dart';
import '../../domain/app_account.dart';
import '../../domain/pending_redirect.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../account/delete_account.dart';

/// Sign-in methods — the door the app was missing (#32), and the way out (#33).
///
/// The linking machinery has always worked; its only entry point was the
/// dialog you get when you are SIGNING OUT, where it was offered as an
/// alternative to leaving. So the one control that makes a guest account safe
/// was reachable only by starting to abandon it, while Security kept telling
/// the artist to "link Apple or Google first". This is where they can.
///
/// Linking is an UPGRADE IN PLACE: same uid, same profiles, same history,
/// nothing migrated (see AuthService.signInWithGoogle's `link` flag, and
/// AuthController._startRedirect for the web's custom-token round trip). The
/// copy says so out loud, because "link" reads like "start over" to anyone an
/// app has burnt before.
///
/// Unlinking is allowed only while ANOTHER permanent method remains: taking
/// the last one off would turn the account back into a guest — no sign-in, no
/// kill switch, no recovery — and Firebase would do it without a murmur. The
/// refusal, and the explanation, are ours (AuthController.canUnlink).
///
/// And this is where the account ENDS. Deleting is irreversible, so the
/// confirmation is proportional: it names what goes AND what stays (the
/// artist's Stripe payments live in the artist's own Stripe account and are
/// not ours to touch), and it asks for the word to be typed.
class SignInMethodsScreen extends ConsumerStatefulWidget {
  const SignInMethodsScreen({super.key});

  @override
  ConsumerState<SignInMethodsScreen> createState() =>
      _SignInMethodsScreenState();
}

class _SignInMethodsScreenState extends ConsumerState<SignInMethodsScreen> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// The guest upgrade, and the second method for everyone else. On the web
  /// this leaves the page (the auth bridge) and comes back through
  /// RedirectSignInGate — which lands right back here, on Settings.
  Future<void> _link(AccountKind kind) async {
    final s = context.s;
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider.notifier);
    final user = switch (kind) {
      AccountKind.apple =>
        await auth.signInWithApple(link: true, origin: RedirectOrigin.settings),
      AccountKind.google => await auth.signInWithGoogle(
          link: true, origin: RedirectOrigin.settings),
      _ => null,
    };
    if (!mounted) return;
    setState(() => _busy = false);
    // On the web there is no user to return: the page is on its way to the
    // provider, and this screen is about to be torn down with it. Only a
    // reported error is a failure.
    if (user == null) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) _snack(s.t('settings.sign_in_methods.link_failed'));
      return;
    }
    _snack(s.t('settings.sign_in_methods.linked_snack', {
      'method': accountProviderLabel(context, kind),
    }));
  }

  Future<void> _unlink(AccountKind kind) async {
    final s = context.s;
    final method = accountProviderLabel(context, kind);
    final auth = ref.read(authControllerProvider.notifier);
    // The refusal that keeps an account recoverable — stated, never silently
    // disabled: the artist asked for something reasonable, and deserves the
    // reason it cannot happen.
    if (!auth.canUnlink(kind)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.t('settings.sign_in_methods.unlink_last_title')),
          content: Text(s.t('settings.sign_in_methods.unlink_last_body',
              {'method': method})),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.t('common.ok')),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(s.t('settings.sign_in_methods.unlink_title', {'method': method})),
        content: Text(s.t('settings.sign_in_methods.unlink_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('settings.sign_in_methods.unlink')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await auth.unlinkProvider(kind);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(ok
        ? s.t('settings.sign_in_methods.unlinked_snack', {'method': method})
        : s.t('settings.sign_in_methods.unlink_failed'));
  }

  /// The irreversible one. Type-to-confirm, and the dialog states what SURVIVES
  /// as well as what dies — a delete that quietly left the artist's Stripe
  /// payment history unmentioned would be lying by omission about the one thing
  /// we cannot touch.
  Future<void> _confirmDelete() async {
    final s = context.s;
    // An account flip like any other: refused mid-session, by the same guard
    // sign-out/switch/remove ask. Ending an artist's live set — permanently —
    // from a Settings tap is not an option.
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      _snack(block == AccountActionBlock.switching
          ? s.t('widgets.band_switcher.switching')
          : s.t('settings.sign_in_methods.stop_session_delete'));
      return;
    }
    final word = s.t('settings.sign_in_methods.delete_word');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(word: word),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    List<String> stranded;
    try {
      stranded = await runAccountDelete(ref);
    } on AccountCallError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // Never "deleted anyway": a refused or half-finished delete is an
      // account that still exists, and the server says so.
      _snack(e.kind == AccountCallErrorKind.unauthenticated
          ? s.t('settings.sign_in_methods.delete_stale')
          : s.t('settings.sign_in_methods.delete_failed'));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    // The one residue we could not clear, named rather than buried: an
    // endpoint on the artist's own Stripe account that a revoked key kept us
    // from deleting.
    _snack(stranded.isEmpty
        ? s.t('settings.sign_in_methods.deleted_snack')
        : s.t('settings.sign_in_methods.delete_stripe_leftover'));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final user = ref.watch(authControllerProvider).user;
    final busy = _busy || ref.watch(authControllerProvider).busy;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.sign_in_methods.title'))),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.t('settings.security.signed_out'),
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontFamily: kFontBody, color: c.textSecondary),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      s.t('settings.sign_in_methods.intro'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        height: 1.45,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // A guest account is one lost device from oblivion, and
                    // the app knows it. Say it here, where it can be fixed.
                    if (user.isGuest) ...[
                      LtCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 20, color: c.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.t('settings.sign_in_methods.guest_warning'),
                                style: TextStyle(
                                  fontFamily: kFontBody,
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    LtRowGroup(
                      header: s.t('settings.sign_in_methods.header'),
                      children: [
                        for (final kind
                            in const [AccountKind.apple, AccountKind.google])
                          _MethodRow(
                            kind: kind,
                            linked: user.providers.contains(kind),
                            busy: busy,
                            onLink: () => _link(kind),
                            onUnlink: () => _unlink(kind),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ------------------------------------ delete account ---
                    LtCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LtSectionLabel(
                              s.t('settings.sign_in_methods.delete_header')),
                          const SizedBox(height: 8),
                          Text(
                            s.t('settings.sign_in_methods.delete_body'),
                            style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 12.5,
                              height: 1.45,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LtDangerButton(
                            label:
                                s.t('settings.sign_in_methods.delete_button'),
                            icon: Icons.delete_forever_rounded,
                            busy: busy,
                            onPressed: busy ? null : _confirmDelete,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// One method: linked (with the way to take it off) or not (with the way to
/// put it on).
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.kind,
    required this.linked,
    required this.busy,
    required this.onLink,
    required this.onUnlink,
  });

  final AccountKind kind;
  final bool linked;
  final bool busy;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final method = accountProviderLabel(context, kind);
    return LtRow(
      icon: kind == AccountKind.apple
          ? Icons.apple
          : Icons.account_circle_outlined,
      iconColor: linked ? c.success : null,
      title: method,
      subtitle: s.t(linked
          ? 'settings.sign_in_methods.linked'
          : 'settings.sign_in_methods.not_linked'),
      trailing: TextButton(
        onPressed: busy ? null : (linked ? onUnlink : onLink),
        child: Text(
          s.t(linked
              ? 'settings.sign_in_methods.unlink'
              : 'settings.sign_in_methods.link'),
          // Named to the a11y tree: a bare "Link" tells a screen-reader user
          // nothing about WHICH identity they are about to attach.
          semanticsLabel: s.t(
            linked
                ? 'settings.sign_in_methods.unlink_named'
                : 'settings.sign_in_methods.link_named',
            {'method': method},
          ),
        ),
      ),
    );
  }
}

/// Type-to-confirm. The button stays dead until the word is typed exactly —
/// this is the one act with no undo anywhere behind it.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.word});

  final String word;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final armed = _controller.text.trim() == widget.word;
    return AlertDialog(
      title: Text(s.t('settings.sign_in_methods.delete_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('settings.sign_in_methods.delete_dialog_body')),
            const SizedBox(height: 16),
            Text(s.t('settings.sign_in_methods.delete_type_to_confirm',
                {'word': widget.word})),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autocorrect: false,
              decoration: InputDecoration(hintText: widget.word),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.t('common.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: armed ? () => Navigator.of(context).pop(true) : null,
          child: Text(s.t('settings.sign_in_methods.delete_confirm')),
        ),
      ],
    );
  }
}
