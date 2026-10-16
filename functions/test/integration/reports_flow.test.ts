// Terms of use and reports (Google Play's User Generated Content policy):
// acceptTerms, reportContent and resolveReport through the real callables,
// and what deleting an account or erasing a student does to reports.

import {Timestamp} from "firebase-admin/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {CURRENT_TERMS_VERSION} from "../../src/domain/terms";
import {
  auditCol,
  booksCol,
  bookSuggestionsCol,
  programsCol,
  reportsCol,
  usersCol,
} from "../../src/infra/firebase";
import {
  addJoined,
  addPasswordAccount,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  eventually,
  signIn,
  wibDate,
} from "./helpers";

const A = "sman1";
const B = "sman2";
const DATE = wibDate(-1);
const KEY_INFORMATION = "Ikal dan teman-temannya belajar di sekolah yang hampir roboh. ".repeat(8);

let teacherA: Client;
let teacherA2: Client;
let teacherB: Client;
let student: Client;
let classmate: Client;

const report = async (id: string) => (await reportsCol().doc(id).get()).data();

/** A program with one journal, as the app and onJournalWritten leave it. */
async function addProgram(schoolId: string, programId: string, studentId: string) {
  const program = programsCol(schoolId).doc(programId);
  await program.set({
    studentId,
    classId: "XII-A1",
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
  await program.collection("journals").doc(DATE).set({
    studentId,
    date: DATE,
    pageStart: 1,
    pageEnd: 30,
    durationRange: "15to30",
    keyInformation: KEY_INFORMATION,
    hasUnreadTeacherComment: false,
  });
  // Let onJournalWritten settle so it does not race the deletes later on.
  await eventually(async () => (await program.get()).get("currentPage") === 30);
  return program;
}

async function addComment(schoolId: string, programId: string, commentId: string, author: Client, name: string) {
  await programsCol(schoolId)
    .doc(programId)
    .collection("journals")
    .doc(DATE)
    .collection("comments")
    .doc(commentId)
    .set({teacherId: author.uid, teacherName: name, text: "Ringkasanmu terlalu pendek, ulangi.", createdAt: Timestamp.now()});
}

beforeAll(async () => {
  await clearEmulators();
  await addSchool(A);
  await addSchool(B);
  teacherA = await addJoined(A, {email: "sari@a.test", role: "guru", name: "Bu Sari"});
  teacherA2 = await addJoined(A, {email: "joko@a.test", role: "guru", name: "Pak Joko"});
  teacherB = await addJoined(B, {email: "budi@b.test", role: "guru", name: "Pak Budi"});
  student = await addJoined(A, {email: "raka@a.test", role: "siswa", name: "Raka Pratama", classId: "XII-A1"});
  classmate = await addJoined(A, {email: "dewi@a.test", role: "siswa", name: "Dewi", classId: "XII-A1"});

  await addProgram(A, "buku1", student.uid);
  await addComment(A, "buku1", "c1", teacherA, "Bu Sari");

  await booksCol().doc("bk-laskar").set({
    title: "Laskar Pelangi",
    authors: ["Andrea Hirata"],
    pageCount: 529,
    categories: ["Novel"],
    coverUrl: null,
    status: "active",
  });
  await bookSuggestionsCol().doc("sg-new").set({
    kind: "new",
    bookId: null,
    proposed: {title: "Buku Baru", authors: ["Penulis Baru"], coverUrl: "https://example.test/c.jpg"},
    status: "pending",
  });
  await bookSuggestionsCol().doc("sg-edit").set({
    kind: "edit",
    bookId: "bk-laskar",
    proposed: {pageCount: 530},
    status: "pending",
  });
});

afterAll(closeClients);

describe("acceptTerms", () => {
  it("versi yang bukan versi sekarang ditolak", async () => {
    expect(await codeOf(student.call("acceptTerms", {version: CURRENT_TERMS_VERSION - 1}))).toBe(
      "invalid-argument",
    );
    expect(await codeOf(student.call("acceptTerms", {version: CURRENT_TERMS_VERSION + 1}))).toBe(
      "invalid-argument",
    );
    expect(await codeOf(student.call("acceptTerms", {version: "1"}))).toBe("invalid-argument");
    expect((await usersCol(A).doc(student.uid).get()).get("termsVersion")).toBeUndefined();
  });

  it("mencatat versi dan waktu; memanggil lagi tidak mengubah apa pun", async () => {
    expect(await student.call("acceptTerms", {version: CURRENT_TERMS_VERSION})).toEqual({
      version: CURRENT_TERMS_VERSION,
    });
    const first = await usersCol(A).doc(student.uid).get();
    expect(first.get("termsVersion")).toBe(CURRENT_TERMS_VERSION);
    expect(first.get("termsAcceptedAt")).toBeInstanceOf(Timestamp);

    await student.call("acceptTerms", {version: CURRENT_TERMS_VERSION});
    const second = await usersCol(A).doc(student.uid).get();
    expect(second.get("termsAcceptedAt")).toEqual(first.get("termsAcceptedAt"));
    expect(second.updateTime).toEqual(first.updateTime);
  });

  it("guru juga menyetujui; pengguna tanpa sekolah ditolak", async () => {
    await teacherA.call("acceptTerms", {version: CURRENT_TERMS_VERSION});
    expect((await usersCol(A).doc(teacherA.uid).get()).get("termsVersion")).toBe(CURRENT_TERMS_VERSION);

    await addPasswordAccount("tanpa.sekolah@a.test");
    const outsider = await signIn("tanpa.sekolah@a.test");
    expect(await codeOf(outsider.call("acceptTerms", {version: CURRENT_TERMS_VERSION}))).toBe(
      "permission-denied",
    );
  });
});

describe("reportContent", () => {
  const comment = {kind: "comment", programId: "buku1", date: DATE, commentId: "c1"};

  it("siswa melaporkan komentar di jurnalnya: salinan, sekolah, dan subjek tercatat", async () => {
    const {id} = await student.call<{id: string}>("reportContent", {
      ...comment,
      reason: "harassment",
      note: "  Kata-katanya kasar.  ",
    });
    expect(await report(id)).toMatchObject({
      kind: "comment",
      reason: "harassment",
      note: "Kata-katanya kasar.",
      status: "open",
      reporterId: student.uid,
      reporterRole: "siswa",
      reporterName: "Raka Pratama",
      schoolId: A,
      targetSchoolId: A,
      schools: [], // about a teacher: the developer only
      subjectId: teacherA.uid,
      target: {programId: "buku1", date: DATE, commentId: "c1"},
      snapshot: {text: "Ringkasanmu terlalu pendek, ulangi.", authorName: "Bu Sari"},
      targetDeleted: false,
    });
    const stored = await reportsCol().doc(id).get();
    expect(stored.get("createdAt")).toBeInstanceOf(Timestamp);
    expect(stored.get("resolvedBy")).toBeUndefined();

    const logged = await auditCol(A).where("action", "==", "reportContent").get();
    expect(logged.docs.map((entry) => entry.get("details"))).toContainEqual({kind: "comment", reportId: id});
  });

  it("komentar: guru sekolah itu boleh; siswa lain, sekolah lain, dan penulisnya tidak", async () => {
    const {id} = await teacherA2.call<{id: string}>("reportContent", {...comment, reason: "other"});
    expect(await report(id)).toMatchObject({reporterRole: "guru", reporterName: "Pak Joko", note: null});

    expect(await codeOf(classmate.call("reportContent", {...comment, reason: "other"}))).toBe(
      "permission-denied",
    );
    expect(await codeOf(teacherB.call("reportContent", {...comment, reason: "other"}))).toBe("not-found");
    expect(await codeOf(teacherA.call("reportContent", {...comment, reason: "other"}))).toBe(
      "invalid-argument",
    );
    expect(
      await codeOf(student.call("reportContent", {...comment, commentId: "tidak-ada", reason: "other"})),
    ).toBe("not-found");
    expect(
      await codeOf(student.call("reportContent", {kind: "comment", programId: "buku1", reason: "other"})),
    ).toBe("invalid-argument");
  });

  it("jurnal: hanya guru sekolah itu; subjeknya siswa, kutipan 300 karakter", async () => {
    const journal = {kind: "journal", programId: "buku1", date: DATE, reason: "inappropriate"};
    expect(await codeOf(student.call("reportContent", journal))).toBe("permission-denied");
    expect(await codeOf(teacherB.call("reportContent", journal))).toBe("not-found");
    expect(await codeOf(teacherA.call("reportContent", {...journal, date: wibDate(-3)}))).toBe("not-found");

    const {id} = await teacherA.call<{id: string}>("reportContent", journal);
    expect(await report(id)).toMatchObject({
      schools: [A],
      targetSchoolId: A,
      subjectId: student.uid,
      target: {programId: "buku1", date: DATE},
      snapshot: {studentName: "Raka Pratama", date: DATE, keyInformation: KEY_INFORMATION.slice(0, 300)},
    });
    expect(((await report(id))!.snapshot.keyInformation as string).length).toBe(300);
  });

  it("buku: siapa pun; tanpa sekolah sasaran dan tanpa subjek", async () => {
    const {id} = await student.call<{id: string}>("reportContent", {
      kind: "book",
      bookId: "bk-laskar",
      reason: "wrong_data",
    });
    expect(await report(id)).toMatchObject({
      schoolId: A,
      targetSchoolId: null,
      schools: [A],
      subjectId: null,
      target: {bookId: "bk-laskar"},
      snapshot: {title: "Laskar Pelangi", authors: ["Andrea Hirata"], coverUrl: null},
    });
    const fromB = await teacherB.call<{id: string}>("reportContent", {
      kind: "book",
      bookId: "bk-laskar",
      reason: "copyright",
    });
    expect((await report(fromB.id))!.schools).toEqual([B]);
    expect(
      await codeOf(student.call("reportContent", {kind: "book", bookId: "tidak-ada", reason: "other"})),
    ).toBe("not-found");
  });

  it("saran: hanya guru; judul dari usulan atau dari bukunya", async () => {
    expect(
      await codeOf(student.call("reportContent", {kind: "suggestion", suggestionId: "sg-new", reason: "other"})),
    ).toBe("permission-denied");

    const created = await teacherB.call<{id: string}>("reportContent", {
      kind: "suggestion",
      suggestionId: "sg-new",
      reason: "inappropriate",
    });
    expect(await report(created.id)).toMatchObject({
      schools: [B],
      targetSchoolId: null,
      subjectId: null,
      target: {suggestionId: "sg-new"},
      snapshot: {title: "Buku Baru", coverUrl: "https://example.test/c.jpg"},
    });
    const edited = await teacherA.call<{id: string}>("reportContent", {
      kind: "suggestion",
      suggestionId: "sg-edit",
      reason: "wrong_data",
    });
    expect((await report(edited.id))!.snapshot).toEqual({title: "Laskar Pelangi", coverUrl: null});
    expect(
      await codeOf(teacherA.call("reportContent", {kind: "suggestion", suggestionId: "x", reason: "other"})),
    ).toBe("not-found");
  });

  it("pengguna: di sekolah sendiri, bukan diri sendiri", async () => {
    const {id} = await student.call<{id: string}>("reportContent", {
      kind: "user",
      userId: teacherA.uid,
      reason: "harassment",
    });
    expect(await report(id)).toMatchObject({
      schools: [], // about a teacher: the developer only
      targetSchoolId: A,
      subjectId: teacherA.uid,
      target: {userId: teacherA.uid},
      snapshot: {name: "Bu Sari", role: "guru"},
    });
    expect(
      await codeOf(student.call("reportContent", {kind: "user", userId: student.uid, reason: "other"})),
    ).toBe("invalid-argument");
    expect(
      await codeOf(student.call("reportContent", {kind: "user", userId: teacherB.uid, reason: "other"})),
    ).toBe("not-found");
  });

  it("data yang tidak valid ditolak", async () => {
    const user = {kind: "user", userId: teacherA.uid};
    expect(await codeOf(student.call("reportContent", {...user, reason: "bosan"}))).toBe("invalid-argument");
    expect(await codeOf(student.call("reportContent", {...user, reason: "other", note: "x".repeat(501)}))).toBe(
      "invalid-argument",
    );
    expect(await codeOf(student.call("reportContent", {kind: "artikel", reason: "other"}))).toBe(
      "invalid-argument",
    );
    expect(await codeOf(student.call("reportContent", {kind: "user", userId: "a/b", reason: "other"}))).toBe(
      "invalid-argument",
    );
  });

  it("paling banyak 20 laporan per orang dalam 24 jam", async () => {
    const reporter = await addJoined(A, {email: "rajin@a.test", role: "siswa", name: "Rajin", classId: "XII-A1"});
    const seed = (createdAt: Timestamp) =>
      reportsCol().add({reporterId: reporter.uid, kind: "book", status: "open", schools: [A], createdAt});
    // Older reports do not count.
    for (let i = 0; i < 5; i++) await seed(Timestamp.fromMillis(Date.now() - 25 * 3600_000));
    for (let i = 0; i < 19; i++) await seed(Timestamp.now());

    const book = {kind: "book", bookId: "bk-laskar", reason: "wrong_data"};
    expect(await codeOf(reporter.call("reportContent", book))).toBe("ok"); // the 20th
    expect(await codeOf(reporter.call("reportContent", book))).toBe("resource-exhausted");
    const count = await reportsCol().where("reporterId", "==", reporter.uid).count().get();
    expect(count.data().count).toBe(25);
    // Someone else is not affected.
    expect(await codeOf(classmate.call("reportContent", book))).toBe("ok");
  });
});

describe("resolveReport", () => {
  let id: string;

  beforeAll(async () => {
    id = (
      await student.call<{id: string}>("reportContent", {kind: "user", userId: classmate.uid, reason: "other"})
    ).id;
  });

  it("siswa dan guru sekolah lain tidak bisa menyelesaikan", async () => {
    expect(await codeOf(student.call("resolveReport", {id}))).toBe("permission-denied");
    expect(await codeOf(teacherB.call("resolveReport", {id}))).toBe("permission-denied");
    expect(await codeOf(teacherA.call("resolveReport", {id: "tidak-ada"}))).toBe("not-found");
    expect((await report(id))!.status).toBe("open");
  });

  it("guru sekolah itu menyelesaikan; menyelesaikan lagi tidak mengubah apa pun", async () => {
    expect(await teacherA2.call("resolveReport", {id, resolution: " Sudah dibicarakan dengan siswa. "})).toEqual({
      ok: true,
    });
    const resolved = await reportsCol().doc(id).get();
    expect(resolved.data()).toMatchObject({
      status: "resolved",
      resolvedBy: {uid: teacherA2.uid, name: "Pak Joko"},
      resolution: "Sudah dibicarakan dengan siswa.",
    });
    expect(resolved.get("resolvedAt")).toBeInstanceOf(Timestamp);

    expect(await teacherA.call("resolveReport", {id, resolution: "Lain"})).toEqual({ok: true});
    const again = await reportsCol().doc(id).get();
    expect(again.updateTime).toEqual(resolved.updateTime);
    expect(again.get("resolvedBy")).toEqual({uid: teacherA2.uid, name: "Pak Joko"});
  });

  it("laporan buku dari sekolah lain diselesaikan sekolah itu sendiri", async () => {
    const fromB = await teacherB.call<{id: string}>("reportContent", {
      kind: "book",
      bookId: "bk-laskar",
      reason: "other",
    });
    expect(await codeOf(teacherA.call("resolveReport", {id: fromB.id}))).toBe("permission-denied");
    await teacherB.call("resolveReport", {id: fromB.id});
    expect((await report(fromB.id))!).toMatchObject({status: "resolved", resolution: null});
  });
});

describe("hapus akun dan hapus data siswa", () => {
  it("guru menghapus akunnya: laporannya hilang, laporan tentangnya tanpa salinan", async () => {
    const leaving = await addJoined(A, {email: "pergi@a.test", role: "guru", name: "Pak Pergi"});
    await addComment(A, "buku1", "c-pergi", leaving, "Pak Pergi");
    const filed = await leaving.call<{id: string}>("reportContent", {
      kind: "user",
      userId: classmate.uid,
      reason: "other",
    });
    const aboutComment = await student.call<{id: string}>("reportContent", {
      kind: "comment",
      programId: "buku1",
      date: DATE,
      commentId: "c-pergi",
      reason: "harassment",
    });
    const aboutUser = await student.call<{id: string}>("reportContent", {
      kind: "user",
      userId: leaving.uid,
      reason: "harassment",
    });
    const unrelated = await student.call<{id: string}>("reportContent", {
      kind: "user",
      userId: teacherA2.uid,
      reason: "other",
    });

    await leaving.call("deleteMyAccount");

    expect(await report(filed.id)).toBeUndefined();
    for (const id of [aboutComment.id, aboutUser.id]) {
      expect(await report(id)).toMatchObject({snapshot: {}, targetDeleted: true, subjectId: leaving.uid});
    }
    expect(await report(unrelated.id)).toMatchObject({
      snapshot: {name: "Pak Joko", role: "guru"},
      targetDeleted: false,
    });
  });

  it("hapus data siswa: laporannya hilang, laporan tentang dia dan jurnalnya tanpa salinan", async () => {
    const erased = await addJoined(A, {email: "sinta@a.test", role: "siswa", name: "Sinta", classId: "XII-A1"});
    await addProgram(A, "buku-sinta", erased.uid);
    const filed = await erased.call<{id: string}>("reportContent", {
      kind: "user",
      userId: teacherA.uid,
      reason: "other",
    });
    const aboutJournal = await teacherA.call<{id: string}>("reportContent", {
      kind: "journal",
      programId: "buku-sinta",
      date: DATE,
      reason: "personal_data",
    });
    const aboutUser = await teacherA2.call<{id: string}>("reportContent", {
      kind: "user",
      userId: erased.uid,
      reason: "other",
    });

    await teacherA.call("eraseStudent", {email: "sinta@a.test"});

    expect(await report(filed.id)).toBeUndefined();
    for (const id of [aboutJournal.id, aboutUser.id]) {
      expect(await report(id)).toMatchObject({snapshot: {}, targetDeleted: true, status: "open"});
    }
  });

  it("siswa menghapus akunnya: laporannya ikut hilang", async () => {
    const leaving = await addJoined(A, {email: "tono@a.test", role: "siswa", name: "Tono", classId: "XII-A1"});
    const filed = await leaving.call<{id: string}>("reportContent", {
      kind: "book",
      bookId: "bk-laskar",
      reason: "other",
    });
    const about = await teacherA.call<{id: string}>("reportContent", {
      kind: "user",
      userId: leaving.uid,
      reason: "other",
    });
    await leaving.call("deleteMyAccount");
    expect(await report(filed.id)).toBeUndefined();
    expect(await report(about.id)).toMatchObject({snapshot: {}, targetDeleted: true});
  });
});
