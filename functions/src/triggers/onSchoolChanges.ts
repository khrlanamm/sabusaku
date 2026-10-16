import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";

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
