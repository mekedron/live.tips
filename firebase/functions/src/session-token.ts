/// The return half of the web sign-in bridge (hosting-public/signin.html).
///
/// Safari partitions cross-origin iframe storage, so Firebase's redirect
/// sign-in can only complete on the authDomain origin (auth.live.tips) — not
/// on the app's own origin (live.tips). The bridge page signs in there and
/// carries the session across origins as a custom token minted here.
///
/// Anonymous callers are allowed on purpose: a guest account upgrading itself
/// (linkWithRedirect on the bridge) has to bring its OWN session along, and
/// that session is anonymous by definition. A caller can only ever mint a
/// token for the uid it is already signed in as — this grants nothing new.

import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";

export async function mintSessionTokenHandler(
  request: CallableRequest,
): Promise<{ token: string }> {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in before requesting a session token.");
  }
  return { token: await getAuth().createCustomToken(auth.uid) };
}
