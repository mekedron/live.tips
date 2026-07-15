import 'package:cloud_functions/cloud_functions.dart';

import 'callables.dart';

/// The account-level callable: `deleteAccount`
/// (firebase/functions/src/account.ts).
///
/// The erasure is the SERVER's, not this client's, and deliberately so: a
/// device cannot enumerate what it never cached (the trap #17 fixed for the
/// per-profile wipe), and the Firebase Auth user plus the webhook endpoint on
/// the artist's own Stripe account need admin credentials no device will ever
/// hold. This class is the door, and the typed refusal behind it.

/// Why the callable refused. Maps onto the function's HttpsError codes, plus
/// [network] for "the call never landed" — same contract as [LinkCodeError].
enum AccountCallErrorKind {
  /// Not signed in, or a session older than the account's revocation
  /// watermark (`requireFreshSession`): deleting an account is at least as
  /// sensitive as revoking a device, and asks for the same freshness.
  unauthenticated,

  /// Offline, DNS, TLS — the call never reached a function.
  network,

  unknown,
}

class AccountCallError implements Exception {
  const AccountCallError(this.kind, [this.message]);

  final AccountCallErrorKind kind;

  /// The server's sentence, when it had one. Diagnostics only — the UI shows
  /// its own localized copy, chosen by [kind].
  final String? message;

  @override
  String toString() => 'AccountCallError(${kind.name}: ${message ?? ''})';
}

class AccountService {
  AccountService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  bool get available => _functions != null;

  /// Erases the account: every band and its jars, sessions, relay tips and
  /// sealed secrets; the relay jars behind the public tip pages; the Stripe
  /// connection AND the webhook endpoint on the artist's own Stripe account;
  /// the devices, the link codes, the watermark; and the Firebase Auth user
  /// itself, last of all.
  ///
  /// Returns the webhook endpoints Stripe would NOT let the server remove
  /// (ordinarily none) — the one residue we cannot clear from here, and
  /// therefore the one the artist has to be told about instead of discovering
  /// a live webhook on their own account months later.
  ///
  /// Throws on every refusal. There is no partial success to report: the
  /// server records what it erased and finishes the job later, and until it
  /// has, the account is not deleted.
  Future<List<String>> deleteAccount() async {
    final functions = _functions;
    if (functions == null) {
      throw const AccountCallError(
          AccountCallErrorKind.unauthenticated, 'Firebase unavailable');
    }
    try {
      final data = await callCallable(functions, 'deleteAccount');
      final stranded = data['strandedEndpoints'];
      return [
        if (stranded is List)
          for (final id in stranded)
            if (id is String) id,
      ];
    } on FirebaseFunctionsException catch (e) {
      throw AccountCallError(_kindOf(e.code), e.message);
    } on AccountCallError {
      rethrow;
    } catch (e) {
      throw AccountCallError(AccountCallErrorKind.network, '$e');
    }
  }

  static AccountCallErrorKind _kindOf(String code) => switch (code) {
        'unauthenticated' => AccountCallErrorKind.unauthenticated,
        'unavailable' || 'deadline-exceeded' => AccountCallErrorKind.network,
        _ => AccountCallErrorKind.unknown,
      };
}
