import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {normalizeEmail} from "../domain/labels";
import {audit} from "../infra/audit";
import {membersCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";
import {eraseStudentData, revokeSchoolAccess} from "../infra/members";

const inputSchema = z.object({email: z.string().min(3).max(320)});

/**
 * Permanently deletes everything a student has in the caller's school
 * (docs/03 §5): roster entry, profile, summary, and every program with its
 * journals and comments. Irreversible. The student's sign-in account belongs
 * to them and is kept; it just no longer has a school.
 */
export const eraseStudent = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 300},
  async (request): Promise<{programs: number}> => {
    const caller = await requireCaller(request, ["guru"]);
    const email = normalizeEmail(parseInput(inputSchema, request.data).email);

    const memberRef = membersCol().doc(email);
    const member = await memberRef.get();
    if (!member.exists || member.get("schoolId") !== caller.schoolId) {
      throw new HttpsError("not-found", "Siswa tidak ditemukan.");
    }
    if (member.get("role") !== "siswa") {
      throw new HttpsError("permission-denied", "Hanya data siswa yang bisa dihapus.");
    }

    const uid = (member.get("uid") as string | null) ?? null;
    // Lock the student out first so nothing is written while data is removed.
    if (uid) await revokeSchoolAccess(uid);
    await memberRef.delete();
    const programs = uid ? await eraseStudentData(caller.schoolId, uid) : 0;

    await audit(caller.schoolId, caller.uid, "eraseStudent", {target: uid, programs});
    return {programs};
  },
);
