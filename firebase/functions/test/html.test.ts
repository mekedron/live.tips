import { describe, expect, it } from "vitest";
import { html, raw, SafeHtml } from "../src/html";

describe("html tagged template", () => {
  it("escapes every interpolated string by default", () => {
    const evil = 'x"><script>alert(1)</script>';
    const out = html`<div title="${evil}">${evil}</div>`.value;
    expect(out).toBe(
      '<div title="x&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;">x&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;</div>',
    );
    expect(out).not.toContain("<script>");
  });

  it("emits numbers verbatim and drops null/undefined/false", () => {
    expect(html`${5}${null}${undefined}${false}`.value).toBe("5");
  });

  it("passes raw() strings through unescaped", () => {
    expect(html`<style>${raw("a>b & c")}</style>`.value).toBe("<style>a>b & c</style>");
  });

  it("nests SafeHtml results without double-escaping", () => {
    const inner = html`<b>${"A & B"}</b>`;
    expect(html`<p>${inner}</p>`.value).toBe("<p><b>A &amp; B</b></p>");
  });

  it("joins arrays of fragments", () => {
    const items = ["a", "b"].map((c) => html`<li>${c}</li>`);
    expect(html`<ul>${items}</ul>`.value).toBe("<ul><li>a</li><li>b</li></ul>");
  });

  it("returns a SafeHtml whose toString is its value", () => {
    const s = html`<i>hi</i>`;
    expect(s).toBeInstanceOf(SafeHtml);
    expect(`${s}`).toBe("<i>hi</i>");
  });
});
