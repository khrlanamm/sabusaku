import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {normalizeEmail} from "../domain/labels";
import {audit} from "../infra/audit";
import {membersCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";
import {MemberError, removeMember} from "../infra/members";
import {notifyClaimsChanged} from "../infra/notify";

const inputSchema = z.object({email: z.string().min(3).max(320)});

/**
 * Takes a student out of the caller's school. The student's own account is
 * kept and their journals stay in the school: adding the same email again
 * restores everything.
 */
export const removeStudent = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["guru"]);
  const email = normalizeEmail(parseInput(inputSchema, request.data).email);

  const member = await membersCol().doc(email).get();
  if (!member.exists || member.get("schoolId") !== caller.schoolId) {
    throw new HttpsError("not-found", "Siswa tidak ditemukan.");
  }
  if (member.get("role") !== "siswa") {
    throw new HttpsError("permission-denied", "Keluarkan penanggung jawab dari tab Sekolah.");
  }

  try {
    const uid = await removeMember(caller.schoolId, email);
    if (uid) await notifyClaimsChanged(caller.schoolId, uid);
  } catch (error) {
    if (error instanceof MemberError) throw new HttpsError("not-found", error.message);
    throw error;
  }
  await audit(caller.schoolId, caller.uid, "removeStudent", {target: member.get("uid") ?? null});
  return {ok: true};
});
