import { describe, expect, it } from "vitest";
import { _inlineScriptForTests, renderNotFoundPage, renderTipPage, tipPageCsp } from "../src/tip-page";
import type { JarProfile } from "../src/types";

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
