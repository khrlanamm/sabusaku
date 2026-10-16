// docs/03 §6, cases #2 (comments), #3, #16 and #17.

import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

import {actors, CLASS_1, createEnv, Db, SCHOOL, seedSchool, wibDate} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

const DATE = wibDate(-5);
const journalPath = `schools/${SCHOOL}/programs/prog1/journals/${DATE}`;
const commentsPath = `${journalPath}/comments`;

const comment = (overrides: Record<string, unknown> = {}) => ({
  teacherId: "guru1",
  teacherName: "Guru Satu",
  text: "Ringkasanmu jelas. Coba kaitkan dengan pengalamanmu sendiri.",
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

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
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Db;
    await setDoc(doc(db, `schools/${SCHOOL}/programs/prog1`), {
      studentId: "siswa1",
      classId: CLASS_1,
      status: "active",
      book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 300},
      startDate: wibDate(-10),
    });
    await setDoc(doc(db, journalPath), {
      studentId: "siswa1",
      date: DATE,
      pageStart: 1,
      pageEnd: 20,
      keyInformation: "x".repeat(40),
      hasUnreadTeacherComment: false,
    });
    await setDoc(doc(db, `${commentsPath}/milik-guru1`), {
      teacherId: "guru1",
      teacherName: "Guru Satu",
      text: "Komentar awal.",
    });
  });
});

describe("comments", () => {
  // #16
  it("semua guru sekolah membuat komentar; guru sekolah lain dan siswa tidak", async () => {
    await assertSucceeds(addDoc(collection(a.teacher1, commentsPath), comment()));
    await assertSucceeds(
      addDoc(
        collection(a.teacher2, commentsPath),
        comment({teacherId: "guru2", teacherName: "Guru Dua"}),
      ),
    );
    await assertFails(
      addDoc(collection(a.student, commentsPath), comment({teacherId: "siswa1"})),
    );
    await assertFails(
      addDoc(collection(a.otherTeacher, commentsPath), comment({teacherId: "guru9"})),
    );
  });

  it("komentar harus atas nama dan identitas guru itu sendiri", async () => {
    const create = (overrides: Record<string, unknown>) =>
      addDoc(collection(a.teacher1, commentsPath), comment(overrides));
    await assertFails(create({teacherId: "guru2"}));
    await assertFails(create({teacherName: "Kepala Sekolah"}));
    await assertFails(create({text: ""}));
    await assertFails(create({text: "x".repeat(1001)}));
    await assertFails(create({notifiedAt: serverTimestamp()}));
  });

  it("komentar hanya untuk jurnal yang ada", async () => {
    const missing = `schools/${SCHOOL}/programs/prog1/journals/${wibDate(-6)}/comments`;
    await assertFails(addDoc(collection(a.teacher1, missing), comment()));
  });

  // #17
  it("guru hanya mengubah dan menghapus komentarnya sendiri", async () => {
    const mine = doc(a.teacher1, `${commentsPath}/milik-guru1`);
    await assertSucceeds(updateDoc(mine, {text: "Diperbarui.", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(mine, {teacherName: "Nama Lain", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(mine, {text: "", updatedAt: serverTimestamp()}));

    // Another teacher of the school may read but not touch it.
    const coTeacher = a.teacher2;
    await assertSucceeds(getDoc(doc(coTeacher, `${commentsPath}/milik-guru1`)));
    await assertFails(
      updateDoc(doc(coTeacher, `${commentsPath}/milik-guru1`), {
        text: "Diubah orang lain.",
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(coTeacher, `${commentsPath}/milik-guru1`)));
    await assertSucceeds(deleteDoc(mine));
  });

  it("siswa pemilik membaca komentar tetapi tidak mengubahnya", async () => {
    await assertSucceeds(getDocs(collection(a.student, commentsPath)));
    await assertFails(
      updateDoc(doc(a.student, `${commentsPath}/milik-guru1`), {
        text: "Diubah siswa.",
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(a.student, `${commentsPath}/milik-guru1`)));
  });

  // #2 and #3
  it("guru sekolah lain dan siswa lain tidak membaca komentar", async () => {
    for (const db of [a.otherTeacher, a.classmate, a.outsider]) {
      await assertFails(getDocs(collection(db, commentsPath)));
      await assertFails(getDoc(doc(db, `${commentsPath}/milik-guru1`)));
    }
  });
});
