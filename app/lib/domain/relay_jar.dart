/// The artist's connected-mode jar registered with the live.tips relay
/// worker: a public donor page URL plus the payment methods it offers.
/// The jar secret is NEVER stored here — it lives in the SecureStore only.
class RelayJar {
  const RelayJar({
    required this.jarId,
    required this.donateUrl,
    required this.artistName,
    required this.currency,
    this.revolutUsername,
    this.mobilepayBoxId,
    required this.createdAtMs,
  });

  final String jarId;

  /// Public `https://live.tips/t/<jarId>` URL — what goes on the QR code in
  /// connected mode.
  final String donateUrl;
  final String artistName;
  final String currency;
  final String? revolutUsername;
  final String? mobilepayBoxId;
  final int createdAtMs;

  bool get hasRevolut => (revolutUsername?.trim() ?? '').isNotEmpty;

  bool get hasMobilePay => (mobilepayBoxId?.trim() ?? '').isNotEmpty;

  static const demo = RelayJar(
    jarId: 'demo',
    donateUrl: 'https://live.tips/t/demo',
    artistName: 'Demo Artist',
    currency: 'usd',
    revolutUsername: 'demo',
    mobilepayBoxId: null,
    createdAtMs: 0,
  );

  RelayJar copyWith({
    String? jarId,
    String? donateUrl,
    String? artistName,
    String? currency,
    String? revolutUsername,
    String? mobilepayBoxId,
    int? createdAtMs,
  }) =>
      RelayJar(
        jarId: jarId ?? this.jarId,
        donateUrl: donateUrl ?? this.donateUrl,
        artistName: artistName ?? this.artistName,
        currency: currency ?? this.currency,
        revolutUsername: revolutUsername ?? this.revolutUsername,
        mobilepayBoxId: mobilepayBoxId ?? this.mobilepayBoxId,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );

  Map<String, dynamic> toJson() => {
        'jarId': jarId,
        'donateUrl': donateUrl,
        'artistName': artistName,
        'currency': currency,
        if (revolutUsername != null) 'revolutUsername': revolutUsername,
        if (mobilepayBoxId != null) 'mobilepayBoxId': mobilepayBoxId,
        'createdAtMs': createdAtMs,
      };

  factory RelayJar.fromJson(Map<String, dynamic> json) => RelayJar(
        jarId: json['jarId'] as String,
        donateUrl: json['donateUrl'] as String,
        artistName: json['artistName'] as String? ?? '',
        currency: json['currency'] as String? ?? 'usd',
        revolutUsername: json['revolutUsername'] as String?,
        mobilepayBoxId: json['mobilepayBoxId'] as String?,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}
