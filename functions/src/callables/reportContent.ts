import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {bookNotFound} from "../infra/books";
import {booksCol, bookSuggestionsCol, db, programsCol, reportsCol, usersCol} from "../infra/firebase";
import {Caller, parseInput, requireCaller} from "../infra/guard";
import {
  MAX_REPORT_TEXT,
  MAX_REPORTS_PER_DAY,
  REPORT_KINDS,
  REPORT_REASONS,
  ReportKind,
} from "../infra/reports";

/** A document ID from the app; never a path. */
const docId = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);

const inputSchema = z.object({
  kind: z.enum(REPORT_KINDS),
  reason: z.enum(REPORT_REASONS),
  note: z.string().trim().max(MAX_REPORT_TEXT).nullish(),
  programId: docId.nullish(),
  /** The journal's ID, `yyyy-MM-dd`. */
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullish(),
  commentId: docId.nullish(),
  bookId: docId.nullish(),
  suggestionId: docId.nullish(),
  userId: docId.nullish(),
});
type Input = z.infer<typeof inputSchema>;

/** Kinds only a teacher can see, so only a teacher can report them. */
const TEACHER_ONLY: readonly ReportKind[] = ["journal", "suggestion"];

/** Characters of a journal's key information copied into its report. */
const JOURNAL_EXCERPT = 300;

const DAY_MS = 24 * 3600_000;

/** What a report points at, and who it is about. */
interface Target {
  /** The school that owns the content; null for the shared catalog. */
  targetSchoolId: string | null;
  /** The person whose content or account is reported. */
  subjectId: string | null;
  target: Record<string, string>;
  /** The content as it was when reported: it may change or go later. */
  snapshot: Record<string, unknown>;
}

const missing = () => new HttpsError("invalid-argument", "Data yang dikirim tidak valid.");
const denied = () => new HttpsError("permission-denied", "Akses ditolak.");

/**
 * Finds the reported content in the caller's school (or the catalog) and
 * copies what the reviewer needs to see. A student reaches only their own
 * programs, as in the rules.
 */
async function findTarget(caller: Caller, input: Input): Promise<Target> {
  const school = caller.schoolId;
  switch (input.kind) {
    case "comment": {
      const {programId, date, commentId} = input;
      if (!programId || !date || !commentId) throw missing();
      const notFound = () => new HttpsError("not-found", "Komentar tidak ditemukan.");
      const program = await programsCol(school).doc(programId).get();
      if (!program.exists) throw notFound();
      if (caller.role === "siswa" && program.get("studentId") !== caller.uid) throw denied();
      const comment = await program.ref
        .collection("journals")
        .doc(date)
        .collection("comments")
        .doc(commentId)
        .get();
      if (!comment.exists) throw notFound();
      return {
        targetSchoolId: school,
        subjectId: (comment.get("teacherId") as string | undefined) ?? null,
        target: {programId, date, commentId},
        snapshot: {
          text: (comment.get("text") as string | undefined) ?? "",
          authorName: (comment.get("teacherName") as string | undefined) ?? "",
        },
      };
    }

    case "journal": {
      const {programId, date} = input;
      if (!programId || !date) throw missing();
      const notFound = () => new HttpsError("not-found", "Jurnal tidak ditemukan.");
      const program = await programsCol(school).doc(programId).get();
      if (!program.exists) throw notFound();
      const journal = await program.ref.collection("journals").doc(date).get();
      if (!journal.exists) throw notFound();
      const studentId = program.get("studentId") as string;
      const student = await usersCol(school).doc(studentId).get();
      return {
        targetSchoolId: school,
        subjectId: studentId,
        target: {programId, date},
        snapshot: {
          studentName: (student.get("name") as string | undefined) ?? "",
          date,
          keyInformation: ((journal.get("keyInformation") as string | undefined) ?? "").slice(
            0,
            JOURNAL_EXCERPT,
          ),
        },
      };
    }

    case "book": {
      const {bookId} = input;
      if (!bookId) throw missing();
      const book = await booksCol().doc(bookId).get();
      if (!book.exists) throw bookNotFound();
      return {
        targetSchoolId: null,
        subjectId: null,
        target: {bookId},
        snapshot: {
          title: (book.get("title") as string | undefined) ?? "",
          authors: (book.get("authors") as string[] | undefined) ?? [],
          coverUrl: (book.get("coverUrl") as string | null | undefined) ?? null,
        },
      };
    }

    case "suggestion": {
      const {suggestionId} = input;
      if (!suggestionId) throw missing();
      const suggestion = await bookSuggestionsCol().doc(suggestionId).get();
      if (!suggestion.exists) throw new HttpsError("not-found", "Saran tidak ditemukan.");
      const proposed = (suggestion.get("proposed") as Record<string, unknown> | undefined) ?? {};
      // An edit proposal may leave the title as it is: name the book instead.
      let title = typeof proposed.title === "string" ? proposed.title : null;
      const bookId = suggestion.get("bookId") as string | null | undefined;
      if (!title && bookId) {
        title = ((await booksCol().doc(bookId).get()).get("title") as string | undefined) ?? null;
      }
      return {
        targetSchoolId: null,
        subjectId: null,
        target: {suggestionId},
        snapshot: {
          title: title ?? "",
          coverUrl: typeof proposed.coverUrl === "string" ? proposed.coverUrl : null,
        },
      };
    }

    case "user": {
      const {userId} = input;
      if (!userId) throw missing();
      const user = await usersCol(school).doc(userId).get();
      if (!user.exists) throw new HttpsError("not-found", "Pengguna tidak ditemukan.");
      return {
        targetSchoolId: school,
        subjectId: userId,
        target: {userId},
        snapshot: {
          name: (user.get("name") as string | undefined) ?? "",
          role: (user.get("role") as string | undefined) ?? null,
        },
      };
    }
  }
}

/**
 * Reports content or a user (Google Play's User Generated Content policy):
 * a teacher's comment, a student's journal, a catalog book, a book
 * suggestion, or a person in the caller's school. The report keeps a copy of
 * the content, and the teachers of the schools in `schools` review it next
 * to the developer; a report about a teacher reaches the developer only. Comments, journals and users are found in the caller's
 * school only. At most 20 reports per person in 24 hours.
 */
export const reportContent = onCall(CALLABLE_OPTIONS, async (request): Promise<{id: string}> => {
  const caller = await requireCaller(request, ["guru", "siswa"]);
  const input = parseInput(inputSchema, request.data);
  if (TEACHER_ONLY.includes(input.kind) && caller.role !== "guru") throw denied();

  const found = await findTarget(caller, input);
  if (found.subjectId === caller.uid) {
    throw new HttpsError(
      "invalid-argument",
      input.kind === "user"
        ? "Kamu tidak bisa melaporkan dirimu sendiri."
        : "Kamu tidak bisa melaporkan kontenmu sendiri.",
    );
  }
  const reporter = await usersCol(caller.schoolId).doc(caller.uid).get();

  const ref = reportsCol().doc();
  await db.runTransaction(async (transaction) => {
    // The 20th most recent report must be older than a day.
    const recent = await transaction.get(
      reportsCol()
        .where("reporterId", "==", caller.uid)
        .orderBy("createdAt", "desc")
        .limit(MAX_REPORTS_PER_DAY),
    );
    const oldest = recent.docs[MAX_REPORTS_PER_DAY - 1]?.get("createdAt") as Timestamp | undefined;
    if (oldest && oldest.toMillis() > Date.now() - DAY_MS) {
      throw new HttpsError("resource-exhausted", "Terlalu banyak laporan. Coba lagi besok.");
    }

    const now = FieldValue.serverTimestamp();
    // A report about a teacher (their comment, or the teacher as a user)
    // goes to the developer only: the teachers of the school, the reported
    // one included, would otherwise see who reported them.
    const aboutTeacher =
      input.kind === "comment" || (input.kind === "user" && found.snapshot.role === "guru");
    const schools: string[] = [];
    if (!aboutTeacher) {
      schools.push(caller.schoolId);
      if (found.targetSchoolId && found.targetSchoolId !== caller.schoolId) {
        schools.push(found.targetSchoolId);
      }
    }
    transaction.create(ref, {
      kind: input.kind,
      reason: input.reason,
      note: input.note || null,
      status: "open",
      reporterId: caller.uid,
      reporterRole: caller.role,
      reporterName: (reporter.get("name") as string | undefined) ?? "",
      schoolId: caller.schoolId,
      targetSchoolId: found.targetSchoolId,
      schools,
      subjectId: found.subjectId,
      target: found.target,
      snapshot: found.snapshot,
      targetDeleted: false,
      createdAt: now,
      updatedAt: now,
    });
  });

  await audit(caller.schoolId, caller.uid, "reportContent", {kind: input.kind, reportId: ref.id});
  return {id: ref.id};
});
