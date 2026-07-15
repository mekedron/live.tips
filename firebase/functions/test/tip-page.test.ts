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

  it("lists Card first, then the relay methods, and marks Monzo's GBP on a EUR jar", () => {
    const html = renderTipPage(profile, "sitekey");
    // Card is a UI method (data-method="card") carrying its Stripe link.
    expect(html).toContain('data-method="card"');
    expect(html).toContain('<span class="method-label">Monzo · GBP</span>');
    expect(html).toContain('<span class="method-label">Revolut</span>');
    // Its own currency (EUR) rides no suffix.
    expect(html).toContain('<span class="method-label">Revolut</span>');
    expect(html).not.toContain("Revolut · EUR");
  });

  it("marks each priced method with its currency symbol and placement", () => {
    // EUR trails, GBP leads — the script formats amounts from these fields.
    const eur = renderTipPage(profile, "sitekey");
    expect(eur).toContain(escapeAttr('"sym":"€"'));
    expect(eur).toContain(escapeAttr('"symLeads":false'));
    const gbp = renderTipPage({ ...profile, currency: "gbp" }, "sitekey");
    expect(gbp).toContain(escapeAttr('"sym":"£"'));
    expect(gbp).toContain(escapeAttr('"symLeads":true'));
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
      expect(html.includes('id="s-songs"')).toBe(expected);
      expect(html.includes("data-requests=")).toBe(expected);
      expect(html.includes('id="tab-requests"')).toBe(expected);
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

  it("prices each card with the currency symbol: per-song override or the default", () => {
    const html = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(html).toContain("Request · 3 €"); // default 300 minor
    expect(html).toContain("Request · 5.50 €"); // s2's 550 override
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

  it("labels a song's action Boost once it has fans, Request while it has none, and hides it once done", () => {
    const live = openLive({
      songs: {
        s1: { t: 900, c: 3, s: "q" }, // has fans -> Boost
        // s2 unrequested -> "Request · <price>"
        s3: { t: 300, c: 1, s: "k" }, // done -> no action shown
      },
    });
    const html = renderTipPage(profile, "sitekey", hostileConfig, live);
    expect(html).toContain('<span class="song-action boost">Boost</span>');
    // s2 carries its own 550-minor override, not the 300-minor default.
    expect(html).toContain('<span class="song-action">Request · 5.50 €</span>');
    expect(html).toContain('<span class="song-action" hidden></span>');
  });

  it("ranks songs by standing, played/skipped last, ties broken by the artist's configured order", () => {
    const live = openLive({
      songs: {
        s1: { t: 300, c: 1, s: "q" },
        s2: { t: 900, c: 3, s: "q" },
      },
    });
    const html = renderTipPage(profile, "sitekey", hostileConfig, live);
    // s2 outranks s1 (more support) despite s1 being configured first; s3
    // (no votes) sorts after both, ranked entries carry a numeric badge.
    const s2At = html.indexOf('data-song="s2"');
    const s1At = html.indexOf('data-song="s1"');
    const s3At = html.indexOf('data-song="s3"');
    expect(s2At).toBeGreaterThan(-1);
    expect(s2At).toBeLessThan(s1At);
    expect(s1At).toBeLessThan(s3At);
    expect(html).toContain('<span class="song-rank" aria-hidden="true">1</span>');
    expect(html).toContain('<span class="song-rank" aria-hidden="true">2</span>');
  });

  it("offers the Stripe request radio only when a song carries a payment link", () => {
    // The inline script mentions [data-reqmethod="stripe"] in a selector, so
    // assert on the rendered BUTTON markup, not the bare attribute.
    const stripeRadio = 'class="method" data-reqmethod="stripe"';
    const withStripe = renderTipPage(profile, "sitekey", hostileConfig, openLive());
    expect(withStripe).toContain(stripeRadio);
    expect(withStripe).toContain(escapeAttr("https://buy.stripe.com/xyz789")); // in data-requests

    // Same songs, but "stripe" is not an accepted request method: no radio,
    // and the per-song link never even reaches the page data.
    const noStripeMethod = renderTipPage(
      profile,
      "sitekey",
      { ...hostileConfig, methods: ["revolut"] },
      openLive(),
    );
    expect(noStripeMethod).not.toContain(stripeRadio);
    expect(noStripeMethod).not.toContain("xyz789");

    const noSongLinks = renderTipPage(
      profile,
      "sitekey",
      { ...hostileConfig, songs: [{ id: "s1", title: "Wonderwall" }] },
      openLive(),
    );
    expect(noSongLinks).not.toContain(stripeRadio);
  });

  it("shows the live standing with the symbol, and mutes played/skipped songs under a badge", () => {
    const live = openLive({
      songs: {
        s1: { t: 900, c: 3, s: "q" },
        s2: { t: 550, c: 1, s: "p" },
        s3: { t: 300, c: 1, s: "k" },
      },
    });
    const html = renderTipPage(profile, "sitekey", hostileConfig, live);
    expect(html).toContain('<span class="song-standing">9 € · 3 fans</span>');
    // Once a song is done, its standing is hidden — the badge takes over.
    expect(html).toContain('<span class="song-standing" hidden></span>');
    expect(html).toContain('<span class="song-badge">Played</span>');
    expect(html).toContain('<span class="song-badge">Skipped</span>');
    // Queued songs are neither badged nor muted.
    expect(html).toContain('class="song" data-song="s1"');
    expect(html).toContain('class="song done" data-song="s2"');
    expect(html).toContain('class="song done" data-song="s3"');
  });

  it("disables played/skipped songs so they cannot be donated to", () => {
    const live = openLive({
      songs: {
        s1: { t: 900, c: 3, s: "q" }, // active -> clickable
        s2: { t: 550, c: 1, s: "p" }, // played -> disabled
        s3: { t: 300, c: 1, s: "k" }, // skipped -> disabled
      },
    });
    const html = renderTipPage(profile, "sitekey", hostileConfig, live);
    expect(html).toContain('class="song done" data-song="s2" disabled>');
    expect(html).toContain('class="song done" data-song="s3" disabled>');
    // An active song stays enabled (no disabled attribute on its button tag).
    expect(html).toContain('class="song" data-song="s1">');
  });
});

/** What a string looks like once it rides an escaped data-* attribute. */
function escapeAttr(text: string): string {
  return text.replace(/&/g, "&amp;").replace(/"/g, "&quot;");
}
