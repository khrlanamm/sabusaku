import {EMAIL_DOMAIN} from "../config";

/** Lowercase letters and digits, optionally joined by single `.`, `_` or `-`. */
const USERNAME_RE = /^[a-z0-9]+(?:[._-][a-z0-9]+)*$/;
const SCHOOL_ID_RE = /^[a-z0-9]{3,20}$/;

export function normalizeUsername(raw: string): string {
  return raw.trim().toLowerCase();
}

export function isValidUsername(username: string): boolean {
  return username.length >= 3 && username.length <= 30 && USERNAME_RE.test(username);
}

export function isValidSchoolId(schoolId: string): boolean {
  return SCHOOL_ID_RE.test(schoolId);
}

/**
 * Firebase Auth is email based while users sign in with a username or NIS, so
 * each account gets a deterministic address that is never mailed.
 */
export function pseudoEmail(schoolId: string, username: string): string {
  return `${username}@${schoolId}.${EMAIL_DOMAIN}`;
}
