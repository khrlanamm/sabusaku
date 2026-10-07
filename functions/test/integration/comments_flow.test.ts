// docs/04 §2.3: a teacher comment flags the journal as unread for the
// student, exactly once, without disturbing the derived numbers.

import {addDoc, collection, doc, serverTimestamp, setDoc, updateDoc} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {programsCol, usersCol} from "../../src/infra/firebase";
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
const DATE = wibDate(-1);

let teacher: Client;
let student: Client;
let studentUid: string;

const programRef = () => programsCol(SCHOOL).doc("buku1");
const journalRef = () => programRef().collection("journals").doc(DATE);
const commentsPath = `schools/${SCHOOL}/programs/buku1/journals/${DATE}/comments`;

beforeAll(async () => {
  await clearEmulators();
  await addSchool(SCHOOL);
  await addClass(SCHOOL, "k1", "XII IPA 1");
  await addAccount(SCHOOL, {role: "guru", name: "Bu Sari", username: "sari", classIds: ["k1"]});
  studentUid = await addAccount(SCHOOL, {
    role: "siswa",
    name: "Raka Pratama",
    username: "1001",
    classId: "k1",
    className: "XII IPA 1",
  });
  await programRef().set({
    studentId: studentUid,
    classId: "k1",
    book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 100},
    startDate: wibDate(-5),
    targetDate: wibDate(20),
    extended: false,
    status: "active",
    currentPage: 0,
    journalCount: 0,
    lastJournalDate: null,
    streakCurrent: 0,
    streakBest: 0,
  });
  await journalRef().set({
    studentId: studentUid,
    date: DATE,
    pageStart: 1,
    pageEnd: 30,
    durationRange: "15to30",
    keyInformation: "x".repeat(40),
    hasUnreadTeacherComment: false,
  });
  // Let onJournalWritten settle so its update does not race the assertions.
  await eventually(async () => (await programRef().get()).get("currentPage") === 30);

  teacher = await signIn(SCHOOL, "sari");
  student = await signIn(SCHOOL, "1001");
});

afterAll(closeClients);

describe("komentar guru", () => {
  let commentId: string;

  it("menandai jurnal punya komentar belum dibaca dan mencap komentar", async () => {
    const created = await addDoc(collection(teacher.db, commentsPath), {
      teacherId: teacher.uid,
      teacherName: "Bu Sari",
      text: "Ringkasanmu jelas. Coba kaitkan dengan pengalamanmu sendiri.",
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    commentId = created.id;

    await eventually(async () => (await journalRef().get()).get("hasUnreadTeacherComment") === true);
    const journal = await journalRef().get();
    expect(journal.get("lastCommentAt")).toBeTruthy();
    expect((await journalRef().collection("comments").doc(commentId).get()).get("notifiedAt")).toBeTruthy();
  });

  it("tidak mengubah angka turunan program", async () => {
    expect((await programRef().get()).data()).toMatchObject({currentPage: 30, journalCount: 1});
  });

  it("siswa menandai terbaca; komentar berikutnya menandai lagi", async () => {
    await updateDoc(doc(student.db, journalRef().path), {hasUnreadTeacherComment: false});
    expect((await journalRef().get()).get("hasUnreadTeacherComment")).toBe(false);

    await addDoc(collection(teacher.db, commentsPath), {
      teacherId: teacher.uid,
      teacherName: "Bu Sari",
      text: "Satu lagi: tulis juga pertanyaanmu.",
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await eventually(async () => (await journalRef().get()).get("hasUnreadTeacherComment") === true);
  });

  it("mengubah komentar tidak memberi tahu ulang", async () => {
    await updateDoc(doc(student.db, journalRef().path), {hasUnreadTeacherComment: false});
    await updateDoc(doc(teacher.db, `${commentsPath}/${commentId}`), {
      text: "Ringkasanmu jelas.",
      updatedAt: serverTimestamp(),
    });
    // Give a (wrongly) firing trigger time to act before asserting it did not.
    await new Promise((resolve) => setTimeout(resolve, 1500));
    expect((await journalRef().get()).get("hasUnreadTeacherComment")).toBe(false);
  });

  it("token perangkat siswa tersimpan di bawah profilnya", async () => {
    const token = "t".repeat(60);
    await setDoc(doc(student.db, `schools/${SCHOOL}/users/${studentUid}/devices/abc`), {
      token,
      platform: "android",
      updatedAt: serverTimestamp(),
    });
    const devices = await usersCol(SCHOOL).doc(studentUid).collection("devices").get();
    expect(devices.docs.map((d) => d.get("token"))).toEqual([token]);
  });
});
