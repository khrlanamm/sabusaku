import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {auth} from "../infra/firebase";
import {loadUser, parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({uid: z.string().min(1), active: z.boolean()});

/**
 * Activates or deactivates an account. A deactivated user cannot sign in and
 * loses their sessions; their data is kept (PRD BR-15). The `onUserUpdated`
 * trigger hides or restores a student's summary on teacher dashboards.
 */
export const setUserActive = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["admin"]);
  const {uid, active} = parseInput(inputSchema, request.data);
  if (uid === caller.uid) {
    throw new HttpsError("failed-precondition", "Tidak bisa menonaktifkan akun sendiri.");
  }

  const target = await loadUser(caller.schoolId, uid);
  await auth.updateUser(uid, {disabled: !active});
  if (!active) await auth.revokeRefreshTokens(uid);
  await target.ref.update({
    status: active ? "active" : "disabled",
    updatedAt: FieldValue.serverTimestamp(),
  });
  await audit(caller.schoolId, caller.uid, "setUserActive", {target: uid, active});

  return {ok: true};
});
