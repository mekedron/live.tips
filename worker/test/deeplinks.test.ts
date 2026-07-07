import { describe, expect, it } from "vitest";
import {
  buildMobilePayUrl,
  buildRedirectUrl,
  buildRevolutUrl,
  clampNote,
  packNote,
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

  it("cannot be steered off the allowlisted hosts by hostile note text", () => {
    const hostile = "x&redirect=https://evil.com#//evil.com";
    for (const raw of [
      buildRevolutUrl("mekedron", 500, "eur", hostile),
      buildMobilePayUrl("a76b1e43-1958-483c-b602-da5869f57212", 500, hostile),
    ]) {
      const url = new URL(raw);
      expect(["https://revolut.me", "https://qr.mobilepay.fi"]).toContain(url.origin);
      // The hostile text survived only as an encoded query value.
      expect(url.searchParams.getAll("redirect")).toEqual([]);
    }
  });

  it("returns null for unconfigured methods", () => {
    const stripeOnly: JarProfile = { ...profile, methods: { stripeUrl: "https://buy.stripe.com/x" } };
    expect(buildRedirectUrl(stripeOnly, { method: "revolut", amountMinor: 500, name: "", message: "" })).toBeNull();
  });
});
