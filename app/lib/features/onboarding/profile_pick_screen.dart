import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repository/account_data_repository.dart';
import '../../domain/band_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../settings/account_switch_screen.dart';
import 'onboarding_flow.dart';

/// The profile question of a cloud account, in its two forms — and the app
/// answers neither of them itself.
///
/// PUSHED (the default), it is the fork right after an onboarding sign-in:
/// does this account already have profiles? Signing in to an existing account
/// on a new device used to march straight into band creation — every
/// re-onboarding minted yet another profile. Now the existing profiles are
/// offered first, with "create a new one" as the explicit alternative.
///
/// The answer has to be WAITED for: the cloud mirror is silent until its
/// first snapshot, and an empty cold mirror says nothing about the profiles
/// (deciding "none" on it is exactly how junk profiles were minted). So this
/// screen holds a spinner until the repository is warm, then either forwards
/// itself to the band setup (a genuinely fresh account — no extra screen to
/// notice) or lists what the account already has. The spinner is bounded:
/// the sign-in just crossed the network, so a snapshot is close — and if it
/// still never lands, the deadline falls through to the band setup rather
/// than trapping onboarding.
///
/// [asRoot], it is RootGate's landing for a cloud account whose band question
/// is open — no navigation stack under it, nothing pushed on top:
///
/// * SEVERAL profiles and nobody has said which (a sign-in, an account
///   switch, a boot): the app used to pick one — the id this device last used,
///   else simply the first band — and drop the artist into somebody else's
///   gig. Here the list is the question. The last-used profile pre-selects a
///   row; a pre-selection is not an answer, and it never skips the tap.
/// * NO profile at all: the account genuinely has none, which is a state, not
///   an accident to repair. The create card is the only card, and no band doc
///   is written until the artist walks through the setup that names it.
///
/// The LOCAL profile with no bands left lands here too, on that same second
/// form — it is an empty profile set like any other, and the way out of one is
/// to make a profile. (It used to land on the account switcher, which is the
/// screen the artist had just tapped the local row on: a dead end with no door
/// to a profile at all — #38.) The copy is the one thing that differs: there is
/// no account for a device profile to have profiles "in".
///
/// As the root there is nothing to forward TO (a pushReplacement would bury
/// RootGate itself), so the deadline and the auto-forward are the pushed
/// form's alone — and there is a door out to the other accounts instead.
class ProfilePickScreen extends ConsumerStatefulWidget {
  const ProfilePickScreen({super.key, this.asRoot = false});

  /// RootGate's landing rather than a step pushed on top of onboarding.
  final bool asRoot;

  @override
  ConsumerState<ProfilePickScreen> createState() => _ProfilePickScreenState();
}

class _ProfilePickScreenState extends ConsumerState<ProfilePickScreen> {
  static const _deadline = Duration(seconds: 8);

  Timer? _timer;
  bool _forwarded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.asRoot) _timer = Timer(_deadline, _forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// On to the band setup — the account has nothing to offer (or the mirror
  /// never spoke). Replacement, not push: a fresh account's user never chose
  /// this screen, so Back must not return to its spinner.
  void _forward() {
    if (_forwarded || !mounted) return;
    // The deadline may fire in the same beat a snapshot lands — profiles
    // that exist always win over the fallback.
    final repo = ref.read(accountDataRepositoryProvider);
    if (repo.isWarm && repo.listBands().any((b) => _real(repo, b))) return;
    _forwarded = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  /// A profile that would be worth re-entering. The seeded first band of a
  /// fresh account is unnamed and empty — it must not read as "you already
  /// have a profile"; a real one has a name (onboarding requires it before
  /// any method saves) or, at minimum, a configured jar.
  bool _real(AccountDataRepository repo, BandAccount band) =>
      band.name.trim().isNotEmpty ||
      repo.readTipJar(band.id) != null ||
      repo.readRelayJar(band.id) != null;

  Future<void> _pick(BandAccount band) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final busy = context.s.t('widgets.band_switcher.switching');
    final ok =
        await ref.read(appStateProvider.notifier).switchAccount(band.id);
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(busy)));
      return;
    }
    // Entering an existing profile IS the end of onboarding: drop the whole
    // stack so RootGate shows the shell, and clear the step counter the way
    // the done screen does.
    ref.read(onboardingPreludeProvider.notifier).reset();
    navigator.popUntil((route) => route.isFirst);
  }

  /// The other door of the root form: an account with no profile the artist
  /// wants (or with none at all) is not a trap — the accounts this device
  /// knows, and a fresh sign-in, are one tap away.
  void _switchAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountSwitchScreen()),
    );
  }

  Future<void> _createNew() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final addFailed = context.s.t('widgets.profile_switcher.add_failed');
    // The band setup's details step renames the ACTIVE band — which right
    // now is one of the account's real profiles (or nothing at all). A new
    // empty one has to be created and activated first, exactly like the
    // switcher's "Add a profile" row. This tap is the artist asking for a
    // profile, which is the only thing that may ever write a band entry.
    final account = await ref.read(appStateProvider.notifier).addAccount();
    if (!mounted) return;
    if (account == null) {
      messenger.showSnackBar(SnackBar(content: Text(addFailed)));
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    // Every road to a warm mirror rebuilds this: the revision bump of a
    // landed snapshot, the repository swap of the sign-in's directory flip,
    // and the app-state reload that adopts the bands.
    ref.watch(repoRevisionProvider);
    final app = ref.watch(appStateProvider);
    final repo = ref.watch(accountDataRepositoryProvider);
    final asRoot = widget.asRoot;
    // As the root, the question is about the account's profiles as they ARE:
    // an unnamed, unfinished one is still a profile the artist can go back
    // into, and hiding it would leave the app asking about a list nobody can
    // see. The onboarding fork asks the narrower question — "is there
    // anything here worth re-entering?" — and ignores the placeholders.
    final existing = repo.isWarm
        ? [
            for (final band in repo.listBands())
              if (asRoot || _real(repo, band)) band,
          ]
        : null;

    if (!asRoot && existing != null && existing.isEmpty && !_forwarded) {
      // A warm answer with nothing in it — a genuinely fresh account walks
      // on to the band setup without ever seeing this screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _forward());
    }
    if (existing == null || (existing.isEmpty && !asRoot)) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('onboarding.profile_pick.title'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 14),
              Text(
                s.t('onboarding.profile_pick.loading'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    _timer?.cancel(); // the mirror spoke — the deadline has done its job
    // The band this device last had open in this account. It says which row
    // to mark, and nothing more: the app opening it unasked is the bug this
    // screen exists for.
    final lastUsed = repo.readActiveBandId();
    final empty = existing.isEmpty;
    // The device profile has no account behind it, so "no profile in this
    // account" would name a thing that does not exist. Same screen, same card,
    // honest heading.
    final local =
        ref.watch(accountsDirectoryProvider.select((d) => d.active.isLocal));
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('onboarding.profile_pick.title')),
        actions: [
          if (asRoot)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _switchAccount,
                child: Text(s.t('settings.account.switch_title')),
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
              Text(
                s.t(!empty
                    ? 'onboarding.profile_pick.heading'
                    : local
                        ? 'onboarding.profile_pick.empty_heading_local'
                        : 'onboarding.profile_pick.empty_heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                s.t(!empty
                    ? 'onboarding.profile_pick.subtitle'
                    : local
                        ? 'onboarding.profile_pick.empty_subtitle_local'
                        : 'onboarding.profile_pick.empty_subtitle'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              for (final band in existing) ...[
                _ProfileCard(
                  band: band,
                  enabled: !app.switching,
                  lastUsed: band.id == lastUsed,
                  onTap: () => unawaited(_pick(band)),
                ),
                const SizedBox(height: 12),
              ],
              _CreateNewCard(
                enabled: !app.switching,
                onTap: () => unawaited(_createNew()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One existing profile, styled like the switcher's rows but as an
/// onboarding card: avatar, name, which methods it already has — and, for the
/// one this device last used, a pill saying so. The pill is the whole extent
/// of "remembering": it points at a row, it does not open it.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.band,
    required this.enabled,
    required this.onTap,
    this.lastUsed = false,
  });

  final BandAccount band;
  final bool enabled;
  final VoidCallback onTap;
  final bool lastUsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final name = band.name.trim().isEmpty
        ? context.s.t('widgets.profile_switcher.unnamed')
        : band.name;
    return LtCard(
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              InitialAvatar(
                name: name,
                anonymous: band.name.trim().isEmpty,
                size: 40,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: outfitStyle(15, c.text,
                                weight: FontWeight.w600),
                          ),
                        ),
                        if (lastUsed) ...[
                          const SizedBox(width: 8),
                          LtPill(
                            label:
                                context.s.t('onboarding.profile_pick.last_used'),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      bandMethodsSummary(context, ref, band.id),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateNewCard extends StatelessWidget {
  const _CreateNewCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, size: 22, color: c.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.t('onboarding.profile_pick.create'),
                      style: outfitStyle(15, c.text, weight: FontWeight.w600),
                    ),
                    Text(
                      context.s.t('widgets.profile_switcher.add_subtitle'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
