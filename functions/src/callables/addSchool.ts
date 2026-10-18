import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {DEFAULT_EXTRACURRICULARS, isValidSchoolId} from "../domain/labels";
import {audit} from "../infra/audit";
import {auth, membersCol, schoolRef} from "../infra/firebase";
import {parseInput, requireSuperadmin} from "../infra/guard";
import {addMember, claimMembership, cleanMember} from "../infra/members";
import {createSchool} from "../infra/schools";

const inputSchema = z.object({
  code: z.string().max(40),
  name: z.string().max(200),
  teacherName: z.string().max(200),
  teacherEmail: z.string().max(320),
});

/** gRPC ALREADY_EXISTS from `create()`. */
const ALREADY_EXISTS = 6;

/**
 * Registers a school with its first teacher (penanggung jawab), like
 * tools/create-school.ts followed by tools/add-guru.ts. Superadmin only. The
 * school starts without classes and with the default extracurriculars; its
 * teachers add the rest in the app.
 */
export const addSchool = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{schoolId: string; joined: boolean}> => {
    const caller = await requireSuperadmin(request);
    const input = parseInput(inputSchema, request.data);

    const schoolId = input.code.trim().toLowerCase();
    if (!isValidSchoolId(schoolId)) {
      throw new HttpsError(
        "invalid-argument",
        "Kode sekolah harus 3–30 karakter, huruf kecil dan angka saja.",
      );
    }
    const name = input.name.trim().replace(/\s+/g, " ");
    if (name.length < 3 || name.length > 100) {
      throw new HttpsError("invalid-argument", "Nama sekolah 3–100 karakter.");
    }
    const cleaned = cleanMember(
      {email: input.teacherEmail, role: "guru", name: input.teacherName},
      {classes: [], extracurriculars: DEFAULT_EXTRACURRICULARS},
    );
    if (!cleaned.ok) throw new HttpsError("invalid-argument", cleaned.reason);
    if (cleaned.name.length < 2) throw new HttpsError("invalid-argument", "Nama minimal 2 karakter.");

    // Checked first so a taken email leaves no school behind.
    if ((await membersCol().doc(cleaned.email).get()).exists) {
      throw new HttpsError("already-exists", "Email sudah terdaftar.");
    }
    try {
      await createSchool(schoolId, name);
    } catch (error) {
      if ((error as {code?: number}).code !== ALREADY_EXISTS) throw error;
      throw new HttpsError("already-exists", "Kode sekolah sudah dipakai.");
    }
    const added = await addMember(schoolId, cleaned, "guru", caller.uid);
    if (!added.ok) {
      // Taken in the meantime.
      await schoolRef(schoolId).delete();
      throw new HttpsError("already-exists", added.reason);
    }

    const existing = await auth.getUserByEmail(cleaned.email).catch(() => null);
    const joined = existing?.emailVerified === true;
    if (existing && joined) await claimMembership(existing.uid, cleaned.email, null);

    await audit(schoolId, caller.uid, "addSchool", {target: existing?.uid ?? null, joined});
    return {schoolId, joined};
  },
);
