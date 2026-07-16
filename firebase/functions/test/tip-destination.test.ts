/// The routing decision and the wire builders of tip-destination.ts — pure
/// functions, tested against the app's own semantics:
///
///  * liveSessionId must agree with CloudSessionCoordinator.leaseAlive
///    (app/lib/state/cloud_session_coordinator.dart) plus the active/band
///    guards, or the server and the app disagree about whether a set is
///    running and money lands on the wrong page;
///  * relayTipWire / stripeTipWire must reproduce Tip.toJson
///    (app/lib/domain/tip.dart) byte-for-byte, omit-when-default semantics
///    included — every device decodes these docs with Tip.fromJson.

import { describe, expect, it } from "vitest";
import {
  SESSION_LEASE_STALE_MS,
  liveSessionId,
  relayTipWire,
  requestBumpFields,
  stripeTipWire,
} from "../src/tip-destination";
import type { StripeTipData } from "../src/stripe-events";
import type { RequestsLive } from "../src/types";

const NOW = 1_800_000_000_000;
const BAND = "acc_m3k9zq1a2b3c";

/** live/current as the app's claim transaction writes it, lease fresh. */
function liveDoc(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    active: true,
    bandId: BAND,
    sessionId: "sess_tonight",
    startedAtMs: NOW - 3_600_000,
    currency: "eur",
    leaderDeviceId: "device_a",
    leaderLeaseUntilMs: NOW + 45_000,
    ...overrides,
  };
}

describe("liveSessionId: the ONE definition of a running set, server side", () => {
  it("a fresh-leased active session for the band is running", () => {
    expect(liveSessionId(liveDoc(), BAND, NOW)).toBe("sess_tonight");
  });

  it("no live doc at all: not running", () => {
    expect(liveSessionId(undefined, BAND, NOW)).toBeNull();
  });

  it("active:false (a clean stop) is not running, whatever the lease says", () => {
    expect(liveSessionId(liveDoc({ active: false }), BAND, NOW)).toBeNull();
  });

  it("the lease decays: dead exactly at staleMs, alive one ms before it", () => {
    // The takeover window: a crashed leader's session keeps receiving tips
    // until the app itself would declare the session gone — the same
    // staleMs the followers' takeover logic uses.
    const boundary = NOW - SESSION_LEASE_STALE_MS;
    expect(liveSessionId(liveDoc({ leaderLeaseUntilMs: boundary }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ leaderLeaseUntilMs: boundary + 1 }), BAND, NOW)).toBe("sess_tonight");
  });

  it("staleMs mirrors the app's CloudSessionCoordinator.staleMs (2 min)", () => {
    expect(SESSION_LEASE_STALE_MS).toBe(2 * 60_000);
  });

  it("another band's set does not capture this band's tips", () => {
    expect(liveSessionId(liveDoc({ bandId: "acc_other" }), BAND, NOW)).toBeNull();
  });

  it("malformed docs route to the archive, never throw: the tip survives", () => {
    expect(liveSessionId(liveDoc({ sessionId: 42 }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ sessionId: "" }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ sessionId: undefined }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ leaderLeaseUntilMs: "soon" }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ leaderLeaseUntilMs: undefined }), BAND, NOW)).toBeNull();
    expect(liveSessionId(liveDoc({ active: "true" }), BAND, NOW)).toBeNull();
    expect(liveSessionId({}, BAND, NOW)).toBeNull();
  });
});

// ---------------------------------------------------------------------------

describe("relayTipWire: Tip.relayTip(...).toJson() + updatedAtMs, exactly", () => {
  it("a full request tip round-trips every field the app expects", () => {
    const doc = relayTipWire({
      id: "relay_9f8e7d6c",
      tsMs: NOW,
      method: "revolut",
      amountMinor: 500,
      currency: "eur",
      name: "Ada",
      message: "great show",
      songId: "s2",
      songTitle: "Hallelujah",
    }, NOW + 5);

    // toEqual: absent keys are the contract as much as present ones.
    expect(doc).toEqual({
      id: "relay_9f8e7d6c",
      amountMinor: 500,
      currency: "eur",
      createdAt: NOW,
      name: "Ada",
      message: "great show",
      livemode: true,
      viaService: true,
      method: "revolut",
      verified: false, // fan-declared money is UNVERIFIED — always written
      songId: "s2",
      songTitle: "Hallelujah",
      updatedAtMs: NOW + 5,
    });
  });

  it("empty name/message become ABSENT keys — the app's ''→null→omitted chain", () => {
    const doc = relayTipWire({
      id: "relay_1",
      tsMs: NOW,
      method: "mobilepay",
      amountMinor: 300,
      currency: "eur",
      name: "",
      message: "",
    }, NOW);

    expect("name" in doc).toBe(false);
    expect("message" in doc).toBe(false);
    expect("songId" in doc).toBe(false);
    expect("songTitle" in doc).toBe(false);
    // method is always written on this path: relay methods are never Tip's
    // stripe default, and verified:false is never Tip's true default.
    expect(doc["method"]).toBe("mobilepay");
    expect(doc["verified"]).toBe(false);
  });
});

describe("stripeTipWire: the app's Tip.fromCheckoutSession/toJson round-trip", () => {
  const donation: StripeTipData = {
    tsMs: NOW,
    method: "stripe",
    amountMinor: 1500,
    currency: "eur",
    name: "Maya",
    message: "",
    inPerson: false,
    livemode: true,
    paymentIntentId: "pi_123",
  };

  it("a donation omits method/verified/inPerson — Tip's defaults stay off the wire", () => {
    expect(stripeTipWire("cs_test_1", donation, NOW + 5)).toEqual({
      id: "cs_test_1",
      amountMinor: 1500,
      currency: "eur",
      createdAt: NOW,
      name: "Maya",
      livemode: true,
      viaService: true,
      paymentIntentId: "pi_123",
      updatedAtMs: NOW + 5,
    });
  });

  it("a request tip carries songId/songTitle; a tap carries inPerson and no name", () => {
    const request = stripeTipWire("cs_test_2", {
      ...donation, songId: "song_w", songTitle: "Wonderwall",
    }, NOW);
    expect(request["songId"]).toBe("song_w");
    expect(request["songTitle"]).toBe("Wonderwall");

    const tap = stripeTipWire("ch_tap_1", {
      ...donation, name: "", paymentIntentId: null, inPerson: true, livemode: false,
    }, NOW);
    expect(tap).toEqual({
      id: "ch_tap_1",
      amountMinor: 1500,
      currency: "eur",
      createdAt: NOW,
      livemode: false,
      viaService: true,
      inPerson: true,
      updatedAtMs: NOW,
    });
  });
});

describe("requestBumpFields: one accepted request folded into the fan-page queue (#71 P3)", () => {
  const NOW = 1_700_000_000_000;
  const live = (songs: RequestsLive["songs"]): RequestsLive =>
    ({ openUntilMs: NOW + 3_600_000, updatedAtMs: 1, currency: "eur", songs });

  it("a first request mints a queued entry; a later one accumulates and keeps the verdict", () => {
    expect(requestBumpFields(live({}), "s1", 300, NOW)).toEqual({
      "requestsLive.songs.s1.t": 300,
      "requestsLive.songs.s1.c": 1,
      "requestsLive.songs.s1.s": "q",
      "requestsLive.updatedAtMs": NOW,
    });
    expect(requestBumpFields(live({ s1: { t: 300, c: 1, s: "p" } }), "s1", 900, NOW)).toEqual({
      "requestsLive.songs.s1.t": 1200,
      "requestsLive.songs.s1.c": 2,
      "requestsLive.songs.s1.s": "p",
      "requestsLive.updatedAtMs": NOW,
    });
  });

  it("survives a doc with no songs map (armed open before any publish)", () => {
    const armed = live({});
    delete (armed as Partial<RequestsLive>).songs;
    expect(requestBumpFields(armed, "s1", 300, NOW)).toMatchObject({
      "requestsLive.songs.s1.t": 300,
      "requestsLive.songs.s1.c": 1,
    });
  });

  it("saturates at the published wire bounds instead of overflowing them", () => {
    const fields = requestBumpFields(live({ s1: { t: 99_999_950, c: 10_000, s: "q" } }), "s1", 300, NOW)!;
    expect(fields["requestsLive.songs.s1.t"]).toBe(100_000_000);
    expect(fields["requestsLive.songs.s1.c"]).toBe(10_000);
  });

  it("refuses to write when there is nothing to write INTO, or when the id cannot be a field path", () => {
    // No requestsLive: a partial doc (updatedAtMs, no openUntilMs) would read
    // as an OPEN window to /queue — the 2026-07-14 partial-shape family.
    expect(requestBumpFields(undefined, "s1", 300, NOW)).toBeNull();
    // The webhook's songId comes from a connection doc written months ago;
    // a dot would silently address a DIFFERENT field.
    expect(requestBumpFields(live({}), "s1.evil", 300, NOW)).toBeNull();
    expect(requestBumpFields(live({}), "", 300, NOW)).toBeNull();
  });
});
