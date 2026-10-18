// Roster and sign-in: claimAccount, addStudents, removeStudent, eraseStudent,
// addTeacher, removeTeacher and deleteMyAccount against the Auth, Firestore,
// Functions and Storage emulators.

import {getStorage} from "firebase-admin/storage";
import {doc, serverTimestamp, updateDoc} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {
  auth,
  bookSuggestionsCol,
  membersCol,
  programsCol,
  schoolRef,
  statsCol,
  usersCol,
} from "../../src/infra/firebase";
import {
  addJoined,
  addPasswordAccount,
  addSchool,
  addToRoster,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  eventually,
  signIn,
  signInWithGoogle,
} from "./helpers";

const A = "sman1";
const B = "sman2";

let teacherA: Client;
let teacherB: Client;

/** The `details.reason` a callable failed with. */
async function reasonOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
    return undefined;
  } catch (error) {
    return (error as {details?: {reason?: string}}).details?.reason;
  }
}

/** The message a callable failed with. */
async function messageOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
    return undefined;
  } catch (error) {
    return (error as {message?: string}).message;
  }
}

beforeAll(async () => {
  await clearEmulators();
  await addSchool(A);
  await addSchool(B);
  teacherA = await addJoined(A, {email: "guru.a@sekolah.test", role: "guru", name: "Guru A"});
  teacherB = await addJoined(B, {email: "guru.b@sekolah.test", role: "guru", name: "Guru B"});
});

afterAll(closeClients);

describe("claimAccount", () => {
  it("menolak email yang belum diverifikasi", async () => {
    await addToRoster(A, {email: "belum@sekolah.test", role: "siswa"});
    await addPasswordAccount("belum@sekolah.test", false);
    const client = await signIn("belum@sekolah.test");
    expect(await codeOf(client.join())).toBe("failed-precondition");
    expect(await reasonOf(client.join())).toBe("email-not-verified");
  });

  it("email yang tidak ada di daftar mana pun: not-registered, akun tetap ada", async () => {
    const uid = await addPasswordAccount("asing@sekolah.test");
    const client = await signIn("asing@sekolah.test");
    expect(await codeOf(client.join())).toBe("not-found");
    expect(await reasonOf(client.join())).toBe("not-registered");
    expect((await auth.getUser(uid)).email).toBe("asing@sekolah.test");
  });

  it("masuk Google pertama: profil dari daftar, foto Google diperbesar, claims terpasang", async () => {
    await addToRoster(A, {
      email: "gita@gmail.com",
      role: "siswa",
      name: "Gita Lestari",
      classId: "XII-A2",
      extracurriculars: ["PMR"],
    });
    const client = await signInWithGoogle("gita@gmail.com", {
      picture: "https://lh3.googleusercontent.com/a/gita=s96-c",
    });
    expect(await client.join()).toEqual({role: "siswa", schoolId: A});

    const claims = (await auth.getUser(client.uid)).customClaims;
    expect(claims).toEqual({role: "siswa", schoolId: A});
    const profile = (await usersCol(A).doc(client.uid).get()).data();
    expect(profile).toMatchObject({
      role: "siswa",
      name: "Gita Lestari",
      email: "gita@gmail.com",
      classId: "XII-A2",
      extracurriculars: ["PMR"],
      photoUrl: "https://lh3.googleusercontent.com/a/gita=s400-c",
      status: "active",
    });
    expect((await membersCol().doc("gita@gmail.com").get()).get("uid")).toBe(client.uid);
    const stats = await eventually(async () => (await statsCol(A).doc(client.uid).get()).data());
    expect(stats).toMatchObject({photoUrl: "https://lh3.googleusercontent.com/a/gita=s400-c"});

    // Every later sign-in calls it again; nothing changes.
    const before = (await usersCol(A).doc(client.uid).get()).updateTime;
    await client.join();
    expect((await usersCol(A).doc(client.uid).get()).updateTime).toEqual(before);
  });

  it("foto yang sudah ada tidak pernah diganti foto Google", async () => {
    const own = "https://firebasestorage.googleapis.com/v0/b/x/o/gita.jpg?alt=media";
    const client = await signInWithGoogle("gita@gmail.com", {
      picture: "https://lh3.googleusercontent.com/a/gita-baru=s96-c",
    });
    await usersCol(A).doc(client.uid).update({photoUrl: own});
    await client.join();
    expect((await usersCol(A).doc(client.uid).get()).get("photoUrl")).toBe(own);
  });

  it("foto kosong diisi saat akun email kemudian masuk dengan Google", async () => {
    const client = await addJoined(A, {email: "dewi@gmail.com", role: "siswa", name: "Dewi"});
    expect((await usersCol(A).doc(client.uid).get()).get("photoUrl")).toBeNull();
    // Google is authoritative for gmail.com: the verified account gets Google linked.
    const google = await signInWithGoogle("dewi@gmail.com", {
      picture: "https://lh3.googleusercontent.com/a/dewi=s96-c",
    });
    expect(google.uid).toBe(client.uid);
    await google.join();
    expect((await usersCol(A).doc(client.uid).get()).get("photoUrl")).toBe(
      "https://lh3.googleusercontent.com/a/dewi=s400-c",
    );
  });
});

describe("addStudents", () => {
  it("menormalkan kelas, menambah label baru, dan melapor per baris", async () => {
    await addToRoster(B, {email: "milik.b@sekolah.test", role: "siswa"});
    const {results} = await teacherA.call<{results: {email: string; ok: boolean; reason?: string}[]}>(
      "addStudents",
      {
        students: [
          {email: " Bima@Gmail.com ", name: "Bima Saputra", classId: "12  A1", extracurriculars: ["masis-kir"]},
          {email: "zafira@gmail.com", name: "Salsabila", classId: "X-G2"},
          {email: "tanpa.data@gmail.com"},
          {email: "bukan-email"},
          {email: "salah.kelas@gmail.com", classId: "kelas dua belas"},
          {email: "ekskul@gmail.com", extracurriculars: ["Catur"]},
          {email: "milik.b@sekolah.test"},
          {email: "bima@gmail.com"},
        ],
      },
    );
    expect(results.map((r) => r.ok)).toEqual([true, true, true, false, false, false, false, false]);
    expect(results[6].reason).toBe("Email sudah terdaftar.");
    expect(results[7].reason).toBe("Email kembar dalam daftar ini.");

    expect((await membersCol().doc("bima@gmail.com").get()).data()).toMatchObject({
      schoolId: A,
      role: "siswa",
      name: "Bima Saputra",
      classId: "XII-A1",
      extracurriculars: ["Masis-KIR"],
      uid: null,
    });
    expect((await membersCol().doc("tanpa.data@gmail.com").get()).data()).toMatchObject({
      name: "",
      classId: null,
    });
    expect((await schoolRef(A).get()).get("classes")).toEqual(["X-G2", "XII-A1", "XII-A2"]);
    // The other school's entry is untouched.
    expect((await membersCol().doc("milik.b@sekolah.test").get()).get("schoolId")).toBe(B);
  });

  it("menambah ulang siswa yang sama di sekolah yang sama tidak gagal", async () => {
    const {results} = await teacherA.call<{results: {ok: boolean}[]}>("addStudents", {
      students: [{email: "bima@gmail.com"}],
    });
    expect(results[0].ok).toBe(true);
  });

  it("hanya guru yang boleh menambah siswa", async () => {
    const student = await addJoined(A, {email: "raka@sekolah.test", role: "siswa", name: "Raka", classId: "XII-A1"});
    expect(await codeOf(student.call("addStudents", {students: [{email: "x@gmail.com"}]}))).toBe(
      "permission-denied",
    );
  });
});

describe("removeStudent dan eraseStudent", () => {
  it("guru tidak bisa mengeluarkan guru lain atau siswa sekolah lain", async () => {
    await addJoined(A, {email: "guru.dua@sekolah.test", role: "guru", name: "Guru Dua"});
    expect(await codeOf(teacherA.call("removeStudent", {email: "guru.dua@sekolah.test"}))).toBe(
      "permission-denied",
    );
    expect(await codeOf(teacherB.call("removeStudent", {email: "raka@sekolah.test"}))).toBe(
      "not-found",
    );
    expect((await membersCol().doc("guru.dua@sekolah.test").get()).exists).toBe(true);
  });

  it("mengeluarkan siswa yang belum pernah masuk hanya menghapus daftarnya", async () => {
    await teacherA.call("removeStudent", {email: "tanpa.data@gmail.com"});
    expect((await membersCol().doc("tanpa.data@gmail.com").get()).exists).toBe(false);
  });

  it("hapus data permanen: semua data siswa di sekolah hilang, akun tetap", async () => {
    const student = await addJoined(A, {email: "hapus@sekolah.test", role: "siswa", name: "Hapus", classId: "XII-A1"});
    await programsCol(A).doc("buku-hapus").set({studentId: student.uid, classId: "XII-A1", status: "completed"});
    await programsCol(A).doc("buku-hapus").collection("journals").doc("2026-10-01").set({studentId: student.uid});

    const result = await teacherA.call<{programs: number}>("eraseStudent", {email: "hapus@sekolah.test"});
    expect(result.programs).toBe(1);
    expect((await usersCol(A).doc(student.uid).get()).exists).toBe(false);
    expect((await programsCol(A).doc("buku-hapus").get()).exists).toBe(false);
    expect((await membersCol().doc("hapus@sekolah.test").get()).exists).toBe(false);
    await eventually(async () => !(await statsCol(A).doc(student.uid).get()).exists);
    const record = await auth.getUser(student.uid);
    expect(record.email).toBe("hapus@sekolah.test");
    expect(record.customClaims ?? {}).not.toHaveProperty("schoolId");
  });

  it("siswa yang dikeluarkan tidak bisa lagi menulis ke sekolah", async () => {
    const student = await addJoined(A, {email: "keluar@sekolah.test", role: "siswa", name: "Keluar", classId: "XII-A1"});
    await teacherA.call("removeStudent", {email: "keluar@sekolah.test"});
    expect((await usersCol(A).doc(student.uid).get()).get("status")).toBe("removed");
    // A fresh sign-in carries no school claims any more.
    const again = await signIn("keluar@sekolah.test");
    await expect(
      updateDoc(doc(again.db, `schools/${A}/users/${student.uid}`), {
        name: "Masih Di Sini",
        updatedAt: serverTimestamp(),
      }),
    ).rejects.toThrow();
  });
});

describe("addTeacher dan removeTeacher", () => {
  it("guru menambah guru lain dengan wali kelas dan ekskul; klaim menyalinnya", async () => {
    const result = await teacherA.call<{joined: boolean}>("addTeacher", {
      email: " Wali@Sekolah.test ",
      name: "Bu Wali",
      homeroomClass: "12 a1",
      extracurriculars: ["pmr"],
    });
    expect(result.joined).toBe(false);
    expect((await membersCol().doc("wali@sekolah.test").get()).data()).toMatchObject({
      schoolId: A,
      role: "guru",
      name: "Bu Wali",
      classId: null,
      homeroomClass: "XII-A1",
      extracurriculars: ["PMR"],
      uid: null,
      addedBy: teacherA.uid,
    });

    await addPasswordAccount("wali@sekolah.test");
    const wali = await signIn("wali@sekolah.test");
    expect(await wali.join()).toEqual({role: "guru", schoolId: A});
    expect((await usersCol(A).doc(wali.uid).get()).data()).toMatchObject({
      role: "guru",
      name: "Bu Wali",
      homeroomClass: "XII-A1",
      extracurriculars: ["PMR"],
    });
  });

  it("akun yang sudah ada langsung bergabung", async () => {
    const uid = await addPasswordAccount("langsung@sekolah.test");
    const result = await teacherA.call<{joined: boolean}>("addTeacher", {
      email: "langsung@sekolah.test",
      name: "Pak Langsung",
    });
    expect(result.joined).toBe(true);
    expect((await auth.getUser(uid)).customClaims).toMatchObject({role: "guru", schoolId: A});
    expect((await usersCol(A).doc(uid).get()).get("homeroomClass")).toBeNull();
  });

  it("menolak kelas tak terdaftar, email terdaftar, nama kosong, dan siswa", async () => {
    expect(
      await messageOf(teacherA.call("addTeacher", {email: "z@sekolah.test", name: "Guru Z", homeroomClass: "XII-Z9"})),
    ).toContain('Kelas "XII-Z9" belum ada di sekolah.');
    expect(await codeOf(teacherA.call("addTeacher", {email: "guru.b@sekolah.test", name: "Guru B"}))).toBe(
      "already-exists",
    );
    expect(await codeOf(teacherA.call("addTeacher", {email: "wali@sekolah.test", name: "Bu Wali"}))).toBe(
      "already-exists",
    );
    expect(await codeOf(teacherA.call("addTeacher", {email: "tanpa.nama@sekolah.test", name: " "}))).toBe(
      "invalid-argument",
    );
    const student = await addJoined(A, {email: "siswa.pj@sekolah.test", role: "siswa", name: "Siswa", classId: "XII-A1"});
    expect(await codeOf(student.call("addTeacher", {email: "x@sekolah.test", name: "Guru X"}))).toBe(
      "permission-denied",
    );
    expect(await codeOf(student.call("removeTeacher", {email: "wali@sekolah.test"}))).toBe("permission-denied");
    expect((await membersCol().doc("z@sekolah.test").get()).exists).toBe(false);
  });

  it("guru mengeluarkan guru lain atau membatalkan undangan, bukan dirinya sendiri", async () => {
    expect(await codeOf(teacherA.call("removeTeacher", {email: "guru.a@sekolah.test"}))).toBe(
      "failed-precondition",
    );
    expect(await codeOf(teacherB.call("removeTeacher", {email: "wali@sekolah.test"}))).toBe("not-found");
    expect(await codeOf(teacherA.call("removeTeacher", {email: "siswa.pj@sekolah.test"}))).toBe("not-found");

    await teacherA.call("addTeacher", {email: "batal@sekolah.test", name: "Guru Batal"});
    await teacherA.call("removeTeacher", {email: "batal@sekolah.test"});
    expect((await membersCol().doc("batal@sekolah.test").get()).exists).toBe(false);

    const waliUid = (await membersCol().doc("wali@sekolah.test").get()).get("uid") as string;
    await teacherA.call("removeTeacher", {email: "wali@sekolah.test"});
    expect((await membersCol().doc("wali@sekolah.test").get()).exists).toBe(false);
    expect((await usersCol(A).doc(waliUid).get()).get("status")).toBe("removed");
    expect((await auth.getUser(waliUid)).customClaims ?? {}).not.toHaveProperty("schoolId");
  });
});

describe("akun pindah dan hapus akun sendiri", () => {
  it("email yang dibuat ulang mengambil alih daftar; profil lama ditandai removed", async () => {
    const first = await addJoined(A, {email: "ulang@sekolah.test", role: "siswa", name: "Ulang", classId: "XII-A1"});
    await auth.deleteUser(first.uid);
    await addPasswordAccount("ulang@sekolah.test");
    const second = await signIn("ulang@sekolah.test");
    await second.join();
    expect((await usersCol(A).doc(first.uid).get()).get("status")).toBe("removed");
    expect((await membersCol().doc("ulang@sekolah.test").get()).get("uid")).toBe(second.uid);
  });

  it("siswa menghapus akunnya: akun, profil, dan daftar hilang", async () => {
    const student = await addJoined(A, {email: "pamit@sekolah.test", role: "siswa", name: "Pamit", classId: "XII-A1"});
    await programsCol(A).doc("buku-pamit").set({studentId: student.uid, classId: "XII-A1", status: "stopped"});
    await student.call("deleteMyAccount");
    expect(await codeOf(auth.getUser(student.uid))).toBe("auth/user-not-found");
    expect((await usersCol(A).doc(student.uid).get()).exists).toBe(false);
    expect((await programsCol(A).doc("buku-pamit").get()).exists).toBe(false);
    expect((await membersCol().doc("pamit@sekolah.test").get()).exists).toBe(false);
  });

  it("hapus akun ikut menghapus foto cover unggahan siswa dan rujukannya di saran", async () => {
    const bucket = getStorage().bucket(process.env.STORAGE_BUCKET ?? "demo-sabusaku.appspot.com");
    const student = await addJoined(A, {email: "cover@sekolah.test", role: "siswa", name: "Cover", classId: "XII-A1"});
    const path = `schools/${A}/programCovers/${student.uid}/1700000000.jpg`;
    await bucket.file(path).save(Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2]), {contentType: "image/jpeg"});
    const cover = {coverUrl: "https://example.test/cover.jpg", coverPath: path};
    const coverOnly = await bookSuggestionsCol().add({kind: "edit", bookId: "bk-a", status: "pending", proposed: cover});
    const newBook = await bookSuggestionsCol().add({
      kind: "new",
      bookId: null,
      status: "pending",
      proposed: {title: "Buku Baru", ...cover},
    });
    const rejected = await bookSuggestionsCol().add({kind: "edit", bookId: "bk-a", status: "rejected", proposed: cover});
    const otherPath = `schools/${A}/programCovers/orang-lain/1700000000.jpg`;
    const other = await bookSuggestionsCol().add({
      kind: "edit",
      bookId: "bk-a",
      status: "pending",
      proposed: {...cover, coverPath: otherPath},
    });

    await student.call("deleteMyAccount");

    expect((await bucket.file(path).exists())[0]).toBe(false);
    // Nothing left to propose once the cover is gone.
    expect((await coverOnly.get()).exists).toBe(false);
    // The book data stays; it names no student.
    expect((await newBook.get()).get("proposed")).toEqual({title: "Buku Baru"});
    expect((await rejected.get()).get("proposed")).toEqual({});
    expect((await other.get()).get("proposed.coverPath")).toBe(otherPath);
  });

  it("pengguna tanpa sekolah juga bisa menghapus akunnya", async () => {
    const uid = await addPasswordAccount("sendiri@sekolah.test");
    const client = await signIn("sendiri@sekolah.test");
    await client.call("deleteMyAccount");
    expect(await codeOf(auth.getUser(uid))).toBe("auth/user-not-found");
  });
});
