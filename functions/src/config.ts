/** Firestore lives in Jakarta, so every function runs there too (docs/02). */
export const REGION = "asia-southeast2";

/**
 * Applied to every callable. App Check enforcement stays off until the Play
 * App Signing certificate is registered, otherwise Play Integrity would reject
 * every build (docs/03 §4).
 */
export const CALLABLE_OPTIONS = {enforceAppCheck: false} as const;
