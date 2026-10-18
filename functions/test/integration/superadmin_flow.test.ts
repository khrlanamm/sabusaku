// Superadmin: listSchools, switchSchool, createSchool, and the superadmin's
// first sign-in, against the Auth, Firestore and Functions emulators.

import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {SUPERADMIN_EMAILS} from "../../src/config";
import {auth, membersCol, schoolRef, usersCol} from "../../src/infra/firebase";
import {
  addJoined,
  addPasswordAccount,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  signIn,
  signInWithGoogle,
} from "./helpers";

const A = "sman1";
const B = "sman2";
const SUPERADMIN = SUPERADMIN_EMAILS[0];

let teacherA: Client;
let superadmin: Client;

beforeAll(async () => {
  await clearEmulators();
  await addSchool(A);
  await addSchool(B);
  teacherA = await addJoined(A, {email: "guru.a@sekolah.test", role: "guru", name: "Guru A"});
});

afterAll(closeClients);

describe("superadmin", () => {
  it("masuk pertama tanpa daftar: menjadi penanggung jawab sekolah aktif pertama", async () => {
    superadmin = await signInWithGoogle(SUPERADMIN);
    expect(await superadmin.join()).toEqual({role: "guru", schoolId: A});
    expect((await auth.getUser(superadmin.uid)).customClaims).toEqual({
      role: "guru",
      schoolId: A,
      superadmin: true,
    });
    expect((await membersCol().doc(SUPERADMIN).get()).data()).toMatchObject({
      schoolId: A,
      role: "guru",
      addedBy: "superadmin",
      uid: superadmin.uid,
    });
    expect((await usersCol(A).doc(superadmin.uid).get()).get("status")).toBe("active");
  });

  it("guru biasa ditolak dan claims-nya tanpa superadmin", async () => {
    expect((await auth.getUser(teacherA.uid)).customClaims).toEqual({role: "guru", schoolId: A});
    expect(await codeOf(teacherA.call("listSchools"))).toBe("permission-denied");
    expect(await codeOf(teacherA.call("switchSchool", {schoolId: B}))).toBe("permission-denied");
    expect(
      await codeOf(
        teacherA.call("createSchool", {
          code: "sman9",
          name: "SMA 9",
          teacherEmail: "pj9@sekolah.test",
          teacherName: "PJ Sembilan",
        }),
      ),
    ).toBe("permission-denied");
  });

  it("melihat semua sekolah", async () => {
    const {schools} = await superadmin.call<{schools: {id: string; status: string}[]}>(
      "listSchools",
    );
    expect(schools.map((school) => school.id)).toEqual([A, B]);
    expect(schools.every((school) => school.status === "active")).toBe(true);
  });

  it("ganti sekolah: claims dan profil pindah, profil lama tidak aktif", async () => {
    expect(await superadmin.call("switchSchool", {schoolId: B})).toEqual({
      role: "guru",
      schoolId: B,
    });
    expect((await auth.getUser(superadmin.uid)).customClaims).toMatchObject({schoolId: B});
    expect((await membersCol().doc(SUPERADMIN).get()).get("schoolId")).toBe(B);
    expect((await usersCol(B).doc(superadmin.uid).get()).get("status")).toBe("active");
    expect((await usersCol(A).doc(superadmin.uid).get()).get("status")).toBe("removed");

    // Back again: the old profile is active once more.
    await superadmin.call("switchSchool", {schoolId: A});
    expect((await usersCol(A).doc(superadmin.uid).get()).get("status")).toBe("active");
    expect((await usersCol(B).doc(superadmin.uid).get()).get("status")).toBe("removed");
    await superadmin.user.getIdToken(true);
  });

  it("sekolah yang tidak ada ditolak", async () => {
    expect(await codeOf(superadmin.call("switchSchool", {schoolId: "tidakada"}))).toBe("not-found");
  });

  it("guru lain tidak bisa mengeluarkan superadmin", async () => {
    expect(await codeOf(teacherA.call("removeTeacher", {email: SUPERADMIN}))).toBe(
      "failed-precondition",
    );
  });

  it("menambah sekolah dengan penanggung jawab pertamanya", async () => {
    const result = await superadmin.call<{schoolId: string; joined: boolean}>("createSchool", {
      code: " SMAN3 ",
      name: "SMA Negeri 3",
      teacherEmail: "PJ3@Sekolah.test",
      teacherName: "Pak Tiga",
    });
    expect(result).toEqual({schoolId: "sman3", joined: false});
    expect((await schoolRef("sman3").get()).data()).toMatchObject({
      name: "SMA Negeri 3",
      status: "active",
      classes: [],
    });
    expect((await membersCol().doc("pj3@sekolah.test").get()).data()).toMatchObject({
      schoolId: "sman3",
      role: "guru",
      name: "Pak Tiga",
      uid: null,
      addedBy: "superadmin",
    });

    // The teacher signs up later and joins the new school.
    await addPasswordAccount("pj3@sekolah.test");
    const pj = await signIn("pj3@sekolah.test");
    expect(await pj.join()).toEqual({role: "guru", schoolId: "sman3"});
  });

  it("penanggung jawab yang sudah punya akun langsung bergabung", async () => {
    await addPasswordAccount("pj4@sekolah.test");
    const result = await superadmin.call<{joined: boolean}>("createSchool", {
      code: "sman4",
      name: "SMA Negeri 4",
      teacherEmail: "pj4@sekolah.test",
      teacherName: "Bu Empat",
    });
    expect(result.joined).toBe(true);
    const user = await auth.getUserByEmail("pj4@sekolah.test");
    expect(user.customClaims).toEqual({role: "guru", schoolId: "sman4"});
  });

  it("kode terpakai atau email terdaftar ditolak tanpa membuat sekolah", async () => {
    const add = (code: string, teacherEmail: string) =>
      superadmin.call("createSchool", {
        code,
        name: "Sekolah Baru",
        teacherEmail,
        teacherName: "Guru Baru",
      });
    expect(await codeOf(add(B, "baru@sekolah.test"))).toBe("already-exists");
    expect(await codeOf(add("sman5", "guru.a@sekolah.test"))).toBe("already-exists");
    expect((await schoolRef("sman5").get()).exists).toBe(false);
    expect(await codeOf(add("sman5", SUPERADMIN))).toBe("invalid-argument");
    expect(await codeOf(add("ab", "baru@sekolah.test"))).toBe("invalid-argument");
    expect((await membersCol().doc("baru@sekolah.test").get()).exists).toBe(false);
  });
});
