import 'package:flutter/widgets.dart';

/// How many modal/popup routes currently cover the live stage. While this is
/// > 0 the web stage makes its `<iframe>` inert (pointer-events: none), so the
/// modal — barrier and all — stays fully clickable over the jar. On Flutter
/// Web the iframe is a real DOM element that otherwise swallows every tap that
/// lands on it, which is why sheets/dialogs shown over the stage go dead. Back
/// to 0 and the jar regains its drag-to-orbit.
///
/// The always-present floating controls (they must stay tappable *while* the
/// jar is interactive) are handled separately by wrapping them in a
/// `PointerInterceptor`; this notifier is only for the full-screen modals.
final ValueNotifier<int> stageOverlayDepth = ValueNotifier<int>(0);

/// Counts modal/popup routes pushed on top of the stage. Registered on the
/// app's root navigator (tabs are an IndexedStack, not nested navigators, so
/// there is exactly one) — it therefore sees every bottom sheet and dialog.
/// Page navigations don't count: a [PageRoute] is not a [PopupRoute].
class StageOverlayObserver extends NavigatorObserver {
  void _bump(Route<dynamic>? route, int delta) {
    if (route is PopupRoute) {
      final next = stageOverlayDepth.value + delta;
      stageOverlayDepth.value = next < 0 ? 0 : next;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _bump(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _bump(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _bump(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _bump(oldRoute, -1);
    _bump(newRoute, 1);
  }
}
