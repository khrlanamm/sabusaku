// The morning digest to homeroom teachers and supervisors: the summary keeps
// statusChangedAt while the status stays, and sendTeacherDigests picks only
// the teachers whose own students need attention. FCM itself is not called:
// nobody here has a device token.

import {Timestamp} from "firebase-admin/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {programsCol, statsCol} from "../../src/infra/firebase";
import {refreshStudentStats} from "../../src/infra/stats";
import {sendTeacherDigests} from "../../src/scheduled/teacherDigest";
import {addJoined, addSchool, clearEmulators, closeClients, eventually, wibDate} from "./helpers";

const S = "sman1";

beforeAll(async () => {
  await clearEmulators();
  await addSchool(S);
});

afterAll(closeClients);

describe("ringkasan pagi untuk wali kelas dan pembina", () => {
  it("statusChangedAt tetap selama status sama dan berganti saat status berubah", async () => {
    await addJoined(S, {email: "wali@sekolah.test", role: "guru", name: "Bu Wali", homeroomClass: "XII-A1"});
    await addJoined(S, {email: "pembina@sekolah.test", role: "guru", name: "Pak Pembina", extracurriculars: ["PMR"]});
    await addJoined(S, {email: "tanpa.peran@sekolah.test", role: "guru", name: "Bu Umum"});
    const raka = await addJoined(S, {email: "raka@sekolah.test", role: "siswa", name: "Raka", classId: "XII-A1"});
    const stats = statsCol(S).doc(raka.uid);

    const first = await eventually(async () => (await stats.get()).get("statusChangedAt") as Timestamp | undefined);
    await refreshStudentStats(S, raka.uid);
    expect(((await stats.get()).get("statusChangedAt") as Timestamp).isEqual(first)).toBe(true);
    // Nothing worth a notification yet: Raka has not started a book.
    expect(await sendTeacherDigests()).toBe(0);

    // A book started three weeks ago without a single journal: tidak_aktif.
    await programsCol(S).doc("buku-raka").set({
      studentId: raka.uid,
      classId: "XII-A1",
      book: {title: "Bumi", author: "Tere Liye", totalPages: 300},
      month: wibDate(-20).slice(0, 7),
      startDate: wibDate(-20),
      targetDate: wibDate(5),
      extended: false,
      status: "active",
      currentPage: 0,
      journalCount: 0,
      lastJournalDate: null,
      streakCurrent: 0,
      streakBest: 0,
    });
    await eventually(async () => (await stats.get()).get("status") === "tidak_aktif");
    const changedAt = (await stats.get()).get("statusChangedAt") as Timestamp;
    expect(changedAt.toMillis()).toBeGreaterThan(first.toMillis());

    // Only the homeroom teacher of XII-A1 is told; Raka is in no extracurricular.
    expect(await sendTeacherDigests()).toBe(1);
    // A day later the change is old news.
    expect(await sendTeacherDigests(changedAt.toMillis() + 86_400_000 + 1)).toBe(0);
  });
});
