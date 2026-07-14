import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform_support.dart';
import '../core/theme.dart';
import '../data/repository/account_data_repository.dart';
import '../domain/app_account.dart';
import '../domain/band_account.dart';
import '../domain/pending_redirect.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/venue/venue_reapproval_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_providers.dart';
import '../state/live_session_controller.dart';
import '../state/onboarding_draft.dart';
import '../state/providers.dart';
import '../state/venue_providers.dart';
import 'lt_ui.dart';
import 'sign_in_sheet.dart';

/// The switcher/settings label for a profile's auth provider.
String accountProviderLabel(BuildContext context, AccountKind kind) =>
    switch (kind) {
      AccountKind.local =>
        context.s.t('widgets.account_switcher.provider_local'),
      AccountKind.anonymous =>
        context.s.t('widgets.account_switcher.provider_anonymous'),
      AccountKind.apple =>
        context.s.t('widgets.account_switcher.provider_apple'),
      AccountKind.google =>
        context.s.t('widgets.account_switcher.provider_google'),
    };

/// What an account calls itself: the chosen account name, else the email,
/// else the provider label — and the local profile is always "On this
/// device".
String accountDisplayName(BuildContext context, AppAccount account) {
  if (account.isLocal) {
    return context.s.t('widgets.account_switcher.on_this_device');
  }
  if (account.name.trim().isNotEmpty) return account.name;
  return account.email ?? accountProviderLabel(context, account.kind);
}

/// The label under a profile row: which payment methods it has configured,
/// read straight from the profile's stored jars (cheap prefs lookups).
///
/// [source] overrides where the jars are read from. It defaults to the ambient
/// repository — which is right for the switcher and the picker, both of which
/// list the account they are standing in. The move-in dialog is the exception:
/// it lists LOCAL bands while a cloud account may already be the active
/// profile, so its ambient repository is the cloud mirror and would answer
/// "not set up" for every local band. That dialog passes the local store's own
/// repository instead, so the methods it prints are the ones that will move.
String bandMethodsSummary(
  BuildContext context,
  WidgetRef ref,
  String accountId, {
  AccountDataRepository? source,
}) {
  final AccountDataRepository repo =
      source ?? ref.read(accountDataRepositoryProvider);
  final tipJar = repo.readTipJar(accountId);
  final relayJar = repo.readRelayJar(accountId);
  final methods = <String>[
    if (tipJar != null) 'Stripe',
    if (relayJar?.hasRevolut ?? false) 'Revolut',
    if (relayJar?.hasMobilePay ?? false) 'MobilePay',
    if (relayJar?.hasMonzo ?? false) 'Monzo',
  ];
  return methods.isEmpty
      ? context.s.t('widgets.band_switcher.not_set_up')
      : methods.join(' · ');
}

/// The message behind a refused switch/add/sign-out/delete. Every refusal has
/// one: a silent no-op button is a broken button as far as the artist can tell.
///
/// A SWITCH — of a profile, of an account, or of both at once — says the same
/// sentence whatever it was that moved. Two switchers meant two messages, and
/// the artist was left to know which of our words ("profile", "account") named
/// the thing they had just tapped. [sessionKey] is for the acts that are NOT a
/// switch — adding, signing out, deleting — which name themselves.
String accountBlockMessage(
  BuildContext context,
  AccountActionBlock block, {
  String? sessionKey,
}) =>
    switch (block) {
      AccountActionBlock.switching =>
        context.s.t('widgets.band_switcher.switching'),
      AccountActionBlock.localSession ||
      AccountActionBlock.remoteSession =>
        context.s.t(sessionKey ?? 'widgets.profile_switcher.stop_session_switch'),
    };

/// A refusal, and the number of times it has been said. The [tick] is what makes
/// a SECOND tap on the same blocked row visible: the sentence does not change,
/// so nothing on the screen would, and an artist who taps again and sees the
/// same still frame has learned nothing. The banner replays its pulse on every
/// new tick.
class _Refusal {
  const _Refusal(this.message, this.tick);

  final String message;
  final int tick;
}

/// Where a sheet's refusals are SAID. One per open sheet, and the sheet's chrome
/// listens to it ([_SheetFrame]).
class _RefusalSink extends ValueNotifier<_Refusal?> {
  _RefusalSink() : super(null);

  void say(String message) => value = _Refusal(message, (value?.tick ?? 0) + 1);

  void clear() => value = null;
}

/// The scope a refusal is spoken INTO — wrapped around each sheet's body, and
/// absent everywhere else. It is how [accountActionAllowed] knows which surface
/// the artist is actually looking at.
class _RefusalScope extends InheritedWidget {
  const _RefusalScope({required this.sink, required super.child});

  final _RefusalSink sink;

  /// Deliberately non-dependent (`getElementForInheritedWidgetOfExactType`):
  /// this is read from a TAP, not from a build, and a refusal must not
  /// re-subscribe half the sheet on its way out.
  static _RefusalSink? maybeOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<_RefusalScope>();
    return (element?.widget as _RefusalScope?)?.sink;
  }

  @override
  bool updateShouldNotify(_RefusalScope oldWidget) => sink != oldWidget.sink;
}

/// Owns the sink for the sheet under it — one refusal channel per open sheet,
/// disposed with it.
class _RefusalHost extends StatefulWidget {
  const _RefusalHost({required this.child});

  final Widget child;

  @override
  State<_RefusalHost> createState() => _RefusalHostState();
}

class _RefusalHostState extends State<_RefusalHost> {
  final _sink = _RefusalSink();

  @override
  void dispose() {
    _sink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RefusalScope(sink: _sink, child: widget.child);
}

/// How a refusal is HEARD on the surface it was asked from — the whole of #53.
///
/// A snackbar is anchored to the bottom edge of the screen; a bottom sheet
/// covers the bottom edge. Every refusal this file has ever given from inside a
/// sheet was painted UNDER that sheet, behind the barrier, on a route whose
/// semantics are blocked — a correct guard, refusing in a whisper, into a room
/// the artist is not standing in. Mid-gig, the artist tapped and nothing moved.
///
/// So the surface decides. Inside a sheet ([_RefusalScope]) the sentence goes to
/// the sheet's own chrome, above the barrier, and STAYS there as long as the
/// block does — a condition that is still true when a snackbar would have timed
/// out has no business timing out. On a full screen (Settings, the root picker)
/// there is no scope, the snackbar is visible, and nothing changes.
///
/// The sink is resolved from the context BEFORE any await, so a caller that
/// comes back to an unmounted context can still speak (it is the sheet's sink,
/// not the sheet's context, that does the talking).
void Function(String message) _refusalVoice(BuildContext context) {
  final sink = _RefusalScope.maybeOf(context);
  if (sink != null) return sink.say;
  final messenger = ScaffoldMessenger.of(context);
  return (message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// THE guard, asked once, before anything moves — and it always answers out
/// loud. Every account-level act (switch, add, sign out, delete, move, change
/// the device kind) runs through this: guards that disagreed is how a dead
/// session used to lock an account out of its own switcher, and how a live set
/// could be yanked out from under an artist by one of the two switchers but
/// never by the other.
///
/// "Out loud" means ON THE SURFACE THE ARTIST IS LOOKING AT — see
/// [_refusalVoice]. It refuses exactly as before; only the room changed.
bool accountActionAllowed(
  BuildContext context,
  WidgetRef ref, {
  String? sessionKey,
}) {
  final block = ref.read(appStateProvider.notifier).accountActionBlock;
  if (block == null) return true;
  _refusalVoice(context)(
    accountBlockMessage(context, block, sessionKey: sessionKey),
  );
  return false;
}

/// The profile name as a tap target with a chevron — tapping opens the
/// switcher. Used in the home headers.
class BandNameButton extends ConsumerWidget {
  const BandNameButton({
    super.key,
    required this.fontSize,
    required this.weight,
  });

  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final style = outfitStyle(fontSize, c.text, weight: weight);
    final name = app.displayName.isEmpty
        ? context.s.t('widgets.profile_switcher.your_profile')
        : app.displayName;
    // Demo has no real profile to switch unless others already exist — the
    // escape hatch back to a real profile must stay reachable.
    if (app.demo && app.accounts.length < 2) {
      return Text(name, style: style);
    }
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: InkWell(
        onTap: () => showProfileSheet(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Text.rich(
          TextSpan(
            text: name,
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: fontSize * 0.8,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}

/// Small pill naming the active profile, opening the switcher — for surfaces
/// outside the home header (side rail, welcome, jar setup).
class BandChip extends ConsumerWidget {
  const BandChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final name = app.displayName.isEmpty
        ? context.s.t('widgets.profile_switcher.new_profile')
        : app.displayName;
    return Material(
      color: c.chip,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showProfileSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_rounded, size: 15, color: c.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: outfitStyle(
                    13,
                    c.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 16, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// TWO sheets, ONE design — and each door opens the one it names.
///
/// The two nouns of this app are the cloud **account** you are signed into and
/// the **profile** (the band) you perform as, and they are the two most
/// confusable ideas in it. #29 was asked to bring their two switchers to a
/// common FORM — the account's was a full screen in Settings, the profile's a
/// sheet from the header — and instead it merged them into one list: a device
/// mode, some profiles, an account with a Google pill, "Add a profile" and
/// "Sign in to another account", four kinds of thing under the single heading
/// "Your profiles". The artist who wanted to change account had to find it among
/// the profiles; the entry point labelled "Switch account" opened it (#49).
///
/// What #29 got right is kept whole, and it is the expensive half: ONE guard
/// ([accountActionAllowed]), ONE switch ([switchTo]), ONE birthplace of a
/// profile ([addProfile], which writes nothing on the tap — #44), ONE sign-out
/// ([confirmSignOut]), one [ProfileRow], one chrome. The sheets differ in the
/// QUESTION they ask, not in the rules they obey.
///
/// A SHEET, both of them, and that is the shape decision: switching is the most
/// frequent, least destructive thing the artist does — mid-gig, one thumb, over
/// whatever they were looking at — and a sheet is the one form that can open
/// above ANY surface, including RootGate's own root picker, without a route to
/// push. (A modal also has no route identity to collide with the root it just
/// flipped, which is the whole of #38.)
///
/// The PROFILE sheet — *which profile am I performing as?* The profiles of the
/// account currently in use, and "Add a profile" under them (adding into an
/// account you are not in means going there first, which is a different
/// decision). Nothing about accounts, except the one door that names the one you
/// are in — [_AccountDoorRow] — because an artist who opened the wrong sheet
/// must not have to guess which of two words we chose for the other one.
///
/// On a VENUE device that door is absent: the ways in and out of an account
/// there run through the banner's approve-and-wipe ceremony, and a switcher that
/// skipped it would be the hole that ceremony exists to close.
Future<void> showProfileSheet(BuildContext context, WidgetRef ref) async {
  // The door out is a RESULT, not a nested sheet: this sheet closes, and the
  // account sheet opens from the surface that opened this one — still standing,
  // because a modal moves no route.
  final toAccounts = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    // The sheet is the room the artist is standing in, so it is the room a
    // refusal is spoken in (#53).
    builder: (sheetContext) => const _RefusalHost(child: _ProfileSheet()),
  );
  if (toAccounts == true && context.mounted) {
    await showAccountSheet(context, ref);
  }
}

/// The ACCOUNT sheet — *whose profiles am I looking at?*
///
/// * **On this device** — a MODE, not an account: the profiles that never leave
///   this phone. It belongs HERE and not among the profiles, because it is an
///   answer to whose-profiles, not to which-profile. It carries no account
///   chrome (no provider pill, no sign-out, no delete): there is nothing there
///   to sign out of or delete — it is permanent by construction
///   (AccountsDirectory.withoutAccount) — and a row offering either would be a
///   button that cannot work.
/// * **Each cloud account** this device knows, one row each. This device holds
///   no list of another account's profiles (the repository mirrors the account
///   it is in), and inventing one out of a stale cache is the cache-first lie
///   this codebase keeps paying for. So an account is a single act: the flip,
///   and then that account's own profile question, asked by RootGate's picker
///   once the artist has landed — the same for the local mode as for a cloud
///   account.
/// * **Sign in to another account**, at the foot: the door to an account this
///   device has never seen.
///
/// A live session refuses every one of those, with the same guard and the same
/// sentence the profile sheet uses ([accountActionAllowed]).
Future<void> showAccountSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _RefusalHost(child: _AccountSheet()),
  );
}

/// Switching, both kinds, one code path: a profile of the account in use, a
/// profile of the local mode while a cloud account is open (the flip and the
/// choice as ONE act), or an account whose profile question is still open.
///
/// The guard is asked ONCE, before anything moves — never once per moving part.
/// Returns true when the artist has landed somewhere new; the caller decides
/// what that means for the route it is standing on (the sheet closes, the root
/// picker drops the onboarding stack).
Future<bool> switchTo(
  BuildContext context,
  WidgetRef ref, {
  required AppAccount account,
  BandAccount? band,
}) async {
  // The owner's rule for shared devices: changing what a venue tablet shows
  // needs a fresh approval from the artist's own phone.
  if (!await ensureVenueReapproval(context, ref)) return false;
  if (!context.mounted) return false;
  if (!accountActionAllowed(context, ref)) return false;

  final directory = ref.read(accountsDirectoryProvider);
  final notifier = ref.read(appStateProvider.notifier);
  // Resolved BEFORE the awaits below — the voice outlives this context.
  final refuse = _refusalVoice(context);
  final stopSessionMsg =
      context.s.t('widgets.profile_switcher.stop_session_switch');

  if (account.id != directory.activeAccountId) {
    return _enterAccount(context, ref, account, band);
  }
  // Already here — nothing to move.
  if (band == null || band.id == ref.read(appStateProvider).accountId) {
    return true;
  }

  // Leaving a half-finished new profile behind — one that was named on the
  // details step but never got a payment method, and holds no data? It is
  // reachable (the shell's empty-state home) but worthless. Offer to discard it
  // on the way out rather than let unfinished profiles pile up. (Nothing is
  // being left behind when nothing is open — the root picker's '' band.)
  final leavingId = ref.read(appStateProvider).accountId;
  // `== false`, not `!`: the cloud repository answers null until its mirrors
  // have heard from the server, and a discard dialog must never be driven by a
  // maybe — an unconfirmed profile is simply left alone.
  final abandoning = leavingId.isNotEmpty &&
      !ref.read(appStateProvider).connected &&
      ref.read(accountDataRepositoryProvider).accountHasData(leavingId) ==
          false;
  if (abandoning && !await _confirmDiscard(context)) return false;

  final ok = await notifier.switchAccount(band.id);
  if (!ok) {
    // The guard said yes and something moved in between — say why, in the same
    // sentence every other refusal here uses, and in the same place.
    refuse(stopSessionMsg);
    return false;
  }
  // The unfinished profile is no longer active — remove it now that we have
  // landed safely on the chosen one.
  if (abandoning) await notifier.removeAccount(leavingId);
  return true;
}

/// The other-account half of [switchTo]: the flip itself, and what has to
/// happen before it.
///
/// A cloud account whose own session is alive (they all stay alive — see
/// AccountSessions) is one directory flip away, no re-auth. Only a session that
/// DIED needs its provider run again, and a guest account, having no credential,
/// cannot be signed back in at all (that row is disabled).
///
/// [band] rides along when the artist picked a profile UNDER the account they
/// are moving to — which this device can only enumerate for the local mode.
/// Writing the choice down BEFORE the flip is what makes it one action: the
/// reload that follows reads it back (AppStateNotifier `_pickActive`) and opens
/// exactly the profile that was tapped, instead of landing the artist on a
/// question they have already answered.
Future<bool> _enterAccount(
  BuildContext context,
  WidgetRef ref,
  AppAccount account,
  BandAccount? band,
) async {
  if (band != null && account.isLocal) {
    final local = ref.read(localStoreProvider);
    final registry = local.readAccountsRegistry();
    if (registry != null && registry.contains(band.id)) {
      await local.saveAccountsRegistry(registry.withActive(band.id));
    }
  }
  final liveUid = ref.read(authControllerProvider).user?.uid;
  final sessions = ref.read(accountSessionsProvider);
  if (account.isLocal ||
      account.id == liveUid ||
      sessions.isAlive(account.id)) {
    await ref.read(accountsDirectoryProvider.notifier).setActive(account.id);
    return true;
  }
  final controller = ref.read(authControllerProvider.notifier);
  // On the web this leaves the page for the provider and returns null; the
  // sign-in finishes on the way back and lands on Settings (RedirectOrigin).
  final user = switch (account.kind) {
    AccountKind.apple =>
      await controller.signInWithApple(origin: RedirectOrigin.settings),
    AccountKind.google =>
      await controller.signInWithGoogle(origin: RedirectOrigin.settings),
    // A guest account has no credential: with its session gone there is
    // nothing to sign back in with. That row is disabled (and removable).
    _ => null,
  };
  // Null is a cancel or a failure: stay put, the error renders inline.
  return user != null;
}

/// The unfinished-profile prompt (#6) — a destructive act that looks like one,
/// and the artist's to refuse.
Future<bool> _confirmDiscard(BuildContext context) async {
  final s = context.s;
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.t('widgets.profile_switcher.discard_title')),
      content: Text(s.t('widgets.profile_switcher.discard_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.t('widgets.band_switcher.keep_editing')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.t('widgets.band_switcher.discard_switch')),
        ),
      ],
    ),
  );
  return discard == true;
}

/// STARTS adding a profile — or says why it can't. The ONE "Add a profile",
/// shared by the switcher's row and the root picker's create card: the old
/// silent `return` on a refusal made the button look broken, and two copies of
/// the rule were free to disagree about what a refusal even was.
///
/// It writes NOTHING. The tap opens the form; the profile is written by the
/// details step, out of the name typed into it (`createFirstBand`). It used to
/// mint the band here, on the tap, before the artist had typed a character —
/// and an artist who then backed out of the form was left with an "Unnamed"
/// profile they never made, active, and on a cloud account on every device they
/// own, forcing the picker on every cold boot of each (#44). A tap on "Create"
/// is the artist asking for the FORM; the name is the ask.
///
/// True means the caller may walk into the setup — which it must open with
/// `firstBandSetupScreen(createsProfile: true)`, so the name lands on a new
/// profile rather than renaming the one the artist is standing in.
Future<bool> addProfile(BuildContext context, WidgetRef ref) async {
  // Creating a profile changes the account's data — on a venue device that,
  // too, waits for the phone's nod.
  if (!await ensureVenueReapproval(context, ref)) return false;
  if (!context.mounted) return false;
  if (!accountActionAllowed(context, ref,
      sessionKey: 'widgets.profile_switcher.stop_session_add')) {
    return false;
  }
  // A new run: it inherits no method choices from the last one — and the draft
  // IS the run, so clearing it puts the step counter back to "1 of 3".
  ref.read(onboardingDraftProvider.notifier).clear();
  return true;
}

/// SIGN OUT — the whole act (#31): the account's session ends and the account
/// leaves this device. Everything it owns stays in the cloud, and the dialog
/// says so. A guest account is the exception, and the dialog says that too:
/// with no credential to come back with, signing out destroys it — so the way
/// out that KEEPS it (linking a real provider to the same uid) is offered right
/// there.
///
/// One copy, called from the switcher's account menu and from Settings' row. It
/// was Settings' alone, which is why the account rows of a switcher full of
/// accounts had no way to leave one.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final s = context.s;
  final user = ref.read(authControllerProvider).user;
  if (user == null) return;
  // A sign-out is an account flip like any other — refused mid-session, by the
  // same guard switch/add/delete ask. Silently ending an artist's live set from
  // a tap in a menu is not an option.
  if (!accountActionAllowed(context, ref,
      sessionKey: 'settings.account.stop_session_sign_out')) {
    return;
  }
  final anonymous = user.kind == AccountKind.anonymous;
  final choice = await showDialog<_SignOutChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.t('settings.account.sign_out_title')),
      content: Text(
        anonymous
            ? s.t('settings.account.sign_out_anonymous_body')
            : s.t('settings.account.sign_out_body_device'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_SignOutChoice.cancel),
          child: Text(s.t('common.cancel')),
        ),
        if (anonymous) ...[
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_SignOutChoice.linkApple),
            child: Text(s.t('settings.account.link_apple')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_SignOutChoice.linkGoogle),
            child: Text(s.t('settings.account.link_google')),
          ),
        ],
        FilledButton(
          style: anonymous
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(_SignOutChoice.signOut),
          child: Text(s.t('settings.account.sign_out')),
        ),
      ],
    ),
  );
  final auth = ref.read(authControllerProvider.notifier);
  switch (choice) {
    case _SignOutChoice.signOut:
      // The whole act, not just the session: the account leaves this device
      // (#31). Never AuthController.signOut alone — that is the half that used
      // to leave the artist's email address in the switcher.
      await ref.read(signOutProvider)();
    // The guest upgrade. On the web this is linkWithRedirect: the page leaves
    // and the LINK is remembered across the reload (PendingRedirect.link), so
    // the guest's uid — and every profile under it — is upgraded in place
    // rather than a second, empty account being signed in beside it.
    case _SignOutChoice.linkApple:
      await auth.signInWithApple(link: true, origin: RedirectOrigin.settings);
    case _SignOutChoice.linkGoogle:
      await auth.signInWithGoogle(link: true, origin: RedirectOrigin.settings);
    case _SignOutChoice.cancel:
    case null:
      break;
  }
}

/// What the sign-out dialog resolved to. A guest can also leave by KEEPING the
/// account and giving it a real credential — that is the whole point of
/// offering the link there.
enum _SignOutChoice { cancel, signOut, linkApple, linkGoogle }

/// A row was tapped: the switch runs, and the sheet closes over whatever the
/// artist landed on. Only if it is still up — they may have swiped it away
/// during the keychain read, and popping then would eat the route underneath.
Future<void> _switchAndClose(
  BuildContext context,
  WidgetRef ref,
  AppAccount account, [
  BandAccount? band,
]) async {
  final sheet = Navigator.of(context);
  if (!await switchTo(context, ref, account: account, band: band)) return;
  if (sheet.canPop()) sheet.pop();
}

/// Whether this device can reach an account at all: not a venue tablet (the
/// banner's ceremony owns that door), on a platform with cloud accounts, with a
/// provider to run. It gates the sign-in row, and the profile sheet's door to
/// the account sheet — a door to a sheet that could hold nothing but a mode is
/// no door at all.
bool _accountsReachable(BuildContext context, WidgetRef ref) =>
    !ref.watch(venueModeActiveProvider) &&
    platformSupportsCloudAccounts &&
    ref.read(authControllerProvider.notifier).available;

/// The chrome both sheets wear: a heading that says which question is being
/// asked, the one hint a blocked state gets — which SPEAKS when a blocked row is
/// tapped (#53) — the rows, and a foot. Written once: the sheets differ in what
/// they ASK, and in nothing else.
class _SheetFrame extends ConsumerWidget {
  const _SheetFrame({required this.title, required this.rows, this.footer});

  final String title;
  final List<Widget> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    final live = ref.watch(liveSessionProvider);
    final switching = ref.watch(appStateProvider.select((a) => a.switching));
    final blocked = live != null || switching;
    final hint = live != null
        ? s.t('widgets.profile_switcher.live_running_hint')
        : s.t('widgets.band_switcher.switching');
    final sink = _RefusalScope.maybeOf(context);
    // The block is over (the set was stopped from another surface): the refusal
    // it explained goes with it — a sentence about a session that ended is a
    // lie, however loudly it is printed.
    if (!blocked && sink?.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sink?.clear());
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                title,
                style: outfitStyle(18, c.text, weight: FontWeight.w700),
              ),
            ),
            if (blocked)
              if (sink == null)
                _BlockedNotice(hint: hint, refusal: null)
              else
                ValueListenableBuilder<_Refusal?>(
                  valueListenable: sink,
                  builder: (context, refusal, _) =>
                      _BlockedNotice(hint: hint, refusal: refusal),
                ),
            Flexible(child: ListView(shrinkWrap: true, children: rows)),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// The sheet's one blocked-state line, in its two voices.
///
/// **Untapped** — the muted hint it has always been: a live session is running,
/// so some of this is refused.
///
/// **Refused** — the artist tapped anyway, and the sentence the guard answered
/// with takes the line over: loud, named for the act that was refused ("Stop the
/// live session before adding a profile."), and INSIDE the sheet, which is the
/// only place a refusal is worth printing while a sheet is open. It stays for as
/// long as the block does, and pulses again on every further tap — a repeated
/// tap must produce a repeated answer, or the artist is back to a still frame.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.hint, required this.refusal});

  final String hint;
  final _Refusal? refusal;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final refused = refusal;
    if (refused == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Text(
          hint,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 12.5,
            color: c.textMuted,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      // Keyed on the tick: a second refusal is a NEW widget, so the pulse runs
      // again even though the words did not change.
      child: TweenAnimationBuilder<double>(
        key: ValueKey(refused.tick),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Transform.scale(
          scale: 0.94 + 0.06 * t,
          alignment: Alignment.centerLeft,
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
        // A live region: the artist who cannot see it is told it, which is more
        // than the snackbar managed — a modal route blocks the semantics of the
        // screen the snackbar was printed on.
        child: Semantics(
          liveRegion: true,
          child: Container(
            decoration: BoxDecoration(
              color: c.warningContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: c.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    refused.message,
                    style: outfitStyle(13.5, c.warning, weight: FontWeight.w600),
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

/// *Which profile am I performing as?* — the profiles of the account in use,
/// and the one way to make another. See [showProfileSheet].
class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  Future<void> _addProfile(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final sheet = Navigator.of(context);
    if (!await addProfile(context, ref)) return;
    if (sheet.canPop()) sheet.pop();
    // The setup starts by naming the profile — and naming it is what creates
    // it. Backing out of that form leaves the artist where they were, on the
    // profile they were already in, with nothing new written anywhere.
    rootNavigator.push(
      MaterialPageRoute(
        builder: (_) => firstBandSetupScreen(createsProfile: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final app = ref.watch(appStateProvider);
    final account = ref.watch(accountsDirectoryProvider).active;
    return _SheetFrame(
      title: s.t('widgets.profile_switcher.title'),
      rows: [
        // The profiles of the account in use — the only ones this device can
        // enumerate for the account it is standing in, and the only ones this
        // question is about.
        for (final band in app.accounts)
          ProfileRow(
            band: band,
            active: !app.demo && band.id == app.accountId,
            // Every row stays tappable, blocked or not: a refusal must be able
            // to SAY why. The old band sheet greyed its rows out mid-session and
            // left a hint at the top — which an artist tapping the row they want
            // never reads, and a dead button is indistinguishable from a broken
            // one.
            enabled: true,
            onTap: () => _switchAndClose(context, ref, account, band),
          ),
        AddProfileRow(
          title: s.t('widgets.profile_switcher.add'),
          enabled: true,
          onTap: () => _addProfile(context, ref),
        ),
      ],
      // The one account thing in a sheet about profiles, and it is a DOOR, not
      // a row in the list: it names the account these profiles belong to, and
      // opening it is how an artist who wanted the other question gets there
      // (#49).
      footer: _accountsReachable(context, ref)
          ? _AccountDoorRow(
              account: account,
              onTap: () => Navigator.of(context).pop(true),
            )
          : null,
    );
  }
}

/// *Whose profiles am I looking at?* — the accounts on this device, the local
/// mode, and the door to an account it has never seen. See [showAccountSheet].
class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  /// Drops a guest account whose session is gone. There is nothing to recover
  /// and nothing to sign back into — the only honest choices are a dead row
  /// forever or this, said bluntly.
  Future<void> _confirmForget(
    BuildContext context,
    WidgetRef ref,
    AppAccount account,
  ) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.account.forget_title')),
        content: Text(s.t('settings.account.forget_body')),
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
            child: Text(s.t('common.remove')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountsDirectoryProvider.notifier).remove(account.id);
  }

  Future<void> _signInAnother(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    // A sign-in lands on a fresh account's profile question — the same flip
    // every other row here performs, so it asks the same guard first.
    if (!accountActionAllowed(context, ref)) return;
    final user = await showSignInSheet(context);
    if (user != null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    final directory = ref.watch(accountsDirectoryProvider);
    final auth = ref.watch(authControllerProvider);
    // Sessions live in their own FirebaseApp instances — every one of them
    // stays reachable without a re-auth, not just the one in the foreground.
    final sessions = ref.watch(accountSessionsProvider);
    ref.watch(accountSessionsChangesProvider);
    final canSignIn = _accountsReachable(context, ref);
    final liveUid = auth.user?.uid;
    final activeId = directory.activeAccountId;
    // Whether the local mode has anything under it — the caption says so, and
    // an empty one lands on the create step rather than nowhere (#38).
    final localBands =
        ref.watch(localStoreProvider).readAccountsRegistry()?.accounts ??
            const <BandAccount>[];

    return _SheetFrame(
      title: s.t('widgets.account_switcher.title'),
      rows: [
        for (final account in directory.accounts)
          if (account.isLocal)
            _LocalHeader(
              active: account.id == activeId,
              empty: localBands.isEmpty,
              // Always the door in, whatever is under it: the merged sheet made
              // this label tappable only when the mode was EMPTY (its profiles
              // were the way in), and in a sheet that lists no profiles that
              // would leave the mode unreachable.
              onTap: account.id == activeId
                  ? null
                  : () => _switchAndClose(context, ref, account),
            )
          else
            _AccountHeader(
              account: account,
              active: account.id == activeId,
              // A live session is re-entered by a directory flip, whatever the
              // provider. Without one, Apple/Google sign in again — and a guest
              // account, having no credential, cannot.
              sessionAlive:
                  account.id == liveUid || sessions.isAlive(account.id),
              enabled: !auth.busy &&
                  (account.id == liveUid ||
                      sessions.isAlive(account.id) ||
                      (canSignIn && account.kind != AccountKind.anonymous)),
              // The only unreachable account there is: a guest whose session is
              // gone. Offer to forget it rather than keep a dead row around
              // forever.
              onForget: account.kind == AccountKind.anonymous &&
                      account.id != liveUid &&
                      !sessions.isAlive(account.id)
                  ? () => _confirmForget(context, ref, account)
                  : null,
              onSignOut: account.id == activeId
                  ? () => confirmSignOut(context, ref)
                  : null,
              onTap: () => _switchAndClose(context, ref, account),
            ),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                auth.error!,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 12.5,
                  height: 1.45,
                  color: c.danger,
                ),
              ),
            ),
          if (canSignIn) ...[
            Divider(height: 16, color: c.divider),
            _SignInAnotherRow(
              enabled: !auth.busy,
              onTap: () => _signInAnother(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

/// The profile sheet's one account row — a DOOR, at the foot, named for what it
/// opens ("Switch account") and captioned with the account whose profiles are
/// listed above it. It is the answer to the question the split creates: from the
/// profiles, how does the artist reach the accounts? One door, named — and it
/// says which account they are in, which the band-less root never did either
/// (#51).
class _AccountDoorRow extends StatelessWidget {
  const _AccountDoorRow({required this.account, required this.onTap});

  final AppAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 16, color: c.divider),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.swap_horiz_rounded,
                        size: 20, color: c.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('settings.account.switch_title'),
                          style:
                              outfitStyle(15, c.text, weight: FontWeight.w600),
                        ),
                        Text(
                          // The local mode is not an account, and saying
                          // "signed in as On this device" would be the same
                          // muddle in one line.
                          account.isLocal
                              ? s.t('widgets.switcher.local_caption')
                              : s.t('widgets.profile_switcher.signed_in_as',
                                  {'account': accountDisplayName(context, account)}),
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
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: c.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "On this device" — a MODE, and it must not read as an account. No provider
/// pill, no menu: there is no signing out of this device and no deleting it
/// (AccountsDirectory.withoutAccount refuses to remove it — it is permanent by
/// construction), and a row offering either would be a promise the model cannot
/// keep. It answers *whose profiles am I looking at* with "nobody's — they never
/// leave this phone", which is why it stands among the accounts and not among
/// the profiles (#49).
class _LocalHeader extends StatelessWidget {
  const _LocalHeader({
    required this.active,
    required this.empty,
    this.onTap,
  });

  /// The mode this device is in right now — the profiles behind the sheet are
  /// its profiles.
  final bool active;

  /// Nothing under it yet: the caption says so, and choosing it lands the empty
  /// profile set on the create step rather than on nothing (#38).
  final bool empty;

  /// Null only when it is already the mode in use — there is nowhere to go.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.smartphone_rounded, size: 20, color: c.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('widgets.account_switcher.on_this_device'),
                      style: outfitStyle(
                        14.5,
                        c.text,
                        weight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      s.t(empty && !active
                          ? 'widgets.switcher.local_empty'
                          : 'widgets.switcher.local_caption'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Icon(Icons.check_circle_rounded, size: 22, color: c.accent)
              else
                Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One cloud account: name/email, provider, and — when it is the one in use —
/// its profiles listed underneath. A guest account whose session is gone is the
/// one unreachable row: disabled, with the reason as its subtitle and a way to
/// forget it.
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.account,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.sessionAlive = false,
    this.onForget,
    this.onSignOut,
  });

  final AppAccount account;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  /// Whether this account's own session is alive on the device — one tap
  /// re-enters it; a dead session means the provider sign-in runs again.
  final bool sessionAlive;

  final VoidCallback? onForget;

  /// Only the account in use can be signed out of — the act ends ITS session
  /// and takes ITS cached profiles off this device.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final name = accountDisplayName(context, account);
    final subtitle = active
        ? s.t('settings.account.switch_current')
        : onForget != null
            ? s.t('widgets.account_switcher.anonymous_locked')
            : sessionAlive
                ? s.t('settings.account.session_alive')
                : s.t('settings.account.session_gone');
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !active ? onTap : null,
        child: Opacity(
          opacity: enabled || active ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: name,
                  anonymous: account.kind == AccountKind.anonymous,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: outfitStyle(
                          14.5,
                          c.text,
                          weight: active ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                LtPill(
                  label: accountProviderLabel(context, account.kind),
                  soft: false,
                ),
                if (onForget != null)
                  IconButton(
                    onPressed: onForget,
                    tooltip: s.t('settings.account.forget_row'),
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 22, color: c.danger),
                  )
                // Destructive, and it looks it: red, named in full, and behind a
                // menu rather than under the thumb of an artist reaching for a
                // profile.
                else if (onSignOut != null)
                  PopupMenuButton<void>(
                    tooltip: s.t('settings.account.sign_out'),
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 22, color: c.textMuted),
                    itemBuilder: (context) => [
                      PopupMenuItem<void>(
                        onTap: onSignOut,
                        child: Text(
                          s.t('settings.account.sign_out'),
                          style:
                              outfitStyle(14, c.danger, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 22, color: c.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One profile — in the switcher, and on the root picker, which asks the same
/// question with no answer on file yet. Avatar, name, the methods it already
/// has, a check when it is the one in use, and — where the device remembers one
/// — a "Last used" pill. The pill is the whole extent of remembering: it points
/// at a row, it does not open it.
class ProfileRow extends ConsumerWidget {
  const ProfileRow({
    super.key,
    required this.band,
    required this.enabled,
    required this.onTap,
    this.active = false,
    this.lastUsed = false,
    this.trailing,
    this.dataSource,
  });

  final BandAccount band;
  final bool active;
  final bool enabled;
  final bool lastUsed;
  final VoidCallback onTap;

  /// Drawn at the row's tail in place of the active check — a checkbox, in the
  /// move-in dialog, where the row is a selection rather than a destination.
  final Widget? trailing;

  /// Where the methods summary is read from (see [bandMethodsSummary]). Null
  /// keeps the ambient repository, which is what every switcher/picker row
  /// wants; the move-in dialog passes a local-store repository so a local
  /// band's methods still read while a cloud account is the active profile.
  final AccountDataRepository? dataSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final name = band.name.trim().isEmpty
        ? context.s.t('widgets.profile_switcher.unnamed')
        : band.name;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !active ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: name,
                  anonymous: band.name.trim().isEmpty,
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
                              style: outfitStyle(
                                15,
                                c.text,
                                weight:
                                    active ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (lastUsed) ...[
                            const SizedBox(width: 8),
                            LtPill(
                              label: context.s
                                  .t('onboarding.profile_pick.last_used'),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        bandMethodsSummary(context, ref, band.id,
                            source: dataSource),
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
                // A tail widget takes the slot the active check would hold — a
                // selection row has a checkbox there, and is never itself the
                // active profile.
                if (trailing != null)
                  trailing!
                else if (active)
                  Icon(Icons.check_circle_rounded, size: 22, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Add a profile" / "Create a new profile" — one row, two names for where it
/// is being read: the switcher's list, and the root picker's only card.
class AddProfileRow extends StatelessWidget {
  const AddProfileRow({
    super.key,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sign in to another account" — the door to an account this device has never
/// seen. At the foot of the list, where a door belongs: it is the one row here
/// that does not lead to something the artist already has.
class _SignInAnotherRow extends StatelessWidget {
  const _SignInAnotherRow({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_alt_rounded,
                      size: 20, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.s.t('widgets.account_switcher.sign_in_another'),
                    style: outfitStyle(15, c.text, weight: FontWeight.w600),
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
