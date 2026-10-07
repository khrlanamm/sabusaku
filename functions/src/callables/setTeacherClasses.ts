import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {MAX_TEACHER_CLASSES} from "../domain/types";
import {claimsFor} from "../infra/accounts";
import {audit} from "../infra/audit";
import {auth, classesCol, db} from "../infra/firebase";
import {loadUser, parseInput, requireCaller} from "../infra/guard";
import {notifyClaimsChanged} from "../infra/notify";

const inputSchema = z.object({
  uid: z.string().min(1),
  classIds: z.array(z.string().min(1)).max(MAX_TEACHER_CLASSES),
});

/**
 * Sets the classes a teacher monitors. `users.classIds` is the source; it is
 * mirrored to `classes.teacherIds` for display and to the `classIds` claim
 * that security rules check.
 */
export const setTeacherClasses = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["admin"]);
  const input = parseInput(inputSchema, request.data);
  const classIds = [...new Set(input.classIds)];

  const teacher = await loadUser(caller.schoolId, input.uid);
  if (teacher.get("role") !== "guru") {
    throw new HttpsError("failed-precondition", "Hanya guru yang bisa ditugaskan ke kelas.");
  }

  const classes = classesCol(caller.schoolId);
  const found = await Promise.all(classIds.map((id) => classes.doc(id).get()));
  if (found.some((doc) => !doc.exists)) {
    throw new HttpsError("not-found", "Kelas tidak ditemukan.");
  }

  const previous = (teacher.get("classIds") as string[] | undefined) ?? [];
  const batch = db.batch();
  batch.update(teacher.ref, {classIds, updatedAt: FieldValue.serverTimestamp()});
  for (const id of previous.filter((id) => !classIds.includes(id))) {
    batch.update(classes.doc(id), {teacherIds: FieldValue.arrayRemove(input.uid)});
  }
  for (const id of classIds.filter((id) => !previous.includes(id))) {
    batch.update(classes.doc(id), {teacherIds: FieldValue.arrayUnion(input.uid)});
  }
  await batch.commit();

  await auth.setCustomUserClaims(input.uid, claimsFor(caller.schoolId, "guru", classIds));
  await notifyClaimsChanged(caller.schoolId, input.uid);
  await audit(caller.schoolId, caller.uid, "setTeacherClasses", {
    target: input.uid,
    classes: classIds.length,
  });

  return {ok: true};
});
