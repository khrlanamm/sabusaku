import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {auth} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";
import {addMember, claimMembership, cleanMember, loadSchoolLabels} from "../infra/members";

const inputSchema = z.object({
  email: z.string().max(320),
  name: z.string().max(200),
  homeroomClass: z.string().max(40).nullish(),
  extracurriculars: z.array(z.string().max(80)).max(20).optional(),
});

/**
 * Puts another teacher (penanggung jawab) on the caller's school roster, with
 * an optional homeroom class and supervised extracurriculars. No account is
 * created: the teacher signs in with Google or signs up with that email.
 * Someone who already has a verified account with it joins right away.
 */
export const addTeacher = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{joined: boolean}> => {
    const caller = await requireCaller(request, ["guru"]);
    const input = parseInput(inputSchema, request.data);
    const cleaned = cleanMember({...input, role: "guru"}, await loadSchoolLabels(caller.schoolId));
    if (!cleaned.ok) throw new HttpsError("invalid-argument", cleaned.reason);
    if (cleaned.name.length < 2) throw new HttpsError("invalid-argument", "Nama minimal 2 karakter.");

    const added = await addMember(caller.schoolId, cleaned, "guru", caller.uid);
    if (!added.ok) throw new HttpsError("already-exists", added.reason);
    if (!added.created) {
      throw new HttpsError("already-exists", "Email ini sudah terdaftar sebagai penanggung jawab.");
    }

    const existing = await auth.getUserByEmail(cleaned.email).catch(() => null);
    const joined = existing?.emailVerified === true;
    if (existing && joined) await claimMembership(existing.uid, cleaned.email, null);

    await audit(caller.schoolId, caller.uid, "addTeacher", {target: existing?.uid ?? null, joined});
    return {joined};
  },
);
