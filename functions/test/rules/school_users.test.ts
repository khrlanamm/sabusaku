import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

import {
  actors,
  CLASS_1,
  CLASS_2,
  createEnv,
  Db,
  EKSKUL,
  OTHER_SCHOOL,
  SCHOOL,
  seedSchool,
  userDoc,
} from "./helpers";

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
const now = () => ({updatedAt: serverTimestamp()});

describe("isolasi sekolah", () => {
  // docs/03 §6 #1
  it("siswa sekolah lain tidak bisa membaca apa pun di sekolah ini", async () => {
    await assertFails(getDoc(doc(a.outsider, school)));
    await assertFails(getDoc(doc(a.outsider, `${school}/users/siswa1`)));
    await assertFails(getDoc(doc(a.outsider, `${school}/studentStats/siswa1`)));
    await assertFails(getDocs(collection(a.outsider, `${school}/programs`)));
    await assertFails(getDoc(doc(a.outsider, `${school}/activePrograms/siswa1`)));
  });

  it("guru sekolah lain tidak bisa membaca atau mengubah sekolah ini", async () => {
    await assertFails(getDoc(doc(a.otherTeacher, school)));
    await assertFails(getDocs(collection(a.otherTeacher, `${school}/users`)));
    await assertFails(getDocs(collection(a.otherTeacher, `${school}/studentStats`)));
    await assertFails(updateDoc(doc(a.otherTeacher, `${school}/users/siswa1`), {name: "X", ...now()}));
    await assertFails(getDoc(doc(a.otherTeacher, "members/siswa.satu@sekolah.test")));
    await assertFails(
      getDocs(query(collection(a.otherTeacher, "members"), where("schoolId", "==", SCHOOL))),
    );
    await assertSucceeds(getDoc(doc(a.otherTeacher, `schools/${OTHER_SCHOOL}`)));
  });

  // docs/03 §6 #4
  it("pengguna tanpa claim atau dengan peran salah ditolak di semua koleksi", async () => {
    for (const db of [a.noClaims, a.badRole, a.anonymous]) {
      await assertFails(getDoc(doc(db, `${school}/users/siswa1`)));
      await assertFails(getDocs(collection(db, `${school}/users`)));
      await assertFails(getDoc(doc(db, `${school}/studentStats/siswa1`)));
      await assertFails(getDocs(collection(db, `${school}/programs`)));
      await assertFails(getDoc(doc(db, `${school}/activePrograms/siswa1`)));
      await assertFails(getDoc(doc(db, "members/calon@sekolah.test")));
      await assertFails(updateDoc(doc(db, school), {classes: ["X-A"]}));
    }
    // No claims at all cannot even read the school document.
    await assertFails(getDoc(doc(a.noClaims, school)));
    await assertFails(getDoc(doc(a.anonymous, school)));
  });

  it("daftar sekolah tidak bisa di-list oleh siapa pun", async () => {
    await assertFails(getDocs(collection(a.teacher1, "schools")));
  });
});

describe("members (daftar anggota)", () => {
  const roster = (db: typeof a.teacher1) =>
    query(collection(db, "members"), where("schoolId", "==", SCHOOL));

  it("guru membaca daftar sekolahnya; siswa tidak", async () => {
    await assertSucceeds(getDocs(roster(a.teacher1)));
    await assertSucceeds(
      getDocs(query(collection(a.teacher1, "members"), where("schoolId", "==", SCHOOL), where("role", "==", "siswa"))),
    );
    await assertSucceeds(getDoc(doc(a.teacher1, "members/calon@sekolah.test")));
    await assertFails(getDoc(doc(a.teacher1, "members/luar@sekolah.test")));
    await assertFails(getDocs(collection(a.teacher1, "members"))); // unfiltered
    await assertFails(getDocs(roster(a.student)));
    await assertFails(getDoc(doc(a.student, "members/siswa.satu@sekolah.test")));
  });

  it("klien tidak bisa menambah atau menghapus anggota, termasuk guru", async () => {
    const entry = {
      email: "baru@sekolah.test",
      schoolId: SCHOOL,
      role: "guru",
      name: "Guru Baru",
      classId: null,
      extracurriculars: [],
      uid: null,
    };
    await assertFails(setDoc(doc(a.teacher1, "members/baru@sekolah.test"), entry));
    await assertFails(setDoc(doc(a.teacher1, "members/baru@sekolah.test"), {...entry, role: "siswa"}));
    await assertFails(deleteDoc(doc(a.teacher1, "members/calon@sekolah.test")));
    await assertFails(deleteDoc(doc(a.teacher1, "members/guru.satu@sekolah.test")));
  });

  it("guru melengkapi data siswa yang belum masuk", async () => {
    const pending = doc(a.teacher1, "members/calon@sekolah.test");
    await assertSucceeds(
      updateDoc(pending, {name: "Calon Siswa", classId: CLASS_2, extracurriculars: ["PMR"], ...now()}),
    );
    await assertFails(updateDoc(pending, {classId: "XII-Z9", ...now()})); // unlisted
    await assertFails(updateDoc(pending, {extracurriculars: ["Catur"], ...now()}));
    await assertFails(updateDoc(pending, {role: "guru", ...now()}));
    await assertFails(updateDoc(pending, {schoolId: OTHER_SCHOOL, ...now()}));
    await assertFails(updateDoc(pending, {uid: "x", ...now()}));
    // claimed entries and teachers are changed through the profile or the developer
    await assertFails(updateDoc(doc(a.teacher1, "members/siswa.satu@sekolah.test"), {name: "X Y", ...now()}));
    await assertFails(updateDoc(doc(a.teacher1, "members/guru.satu@sekolah.test"), {name: "X Y", ...now()}));
  });
});

describe("users", () => {
  it("siswa membaca profilnya sendiri; guru membaca semua di sekolahnya", async () => {
    await assertSucceeds(getDoc(doc(a.student, `${school}/users/siswa1`)));
    await assertFails(getDoc(doc(a.student, `${school}/users/siswa2`)));
    await assertFails(getDocs(collection(a.student, `${school}/users`)));
    await assertSucceeds(getDocs(collection(a.teacher1, `${school}/users`)));
    await assertSucceeds(getDoc(doc(a.teacher1, `${school}/users/siswa2`)));
  });

  it("siswa melengkapi nama, kelas, ekskul, dan foto miliknya", async () => {
    const me = doc(a.student, `${school}/users/siswa1`);
    await assertSucceeds(
      updateDoc(me, {
        name: "Siswa Satu Baru",
        classId: CLASS_2,
        extracurriculars: ["Masis-KIR", "PMR"],
        photoUrl: "https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media",
        ...now(),
      }),
    );
    await assertSucceeds(updateDoc(me, {extracurriculars: [], ...now()}));
    await assertSucceeds(
      updateDoc(me, {photoUrl: "https://lh3.googleusercontent.com/a/abc=s400-c", ...now()}),
    );
    await assertSucceeds(updateDoc(me, {photoUrl: null, ...now()}));
  });

  it("kelas harus label yang terdaftar; ekskul harus dari daftar sekolah", async () => {
    const me = doc(a.student, `${school}/users/siswa1`);
    await assertFails(updateDoc(me, {classId: "XII-Z9", ...now()}));
    await assertFails(updateDoc(me, {classId: null, ...now()}));
    await assertFails(updateDoc(me, {extracurriculars: ["Catur"], ...now()}));
    await assertFails(updateDoc(me, {extracurriculars: ["PMR", "PMR"], ...now()}));
    await assertFails(updateDoc(me, {name: "S", ...now()}));
    await assertFails(updateDoc(me, {photoUrl: "https://contoh.com/foto.jpg", ...now()}));
    await assertFails(updateDoc(me, {name: "Tanpa Waktu"})); // updatedAt required
  });

  // docs/03 §6 #18
  it("pengguna tidak bisa mengubah role, email, atau status", async () => {
    const me = doc(a.student, `${school}/users/siswa1`);
    await assertFails(updateDoc(me, {role: "guru", ...now()}));
    await assertFails(updateDoc(me, {status: "active", email: "lain@x.test", ...now()}));
    await assertFails(updateDoc(me, {status: "removed", ...now()}));
    await assertFails(updateDoc(doc(a.student, `${school}/users/siswa2`), {name: "Orang Lain", ...now()}));
  });

  it("guru tidak punya kelas", async () => {
    const me = doc(a.teacher1, `${school}/users/guru1`);
    await assertSucceeds(updateDoc(me, {name: "Guru Satu, S.Pd.", extracurriculars: ["Masis-KIR"], ...now()}));
    await assertFails(updateDoc(me, {classId: CLASS_2, ...now()}));
  });

  it("guru mengatur kelas perwaliannya sendiri: satu kelas terdaftar atau kosong", async () => {
    const me = doc(a.teacher1, `${school}/users/guru1`);
    await assertSucceeds(updateDoc(me, {homeroomClass: CLASS_2, extracurriculars: ["PMR"], ...now()}));
    await assertSucceeds(updateDoc(me, {homeroomClass: null, ...now()}));
    await assertFails(updateDoc(me, {homeroomClass: "XII-Z9", ...now()})); // unlisted
    await assertFails(updateDoc(me, {homeroomClass: [CLASS_1, CLASS_2], ...now()}));
    // not for a student, and not for someone else
    await assertFails(updateDoc(doc(a.student, `${school}/users/siswa1`), {homeroomClass: CLASS_1, ...now()}));
    await assertFails(updateDoc(doc(a.teacher1, `${school}/users/guru2`), {homeroomClass: CLASS_1, ...now()}));
    await assertFails(updateDoc(doc(a.teacher1, `${school}/users/siswa1`), {homeroomClass: CLASS_1, ...now()}));
  });

  it("siswa yang dikeluarkan tidak bisa mengubah profilnya", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await updateDoc(doc(context.firestore() as unknown as Db, `${school}/users/siswa1`), {status: "removed"});
    });
    await assertFails(updateDoc(doc(a.student, `${school}/users/siswa1`), {name: "Masih Bisa", ...now()}));
  });

  it("guru mengubah nama, kelas, dan ekskul siswa, bukan guru lain", async () => {
    const target = doc(a.teacher1, `${school}/users/siswa1`);
    await assertSucceeds(
      updateDoc(target, {name: "Siswa Diubah", classId: CLASS_2, extracurriculars: ["Pala"], ...now()}),
    );
    await assertFails(updateDoc(target, {classId: "X-Q7", ...now()}));
    await assertFails(
      updateDoc(target, {photoUrl: "https://lh3.googleusercontent.com/a/x=s400-c", ...now()}),
    );
    await assertFails(updateDoc(target, {role: "guru", ...now()}));
    await assertFails(updateDoc(target, {status: "removed", ...now()}));
    await assertFails(updateDoc(doc(a.teacher1, `${school}/users/guru2`), {name: "Guru Lain", ...now()}));
  });

  // Accepting the terms of use goes through acceptTerms only.
  it("klien tidak bisa menulis termsVersion atau termsAcceptedAt", async () => {
    const me = doc(a.student, `${school}/users/siswa1`);
    await assertFails(updateDoc(me, {termsVersion: 1, ...now()}));
    await assertFails(updateDoc(me, {termsAcceptedAt: serverTimestamp(), ...now()}));
    await assertFails(updateDoc(me, {name: "Siswa Satu", termsVersion: 1, termsAcceptedAt: serverTimestamp(), ...now()}));
    await assertFails(setDoc(me, {termsVersion: 1, updatedAt: serverTimestamp()}, {merge: true}));
    const teacherMe = doc(a.teacher1, `${school}/users/guru1`);
    await assertFails(updateDoc(teacherMe, {termsVersion: 1, termsAcceptedAt: serverTimestamp(), ...now()}));
    // A teacher cannot accept for a student either, nor create a profile that has accepted.
    await assertFails(updateDoc(doc(a.teacher1, `${school}/users/siswa1`), {termsVersion: 1, ...now()}));
    await assertFails(
      setDoc(doc(a.student, `${school}/users/siswa3`), userDoc("siswa", "Siswa Tiga", {termsVersion: 1})),
    );

    // Once accepted, the fields can be neither raised nor removed; other edits still work.
    await env.withSecurityRulesDisabled(async (context) => {
      await updateDoc(doc(context.firestore() as unknown as Db, `${school}/users/siswa1`), {
        termsVersion: 1,
        termsAcceptedAt: serverTimestamp(),
      });
    });
    await assertFails(updateDoc(me, {termsVersion: 2, ...now()}));
    await assertFails(updateDoc(me, {termsVersion: deleteField(), ...now()}));
    await assertFails(updateDoc(me, {termsAcceptedAt: deleteField(), ...now()}));
    await assertSucceeds(updateDoc(me, {name: "Siswa Satu Lagi", ...now()}));
    await assertSucceeds(updateDoc(doc(a.teacher1, `${school}/users/siswa1`), {name: "Siswa Satu", ...now()}));
  });

  it("klien tidak bisa membuat atau menghapus pengguna", async () => {
    await assertFails(setDoc(doc(a.teacher1, `${school}/users/baru`), {role: "siswa", name: "Baru"}));
    await assertFails(deleteDoc(doc(a.teacher1, `${school}/users/siswa1`)));
  });

  it("token perangkat hanya milik pemilik akun", async () => {
    const mine = doc(a.student, `${school}/users/siswa1/devices/abc`);
    const token = "t".repeat(40);
    await assertSucceeds(setDoc(mine, {token, platform: "android", updatedAt: serverTimestamp()}));
    await assertSucceeds(getDoc(mine));
    await assertFails(setDoc(mine, {token, platform: "ios", updatedAt: serverTimestamp()}));
    await assertFails(getDoc(doc(a.classmate, `${school}/users/siswa1/devices/abc`)));
    await assertFails(getDoc(doc(a.teacher1, `${school}/users/siswa1/devices/abc`)));
    await assertSucceeds(deleteDoc(mine));
  });
});

describe("schools: pengaturan dan label", () => {
  const settings = {neutralWeekdays: [0, 6], holidays: ["2026-12-25"], activeMaxDays: 3, attentionMaxDays: 7};

  it("anggota membaca sekolah; hanya guru mengubah settings dan label", async () => {
    await assertSucceeds(getDoc(doc(a.student, school)));
    await assertSucceeds(updateDoc(doc(a.teacher1, school), {settings}));
    await assertSucceeds(
      updateDoc(doc(a.teacher1, school), {classes: ["X-G", "X-G2", "XI-A4", "XII-A1", "XII-A2"]}),
    );
    await assertSucceeds(updateDoc(doc(a.teacher1, school), {extracurriculars: [...EKSKUL, "Pramuka Inti"]}));
    await assertFails(updateDoc(doc(a.student, school), {settings}));
    await assertFails(updateDoc(doc(a.student, school), {classes: ["X-A"]}));
    await assertFails(updateDoc(doc(a.teacher1, school), {status: "suspended"}));
    await assertFails(updateDoc(doc(a.teacher1, school), {name: "Nama Lain"}));
  });

  it("label kelas dan ekskul yang tidak valid ditolak", async () => {
    const update = (patch: Record<string, unknown>) => updateDoc(doc(a.teacher1, school), patch);
    await assertFails(update({classes: ["XII IPA 1"]}));
    await assertFails(update({classes: ["XIII-A1"]}));
    await assertFails(update({classes: ["xii-a1"]}));
    await assertFails(update({classes: ["XII-A1", "XII-A1"]}));
    await assertFails(update({classes: "XII-A1"}));
    await assertFails(update({extracurriculars: ["P"]}));
    await assertFails(update({extracurriculars: ["PMR", "PMR"]}));
    await assertFails(update({extracurriculars: ["a|b"]}));
    await assertSucceeds(update({classes: []}));
  });

  it("settings yang tidak valid ditolak", async () => {
    const bad = (patch: Record<string, unknown>) =>
      assertFails(updateDoc(doc(a.teacher1, school), {settings: {...settings, ...patch}}));
    await bad({neutralWeekdays: [7]});
    await bad({activeMaxDays: 0});
    await bad({attentionMaxDays: 2});
    await bad({holidays: "2026-12-25"});
    await bad({extra: true});
  });
});
