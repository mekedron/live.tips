import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          // Test-only secrets; production values come from `wrangler secret put`.
          bindings: {
            // Cloudflare's always-passing Turnstile test secret.
            TURNSTILE_SECRET: "1x0000000000000000000000000000000AA",
            ADMIN_TOKEN: "test-admin-token",
            IP_HASH_SALT: "test-ip-hash-salt",
          },
        },
      },
    },
  },
});
