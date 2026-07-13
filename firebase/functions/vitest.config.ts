import { defineConfig } from "vitest/config";

// Pure-logic tests only — no Firestore emulator, no firebase-admin import.
export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
  },
});
