import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {auth} from "../infra/firebase";
import {loadUser, parseInput, requireCaller} from "../infra/guard";
import {generatePassword} from "../infra/passwords";

const inputSchema = z.object({uid: z.string().min(1)});

/**
 * Issues a temporary password. Admins may reset anyone in their school;
 * teachers only students of the classes they are assigned to. There is no
 * email reset: sign-in emails are synthetic.
 */
export const resetPassword = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{username: string; password: string}> => {
    const caller = await requireCaller(request, ["admin", "guru"]);
    const {uid} = parseInput(inputSchema, request.data);
    if (uid === caller.uid) {
      throw new HttpsError("failed-precondition", "Gunakan menu Ubah password untuk akun sendiri.");
    }

    const target = await loadUser(caller.schoolId, uid);
    if (caller.role === "guru") {
      const inMyClass =
        target.get("role") === "siswa" && caller.classIds.includes(target.get("classId"));
      // Same answer as a missing user: a teacher must not learn who exists.
      if (!inMyClass) throw new HttpsError("not-found", "Pengguna tidak ditemukan.");
    }

    const password = generatePassword();
    await auth.updateUser(uid, {password});
    await auth.revokeRefreshTokens(uid);
    await target.ref.update({
      mustChangePassword: true,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await audit(caller.schoolId, caller.uid, "resetPassword", {target: uid});

    return {username: target.get("username") as string, password};
  },
);
