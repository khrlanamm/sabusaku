// docs/04 §8: createUsers → sign in → start a book → write journals →
// studentStats is filled by the triggers, through the real security rules.

import {
  deleteDoc,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {programsCol, schoolRef, statsCol, usersCol} from "../../src/infra/firebase";
import {refreshAllSchools} from "../../src/scheduled/dailyRefresh";
import {
  addAccount,
  addClass,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  eventually,
  signIn,
  wibDate,
} from "./helpers";

const SCHOOL = "sman1";
const PROGRAM = "buku1";
const TEXT = "Tokoh utama mulai menyadari pentingnya pendidikan.";

let admin: Client;
let student: Client;
let studentUid: string;

const school = `schools/${SCHOOL}`;
const stats = async () => (await statsCol(SCHOOL).doc(studentUid).get()).data();
const statsWhere = (check: (data: FirebaseFirestore.DocumentData) => boolean) =>
  eventually(async () => {
    const data = await stats();
    return data && check(data) ? data : undefined;
  });

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
  await addClass(SCHOOL, "k1", "XII IPA 1");
  await addClass(SCHOOL, "k2", "XII IPA 2");
  studentUid = await addAccount(SCHOOL, {
    role: "siswa",
    name: "Raka Pratama",
    username: "1001",
    classId: "k1",
    className: "XII IPA 1",
  });
  admin = await signIn(SCHOOL, "admin");
  student = await signIn(SCHOOL, "1001");
});

afterAll(closeClients);

describe("alur membaca", () => {
  it("siswa baru punya ringkasan belum_mulai", async () => {
    expect(await stats()).toMatchObject({
      status: "belum_mulai",
      activeProgram: null,
      className: "XII IPA 1",
    });
  });

  it("memulai buku mengisi buku aktif dan status aktif", async () => {
    const today = wibDate();
    const batch = writeBatch(student.db);
    batch.set(doc(student.db, `${school}/programs/${PROGRAM}`), {
      studentId: studentUid,
      classId: "k1",
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
    });
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
      streakCurrent: 0,
      streakBest: 1,
      journalCountTotal: 1,
      journalCountMonth: 1,
    });
  });
});

describe("perubahan profil dan pengaturan", () => {
  it("pindah kelas mengikutkan program dan ringkasan", async () => {
    await admin.call("moveStudentClass", {uid: studentUid, classId: "k2"});
    const data = await statsWhere((s) => s.classId === "k2");
    expect(data.className).toBe("XII IPA 2");
    await eventually(
      async () => (await programsCol(SCHOOL).doc(PROGRAM).get()).get("classId") === "k2",
    );
  });

  it("mengganti nama siswa dan nama kelas memperbarui ringkasan", async () => {
    await usersCol(SCHOOL).doc(studentUid).update({name: "Raka P."});
    await statsWhere((s) => s.name === "Raka P.");
    await schoolRef(SCHOOL).collection("classes").doc("k2").update({name: "XII IPA 2B"});
    await statsWhere((s) => s.className === "XII IPA 2B");
  });

  it("akun nonaktif hilang dari ringkasan dan kembali saat diaktifkan", async () => {
    await admin.call("setUserActive", {uid: studentUid, active: false});
    await eventually(async () => !(await statsCol(SCHOOL).doc(studentUid).get()).exists);
    await admin.call("setUserActive", {uid: studentUid, active: true});
    const data = await statsWhere((s) => s.studentId === studentUid);
    expect(data.booksCompleted).toBe(1);
  });

  it("refresh harian menghitung ulang status seiring waktu berjalan", async () => {
    // A book started 12 days ago with a single journal 10 days ago.
    const start = wibDate(-12);
    await programsCol(SCHOOL).doc("buku2").set({
      studentId: studentUid,
      classId: "k2",
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
      streakCurrent: 0,
      streakBest: 1,
      activeProgram: {overdue: true},
    });

    // Looser thresholds apply as soon as the admin saves them.
    await updateDoc(doc(admin.db, school), {
      settings: {neutralWeekdays: [], holidays: [], activeMaxDays: 14, attentionMaxDays: 30},
    });
    await statsWhere((s) => s.status === "aktif");

    // The nightly job computes against the given day.
    await refreshAllSchools(wibDate(21));
    const later = await stats();
    expect(later).toMatchObject({status: "tidak_aktif", daysSinceLastJournal: 31});
  });
});
