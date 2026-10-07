// docs/03 §6, cases #5–#15: journals and programs.

import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, expect, it} from "vitest";

import {actors, CLASS_1, CLASS_2, createEnv, Db, SCHOOL, seedSchool, wibDate} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

const school = `schools/${SCHOOL}`;
const PROGRAM = "prog1";
const programPath = `${school}/programs/${PROGRAM}`;
const journalPath = (date: string, program = PROGRAM) =>
  `${school}/programs/${program}/journals/${date}`;

const TEXT = "Tokoh utama mulai menyadari pentingnya pendidikan."; // ≥ 30 chars

function programData(overrides: Record<string, unknown> = {}) {
  const startDate = wibDate();
  return {
    studentId: "siswa1",
    classId: CLASS_1,
    book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 300},
    month: startDate.slice(0, 7),
    startDate,
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
    ...overrides,
  };
}

function journalData(date: string, overrides: Record<string, unknown> = {}) {
  return {
    studentId: "siswa1",
    date,
    pageStart: 1,
    pageEnd: 20,
    durationRange: "15to30",
    keyInformation: TEXT,
    hasUnreadTeacherComment: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

/** Starts a book the way the app does: program + BR-1 lock in one batch. */
function startBook(db: Db, id: string, uid: string, data: Record<string, unknown>) {
  const batch = writeBatch(db);
  batch.set(doc(db, `${school}/programs/${id}`), data);
  batch.set(doc(db, `${school}/activePrograms/${uid}`), {programId: id});
  return batch.commit();
}

/** An active program that started `daysAgo` days ago, written past the rules. */
async function seedProgram(
  overrides: Record<string, unknown> = {},
  id = PROGRAM,
  daysAgo = 10,
): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Db;
    const startDate = wibDate(-daysAgo);
    const data = programData({
      startDate,
      month: startDate.slice(0, 7),
      targetDate: wibDate(20),
      ...overrides,
    });
    await setDoc(doc(db, `${school}/programs/${id}`), data);
    if (data.status === "active") {
      await setDoc(doc(db, `${school}/activePrograms/${data.studentId}`), {programId: id});
    }
  });
}

async function seedJournal(date: string, overrides: Record<string, unknown> = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Db;
    await setDoc(doc(db, journalPath(date)), journalData(date, overrides));
  });
}

beforeAll(async () => {
  env = await createEnv();
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await seedSchool(env);
  a = actors(env);
});

describe("journals: create", () => {
  beforeEach(() => seedProgram());

  // #5
  it("hari ini, kemarin, dan 2 hari lalu lolos; 3 hari lalu dan besok ditolak", async () => {
    for (const offset of [0, -1, -2]) {
      const date = wibDate(offset);
      await assertSucceeds(setDoc(doc(a.student, journalPath(date)), journalData(date)));
    }
    for (const offset of [-3, 1]) {
      const date = wibDate(offset);
      await assertFails(setDoc(doc(a.student, journalPath(date)), journalData(date)));
    }
  });

  // #6
  it("jurnal kedua pada tanggal yang sama ditolak oleh database", async () => {
    const today = wibDate();
    await assertSucceeds(setDoc(doc(a.student, journalPath(today)), journalData(today)));
    // A second create on the same ID is an update, which may not rewrite
    // createdAt or studentId.
    await assertFails(
      setDoc(doc(a.student, journalPath(today)), journalData(today, {pageEnd: 50})),
    );
    const snapshot = await getDoc(doc(a.student, journalPath(today)));
    expect(snapshot.get("pageEnd")).toBe(20);
  });

  // #7
  it("halaman dan panjang teks divalidasi", async () => {
    const today = wibDate();
    const create = (overrides: Record<string, unknown>) =>
      setDoc(doc(a.student, journalPath(today)), journalData(today, overrides));
    await assertFails(create({pageEnd: 301}));
    await assertFails(create({pageStart: 30, pageEnd: 29}));
    await assertFails(create({pageStart: 0}));
    await assertFails(create({keyInformation: "x".repeat(29)}));
    await assertFails(create({keyInformation: "x".repeat(1001)}));
    await assertFails(create({durationRange: "lama"}));
    await assertFails(create({reflection: "x".repeat(1001)}));
    await assertFails(create({date: wibDate(-1)}));
    await assertFails(create({ekstra: true}));
    await assertSucceeds(
      create({pageStart: 300, pageEnd: 300, reflection: "Menarik.", question: null}),
    );
  });

  // #8
  it("siswa lain tidak bisa menulis atau membaca jurnal ini", async () => {
    const today = wibDate();
    await assertFails(setDoc(doc(a.classmate, journalPath(today)), journalData(today)));
    await assertFails(
      setDoc(doc(a.classmate, journalPath(today)), journalData(today, {studentId: "siswa2"})),
    );
    await seedJournal(today);
    await assertFails(getDoc(doc(a.classmate, journalPath(today))));
    await assertFails(getDocs(collection(a.classmate, `${programPath}/journals`)));
  });

  // #10
  it("siswa tidak bisa menulis field turunan atau penanda komentar", async () => {
    const today = wibDate();
    await assertFails(
      setDoc(doc(a.student, journalPath(today)), journalData(today, {hasUnreadTeacherComment: true})),
    );
    await assertFails(
      setDoc(doc(a.student, journalPath(today)), journalData(today, {lastCommentAt: serverTimestamp()})),
    );
    await assertFails(updateDoc(doc(a.student, programPath), {currentPage: 300}));
    await assertFails(updateDoc(doc(a.student, programPath), {streakCurrent: 99}));
    await assertFails(updateDoc(doc(a.student, programPath), {journalCount: 30}));
    await assertFails(updateDoc(doc(a.student, programPath), {"book.totalPages": 20}));
  });

  it("jurnal sebelum tanggal mulai buku ditolak", async () => {
    await seedProgram({}, "prog-baru", 0);
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore() as unknown as Db;
      await setDoc(doc(db, `${school}/activePrograms/siswa1`), {programId: "prog-baru"});
    });
    const yesterday = wibDate(-1);
    await assertFails(
      setDoc(doc(a.student, journalPath(yesterday, "prog-baru")), journalData(yesterday)),
    );
  });
});

describe("journals: edit dan hapus", () => {
  beforeEach(() => seedProgram());

  // #9
  it("ubah dan hapus sampai H+1; H+2 terkunci", async () => {
    const yesterday = wibDate(-1);
    const twoDaysAgo = wibDate(-2);
    await seedJournal(yesterday);
    await seedJournal(twoDaysAgo);
    const edit = {pageEnd: 45, keyInformation: `${TEXT} Diperbarui.`, updatedAt: serverTimestamp()};

    await assertSucceeds(updateDoc(doc(a.student, journalPath(yesterday)), edit));
    await assertFails(updateDoc(doc(a.student, journalPath(twoDaysAgo)), edit));
    await assertFails(deleteDoc(doc(a.student, journalPath(twoDaysAgo))));
    await assertSucceeds(deleteDoc(doc(a.student, journalPath(yesterday))));
  });

  it("isi yang diubah tetap divalidasi dan tanggal tidak bisa diganti", async () => {
    const today = wibDate();
    await seedJournal(today);
    const journal = doc(a.student, journalPath(today));
    await assertFails(updateDoc(journal, {pageEnd: 999, updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(journal, {keyInformation: "pendek", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(journal, {date: wibDate(-1), updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(journal, {studentId: "siswa2", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(journal, {pageEnd: 30})); // updatedAt must be server time
  });

  it("siswa boleh menandai komentar terbaca kapan saja, tidak sebaliknya", async () => {
    const old = wibDate(-9);
    await seedJournal(old, {hasUnreadTeacherComment: true});
    await assertSucceeds(
      updateDoc(doc(a.student, journalPath(old)), {hasUnreadTeacherComment: false}),
    );
    await assertFails(
      updateDoc(doc(a.student, journalPath(old)), {hasUnreadTeacherComment: true}),
    );
    await assertFails(
      updateDoc(doc(a.classmate, journalPath(old)), {hasUnreadTeacherComment: false}),
    );
  });

  // #11
  it("program selesai atau dihentikan tidak menerima tulisan lagi", async () => {
    const today = wibDate();
    for (const status of ["completed", "stopped"]) {
      const id = `prog-${status}`;
      await seedProgram({status}, id);
      await env.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore() as unknown as Db;
        await setDoc(doc(db, journalPath(wibDate(-1), id)), journalData(wibDate(-1)));
      });
      await assertFails(setDoc(doc(a.student, journalPath(today, id)), journalData(today)));
      await assertFails(
        updateDoc(doc(a.student, journalPath(wibDate(-1), id)), {
          pageEnd: 40,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(deleteDoc(doc(a.student, journalPath(wibDate(-1), id))));
    }
  });
});

describe("journals: akses baca", () => {
  it("guru kelasnya membaca; guru kelas lain dan admin tidak", async () => {
    await seedProgram();
    const today = wibDate();
    await seedJournal(today);

    await assertSucceeds(getDoc(doc(a.teacher1, journalPath(today))));
    await assertSucceeds(getDocs(collection(a.teacher1, `${programPath}/journals`)));
    await assertSucceeds(getDoc(doc(a.student, journalPath(today))));

    // #2 (journals part) and #3
    await assertFails(getDoc(doc(a.teacher2, journalPath(today))));
    await assertFails(getDocs(collection(a.teacher2, `${programPath}/journals`)));
    await assertFails(getDoc(doc(a.admin, journalPath(today))));
    await assertFails(getDocs(collection(a.admin, `${programPath}/journals`)));
    // teachers never write journals
    await assertFails(updateDoc(doc(a.teacher1, journalPath(today)), {pageEnd: 99}));
  });
});

describe("programs", () => {
  it("siswa memulai buku lewat batch program + kunci aktif", async () => {
    await assertSucceeds(startBook(a.student, PROGRAM, "siswa1", programData()));
    await assertSucceeds(getDoc(doc(a.student, `${school}/activePrograms/siswa1`)));
    // optional ISBN
    await assertSucceeds(
      startBook(
        a.classmate,
        "prog2",
        "siswa2",
        programData({
          studentId: "siswa2",
          book: {title: "Bumi", author: "Tere Liye", totalPages: 440, isbn: "9786020332956"},
        }),
      ),
    );
  });

  it("program tanpa kunci, atau kunci tanpa program, ditolak", async () => {
    await assertFails(setDoc(doc(a.student, programPath), programData()));
    await assertFails(
      setDoc(doc(a.student, `${school}/activePrograms/siswa1`), {programId: "tidak-ada"}),
    );
  });

  // #12
  it("program kedua saat masih ada yang aktif ditolak", async () => {
    await startBook(a.student, PROGRAM, "siswa1", programData());
    await assertFails(startBook(a.student, "prog-kedua", "siswa1", programData()));
    // A second program cannot ride on the existing lock either.
    await assertFails(setDoc(doc(a.student, `${school}/programs/prog-kedua`), programData()));
  });

  // #13
  it("field turunan harus kosong saat dibuat", async () => {
    const create = (overrides: Record<string, unknown>) =>
      startBook(a.student, PROGRAM, "siswa1", programData(overrides));
    await assertFails(create({currentPage: 150}));
    await assertFails(create({journalCount: 3}));
    await assertFails(create({streakCurrent: 5}));
    await assertFails(create({streakBest: 5}));
    await assertFails(create({lastJournalDate: wibDate()}));
    await assertFails(create({status: "completed"}));
    await assertFails(create({extended: true}));
  });

  it("data buku dan tanggal divalidasi saat dibuat", async () => {
    const create = (overrides: Record<string, unknown>) =>
      startBook(a.student, PROGRAM, "siswa1", programData(overrides));
    const book = {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 300};
    await assertFails(create({book: {...book, title: "L"}}));
    await assertFails(create({book: {...book, author: "A"}}));
    await assertFails(create({book: {...book, totalPages: 9}}));
    await assertFails(create({book: {...book, totalPages: 2001}}));
    await assertFails(create({book: {...book, sampul: "x"}}));
    await assertFails(create({startDate: wibDate(-1)}));
    await assertFails(create({month: "2020-01"}));
    await assertFails(create({targetDate: wibDate(-1)}));
    await assertFails(create({targetDate: wibDate(40)}));
    await assertFails(create({classId: CLASS_2})); // must match the profile
    await assertFails(create({studentId: "siswa2"}));
  });

  // #14
  it("tandai selesai hanya saat progres 100%", async () => {
    await seedProgram({currentPage: 299});
    const complete = (db: Db) => {
      const batch = writeBatch(db);
      batch.update(doc(db, programPath), {
        status: "completed",
        finalReflection: "Buku yang menginspirasi.",
        completedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      batch.delete(doc(db, `${school}/activePrograms/siswa1`));
      return batch.commit();
    };
    await assertFails(complete(a.student));

    await seedProgram({currentPage: 300});
    // Not without releasing the lock in the same batch.
    await assertFails(
      updateDoc(doc(a.student, programPath), {
        status: "completed",
        completedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(complete(a.student));
    // Once finished the student is free to start a new book.
    await assertSucceeds(startBook(a.student, "prog-baru", "siswa1", programData()));
  });

  it("hentikan boleh kapan saja dan melepas kunci", async () => {
    await seedProgram({currentPage: 12});
    const batch = writeBatch(a.student);
    batch.update(doc(a.student, programPath), {
      status: "stopped",
      stoppedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.delete(doc(a.student, `${school}/activePrograms/siswa1`));
    await assertSucceeds(batch.commit());
    // A stopped program cannot be revived.
    await assertFails(
      updateDoc(doc(a.student, programPath), {status: "active", updatedAt: serverTimestamp()}),
    );
  });

  it("kunci aktif tidak bisa dilepas selama programnya masih aktif", async () => {
    await seedProgram();
    await assertFails(deleteDoc(doc(a.student, `${school}/activePrograms/siswa1`)));
    await assertFails(deleteDoc(doc(a.classmate, `${school}/activePrograms/siswa1`)));
  });

  // #15
  it("perpanjang target sekali saja, maksimal 31 hari", async () => {
    await seedProgram({targetDate: wibDate(5)});
    const extend = (targetDate: string) =>
      updateDoc(doc(a.student, programPath), {
        targetDate,
        extended: true,
        updatedAt: serverTimestamp(),
      });
    await assertFails(extend(wibDate(5 + 32)));
    await assertFails(extend(wibDate(4)));
    await assertSucceeds(extend(wibDate(5 + 31)));
    await assertFails(extend(wibDate(5 + 40)));
  });

  it("program tidak bisa dihapus klien", async () => {
    await seedProgram();
    await assertFails(deleteDoc(doc(a.student, programPath)));
    await assertFails(deleteDoc(doc(a.admin, programPath)));
  });

  it("siswa membaca programnya; guru per kelas; admin tidak", async () => {
    await seedProgram();
    const programs = (db: Db) => collection(db, `${school}/programs`);

    await assertSucceeds(getDoc(doc(a.student, programPath)));
    await assertSucceeds(getDocs(query(programs(a.student), where("studentId", "==", "siswa1"))));
    await assertFails(getDoc(doc(a.classmate, programPath)));
    await assertFails(getDocs(programs(a.student))); // unfiltered list

    const ofStudentInClass = (db: Db, classId: string) =>
      query(programs(db), where("studentId", "==", "siswa1"), where("classId", "==", classId));
    await assertSucceeds(getDocs(ofStudentInClass(a.teacher1, CLASS_1)));
    await assertFails(getDocs(ofStudentInClass(a.teacher2, CLASS_1)));
    await assertFails(getDoc(doc(a.teacher2, programPath)));
    await assertFails(getDoc(doc(a.admin, programPath)));
  });
});

describe("studentStats", () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore() as unknown as Db;
      for (const [id, classId] of [
        ["siswa1", CLASS_1],
        ["siswa2", CLASS_1],
        ["siswa3", CLASS_2],
      ]) {
        await setDoc(doc(db, `${school}/studentStats/${id}`), {
          studentId: id,
          classId,
          name: id,
          status: "aktif",
        });
      }
    });
  });

  const stats = (db: Db) => collection(db, `${school}/studentStats`);

  it("siswa hanya membaca ringkasannya sendiri, termasuk saat belum ada", async () => {
    await assertSucceeds(getDoc(doc(a.student, `${school}/studentStats/siswa1`)));
    await assertFails(getDoc(doc(a.student, `${school}/studentStats/siswa2`)));
    await assertFails(getDocs(stats(a.student)));
    const fresh = env.authenticatedContext("siswa-baru", {role: "siswa", schoolId: SCHOOL});
    await assertSucceeds(
      getDoc(doc(fresh.firestore() as unknown as Db, `${school}/studentStats/siswa-baru`)),
    );
  });

  // #2 (studentStats part)
  it("guru membaca per kelas yang ditugaskan saja", async () => {
    await assertSucceeds(getDocs(query(stats(a.teacher1), where("classId", "==", CLASS_1))));
    await assertSucceeds(getDoc(doc(a.teacher1, `${school}/studentStats/siswa1`)));
    await assertFails(getDocs(query(stats(a.teacher1), where("classId", "==", CLASS_2))));
    await assertFails(getDoc(doc(a.teacher1, `${school}/studentStats/siswa3`)));
    await assertFails(getDocs(stats(a.teacher1))); // must filter by class
  });

  it("admin membaca semua; tidak ada klien yang menulis", async () => {
    await assertSucceeds(getDocs(stats(a.admin)));
    for (const db of [a.admin, a.teacher1, a.student]) {
      await assertFails(
        setDoc(doc(db, `${school}/studentStats/siswa1`), {status: "aktif", streakCurrent: 99}),
      );
    }
  });
});
