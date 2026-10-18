/** Firestore lives in Jakarta, so every function runs there too (docs/02). */
export const REGION = "asia-southeast2";

/**
 * Applied to every callable. App Check enforcement stays off until the Play
 * App Signing certificate is registered, otherwise Play Integrity would reject
 * every build (docs/03 §4).
 */
export const CALLABLE_OPTIONS = {enforceAppCheck: false} as const;

/**
 * Applied to every Firestore trigger and schedule. Nobody waits on them, so
 * they run on a fraction of a vCPU, as in Cloud Functions gen 1 (0.167 vCPU at
 * 256 MiB, 0.333 at 512 MiB), one event per instance; more instances make up
 * for that. Cloud Run's CPU quota in asia-southeast2 is 20 vCPU for all running
 * instances together, and a deploy starts one instance per function, so this
 * keeps a full deploy inside it.
 */
export const BACKGROUND_OPTIONS = {cpu: "gcf_gen1", maxInstances: 20} as const;
