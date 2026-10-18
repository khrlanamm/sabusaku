import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS, isSuperadmin} from "../config";
import {audit} from "../infra/audit";
import {auth, membersCol, schoolRef} from "../infra/firebase";
import {parseInput, requireSuperadmin} from "../infra/guard";
import {addMember, claimMembership, cleanMember} from "../infra/members";
import {createSchool as createSchoolDoc, SCHOOL_ID_RE} from "../infra/schools";

const inputSchema = z.object({
  code: z.string().trim().toLowerCase().regex(SCHOOL_ID_RE),
  name: z.string().trim().max(200),
  teacherEmail: z.string().max(320),
  teacherName: z.string().max(200),
});

/**
 * A superadmin registers a school with its first teacher (penanggung jawab),
 * what tools/create-school.ts and tools/add-guru.ts do for the developer.
 * The teacher then adds students and other teachers in the app.
 */
export const createSchool = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{schoolId: string; joined: boolean}> => {
    const superadmin = requireSuperadmin(request);
    const input = parseInput(inputSchema, request.data);
    if (input.name.length < 3) {
      throw new HttpsError("invalid-argument", "Nama sekolah minimal 3 karakter.");
    }

    // Checked before the school exists, so a refused teacher leaves nothing behind.
    // No class or extracurricular is given, so the school's labels do not matter.
    const cleaned = cleanMember(
      {email: input.teacherEmail, role: "guru", name: input.teacherName},
      {classes: [], extracurriculars: []},
    );
    if (!cleaned.ok) throw new HttpsError("invalid-argument", cleaned.reason);
    if (cleaned.name.length < 2) {
      throw new HttpsError("invalid-argument", "Nama penanggung jawab minimal 2 karakter.");
    }
    if (isSuperadmin(cleaned.email)) {
      throw new HttpsError("invalid-argument", "Superadmin masuk ke sekolah lewat Ganti sekolah.");
    }
    if ((await membersCol().doc(cleaned.email).get()).exists) {
      throw new HttpsError("already-exists", "Email penanggung jawab sudah terdaftar.");
    }
    if ((await schoolRef(input.code).get()).exists) {
      throw new HttpsError("already-exists", "Kode sekolah sudah dipakai.");
    }

    try {
      await createSchoolDoc(input.code, input.name);
    } catch (error) {
      // create() lost a race with another request for the same code.
      if ((error as {code?: number}).code === 6) {
        throw new HttpsError("already-exists", "Kode sekolah sudah dipakai.");
      }
      throw error;
    }

    const added = await addMember(input.code, cleaned, "guru", "superadmin");
    if (!added.ok) throw new HttpsError("already-exists", added.reason);

    const existing = await auth.getUserByEmail(cleaned.email).catch(() => null);
    const joined = existing?.emailVerified === true;
    if (existing && joined) await claimMembership(existing.uid, cleaned.email, null);

    await audit(input.code, superadmin.uid, "createSchool", {joined});
    return {schoolId: input.code, joined};
  },
);
