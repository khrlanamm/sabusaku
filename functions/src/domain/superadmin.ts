// The superadmin adds schools with their first teacher and opens any school
// as one of its teachers (docs/07). Revoking: drop the email here, deploy,
// then clear the account's claims.

import {normalizeEmail} from "./labels";

export const SUPERADMIN_EMAILS: readonly string[] = ["benevology@gmail.com"];

export function isSuperadminEmail(email: string | null | undefined): boolean {
  return !!email && SUPERADMIN_EMAILS.includes(normalizeEmail(email));
}
