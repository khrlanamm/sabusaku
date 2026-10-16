// Reports of content and users (Google Play UGC policy): only Cloud
// Functions write them; the teachers of the schools a report names read it,
// students never do.

import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, expect, it} from "vitest";

import {actors, createEnv, Db, OTHER_SCHOOL, SCHOOL, seedSchool} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

const report = (schools: string[], extra: Record<string, unknown> = {}) => ({
  kind: "user",
  reason: "harassment",
  note: null,
  status: "open",
  reporterId: "siswa1",
  reporterRole: "siswa",
  reporterName: "Siswa Satu",
  schoolId: schools[0],
  targetSchoolId: schools[0],
  schools,
  subjectId: "siswa2",
  target: {userId: "siswa2"},
  snapshot: {name: "Siswa Dua", role: "siswa"},
  targetDeleted: false,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...extra,
});

beforeAll(async () => {
  env = await createEnv();
  a = actors(env);
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await seedSchool(env);
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Db;
    await setDoc(doc(db, "reports/mine"), report([SCHOOL]));
    await setDoc(doc(db, "reports/theirs"), report([OTHER_SCHOOL], {reporterId: "siswa9"}));
    await setDoc(doc(db, "reports/both"), report([SCHOOL, OTHER_SCHOOL]));
  });
});

const bySchool = (db: Db, school: string) =>
  query(collection(db, "reports"), where("schools", "array-contains", school), orderBy("createdAt", "desc"));

describe("reports", () => {
  it("guru membaca laporan yang menyebut sekolahnya", async () => {
    await assertSucceeds(getDoc(doc(a.teacher1, "reports/mine")));
    await assertSucceeds(getDoc(doc(a.teacher1, "reports/both")));
    const list = await assertSucceeds(getDocs(bySchool(a.teacher1, SCHOOL)));
    expect(list.docs.map((d) => d.id).sort()).toEqual(["both", "mine"]);
    await assertSucceeds(getDoc(doc(a.otherTeacher, "reports/both")));
    await assertSucceeds(getDocs(bySchool(a.otherTeacher, OTHER_SCHOOL)));
  });

  it("guru tidak membaca laporan sekolah lain", async () => {
    await assertFails(getDoc(doc(a.teacher1, "reports/theirs")));
    await assertFails(getDoc(doc(a.otherTeacher, "reports/mine")));
    await assertFails(getDocs(bySchool(a.teacher1, OTHER_SCHOOL)));
    await assertFails(getDocs(collection(a.teacher1, "reports"))); // unfiltered
  });

  it("siswa tidak membaca laporan, termasuk yang ia kirim sendiri", async () => {
    for (const db of [a.student, a.classmate, a.outsider]) {
      await assertFails(getDoc(doc(db, "reports/mine")));
      await assertFails(getDoc(doc(db, "reports/both")));
      await assertFails(getDocs(bySchool(db, SCHOOL)));
      await assertFails(
        getDocs(query(collection(db, "reports"), where("reporterId", "==", "siswa1"))),
      );
    }
    for (const db of [a.noClaims, a.badRole, a.anonymous]) {
      await assertFails(getDoc(doc(db, "reports/mine")));
      await assertFails(getDocs(bySchool(db, SCHOOL)));
    }
  });

  it("klien tidak bisa membuat, mengubah, atau menghapus laporan", async () => {
    for (const db of [a.teacher1, a.student]) {
      await assertFails(setDoc(doc(db, "reports/baru"), report([SCHOOL])));
      await assertFails(addDoc(collection(db, "reports"), report([SCHOOL])));
      await assertFails(
        updateDoc(doc(db, "reports/mine"), {status: "resolved", updatedAt: serverTimestamp()}),
      );
      await assertFails(updateDoc(doc(db, "reports/mine"), {snapshot: {}}));
      await assertFails(deleteDoc(doc(db, "reports/mine")));
    }
  });
});
