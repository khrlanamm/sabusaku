import {FieldValue} from "firebase-admin/firestore";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {
  editProposal,
  newProposal,
  programCoverPath,
  upsertSuggestion,
} from "../infra/books";
import {booksCol, bookStatsCol, schoolRef} from "../infra/firebase";
import {refreshStudentStats} from "../infra/stats";

type Data = FirebaseFirestore.DocumentData;

/**
 * Reacts to a student's program (one book read by one student):
 *   - refreshes the student's summary when a book is started, finished,
 *     stopped, extended, removed or gets a cover (docs/04 §2.2); updates that only touch
 *     derived fields are ignored, `onJournalWritten` already refreshes then;
 *   - keeps the reader counts of the catalog book it points at (global
 *     `readerCount`, per-school `bookStats`);
 *   - when the program starts, turns what the student typed into a
 *     suggestion for the catalog: changed details of a catalog book (`edit`)
 *     or a book the catalog does not have (`new`).
 */
export const onProgramWritten = onDocumentWritten(
  "schools/{schoolId}/programs/{programId}",
  async (event) => {
    const before = event.data?.before?.exists ? event.data.before.data()! : null;
    const after = event.data?.after?.exists ? event.data.after.data()! : null;
    const {schoolId, programId} = event.params;

    await Promise.all([
      refreshSummary(schoolId, before, after),
      countReaders(schoolId, before, after),
      before === null && after !== null ? suggest(schoolId, programId, after) : null,
    ]);
  },
);

async function refreshSummary(schoolId: string, before: Data | null, after: Data | null) {
  if (
    before &&
    after &&
    before.status === after.status &&
    before.targetDate === after.targetDate &&
    (before.book?.coverUrl ?? null) === (after.book?.coverUrl ?? null)
  ) {
    return;
  }
  const studentId = (after ?? before)?.studentId as string | undefined;
  if (studentId) await refreshStudentStats(schoolId, studentId);
}

/** Reader counts follow the program's `book.bookId` and its status. */
async function countReaders(schoolId: string, before: Data | null, after: Data | null) {
  const beforeBook = (before?.book?.bookId as string | undefined) ?? null;
  const afterBook = (after?.book?.bookId as string | undefined) ?? null;
  const beforeActive = before?.status === "active";
  const afterActive = after?.status === "active";

  if (beforeBook !== afterBook) {
    if (beforeBook) await count(schoolId, beforeBook, -1, beforeActive ? -1 : 0);
    if (afterBook) await count(schoolId, afterBook, 1, afterActive ? 1 : 0);
  } else if (afterBook && beforeActive !== afterActive) {
    await count(schoolId, afterBook, 0, afterActive ? 1 : -1);
  }
}

async function count(schoolId: string, bookId: string, readers: number, active: number) {
  if (readers !== 0) {
    try {
      await booksCol().doc(bookId).update({readerCount: FieldValue.increment(readers)});
    } catch (error) {
      // gRPC NOT_FOUND: the catalog book is gone; the school's count still moves.
      if ((error as {code?: number}).code !== 5) throw error;
    }
  }
  await bookStatsCol(schoolId).doc(bookId).set(
    {
      readers: FieldValue.increment(readers),
      active: FieldValue.increment(active),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function suggest(schoolId: string, programId: string, program: Data) {
  const book = (program.book ?? {}) as Record<string, unknown>;
  const school = await schoolRef(schoolId).get();
  const source = {
    schoolId,
    schoolName: (school.get("name") as string | undefined) ?? schoolId,
    programId,
  };
  const coverPath = programCoverPath(book.coverUrl, schoolId, String(program.studentId ?? ""));
  const cover: Record<string, unknown> = coverPath ? {coverUrl: book.coverUrl, coverPath} : {};

  const bookId = typeof book.bookId === "string" ? book.bookId : null;
  if (bookId) {
    const catalog = await booksCol().doc(bookId).get();
    if (!catalog.exists) return;
    const proposed = editProposal(book, catalog.data()!);
    if (coverPath && book.coverUrl !== catalog.get("coverUrl")) Object.assign(proposed, cover);
    if (Object.keys(proposed).length === 0) return;
    await upsertSuggestion({kind: "edit", bookId, proposed}, source);
    return;
  }

  const proposed: Record<string, unknown> = {...newProposal(book), ...cover};
  if (!proposed.title) return;
  await upsertSuggestion({kind: "new", bookId: null, proposed}, source);
}
