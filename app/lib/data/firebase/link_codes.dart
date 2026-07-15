import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'callables.dart';

/// The QR add-device handshake, client side. See firebase/functions/src/
/// linkcodes.ts for the lifecycle this mirrors:
///
///   A: createLinkCode  → pending, shown as a QR
///   B: redeemLinkCode  → claimed, B alone holds the nonce
///   A: confirmLinkCode → confirmed (the anti-phishing tap)
///   B: collectLinkToken→ used, B gets a custom token and signs in
///
/// Everything the UI needs to branch on is a [LinkCodeError] with a typed
/// [LinkCodeErrorKind] — no string matching on Firebase messages.

/// Why a callable refused. Maps 1:1 onto the functions' HttpsError codes,
/// plus [network] for "the call never landed".
enum LinkCodeErrorKind {
  /// Not signed in, or a session revoked by the watermark.
  unauthenticated,

  /// Anonymous account (createLinkCode), a code that expired, was already
  /// redeemed, or isn't confirmable any more.
  failedPrecondition,

  /// Unknown/malformed code, or a device id with no doc.
  notFound,

  /// Someone else's code.
  permissionDenied,

  /// Too many open codes, or the per-IP hourly cap.
  resourceExhausted,

  /// Missing/blank device name or platform.
  invalidArgument,

  /// Offline, DNS, TLS — the call never reached a function.
  network,

  /// The caller stopped waiting before the token was collected — the screen
  /// that ran the handshake was disposed (the artist backed out of "Confirm
  /// on your phone"). Never shown to anyone: the widget is already gone, and
  /// the point of raising it is to unwind the orphaned poll WITHOUT collecting.
  cancelled,

  unknown,
}

class LinkCodeError implements Exception {
  const LinkCodeError(this.kind, [this.message]);

  final LinkCodeErrorKind kind;

  /// The server's sentence, when it had one. Diagnostics only — the UI shows
  /// its own localized copy, chosen by [kind].
  final String? message;

  @override
  String toString() => 'LinkCodeError(${kind.name}: ${message ?? ''})';
}

/// A freshly minted code and the instant it dies (epoch ms).
class LinkCode {
  const LinkCode({required this.code, required this.expiresAtMs});

  final String code;
  final int expiresAtMs;

  /// What device B scans. The code rides in the FRAGMENT: fragments are never
  /// sent to a server, so the code stays out of hosting/CDN access logs even
  /// when the link is opened in a browser instead of the app.
  String get url => 'https://tip.live.tips/link#c=$code';
}

/// What the kill switch gives back: how many devices it flagged, and this
/// device's own way back in.
class RevokedSessions {
  const RevokedSessions({required this.revokedCount, this.token});

  final int revokedCount;

  /// A custom token for the caller's own uid, minted by the server AFTER it
  /// revoked every refresh token this account had — including ours. Redeeming
  /// it is what keeps THIS device signed in (see SecurityScreen).
  ///
  /// Null only from a server that predates #34. The revoke still happened, so
  /// a null is a failure to re-enter, never a failure to revoke.
  final String? token;
}

/// Where a code is in its lifecycle, as device A's listener sees it.
enum LinkCodeStatus { pending, claimed, confirmed, used, expired, unknown }

/// The live view of `linkCodes/{code}` device A watches: the status, and —
/// once B has scanned — who is asking to be let in.
class LinkCodeState {
  const LinkCodeState({
    required this.status,
    this.requesterName,
    this.requesterPlatform,
  });

  final LinkCodeStatus status;
  final String? requesterName;
  final String? requesterPlatform;

  static LinkCodeState fromData(Map<String, dynamic>? data) {
    if (data == null) {
      return const LinkCodeState(status: LinkCodeStatus.unknown);
    }
    final requester = data['requester'] as Map<String, dynamic>?;
    return LinkCodeState(
      status: LinkCodeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => LinkCodeStatus.unknown,
      ),
      requesterName: requester?['name'] as String?,
      requesterPlatform: requester?['platform'] as String?,
    );
  }
}

/// The answer to one collectLinkToken poll: still waiting on device A's tap,
/// or here is your custom token.
class CollectedToken {
  const CollectedToken({this.token, this.pending = false});

  final String? token;
  final bool pending;
}

/// The six callables, typed. Constructed with a null [FirebaseFunctions]
/// wherever Firebase isn't — then every call throws
/// [LinkCodeErrorKind.unauthenticated] rather than crashing on a null.
class LinkCodeService {
  LinkCodeService({FirebaseFunctions? functions, FirebaseFirestore? db})
      : _functions = functions,
        _db = db;

  final FirebaseFunctions? _functions;
  final FirebaseFirestore? _db;

  bool get available => _functions != null;

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic> args = const {},
  ]) async {
    final functions = _functions;
    if (functions == null) {
      throw const LinkCodeError(
          LinkCodeErrorKind.unauthenticated, 'Firebase unavailable');
    }
    try {
      return await callCallable(functions, name, args);
    } on FirebaseFunctionsException catch (e) {
      throw LinkCodeError(_kindOf(e.code), e.message);
    } catch (e) {
      throw LinkCodeError(LinkCodeErrorKind.network, '$e');
    }
  }

  static LinkCodeErrorKind _kindOf(String code) => switch (code) {
        'unauthenticated' => LinkCodeErrorKind.unauthenticated,
        'failed-precondition' => LinkCodeErrorKind.failedPrecondition,
        'not-found' => LinkCodeErrorKind.notFound,
        'permission-denied' => LinkCodeErrorKind.permissionDenied,
        'resource-exhausted' => LinkCodeErrorKind.resourceExhausted,
        'invalid-argument' => LinkCodeErrorKind.invalidArgument,
        'unavailable' || 'deadline-exceeded' => LinkCodeErrorKind.network,
        _ => LinkCodeErrorKind.unknown,
      };

  /// Device A, step 1. Non-anonymous accounts only — an anonymous caller gets
  /// [LinkCodeErrorKind.failedPrecondition].
  Future<LinkCode> createLinkCode() async {
    final data = await _call('createLinkCode');
    final code = data['code'] as String?;
    if (code == null) {
      throw const LinkCodeError(LinkCodeErrorKind.unknown, 'no code returned');
    }
    return LinkCode(
      code: code,
      expiresAtMs: (data['expiresAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Device B, step 2 — no auth needed. Returns the redeem nonce, which only
  /// this device ever holds (it is never in the QR).
  ///
  /// [deviceId] is how B names itself: a device this account once revoked is
  /// re-admitted by A's confirm, and by nothing else (#36). Without it, a
  /// revoked device would sign in on the collected token and be signed straight
  /// back out by its own tombstone.
  Future<String> redeemLinkCode({
    required String code,
    required String deviceName,
    required String devicePlatform,
    String? deviceId,
  }) async {
    final data = await _call('redeemLinkCode', {
      'code': code,
      'deviceName': deviceName,
      'devicePlatform': devicePlatform,
      'deviceId': ?deviceId,
    });
    final nonce = data['nonce'] as String?;
    if (nonce == null) {
      throw const LinkCodeError(LinkCodeErrorKind.unknown, 'no nonce returned');
    }
    return nonce;
  }

  /// Device A, step 3: the tap that says "yes, that's my other device".
  Future<void> confirmLinkCode(String code) =>
      _call('confirmLinkCode', {'code': code});

  /// Device B, step 4. `{pending: true}` is NOT an error — it means device A
  /// hasn't tapped confirm yet. See [awaitToken] for the polling loop.
  Future<CollectedToken> collectLinkToken({
    required String code,
    required String nonce,
  }) async {
    final data = await _call('collectLinkToken', {'code': code, 'nonce': nonce});
    if (data['pending'] == true) return const CollectedToken(pending: true);
    final token = data['token'] as String?;
    if (token == null) {
      throw const LinkCodeError(LinkCodeErrorKind.unknown, 'no token returned');
    }
    return CollectedToken(token: token);
  }

  /// Polls [collectLinkToken] until device A confirms, and returns the custom
  /// token. Gives up with [LinkCodeErrorKind.failedPrecondition] once the code
  /// would have expired anyway — the server would say the same, a few seconds
  /// later and one round trip more expensively.
  ///
  /// [keepWaiting] is the credential guard. Collecting the token is what SPENDS
  /// the code — the server flips it 'used' and hands over a custom token, and
  /// device A's phone reads 'used' as "they got in". So we must not collect for
  /// a device that has walked away: [keepWaiting] is checked before every poll
  /// (pass `() => mounted`), and once it returns false we stop WITHOUT another
  /// collect. The code then stays 'confirmed'-and-uncollected — re-usable until
  /// its short TTL — and the phone keeps showing "waiting", which is the truth,
  /// rather than a success card for a sign-in that never happened.
  Future<String> awaitToken({
    required String code,
    required String nonce,
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
    bool Function()? keepWaiting,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      if (keepWaiting != null && !keepWaiting()) {
        throw const LinkCodeError(
            LinkCodeErrorKind.cancelled, 'no longer waiting for the token');
      }
      final result = await collectLinkToken(code: code, nonce: nonce);
      final token = result.token;
      if (token != null) return token;
      if (!DateTime.now().add(interval).isBefore(deadline)) {
        throw const LinkCodeError(
            LinkCodeErrorKind.failedPrecondition, 'code expired');
      }
      await Future<void>.delayed(interval);
    }
  }

  /// Device A's live view of its own code — how it learns someone scanned it
  /// (claimed → show the requester) and that they got in (used).
  Stream<LinkCodeState> watchLinkCode(String code) {
    final db = _db;
    if (db == null) {
      return Stream.value(const LinkCodeState(status: LinkCodeStatus.unknown));
    }
    return db
        .doc('linkCodes/$code')
        .snapshots()
        .map((snap) => LinkCodeState.fromData(snap.data()));
  }

  /// Cooperative revocation: flips the flag [deviceId] watches. It cannot
  /// force a hostile client out — [revokeAllOtherDevices] is the kill switch.
  Future<void> revokeDevice(String deviceId) =>
      _call('revokeDevice', {'deviceId': deviceId});

  /// The real kill switch. It revokes the CALLER's refresh token too — that is
  /// what makes it real — and hands back a custom token minted after the
  /// revoke, which the caller redeems to stay signed in. Guests included: the
  /// token needs no provider (#34).
  Future<RevokedSessions> revokeAllOtherDevices(String currentDeviceId) async {
    final data = await _call(
        'revokeAllOtherDevices', {'currentDeviceId': currentDeviceId});
    final token = data['token'] as String?;
    return RevokedSessions(
      revokedCount: (data['revokedCount'] as num?)?.toInt() ?? 0,
      token: token == null || token.isEmpty ? null : token,
    );
  }
}
