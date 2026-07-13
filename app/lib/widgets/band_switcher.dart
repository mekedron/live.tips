import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/app_account.dart';
import '../domain/band_account.dart';
import '../features/onboarding/onboarding_details_screen.dart';
import '../features/venue/venue_reapproval_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_providers.dart';
import '../state/live_session_controller.dart';
import '../state/providers.dart';
import 'lt_ui.dart';

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

/// What a profile calls itself: the chosen account name, else the email,
/// else the provider label — and the local profile is always "On this
/// device".
String accountDisplayName(BuildContext context, AppAccount account) {
  if (account.isLocal) {
    return context.s.t('widgets.account_switcher.on_this_device');
  }
  if (account.name.trim().isNotEmpty) return account.name;
  return account.email ?? accountProviderLabel(context, account.kind);
}

/// The label under a band row: which payment methods it has configured,
/// read straight from the band's stored jars (cheap prefs lookups).
String bandMethodsSummary(
  BuildContext context,
  WidgetRef ref,
  String accountId,
) {
  final repo = ref.read(accountDataRepositoryProvider);
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

/// The band name as a tap target with a chevron — tapping opens the
/// switcher sheet. Used in the home headers; [compact] renders the smaller
/// chip used on the side rail, welcome, and jar setup.
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
    // Demo has no real band to switch unless others already exist — the
    // escape hatch back to a real band must stay reachable.
    if (app.demo && app.accounts.length < 2) {
      return Text(name, style: style);
    }
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: InkWell(
        onTap: () => showBandSwitcherSheet(context, ref),
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

/// Small pill naming the active band, opening the switcher — for surfaces
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
        onTap: () => showBandSwitcherSheet(context, ref),
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

/// The message behind a refused add/switch/remove. Every refusal has one:
/// a silent no-op button is a broken button as far as the artist can tell.
String accountBlockMessage(BuildContext context, AccountActionBlock block) =>
    switch (block) {
      AccountActionBlock.switching =>
        context.s.t('widgets.band_switcher.switching'),
      AccountActionBlock.localSession ||
      AccountActionBlock.remoteSession =>
        context.s.t('widgets.profile_switcher.stop_session_switch'),
    };

/// The profile switcher: the profiles of the ACTIVE account, plus "Add a
/// profile". Cloud accounts are deliberately absent — switching accounts is a
/// different decision, made in Settings › Cloud account. Two concepts, two
/// surfaces.
///
/// Switching is blocked (rows greyed, hint shown) while a live session runs —
/// a session is bound to its profile's key and relay socket.
Future<void> showBandSwitcherSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _BandSwitcherSheet(),
  );
}

class _BandSwitcherSheet extends ConsumerWidget {
  const _BandSwitcherSheet();

  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    BandAccount account,
  ) async {
    // The owner's rule for shared devices: changing which profile a venue
    // tablet shows needs a fresh approval from the artist's own phone.
    if (!await ensureVenueReapproval(context, ref)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(appStateProvider.notifier);
    final app = ref.read(appStateProvider);
    final stopSessionMsg = context.s.t(
      'widgets.profile_switcher.stop_session_switch',
    );

    // Leaving a half-finished new profile behind — one that was named on the
    // details step but never got a payment method, and holds no data? It is
    // reachable (the shell's empty-state home) but worthless. Offer to discard
    // it on the way out rather than let unfinished profiles pile up.
    final leavingId = app.accountId;
    final abandoning =
        account.id != leavingId &&
        !app.connected &&
        !ref.read(accountDataRepositoryProvider).accountHasData(leavingId);
    if (abandoning) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.s.t('widgets.profile_switcher.discard_title')),
          content: Text(context.s.t('widgets.profile_switcher.discard_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.s.t('widgets.band_switcher.keep_editing')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.s.t('widgets.band_switcher.discard_switch')),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }

    final ok = await notifier.switchAccount(account.id);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(stopSessionMsg)));
      return;
    }
    // The unfinished account is no longer active — remove it now that we've
    // landed safely on the chosen one.
    if (abandoning) await notifier.removeAccount(leavingId);
    // Only close the sheet if it is still up — the user may have swiped it
    // away during the keychain read, and popping then would eat whatever
    // route sits underneath.
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Adds a profile — or says why it can't. The old silent `return` on a
  /// refusal made "Add a profile" look broken: a dead button, no message, no
  /// clue that a stale session was holding it shut.
  Future<void> _addBand(BuildContext context, WidgetRef ref) async {
    // Creating a profile changes the account's data — on a venue device
    // that, too, waits for the phone's nod.
    if (!await ensureVenueReapproval(context, ref)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final notifier = ref.read(appStateProvider.notifier);
    final block = notifier.accountActionBlock;
    if (block != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(block == AccountActionBlock.switching
            ? context.s.t('widgets.band_switcher.switching')
            : context.s.t('widgets.profile_switcher.stop_session_add')),
      ));
      return;
    }
    final addFailed = context.s.t('widgets.profile_switcher.add_failed');
    final account = await notifier.addAccount();
    if (account == null) {
      messenger.showSnackBar(SnackBar(content: Text(addFailed)));
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
    // The new empty profile is active now; the details step starts its
    // onboarding, and the shell's empty-state home (behind this route) is
    // where the user lands if they back out — never a dead end.
    rootNavigator.push(
      MaterialPageRoute(builder: (_) => const OnboardingDetailsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
    final directory = ref.watch(accountsDirectoryProvider);
    final blocked = live != null || app.switching;

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
                context.s.t('widgets.profile_switcher.title'),
                style: outfitStyle(18, c.text, weight: FontWeight.w700),
              ),
            ),
            // Which ACCOUNT these profiles live under. Informational only —
            // switching accounts is Settings' job, not this sheet's.
            _ActiveProfileHeader(profile: directory.active),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  live != null
                      ? context.s
                          .t('widgets.profile_switcher.live_running_hint')
                      : context.s.t('widgets.band_switcher.switching'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: c.textMuted,
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final account in app.accounts)
                    _BandRow(
                      account: account,
                      active: !app.demo && account.id == app.accountId,
                      enabled: !blocked,
                      onTap: () => _switchTo(context, ref, account),
                    ),
                ],
              ),
            ),
            Divider(height: 16, color: c.divider),
            // Always tappable: a refusal must be able to SAY why (a stale
            // remote session used to make this a dead, silent button).
            _AddBandRow(enabled: true, onTap: () => _addBand(context, ref)),
          ],
        ),
      ),
    );
  }
}

/// The sheet's subheader: the active profile's name plus a small provider
/// pill — so "whose bands am I looking at" answers itself.
class _ActiveProfileHeader extends StatelessWidget {
  const _ActiveProfileHeader({required this.profile});

  final AppAccount profile;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: [
          Icon(
            profile.isLocal ? Icons.smartphone_rounded : Icons.cloud_rounded,
            size: 16,
            color: c.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              accountDisplayName(context, profile),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: outfitStyle(13.5, c.textSecondary, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          LtPill(
            label: accountProviderLabel(context, profile.kind),
            soft: false,
          ),
        ],
      ),
    );
  }
}

class _BandRow extends ConsumerWidget {
  const _BandRow({
    required this.account,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final BandAccount account;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final name = account.name.isEmpty
        ? context.s.t('widgets.profile_switcher.unnamed')
        : account.name;
    final subtitle = bandMethodsSummary(context, ref, account.id);
    final dim = enabled ? 1.0 : 0.45;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !active ? onTap : null,
        child: Opacity(
          opacity: dim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: name,
                  anonymous: account.name.isEmpty,
                  size: 38,
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
                          15,
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
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Icon(Icons.check_circle_rounded, size: 22, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBandRow extends StatelessWidget {
  const _AddBandRow({required this.enabled, required this.onTap});

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
                        context.s.t('widgets.profile_switcher.add'),
                        style: outfitStyle(15, c.text, weight: FontWeight.w600),
                      ),
                      Text(
                        context.s.t(
                          'widgets.profile_switcher.add_subtitle',
                        ),
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
