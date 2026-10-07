import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {classesCol} from "../infra/firebase";
import {loadUser, parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({uid: z.string().min(1), classId: z.string().min(1)});

/**
 * Moves a student to another class. Only the profile changes here; the
 * `onUserUpdated` trigger carries the new class to the student's programs and
 * summary, which is what moves teacher access (PRD BR-14).
 */
export const moveStudentClass = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["admin"]);
  const {uid, classId} = parseInput(inputSchema, request.data);

  const student = await loadUser(caller.schoolId, uid);
  if (student.get("role") !== "siswa") {
    throw new HttpsError("failed-precondition", "Hanya siswa yang bisa dipindah kelas.");
  }
  const target = await classesCol(caller.schoolId).doc(classId).get();
  if (!target.exists) throw new HttpsError("not-found", "Kelas tidak ditemukan.");
  if (target.get("isArchived") === true) {
    throw new HttpsError("failed-precondition", "Kelas sudah diarsipkan.");
  }

  if (student.get("classId") !== classId) {
    await student.ref.update({classId, updatedAt: FieldValue.serverTimestamp()});
    await audit(caller.schoolId, caller.uid, "moveStudentClass", {target: uid, classId});
  }
  return {ok: true};
});
