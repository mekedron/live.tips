import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'providers.dart';

/// WHOSE profiles the app is showing, and WHICH one of them — the world every
/// root of this app is a picture of.
///
/// The account is the cloud account in use (or the local mode, which is not an
/// account but is the same kind of answer to "whose"); the profile is the band
/// open inside it, and it is empty exactly where RootGate has no band to build
/// the shell around. Between them they say which of RootGate's screens is on
/// the bottom of the stack and what it is about — and neither of them moves
/// unless the artist signed in, signed out, switched account, switched profile,
/// created one or deleted one. Nothing else in the app changes this pair.
@immutable
class RootWorld {
  const RootWorld({required this.accountId, required this.profileId});

  /// The cloud account in use, or [kLocalAccountId] for the device's own mode.
  final String accountId;

  /// The band open in it. Empty means the profile question is still open —
  /// RootGate's band-less roots.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is RootWorld &&
      other.accountId == accountId &&
      other.profileId == profileId;

  @override
  int get hashCode => Object.hash(accountId, profileId);

  @override
  String toString() => 'RootWorld($accountId/$profileId)';
}

final rootWorldProvider = Provider<RootWorld>((ref) => RootWorld(
      accountId: ref.watch(
        accountsDirectoryProvider.select((d) => d.activeAccountId),
      ),
      profileId: ref.watch(appStateProvider.select((a) => a.accountId)),
    ));

/// A route pushed OVER the root — and told when the root flips (#48).
///
/// The rule, and it is one rule for the whole class: **a route pushed over the
/// root describes the world it was pushed over, and when that world is gone the
/// route goes with it.** It does not get to re-render against whatever world
/// happens to be active now, because nobody navigated it there.
///
/// The bug that named the class: Settings, pushed over the band-less root
/// (#40's design, and it is right), with the artist tapping Sign out inside it.
/// The root beneath correctly became Welcome — and Settings stayed on top,
/// re-rendered against the LOCAL profile, offering "Delete this profile" for a
/// profile the artist had never navigated to and had not asked about. Settings'
/// own guard (`app.accountId.isEmpty`) is right about the state it was written
/// for; it simply was not the state the artist was in. The third screen in this
/// audit to narrate a root that had already moved (#38, #41), so this fixes the
/// shape rather than the instance: sign-out rebuilds the root, and the routes
/// standing on it are unwound by the same act.
///
/// It unwinds to the root, not just itself: everything above a dead route was
/// pushed FROM it (Settings' own account, security and payment screens), and
/// belongs to the same dead world.
///
/// The routes that must NOT be bound are the ones that BUILD the world instead
/// of describing it — onboarding: "Get started", the account step, the details
/// step that mints the profile as it names it (#44). They deliberately move the
/// root under themselves and carry on; they push plain routes and end with their
/// own `popUntil`. Describe the world → bind. Build it → do not.
class RootBoundRoute<T> extends MaterialPageRoute<T> {
  RootBoundRoute({required WidgetBuilder builder, super.settings})
      : super(
          builder: (context) => _RootBound(
            child: Builder(builder: builder),
          ),
        );
}

class _RootBound extends ConsumerStatefulWidget {
  const _RootBound({required this.child});

  final Widget child;

  @override
  ConsumerState<_RootBound> createState() => _RootBoundState();
}

class _RootBoundState extends ConsumerState<_RootBound> {
  /// The world this route was pushed over. Read in [initState] and NOT with a
  /// lazy `late final`: a lazy field is first evaluated where it is first read,
  /// which would be inside the listener below — i.e. AFTER the flip, against
  /// the world that just replaced it. It would compare the new world with
  /// itself, find them equal, and stand there.
  late final RootWorld _pushedOver;

  @override
  void initState() {
    super.initState();
    _pushedOver = ref.read(rootWorldProvider);
  }

  @override
  Widget build(BuildContext context) {
    // A covered route keeps its state (maintainState), so this listener is
    // alive even under the screens this one pushed — which is what lets the
    // whole stack come down together.
    ref.listen(rootWorldProvider, (_, world) {
      if (world == _pushedOver || !mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
    return widget.child;
  }
}
