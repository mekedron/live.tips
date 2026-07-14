import 'tip.dart';
import 'fx_rates.dart';
import 'rollover_math.dart';

/// One "set" on stage: from Start to Stop. Collects every tip that
/// arrived while it was running, against an editable goal.
class LiveSession {
  LiveSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.currency,
    required this.goalMinor,
    List<Tip>? tips,
    this.bankedMinor = 0,
    this.bankedJars = 0,
    this.requestsOpen = false,
    Map<String, String>? songStatuses,
  })  : tips = List.of(tips ?? const []),
        _songStatuses = {...?songStatuses};

  /// A song request marked as performed / passed over (#64). Absent from
  /// [songStatuses] means queued — the default every request starts in.
  static const statusPlayed = 'p';
  static const statusSkipped = 'k';

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

  /// Whether this set is taking song requests RIGHT NOW (#64) — the artist's
  /// mid-session pause/resume, distinct from the band's master toggle in
  /// settings. Rides the session json so it survives a crash resume.
  bool requestsOpen;

  /// Per-song request status: songId → [statusPlayed] | [statusSkipped].
  /// A song absent here is queued. Kept sparse on purpose: "queued" is not
  /// stored, so the map stays empty for the overwhelmingly common set.
  final Map<String, String> _songStatuses;

  /// Read-only view — mutate through [setSongStatus]/[clearSongStatus] so
  /// every write path stays in one place.
  Map<String, String> get songStatuses => Map.unmodifiable(_songStatuses);

  /// Marks a song played/skipped. Anything but the two known statuses is
  /// dropped — a garbled remote value must not poison the map.
  void setSongStatus(String songId, String status) {
    if (status != statusPlayed && status != statusSkipped) return;
    _songStatuses[songId] = status;
  }

  /// Back to queued (the artist un-sinks a card).
  void clearSongStatus(String songId) => _songStatuses.remove(songId);

  /// Replaces the whole status map — the remote-wins path when another
  /// device's edit lands. Unknown status values are dropped per entry.
  void replaceSongStatuses(Map<String, String> statuses) {
    _songStatuses
      ..clear()
      ..addAll({
        for (final e in statuses.entries)
          if (e.value == statusPlayed || e.value == statusSkipped)
            e.key: e.value,
      });
  }

  final List<Tip> tips;
  final Set<String> _ids = {};

  /// Rates for adding up tips paid in a currency other than [currency] — a £5
  /// Monzo tip on a EUR jar. Injected by the live controller, never persisted
  /// (rates are refetched, and a stored one would silently go stale). Null,
  /// or missing a currency, means such tips are shown but not counted: see
  /// [uncountedTips]. Tips in [currency] never need it.
  FxRates? fx;

  bool get isRunning => endedAt == null;

  /// A tip's amount expressed in the session's currency. Null when it was
  /// paid in another currency and no rate is available to bring it over.
  int? amountInSessionCurrency(Tip d) =>
      d.currency.toLowerCase() == currency.toLowerCase()
      ? d.amountMinor
      : fx?.convertMinor(d.amountMinor, d.currency, currency);

  /// Tips that arrived in a currency we can't convert, so they're absent from
  /// [totalMinor]. Not silent: the stage and history flag them rather than
  /// fold a £ into a € and call it a total.
  List<Tip> get uncountedTips =>
      [for (final d in tips) if (amountInSessionCurrency(d) == null) d];

  /// True once any tip needed converting — the cue to show totals as "≈".
  bool get isMixedCurrency =>
      tips.any((d) => d.currency.toLowerCase() != currency.toLowerCase());

  int get totalMinor =>
      tips.fold(0, (sum, d) => sum + (amountInSessionCurrency(d) ?? 0));
  int get count => tips.length;

  double get progress =>
      goalMinor <= 0 ? 0 : (totalMinor / goalMinor).clamp(0.0, 1.0).toDouble();

  bool get goalReached => goalMinor > 0 && totalMinor >= goalMinor;

  /// Compared in the session's currency, so a £5 tip doesn't out-rank a €6 one
  /// just because 5 < 6 is evaluated on raw minor units.
  Tip? get biggest => tips.isEmpty
      ? null
      : tips.reduce(
          (a, b) =>
              (amountInSessionCurrency(b) ?? 0) > (amountInSessionCurrency(a) ?? 0)
              ? b
              : a,
        );

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
  /// tip AND after goal edits (lowering the goal can instantly owe
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

  /// Adds a tip if we haven't seen its id yet. Returns true when added.
  bool addTip(Tip tip) {
    if (_ids.isEmpty && tips.isNotEmpty) {
      _ids.addAll(tips.map((d) => d.id));
    }
    if (!_ids.add(tip.id)) return false;
    tips.add(tip);
    return true;
  }

  /// [addTip] + eager rollover accounting in one step, capturing how the
  /// tip played out for the stage renderers. Null for duplicates.
  JarTipAttribution? addTipAttributed(Tip tip) {
    if (!addTip(tip)) return null;
    final deltaPct =
        goalMinor <= 0 ? 0.0 : tip.amountMinor / goalMinor;
    final rolled = applyRollovers();
    return JarTipAttribution(
      tip: tip,
      deltaPct: deltaPct,
      jarPctAfter: jarPct,
      rollovers: rolled,
      bankedJarsAfter: bankedJars,
    );
  }

  /// Swaps a tip already in the session for [tip] (matched by id), keeping
  /// its position; `_ids` stays consistent because the id is the match key.
  /// No-op (false) for an unknown id — an update for a tip we never had is
  /// not an insert. This is how "verified elsewhere" reaches a session copy.
  bool replaceTip(Tip tip) {
    for (var i = 0; i < tips.length; i++) {
      if (tips[i].id == tip.id) {
        tips[i] = tip;
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.millisecondsSinceEpoch,
        if (endedAt != null) 'endedAt': endedAt!.millisecondsSinceEpoch,
        'currency': currency,
        'goalMinor': goalMinor,
        'bankedMinor': bankedMinor,
        'bankedJars': bankedJars,
        // Written only when set so a pre-requests session re-saves
        // byte-identically (pinned by a test, like Tip.toJson's song keys).
        if (requestsOpen) 'requestsOpen': true,
        if (_songStatuses.isNotEmpty) 'songStatuses': {..._songStatuses},
        'tips': tips.map((d) => d.toJson()).toList(),
      };

  /// Restores a stored session.
  ///
  /// A blob written by an older build has no `tips` key at all. That is not an
  /// error to us: the session loads with an empty tip list rather than
  /// throwing, so a stale blob on disk can never take the app down on boot.
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
        requestsOpen: json['requestsOpen'] == true,
        songStatuses: json['songStatuses'] is Map
            ? {
                for (final e in (json['songStatuses'] as Map).entries)
                  if (e.key is String &&
                      (e.value == statusPlayed || e.value == statusSkipped))
                    e.key as String: e.value as String,
              }
            : null,
        tips: (json['tips'] as List? ?? const [])
            .map((d) => Tip.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}
