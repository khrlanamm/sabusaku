import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {isValidUsername, normalizeUsername} from "../domain/identity";
import {MAX_TEACHER_CLASSES, MAX_USERS_PER_CALL} from "../domain/types";
import {createAccount, UsernameTakenError} from "../infra/accounts";
import {audit} from "../infra/audit";
import {classesCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  users: z
    .array(
      z.object({
        role: z.enum(["guru", "siswa"]),
        name: z.string(),
        username: z.string(),
        classId: z.string().optional(),
        classIds: z.array(z.string()).optional(),
      }),
    )
    .min(1)
    .max(MAX_USERS_PER_CALL),
});

type Row = z.infer<typeof inputSchema>["users"][number];

export type CreateUserResult =
  | {username: string; ok: true; uid: string; password: string}
  | {username: string; ok: false; reason: string};

const CONCURRENCY = 5;

/**
 * Creates 1–100 teachers or students. Each row succeeds or fails on its own
 * with a reason, so a CSV import can report problems per line. Initial
 * passwords are returned once and never stored.
 */
export const createUsers = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 300, memory: "512MiB"},
  async (request): Promise<{results: CreateUserResult[]}> => {
    const caller = await requireCaller(request, ["admin"]);
    const {users} = parseInput(inputSchema, request.data);

    const classSnapshots = await classesCol(caller.schoolId).get();
    const classes = new Map(
      classSnapshots.docs.map((doc) => [
        doc.id,
        {name: doc.get("name") as string, isArchived: doc.get("isArchived") === true},
      ]),
    );

    const seen = new Set<string>();
    const validate = (row: Row, username: string): string | null => {
      const name = row.name.trim();
      if (name.length < 2 || name.length > 80) return "Nama harus 2–80 karakter.";
      if (!isValidUsername(username)) {
        return "Username harus 3–30 karakter: huruf kecil, angka, titik, garis bawah, atau tanda hubung.";
      }
      if (seen.has(username)) return "Username kembar dalam daftar ini.";
      seen.add(username);

      if (row.role === "siswa") {
        const target = row.classId ? classes.get(row.classId) : undefined;
        if (!target) return "Kelas tidak ditemukan.";
        if (target.isArchived) return "Kelas sudah diarsipkan.";
      } else {
        const ids = row.classIds ?? [];
        if (ids.length > MAX_TEACHER_CLASSES) {
          return `Guru maksimal ${MAX_TEACHER_CLASSES} kelas.`;
        }
        if (new Set(ids).size !== ids.length) return "Kelas guru tercantum dua kali.";
        if (ids.some((id) => !classes.has(id))) return "Kelas tidak ditemukan.";
      }
      return null;
    };

    // Validate in order first so duplicate detection is deterministic.
    const prepared = users.map((row) => {
      const username = normalizeUsername(row.username);
      return {row, username, reason: validate(row, username)};
    });

    const results = new Array<CreateUserResult>(prepared.length);
    let next = 0;
    const worker = async () => {
      while (next < prepared.length) {
        const index = next++;
        const {row, username, reason} = prepared[index];
        if (reason) {
          results[index] = {username, ok: false, reason};
          continue;
        }
        try {
          const account = await createAccount(caller.schoolId, {
            role: row.role,
            name: row.name.trim(),
            username,
            classId: row.classId ?? null,
            className: row.classId ? classes.get(row.classId)!.name : null,
            classIds: row.classIds ?? [],
          });
          results[index] = {username, ok: true, uid: account.uid, password: account.password};
        } catch (error) {
          results[index] = {
            username,
            ok: false,
            reason:
              error instanceof UsernameTakenError
                ? "Username sudah dipakai."
                : "Gagal membuat akun. Coba lagi.",
          };
        }
      }
    };
    await Promise.all(Array.from({length: CONCURRENCY}, worker));

    const created = results.filter((result) => result.ok).length;
    if (created === 0 && results.length === 1 && !results[0].ok) {
      // Single manual add: surface the reason as the call's error.
      throw new HttpsError("failed-precondition", results[0].reason);
    }
    await audit(caller.schoolId, caller.uid, "createUsers", {
      requested: results.length,
      created,
    });
    return {results};
  },
);
