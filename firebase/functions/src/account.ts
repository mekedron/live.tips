/// deleteAccount — the one irreversible act, and the one the client cannot be
/// trusted to perform.
///
/// Why it is a callable and not a client-side sweep:
///  - the client cannot ENUMERATE what it never cached. A cache-backed listing
///    silently misses docs and strands them (issue #17, the per-profile wipe);
///    an account's surface is wider still — bands it never opened, a Stripe
///    connection doc it is not even allowed to read, jars from a device that
///    is now in a drawer.
///  - deleting the Firebase Auth user and pulling the webhook endpoint off the
///    artist's OWN Stripe account both need admin credentials, which no device
///    has, and never will.
///
/// Guests included, deliberately. requireNonAnonymousUid guards the Stripe
/// custody surface because a guest could never come back to disconnect a key —
/// but the way OUT of an unrecoverable account is the one door a guest needs
/// most, so this one asks only for a signed-in caller and a fresh session
/// (requireFreshSession, the same watermark the device ceremonies enforce:
/// deleting an account is at least as sensitive as revoking a device).
///
/// FAIL-CLOSED AND RESUMABLE. Before anything is touched, the intent is
/// written to accountDeletions/{uid} — top-level, because users/{uid} and the
/// Auth user are precisely what is about to stop existing. Each stage stamps
/// itself done; a stage that throws leaves the ledger behind, and the caller
/// gets an error, never {ok: true}. The next call resumes where it stopped —
/// and so does sweepAccountDeletions (sweeps.ts), which matters because the
/// LAST stage deletes the Auth user: after that the artist could not call
/// again if they tried.
///
/// Stage order is not arbitrary: Stripe reads the pointer under users/{uid},
/// and the jar sweep reads the band docs there, so both must run BEFORE the
/// subtree they read is deleted. The Auth user goes last of all.

import { getAuth } from "firebase-admin/auth";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { requireFreshSession } from "./devices";
import { purgeJar, requireUid } from "./jars";
import { tearDownConnection } from "./stripe-connect";
import {
  stripeConnectionRef,
  stripePointerRef,
  type StripeConnectionDoc,
  type StripePointerDoc,
} from "./stripe-store";
import {
  accountDeletionRef,
  bandsCol,
  db,
  userRef,
  type AccountDeletionDoc,
} from "./store";
import { isValidJarId } from "./validate";

import type { Firestore } from "firebase-admin/firestore";

/**
 * Everything one deletion has to erase, in the order it must happen. The names
 * are what lands in AccountDeletionDoc.done — a partial delete is legible from
 * the ledger alone.
 */
const STAGES = ["stripe", "jars", "codes", "quotas", "data", "auth"] as const;

type Stage = (typeof STAGES)[number];

/** The uid-keyed quota buckets (rateLimits/{key}); the IP-keyed ones are not
 * this account's to reclaim — they are shared with whoever else uses that IP. */
const QUOTA_KEYS = (uid: string): string[] => [
  `create-uid-${uid}`,
  `stripe-connect-${uid}`,
  `stripe-proxy-${uid}`,
  `stripe-tips-${uid}`,
];

// ---------------------------------------------------------------------------
// The stages

/**
 * The Stripe connections: for each, the webhook endpoint comes off the
 * ARTIST'S account, then the sealed key + signing secret go, then the pointer.
 *
 * Enumerated from BOTH the pointer and a uid query — the query is not
 * redundant. An orphaned connection (#19(c): a doc whose pointer entry was
 * lost) holds a sealed key and a LIVE endpoint that the pointer can no longer
 * see and that nothing else would ever collect. "Delete everything" means the
 * ones we lost track of too.
 *
 * Returns the endpoints Stripe would not let us remove — the residue we name
 * instead of hiding (the artist can delete them in their own dashboard).
 */
async function deleteStripe(firestore: Firestore, uid: string): Promise<string[]> {
  const pointer = (await stripePointerRef(firestore, uid).get()).data() as StripePointerDoc | undefined;
  const ids = new Set<string>();
  for (const id of Object.values(pointer?.connections ?? {})) {
    if (isValidJarId(id)) ids.add(id);
  }
  const owned = await firestore.collection("stripeConnections").where("uid", "==", uid).get();
  for (const doc of owned.docs) ids.add(doc.id);

  const stranded: string[] = [];
  for (const connectionId of ids) {
    const doc = (await stripeConnectionRef(firestore, connectionId).get()).data() as
      | StripeConnectionDoc
      | undefined;
    // A dangling pointer entry (already torn down) is nothing to do; a doc
    // owned by somebody else is not ours to touch, pointer or no pointer.
    if (!doc || doc.uid !== uid) continue;
    const removed = await tearDownConnection(firestore, connectionId, doc, {
      // The link is the artist's own object on their own account: deactivating
      // it stops NEW payments to a page that no longer exists anywhere. Their
      // past payments stay theirs — see the confirmation copy.
      deactivateLink: true,
      context: "deleteAccount",
    });
    if (!removed) stranded.push(doc.webhookEndpointId);
  }
  await stripePointerRef(firestore, uid).delete();
  return stranded;
}

/**
 * The relay jars — the public tip.live.tips/t/{id} pages. They must die with
 * the account: a page that keeps taking money for a deleted artist is the
 * loudest possible residue.
 *
 * Two sources, and both are needed. ownerUid pins a jar to a REAL account
 * (RelayAuth.ownsJars refuses to pin one to a guest uid, so a guest's page
 * would survive an ownerUid query untouched) — and the band docs name every
 * jar the account actually holds, read from the SERVER, which is the whole
 * point of doing this here instead of on a device.
 */
async function deleteJars(firestore: Firestore, uid: string): Promise<void> {
  const jarIds = new Set<string>();
  const bands = await bandsCol(firestore, uid).get();
  for (const band of bands.docs) {
    const jarId = (band.get("relayJar") as { jarId?: unknown } | undefined)?.jarId;
    if (typeof jarId === "string" && isValidJarId(jarId)) jarIds.add(jarId);
  }
  const owned = await firestore.collection("jars").where("ownerUid", "==", uid).get();
  for (const doc of owned.docs) jarIds.add(doc.id);
  for (const jarId of jarIds) await purgeJar(firestore, jarId);
}

/** Open QR grants. A link code outliving its account would be a token minted
 * for a uid that no longer exists — and revokeAllOtherDevices already taught
 * us that the watermark alone cannot reach the unauthenticated collect. */
async function deleteLinkCodes(firestore: Firestore, uid: string): Promise<void> {
  const codes = await firestore.collection("linkCodes").where("uid", "==", uid).get();
  const batch = firestore.batch();
  for (const doc of codes.docs) batch.delete(doc.ref);
  await batch.commit();
}

async function deleteQuotas(firestore: Firestore, uid: string): Promise<void> {
  const batch = firestore.batch();
  for (const key of QUOTA_KEYS(uid)) {
    batch.delete(firestore.collection("rateLimits").doc(key));
  }
  await batch.commit();
}

/**
 * users/{uid} and everything under it, in one recursive move: every band
 * (settings, tip jars, sessions, relayTips, stripeTips, secrets/v1), the
 * device registry, live/current, settings/app, and the private/ docs — the
 * security watermark and what is left of the Stripe pointer.
 */
async function deleteUserData(firestore: Firestore, uid: string): Promise<void> {
  await firestore.recursiveDelete(userRef(firestore, uid));
}

/** The Firebase Auth user itself — nothing in the app called user.delete()
 * before this. Last, and idempotent: a user already gone is a stage done. */
async function deleteAuthUser(uid: string): Promise<void> {
  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "auth/user-not-found") return;
    throw e;
  }
}

// ---------------------------------------------------------------------------
// The run

/**
 * Runs (or resumes) the deletion recorded in [record]. Every stage is
 * idempotent, so a resume may safely re-enter one that half-ran; `done` only
 * spares us the round trips. A throw leaves the ledger — with the error on it
 * — for the next attempt.
 */
async function runDeletion(
  firestore: Firestore,
  record: AccountDeletionDoc,
): Promise<{ strandedEndpoints: string[] }> {
  const uid = record.uid;
  const ref = accountDeletionRef(firestore, uid);
  const done = new Set<Stage>(record.done as Stage[]);
  let stranded = record.strandedEndpoints ?? [];

  const finish = async (stage: Stage) => {
    done.add(stage);
    await ref.set(
      { done: [...done], strandedEndpoints: stranded },
      { merge: true },
    );
  };

  try {
    for (const stage of STAGES) {
      if (done.has(stage)) continue;
      switch (stage) {
        case "stripe":
          stranded = [...stranded, ...(await deleteStripe(firestore, uid))];
          break;
        case "jars":
          await deleteJars(firestore, uid);
          break;
        case "codes":
          await deleteLinkCodes(firestore, uid);
          break;
        case "quotas":
          await deleteQuotas(firestore, uid);
          break;
        case "data":
          await deleteUserData(firestore, uid);
          break;
        case "auth":
          await deleteAuthUser(uid);
          break;
      }
      await finish(stage);
    }
  } catch (e) {
    // The ledger survives, and says how far we got. Nothing here reports
    // success — a half-deleted account is a deletion still owed.
    await ref.set(
      {
        attempts: record.attempts + 1,
        lastErrorAtMs: Date.now(),
        lastError: e instanceof Error ? e.message : String(e),
        done: [...done],
        strandedEndpoints: stranded,
      },
      { merge: true },
    );
    console.error(`deleteAccount(${uid}): stopped after [${[...done].join(",")}]`, e);
    throw e;
  }

  // Everything is gone, including the account that asked — so the ledger has
  // nothing left to remember.
  await ref.delete();
  return { strandedEndpoints: stranded };
}

/**
 * Finishes deletions that were recorded and never completed: the client's own
 * call died mid-flight, or the LAST stage (the Auth user) failed — after which
 * there is no session left that could ever ask again. Older than [graceMs] so
 * a run still in progress is left alone.
 */
export async function resumeAccountDeletions(
  firestore: Firestore,
  nowMs: number,
  graceMs: number,
): Promise<number> {
  const stale = await firestore
    .collection("accountDeletions")
    .where("requestedAtMs", "<", nowMs - graceMs)
    .limit(20)
    .get();
  let finished = 0;
  for (const doc of stale.docs) {
    const record = doc.data() as AccountDeletionDoc;
    try {
      await runDeletion(firestore, record);
      finished++;
    } catch {
      // runDeletion already logged and stamped the ledger; the next sweep
      // picks it up again. A deletion is never dropped, only retried.
    }
  }
  return finished;
}

// ---------------------------------------------------------------------------

/**
 * The callable. No per-uid quota: the act is self-limiting (it ends with the
 * uid), and a resume after a partial failure must never be the call a rate
 * limit refuses.
 *
 * Returns the endpoints the artist's Stripe account kept, so the app can say
 * so out loud instead of the artist discovering a live webhook months later.
 */
export async function deleteAccountHandler(
  request: CallableRequest,
): Promise<{ ok: true; strandedEndpoints: string[] }> {
  const uid = requireUid(request);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  const ref = accountDeletionRef(firestore, uid);
  const existing = (await ref.get()).data() as AccountDeletionDoc | undefined;
  // The intent is written BEFORE the first deletion: if this process dies at
  // any point after it, the ledger is what finishes the job.
  const record: AccountDeletionDoc = existing ?? {
    uid,
    requestedAtMs: Date.now(),
    done: [],
    attempts: 0,
  };
  if (!existing) await ref.create(record);

  try {
    const { strandedEndpoints } = await runDeletion(firestore, record);
    return { ok: true, strandedEndpoints };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    // Honest, and specifically NOT "done": the account is still there (in
    // part), the ledger holds what was erased, and the sweep will finish it.
    throw new HttpsError(
      "internal",
      "the account was not fully deleted — nothing was reported as done, and the deletion will be completed",
    );
  }
}
