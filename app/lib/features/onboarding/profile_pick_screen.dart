import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repository/account_data_repository.dart';
import '../../domain/app_account.dart';
import '../../domain/band_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/root_world.dart';
import '../../state/venue_providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/profile_switcher.dart';
import '../settings/settings_screen.dart';
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
/// screen holds a spinner until it has an ANSWER — a warm mirror, or the bands
/// the app is already holding ([_known]) — then either forwards itself to the
/// band setup (a genuinely fresh account — no extra screen to notice) or lists
/// what the account already has. The spinner is bounded, and bounded EVERY time
/// it comes up ([_arm]): the sign-in just crossed the network, so a snapshot is
/// close — and if it still never lands, the deadline falls through to the band
/// setup rather than trapping onboarding.
///
/// [asRoot], it is RootGate's landing for a cloud account whose band question
/// is open — no navigation stack under it, nothing pushed on top:
///
/// * SEVERAL profiles and nobody has said which: no band remembered as open
///   on this device (a fresh sign-in, a sign-out's landing, a memory whose
///   band was deleted elsewhere) — or a venue tablet, which remembers but
///   never answers. On the artist's own device the remembered band opens
///   without this screen: that memory IS the artist's answer, given last
///   time, and re-asking it on every open was a toll booth. What the app
///   still never does is GUESS — "the first band" dropped the artist into
///   somebody else's gig (#28). Here the list is the question; the last-used
///   profile at most pre-selects a row.
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
/// form's alone — and there are doors instead. It needs them: every other root
/// is the shell, where the switcher, Settings, sign-out, the account section
/// and the device kind are one tap away, and this one has no tab bar to hang
/// any of that on. An artist whose profile set is empty used to land here with
/// two affordances — create a profile, or switch to an account that might be
/// just as empty — and no Settings on the device at all: no sign-out, no way to
/// change what the device is, no way back to onboarding (#40). So the root form
/// carries its own chrome: THE switcher (a sheet, over this screen), and
/// Settings (a route, pushed over a root that is not moving).
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// A deadline for as long as this screen is WAITING — re-armed every time it
  /// goes back to waiting, and cancelled the moment it has an answer.
  ///
  /// It used to be armed ONCE, in initState, and cancelled in [build] the first
  /// time the mirror spoke. A screen that went back to its spinner afterwards
  /// had no deadline left at all — and going back to the spinner is exactly
  /// what a repository rebuilt COLD does to it (see [_known]). No deadline, and
  /// no snapshot coming either (the new repository's listener is its own): the
  /// spinner span until the artist reloaded the page. That was the sign-in that
  /// never completed (#54).
  void _arm() {
    if (widget.asRoot || _forwarded) return;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(_deadline, _forward);
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
  }

  /// The profiles this screen can vouch for — or NULL while it has no answer
  /// from anywhere, which is the only thing that means "wait".
  ///
  /// The repository is the source, and a cold cloud mirror is SILENT: it says
  /// nothing about the account's profiles, and deciding "none" on it is how
  /// junk profiles got minted. That rule stands — the fallback below may only
  /// ever ADD profiles that are known to exist, never conclude that there are
  /// none. A cache proves what exists; it never proves what is absent.
  ///
  /// But a repository that is cold is not the same thing as an account nobody
  /// knows anything about. [accountDataRepositoryProvider] builds a BRAND-NEW,
  /// cold [FirestoreRepository] every time the session/auth/directory graph
  /// moves under it — which is routinely, in the beats right after the sign-in
  /// that lands the artist here — and the bands the app is already holding
  /// ([AppState.accounts]) do not stop existing because the object that read
  /// them was replaced. They are the very bands RootGate routed here ON.
  ///
  /// So: the warm mirror answers when there is one, and the app's own bands
  /// answer when there is not. Waiting on the WARMTH OF AN OBJECT rather than
  /// on the ANSWER was the bug — the object can go cold again, and the answer
  /// cannot.
  List<BandAccount>? _known(AccountDataRepository repo, AppState app) {
    if (repo.isWarm) return repo.listBands();
    return app.accounts.isNotEmpty ? app.accounts : null;
  }

  /// On to the band setup — the account has nothing to offer (or the mirror
  /// never spoke). Replacement, not push: a fresh account's user never chose
  /// this screen, so Back must not return to its spinner.
  void _forward() {
    if (_forwarded || !mounted) return;
    // The deadline may fire in the same beat a snapshot lands — profiles
    // that exist always win over the fallback.
    final repo = ref.read(accountDataRepositoryProvider);
    final known = _known(repo, ref.read(appStateProvider));
    if (known != null && known.any((b) => _real(repo, b))) return;
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

  /// The same act the switcher performs, through the same code path — the
  /// guard, the refusal's sentence and the discard rule are written once
  /// ([switchTo]), not once per surface.
  Future<void> _pick(BandAccount band) async {
    final navigator = Navigator.of(context);
    final account = ref.read(accountsDirectoryProvider).active;
    if (!await switchTo(context, ref, account: account, band: band)) return;
    if (!mounted) return;
    // Entering an existing profile IS the end of onboarding: drop the whole
    // stack so RootGate shows the shell.
    navigator.popUntil((route) => route.isFirst);
  }

  /// The other door of the root form, and it opens what its label says (#49):
  /// this screen IS the profile question of the account in use, so the only
  /// switcher that has anything to offer an artist standing on it is the
  /// ACCOUNT one — every account this device knows, the local mode, and a fresh
  /// sign-in. (It used to open the profile sheet, under the words "Switch
  /// account", and there was no account picker in the app at all.)
  ///
  /// A sheet, so this screen is still standing under it when the artist changes
  /// their mind (and so the flip cannot land on a rebuild of the very route it
  /// was tapped on — #38).
  void _switchAccount() => unawaited(showAccountSheet(context, ref));

  /// And the door the shell has always had, which this root did not: Settings.
  /// Sign out, the sign-in methods, delete account, what this device is, the
  /// demo — every exit from a state lives in there, and a root with no tab bar
  /// used to reach none of them (#40). A pushed route over a root that is not
  /// moving: its Back arrow comes back here, which is where the artist is.
  ///
  /// [RootBoundRoute], because the root under it CAN move — and the doors that
  /// move it are the ones behind this very screen. A sign-out taken in there
  /// rebuilt the root into Welcome and left Settings standing on top of it,
  /// re-rendered against the local profile, offering to delete a profile the
  /// artist had never opened (#48). The route describes this world; when the
  /// world goes, it goes.
  void _settings() => unawaited(Navigator.of(context).push(
        RootBoundRoute(builder: (_) => const SettingsRouteScreen()),
      ));

  /// "Add a profile" by another name — the same call, the same rule: the tap
  /// opens the form, and the form's own Save is what writes the profile, out of
  /// the name typed into it. Abandoning it leaves this screen exactly as it was
  /// and nothing behind it (#44).
  Future<void> _createNew() async {
    final navigator = Navigator.of(context);
    if (!await addProfile(context, ref)) return;
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => firstBandSetupScreen(createsProfile: true),
      ),
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
    final known = _known(repo, app);
    final existing = known == null
        ? null
        : [
            for (final band in known)
              if (asRoot || _real(repo, band)) band,
          ];

    if (!asRoot && existing != null && existing.isEmpty && !_forwarded) {
      // A warm answer with nothing in it — a genuinely fresh account walks
      // on to the band setup without ever seeing this screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _forward());
    }
    if (existing == null || (existing.isEmpty && !asRoot)) {
      // Still waiting: a deadline runs for as long as that is true, however
      // many times the answer is taken away again.
      _arm();
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

    _disarm(); // there is an answer on the screen — nothing left to wait for
    // The band this device last had open in this account. When this screen
    // shows at all the memory did not answer (it names nothing, or the
    // device is a venue tablet that never lets it) — so here it only says
    // which row to mark.
    final lastUsed = repo.readActiveBandId();
    final empty = existing.isEmpty;
    // WHOSE profiles this screen is asking about. It used to keep one bit of
    // this — isLocal, for the heading — and throw the account itself away, so
    // the screen said "this account" three times and never named it: no name,
    // no email, no provider, nothing to tell an artist with two accounts which
    // one tonight's QR would be created under (#51).
    final account = ref.watch(accountsDirectoryProvider).active;
    // The device profile has no account behind it, so "no profile in this
    // account" would name a thing that does not exist. Same screen, same card,
    // honest heading — and an identity line that says "On this device" rather
    // than inventing an account for it to be in.
    final local = account.isLocal;
    // A venue tablet has no account door at all: accounts are entered and left
    // through the banner's approve-and-wipe ceremony, and the switcher hides
    // its account half there anyway — so an action that says "Switch account"
    // on a public device would open a sheet listing the profiles this screen is
    // already asking about, under a name for something it cannot do (#43). The
    // identity stays: knowing whose tablet this is tonight is not a door.
    final venue = ref.watch(venueModeActiveProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('onboarding.profile_pick.title')),
        actions: [
          if (asRoot)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: _settings,
                tooltip: s.t('settings.main.title'),
                icon: const Icon(Icons.settings_outlined),
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
              const SizedBox(height: 12),
              // WHO is being asked. The root form is a forced question with
              // nothing under it, and "is this the right account?" is the first
              // half of it — so the answer stands on the screen, above the
              // profiles, with the door to change it beside the identity it
              // raises rather than floating in the app bar (#51).
              if (asRoot) ...[
                _AccountIdentity(
                  account: account,
                  onSwitch: venue ? null : _switchAccount,
                ),
                const SizedBox(height: 12),
              ],
              // The switcher's rows, on the switcher's rules — this screen asks
              // the same question, it just has no answer on file yet.
              for (final band in existing)
                ProfileRow(
                  band: band,
                  enabled: !app.switching,
                  lastUsed: band.id == lastUsed,
                  onTap: () => unawaited(_pick(band)),
                ),
              AddProfileRow(
                title: s.t('onboarding.profile_pick.create'),
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

/// WHICH account this screen is talking about — named, on the screen, without a
/// tap (#51).
///
/// The root picker said "this account" in its title, its heading and its
/// subtitle, and never once said which: an artist who keeps the band's account
/// beside their own could not tell, from anything on the screen, whose account
/// the profile they were about to create would land in. Nothing even showed a
/// cloud account was signed in at all — the one hint was a bare "Switch account"
/// in the app bar, which reads as a way OUT, not as a fact about where you are.
///
/// It is the switcher's own identity line, deliberately: the same avatar, the
/// same [accountDisplayName], the same provider pill the account sheet draws —
/// so the account the artist recognises here is the account they recognise
/// there. And the door sits ON it, because "which account is this?" and "not
/// this one" are the same question and its answer.
///
/// The LOCAL mode is not an account and must not grow a costume of one: no
/// provider pill, no email, no avatar initial — a phone, "On this device", and
/// the caption that says in words that it is not an account. Its door still
/// opens (the account sheet is where the accounts of this device are, and the
/// local mode is one row in it); a VENUE tablet's does not — accounts arrive and
/// leave there through the banner's approve-and-wipe ceremony (#43).
class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({required this.account, required this.onSwitch});

  final AppAccount account;

  /// Null on a venue device: the identity is a fact, not a door (#43).
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final local = account.isLocal;
    final name = accountDisplayName(context, account);
    final email = account.email?.trim();
    final subtitle = local
        ? s.t('widgets.switcher.local_caption')
        : email != null && email.isNotEmpty && email != name
            ? email
            : s.t('onboarding.profile_pick.signed_in');
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          if (local)
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.chip, shape: BoxShape.circle),
              child: Icon(Icons.smartphone_rounded,
                  size: 20, color: c.textSecondary),
            )
          else
            InitialAvatar(
              name: name,
              anonymous: account.kind == AccountKind.anonymous,
              size: 38,
            ),
          const SizedBox(width: 12),
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
                        style: outfitStyle(15, c.text, weight: FontWeight.w700),
                      ),
                    ),
                    // The provider is half of "which account": two Google rows
                    // are told apart by the email, a Google one from an Apple
                    // one by this.
                    if (!local) ...[
                      const SizedBox(width: 8),
                      LtPill(
                        label: accountProviderLabel(context, account.kind),
                        soft: false,
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onSwitch != null)
            TextButton(
              onPressed: onSwitch,
              child: Text(s.t('settings.account.switch_title')),
            ),
        ],
      ),
    );
  }
}
