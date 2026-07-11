import '../../../domain/donation.dart';
import '../../../state/live_session_controller.dart';

/// Immutable value snapshot of everything a stage renders. Built fresh from
/// [LiveState] on every rebuild; stages diff by FIELDS (the controller
/// mutates the same LiveSession instance, so object identity means nothing).
class StageSnapshot {
  const StageSnapshot({
    required this.totalMinor,
    required this.goalMinor,
    required this.currentJarMinor,
    required this.bankedMinor,
    required this.bankedJars,
    required this.jarPct,
    required this.count,
    required this.currency,
    required this.goalReached,
    this.approximateTotal = false,
    this.lastDonation,
    this.biggest,
    this.recentDonations = const [],
  });

  final int totalMinor;
  final int goalMinor;
  final int currentJarMinor;
  final int bankedMinor;
  final int bankedJars;

  /// Current-jar fill in [0, 2) of the goal (post eager rollover banking).
  final double jarPct;
  final int count;
  final String currency;
  final bool goalReached;

  /// The set mixed currencies, so [totalMinor] is a converted approximation.
  final bool approximateTotal;
  final Donation? lastDonation;
  final Donation? biggest;

  /// Latest first, capped — for the feed / mini-feed.
  final List<Donation> recentDonations;

  factory StageSnapshot.fromState(LiveState live) {
    final s = live.session;
    return StageSnapshot(
      totalMinor: s.totalMinor,
      goalMinor: s.goalMinor,
      currentJarMinor: s.currentJarMinor,
      bankedMinor: s.bankedMinor,
      bankedJars: s.bankedJars,
      jarPct: s.jarPct,
      count: s.count,
      currency: s.currency,
      goalReached: s.goalReached,
      approximateTotal: s.isMixedCurrency,
      lastDonation: live.lastDonation,
      biggest: s.biggest,
      recentDonations: s.donations.reversed.take(14).toList(),
    );
  }

  /// Clamped 0..1 progress for the classic goal bar.
  double get progress =>
      goalMinor <= 0 ? 0 : (totalMinor / goalMinor).clamp(0.0, 1.0).toDouble();

  @override
  bool operator ==(Object other) =>
      other is StageSnapshot &&
      other.totalMinor == totalMinor &&
      other.goalMinor == goalMinor &&
      other.bankedMinor == bankedMinor &&
      other.bankedJars == bankedJars &&
      other.count == count &&
      other.currency == currency &&
      other.lastDonation?.id == lastDonation?.id;

  @override
  int get hashCode => Object.hash(totalMinor, goalMinor, bankedMinor,
      bankedJars, count, currency, lastDonation?.id);
}
