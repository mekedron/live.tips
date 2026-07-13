import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many routes sit ON TOP of the root screen right now (0 = the user is
/// looking at RootGate itself; 1+ = an onboarding screen, a sheet, a dialog).
///
/// The one thing anything root-level needs to know before it interrupts the
/// user: a dialog pushed while onboarding is mid-flight lands UNDER the next
/// opaque route that flow pushes, and is never seen at all. Wait for the
/// depth to fall to zero and the offer arrives where it can be answered.
class RouteDepthNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void push() => state = state + 1;

  void pop() {
    if (state > 0) state = state - 1;
  }
}

final routeDepthProvider =
    NotifierProvider<RouteDepthNotifier, int>(RouteDepthNotifier.new);

/// Feeds [routeDepthProvider] from the navigator. Installed once, in the app's
/// `navigatorObservers`; the root route itself is not counted (it has no
/// previous route to come back to).
class RouteDepthObserver extends NavigatorObserver {
  RouteDepthObserver(this._depth);

  final RouteDepthNotifier _depth;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _depth.push();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _depth.pop();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _depth.pop();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // A replace swaps one route for another — the depth is unchanged.
  }
}

final routeDepthObserverProvider = Provider<RouteDepthObserver>(
  (ref) => RouteDepthObserver(ref.read(routeDepthProvider.notifier)),
);
