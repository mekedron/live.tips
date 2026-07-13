/// The artist's connected-mode jar registered with the live.tips relay:
/// a public fan page URL plus the payment methods it offers. The jar secret
/// is NEVER stored here — it lives in the SecureStore only.
class RelayJar {
  const RelayJar({
    required this.jarId,
    required this.tipUrl,
    required this.artistName,
    required this.currency,
    this.message,
    this.revolutUsername,
    this.mobilepayBoxId,
    this.monzoUsername,
    required this.createdAtMs,
  });

  final String jarId;

  /// Public `https://tip.live.tips/t/<jarId>` URL — what goes on the QR code
  /// in connected mode. Minted by the relay, never assembled on the device:
  /// the server owns the host.
  final String tipUrl;
  final String artistName;
  final String currency;

  /// The artist's thank-you / welcome message shown on the fan page. The
  /// tip-page equivalent of the Stripe link's thank-you message; edited from
  /// Account Details. Null/empty means the fan page shows no message line.
  final String? message;
  final String? revolutUsername;
  final String? mobilepayBoxId;
  final String? monzoUsername;
  final int createdAtMs;

  bool get hasRevolut => (revolutUsername?.trim() ?? '').isNotEmpty;

  bool get hasMobilePay => (mobilepayBoxId?.trim() ?? '').isNotEmpty;

  bool get hasMonzo => (monzoUsername?.trim() ?? '').isNotEmpty;

  static const demo = RelayJar(
    jarId: 'demo',
    tipUrl: 'https://tip.live.tips/t/demo',
    artistName: 'Demo Artist',
    currency: 'usd',
    revolutUsername: 'demo',
    mobilepayBoxId: null,
    monzoUsername: null,
    createdAtMs: 0,
  );

  RelayJar copyWith({
    String? jarId,
    String? tipUrl,
    String? artistName,
    String? currency,
    String? message,
    String? revolutUsername,
    String? mobilepayBoxId,
    String? monzoUsername,
    int? createdAtMs,
  }) =>
      RelayJar(
        jarId: jarId ?? this.jarId,
        tipUrl: tipUrl ?? this.tipUrl,
        artistName: artistName ?? this.artistName,
        currency: currency ?? this.currency,
        message: message ?? this.message,
        revolutUsername: revolutUsername ?? this.revolutUsername,
        mobilepayBoxId: mobilepayBoxId ?? this.mobilepayBoxId,
        monzoUsername: monzoUsername ?? this.monzoUsername,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );

  Map<String, dynamic> toJson() => {
        'jarId': jarId,
        'tipUrl': tipUrl,
        'artistName': artistName,
        'currency': currency,
        if (message != null) 'message': message,
        if (revolutUsername != null) 'revolutUsername': revolutUsername,
        if (mobilepayBoxId != null) 'mobilepayBoxId': mobilepayBoxId,
        if (monzoUsername != null) 'monzoUsername': monzoUsername,
        'createdAtMs': createdAtMs,
      };

  factory RelayJar.fromJson(Map<String, dynamic> json) => RelayJar(
        jarId: json['jarId'] as String,
        tipUrl: json['tipUrl'] as String,
        artistName: json['artistName'] as String? ?? '',
        currency: json['currency'] as String? ?? 'usd',
        message: json['message'] as String?,
        revolutUsername: json['revolutUsername'] as String?,
        mobilepayBoxId: json['mobilepayBoxId'] as String?,
        monzoUsername: json['monzoUsername'] as String?,
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}
