// docs/03 §6 case 31: leaderboards are written only by Cloud Functions and
// read, one period at a time, by members of the school.

import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

import {actors, createEnv, Db, OTHER_SCHOOL, SCHOOL, seedSchool} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

const BOARD = `schools/${SCHOOL}/leaderboards/month-2026-10`;
const ENTRY = {name: "Raka", classId: "XII-A1", extracurriculars: [], books: 1, streak: 3, days: 5};

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
    await setDoc(doc(db, BOARD), {kind: "month", key: "2026-10", entries: {siswa1: ENTRY}});
    await setDoc(doc(db, `schools/${OTHER_SCHOOL}/leaderboards/all`), {kind: "all", entries: {}});
  });
});

describe("peringkat", () => {
  it("siswa dan guru sekolahnya membaca satu periode", async () => {
    for (const db of [a.student, a.classmate, a.teacher1]) {
      await assertSucceeds(getDoc(doc(db, BOARD)));
    }
    // A period without a board yet reads as missing, not as denied.
    await assertSucceeds(getDoc(doc(a.student, `schools/${SCHOOL}/leaderboards/year-2031`)));
  });

  it("sekolah lain dan pengguna tanpa claim ditolak", async () => {
    for (const db of [a.outsider, a.otherTeacher, a.noClaims, a.badRole, a.anonymous]) {
      await assertFails(getDoc(doc(db, BOARD)));
    }
    await assertFails(getDoc(doc(a.student, `schools/${OTHER_SCHOOL}/leaderboards/all`)));
  });

  it("tidak bisa didaftar", async () => {
    for (const db of [a.student, a.teacher1]) {
      await assertFails(getDocs(collection(db, `schools/${SCHOOL}/leaderboards`)));
    }
  });

  it("tidak ada klien yang menulis", async () => {
    for (const db of [a.student, a.teacher1]) {
      await assertFails(setDoc(doc(db, `schools/${SCHOOL}/leaderboards/all`), {entries: {}}));
      await assertFails(updateDoc(doc(db, BOARD), {"entries.siswa1.books": 9}));
      await assertFails(deleteDoc(doc(db, BOARD)));
    }
  });
});
