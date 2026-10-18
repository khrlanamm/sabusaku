import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {membersCol, schoolRef} from "../infra/firebase";
import {parseInput, requireSuperadmin} from "../infra/guard";
import {ClaimResult, MemberError, moveSuperadmin} from "../infra/members";
import {SCHOOL_ID_RE} from "../infra/schools";

const inputSchema = z.object({schoolId: z.string().regex(SCHOOL_ID_RE)});

/**
 * Moves a superadmin to another school as its teacher (penanggung jawab).
 * The app refreshes the token afterwards and opens that school.
 */
export const switchSchool = onCall(CALLABLE_OPTIONS, async (request): Promise<ClaimResult> => {
  const superadmin = requireSuperadmin(request);
  const {schoolId} = parseInput(inputSchema, request.data);
  if (!(await schoolRef(schoolId).get()).exists) {
    throw new HttpsError("not-found", "Sekolah tidak ditemukan.");
  }

  const from = (await membersCol().doc(superadmin.email).get()).get("schoolId") ?? null;
  try {
    const result = await moveSuperadmin(
      superadmin.uid,
      superadmin.email,
      superadmin.name,
      schoolId,
      superadmin.picture,
    );
    await audit(schoolId, superadmin.uid, "switchSchool", {from});
    return result;
  } catch (error) {
    if (error instanceof MemberError) throw new HttpsError("failed-precondition", error.message);
    throw error;
  }
});
