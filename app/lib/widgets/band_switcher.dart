import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/band_account.dart';
import '../features/onboarding/method_select_screen.dart';
import '../state/live_session_controller.dart';
import '../state/providers.dart';
import 'lt_ui.dart';

/// The label under a band row: which payment methods it has configured,
/// read straight from the band's stored jars (cheap prefs lookups).
String bandMethodsSummary(WidgetRef ref, String accountId) {
  final store = ref.read(localStoreProvider);
  final tipJar = store.readTipJar(accountId);
  final relayJar = store.readRelayJar(accountId);
  final methods = <String>[
    if (tipJar != null) 'Stripe',
    if (relayJar?.hasRevolut ?? false) 'Revolut',
    if (relayJar?.hasMobilePay ?? false) 'MobilePay',
  ];
  return methods.isEmpty ? 'Not set up yet' : methods.join(' · ');
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
    final name =
        app.displayName.isEmpty ? 'Your band' : app.displayName;
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
                  child: Icon(Icons.expand_more_rounded,
                      size: fontSize * 0.8, color: c.textMuted),
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
    final name = app.displayName.isEmpty ? 'New band' : app.displayName;
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
                  style: outfitStyle(13, c.textSecondary,
                      weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 16, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switcher: every band on this device plus "Add a band". Switching is
/// blocked (rows greyed, hint shown) while a live session runs — a session
/// is bound to its band's key and relay socket.
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
      BuildContext context, WidgetRef ref, BandAccount account) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(appStateProvider.notifier)
        .switchAccount(account.id);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Stop the live session before switching bands.')));
      return;
    }
    // Only close the sheet if it is still up — the user may have swiped it
    // away during the keychain read, and popping then would eat whatever
    // route sits underneath.
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _addBand(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final account = await ref.read(appStateProvider.notifier).addAccount();
    if (account == null) return;
    if (context.mounted) Navigator.of(context).pop();
    // The new empty band is active now; the method-select step starts its
    // onboarding, and RootGate (welcome, behind this route) is the fallback
    // if the user backs out.
    rootNavigator.push(
      MaterialPageRoute(builder: (_) => const MethodSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
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
              child: Text('Your bands',
                  style: outfitStyle(18, c.text, weight: FontWeight.w700)),
            ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  live != null
                      ? 'A live session is running — stop it to switch bands.'
                      : 'Switching…',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12.5,
                      color: c.textMuted),
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
            _AddBandRow(
              enabled: !blocked,
              onTap: () => _addBand(context, ref),
            ),
          ],
        ),
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
    final name = account.name.isEmpty ? 'Unnamed band' : account.name;
    final subtitle = bandMethodsSummary(ref, account.id);
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        style: outfitStyle(15, c.text,
                            weight:
                                active ? FontWeight.w700 : FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 12.5,
                            color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Icon(Icons.check_circle_rounded,
                      size: 22, color: c.accent),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: c.accentSoft, shape: BoxShape.circle),
                  child: Icon(Icons.add_rounded, size: 22, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a band',
                          style: outfitStyle(15, c.text,
                              weight: FontWeight.w600)),
                      Text(
                        'Another act with its own links, goal and history.',
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 12.5,
                            color: c.textSecondary),
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
