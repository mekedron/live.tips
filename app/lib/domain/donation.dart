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
  });

  /// Checkout Session id (`cs_…`) — stable, used for de-duplication.
  final String id;
  final int amountMinor;
  final String currency;
  final DateTime createdAt;
  final String? name;
  final String? message;
  final bool livemode;

  String get displayName {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'Anonymous' : trimmed;
  }

  bool get hasMessage => (message?.trim() ?? '').isNotEmpty;

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
      );
}
