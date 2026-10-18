import {Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {BACKGROUND_OPTIONS} from "../config";

import {attentionFor, DigestStudent, digestMessage} from "../domain/digest";
import {StudentStatus} from "../domain/types";
import {db, statsCol, usersCol} from "../infra/firebase";
import {sendToUser} from "../infra/notify";

/** Android notification channel created by the app (MainActivity). */
const CHANNEL_ID = "siswa_binaan";
const DAY_MS = 86_400_000;

/**
 * Tells each teacher which of their own students (homeroom class or
 * supervised extracurriculars) became perlu_perhatian or tidak_aktif in the
 * 24 hours before `now`: one notification per teacher, none when nobody
 * changed. Returns the number of teachers notified. Exported for tests and
 * manual runs.
 */
export async function sendTeacherDigests(now = Date.now()): Promise<number> {
  const since = Timestamp.fromMillis(now - DAY_MS);
  const schools = await db.collection("schools").where("status", "==", "active").select().get();
  let notified = 0;
  for (const school of schools.docs) {
    // A single-field range: no composite index needed.
    const changed = await statsCol(school.id).where("statusChangedAt", ">=", since).get();
    const students: DigestStudent[] = changed.docs.map((doc) => ({
      name: (doc.get("name") as string | undefined) || ((doc.get("email") as string | undefined) ?? ""),
      classId: (doc.get("classId") as string | null | undefined) ?? null,
      extracurriculars: (doc.get("extracurriculars") as string[] | undefined) ?? [],
      status: doc.get("status") as StudentStatus,
    }));
    if (students.length === 0) continue;

    const teachers = await usersCol(school.id)
      .where("role", "==", "guru")
      .where("status", "==", "active")
      .get();
    for (const teacher of teachers.docs) {
      const picked = attentionFor(
        {
          homeroomClass: (teacher.get("homeroomClass") as string | null | undefined) ?? null,
          extracurriculars: (teacher.get("extracurriculars") as string[] | undefined) ?? [],
        },
        students,
      );
      if (picked.length === 0) continue;
      notified++;
      await sendToUser(school.id, teacher.id, {
        notification: digestMessage(picked.map((student) => student.name)),
        // Opens the dashboard on "Binaan saya"; no student data in the payload.
        data: {type: "attention"},
        android: {notification: {channelId: CHANNEL_ID}},
      });
    }
  }
  logger.info("teacher digest done", {schools: schools.size, notified});
  return notified;
}

/**
 * Early morning WIB, after the nightly refresh moved the statuses and before
 * lessons start. Not retried: a retry could notify twice.
 */
export const teacherDigest = onSchedule(
  {
    ...BACKGROUND_OPTIONS,
    maxInstances: 1,
    schedule: "30 6 * * *",
    timeZone: "Asia/Jakarta",
    timeoutSeconds: 300,
    retryCount: 0,
  },
  async () => {
    await sendTeacherDigests();
  },
);
