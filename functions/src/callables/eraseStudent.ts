import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {activeProgramsCol, auth, db, programsCol, statsCol} from "../infra/firebase";
import {loadUser, parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({uid: z.string().min(1)});

/**
 * Permanently removes a student: sign-in account, profile, summary, and every
 * program with its journals and comments (docs/03 §5). Used when a student
 * graduates or the school asks for deletion. Irreversible.
 */
export const eraseStudent = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 300},
  async (request): Promise<{programs: number}> => {
    const caller = await requireCaller(request, ["admin"]);
    const {uid} = parseInput(inputSchema, request.data);

    const student = await loadUser(caller.schoolId, uid);
    if (student.get("role") !== "siswa") {
      throw new HttpsError("failed-precondition", "Hanya data siswa yang bisa dihapus.");
    }

    // Lock the account first so the student cannot write while data is removed.
    await auth.updateUser(uid, {disabled: true});
    await auth.revokeRefreshTokens(uid);

    // The profile goes first: triggers fired by the deletes below then find no
    // student and do not rebuild the summary.
    await db.recursiveDelete(student.ref);
    await activeProgramsCol(caller.schoolId).doc(uid).delete();
    await statsCol(caller.schoolId).doc(uid).delete();

    const programs = await programsCol(caller.schoolId).where("studentId", "==", uid).get();
    for (const program of programs.docs) await db.recursiveDelete(program.ref);

    await auth.deleteUser(uid);
    await audit(caller.schoolId, caller.uid, "eraseStudent", {
      target: uid,
      programs: programs.size,
    });

    return {programs: programs.size};
  },
);
