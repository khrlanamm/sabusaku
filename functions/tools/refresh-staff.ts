// Rebuilds the teacher names students see as their homeroom teacher and
// extracurricular supervisors (`schools/{code}.staff`). The onTeacherWritten
// trigger keeps it current; run this once for teachers that existed before
// it, or after fixing data by hand.
//
//   npx tsx tools/refresh-staff.ts [--school sman1sukodadi] [--emulator]

import {arg, run, target} from "./_env";

import {db} from "../src/infra/firebase";
import {refreshSchoolStaff} from "../src/infra/staff";

run(async () => {
  const only = arg("school")?.toLowerCase();
  const schools = only ? [only] : (await db.collection("schools").select().get()).docs.map((doc) => doc.id);
  for (const schoolId of schools) {
    await refreshSchoolStaff(schoolId);
    const staff = (await db.doc(`schools/${schoolId}`).get()).get("staff") ?? {};
    console.log(`${schoolId} di ${target()}: ${JSON.stringify(staff)}`);
  }
});
