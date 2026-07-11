import { SELF } from "cloudflare:test";
import { expect } from "vitest";

let ipCounter = 0;
export function uniqueIp(): string {
  ipCounter += 1;
  return `203.0.113.${ipCounter % 250}`;
}

export async function createJar(
  overrides: Record<string, unknown> = {},
): Promise<{ jarId: string; secret: string; tipUrl: string }> {
  const res = await SELF.fetch("https://api.live.tips/v1/jars", {
    method: "POST",
    headers: { "content-type": "application/json", "CF-Connecting-IP": uniqueIp() },
    body: JSON.stringify({
      artistName: "Ada Lovelace",
      message: "Thanks for listening!",
      currency: "eur",
      methods: {
        stripeUrl: "https://donate.stripe.com/testCode123",
        revolutUsername: "mekedron",
        mobilepayBoxId: "a76b1e43-1958-483c-b602-da5869f57212",
      },
      ...overrides,
    }),
  });
  expect(res.status).toBe(201);
  return res.json();
}
