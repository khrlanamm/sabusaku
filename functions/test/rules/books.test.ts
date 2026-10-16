// The shared book catalog: books, their history, the search index and the
// students' suggestions are written only by Cloud Functions; schools keep
// their recommended books; programs may point at a catalog book.

import {assertFails, assertSucceeds, RulesTestEnvironment} from "@firebase/rules-unit-testing";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

import {actors, CLASS_1, createEnv, Db, SCHOOL, seedSchool, wibDate} from "./helpers";

let env: RulesTestEnvironment;
let a: ReturnType<typeof actors>;

const BOOK = "bk_laskar";
const STORAGE_URL =
  "https://firebasestorage.googleapis.com/v0/b/sabusaku.firebasestorage.app/o/x.jpg?alt=media";

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
    await setDoc(doc(db, `books/${BOOK}`), {
      title: "Laskar Pelangi",
      authors: ["Andrea Hirata"],
      pageCount: 529,
      categories: ["Novel"],
      status: "active",
      readerCount: 0,
    });
    await setDoc(doc(db, `books/${BOOK}/history/h1`), {type: "created", changes: {}});
    await setDoc(doc(db, "catalog/shard-0"), {entries: {}});
    await setDoc(doc(db, "bookSuggestions/s1"), {kind: "new", status: "pending", count: 1});
    await setDoc(doc(db, `schools/${SCHOOL}/bookStats/${BOOK}`), {readers: 1, active: 1});
  });
});

describe("katalog buku", () => {
  it("anggota sekolah mana pun membaca buku, riwayat, dan indeks", async () => {
    for (const db of [a.student, a.teacher1, a.outsider, a.otherTeacher]) {
      await assertSucceeds(getDoc(doc(db, `books/${BOOK}`)));
      await assertSucceeds(getDocs(collection(db, `books/${BOOK}/history`)));
      await assertSucceeds(getDoc(doc(db, "catalog/shard-0")));
    }
    for (const db of [a.noClaims, a.badRole, a.anonymous]) {
      await assertFails(getDoc(doc(db, `books/${BOOK}`)));
      await assertFails(getDoc(doc(db, "catalog/shard-0")));
    }
  });

  it("tidak ada yang menulis katalog langsung, termasuk guru", async () => {
    for (const db of [a.teacher1, a.student]) {
      await assertFails(updateDoc(doc(db, `books/${BOOK}`), {pageCount: 530}));
      await assertFails(setDoc(doc(db, "books/baru"), {title: "Baru", status: "active"}));
      await assertFails(setDoc(doc(db, `books/${BOOK}/history/h2`), {type: "updated"}));
      await assertFails(setDoc(doc(db, "catalog/shard-1"), {entries: {}}));
      await assertFails(updateDoc(doc(db, "bookSuggestions/s1"), {status: "accepted"}));
      await assertFails(setDoc(doc(db, `schools/${SCHOOL}/bookStats/${BOOK}`), {readers: 9}));
    }
  });

  it("saran dibaca guru sekolah mana pun, tidak oleh siswa", async () => {
    await assertSucceeds(getDoc(doc(a.teacher1, "bookSuggestions/s1")));
    await assertSucceeds(getDoc(doc(a.otherTeacher, "bookSuggestions/s1")));
    await assertSucceeds(getDocs(collection(a.otherTeacher, "bookSuggestions")));
    await assertFails(getDoc(doc(a.student, "bookSuggestions/s1")));
    await assertFails(getDocs(collection(a.student, "bookSuggestions")));
  });

  it("statistik pembaca hanya untuk anggota sekolahnya", async () => {
    await assertSucceeds(getDoc(doc(a.student, `schools/${SCHOOL}/bookStats/${BOOK}`)));
    await assertSucceeds(getDocs(collection(a.teacher1, `schools/${SCHOOL}/bookStats`)));
    await assertFails(getDoc(doc(a.outsider, `schools/${SCHOOL}/bookStats/${BOOK}`)));
    await assertFails(getDoc(doc(a.otherTeacher, `schools/${SCHOOL}/bookStats/${BOOK}`)));
  });
});

describe("rekomendasi sekolah", () => {
  it("guru sekolah itu mengatur daftar rekomendasi", async () => {
    await assertSucceeds(
      updateDoc(doc(a.teacher1, `schools/${SCHOOL}`), {recommendedBooks: [BOOK, "bk_bumi"]}),
    );
    await assertSucceeds(updateDoc(doc(a.teacher2, `schools/${SCHOOL}`), {recommendedBooks: []}));
  });

  it("daftar tidak valid, siswa, dan guru sekolah lain ditolak", async () => {
    const school = (db: Db) => doc(db, `schools/${SCHOOL}`);
    await assertFails(updateDoc(school(a.teacher1), {recommendedBooks: [BOOK, BOOK]}));
    await assertFails(updateDoc(school(a.teacher1), {recommendedBooks: ["bukan id/valid"]}));
    await assertFails(
      updateDoc(school(a.teacher1), {
        recommendedBooks: Array.from({length: 201}, (_, i) => `bk_${i}`),
      }),
    );
    await assertFails(updateDoc(school(a.teacher1), {recommendedBooks: "bk_laskar"}));
    await assertFails(updateDoc(school(a.student), {recommendedBooks: [BOOK]}));
    await assertFails(updateDoc(school(a.otherTeacher), {recommendedBooks: [BOOK]}));
  });
});

describe("program dari katalog", () => {
  const school = `schools/${SCHOOL}`;

  function start(book: Record<string, unknown>, db: Db = a.student) {
    const startDate = wibDate();
    const batch = writeBatch(db);
    batch.set(doc(db, `${school}/programs/p1`), {
      studentId: "siswa1",
      classId: CLASS_1,
      book,
      month: startDate.slice(0, 7),
      startDate,
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
    batch.set(doc(db, `${school}/activePrograms/siswa1`), {programId: "p1"});
    return batch.commit();
  }

  const base = {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 529};

  it("buku katalog yang ada, dengan cover dari Storage, diterima", async () => {
    await assertSucceeds(start({...base, bookId: BOOK, coverUrl: STORAGE_URL}));
  });

  it("buku tanpa katalog tetap diterima, termasuk judul panjang", async () => {
    await assertSucceeds(start({...base, title: "J".repeat(150), coverUrl: null}));
  });

  it("bookId yang tidak ada, cover dari luar Storage, atau field asing ditolak", async () => {
    await assertFails(start({...base, bookId: "tidak-ada"}));
    await assertFails(start({...base, bookId: 42}));
    await assertFails(start({...base, coverUrl: "https://contoh.com/cover.jpg"}));
    await assertFails(start({...base, coverUrl: "http://firebasestorage.googleapis.com/x"}));
    await assertFails(start({...base, publisher: "Bentang"}));
  });

  it("siswa sekolah lain tidak bisa memakai jalur ini", async () => {
    await assertFails(start({...base, bookId: BOOK}, a.outsider));
  });
});

