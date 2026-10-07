import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {
  activeProgramsCol,
  auth,
  classesCol,
  programsCol,
  statsCol,
  usersCol,
} from "../../src/infra/firebase";
import {
  addAccount,
  addClass,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  PASSWORD,
  signIn,
} from "./helpers";

const SCHOOL = "sman1";

interface CreateResult {
  username: string;
  ok: boolean;
  uid?: string;
  password?: string;
  reason?: string;
}

let admin: Client;

beforeAll(async () => {
  await clearEmulators();
  await addSchool(SCHOOL);
  await addSchool("sman2");
  await addClass(SCHOOL, "k1", "XII IPA 1");
  await addClass(SCHOOL, "k2", "XII IPA 2");
  await classesCol(SCHOOL).doc("lama").set({
    name: "XII Lama",
    grade: 12,
    academicYear: "2025/2026",
    teacherIds: [],
    isArchived: true,
  });
  admin = await signIn(SCHOOL, "admin");
});

afterAll(closeClients);

describe("createUsers", () => {
  let results: CreateResult[];

  beforeAll(async () => {
    ({results} = await admin.call<{results: CreateResult[]}>("createUsers", {
      users: [
        {role: "guru", name: "Bu Sari", username: "sari", classIds: ["k1"]},
        {role: "siswa", name: "Raka Pratama", username: " 1001 ", classId: "k1"},
        {role: "siswa", name: "Dewi Lestari", username: "1002", classId: "k2"},
        {role: "siswa", name: "Kembar", username: "1001", classId: "k1"},
        {role: "siswa", name: "Tanpa Kelas", username: "1003", classId: "tidak-ada"},
        {role: "siswa", name: "Kelas Arsip", username: "1004", classId: "lama"},
        {role: "siswa", name: "X", username: "1005", classId: "k1"},
        {role: "siswa", name: "Username Aneh", username: "Budi Santoso", classId: "k1"},
      ],
    }));
  });

  it("melaporkan hasil per baris dengan alasan yang jelas", () => {
    expect(results.map((r) => r.ok)).toEqual([true, true, true, false, false, false, false, false]);
    expect(results[1].username).toBe("1001");
    expect(results[3].reason).toMatch(/kembar/i);
    expect(results[4].reason).toMatch(/Kelas tidak ditemukan/);
    expect(results[5].reason).toMatch(/diarsipkan/);
    expect(results[6].reason).toMatch(/Nama/);
    expect(results[7].reason).toMatch(/Username/);
    expect(results[0].password).toHaveLength(10);
  });

  it("membuat profil, claims, ringkasan siswa, dan cermin kelas guru", async () => {
    const [teacher, student] = results;
    const teacherDoc = await usersCol(SCHOOL).doc(teacher.uid!).get();
    expect(teacherDoc.data()).toMatchObject({
      role: "guru",
      name: "Bu Sari",
      classIds: ["k1"],
      status: "active",
      mustChangePassword: true,
    });
    expect((await auth.getUser(teacher.uid!)).customClaims).toEqual({
      role: "guru",
      schoolId: SCHOOL,
      classIds: ["k1"],
    });
    expect((await classesCol(SCHOOL).doc("k1").get()).get("teacherIds")).toEqual([teacher.uid]);

    const studentDoc = await usersCol(SCHOOL).doc(student.uid!).get();
    expect(studentDoc.data()).toMatchObject({role: "siswa", nis: "1001", classId: "k1"});
    expect((await auth.getUser(student.uid!)).customClaims).toEqual({
      role: "siswa",
      schoolId: SCHOOL,
    });
    expect((await statsCol(SCHOOL).doc(student.uid!).get()).data()).toMatchObject({
      studentId: student.uid,
      name: "Raka Pratama",
      classId: "k1",
      className: "XII IPA 1",
      status: "belum_mulai",
      activeProgram: null,
    });
  });

  it("akun baru bisa login dengan password awal yang dikembalikan", async () => {
    const student = await signIn(SCHOOL, "1001", results[1].password);
    expect(student.uid).toBe(results[1].uid);
  });

  it("username yang sudah dipakai ditolak, tetapi boleh sama di sekolah lain", async () => {
    await expect(
      codeOf(
        admin.call("createUsers", {
          users: [{role: "siswa", name: "Raka Kedua", username: "1001", classId: "k1"}],
        }),
      ),
    ).resolves.toBe("failed-precondition");

    await addClass("sman2", "k1", "X IPA 1");
    const other = await signIn("sman2", "admin");
    const {results: otherResults} = await other.call<{results: CreateResult[]}>("createUsers", {
      users: [{role: "siswa", name: "Raka Lain", username: "1001", classId: "k1"}],
    });
    expect(otherResults[0].ok).toBe(true);
  });

  it("hanya admin yang boleh, dan maksimal 100 baris", async () => {
    const teacher = await signIn(SCHOOL, "sari", results[0].password);
    const one = {role: "siswa", name: "Siswa Baru", username: "2001", classId: "k1"};
    expect(await codeOf(teacher.call("createUsers", {users: [one]}))).toBe("permission-denied");
    expect(await codeOf(admin.call("createUsers", {users: []}))).toBe("invalid-argument");
    const many = Array.from({length: 101}, (_, i) => ({...one, username: `3${1000 + i}`}));
    expect(await codeOf(admin.call("createUsers", {users: many}))).toBe("invalid-argument");
  });
});

describe("pengelolaan akun", () => {
  let teacherUid: string;
  let studentUid: string;
  let otherClassStudentUid: string;

  beforeAll(async () => {
    teacherUid = await addAccount(SCHOOL, {
      role: "guru",
      name: "Pak Budi",
      username: "budi",
      classIds: ["k1"],
    });
    studentUid = await addAccount(SCHOOL, {
      role: "siswa",
      name: "Siswa Kelas Satu",
      username: "4001",
      classId: "k1",
      className: "XII IPA 1",
    });
    otherClassStudentUid = await addAccount(SCHOOL, {
      role: "siswa",
      name: "Siswa Kelas Dua",
      username: "4002",
      classId: "k2",
      className: "XII IPA 2",
    });
  });

  it("guru mereset password siswa kelasnya saja", async () => {
    const teacher = await signIn(SCHOOL, "budi");
    const reset = await teacher.call<{username: string; password: string}>("resetPassword", {
      uid: studentUid,
    });
    expect(reset.username).toBe("4001");
    expect((await usersCol(SCHOOL).doc(studentUid).get()).get("mustChangePassword")).toBe(true);

    // The old password is gone, the temporary one works.
    await expect(signIn(SCHOOL, "4001", PASSWORD)).rejects.toThrow();
    await expect(signIn(SCHOOL, "4001", reset.password)).resolves.toBeTruthy();

    expect(await codeOf(teacher.call("resetPassword", {uid: otherClassStudentUid}))).toBe("not-found");
    expect(await codeOf(teacher.call("resetPassword", {uid: admin.uid}))).toBe("not-found");
  });

  it("admin mereset siapa pun kecuali dirinya; siswa tidak boleh", async () => {
    const reset = await admin.call<{password: string}>("resetPassword", {uid: teacherUid});
    await expect(signIn(SCHOOL, "budi", reset.password)).resolves.toBeTruthy();
    expect(await codeOf(admin.call("resetPassword", {uid: admin.uid}))).toBe("failed-precondition");

    const student = await signIn(SCHOOL, "4002");
    expect(await codeOf(student.call("resetPassword", {uid: studentUid}))).toBe("permission-denied");
  });

  it("akun nonaktif tidak bisa login dan bisa diaktifkan lagi", async () => {
    await admin.call("setUserActive", {uid: otherClassStudentUid, active: false});
    expect((await usersCol(SCHOOL).doc(otherClassStudentUid).get()).get("status")).toBe("disabled");
    await expect(signIn(SCHOOL, "4002")).rejects.toThrow();

    await admin.call("setUserActive", {uid: otherClassStudentUid, active: true});
    await expect(signIn(SCHOOL, "4002")).resolves.toBeTruthy();
    expect(await codeOf(admin.call("setUserActive", {uid: admin.uid, active: false}))).toBe(
      "failed-precondition",
    );
  });

  it("penugasan kelas guru dicerminkan ke kelas dan claim", async () => {
    await admin.call("setTeacherClasses", {uid: teacherUid, classIds: ["k2"]});

    expect((await usersCol(SCHOOL).doc(teacherUid).get()).get("classIds")).toEqual(["k2"]);
    expect((await classesCol(SCHOOL).doc("k1").get()).get("teacherIds")).not.toContain(teacherUid);
    expect((await classesCol(SCHOOL).doc("k2").get()).get("teacherIds")).toContain(teacherUid);
    expect((await auth.getUser(teacherUid)).customClaims).toMatchObject({classIds: ["k2"]});

    expect(await codeOf(admin.call("setTeacherClasses", {uid: teacherUid, classIds: ["x"]}))).toBe(
      "not-found",
    );
    expect(await codeOf(admin.call("setTeacherClasses", {uid: studentUid, classIds: ["k1"]}))).toBe(
      "failed-precondition",
    );
  });

  it("pindah kelas mengubah profil siswa; kelas arsip ditolak", async () => {
    await admin.call("moveStudentClass", {uid: studentUid, classId: "k2"});
    expect((await usersCol(SCHOOL).doc(studentUid).get()).get("classId")).toBe("k2");

    expect(await codeOf(admin.call("moveStudentClass", {uid: studentUid, classId: "lama"}))).toBe(
      "failed-precondition",
    );
    expect(await codeOf(admin.call("moveStudentClass", {uid: teacherUid, classId: "k1"}))).toBe(
      "failed-precondition",
    );
  });

  it("admin sekolah lain tidak bisa menyentuh akun sekolah ini", async () => {
    const other = await signIn("sman2", "admin");
    expect(await codeOf(other.call("resetPassword", {uid: studentUid}))).toBe("not-found");
    expect(await codeOf(other.call("setUserActive", {uid: studentUid, active: false}))).toBe(
      "not-found",
    );
  });
});

describe("eraseStudent", () => {
  it("menghapus akun, profil, ringkasan, program, jurnal, dan komentar", async () => {
    const uid = await addAccount(SCHOOL, {
      role: "siswa",
      name: "Siswa Lulus",
      username: "5001",
      classId: "k1",
      className: "XII IPA 1",
    });
    const program = programsCol(SCHOOL).doc("p-lulus");
    await program.set({studentId: uid, classId: "k1", status: "completed"});
    const journal = program.collection("journals").doc("2026-09-01");
    await journal.set({studentId: uid, date: "2026-09-01"});
    await journal.collection("comments").doc("c1").set({text: "Bagus"});
    await activeProgramsCol(SCHOOL).doc(uid).set({programId: "p-lulus"});
    await usersCol(SCHOOL).doc(uid).collection("devices").doc("d1").set({token: "t"});

    const result = await admin.call<{programs: number}>("eraseStudent", {uid});
    expect(result.programs).toBe(1);

    await expect(auth.getUser(uid)).rejects.toMatchObject({code: "auth/user-not-found"});
    for (const ref of [
      usersCol(SCHOOL).doc(uid),
      usersCol(SCHOOL).doc(uid).collection("devices").doc("d1"),
      statsCol(SCHOOL).doc(uid),
      activeProgramsCol(SCHOOL).doc(uid),
      program,
      journal,
      journal.collection("comments").doc("c1"),
    ]) {
      expect((await ref.get()).exists, ref.path).toBe(false);
    }
  });

  it("hanya admin, dan hanya untuk siswa", async () => {
    const teacherUid = await addAccount(SCHOOL, {
      role: "guru",
      name: "Guru Tetap",
      username: "tetap",
      classIds: ["k1"],
    });
    expect(await codeOf(admin.call("eraseStudent", {uid: teacherUid}))).toBe("failed-precondition");
    const teacher = await signIn(SCHOOL, "tetap");
    expect(await codeOf(teacher.call("eraseStudent", {uid: teacherUid}))).toBe("permission-denied");
  });
});
