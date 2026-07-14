import { defineConfig } from "vitest/config";

// Emulator-backed rules tests. Unlike firebase/functions (pure logic, no
// emulator), this suite MUST run under `firebase emulators:exec` so the real
// firestore.rules are evaluated against the Firestore emulator. The npm
// `test` script wires that up; running `vitest` bare will fail to connect.
export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    // The emulator round-trips are slower than pure-logic assertions, and the
    // whole file shares one emulator, so keep it single-threaded and patient.
    fileParallelism: false,
    testTimeout: 15000,
    hookTimeout: 30000,
  },
});
