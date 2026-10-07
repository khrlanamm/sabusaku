import {onDocumentUpdated} from "firebase-functions/v2/firestore";

import {db, programsCol} from "../infra/firebase";
import {refreshStudentStats} from "../infra/stats";

/**
 * Carries profile changes of a student to the data derived from it
 * (docs/04 §2.4):
 *   - a class move re-labels the student's programs, which is what moves
 *     teacher access to their journals (PRD BR-14);
 *   - a rename, class move or (de)activation rebuilds the summary.
 */
export const onUserUpdated = onDocumentUpdated(
  "schools/{schoolId}/users/{uid}",
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

    if (
      classChanged ||
      before.get("name") !== after.get("name") ||
      before.get("status") !== after.get("status")
    ) {
      await refreshStudentStats(schoolId, uid);
    }
  },
);
