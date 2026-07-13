import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/venue_providers.dart';
import '../../widgets/lt_ui.dart';

/// The one explanatory step of venue onboarding: what a shared device is,
/// how artists get on it, and how they leave.
///
/// And it is where the device BECOMES one. The Welcome link used to write the
/// kind on the tap and push this screen to explain what it had already done —
/// which made this screen's Back arrow a lie: it popped not to Welcome but
/// into the venue sign-in door, and the only way back was the wipe (#42). The
/// commit belongs at the END of the flow: the artist chooses venue mode when
/// they confirm it, not when they ask what it is.
///
/// So Continue is the choice. It saves the kind (attaching the at-rest cipher
/// and turning off Firestore's disk cache — see [DeviceKindNotifier.choose]),
/// and only then drops the route stack, onto the venue sign-in screen the root
/// gate has just rebuilt into. Back writes nothing, because nothing has been
/// written: the device is still unchosen and Welcome is still the root.
class VenueIntroScreen extends ConsumerStatefulWidget {
  const VenueIntroScreen({super.key});

  @override
  ConsumerState<VenueIntroScreen> createState() => _VenueIntroScreenState();
}

class _VenueIntroScreenState extends ConsumerState<VenueIntroScreen> {
  bool _busy = false;

  /// The commit. A shared device without its at-rest cipher must not exist
  /// (see [DeviceKindNotifier._applyKind]), so a refused keychain leaves the
  /// kind unchosen — and now the snackbar that says so is shown on the screen
  /// the artist is actually standing on, with the choice still theirs.
  Future<void> _confirm() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final s = context.s;
    setState(() => _busy = true);
    try {
      await ref.read(deviceKindProvider.notifier).choose(DeviceKind.venue);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(s.t('venue.boot.choose_failed'))),
      );
      return;
    }
    if (!mounted) return;
    // The kind is saved — RootGate has rebuilt as VenueGate underneath, so
    // dropping the stack lands on the venue sign-in screen.
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('venue.intro.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
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
                busy: _busy,
                onPressed: _busy ? null : () => unawaited(_confirm()),
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
