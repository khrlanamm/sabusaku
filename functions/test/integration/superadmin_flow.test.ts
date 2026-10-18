// The superadmin: claimAccount without a roster entry, switchSchool and
// addSchool against the Auth, Firestore and Functions emulators.

import {collection, doc, getDocs, serverTimestamp, updateDoc} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {DEFAULT_EXTRACURRICULARS} from "../../src/domain/labels";
import {CURRENT_TERMS_VERSION} from "../../src/domain/terms";
import {auth, membersCol, schoolRef, usersCol} from "../../src/infra/firebase";
import {
  addJoined,
  addPasswordAccount,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  eventually,
  signInWithGoogle,
} from "./helpers";

const A = "sman1";
const B = "sman2";
const SUPER = "benevology@gmail.com";

let teacherA: Client;
let superadmin: Client;

beforeAll(async () => {
  await clearEmulators();
  await addSchool(A);
  await addSchool(B);
  teacherA = await addJoined(A, {email: "guru.a@sekolah.test", role: "guru", name: "Guru A"});
});

afterAll(closeClients);

describe("superadmin masuk dan pindah sekolah", () => {
  it("masuk tanpa roster ke sekolah aktif pertama, sebagai guru bertanda superadmin", async () => {
    superadmin = await signInWithGoogle(SUPER, {name: "Super Admin"});
    expect(await superadmin.join()).toEqual({role: "guru", schoolId: A});
    expect((await auth.getUser(superadmin.uid)).customClaims).toEqual({
      role: "guru",
      schoolId: A,
      superadmin: true,
    });
    expect((await usersCol(A).doc(superadmin.uid).get()).data()).toMatchObject({
      role: "guru",
      name: "Super Admin",
      email: SUPER,
      status: "active",
      superadmin: true,
    });
    expect((await membersCol().doc(SUPER).get()).exists).toBe(false);
  });

  it("pindah sekolah: profil baru menyalin nama dan ketentuan, profil lama tetap aktif", async () => {
    await superadmin.call("acceptTerms", {version: CURRENT_TERMS_VERSION});
    expect(await superadmin.call("switchSchool", {schoolId: B})).toEqual({schoolId: B});
    await superadmin.user.getIdToken(true);

    expect((await auth.getUser(superadmin.uid)).customClaims).toMatchObject({schoolId: B, superadmin: true});
    expect((await usersCol(B).doc(superadmin.uid).get()).data()).toMatchObject({
      role: "guru",
      name: "Super Admin",
      termsVersion: CURRENT_TERMS_VERSION,
      status: "active",
      superadmin: true,
    });
    expect((await usersCol(A).doc(superadmin.uid).get()).get("status")).toBe("active");
  });

  it("bertindak sebagai guru sekolah yang dibuka", async () => {
    await superadmin.call("addTeacher", {email: "guru.baru@sekolah.test", name: "Guru Baru"});
    expect((await membersCol().doc("guru.baru@sekolah.test").get()).data()).toMatchObject({
      schoolId: B,
      addedBy: superadmin.uid,
    });
  });

  it("masuk lagi dengan Google tetap di sekolah yang dibuka", async () => {
    expect(await superadmin.join()).toEqual({role: "guru", schoolId: B});
  });

  it("tetap diakui saat email_verified hilang selama akun Google masih tertaut", async () => {
    await auth.updateUser(superadmin.uid, {emailVerified: false});
    await superadmin.user.getIdToken(true);
    expect(await codeOf(superadmin.call("switchSchool", {schoolId: A}))).toBe("ok");
    await superadmin.user.getIdToken(true);
    expect(await superadmin.join()).toEqual({role: "guru", schoolId: A});
  });

  it("sekolah yang tidak ada ditolak", async () => {
    expect(await codeOf(superadmin.call("switchSchool", {schoolId: "tidakada"}))).toBe("not-found");
  });

  it("melihat daftar semua sekolah", async () => {
    const schools = await getDocs(collection(superadmin.db, "schools"));
    expect(schools.docs.map((school) => school.id).sort()).toEqual([A, B]);
  });

  it("tidak masuk daftar wali kelas yang dilihat siswa", async () => {
    await updateDoc(doc(superadmin.db, `schools/${A}/users/${superadmin.uid}`), {
      homeroomClass: "XII-A1",
      updatedAt: serverTimestamp(),
    });
    await updateDoc(doc(teacherA.db, `schools/${A}/users/${teacherA.uid}`), {
      homeroomClass: "XII-A2",
      updatedAt: serverTimestamp(),
    });
    // Rebuilt after both writes: Guru A is in, the superadmin is not.
    const staff = await eventually(async () => {
      const value = (await schoolRef(A).get()).get("staff");
      return value?.homerooms?.["XII-A2"]?.includes("Guru A") ? value : null;
    });
    expect(staff.homerooms["XII-A1"]).toBeUndefined();
  });

  it("tidak bisa didaftarkan ke sekolah atau menghapus akunnya dari aplikasi", async () => {
    expect(await codeOf(teacherA.call("addTeacher", {email: SUPER, name: "Super"}))).toBe("invalid-argument");
    expect(await codeOf(superadmin.call("deleteMyAccount"))).toBe("failed-precondition");
    expect((await auth.getUser(superadmin.uid)).disabled).toBe(false);
  });

  it("guru biasa tidak bisa pindah sekolah, menambah sekolah, atau melihat daftarnya", async () => {
    expect(await codeOf(teacherA.call("switchSchool", {schoolId: B}))).toBe("permission-denied");
    expect(
      await codeOf(
        teacherA.call("addSchool", {code: "sman9", name: "SMA 9", teacherName: "Guru", teacherEmail: "g@x.test"}),
      ),
    ).toBe("permission-denied");
    expect(await codeOf(getDocs(collection(teacherA.db, "schools")))).toBe("permission-denied");
    expect((await schoolRef("sman9").get()).exists).toBe(false);
  });
});

describe("addSchool", () => {
  it("membuat sekolah dengan PJ pertama yang belum masuk", async () => {
    const result = await superadmin.call("addSchool", {
      code: " SMAN3 ",
      name: "SMA  Negeri 3",
      teacherName: "Guru  Tiga",
      teacherEmail: " Guru.Tiga@Sekolah.test ",
    });
    expect(result).toEqual({schoolId: "sman3", joined: false});
    expect((await schoolRef("sman3").get()).data()).toMatchObject({
      name: "SMA Negeri 3",
      status: "active",
      classes: [],
      extracurriculars: DEFAULT_EXTRACURRICULARS,
    });
    expect((await membersCol().doc("guru.tiga@sekolah.test").get()).data()).toMatchObject({
      schoolId: "sman3",
      role: "guru",
      name: "Guru Tiga",
      uid: null,
      addedBy: superadmin.uid,
    });
    // Adding a school does not open it.
    expect((await auth.getUser(superadmin.uid)).customClaims).toMatchObject({schoolId: A});
  });

  it("PJ yang sudah punya akun langsung bergabung", async () => {
    const uid = await addPasswordAccount("guru.empat@sekolah.test");
    const result = await superadmin.call("addSchool", {
      code: "sman4",
      name: "SMA Negeri 4",
      teacherName: "Guru Empat",
      teacherEmail: "guru.empat@sekolah.test",
    });
    expect(result).toEqual({schoolId: "sman4", joined: true});
    expect((await auth.getUser(uid)).customClaims).toEqual({role: "guru", schoolId: "sman4"});
  });

  it("kode terpakai dan email terdaftar ditolak tanpa meninggalkan data", async () => {
    expect(
      await codeOf(
        superadmin.call("addSchool", {
          code: "sman3",
          name: "SMA Lain",
          teacherName: "Guru Lain",
          teacherEmail: "guru.lain@sekolah.test",
        }),
      ),
    ).toBe("already-exists");
    expect((await membersCol().doc("guru.lain@sekolah.test").get()).exists).toBe(false);
    expect((await schoolRef("sman3").get()).get("name")).toBe("SMA Negeri 3");

    expect(
      await codeOf(
        superadmin.call("addSchool", {
          code: "sman5",
          name: "SMA Negeri 5",
          teacherName: "Guru A",
          teacherEmail: "guru.a@sekolah.test",
        }),
      ),
    ).toBe("already-exists");
    expect((await schoolRef("sman5").get()).exists).toBe(false);
  });

  it("isian tidak valid ditolak", async () => {
    const valid = {code: "sman6", name: "SMA Negeri 6", teacherName: "Guru Enam", teacherEmail: "enam@sekolah.test"};
    for (const change of [
      {code: "ab"},
      {code: "sman-6"},
      {name: "AB"},
      {teacherName: "G"},
      {teacherEmail: "bukan-email"},
      {teacherEmail: SUPER},
    ]) {
      expect(await codeOf(superadmin.call("addSchool", {...valid, ...change}))).toBe("invalid-argument");
    }
    expect((await schoolRef("sman6").get()).exists).toBe(false);
  });

  it("sekolah baru bisa langsung dibuka", async () => {
    await superadmin.call("switchSchool", {schoolId: "sman3"});
    await superadmin.user.getIdToken(true);
    await superadmin.call("addStudents", {students: [{email: "siswa.tiga@sekolah.test", classId: "X-A"}]});
    expect((await membersCol().doc("siswa.tiga@sekolah.test").get()).get("schoolId")).toBe("sman3");
  });
});
