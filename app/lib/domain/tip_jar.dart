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
  });

  final String productId;
  final String priceId;
  final String paymentLinkId;

  /// Public `https://buy.stripe.com/…` URL — this is what goes on the QR code.
  final String url;
  final String currency;
  final String displayName;
  final bool livemode;

  bool get isDemo => paymentLinkId == 'demo';

  static const demo = TipJar(
    productId: 'demo',
    priceId: 'demo',
    paymentLinkId: 'demo',
    url: 'https://live.tips/demo',
    currency: 'usd',
    displayName: 'Demo Artist',
    livemode: false,
  );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'priceId': priceId,
        'paymentLinkId': paymentLinkId,
        'url': url,
        'currency': currency,
        'displayName': displayName,
        'livemode': livemode,
      };

  factory TipJar.fromJson(Map<String, dynamic> json) => TipJar(
        productId: json['productId'] as String,
        priceId: json['priceId'] as String,
        paymentLinkId: json['paymentLinkId'] as String,
        url: json['url'] as String,
        currency: json['currency'] as String,
        displayName: json['displayName'] as String? ?? '',
        livemode: json['livemode'] as bool? ?? true,
      );
}
