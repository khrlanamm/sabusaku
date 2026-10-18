import {HttpsError, onCall} from "firebase-functions/v2/https";

import {CALLABLE_OPTIONS, isSuperadmin} from "../config";
import {db} from "../infra/firebase";
import {claimMembership, ClaimResult, moveSuperadmin} from "../infra/members";

/**
 * Joins a signed-in account to the school whose roster lists its email
 * (`members/{email}`). The app calls it whenever the token has no school yet.
 *
 * The email must be verified: Google accounts always are; an address that
 * signed up with a password proves ownership through the verification email.
 */
export const claimAccount = onCall(CALLABLE_OPTIONS, async (request): Promise<ClaimResult> => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");
  const token = request.auth.token;
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

  const picture = typeof token.picture === "string" ? token.picture : null;
  const result =
    (await claimMembership(request.auth.uid, token.email, picture)) ??
    (await joinFirstSchool(request.auth.uid, token.email, token.name, picture));
  if (!result) {
    throw new HttpsError("not-found", "Email belum terdaftar di sekolah mana pun.", {
      reason: "not-registered",
    });
  }
  return result;
});

/**
 * A superadmin on no roster yet (their first sign-in) starts as a teacher of
 * the first active school; from there they switch or create schools.
 */
async function joinFirstSchool(
  uid: string,
  email: string,
  name: unknown,
  picture: string | null,
): Promise<ClaimResult | null> {
  if (!isSuperadmin(email)) return null;
  const first = await db.collection("schools").where("status", "==", "active").limit(1).get();
  if (first.empty) return null;
  const displayName = typeof name === "string" && name.trim().length >= 2 ? name.trim() : "Superadmin";
  return moveSuperadmin(uid, email, displayName, first.docs[0].id, picture);
}
