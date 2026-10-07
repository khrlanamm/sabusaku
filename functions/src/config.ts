/** Firestore lives in Jakarta, so every function runs there too (docs/02). */
export const REGION = "asia-southeast2";

/**
 * Domain of the synthetic sign-in emails (`{username}@{schoolId}.{domain}`).
 *
 * `.invalid` is reserved (RFC 2606) and can never receive mail. Anyone holding
 * the public API key can ask Firebase Auth to send a password-reset email, so
 * the domain must be one nobody can ever own.
 */
export const EMAIL_DOMAIN = "sabusaku.invalid";

/**
 * Applied to every callable. App Check enforcement stays off until the Play
 * App Signing certificate is registered, otherwise Play Integrity would reject
 * every build (docs/03 §4).
 */
export const CALLABLE_OPTIONS = {enforceAppCheck: false} as const;
