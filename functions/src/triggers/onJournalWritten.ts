import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {BACKGROUND_OPTIONS} from "../config";

import {computeProgramAggregates} from "../domain/activity";
import {wibToday} from "../domain/dates";
import {db, programsCol} from "../infra/firebase";
import {loadSettings, refreshStudentStats} from "../infra/stats";

/**
 * Keeps a program's derived fields and the student's summary in step with its
 * journals (docs/04 §2.1). Everything is recomputed from all journals of the
 * program, so retries and offline journals arriving out of order still end in
 * the right numbers.
 */
export const onJournalWritten = onDocumentWritten(
  {document: "schools/{schoolId}/programs/{programId}/journals/{date}", ...BACKGROUND_OPTIONS},
  async (event) => {
    const {schoolId, programId} = event.params;
    const before = event.data?.before;
    const after = event.data?.after;

    // Text edits and comment flags change nothing that is derived.
    if (before?.exists && after?.exists && before.get("pageEnd") === after.get("pageEnd")) {
      return;
    }
    // A deleted journal takes its teacher comments with it.
    if (before?.exists && !after?.exists) {
      await db.recursiveDelete(before.ref.collection("comments"));
    }

    const programRef = programsCol(schoolId).doc(programId);
    const settings = await loadSettings(schoolId);

    // In a transaction, so two journals syncing at once cannot leave the
    // result of the slower trigger (which saw fewer journals) on the program.
    const studentId = await db.runTransaction(async (transaction) => {
      const program = await transaction.get(programRef);
      if (!program.exists) return null;
      const journals = await transaction.get(programRef.collection("journals").select("pageEnd"));
      const aggregates = computeProgramAggregates(
        journals.docs.map((doc) => ({date: doc.id, pageEnd: (doc.get("pageEnd") as number) ?? 0})),
        wibToday(),
        settings,
      );
      transaction.update(programRef, {...aggregates});
      return program.get("studentId") as string;
    });

    if (studentId) await refreshStudentStats(schoolId, studentId, {settings});
  },
);
