import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {schoolRef} from "../infra/firebase";
import {parseInput, requireSuperadmin} from "../infra/guard";
import {enterSchool} from "../infra/superadmin";

const inputSchema = z.object({schoolId: z.string().min(1).max(30)});

/**
 * Opens another school for the superadmin, as one of its teachers. The app
 * refreshes the token afterwards. A suspended school can be opened too.
 */
export const switchSchool = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{schoolId: string}> => {
    const caller = await requireSuperadmin(request);
    const {schoolId} = parseInput(inputSchema, request.data);
    if (!(await schoolRef(schoolId).get()).exists) {
      throw new HttpsError("not-found", "Sekolah tidak ditemukan.");
    }

    await enterSchool(caller.uid, caller.email, schoolId, caller.schoolId);
    await audit(schoolId, caller.uid, "switchSchool", {from: caller.schoolId});
    return {schoolId};
  },
);
