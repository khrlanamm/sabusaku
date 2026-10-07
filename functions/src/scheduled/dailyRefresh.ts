import {logger} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {wibToday} from "../domain/dates";
import {db} from "../infra/firebase";
import {refreshSchool} from "../infra/stats";

/** Refreshes every active school. Exported for tests and manual runs. */
export async function refreshAllSchools(today = wibToday()): Promise<number> {
  const schools = await db.collection("schools").where("status", "==", "active").select().get();
  let students = 0;
  for (const school of schools.docs) {
    students += await refreshSchool(school.id, today);
  }
  logger.info("daily refresh done", {schools: schools.size, students, today});
  return students;
}

/**
 * Just after midnight WIB: status, days since the last journal, current
 * streak, this month's journal count and "overdue" all depend on today's date
 * and must move even when nobody writes anything (docs/04 §3).
 */
export const dailyRefresh = onSchedule(
  {
    schedule: "10 0 * * *",
    timeZone: "Asia/Jakarta",
    timeoutSeconds: 540,
    memory: "512MiB",
    retryCount: 2,
  },
  async () => {
    await refreshAllSchools();
  },
);
