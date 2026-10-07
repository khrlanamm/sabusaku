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

import {actors, CLASS_1, createEnv, OTHER_SCHOOL, SCHOOL, seedSchool} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

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

const school = `schools/${SCHOOL}`;

describe("isolasi sekolah", () => {
  // docs/03 §6 #1
  it("siswa sekolah lain tidak bisa membaca apa pun di sekolah ini", async () => {
    await assertFails(getDoc(doc(a.outsider, school)));
    await assertFails(getDoc(doc(a.outsider, `${school}/users/siswa1`)));
    await assertFails(getDocs(collection(a.outsider, `${school}/classes`)));
    await assertFails(getDoc(doc(a.outsider, `${school}/studentStats/siswa1`)));
    await assertFails(getDocs(collection(a.outsider, `${school}/programs`)));
    await assertFails(getDoc(doc(a.outsider, `${school}/activePrograms/siswa1`)));
  });

  it("admin sekolah lain tidak bisa membaca atau mengubah sekolah ini", async () => {
    await assertFails(getDocs(collection(a.otherAdmin, `${school}/users`)));
    await assertFails(updateDoc(doc(a.otherAdmin, `${school}/users/siswa1`), {name: "X"}));
    await assertSucceeds(getDoc(doc(a.otherAdmin, `schools/${OTHER_SCHOOL}`)));
  });

  // docs/03 §6 #4
  it("pengguna tanpa claim atau dengan peran salah ditolak di semua koleksi", async () => {
    for (const db of [a.noClaims, a.badRole, a.anonymous]) {
      await assertFails(getDoc(doc(db, `${school}/users/siswa1`)));
      await assertFails(getDocs(collection(db, `${school}/users`)));
      await assertFails(getDoc(doc(db, `${school}/studentStats/siswa1`)));
      await assertFails(getDocs(collection(db, `${school}/programs`)));
      await assertFails(getDoc(doc(db, `${school}/activePrograms/siswa1`)));
      await assertFails(
        setDoc(doc(db, `${school}/classes/baru`), {
          name: "X IPA 1",
          grade: 10,
          academicYear: "2026/2027",
          teacherIds: [],
          isArchived: false,
        }),
      );
    }
    // No claims at all cannot even read the school document.
    await assertFails(getDoc(doc(a.noClaims, school)));
    await assertFails(getDoc(doc(a.anonymous, school)));
  });

  it("daftar sekolah tidak bisa di-list oleh siapa pun", async () => {
    await assertFails(getDocs(collection(a.admin, "schools")));
  });
});

describe("users", () => {
  it("pengguna membaca profilnya sendiri, bukan profil orang lain", async () => {
    await assertSucceeds(getDoc(doc(a.student, `${school}/users/siswa1`)));
    await assertFails(getDoc(doc(a.student, `${school}/users/siswa2`)));
    await assertFails(getDocs(collection(a.student, `${school}/users`)));
    await assertFails(getDocs(collection(a.teacher1, `${school}/users`)));
    await assertSucceeds(getDocs(collection(a.admin, `${school}/users`)));
  });

  // docs/03 §6 #18
  it("pengguna tidak bisa mengubah role, classId, atau status", async () => {
    const me = doc(a.student, `${school}/users/siswa1`);
    await assertFails(updateDoc(me, {role: "admin"}));
    await assertFails(updateDoc(me, {classId: "kelas2"}));
    await assertFails(updateDoc(me, {status: "disabled"}));
    await assertFails(updateDoc(me, {name: "Nama Baru"}));
    await assertFails(updateDoc(me, {mustChangePassword: false, role: "guru"}));
  });

  it("pengguna boleh menandai mustChangePassword true → false miliknya", async () => {
    await assertSucceeds(
      updateDoc(doc(a.student, `${school}/users/siswa1`), {mustChangePassword: false}),
    );
    // never back to true, and never on someone else's profile
    await assertFails(
      updateDoc(doc(a.student, `${school}/users/siswa1`), {mustChangePassword: true}),
    );
    await assertFails(
      updateDoc(doc(a.student, `${school}/users/siswa2`), {mustChangePassword: false}),
    );
  });

  it("admin hanya boleh mengubah nama", async () => {
    const target = doc(a.admin, `${school}/users/siswa1`);
    await assertSucceeds(updateDoc(target, {name: "Siswa Baru", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(target, {name: "S", updatedAt: serverTimestamp()}));
    await assertFails(updateDoc(target, {role: "guru"}));
    await assertFails(updateDoc(target, {status: "disabled"}));
    await assertFails(updateDoc(target, {classId: "kelas2"}));
  });

  it("klien tidak bisa membuat atau menghapus pengguna", async () => {
    await assertFails(
      setDoc(doc(a.admin, `${school}/users/baru`), {role: "siswa", name: "Baru"}),
    );
    await assertFails(deleteDoc(doc(a.admin, `${school}/users/siswa1`)));
  });

  it("token perangkat hanya milik pemilik akun", async () => {
    const mine = doc(a.student, `${school}/users/siswa1/devices/abc`);
    const token = "t".repeat(40);
    await assertSucceeds(
      setDoc(mine, {token, platform: "android", updatedAt: serverTimestamp()}),
    );
    await assertSucceeds(getDoc(mine));
    await assertFails(setDoc(mine, {token, platform: "ios", updatedAt: serverTimestamp()}));
    await assertFails(getDoc(doc(a.classmate, `${school}/users/siswa1/devices/abc`)));
    await assertFails(getDoc(doc(a.admin, `${school}/users/siswa1/devices/abc`)));
    await assertSucceeds(deleteDoc(mine));
  });
});

describe("schools dan classes", () => {
  const settings = {neutralWeekdays: [0, 6], holidays: ["2026-12-25"], activeMaxDays: 3, attentionMaxDays: 7};

  it("anggota sekolah membaca data sekolah; hanya admin mengubah settings", async () => {
    await assertSucceeds(getDoc(doc(a.student, school)));
    await assertSucceeds(updateDoc(doc(a.admin, school), {settings}));
    await assertFails(updateDoc(doc(a.teacher1, school), {settings}));
    await assertFails(updateDoc(doc(a.admin, school), {status: "suspended"}));
    await assertFails(updateDoc(doc(a.admin, school), {name: "Nama Lain"}));
  });

  it("settings yang tidak valid ditolak", async () => {
    const bad = (patch: Record<string, unknown>) =>
      assertFails(updateDoc(doc(a.admin, school), {settings: {...settings, ...patch}}));
    await bad({neutralWeekdays: [7]});
    await bad({activeMaxDays: 0});
    await bad({attentionMaxDays: 2});
    await bad({holidays: "2026-12-25"});
    await bad({extra: true});
  });

  it("admin mengelola kelas; teacherIds dan hapus tertutup bagi klien", async () => {
    const valid = {name: "X IPA 1", grade: 10, academicYear: "2026/2027", teacherIds: [], isArchived: false};
    const classes = collection(a.admin, `${school}/classes`);
    await assertSucceeds(addDoc(classes, valid));
    await assertFails(addDoc(classes, {...valid, grade: 9}));
    await assertFails(addDoc(classes, {...valid, teacherIds: ["guru1"]}));
    await assertFails(addDoc(collection(a.teacher1, `${school}/classes`), valid));

    const existing = doc(a.admin, `${school}/classes/${CLASS_1}`);
    await assertSucceeds(updateDoc(existing, {name: "XII IPA 1A", isArchived: true}));
    await assertFails(updateDoc(existing, {teacherIds: ["guru1"]}));
    await assertFails(updateDoc(existing, {academicYear: "x"}));
    await assertFails(deleteDoc(existing));
    await assertSucceeds(getDocs(collection(a.student, `${school}/classes`)));
  });
});
