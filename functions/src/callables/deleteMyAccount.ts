import {HttpsError, onCall} from "firebase-functions/v2/https";

import {CALLABLE_OPTIONS} from "../config";
import {normalizeEmail} from "../domain/labels";
import {audit} from "../infra/audit";
import {auth, db, deleteAvatar, membersCol, usersCol} from "../infra/firebase";
import {eraseStudentData, revokeSchoolAccess} from "../infra/members";
import {forgetReports} from "../infra/reports";

/**
 * Deletes the caller's own account from inside the app (Google Play requires
 * this for apps where accounts are created in the app). A student's journals
 * are deleted with it; a teacher's profile and roster entry go too, while the
 * comments they wrote stay with the students' journals. Either way the
 * reports they filed go, and reports about them lose their copy of the
 * content. The superadmin, with a profile in every school they opened, is
 * refused.
 */
export const deleteMyAccount = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 300},
  async (request): Promise<{ok: true}> => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");
    if ((request.auth.token as Record<string, unknown>).superadmin === true) {
      throw new HttpsError("failed-precondition", "Akun superadmin tidak bisa dihapus dari aplikasi.");
    }
    const uid = request.auth.uid;
    const email = request.auth.token.email ? normalizeEmail(request.auth.token.email) : null;

    const member = email ? await membersCol().doc(email).get() : null;
    const schoolId =
      (member?.exists && member.get("uid") === uid ? (member.get("schoolId") as string) : null) ??
      ((request.auth.token as Record<string, unknown>).schoolId as string | undefined) ??
      null;

    await revokeSchoolAccess(uid);
    if (member?.exists && member.get("uid") === uid) await member.ref.delete();

    if (schoolId) {
      const profile = await usersCol(schoolId).doc(uid).get();
      if (profile.get("role") === "siswa") {
        await eraseStudentData(schoolId, uid);
      } else {
        await db.recursiveDelete(profile.ref);
        await deleteAvatar(schoolId, uid);
        await forgetReports(uid);
      }
      await audit(schoolId, uid, "deleteMyAccount", {role: profile.get("role") ?? null});
    } else {
      // Someone already removed from their school may still have reports.
      await forgetReports(uid);
    }

    await auth.deleteUser(uid);
    return {ok: true};
  },
);
