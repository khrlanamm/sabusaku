import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {refreshSchoolStaff} from "../infra/staff";

/** Teacher profile fields that the school's staff map is built from. */
const STAFF_FIELDS = ["name", "homeroomClass", "extracurriculars", "status"];

/**
 * Keeps `schools/{schoolId}.staff` in step with the teachers: a teacher who
 * joins, leaves, is renamed or changes their homeroom class or supervised
 * extracurriculars rebuilds it. Student profiles are ignored.
 */
export const onTeacherWritten = onDocumentWritten(
  "schools/{schoolId}/users/{uid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const wasTeacher = before?.exists === true && before.get("role") === "guru";
    const isTeacher = after?.exists === true && after.get("role") === "guru";
    if (!wasTeacher && !isTeacher) return;

    const changed =
      wasTeacher !== isTeacher ||
      STAFF_FIELDS.some(
        (field) =>
          JSON.stringify(before?.get(field) ?? null) !== JSON.stringify(after?.get(field) ?? null),
      );
    if (changed) await refreshSchoolStaff(event.params.schoolId);
  },
);
