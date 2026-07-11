import 'tip.dart';

/// How one tip played out against the jar, computed at receipt time by
/// [LiveSession.addTipAttributed]. The stage renderers consume this
/// verbatim: pour `deltaPct`, retire `rollovers` full jars, land the fresh
/// jar at `jarPctAfter`. Money truth never leaves Dart — the renderer only
/// receives goal fractions.
class JarTipAttribution {
  const JarTipAttribution({
    required this.tip,
    required this.deltaPct,
    required this.jarPctAfter,
    required this.rollovers,
    required this.bankedJarsAfter,
  });

  final Tip tip;

  /// amountMinor / goalMinor at the moment the tip arrived.
  final double deltaPct;

  /// Fill of the (possibly fresh) jar after banking, in [0, 2) of the goal.
  final double jarPctAfter;

  /// Whole jars this tip filled to the 2×-goal brim (usually 0).
  final int rollovers;

  /// Trophy count after this tip.
  final int bankedJarsAfter;
}
