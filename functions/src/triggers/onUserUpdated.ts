import {onDocumentUpdated} from "firebase-functions/v2/firestore";

import {BACKGROUND_OPTIONS} from "../config";

import {db, programsCol} from "../infra/firebase";
import {refreshStudentStats} from "../infra/stats";

/** Profile fields copied into the student's summary. */
const SUMMARY_FIELDS = ["name", "email", "classId", "extracurriculars", "photoUrl", "status"];

/**
 * Carries profile changes of a student to the data derived from it
 * (docs/04 §2.4):
 *   - a class change re-labels the student's programs;
 *   - any change to a field shown on teacher lists, or a removal from the
 *     school, rebuilds (or drops) the summary.
 */
export const onUserUpdated = onDocumentUpdated(
  {document: "schools/{schoolId}/users/{uid}", ...BACKGROUND_OPTIONS},
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after || after.get("role") !== "siswa") return;

    const {schoolId, uid} = event.params;
    const classChanged = before.get("classId") !== after.get("classId");
    if (classChanged) {
      const programs = await programsCol(schoolId).where("studentId", "==", uid).get();
      const batch = db.batch();
      for (const program of programs.docs) {
        batch.update(program.ref, {classId: after.get("classId") ?? null});
      }
      await batch.commit();
    }

    const changed = SUMMARY_FIELDS.some(
      (field) => JSON.stringify(before.get(field) ?? null) !== JSON.stringify(after.get(field) ?? null),
    );
    if (changed) await refreshStudentStats(schoolId, uid);
  },
);
