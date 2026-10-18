import {staffOf} from "../domain/staff";
import {schoolRef, usersCol} from "./firebase";

/** gRPC NOT_FOUND: the school document does not exist. */
const NOT_FOUND = 5;

/**
 * Rebuilds `schools/{schoolId}.staff` from the profiles of the school's
 * active teachers. A full rebuild, so concurrent calls cannot leave it stale.
 */
export async function refreshSchoolStaff(schoolId: string): Promise<void> {
  const teachers = await usersCol(schoolId)
    .where("role", "==", "guru")
    .where("status", "==", "active")
    .get();
  const staff = staffOf(
    teachers.docs.map((doc) => ({
      name: (doc.get("name") as string | undefined) ?? "",
      homeroomClass: (doc.get("homeroomClass") as string | null | undefined) ?? null,
      extracurriculars: (doc.get("extracurriculars") as string[] | undefined) ?? [],
    })),
  );
  await schoolRef(schoolId)
    .update({staff})
    .catch((error: unknown) => {
      if ((error as {code?: number}).code !== NOT_FOUND) throw error;
    });
}
