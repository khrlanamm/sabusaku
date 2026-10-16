import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {MAX_STUDENTS_PER_CALL} from "../domain/types";
import {audit} from "../infra/audit";
import {
  addMember,
  addSchoolClasses,
  cleanMember,
  loadSchoolLabels,
  MemberError,
} from "../infra/members";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  students: z
    .array(
      z.object({
        email: z.string().max(320),
        name: z.string().max(200).nullish(),
        classId: z.string().max(40).nullish(),
        extracurriculars: z.array(z.string().max(80)).max(20).optional(),
      }),
    )
    .min(1)
    .max(MAX_STUDENTS_PER_CALL),
});

export type AddStudentResult = {email: string; ok: true} | {email: string; ok: false; reason: string};

const CONCURRENCY = 5;

/**
 * Puts 1–100 student emails on the caller's school roster. Each row succeeds
 * or fails on its own so an import can report per line. No account is
 * created: the student signs in with Google or signs up with that email.
 * Valid class labels the school does not list yet are added to it.
 */
export const addStudents = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 120},
  async (request): Promise<{results: AddStudentResult[]}> => {
    const caller = await requireCaller(request, ["guru"]);
    const {students} = parseInput(inputSchema, request.data);
    const labels = await loadSchoolLabels(caller.schoolId);

    const seen = new Set<string>();
    const prepared = students.map((row) => {
      const cleaned = cleanMember({...row, role: "siswa"}, labels);
      if (cleaned.ok) {
        if (seen.has(cleaned.email)) {
          return {ok: false as const, email: cleaned.email, reason: "Email kembar dalam daftar ini."};
        }
        seen.add(cleaned.email);
      }
      return cleaned;
    });

    const newClasses = [
      ...new Set(prepared.flatMap((row) => (row.ok && row.newClass ? [row.newClass] : []))),
    ];
    try {
      await addSchoolClasses(caller.schoolId, newClasses);
    } catch (error) {
      if (error instanceof MemberError) throw new HttpsError("failed-precondition", error.message);
      throw error;
    }

    const results = new Array<AddStudentResult>(prepared.length);
    let next = 0;
    const worker = async () => {
      while (next < prepared.length) {
        const index = next++;
        const row = prepared[index];
        if (!row.ok) {
          results[index] = {email: row.email, ok: false, reason: row.reason};
          continue;
        }
        try {
          const added = await addMember(caller.schoolId, row, "siswa", caller.uid);
          results[index] = added.ok
            ? {email: added.email, ok: true}
            : {email: added.email, ok: false, reason: added.reason};
        } catch {
          results[index] = {email: row.email, ok: false, reason: "Gagal menyimpan. Coba lagi."};
        }
      }
    };
    await Promise.all(Array.from({length: CONCURRENCY}, worker));

    const added = results.filter((result) => result.ok).length;
    await audit(caller.schoolId, caller.uid, "addStudents", {requested: results.length, added});
    return {results};
  },
);
