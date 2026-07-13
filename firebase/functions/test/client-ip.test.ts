/// The X-Forwarded-For derivation that trust-proxy got wrong in production.
///
/// The regression this pins down: the functions runtime enables
/// `trust proxy = true`, so `req.ip` resolved to the LEFTMOST header entry —
/// the one the CLIENT wrote — and every per-IP quota could be bypassed with a
/// rotating header, or exhausted on behalf of a spoofed victim address. The
/// handler tests never saw it because they call the handlers directly: no
/// proxy, no header, `req.ip` is whatever the harness sets. These tests feed
/// the derivation the header an attacker would actually send.

import { describe, expect, it } from "vitest";
import { DIRECT_HOPS, HOSTING_HOPS, clientIp } from "../src/client-ip";

const CLIENT = "203.0.113.9"; // the address the platform saw
const FORGED = "198.51.100.66"; // the address the attacker typed
const CDN = "216.239.36.53"; // the Hosting hop Cloud Run appended

function req(xff: string | string[] | undefined, socket = "169.254.8.129") {
  return {
    headers: xff === undefined ? {} : { "x-forwarded-for": xff },
    socket: { remoteAddress: socket },
  };
}

describe("clientIp behind the Hosting rewrite (tip surface)", () => {
  it("picks the platform-appended entry, never the client-forged one", () => {
    expect(clientIp(req(`${FORGED}, ${CLIENT}, ${CDN}`), HOSTING_HOPS)).toBe(CLIENT);
  });

  it("a rotating forged header never moves the derived IP", () => {
    for (const junk of ["10.0.0.1", "8.8.8.8", "2001:db8::1", "1.1.1.1, 2.2.2.2"]) {
      expect(clientIp(req(`${junk}, ${CLIENT}, ${CDN}`), HOSTING_HOPS)).toBe(CLIENT);
    }
  });

  it("an honest request (no client-written entries) resolves the same way", () => {
    expect(clientIp(req(`${CLIENT}, ${CDN}`), HOSTING_HOPS)).toBe(CLIENT);
  });

  it("whitespace and empty segments do not shift the count", () => {
    expect(clientIp(req(` ${FORGED} ,, ${CLIENT} ,  ${CDN} `), HOSTING_HOPS)).toBe(CLIENT);
  });

  it("repeated headers arrive as an array and still parse right-to-left", () => {
    expect(clientIp(req([FORGED, `${CLIENT}, ${CDN}`]), HOSTING_HOPS)).toBe(CLIENT);
  });
});

describe("clientIp on the direct surfaces (callables)", () => {
  it("rightmost entry: the peer Cloud Run itself recorded", () => {
    expect(clientIp(req(`${FORGED}, ${CLIENT}`), DIRECT_HOPS)).toBe(CLIENT);
    expect(clientIp(req(CLIENT), DIRECT_HOPS)).toBe(CLIENT);
  });
});

describe("clientIp off-platform (tests, emulators, bare sockets)", () => {
  it("no header at all: the socket peer answers", () => {
    expect(clientIp(req(undefined, "127.0.0.1"), DIRECT_HOPS)).toBe("127.0.0.1");
  });

  it("fewer entries than trusted hops falls back to the socket, never to a client-written entry", () => {
    expect(clientIp(req(FORGED, "127.0.0.1"), HOSTING_HOPS)).toBe("127.0.0.1");
  });

  it("no header and no socket: 'unknown'", () => {
    expect(clientIp({ headers: {} }, DIRECT_HOPS)).toBe("unknown");
  });
});
