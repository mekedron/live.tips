import 'donation.dart';
import 'rollover_math.dart';

/// One "set" on stage: from Start to Stop. Collects every donation that
/// arrived while it was running, against an editable goal.
class LiveSession {
  LiveSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.currency,
    required this.goalMinor,
    List<Donation>? donations,
    this.bankedMinor = 0,
    this.bankedJars = 0,
  }) : donations = List.of(donations ?? const []);

  final String id;
  final DateTime startedAt;
  DateTime? endedAt;
  final String currency;

  /// Editable mid-session ("let's push for €300 tonight!").
  int goalMinor;

  /// Money retired into full trophy jars: every time the current jar reaches
  /// 2× the goal it "rolls over" — exactly 2×goal is banked and a fresh jar
  /// starts with the overshoot. Invariant: bankedMinor + currentJarMinor ==
  /// totalMinor, and jarPct stays < 2.0 after [applyRollovers].
  int bankedMinor;

  /// How many jars have been filled to the brim and retired.
  int bankedJars;

  final List<Donation> donations;
  final Set<String> _ids = {};

  bool get isRunning => endedAt == null;
  int get totalMinor =>
      donations.fold(0, (sum, d) => sum + d.amountMinor);
  int get count => donations.length;

  double get progress =>
      goalMinor <= 0 ? 0 : (totalMinor / goalMinor).clamp(0.0, 1.0).toDouble();

  bool get goalReached => goalMinor > 0 && totalMinor >= goalMinor;

  Donation? get biggest => donations.isEmpty
      ? null
      : donations.reduce((a, b) => b.amountMinor > a.amountMinor ? b : a);

  int get averageMinor => count == 0 ? 0 : totalMinor ~/ count;

  Duration elapsed([DateTime? now]) =>
      (endedAt ?? now ?? DateTime.now()).difference(startedAt);

  /// What's in the CURRENT jar (everything not yet retired into trophies).
  int get currentJarMinor => totalMinor - bankedMinor;

  /// Current-jar fill as a fraction of the goal: 1.0 = goal, 2.0 = rollover.
  double get jarPct => goalMinor <= 0
      ? 0
      : (currentJarMinor / goalMinor).clamp(0.0, 2.0).toDouble();

  /// Banks every full 2×goal sitting in the current jar. Runs after each
  /// donation AND after goal edits (lowering the goal can instantly owe
  /// rollovers). Returns how many jars rolled.
  int applyRollovers() {
    if (goalMinor <= 0) return 0;
    var rolled = 0;
    while (totalMinor - bankedMinor >= 2 * goalMinor) {
      bankedMinor += 2 * goalMinor;
      bankedJars++;
      rolled++;
    }
    return rolled;
  }

  /// Adds a donation if we haven't seen its id yet. Returns true when added.
  bool addDonation(Donation donation) {
    if (_ids.isEmpty && donations.isNotEmpty) {
      _ids.addAll(donations.map((d) => d.id));
    }
    if (!_ids.add(donation.id)) return false;
    donations.add(donation);
    return true;
  }

  /// [addDonation] + eager rollover accounting in one step, capturing how the
  /// donation played out for the stage renderers. Null for duplicates.
  JarTipAttribution? addDonationAttributed(Donation donation) {
    if (!addDonation(donation)) return null;
    final deltaPct =
        goalMinor <= 0 ? 0.0 : donation.amountMinor / goalMinor;
    final rolled = applyRollovers();
    return JarTipAttribution(
      donation: donation,
      deltaPct: deltaPct,
      jarPctAfter: jarPct,
      rollovers: rolled,
      bankedJarsAfter: bankedJars,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.millisecondsSinceEpoch,
        if (endedAt != null) 'endedAt': endedAt!.millisecondsSinceEpoch,
        'currency': currency,
        'goalMinor': goalMinor,
        'bankedMinor': bankedMinor,
        'bankedJars': bankedJars,
        'donations': donations.map((d) => d.toJson()).toList(),
      };

  factory LiveSession.fromJson(Map<String, dynamic> json) => LiveSession(
        id: json['id'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['startedAt'] as num).toInt(),
        ),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['endedAt'] as num).toInt()),
        currency: json['currency'] as String,
        goalMinor: (json['goalMinor'] as num).toInt(),
        bankedMinor: (json['bankedMinor'] as num?)?.toInt() ?? 0,
        bankedJars: (json['bankedJars'] as num?)?.toInt() ?? 0,
        donations: (json['donations'] as List? ?? const [])
            .map((d) => Donation.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}
