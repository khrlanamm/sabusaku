import {defineConfig} from "vitest/config";

export default defineConfig({
  test: {
    // Emulator-backed suites share one Firestore, so files must not interleave.
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 60_000,
  },
});
