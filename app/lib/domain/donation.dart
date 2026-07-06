/// A single tip, derived from a Stripe Checkout Session (one payment made
/// through the artist's payment link) or synthesized in demo mode.
class Donation {
  const Donation({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
    this.name,
    this.message,
    this.livemode = true,
    this.paymentIntentId,
  });

  /// Checkout Session id (`cs_…`) — stable, used for de-duplication.
  final String id;
  final int amountMinor;
  final String currency;
  final DateTime createdAt;
  final String? name;
  final String? message;
  final bool livemode;

  /// PaymentIntent id (`pi_…`) behind this checkout session, when known.
  /// Absent for demo tips and for donations archived before we started
  /// capturing it. Powers [stripeDashboardUrl].
  final String? paymentIntentId;

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
      paymentIntentId: paymentIntent is String
          ? paymentIntent
          : (paymentIntent is Map ? paymentIntent['id'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMinor': amountMinor,
        'currency': currency,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (name != null) 'name': name,
        if (message != null) 'message': message,
        'livemode': livemode,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
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
        paymentIntentId: json['paymentIntentId'] as String?,
      );
}
