// The shared book catalog through the real callables, triggers and rules:
// teachers of two schools edit, delete and restore books; students' programs
// count as readers and turn into suggestions that teachers review.

import {getStorage} from "firebase-admin/storage";
import {collection, doc, getDocs, query, serverTimestamp, where, writeBatch} from "firebase/firestore";
import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {shardOf} from "../../src/domain/search";
import {downloadUrlOf} from "../../src/infra/books";
import {catalogShardRef, rebuildCatalog} from "../../src/infra/catalog";
import {booksCol, bookStatsCol, bookSuggestionsCol, programsCol, statsCol} from "../../src/infra/firebase";
import {
  addJoined,
  addSchool,
  clearEmulators,
  Client,
  closeClients,
  codeOf,
  eventually,
  wibDate,
} from "./helpers";

const A = "sman1";
const B = "sman2";

let teacherA: Client;
let teacherB: Client;
let student: Client;
let classmate: Client;

const laskar = {
  title: "Laskar Pelangi",
  authors: ["Andrea Hirata"],
  publisher: "Bentang Pustaka",
  publishedYear: 2005,
  isbn13: "9789793062792",
  pageCount: 529,
  categories: ["Novel"],
  description: "Kisah sepuluh anak Belitung.",
};

const book = async (id: string) => (await booksCol().doc(id).get()).data();
const history = async (id: string) =>
  (await booksCol().doc(id).collection("history").orderBy("at").get()).docs.map((d) => d.data());
const indexEntry = async (id: string) =>
  (await catalogShardRef(shardOf(id)).get()).get(`entries.${id}`) as Record<string, unknown> | undefined;
const pendingSuggestions = async (key: string) =>
  (
    await bookSuggestionsCol().where("dedupeKey", "==", key).where("status", "==", "pending").get()
  ).docs;

/** Starts a book the way the app does: program + BR-1 lock in one batch. */
async function startBook(client: Client, schoolId: string, programId: string, programBook: Record<string, unknown>) {
  const today = wibDate();
  const batch = writeBatch(client.db);
  batch.set(doc(client.db, `schools/${schoolId}/programs/${programId}`), {
    studentId: client.uid,
    classId: "XII-A1",
    book: programBook,
    month: today.slice(0, 7),
    startDate: today,
    targetDate: wibDate(20),
    extended: false,
    status: "active",
    currentPage: 0,
    journalCount: 0,
    lastJournalDate: null,
    streakCurrent: 0,
    streakBest: 0,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(client.db, `schools/${schoolId}/activePrograms/${client.uid}`), {programId});
  await batch.commit();
}

beforeAll(async () => {
  await clearEmulators();
  await addSchool(A);
  await addSchool(B);
  teacherA = await addJoined(A, {email: "sari@a.test", role: "guru", name: "Bu Sari"});
  teacherB = await addJoined(B, {email: "budi@b.test", role: "guru", name: "Pak Budi"});
  student = await addJoined(A, {email: "raka@a.test", role: "siswa", name: "Raka", classId: "XII-A1"});
  classmate = await addJoined(A, {email: "dewi@a.test", role: "siswa", name: "Dewi", classId: "XII-A1"});
});

afterAll(closeClients);

let laskarId: string;

describe("mengelola katalog", () => {
  it("guru menambah buku; riwayat mencatat nama dan sekolahnya; indeks ikut", async () => {
    ({bookId: laskarId} = await teacherA.call<{bookId: string}>("saveBook", {fields: laskar}));
    expect(await book(laskarId)).toMatchObject({
      ...laskar,
      status: "active",
      readerCount: 0,
      version: 1,
      searchKey: "laskar pelangi|andrea hirata",
      createdBy: {name: "Bu Sari", schoolId: A, schoolName: `Sekolah ${A}`, kind: "guru"},
    });
    const [created] = await history(laskarId);
    expect(created).toMatchObject({type: "created", by: {name: "Bu Sari", schoolId: A}});
    expect(created.changes.title).toEqual({from: null, to: "Laskar Pelangi"});
    const entry = await eventually(() => indexEntry(laskarId));
    expect(entry).toMatchObject({t: "Laskar Pelangi", a: "Andrea Hirata", p: 529, y: 2005, g: ["Novel"]});
  });

  it("siswa tidak bisa mengelola katalog", async () => {
    expect(await codeOf(student.call("saveBook", {fields: laskar}))).toBe("permission-denied");
    expect(await codeOf(student.call("deleteBook", {bookId: laskarId}))).toBe("permission-denied");
  });

  it("buku kembar (ISBN atau judul + penulis) ditolak; data tidak valid ditolak", async () => {
    expect(await codeOf(teacherB.call("saveBook", {fields: laskar}))).toBe("already-exists");
    expect(
      await codeOf(teacherB.call("saveBook", {fields: {...laskar, isbn13: null, title: "LASKAR  pelangi!"}})),
    ).toBe("already-exists");
    expect(await codeOf(teacherB.call("saveBook", {fields: {...laskar, title: "X", isbn13: null}}))).toBe(
      "invalid-argument",
    );
    expect(await codeOf(teacherB.call("saveBook", {fields: {...laskar, pageCount: 5}}))).toBe("invalid-argument");
    expect(
      await codeOf(teacherB.call("saveBook", {fields: {...laskar, title: "Lain", categories: ["Bukan"]}})),
    ).toBe("invalid-argument");
  });

  it("guru sekolah lain mengubahnya; diff tercatat; simpan tanpa perubahan tidak mencatat", async () => {
    await teacherB.call("saveBook", {bookId: laskarId, fields: {...laskar, pageCount: 534}});
    expect(await book(laskarId)).toMatchObject({pageCount: 534, version: 2, updatedBy: {schoolId: B}});
    await teacherB.call("saveBook", {bookId: laskarId, fields: {...laskar, pageCount: 534}});
    const entries = await history(laskarId);
    expect(entries.map((e) => e.type)).toEqual(["created", "updated"]);
    expect(entries[1]).toMatchObject({
      changes: {pageCount: {from: 529, to: 534}},
      by: {name: "Pak Budi", schoolId: B, schoolName: `Sekolah ${B}`},
    });
    await eventually(async () => (await indexEntry(laskarId))?.p === 534);
  });

  it("hapus sementara: keluar dari indeks, muncul di daftar terhapus, dipulihkan sekolah lain", async () => {
    await teacherA.call("deleteBook", {bookId: laskarId, reason: "Uji hapus"});
    expect(await book(laskarId)).toMatchObject({
      status: "deleted",
      deleteReason: "Uji hapus",
      deletedBy: {schoolId: A},
    });
    await eventually(async () => (await indexEntry(laskarId)) === undefined);

    const deleted = await getDocs(
      query(collection(teacherB.db, "books"), where("status", "==", "deleted")),
    );
    expect(deleted.docs.map((d) => d.id)).toContain(laskarId);
    expect(await codeOf(teacherB.call("deleteBook", {bookId: laskarId}))).toBe("failed-precondition");
    expect(await codeOf(teacherB.call("saveBook", {bookId: laskarId, fields: laskar}))).toBe(
      "failed-precondition",
    );

    await teacherB.call("restoreBook", {bookId: laskarId});
    const restored = await book(laskarId);
    expect(restored).toMatchObject({status: "active"});
    expect(restored?.deletedBy).toBeUndefined();
    await eventually(() => indexEntry(laskarId));
    const types = (await history(laskarId)).map((e) => [e.type, e.by.schoolId]);
    expect(types).toContainEqual(["deleted", A]);
    expect(types).toContainEqual(["restored", B]);
    expect(await codeOf(teacherB.call("restoreBook", {bookId: laskarId}))).toBe("failed-precondition");
  });

  it("hapus sebagai duplikat menunjuk buku yang ada", async () => {
    const {bookId} = await teacherA.call<{bookId: string}>("saveBook", {
      fields: {...laskar, title: "Laskar Pelangi (Edisi Lama)", isbn13: null},
    });
    expect(await codeOf(teacherA.call("deleteBook", {bookId, duplicateOf: "tidak-ada"}))).toBe(
      "invalid-argument",
    );
    await teacherA.call("deleteBook", {bookId, duplicateOf: laskarId});
    expect(await book(bookId)).toMatchObject({status: "deleted", duplicateOf: laskarId});
  });
});

describe("program siswa dan saran", () => {
  it("program dari katalog menambah pembaca; halaman berbeda jadi saran yang digabung", async () => {
    const programBook = {
      title: "Laskar Pelangi",
      author: "Andrea Hirata",
      totalPages: 540,
      bookId: laskarId,
      coverUrl: null,
    };
    await startBook(student, A, "p-raka", programBook);
    await startBook(classmate, A, "p-dewi", programBook);

    await eventually(async () => (await book(laskarId))?.readerCount === 2);
    await eventually(async () => (await bookStatsCol(A).doc(laskarId).get()).get("readers") === 2);
    expect((await bookStatsCol(A).doc(laskarId).get()).data()).toMatchObject({readers: 2, active: 2});
    await eventually(async () => (await indexEntry(laskarId))?.r === 2);

    const key = `${laskarId}|${JSON.stringify({pageCount: 540})}`;
    const [suggestion] = await eventually(async () => {
      const docs = await pendingSuggestions(key);
      return docs.length === 1 && docs[0].get("count") === 2 ? docs : undefined;
    });
    expect(suggestion.data()).toMatchObject({
      kind: "edit",
      bookId: laskarId,
      proposed: {pageCount: 540},
      from: [
        {schoolId: A, schoolName: `Sekolah ${A}`},
        {schoolId: A, schoolName: `Sekolah ${A}`},
      ],
    });
    expect(JSON.stringify(suggestion.data())).not.toContain("Raka");

    // Siswa tidak bisa membaca saran.
    expect(await codeOf(getDocs(collection(student.db, "bookSuggestions")))).not.toBe("ok");

    // Menghentikan buku mengurangi pembaca aktif di sekolah itu (program
    // dan kunci BR-1 dalam satu batch, seperti aplikasi).
    const batch = writeBatch(student.db);
    batch.update(doc(student.db, `schools/${A}/programs/p-raka`), {
      status: "stopped",
      stoppedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.delete(doc(student.db, `schools/${A}/activePrograms/${student.uid}`));
    await batch.commit();
    await eventually(async () => (await bookStatsCol(A).doc(laskarId).get()).get("active") === 1);
  });

  it("menerapkan saran mengubah buku dan tercatat; saran yang sudah ditinjau ditolak", async () => {
    const key = `${laskarId}|${JSON.stringify({pageCount: 540})}`;
    const [suggestion] = await pendingSuggestions(key);
    await teacherB.call("reviewSuggestion", {id: suggestion.id, action: "apply"});

    expect(await book(laskarId)).toMatchObject({pageCount: 540});
    const applied = (await history(laskarId)).find((e) => e.type === "suggestion_applied");
    expect(applied).toMatchObject({
      suggestionId: suggestion.id,
      changes: {pageCount: {from: 534, to: 540}},
      by: {schoolId: B},
    });
    expect((await bookSuggestionsCol().doc(suggestion.id).get()).data()).toMatchObject({
      status: "accepted",
      resultBookId: laskarId,
      reviewedBy: {schoolId: B},
    });
    expect(await codeOf(teacherA.call("reviewSuggestion", {id: suggestion.id, action: "reject"}))).toBe(
      "failed-precondition",
    );
  });

  it("saran buku baru: dibuat dari saran, lalu program menunjuk buku itu", async () => {
    await startBook(student, A, "p-raka-2", {
      title: "Ronggeng Dukuh Paruk",
      author: "Ahmad Tohari",
      totalPages: 408,
      isbn: "978-979-22-3480-2",
    });
    const [suggestion] = await eventually(async () => {
      const docs = await pendingSuggestions("ronggeng dukuh paruk|ahmad tohari");
      return docs.length === 1 ? docs : undefined;
    });
    expect(suggestion.data()).toMatchObject({
      kind: "new",
      bookId: null,
      proposed: {title: "Ronggeng Dukuh Paruk", authors: ["Ahmad Tohari"], pageCount: 408, isbn13: "9789792234802"},
    });

    const {bookId} = await teacherA.call<{bookId: string}>("reviewSuggestion", {
      id: suggestion.id,
      action: "create",
      book: {
        title: "Ronggeng Dukuh Paruk",
        authors: ["Ahmad Tohari"],
        pageCount: 408,
        isbn13: "9789792234802",
        categories: ["Novel", "Sastra Klasik"],
      },
    });
    expect(await book(bookId)).toMatchObject({title: "Ronggeng Dukuh Paruk", categories: ["Novel", "Sastra Klasik"]});
    expect((await history(bookId))[0]).toMatchObject({type: "created", suggestionId: suggestion.id});
    expect((await bookSuggestionsCol().doc(suggestion.id).get()).get("status")).toBe("accepted");
    expect((await programsCol(A).doc("p-raka-2").get()).get("book.bookId")).toBe(bookId);
    // The summary carries the program's cover once one is set.
    await programsCol(A).doc("p-raka-2").update({"book.coverUrl": "https://firebasestorage.googleapis.com/v0/b/x/o/c.jpg"});
    await eventually(async () =>
      (await statsCol(A).doc(student.uid).get()).get("activeProgram.coverUrl") ===
        "https://firebasestorage.googleapis.com/v0/b/x/o/c.jpg",
    );
    await eventually(async () => (await book(bookId))?.readerCount === 1);
  });

  it("menolak dan menautkan saran", async () => {
    // A new-book proposal linked to the existing catalog book.
    await bookSuggestionsCol().doc("s-link").set({
      kind: "new",
      bookId: null,
      proposed: {title: "Laskar pelangi", authors: ["A. Hirata"], pageCount: 529},
      dedupeKey: "laskar pelangi|a hirata",
      count: 1,
      from: [],
      status: "pending",
    });
    await teacherB.call("reviewSuggestion", {id: "s-link", action: "link", bookId: laskarId});
    expect((await bookSuggestionsCol().doc("s-link").get()).data()).toMatchObject({
      status: "accepted",
      resultBookId: laskarId,
    });

    await bookSuggestionsCol().doc("s-reject").set({
      kind: "edit",
      bookId: laskarId,
      proposed: {title: "Laskar Pelangi Baru"},
      dedupeKey: "x",
      count: 1,
      from: [],
      status: "pending",
    });
    await teacherA.call("reviewSuggestion", {id: "s-reject", action: "reject"});
    const rejected = (await history(laskarId)).find((e) => e.type === "suggestion_rejected");
    expect(rejected).toMatchObject({
      suggestionId: "s-reject",
      changes: {title: {from: "Laskar Pelangi", to: "Laskar Pelangi Baru"}},
    });
    expect(await codeOf(teacherA.call("reviewSuggestion", {id: "s-reject", action: "apply"}))).toBe(
      "failed-precondition",
    );
  });
});

describe("indeks", () => {
  it("rebuildCatalog menulis 4 shard berisi buku aktif saja", async () => {
    const count = await rebuildCatalog();
    const active = await booksCol().where("status", "==", "active").get();
    expect(count).toBe(active.size);
    let indexed = 0;
    for (let shard = 0; shard < 4; shard++) {
      const entries = ((await catalogShardRef(shard).get()).get("entries") ?? {}) as Record<string, unknown>;
      for (const id of Object.keys(entries)) {
        expect(shardOf(id)).toBe(shard);
        expect((await book(id))?.status).toBe("active");
      }
      indexed += Object.keys(entries).length;
    }
    expect(indexed).toBe(active.size);
  });
});

// Cover copies need the Storage emulator (CI starts it; locally:
// --only auth,firestore,functions,storage).
describe.skipIf(!process.env.FIREBASE_STORAGE_EMULATOR_HOST)("cover", () => {
  const bucket = () => getStorage().bucket(process.env.STORAGE_BUCKET ?? "demo-sabusaku.appspot.com");
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);

  it("guru memasang cover yang ia unggah; riwayat mencatatnya", async () => {
    const path = `books/${laskarId}/cover-upload.jpg`;
    await bucket().file(path).save(jpeg, {contentType: "image/jpeg"});
    const {coverUrl} = await teacherA.call<{coverUrl: string}>("setBookCover", {bookId: laskarId, path});
    expect(coverUrl).toContain(encodeURIComponent(path));
    expect(await book(laskarId)).toMatchObject({coverUrl, coverSource: {provider: "upload"}});
    expect((await history(laskarId)).some((e) => e.type === "cover_changed")).toBe(true);
    expect(
      await codeOf(teacherA.call("setBookCover", {bookId: laskarId, path: `books/lain/cover.jpg`})),
    ).toBe("invalid-argument");
  });

  it("cover dari siswa disalin ke folder katalog saat saran diterapkan", async () => {
    const studentPath = `schools/${A}/programCovers/${classmate.uid}/1700000000.jpg`;
    const file = bucket().file(studentPath);
    await file.save(jpeg, {contentType: "image/jpeg"});
    const studentUrl = await downloadUrlOf(file);

    // Written past the rules: they accept only https Storage URLs, and the
    // emulator serves http.
    const today = wibDate();
    await programsCol(A).doc("p-cover").set({
      studentId: classmate.uid,
      classId: "XII-A1",
      book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 540, bookId: laskarId, coverUrl: studentUrl},
      month: today.slice(0, 7),
      startDate: today,
      targetDate: wibDate(20),
      extended: false,
      status: "completed",
      currentPage: 0,
      journalCount: 0,
      lastJournalDate: null,
      streakCurrent: 0,
      streakBest: 0,
    });
    const [suggestion] = await eventually(async () => {
      const docs = (await bookSuggestionsCol().where("bookId", "==", laskarId).where("status", "==", "pending").get())
        .docs.filter((d) => d.get("proposed.coverPath") === studentPath);
      return docs.length === 1 ? docs : undefined;
    });
    expect(suggestion.get("proposed.coverUrl")).toBe(studentUrl);

    await teacherB.call("reviewSuggestion", {id: suggestion.id, action: "apply", fields: ["coverUrl"]});
    const updated = await book(laskarId);
    expect(updated?.coverUrl).not.toBe(studentUrl);
    expect(decodeURIComponent(String(updated?.coverUrl))).toMatch(new RegExp(`/o/books/${laskarId}/cover-\\d+\\.jpg`));
    expect(updated?.coverSource).toMatchObject({provider: "suggestion", sourceId: suggestion.id});
    const applied = (await history(laskarId)).filter((e) => e.type === "suggestion_applied").pop();
    expect(applied?.changes.coverUrl?.to).toBe(updated?.coverUrl);
    // pageCount was 540 already: only the cover changed.
    expect(Object.keys(applied?.changes ?? {})).toEqual(["coverUrl"]);
  });
});
