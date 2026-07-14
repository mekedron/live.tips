import 'tip_method.dart';

/// A single tip, derived from a Stripe Checkout Session (one payment made
/// through the artist's payment link), from a card-present Charge (the artist
/// took a contactless tap in person), relayed from a MobilePay/Revolut fan
/// page in connected mode, or synthesized in demo mode.
class Tip {
  const Tip({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
    this.name,
    this.message,
    this.livemode = true,
    this.viaService = true,
    this.paymentIntentId,
    this.method = TipMethod.stripe,
    this.verified = true,
    this.inPerson = false,
    this.songId,
    this.songTitle,
  });

  /// Stable id, used for de-duplication: the Checkout Session id (`cs_…`) for
  /// online tips, the Charge id (`ch_…`) for in-person taps.
  final String id;
  final int amountMinor;
  final String currency;
  final DateTime createdAt;
  final String? name;
  final String? message;
  final bool livemode;

  /// Whether this payment arrived through the live.tips-managed payment link —
  /// recognised by the `managed_by: live.tips` metadata we stamp on every link
  /// we create. False for anything else in the account (a link or Checkout the
  /// artist set up themselves, a manual charge, an invoice), which now shows up
  /// here because History lists the whole account, not just the current link.
  /// Defaults to true: demo tips and everything archived from a live session
  /// came in through our link.
  ///
  /// In-person taps ([inPerson]) keep it true even though they touch no
  /// payment link: the flag exists to mark money live.tips did *not* set out
  /// to collect, and a tap the artist took during a set is not that.
  final bool viaService;

  /// PaymentIntent id (`pi_…`) behind this checkout session, when known.
  /// Absent for demo tips and for tips archived before we started
  /// capturing it. Powers [stripeDashboardUrl].
  final String? paymentIntentId;

  /// How this tip was paid. Everything that predates connected mode is
  /// [TipMethod.stripe] — the default, so old stored history parses as-is.
  final TipMethod method;

  /// Whether the payment is confirmed by a source we trust (Stripe). Relay
  /// tips are fan-declared — the worker can't see the MobilePay/Revolut
  /// ledger — so they arrive unverified.
  final bool verified;

  /// Whether the artist collected this tip in person — a contactless tap on a
  /// Stripe Terminal reader or Tap to Pay in the Stripe Dashboard app. Stripe
  /// saw the card, so it is every bit as [verified] as a QR tip; what it has
  /// no room for is a fan: the tap flow collects an amount and nothing else,
  /// so [name] and [message] are always null. A third kind of tip, then —
  /// verified but nameless — and the tile says so with its own quiet badge
  /// rather than pretending someone typed a name.
  final bool inPerson;

  /// The song this tip requested, when it is a song request (#64): the id the
  /// artist's library minted for it, and the title as the fan page showed it.
  /// The title is stored too — not just looked up — so History still names
  /// the song after the artist deletes it from the library. Null for every
  /// plain tip, and omitted from json so old history stays byte-identical.
  final String? songId;
  final String? songTitle;

  String get displayName {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'Anonymous' : trimmed;
  }

  bool get hasMessage => (message?.trim() ?? '').isNotEmpty;

  /// Deep link to this payment in the artist's own Stripe Dashboard — the
  /// "transaction" page — or null when there's nothing to open (demo tips,
  /// or older records saved before the PaymentIntent id was captured).
  /// Test-mode payments live under the dashboard's `/test/` path.
  String? get stripeDashboardUrl {
    final pi = paymentIntentId;
    if (pi == null || !pi.startsWith('pi_')) return null;
    final mode = livemode ? '' : 'test/';
    return 'https://dashboard.stripe.com/${mode}payments/$pi';
  }

  /// Parses a Checkout Session object (from `/v1/events` payloads or the
  /// `/v1/checkout/sessions` list) into a tip.
  factory Tip.fromCheckoutSession(Map<String, dynamic> session) {
    String? customField(String key) {
      final fields = session['custom_fields'];
      if (fields is! List) return null;
      for (final field in fields) {
        if (field is Map && field['key'] == key) {
          final text = field['text'];
          if (text is Map && text['value'] is String) {
            return text['value'] as String;
          }
        }
      }
      return null;
    }

    final customer = session['customer_details'];
    final customerName = customer is Map ? customer['name'] as String? : null;

    // `payment_intent` is an expandable field: unexpanded (as here) it's the
    // `pi_…` string id; expanded it would be the full object — guard for both.
    final paymentIntent = session['payment_intent'];

    // `payment_link` is expandable too. The Checkout Sessions list expands it
    // (`expand[]=data.payment_link`) so we can read the link's metadata and
    // separate live.tips payments from anything else in the account; the
    // `/v1/events` feed leaves it as the bare `plink_…` id — and only ever for
    // our own link. No link at all means it wasn't one of our checkouts.
    final paymentLink = session['payment_link'];
    final bool viaService;
    if (paymentLink is Map) {
      final metadata = paymentLink['metadata'];
      viaService = metadata is Map && metadata['managed_by'] == 'live.tips';
    } else {
      viaService = paymentLink is String;
    }

    return Tip(
      id: session['id'] as String,
      amountMinor: (session['amount_total'] as num?)?.toInt() ?? 0,
      currency: (session['currency'] as String? ?? 'usd').toLowerCase(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((session['created'] as num?)?.toInt() ?? 0) * 1000,
      ),
      name: customField('nickname') ?? customerName,
      message: customField('message'),
      livemode: session['livemode'] as bool? ?? true,
      viaService: viaService,
      paymentIntentId: paymentIntent is String
          ? paymentIntent
          : (paymentIntent is Map ? paymentIntent['id'] as String? : null),
    );
  }

  /// Whether this Charge object is an in-person card payment — the one thing
  /// that separates a tap the artist took at the front of the stage from the
  /// charge that Stripe *also* creates behind every QR checkout.
  ///
  /// A Charge names the payment method it was taken with in
  /// `payment_method_details.type`; `card_present` is the value Stripe uses for
  /// Terminal readers and Tap to Pay (an online card checkout says `card`).
  /// The check is on the discriminator itself, not on the presence of the
  /// `payment_method_details.card_present` hash, so nothing else in the account
  /// can drift into the jar. See https://docs.stripe.com/api/charges/object.
  ///
  /// `status`/`paid` guard the rest: `charge.succeeded` only fires for a
  /// successful charge, but a failed or unpaid object must never reach the jar
  /// even if Stripe's event stream one day says otherwise.
  static bool isCardPresentCharge(Map<String, dynamic> charge) {
    final details = charge['payment_method_details'];
    if (details is! Map || details['type'] != 'card_present') return false;
    if (charge['status'] != 'succeeded') return false;
    return charge['paid'] == true;
  }

  /// An in-person contactless tip, parsed from a card-present Charge object
  /// (from the `/v1/events` feed). No name, no message: the reader asked for
  /// an amount and nothing else. Guard every call with [isCardPresentCharge] —
  /// a card-not-present Charge is the QR tip we already counted through its
  /// Checkout Session, and constructing one here would double it.
  factory Tip.fromCardPresentCharge(Map<String, dynamic> charge) {
    // `payment_intent` is expandable; unexpanded (as in the events feed) it is
    // the bare `pi_…` id. Same guard as [fromCheckoutSession].
    final paymentIntent = charge['payment_intent'];

    return Tip(
      id: charge['id'] as String,
      amountMinor: (charge['amount'] as num?)?.toInt() ?? 0,
      currency: (charge['currency'] as String? ?? 'usd').toLowerCase(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((charge['created'] as num?)?.toInt() ?? 0) * 1000,
      ),
      // Deliberately no name and no message — see [inPerson]. The Charge does
      // carry `billing_details.name`, but for a tap it is either null or the
      // cardholder name off the chip: not a name the fan chose to give the
      // artist, and not one we will put on a stage.
      livemode: charge['livemode'] as bool? ?? true,
      paymentIntentId: paymentIntent is String
          ? paymentIntent
          : (paymentIntent is Map ? paymentIntent['id'] as String? : null),
      verified: true,
      inPerson: true,
    );
  }

  /// A tip relayed by the connected-mode worker (MobilePay/Revolut). The
  /// payment is fan-declared, hence unverified.
  ///
  /// [relayId] is the relay's own id for this tip, stable across redeliveries:
  /// a tip the relay held while this device was away may be replayed, and the
  /// session dedupes on the tip id to keep it off the stage twice. Older
  /// relays send no id, so fall back to a locally-unique one — [serial]
  /// disambiguates tips that share a millisecond.
  factory Tip.relayTip({
    required int amountMinor,
    required String currency,
    required TipMethod method,
    String? name,
    String? message,
    required int ts,
    required int serial,
    String? relayId,
    String? songId,
    String? songTitle,
  }) =>
      Tip(
        id: relayId == null ? 'relay_${ts}_$serial' : 'relay_$relayId',
        amountMinor: amountMinor,
        currency: currency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
        name: name,
        message: message,
        livemode: true,
        viaService: true,
        method: method,
        verified: false,
        songId: songId,
        songTitle: songTitle,
      );

  Tip copyWith({
    String? id,
    int? amountMinor,
    String? currency,
    DateTime? createdAt,
    String? name,
    String? message,
    bool? livemode,
    bool? viaService,
    String? paymentIntentId,
    TipMethod? method,
    bool? verified,
    bool? inPerson,
    String? songId,
    String? songTitle,
  }) =>
      Tip(
        id: id ?? this.id,
        amountMinor: amountMinor ?? this.amountMinor,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
        name: name ?? this.name,
        message: message ?? this.message,
        livemode: livemode ?? this.livemode,
        viaService: viaService ?? this.viaService,
        paymentIntentId: paymentIntentId ?? this.paymentIntentId,
        method: method ?? this.method,
        verified: verified ?? this.verified,
        inPerson: inPerson ?? this.inPerson,
        songId: songId ?? this.songId,
        songTitle: songTitle ?? this.songTitle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMinor': amountMinor,
        'currency': currency,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (name != null) 'name': name,
        if (message != null) 'message': message,
        'livemode': livemode,
        'viaService': viaService,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        // Written only when non-default so pre-connected-mode history stays
        // byte-identical on re-save.
        if (method != TipMethod.stripe) 'method': method.wire,
        if (!verified) 'verified': verified,
        if (inPerson) 'inPerson': inPerson,
        if (songId != null) 'songId': songId,
        if (songTitle != null) 'songTitle': songTitle,
      };

  factory Tip.fromJson(Map<String, dynamic> json) => Tip(
        id: json['id'] as String,
        amountMinor: (json['amountMinor'] as num).toInt(),
        currency: json['currency'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num).toInt(),
        ),
        name: json['name'] as String?,
        message: json['message'] as String?,
        livemode: json['livemode'] as bool? ?? true,
        viaService: json['viaService'] as bool? ?? true,
        paymentIntentId: json['paymentIntentId'] as String?,
        method: TipMethod.fromWire(json['method'] as String?) ??
            TipMethod.stripe,
        verified: json['verified'] as bool? ?? true,
        inPerson: json['inPerson'] as bool? ?? false,
        songId: json['songId'] as String?,
        songTitle: json['songTitle'] as String?,
      );
}
