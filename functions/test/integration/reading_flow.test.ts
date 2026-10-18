// docs/04 §8: roster → sign in → claimAccount → start a book → write
// journals → studentStats is filled by the triggers, through the real
// security rules.

import {
  deleteDoc,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {
  auth,
  leaderboardsCol,
  membersCol,
  programsCol,
  schoolRef,
  statsCol,
} from "../../src/infra/firebase";
import {refreshAllSchools} from "../../src/scheduled/dailyRefresh";
import {
  addJoined,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  eventually,
  signIn,
  wibDate,
} from "./helpers";

const SCHOOL = "sman1";
const PROGRAM = "buku1";
const TEXT = "Tokoh utama mulai menyadari pentingnya pendidikan.";

const STUDENT_EMAIL = "raka@sekolah.test";

let teacher: Client;
let student: Client;
let studentUid: string;

const school = `schools/${SCHOOL}`;
const stats = async () => (await statsCol(SCHOOL).doc(studentUid).get()).data();
const statsWhere = (check: (data: FirebaseFirestore.DocumentData) => boolean) =>
  eventually(async () => {
    const data = await stats();
    return data && check(data) ? data : undefined;
  });

/** The student's row on a board, or undefined. */
const entry = async (periodId: string) =>
  (await leaderboardsCol(SCHOOL).doc(periodId).get()).get(`entries.${studentUid}`) as
    | FirebaseFirestore.DocumentData
    | undefined;
const entryWhere = (periodId: string, check: (data: FirebaseFirestore.DocumentData) => boolean) =>
  eventually(async () => {
    const data = await entry(periodId);
    return data && check(data) ? data : undefined;
  });
const thisMonth = () => `month-${wibDate().slice(0, 7)}`;

function journal(date: string, pageStart: number, pageEnd: number) {
  return setDoc(doc(student.db, `${school}/programs/${PROGRAM}/journals/${date}`), {
    studentId: studentUid,
    date,
    pageStart,
    pageEnd,
    durationRange: "15to30",
    keyInformation: TEXT,
    hasUnreadTeacherComment: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

beforeAll(async () => {
  await clearEmulators();
  await addSchool(SCHOOL);
  // No neutral days, so the expected counts do not depend on the weekday the
  // suite happens to run on.
  await schoolRef(SCHOOL).update({"settings.neutralWeekdays": []});
  teacher = await addJoined(SCHOOL, {email: "sari@sekolah.test", role: "guru", name: "Bu Sari"});
  student = await addJoined(SCHOOL, {
    email: STUDENT_EMAIL,
    role: "siswa",
    name: "Raka Pratama",
    classId: "XII-A1",
    extracurriculars: ["Masis-KIR"],
  });
  studentUid = student.uid;
});

afterAll(closeClients);

describe("alur membaca", () => {
  it("siswa baru punya ringkasan belum_mulai", async () => {
    expect(await stats()).toMatchObject({
      status: "belum_mulai",
      activeProgram: null,
      name: "Raka Pratama",
      email: STUDENT_EMAIL,
      classId: "XII-A1",
      extracurriculars: ["Masis-KIR"],
    });
  });

  it("memulai buku mengisi buku aktif dan status aktif", async () => {
    const today = wibDate();
    const batch = writeBatch(student.db);
    batch.set(doc(student.db, `${school}/programs/${PROGRAM}`), {
      studentId: studentUid,
      classId: "XII-A1",
      book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 100},
      month: today.slice(0, 7),
      startDate: today,
      targetDate: wibDate(20),
      extended: false,
      status: "active",
      currentPage: 0,
      journalCount: 0,
      lastJournalDate: null,
      streakCurrent: 0,
      streakBest: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.set(doc(student.db, `${school}/activePrograms/${studentUid}`), {programId: PROGRAM});
    await batch.commit();

    const data = await statsWhere((s) => s.activeProgram?.programId === PROGRAM);
    expect(data).toMatchObject({
      status: "aktif",
      daysSinceLastJournal: 1,
      streakCurrent: 0,
      activeProgram: {
        title: "Laskar Pelangi",
        totalPages: 100,
        coverUrl: null,
        currentPage: 0,
        percent: 0,
        overdue: false,
      },
    });
  });

  it("jurnal menaikkan progres, hitungan, dan streak", async () => {
    await journal(wibDate(), 1, 40);

    const data = await statsWhere((s) => s.journalCountTotal === 1);
    expect(data).toMatchObject({
      daysSinceLastJournal: 0,
      streakCurrent: 1,
      streakBest: 1,
      lastJournalDate: wibDate(),
      journalCountMonth: 1,
      recentDates: [wibDate()],
      activeProgram: {currentPage: 40, percent: 40},
    });
    expect((await programsCol(SCHOOL).doc(PROGRAM).get()).data()).toMatchObject({
      currentPage: 40,
      journalCount: 1,
      lastJournalDate: wibDate(),
      streakCurrent: 1,
      streakBest: 1,
      journalDates: [wibDate()],
    });
  });

  it("jurnal masuk ke papan peringkat periode ini dan sepanjang waktu", async () => {
    const row = {name: "Raka Pratama", classId: "XII-A1", books: 0, streak: 1, days: 1};
    expect(await entryWhere(thisMonth(), (e) => e.days === 1)).toMatchObject(row);
    expect(await entryWhere("all", (e) => e.days === 1)).toMatchObject(row);
    const board = (await leaderboardsCol(SCHOOL).doc(thisMonth()).get()).data();
    expect(board).toMatchObject({kind: "month", key: wibDate().slice(0, 7)});
    // Only what the whole school may see.
    expect(Object.keys(board?.entries[studentUid]).sort()).toEqual(
      ["books", "classId", "days", "extracurriculars", "name", "streak"],
    );
  });

  it("membaca ulang tidak menurunkan progres; mengubah halaman dihitung ulang", async () => {
    const today = wibDate();
    const ref = doc(student.db, `${school}/programs/${PROGRAM}/journals/${today}`);
    await updateDoc(ref, {pageStart: 1, pageEnd: 100, updatedAt: serverTimestamp()});
    await statsWhere((s) => s.activeProgram?.percent === 100);

    await updateDoc(ref, {pageStart: 1, pageEnd: 60, updatedAt: serverTimestamp()});
    const data = await statsWhere((s) => s.activeProgram?.currentPage === 60);
    expect(data.journalCountTotal).toBe(1);
  });

  it("menghapus jurnal mengembalikan angka turunan", async () => {
    await deleteDoc(doc(student.db, `${school}/programs/${PROGRAM}/journals/${wibDate()}`));
    const data = await statsWhere((s) => s.journalCountTotal === 0);
    expect(data).toMatchObject({
      streakCurrent: 0,
      lastJournalDate: null,
      activeProgram: {currentPage: 0, percent: 0},
    });
    await eventually(async () => (await entry(thisMonth())) === undefined);
  });

  it("menyelesaikan buku melepas buku aktif dan menambah buku selesai", async () => {
    await journal(wibDate(), 1, 100);
    await statsWhere((s) => s.activeProgram?.percent === 100);

    const batch = writeBatch(student.db);
    batch.update(doc(student.db, `${school}/programs/${PROGRAM}`), {
      status: "completed",
      finalReflection: "Menginspirasi.",
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.delete(doc(student.db, `${school}/activePrograms/${studentUid}`));
    await batch.commit();

    const data = await statsWhere((s) => s.booksCompleted === 1);
    expect(data).toMatchObject({
      status: "belum_mulai",
      activeProgram: null,
      // The streak runs on across books: today's journal still counts.
      streakCurrent: 1,
      streakBest: 1,
      journalCountTotal: 1,
      journalCountMonth: 1,
    });
    expect(await entryWhere("all", (e) => e.books === 1)).toMatchObject({streak: 1, days: 1});
    expect(await entry(thisMonth())).toMatchObject({books: 1});
  });
});

describe("perubahan profil dan pengaturan", () => {
  it("siswa pindah kelas sendiri; program dan ringkasan ikut", async () => {
    await updateDoc(doc(student.db, `${school}/users/${studentUid}`), {
      classId: "XII-A2",
      updatedAt: serverTimestamp(),
    });
    await statsWhere((s) => s.classId === "XII-A2");
    await eventually(
      async () => (await programsCol(SCHOOL).doc(PROGRAM).get()).get("classId") === "XII-A2",
    );
  });

  it("guru mengganti nama dan siswa mengganti ekskul; ringkasan ikut", async () => {
    await updateDoc(doc(teacher.db, `${school}/users/${studentUid}`), {
      name: "Raka P.",
      updatedAt: serverTimestamp(),
    });
    await statsWhere((s) => s.name === "Raka P.");
    await updateDoc(doc(student.db, `${school}/users/${studentUid}`), {
      extracurriculars: ["Masis-KIR", "PMR"],
      updatedAt: serverTimestamp(),
    });
    await statsWhere((s) => s.extracurriculars?.length === 2);
  });

  it("siswa dikeluarkan: hilang dari ringkasan, akun tetap; kembali saat ditambah lagi", async () => {
    // A past board the nightly refresh no longer touches.
    await leaderboardsCol(SCHOOL)
      .doc("month-2020-01")
      .set({kind: "month", key: "2020-01", entries: {[studentUid]: {name: "Raka", books: 1}}});

    await teacher.call("removeStudent", {email: STUDENT_EMAIL});
    await eventually(async () => !(await statsCol(SCHOOL).doc(studentUid).get()).exists);
    for (const periodId of ["all", thisMonth(), "month-2020-01"]) {
      await eventually(async () => (await entry(periodId)) === undefined);
    }
    expect((await membersCol().doc(STUDENT_EMAIL).get()).exists).toBe(false);
    expect((await auth.getUser(studentUid)).customClaims ?? {}).not.toHaveProperty("schoolId");

    // The account still signs in, but belongs to no school.
    const again = await signIn(STUDENT_EMAIL);
    expect(await codeOf(again.join())).toBe("not-found");

    await teacher.call("addStudents", {students: [{email: STUDENT_EMAIL}]});
    await again.join();
    const data = await statsWhere((s) => s.studentId === studentUid);
    // The profile and the history come back.
    expect(data).toMatchObject({booksCompleted: 1, name: "Raka P.", classId: "XII-A2"});
    expect(await entryWhere("all", (e) => e.books === 1)).toMatchObject({name: "Raka P."});
    student = again;
  });

  it("refresh harian menghitung ulang status seiring waktu berjalan", async () => {
    // A book started 12 days ago with a single journal 10 days ago.
    const start = wibDate(-12);
    await programsCol(SCHOOL).doc("buku2").set({
      studentId: studentUid,
      classId: "XII-A2",
      book: {title: "Bumi", author: "Tere Liye", totalPages: 440},
      month: start.slice(0, 7),
      startDate: start,
      targetDate: wibDate(-2),
      extended: false,
      status: "active",
      currentPage: 0,
      journalCount: 0,
      lastJournalDate: null,
      streakCurrent: 0,
      streakBest: 0,
    });
    await programsCol(SCHOOL)
      .doc("buku2")
      .collection("journals")
      .doc(wibDate(-10))
      .set({studentId: studentUid, date: wibDate(-10), pageStart: 1, pageEnd: 30});

    const data = await statsWhere((s) => s.activeProgram?.currentPage === 30);
    expect(data).toMatchObject({
      status: "tidak_aktif",
      daysSinceLastJournal: 10,
      // Today's journal on the finished book keeps the student's streak.
      streakCurrent: 1,
      streakBest: 1,
      journalCountTotal: 2,
      activeProgram: {overdue: true},
    });
    expect((await programsCol(SCHOOL).doc("buku2").get()).data()).toMatchObject({
      streakCurrent: 0,
      journalDates: [wibDate(-10)],
    });

    // Looser thresholds apply as soon as a teacher saves them.
    await updateDoc(doc(teacher.db, school), {
      settings: {neutralWeekdays: [], holidays: [], activeMaxDays: 14, attentionMaxDays: 30},
    });
    await statsWhere((s) => s.status === "aktif");

    // The nightly job computes against the given day.
    await refreshAllSchools(wibDate(21));
    const later = await stats();
    expect(later).toMatchObject({
      status: "tidak_aktif",
      daysSinceLastJournal: 31,
      streakCurrent: 0,
    });
    // ... and rewrites the boards of that day in one go.
    expect(await entry("all")).toMatchObject({books: 1, days: 2, streak: 1});
  });
});
