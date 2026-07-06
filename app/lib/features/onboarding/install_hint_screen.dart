import 'package:flutter/material.dart';

import '../../core/fullscreen.dart';
import '../../core/install_prompt.dart';
import '../../core/theme.dart';
import '../../widgets/install_steps.dart';
import '../../widgets/lt_ui.dart';
import 'connect_screen.dart';

/// First stop of onboarding on a phone or tablet browser: recommend installing
/// live.tips to the Home Screen before connecting Stripe. iPhone Safari can't
/// show a web page full-screen at all, and everywhere else an installed PWA
/// still launches chrome-free and app-like — so we surface this once, up front.
///
/// Purely advisory: "Continue" carries straight on to [ConnectScreen] whether or
/// not they installed. The steps come from the shared [installSteps] list, so
/// they stay in lockstep with the stage's fullscreen hint. Shown only where
/// [shouldSuggestInstall] is true (gated by the caller), never on desktop.
class InstallHintScreen extends StatelessWidget {
  const InstallHintScreen({super.key});

  /// The nudge is advisory, but skipping it has real costs — confirm once and
  /// spell them out before connecting inside the browser. [noFullscreen] is the
  /// iPhone case, where the stage can't go full-screen at all; elsewhere the
  /// toggle still works, so we only warn about the lingering browser chrome.
  Future<void> _continueInBrowser(
      BuildContext context, bool noFullscreen) async {
    final navigator = Navigator.of(context);
    final firstLine = noFullscreen
        ? 'Without live.tips on your Home Screen, the stage can’t go '
            'full-screen — the browser’s bars stay on screen and moving around '
            'the app feels less smooth.'
        : 'In the browser the address bar and toolbars stay on screen and '
            'moving around the app feels less smooth.';
    // The clincher: there's no server. History lives in this browser's storage,
    // and a Home-Screen app installed later can start from a separate store —
    // so sessions collected in the browser first may not follow it over.
    final message = '$firstLine\n\n'
        'Your session history is saved on this device only — there’s no '
        'server — and an app added later can start from a separate store, so '
        'sessions you collect in the browser first may not carry over. Adding '
        'it now keeps everything in one place.';
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue in the browser?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue anyway'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const ConnectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final apple = installGuideIsApple;
    // iPhone Safari has no Fullscreen API; on iPad/Android the toggle works.
    final noFullscreen = !fullscreenSupported;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.add_to_home_screen_rounded,
                                size: 34, color: c.accent),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Add live.tips to your Home Screen',
                          textAlign: TextAlign.center,
                          style:
                              outfitStyle(24, c.text, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          apple
                              ? 'Safari can’t show live.tips full-screen on '
                                  'iPhone or iPad. Add it to your Home Screen '
                                  'and it launches edge-to-edge, with no browser '
                                  'bars — the clean stage your audience should '
                                  'see. Takes a few seconds.'
                              : 'Add live.tips to your Home Screen and it '
                                  'launches like an app — full-screen, no '
                                  'browser bars, and one tap away when you’re '
                                  'ready to go live. Takes a few seconds.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 14.5,
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        LtCard(
                          child: InstallStepList(
                            steps: installSteps(apple: apple),
                            numberBg: c.accentSoft,
                            numberFg: c.onAccentSoft,
                            iconColor: c.textSecondary,
                            textColor: c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                  child: Column(
                    children: [
                      LtPrimaryButton(
                        label: 'Continue',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () =>
                            _continueInBrowser(context, noFullscreen),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You can always do this later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12.5,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
