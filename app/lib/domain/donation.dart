import 'tip_method.dart';

/// A single tip, derived from a Stripe Checkout Session (one payment made
/// through the artist's payment link), relayed from a MobilePay/Revolut
/// donor page in connected mode, or synthesized in demo mode.
class Donation {
  const Donation({
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
  });

  /// Checkout Session id (`cs_…`) — stable, used for de-duplication.
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
  final bool viaService;

  /// PaymentIntent id (`pi_…`) behind this checkout session, when known.
  /// Absent for demo tips and for donations archived before we started
  /// capturing it. Powers [stripeDashboardUrl].
  final String? paymentIntentId;

  /// How this tip was paid. Everything that predates connected mode is
  /// [TipMethod.stripe] — the default, so old stored history parses as-is.
  final TipMethod method;

  /// Whether the payment is confirmed by a source we trust (Stripe). Relay
  /// tips are donor-declared — the worker can't see the MobilePay/Revolut
  /// ledger — so they arrive unverified.
  final bool verified;

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
  /// `/v1/checkout/sessions` list) into a donation.
  factory Donation.fromCheckoutSession(Map<String, dynamic> session) {
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

    return Donation(
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

  /// A tip relayed by the connected-mode worker (MobilePay/Revolut). The id
  /// is only locally unique — [serial] disambiguates tips sharing the same
  /// millisecond — and the payment is donor-declared, hence unverified.
  factory Donation.relayTip({
    required int amountMinor,
    required String currency,
    required TipMethod method,
    String? name,
    String? message,
    required int ts,
    required int serial,
  }) =>
      Donation(
        id: 'relay_${ts}_$serial',
        amountMinor: amountMinor,
        currency: currency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
        name: name,
        message: message,
        livemode: true,
        viaService: true,
        method: method,
        verified: false,
      );

  Donation copyWith({
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
  }) =>
      Donation(
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
      };

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
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
      );
}
