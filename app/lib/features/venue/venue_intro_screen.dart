import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lt_ui.dart';
import 'venue_setup_progress.dart';
import 'venue_sign_in_screen.dart';

/// Step 1 of 2 of venue setup: what a shared device is, how artists get on
/// it, and how they leave.
///
/// It EXPLAINS, and writes nothing. The Welcome link used to write the kind
/// on the tap and push this screen to explain what it had already done —
/// which made this screen's Back arrow a lie: it popped not to Welcome but
/// into the venue sign-in door, and the only way back was the wipe (#42).
/// The commit belongs at the END of the flow — and the end moved once more.
/// It used to be this screen's Continue, which chose the kind and dropped
/// the whole route stack onto the venue front door: a world-swap with no
/// Back and a destructive wipe as the only exit, sprung on a person still
/// mid-setup with no code in hand. Now Continue simply pushes the next step
/// ([VenueSignInScreen] in setup mode), where the code is entered — and the
/// kind is chosen THERE, by the successfully collected token, at the moment
/// the setup can actually finish. Back works on every step until then,
/// because until then nothing has been written: the device is still
/// unchosen and Welcome is still the root.
class VenueIntroScreen extends StatelessWidget {
  const VenueIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('venue.intro.title')),
        actions: const [VenueSetupProgress(step: 1, pillOnly: true)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const VenueSetupProgress(step: 1),
              const SizedBox(height: 16),
              Text(
                s.t('venue.intro.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _Point(
                icon: Icons.phone_iphone_rounded,
                text: s.t('venue.intro.point_phone'),
              ),
              _Point(
                icon: Icons.timer_outlined,
                text: s.t('venue.intro.point_ceiling'),
              ),
              _Point(
                icon: Icons.logout_rounded,
                text: s.t('venue.intro.point_leave'),
              ),
              const SizedBox(height: 8),
              LtCard(
                radius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 22, color: c.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.t('venue.intro.warning'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: s.t('venue.intro.continue'),
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VenueSignInScreen(setup: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
