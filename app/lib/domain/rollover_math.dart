import 'donation.dart';

/// How one donation played out against the jar, computed at receipt time by
/// [LiveSession.addDonationAttributed]. The stage renderers consume this
/// verbatim: pour `deltaPct`, retire `rollovers` full jars, land the fresh
/// jar at `jarPctAfter`. Money truth never leaves Dart — the renderer only
/// receives goal fractions.
class JarTipAttribution {
  const JarTipAttribution({
    required this.donation,
    required this.deltaPct,
    required this.jarPctAfter,
    required this.rollovers,
    required this.bankedJarsAfter,
  });

  final Donation donation;

  /// amountMinor / goalMinor at the moment the donation arrived.
  final double deltaPct;

  /// Fill of the (possibly fresh) jar after banking, in [0, 2) of the goal.
  final double jarPctAfter;

  /// Whole jars this donation filled to the 2×-goal brim (usually 0).
  final int rollovers;

  /// Trophy count after this donation.
  final int bankedJarsAfter;
}
