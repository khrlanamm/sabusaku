import {HttpsError, onCall} from "firebase-functions/v2/https";

import {CALLABLE_OPTIONS} from "../config";
import {isSuperadminEmail} from "../domain/superadmin";
import {requireSuperadmin, SuperadminCaller} from "../infra/guard";
import {claimMembership, ClaimResult} from "../infra/members";
import {enterSchool, pickSchool} from "../infra/superadmin";

/**
 * Joins a signed-in account to the school whose roster lists its email
 * (`members/{email}`). The app calls it whenever the token has no school yet.
 *
 * The email must be verified: Google accounts always are; an address that
 * signed up with a password proves ownership through the verification email.
 *
 * The superadmin is on no roster: they keep the school they have open, or get
 * the first one, so signing in again never moves them.
 */
export const claimAccount = onCall(CALLABLE_OPTIONS, async (request): Promise<ClaimResult> => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");
  const token = request.auth.token;
  if (isSuperadminEmail(token.email)) {
    // An unproven address falls through to the checks below.
    const superadmin = await requireSuperadmin(request).catch(() => null);
    if (superadmin) return claimForSuperadmin(superadmin);
  }
  if (!token.email) {
    throw new HttpsError("failed-precondition", "Akun ini tidak punya email.", {
      reason: "not-registered",
    });
  }
  if (token.email_verified !== true) {
    throw new HttpsError("failed-precondition", "Email belum diverifikasi.", {
      reason: "email-not-verified",
    });
  }

  const result = await claimMembership(
    request.auth.uid,
    token.email,
    typeof token.picture === "string" ? token.picture : null,
  );
  if (!result) {
    throw new HttpsError("not-found", "Email belum terdaftar di sekolah mana pun.", {
      reason: "not-registered",
    });
  }
  return result;
});

async function claimForSuperadmin(caller: SuperadminCaller): Promise<ClaimResult> {
  const schoolId = await pickSchool(caller.schoolId);
  if (!schoolId) {
    throw new HttpsError("not-found", "Belum ada sekolah. Buat dengan tools/create-school.ts.", {
      reason: "not-registered",
    });
  }
  return enterSchool(caller.uid, caller.email, schoolId, caller.schoolId);
}
