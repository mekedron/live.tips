/// The trusted client IP, recovered from X-Forwarded-For by hop count.
///
/// `req.ip` is a trap on this runtime: the functions framework enables
/// `trust proxy = true`, so express resolves it to the LEFTMOST
/// X-Forwarded-For entry — the one the CLIENT wrote, not the one the platform
/// saw. Every per-IP quota keyed on that could be bypassed with a rotating
/// header, or aimed at a victim by writing their address into it. The worker
/// read CF-Connecting-IP, which the edge wrote and no client could forge;
/// this module recovers that property on Cloud Run, where each Google hop
/// APPENDS the address of the peer it accepted the connection from: the
/// rightmost `trustedHops` entries are platform-written, and the innermost
/// of them is the client.

import type { IncomingHttpHeaders } from "node:http";

/** The slice of a request the derivation reads. An express request and a
 * callable's rawRequest both fit — never `.ip`, which trust-proxy poisons. */
export interface IpSource {
  headers: IncomingHttpHeaders;
  socket?: { remoteAddress?: string | undefined };
}

/** Callables are invoked at the function URL: client → Cloud Run ingress. */
export const DIRECT_HOPS = 1;

/**
 * The tip surface arrives through the Hosting rewrite: client → Hosting CDN
 * (appends the client's address) → Cloud Run ingress (appends the CDN's), so
 * the client sits second from the right.
 */
export const HOSTING_HOPS = 2;

/**
 * The entry `trustedHops` from the right of X-Forwarded-For. With fewer
 * entries than that (unit tests, the emulators, a bare socket) the peer
 * address is the only one nobody else wrote — fall back to it rather than
 * to anything client-supplied.
 */
export function clientIp(req: IpSource, trustedHops: number): string {
  const header = req.headers["x-forwarded-for"];
  const entries = (Array.isArray(header) ? header.join(",") : header ?? "")
    .split(",")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0);
  if (entries.length < trustedHops) return req.socket?.remoteAddress ?? "unknown";
  return entries[entries.length - trustedHops]!;
}
