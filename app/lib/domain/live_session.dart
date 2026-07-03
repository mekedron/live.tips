import 'donation.dart';

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
  }) : donations = List.of(donations ?? const []);

  final String id;
  final DateTime startedAt;
  DateTime? endedAt;
  final String currency;

  /// Editable mid-session ("let's push for €300 tonight!").
  int goalMinor;

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

  /// Adds a donation if we haven't seen its id yet. Returns true when added.
  bool addDonation(Donation donation) {
    if (_ids.isEmpty && donations.isNotEmpty) {
      _ids.addAll(donations.map((d) => d.id));
    }
    if (!_ids.add(donation.id)) return false;
    donations.add(donation);
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.millisecondsSinceEpoch,
        if (endedAt != null) 'endedAt': endedAt!.millisecondsSinceEpoch,
        'currency': currency,
        'goalMinor': goalMinor,
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
        donations: (json['donations'] as List? ?? const [])
            .map((d) => Donation.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}
