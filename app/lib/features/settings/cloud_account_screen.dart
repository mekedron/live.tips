import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/profile_switcher.dart';
import '../account/cloud_upload_offer.dart';
import '../onboarding/account_name_screen.dart';
import 'security_screen.dart';
import 'sign_in_methods_screen.dart';

/// The signed-in account, on ONE page — everything that edits the ACCOUNT
/// (its name, its sign-in methods, its devices, moving local profiles in,
/// and leaving it) used to sit flat on the Settings screen, five rows deep
/// before the profile section even started. Settings now carries two account
/// rows — who is signed in (this door) and "Switch account" — and this screen
/// holds the rest, unchanged: the rows here are the rows Settings had, with
/// the same guards, the same dialogs and the same venue gating.
///
/// Pushed as a [RootBoundRoute]: this screen DESCRIBES the signed-in account,
/// and sign-out (a row on it) flips the root — the route must come down with
/// the world it narrates rather than re-render against whatever the flip
/// landed on (#48).
class CloudAccountScreen extends ConsumerStatefulWidget {
  const CloudAccountScreen({super.key});

  @override
  ConsumerState<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends ConsumerState<CloudAccountScreen> {
  /// The permanent home of the local→cloud move. The offer that pops after
  /// a sign-in is a convenience with a memory — it only asks about profiles
  /// it hasn't asked about — so without this row, an account that once said
  /// "Not now" had no way to ever bring those profiles over. Same question,
  /// same dialog, same migrator; the only difference is that the artist
  /// walked up to it.
  Future<void> _confirmMoveLocalProfiles() async {
    final s = context.s;
    // The move ends by switching to the migrated profile — the same guard
    // switch/add/sign-out ask, for the same reason: no reshuffling under a
    // live set.
    if (!accountActionAllowed(context, ref,
        sessionKey: 'settings.account.stop_session_move')) {
      return;
    }
    final uid = ref.read(accountsDirectoryProvider).activeAccountId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('account.profile_upload.title')),
        content: Text(s.t('account.profile_upload.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('account.profile_upload.accept')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // The account this screen was about must still be the signed-in one —
    // the dialog sat open, and the upload writes into ITS subtree.
    if (ref.read(authControllerProvider).user?.uid != uid) return;
    await runCloudUpload(context, ref, uid);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final auth = ref.watch(authControllerProvider);
    // Watched so a rename from the naming step refreshes the row.
    final directory = ref.watch(accountsDirectoryProvider);
    final venueMode = ref.watch(venueModeActiveProvider);
    // The account this screen is ABOUT is the active profile, not whichever
    // Firebase session happens to be alive — the same rule Settings reads
    // its account section by.
    final activeProfile = directory.active;
    final cloudEntry = activeProfile.isLocal
        ? null
        // A user the directory hasn't caught up with yet (mid sign-in) falls
        // back to what the provider knows.
        : (auth.user != null && auth.user!.uid == activeProfile.id
            ? AppAccount(
                id: auth.user!.uid,
                name: activeProfile.name.isNotEmpty
                    ? activeProfile.name
                    : (auth.user!.displayName ?? ''),
                kind: auth.user!.kind,
                email: auth.user!.email ?? activeProfile.email,
              )
            : activeProfile);
    // Whether this device still holds local profiles worth moving into the
    // signed-in account (named, or holding data — pristine placeholders are
    // noise, not value). Needs the account's OWN session alive: the upload
    // writes into its Firestore subtree.
    final localStore = ref.watch(localStoreProvider);
    final canMoveLocalProfiles = cloudEntry != null &&
        auth.user?.uid == activeProfile.id &&
        ref.watch(cloudUploadRunnerProvider) != null &&
        (localStore.readAccountsRegistry()?.accounts.any((a) =>
                a.name.trim().isNotEmpty ||
                localStore.accountHasData(a.id)) ??
            false);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.account.header'))),
      body: cloudEntry == null
          // The RootBoundRoute unwinds this screen when the account leaves;
          // this placeholder is only the in-between frame (and the state a
          // test could pump directly).
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
                    LtRowGroup(
                      children: [
                        // Tappable: an account you can't name is an account
                        // you can't tell apart from the next guest one.
                        // AuthController.setAccountName existed all along
                        // with nothing to call it.
                        LtRow(
                          icon: Icons.account_circle_rounded,
                          title: accountDisplayName(context, cloudEntry),
                          subtitle: [
                            accountProviderLabel(context, cloudEntry.kind),
                            if (cloudEntry.email != null) cloudEntry.email!,
                          ].join(' · '),
                          chevron: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AccountNameScreen(rename: true),
                            ),
                          ),
                        ),
                        // The permanent door #32 asked for. Not on a venue
                        // device: a shared tablet must not be able to attach
                        // an identity to the artist's account.
                        if (!venueMode)
                          LtRow(
                            icon: Icons.key_rounded,
                            title: s.t('settings.sign_in_methods.row_title'),
                            subtitle: cloudEntry.kind == AccountKind.anonymous
                                ? s.t(
                                    'settings.sign_in_methods.row_subtitle_guest')
                                : s.t('settings.sign_in_methods.row_subtitle'),
                            chevron: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignInMethodsScreen(),
                              ),
                            ),
                          ),
                        // Not on a venue device: Security can mint add-device
                        // codes, and this tablet could confirm its own —
                        // anyone holding it could join THEIR phone to the
                        // artist's account for good. Devices are managed from
                        // the artist's own phone.
                        if (!venueMode)
                          LtRow(
                            icon: Icons.shield_outlined,
                            title: s.t('settings.security.row_title'),
                            subtitle: s.t('settings.security.row_subtitle'),
                            chevron: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SecurityScreen()),
                            ),
                          ),
                        // The way over for a local profile stranded beside
                        // this account. Always here while both coexist — the
                        // sign-in offer is one-shot per profile, and a dialog
                        // that already ran must never be the only door to the
                        // migrator.
                        if (!venueMode && canMoveLocalProfiles)
                          LtRow(
                            icon: Icons.cloud_upload_outlined,
                            title: s.t('settings.account.move_profiles_row'),
                            subtitle:
                                s.t('settings.account.move_profiles_subtitle'),
                            chevron: true,
                            onTap: _confirmMoveLocalProfiles,
                          ),
                        if (!venueMode)
                          LtRow(
                            icon: Icons.logout_rounded,
                            title: s.t('settings.account.sign_out'),
                            subtitle: cloudEntry.kind == AccountKind.anonymous
                                ? s.t(
                                    'settings.account.sign_out_anonymous_warning')
                                : null,
                            chevron: true,
                            onTap: () => confirmSignOut(context, ref),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
