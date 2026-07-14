/// stripeProxy — the ONLY way a signed-in device reaches Stripe, and it is a
/// STRICT ALLOWLIST, not a passthrough. The allowlist itself (operations,
/// input contracts, response sanitization) is the pure module stripe-ops.ts;
/// this file is the thin handler that authenticates the caller, unseals the
/// band's key, and executes the parsed operation.
///
/// The uid's restricted key is decrypted per call, used, and never returned;
/// no operation's response can contain it. Log hygiene: operations and
/// verdicts may be logged, payloads and keys never.

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { requireFreshSession, requireNonAnonymousUid } from "./devices";
import { dataObject } from "./jars";
import { kmsKeyWrapper } from "./kms";
import { StripeApi, runKeyProbes } from "./stripe-api";
import { lookupConnection, stripeToHttpsError } from "./stripe-connect";
import { openSecret } from "./stripe-crypto";
import { nextPageCursor, parseProxyRequest, sanitizeCardPresentCharge, sanitizeCheckoutSession } from "./stripe-ops";
import {
  MAX_REQUEST_LINKS,
  STRIPE_PROXY_PER_UID_PER_HOUR,
  isValidBandId,
  isValidPaymentLinkId,
  stripeConnectionRef,
} from "./stripe-store";
import { bumpQuota, db } from "./store";

export async function stripeProxyHandler(request: CallableRequest): Promise<Record<string, unknown>> {
  // Cloud accounts only, like connect/disconnect: this surface never serves
  // the anonymous relay-transport identity.
  const uid = requireNonAnonymousUid(request);
  const data = dataObject(request);
  const bandId = data["bandId"];
  if (!isValidBandId(bandId)) throw new HttpsError("invalid-argument", "bandId is required");

  const parsed = parseProxyRequest(data["op"], data["params"]);
  if (!parsed.ok) throw new HttpsError("invalid-argument", parsed.error);
  const req = parsed.value;

  const firestore = db();
  // Revocation watermark, callable-side like devices.ts: a stolen (revoked)
  // session must not page through tip history with the artist's key.
  await requireFreshSession(firestore, uid, request);
  const allowed = await bumpQuota(
    firestore, `stripe-proxy-${uid}`, Math.floor(Date.now() / 3_600_000), STRIPE_PROXY_PER_UID_PER_HOUR, 2 * 3_600_000,
  );
  if (!allowed) throw new HttpsError("resource-exhausted", "too many requests, try later");

  const connection = await lookupConnection(uid, bandId);
  if (connection === null) {
    throw new HttpsError("failed-precondition", "Stripe is not connected for this band");
  }

  // Unsealed per call, used, gone. Never in the return value, never logged.
  let key: string;
  try {
    key = await openSecret(connection.doc.key, kmsKeyWrapper());
  } catch (e) {
    console.error("stripeProxy: could not open the stored key", e instanceof Error ? e.message : "");
    throw new HttpsError("internal", "server misconfigured");
  }
  const api = new StripeApi(key);

  try {
    switch (req.op) {
      case "checkKey": {
        const checks = await runKeyProbes(api);
        return { checks, allOk: checks.every((c) => c.ok) };
      }

      case "createTipJar": {
        // Identical to the app's createTipJar, parameter for parameter —
        // including `pay`, never `donate` (submit_type also picks the
        // checkout hostname, and "donations" is a Stripe business category
        // that gets artists refused; see docs/onboarding/tips-not-donations.md).
        const product = await api.post("products", {
          name: `Tips — ${req.displayName}`,
          description:
            "Tips for a live performance, collected with the open-source live.tips app.",
          "metadata[managed_by]": "live.tips",
        });
        const price = await api.post("prices", {
          product: String(product["id"]),
          currency: req.currency,
          "custom_unit_amount[enabled]": "true",
          "metadata[managed_by]": "live.tips",
        });
        const link = await api.post("payment_links", {
          "line_items[0][price]": String(price["id"]),
          "line_items[0][quantity]": "1",
          submit_type: "pay",
          "custom_fields[0][key]": "nickname",
          "custom_fields[0][label][type]": "custom",
          "custom_fields[0][label][custom]": "Your name or nickname",
          "custom_fields[0][type]": "text",
          "custom_fields[0][optional]": "true",
          "custom_fields[1][key]": "message",
          "custom_fields[1][label][type]": "custom",
          "custom_fields[1][label][custom]": "Leave a message",
          "custom_fields[1][type]": "text",
          "custom_fields[1][optional]": "true",
          "after_completion[type]": "hosted_confirmation",
          "after_completion[hosted_confirmation][custom_message]": req.thankYouMessage,
          "metadata[managed_by]": "live.tips",
        });
        // Stamp the connection: this link's checkout events are tips now.
        // Server-created, so the webhook filter needs no client round trip.
        await stripeConnectionRef(firestore, connection.connectionId).update({
          paymentLinkId: String(link["id"]),
        });
        return {
          productId: product["id"],
          priceId: price["id"],
          paymentLinkId: link["id"],
          url: link["url"],
          currency: req.currency,
          displayName: req.displayName,
          thankYouMessage: req.thankYouMessage,
          livemode: link["livemode"] === true,
        };
      }

      case "updateTipJarDetails": {
        await api.post(`products/${req.productId}`, { name: `Tips — ${req.displayName}` });
        await api.post(`payment_links/${req.paymentLinkId}`, {
          "after_completion[type]": "hosted_confirmation",
          "after_completion[hosted_confirmation][custom_message]": req.thankYouMessage,
        });
        return { ok: true };
      }

      case "deactivatePaymentLink": {
        await api.post(`payment_links/${req.paymentLinkId}`, { active: "false" });
        // paymentLinkId stays on the connection: a deactivated link can
        // still settle async payments started before it went dark, and
        // those are tips.
        return { ok: true };
      }

      case "createSongLink": {
        // One Payment Link per song (issue #64): fixed price = the song's
        // price, quantity 1–50 as "votes" — amount_total arrives already
        // multiplied, so the webhook never parses quantities.
        //
        // The cap is checked BEFORE anything is minted on Stripe: requestLinks
        // is a lifetime map (deactivated links stay for async attribution),
        // and it is read on every webhook delivery, so it must not grow
        // without bound.
        const links = connection.doc.requestLinks ?? {};
        if (Object.keys(links).length >= MAX_REQUEST_LINKS) {
          throw new HttpsError(
            "failed-precondition",
            `this connection already tracks ${MAX_REQUEST_LINKS} song links (deactivated ones included) — remove songs is not enough, the cap is lifetime`,
          );
        }
        const product = await api.post("products", {
          name: `Request — ${req.title}`,
          "metadata[managed_by]": "live.tips",
          "metadata[song_id]": req.songId,
        });
        const price = await api.post("prices", {
          product: String(product["id"]),
          currency: req.currency,
          unit_amount: String(req.priceMinor),
          "metadata[managed_by]": "live.tips",
        });
        const link = await api.post("payment_links", {
          "line_items[0][price]": String(price["id"]),
          "line_items[0][quantity]": "1",
          "line_items[0][adjustable_quantity][enabled]": "true",
          "line_items[0][adjustable_quantity][minimum]": "1",
          "line_items[0][adjustable_quantity][maximum]": "50",
          submit_type: "pay",
          // The SAME fan fields as the tip jar: a request is a tip with a
          // song attached, and the stage shows the same name + message.
          "custom_fields[0][key]": "nickname",
          "custom_fields[0][label][type]": "custom",
          "custom_fields[0][label][custom]": "Your name or nickname",
          "custom_fields[0][type]": "text",
          "custom_fields[0][optional]": "true",
          "custom_fields[1][key]": "message",
          "custom_fields[1][label][type]": "custom",
          "custom_fields[1][label][custom]": "Leave a message",
          "custom_fields[1][type]": "text",
          "custom_fields[1][optional]": "true",
          "metadata[managed_by]": "live.tips",
          "metadata[song_id]": req.songId,
        });
        const paymentLinkId = link["id"];
        if (!isValidPaymentLinkId(paymentLinkId)) {
          // Stripe answered 200 with something that is not a plink id — do
          // not stamp the map with a key the webhook could never match.
          console.error("stripeProxy: createSongLink got a malformed payment link id from Stripe");
          throw new HttpsError("internal", "unexpected reply from Stripe");
        }
        // Stamp the connection: this link's checkout events are request tips
        // for this song. Dot-path update, so concurrent createSongLink calls
        // merge instead of clobbering each other's entries.
        await stripeConnectionRef(firestore, connection.connectionId).update({
          [`requestLinks.${paymentLinkId}`]: { songId: req.songId, title: req.title },
        });
        return {
          productId: product["id"],
          priceId: price["id"],
          paymentLinkId,
          url: link["url"],
        };
      }

      case "updateSongLink": {
        // Title only. A price change is deactivate + create on the app side:
        // Stripe prices are immutable, so "the same link, new price" does
        // not exist as an operation.
        await api.post(`products/${req.productId}`, { name: `Request — ${req.title}` });
        return { ok: true };
      }

      case "deactivateSongLink": {
        await api.post(`payment_links/${req.paymentLinkId}`, { active: "false" });
        // The requestLinks entry stays, like paymentLinkId above: a
        // deactivated link can still settle async payments started before it
        // went dark, and those must still attribute to their song.
        return { ok: true };
      }

      case "listTips": {
        const query: Record<string, string | string[]> = {
          status: "complete",
          "expand[]": "data.payment_link",
          limit: String(req.limit),
        };
        if (req.startingAfter !== null) query["starting_after"] = req.startingAfter;
        // Stripe filters on whole seconds; the ms window floors down so a tip
        // created in the same second as T is included, never dropped.
        if (req.createdAfterMs !== null) query["created[gte]"] = String(Math.floor(req.createdAfterMs / 1000));
        const response = await api.get("checkout/sessions", query);
        const sessions: Record<string, unknown>[] = [];
        if (Array.isArray(response["data"])) {
          for (const item of response["data"]) {
            const sanitized = sanitizeCheckoutSession(item);
            if (sanitized !== null) sessions.push(sanitized);
          }
        }
        // hasMore/nextCursor describe the RAW page (sanitization may have
        // dropped items, even all of them — the loop pages by nextCursor,
        // never by the last sanitized id).
        return { sessions, hasMore: response["has_more"] === true, nextCursor: nextPageCursor(response["data"]) };
      }

      case "listTaps": {
        // The other half of reconciliation: in-person taps are card-present
        // charges, and unlike QR tips they appear in NO other list — a
        // dropped webhook would lose them permanently without this. The raw
        // /v1/charges page can contain anything the account does; only what
        // sanitizeCardPresentCharge accepts (succeeded+paid card_present,
        // PII stripped) goes on the wire, so hasMore and nextCursor refer to
        // the raw page — a busy QR night is a page of card-NOT-present
        // charges that sanitizes to [], and the loop must still advance.
        const query: Record<string, string | string[]> = { limit: String(req.limit) };
        if (req.startingAfter !== null) query["starting_after"] = req.startingAfter;
        if (req.createdAfterMs !== null) query["created[gte]"] = String(Math.floor(req.createdAfterMs / 1000));
        const response = await api.get("charges", query);
        const charges: Record<string, unknown>[] = [];
        if (Array.isArray(response["data"])) {
          for (const item of response["data"]) {
            const sanitized = sanitizeCardPresentCharge(item);
            if (sanitized !== null) charges.push(sanitized);
          }
        }
        return { charges, hasMore: response["has_more"] === true, nextCursor: nextPageCursor(response["data"]) };
      }
    }
  } catch (e) {
    throw stripeToHttpsError(e);
  }
}
