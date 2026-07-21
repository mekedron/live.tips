import 'package:flutter/material.dart';

import '../../core/fullscreen.dart';
import '../../core/install_prompt.dart';
import '../../core/push_support.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/install_steps.dart';
import '../../widgets/lt_ui.dart';

/// THE first stop of onboarding on a phone or tablet browser — before the
/// account question, before any band setup: recommend installing live.tips to
/// the Home Screen.
///
/// It comes first because everything after it costs something to redo. Signing
/// in inside the browser and installing afterwards can land the artist in a
/// separate store, so the nudge has to arrive while there is still nothing to
/// carry over — the moment they tap "Get started", not three screens deep.
///
/// Three reasons, then the steps, and all of it on one screenful. Onboarding is
/// met once, in a hurry, often before a gig, so every row is a feature's own
/// name in bold — "Push notifications", "Fullscreen mode" — and at most one
/// short line under it. Copy that reads beautifully ("the stage your audience
/// should see") is a wall of text to someone who is not reading; the noun they
/// would search for is not.
///
/// Notifications lead because they are the one thing that is not a preference:
/// on iPhone and iPad an uninstalled live.tips cannot send one AT ALL
/// ([pushNeedsPwaInstall] — Safari hands web push only to Home Screen apps), and
/// a notification is how an artist learns a tip landed with their hands on the
/// strings.
///
/// The way out is a quiet text link at the BOTTOM OF THE SCROLL, not a button
/// pinned above it: this is advisory but strongly advised, and pinning "leave"
/// on screen while the steps are still below the fold offers the exit before the
/// instruction. Scrolling past everything is the price of skipping.
///
/// The steps come from the shared [installSteps] list, so they stay in lockstep
/// with the stage's fullscreen hint. Shown only where [shouldSuggestInstall] is
/// true (gated by [withInstallHint]), never on desktop.
class InstallHintScreen extends StatelessWidget {
  const InstallHintScreen({super.key, required this.next});

  /// The onboarding screen this nudge stands in front of — the account question
  /// when cloud accounts are on offer, the band details otherwise. A builder so
  /// the caller's branch stays where the caller can read it, and nothing is
  /// constructed for an artist who leaves to install instead.
  final Widget Function() next;

  /// The nudge is advisory, but skipping it has real costs — confirm once and
  /// spell them out before going on inside the browser. [noFullscreen] is the
  /// iPhone case, where the stage can't go full-screen at all; elsewhere the
  /// toggle still works, so we only warn about the lingering browser chrome.
  Future<void> _continueInBrowser(
    BuildContext context,
    bool noFullscreen,
  ) async {
    final navigator = Navigator.of(context);
    final firstLine = noFullscreen
        ? context.s.t('onboarding.install_hint.no_fullscreen_warning')
        : context.s.t('onboarding.install_hint.browser_chrome_warning');
    // The second cost, and the quiet one: a Home Screen app installed later can
    // come up on a separate store from the browser's, so a profile set up here
    // may simply not be there. (The line no longer claims "there's no server" —
    // a cloud account has one, and this screen now runs BEFORE that choice is
    // made, so it cannot know which kind of artist it is talking to.)
    final message = context.s.t('onboarding.install_hint.continue_body', {
      'first': firstLine,
    });
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.s.t('onboarding.install_hint.continue_dialog_title'),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.t('onboarding.install_hint.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.s.t('onboarding.install_hint.continue_anyway')),
          ),
        ],
      ),
    );
    if (proceed == true) {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => next()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final apple = installGuideIsApple;
    // iPhone Safari has no Fullscreen API; on iPad/Android the toggle works.
    final noFullscreen = !fullscreenSupported;
    // Not the same question as [apple], even if today's answers agree: this one
    // is "can this browser be pushed to at all", and it is what turns the first
    // reason from a nicety into the only way.
    final noPush = pushNeedsPwaInstall;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            // One scroller, everything inside it — including the way out. The
            // skip used to sit pinned below the scroll area, which put "leave"
            // permanently on screen while the steps it lets you skip were still
            // below the fold. Now it is the last thing in the column: on a short
            // screen the artist scrolls past the whole instruction to reach it.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.s.t('onboarding.install_hint.title'),
                    textAlign: TextAlign.center,
                    style: outfitStyle(21, c.text, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  // Reason one carries the whole argument on iPhone, so it gets
                  // the tinted row, the filled badge and — where push is
                  // impossible — the kicker that says so outright. The title is
                  // the literal feature name: a bell glyph says nothing, and
                  // neither does a sentence that never contains the words "push
                  // notifications".
                  _Reason(
                    icon: Icons.notifications_active_rounded,
                    title: context.s.t(
                      'onboarding.install_hint.why_push_title',
                    ),
                    body: noPush
                        ? context.s.t('onboarding.install_hint.why_push_apple')
                        : context.s.t(
                            'onboarding.install_hint.why_push_generic',
                          ),
                    badge: noPush
                        ? context.s.t('onboarding.install_hint.why_push_badge')
                        : null,
                    emphasized: true,
                  ),
                  const SizedBox(height: 8),
                  // One line for every platform. It used to split on
                  // [noFullscreen] to add "only works installed" — which the
                  // kicker above already says, on the one platform where it is
                  // true. Saying it twice on one screen is noise.
                  _Reason(
                    icon: Icons.fullscreen_rounded,
                    title: context.s.t(
                      'onboarding.install_hint.why_stage_title',
                    ),
                    body: context.s.t('onboarding.install_hint.why_stage_body'),
                  ),
                  const SizedBox(height: 8),
                  _Reason(
                    icon: Icons.bolt_rounded,
                    title: context.s.t(
                      'onboarding.install_hint.why_ready_title',
                    ),
                    body: context.s.t('onboarding.install_hint.why_ready_body'),
                  ),
                  const SizedBox(height: 18),
                  LtSectionLabel(context.s.t('onboarding.install_hint.how_to')),
                  const SizedBox(height: 8),
                  LtCard(
                    padding: const EdgeInsets.all(14),
                    radius: 16,
                    child: InstallStepList(
                      steps: installSteps(context, apple: apple),
                      numberBg: c.accentSoft,
                      numberFg: c.onAccentSoft,
                      iconColor: c.textSecondary,
                      textColor: c.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Deliberately the faintest thing on the screen — a way
                  // out for the artist who has already decided, not an
                  // option offered alongside the steps above.
                  TextButton(
                    onPressed: () => _continueInBrowser(context, noFullscreen),
                    style: TextButton.styleFrom(foregroundColor: c.textMuted),
                    child: Text(
                      context.s.t('onboarding.install_hint.skip'),
                      style: const TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One reason to install: glyph, headline, and the sentence that makes the case.
///
/// [emphasized] tints the whole row — reserved for the notifications reason,
/// which on iPhone is not a benefit but a precondition. [badge] is the kicker
/// that says so outright ("ONLY WORKS INSTALLED"), and is omitted where the
/// browser can push on its own, because there the claim would be false.
class _Reason extends StatelessWidget {
  const _Reason({
    required this.icon,
    required this.title,
    required this.body,
    this.badge,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? badge;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: emphasized ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emphasized ? c.accent : c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: emphasized ? c.onAccent : c.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  LtSectionLabel(badge!, color: c.accent),
                  const SizedBox(height: 3),
                ],
                Text(title, style: outfitStyle(15, c.text)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13,
                    height: 1.35,
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
