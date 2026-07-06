/// The artist's tip jar: one Product + pay-what-you-want Price + Payment Link
/// created in *their* Stripe account. We only store the ids and public URL.
class TipJar {
  const TipJar({
    required this.productId,
    required this.priceId,
    required this.paymentLinkId,
    required this.url,
    required this.currency,
    required this.displayName,
    required this.livemode,
    this.thankYouMessage = 'Thank you! 💛',
  });

  final String productId;
  final String priceId;
  final String paymentLinkId;

  /// Public `https://buy.stripe.com/…` URL — this is what goes on the QR code.
  final String url;
  final String currency;
  final String displayName;
  final bool livemode;

  /// The message fans see after tipping (Stripe's hosted confirmation
  /// page). Stored locally too — Stripe doesn't hand it back on read — so
  /// [JarSetupScreen] can prefill it when recreating the link.
  final String thankYouMessage;

  bool get isDemo => paymentLinkId == 'demo';

  /// The artist's own Stripe Dashboard, opened to the full payments list —
  /// every transaction in the account, across all of their payment links.
  /// Test-mode keys live under the dashboard's `/test/` path.
  String get stripePaymentsUrl =>
      'https://dashboard.stripe.com/${livemode ? '' : 'test/'}payments';

  static const demo = TipJar(
    productId: 'demo',
    priceId: 'demo',
    paymentLinkId: 'demo',
    url: 'https://live.tips/demo',
    currency: 'usd',
    displayName: 'Demo Artist',
    livemode: false,
    thankYouMessage: 'Thank you for supporting live music! 🎶',
  );

  TipJar copyWith({
    String? productId,
    String? priceId,
    String? paymentLinkId,
    String? url,
    String? currency,
    String? displayName,
    bool? livemode,
    String? thankYouMessage,
  }) =>
      TipJar(
        productId: productId ?? this.productId,
        priceId: priceId ?? this.priceId,
        paymentLinkId: paymentLinkId ?? this.paymentLinkId,
        url: url ?? this.url,
        currency: currency ?? this.currency,
        displayName: displayName ?? this.displayName,
        livemode: livemode ?? this.livemode,
        thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'priceId': priceId,
        'paymentLinkId': paymentLinkId,
        'url': url,
        'currency': currency,
        'displayName': displayName,
        'livemode': livemode,
        'thankYouMessage': thankYouMessage,
      };

  factory TipJar.fromJson(Map<String, dynamic> json) => TipJar(
        productId: json['productId'] as String,
        priceId: json['priceId'] as String,
        paymentLinkId: json['paymentLinkId'] as String,
        url: json['url'] as String,
        currency: json['currency'] as String,
        displayName: json['displayName'] as String? ?? '',
        livemode: json['livemode'] as bool? ?? true,
        thankYouMessage: json['thankYouMessage'] as String? ?? 'Thank you! 💛',
      );
}
