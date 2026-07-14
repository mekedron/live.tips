import { describe, expect, it } from "vitest";
import { _inlineScriptForTests, renderNotFoundPage, renderTipPage, tipPageCsp } from "../src/tip-page";
import type { JarProfile, RequestsConfig, RequestsLive } from "../src/types";

const profile: JarProfile = {
  artistName: "Ada <script>",
  message: 'Thanks & "see you"',
  currency: "eur",
  methods: {
    revolutUsername: "mekedron",
    monzoUsername: "daniel",
    stripeUrl: "https://buy.stripe.com/abc123",
  },
};

// A hostile song library: every fan-visible string tries to break out.
const hostileConfig: RequestsConfig = {
  enabled: true,
  defaultPriceMinor: 300,
  methods: ["stripe", "revolut", "monzo"],
  songs: [
    { id: "s1", title: 'Wonder<script>alert(1)</script>wall', artist: 'The "Oasis" & Co' },
    { id: "s2", title: "Hallelujah", priceMinor: 550, stripeUrl: "https://buy.stripe.com/xyz789" },
    { id: "s3", title: "x'); alert(2); ('" },
  ],
};

function openLive(over: Partial<RequestsLive> = {}): RequestsLive {
  return { openUntilMs: Date.now() + 3_600_000, updatedAtMs: 1, currency: "eur", songs: {}, ...over };
}

describe("renderTipPage", () => {
  it("escapes every interpolated value", () => {
    const html = renderTipPage(profile, "sitekey");
    expect(html).toContain("Ada &lt;script&gt;");
    expect(html).toContain("Thanks &amp; &quot;see you&quot;");
    expect(html).not.toContain("Ada <script>");
  });

  it("keeps the inline script a static constant (CSP hash invariant)", () => {
    const html = renderTipPage(profile, "sitekey");
    expect(html).toContain(`<script>${_inlineScriptForTests}</script>`);
    // No template holes: rendering a hostile profile never changes the script.
    const hostile = renderTipPage({ ...profile, artistName: "x'); alert(1); ('" }, "k");
    expect(hostile).toContain(`<script>${_inlineScriptForTests}</script>`);
    // Nor does a hostile song library riding an open request window.
    const withRequests = renderTipPage(profile, "k", hostileConfig, openLive());
    expect(withRequests).toContain(`<script>${_inlineScriptForTests}</script>`);
  });

  it("prices Monzo in GBP on a EUR jar (button suffix)", () => {
    const html = renderTipPage(profile, "sitekey");
    expect(html).toContain("Monzo · GBP");
    expect(html).toContain(">Revolut</button>");
  });

  it("emits the CSP with the real script hash", () => {
    const csp = tipPageCsp();
    expect(csp).toContain("default-src 'none'");
    expect(csp).toMatch(/script-src 'sha256-[A-Za-z0-9+/=]+' https:\/\/challenges\.cloudflare\.com/);
  });

  it("renders the anti-enumeration 404 page", () => {
    expect(renderNotFoundPage()).toContain("This tip jar isn't active");
  });
});

describe("renderTipPage: song requests", () => {
  it("renders the section only when the config is enabled AND the window is open", () => {
    const closed = openLive({ openUntilMs: Date.now() - 1 });
    const combos: [RequestsConfig | undefined, RequestsLive | undefined, boolean][] = [
      [hostileConfig, openLive(), true], // enabled + open
      [hostileConfig, closed, false], // enabled + lapsed
      [{ ...hostileConfig, enabled: false }, openLive(), false], // disabled + open
      [undefined, undefined, false], // never configured
    ];
    for (const [config, live, expected] of combos) {
      const html = renderTipPage(profile, "sitekey", config, live);
      expect(html.includes('<section id="requests">')).toBe(expected);
      expect(html.includes("data-requests=")).toBe(expected);
    }
  });

  it("is byte-identical to the plain page when the config is disabled", () => {
    const plain = renderTipPage(profile, "sitekey");
    const disabled = renderTipPage(profile, "sitekey", { ...hostileConfig, enabled: false }, openLive());
    expect(disabled).toBe(plain);
    const noLive = renderTipPage(profile, "sitekey", hostileConfig, undefined);
    expect(noLive).toBe(plain);
  });

  it("escapes hostile song titles and artists", () => {
    const html = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(html).toContain("Wonder&lt;script&gt;alert(1)&lt;/script&gt;wall");
    expect(html).toContain("The &quot;Oasis&quot; &amp; Co");
    expect(html).not.toContain("<script>alert(1)");
  });

  it("prices each card: per-song override or the default, in page format", () => {
    const html = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(html).toContain("3 EUR"); // default 300 minor
    expect(html).toContain("5.50 EUR"); // s2's 550 override
  });

  it("offers no Monzo request button on a EUR jar, even when the config lists it", () => {
    // Monzo collects GBP; requests are priced in the jar's EUR — excluded,
    // exactly as the POST would refuse it. Revolut converts, so it stays.
    const html = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(html).toContain('data-reqmethod="revolut"');
    expect(html).not.toContain('data-reqmethod="monzo"');
    expect(html).not.toContain('data-reqmethod="mobilepay"'); // not configured on the jar at all
    // The escaped data-requests JSON carries the same filtered list.
    expect(html).toContain(escapeAttr('"methods":["revolut"]'));
  });

  it("renders the Stripe anchor slot only when a song carries a payment link", () => {
    const withStripe = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(withStripe).toContain('id="r-stripe"');
    expect(withStripe).toContain(escapeAttr("https://buy.stripe.com/xyz789")); // in data-requests

    // Same songs, but "stripe" is not an accepted request method: no anchor,
    // and the per-song link never even reaches the page data.
    const noStripeMethod = renderTipPage(
      profile,
      "sitekey",
      { ...hostileConfig, methods: ["revolut"] },
      openLive(),
    );
    expect(noStripeMethod).not.toContain('id="r-stripe"');
    expect(noStripeMethod).not.toContain("xyz789");

    const noSongLinks = renderTipPage(
      profile,
      "sitekey",
      { ...hostileConfig, songs: [{ id: "s1", title: "Wonderwall" }] },
      openLive(),
    );
    expect(noSongLinks).not.toContain('id="r-stripe"');
  });

  it("shows the live standing, and mutes played/skipped songs under a badge", () => {
    const live = openLive({
      songs: {
        s1: { t: 900, c: 3, s: "q" },
        s2: { t: 550, c: 1, s: "p" },
        s3: { t: 300, c: 1, s: "k" },
      },
    });
    const html = renderTipPage(profile, "sitekey", hostileConfig, live);
    expect(html).toContain("9 EUR · 3 fans");
    expect(html).toContain("5.50 EUR · 1 fan");
    expect(html).toContain(">Played</span>");
    expect(html).toContain(">Skipped</span>");
    // Queued songs are neither badged nor muted.
    expect(html).toContain('class="song" data-song="s1"');
    expect(html).toContain('class="song done" data-song="s2"');
    expect(html).toContain('class="song done" data-song="s3"');
  });
});

/** What a string looks like once it rides an escaped data-* attribute. */
function escapeAttr(text: string): string {
  return text.replace(/"/g, "&quot;");
}
