import { describe, expect, it } from "vitest";
import {
  REVOLUT_NOTE_MAX,
  buildMobilePayUrl,
  buildMonzoUrl,
  buildRedirectUrl,
  buildRevolutUrl,
  clampNote,
  packNote,
  packRequestNote,
} from "../src/deeplinks";
import type { JarProfile } from "../src/types";

const profile: JarProfile = {
  artistName: "Ada",
  message: "",
  currency: "eur",
  methods: {
    revolutUsername: "mekedron",
    mobilepayBoxId: "a76b1e43-1958-483c-b602-da5869f57212",
  },
};

const monzoProfile: JarProfile = {
  artistName: "Ada",
  message: "",
  currency: "gbp",
  methods: { monzoUsername: "daniel" },
};

describe("packNote / clampNote", () => {
  it("packs name and message with the colon separator", () => {
    expect(packNote("Ada", "great show")).toBe("Ada: great show");
    expect(packNote("", "great show")).toBe("great show");
    expect(packNote("Ada", "")).toBe("Ada");
  });

  it("clamps by code points with an ellipsis", () => {
    expect(clampNote("abcdef", 6)).toBe("abcdef");
    expect(clampNote("abcdefg", 6)).toBe("abcde…");
  });
});

describe("packRequestNote", () => {
  it("puts the song title FIRST, then the packed name/message", () => {
    expect(packRequestNote("Wonderwall", "Ada", "play it slow"))
      .toBe("♪ Wonderwall — Ada: play it slow");
    expect(packRequestNote("Wonderwall", "", "play it slow"))
      .toBe("♪ Wonderwall — play it slow");
  });

  it("is just the marked title when there is no name or message", () => {
    expect(packRequestNote("Wonderwall", "", "")).toBe("♪ Wonderwall");
  });

  it("survives the Revolut 64-char clamp with the title intact", () => {
    // A maximum-length (60 code points) title plus a long message: the clamp
    // eats the message, never the song — the artist must be able to read
    // which song was paid for off the payment itself.
    const title = "T".repeat(60);
    const note = clampNote(packRequestNote(title, "Ada", "x".repeat(150)), REVOLUT_NOTE_MAX);
    expect([...note].length).toBe(REVOLUT_NOTE_MAX);
    expect(note.startsWith(`♪ ${title}`)).toBe(true);
    expect(note.endsWith("…")).toBe(true);
  });
});

describe("URL composition", () => {
  it("builds Revolut links on the hardcoded host with encoded params", () => {
    const url = new URL(buildRevolutUrl("mekedron", 500, "eur", "Ada: nice & fun"));
    expect(url.origin).toBe("https://revolut.me");
    expect(url.pathname).toBe("/mekedron");
    expect(url.searchParams.get("amount")).toBe("500");
    expect(url.searchParams.get("currency")).toBe("eur");
    expect(url.searchParams.get("note")).toBe("Ada: nice & fun");
  });

  it("builds MobilePay links with cents and message", () => {
    const url = new URL(buildMobilePayUrl("a76b1e43-1958-483c-b602-da5869f57212", 1234, "hello"));
    expect(url.origin).toBe("https://qr.mobilepay.fi");
    expect(url.pathname).toBe("/box/a76b1e43-1958-483c-b602-da5869f57212/pay-in");
    expect(url.searchParams.get("amount")).toBe("1234");
    expect(url.searchParams.get("message")).toBe("hello");
  });

  it("builds Monzo links with the amount as a MAJOR-unit path segment", () => {
    const url = new URL(buildMonzoUrl("daniel", 500, "Ada: nice & fun"));
    expect(url.origin).toBe("https://monzo.me");
    // £5.00, not £500 — the 100× overcharge this asserts against.
    expect(url.pathname).toBe("/daniel/5");
    expect(url.searchParams.get("d")).toBe("Ada: nice & fun");
  });

  it("renders a non-round Monzo amount with two decimals", () => {
    expect(new URL(buildMonzoUrl("daniel", 1234, "")).pathname).toBe("/daniel/12.34");
    expect(new URL(buildMonzoUrl("daniel", 550, "")).pathname).toBe("/daniel/5.50");
  });

  it("cannot be steered off the allowlisted hosts by hostile note text", () => {
    const hostile = "x&redirect=https://evil.com#//evil.com";
    for (const raw of [
      buildRevolutUrl("mekedron", 500, "eur", hostile),
      buildMobilePayUrl("a76b1e43-1958-483c-b602-da5869f57212", 500, hostile),
      buildMonzoUrl("daniel", 500, hostile),
    ]) {
      const url = new URL(raw);
      expect(["https://revolut.me", "https://qr.mobilepay.fi", "https://monzo.me"]).toContain(url.origin);
      // The hostile text survived only as an encoded query value.
      expect(url.searchParams.getAll("redirect")).toEqual([]);
    }
  });

  it("routes a monzo tip to monzo.me", () => {
    const url = buildRedirectUrl(monzoProfile, {
      method: "monzo",
      amountMinor: 250,
      name: "Ada",
      message: "great set",
    });
    expect(url).toBe("https://monzo.me/daniel/2.50?d=Ada%3A+great+set");
  });

  it("notes a song-request tip title-first", () => {
    const url = new URL(buildRedirectUrl(profile, {
      method: "revolut",
      amountMinor: 600,
      name: "Ada",
      message: "",
      songId: "s1",
      songTitle: "Wonderwall",
    })!);
    expect(url.searchParams.get("note")).toBe("♪ Wonderwall — Ada");
    expect(url.searchParams.get("amount")).toBe("600");
  });

  it("returns null for unconfigured methods", () => {
    const stripeOnly: JarProfile = { ...profile, methods: { stripeUrl: "https://buy.stripe.com/x" } };
    expect(buildRedirectUrl(stripeOnly, { method: "revolut", amountMinor: 500, name: "", message: "" })).toBeNull();
  });
});
