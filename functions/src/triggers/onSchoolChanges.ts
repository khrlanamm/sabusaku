import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";

import {db, statsCol} from "../infra/firebase";
import {refreshSchool} from "../infra/stats";

/**
 * Holidays, neutral days and thresholds all feed status and streak, so a
 * settings change recomputes every student of the school right away instead
 * of waiting for the nightly refresh.
 */
export const onSchoolUpdated = onDocumentUpdated(
  {document: "schools/{schoolId}", timeoutSeconds: 540, memory: "512MiB"},
  async (event) => {
    const before = JSON.stringify(event.data?.before.get("settings") ?? null);
    const after = JSON.stringify(event.data?.after.get("settings") ?? null);
    if (before === after) return;

    const students = await refreshSchool(event.params.schoolId);
    logger.info("settings changed, school refreshed", {
      schoolId: event.params.schoolId,
      students,
    });
  },
);

/** Keeps the class name shown on student summaries current after a rename. */
export const onClassUpdated = onDocumentUpdated(
  "schools/{schoolId}/classes/{classId}",
  async (event) => {
    const name = event.data?.after.get("name") as string | undefined;
    if (!name || event.data?.before.get("name") === name) return;

    const {schoolId, classId} = event.params;
    const stats = await statsCol(schoolId).where("classId", "==", classId).select().get();
    // Firestore batches hold at most 500 writes.
    for (let start = 0; start < stats.size; start += 400) {
      const batch = db.batch();
      for (const doc of stats.docs.slice(start, start + 400)) {
        batch.update(doc.ref, {className: name});
      }
      await batch.commit();
    }
  },
);
