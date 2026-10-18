import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS, isSuperadmin} from "../config";
import {normalizeEmail} from "../domain/labels";
import {audit} from "../infra/audit";
import {membersCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";
import {MemberError, removeMember} from "../infra/members";
import {notifyClaimsChanged} from "../infra/notify";

const inputSchema = z.object({email: z.string().min(3).max(320)});

/**
 * Takes another teacher out of the caller's school, or withdraws the
 * invitation of one who has not signed in yet. Their own account stays. A
 * teacher cannot remove themselves, so a school always keeps at least one,
 * nor a superadmin, who leaves a school by switching to another.
 */
export const removeTeacher = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["guru"]);
  const email = normalizeEmail(parseInput(inputSchema, request.data).email);

  const member = await membersCol().doc(email).get();
  if (!member.exists || member.get("schoolId") !== caller.schoolId || member.get("role") !== "guru") {
    throw new HttpsError("not-found", "Penanggung jawab tidak ditemukan.");
  }
  if (member.get("uid") === caller.uid) {
    throw new HttpsError("failed-precondition", "Tidak bisa mengeluarkan diri sendiri.");
  }
  if (isSuperadmin(email)) {
    throw new HttpsError("failed-precondition", "Superadmin tidak bisa dikeluarkan.");
  }

  try {
    const uid = await removeMember(caller.schoolId, email);
    if (uid) await notifyClaimsChanged(caller.schoolId, uid);
  } catch (error) {
    if (error instanceof MemberError) throw new HttpsError("not-found", error.message);
    throw error;
  }
  await audit(caller.schoolId, caller.uid, "removeTeacher", {target: member.get("uid") ?? null});
  return {ok: true};
});
