import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {refreshStudentStats} from "../infra/stats";

/**
 * Refreshes the student's summary when a book is started, finished, stopped,
 * extended or removed (docs/04 §2.2). Updates that only touch derived fields
 * are ignored: `onJournalWritten` already refreshes after writing those.
 */
export const onProgramWritten = onDocumentWritten(
  "schools/{schoolId}/programs/{programId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (
      before?.exists &&
      after?.exists &&
      before.get("status") === after.get("status") &&
      before.get("targetDate") === after.get("targetDate")
    ) {
      return;
    }

    const studentId = (after?.exists ? after : before)?.get("studentId") as string | undefined;
    if (studentId) await refreshStudentStats(event.params.schoolId, studentId);
  },
);
