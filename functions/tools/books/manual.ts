// Adds books whose data was checked by hand online, which the import
// pipeline cannot find (Google Books and Open Library know few Indonesian
// editions of translated books):
//
//   - students' "new book" suggestions (SUGGESTION_DECISIONS in review.ts),
//     with the same effect as a teacher's review in the app
//     (reviewSuggestion): the book joins the catalog, or is linked to the
//     catalog book it really is, and the students' programs point at it;
//   - MANUAL_BOOKS (manual-books.ts) that are not in the catalog yet.
//
//   npx tsx tools/books/manual.ts [--apply] [--emulator]
//
// Without --apply it lists what it would do and writes the covers to
// out/manual/ for a look. Against PRODUCTION unless --emulator.
// Suggestions without a decision stay pending for the teachers.
//
// A new book gets the import's ID scheme (ISBN-13, else title + first
// author), so a later import run skips it. Every change is by
// "Kurasi pengembang".

import "../_env";

import {randomUUID} from "node:crypto";
import {writeFileSync} from "node:fs";
import {resolve} from "node:path";

import {FieldValue, Transaction} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import sharp from "sharp";

import {bookKey} from "../../src/domain/search";
import {
  addHistory,
  bookFieldsSchema,
  CoverChange,
  downloadUrlOf,
  linkSuggestionPrograms,
  saveBook,
  SuggestionSource,
} from "../../src/infra/books";
import {upsertCatalogEntry} from "../../src/infra/catalog";
import {booksCol, bookSuggestionsCol, db} from "../../src/infra/firebase";
import {OUT, ensureDir, getBinary, hasFlag, sha1} from "./common";
import {MANUAL_BOOKS} from "./manual-books";
import {ManualBook, SUGGESTION_DECISIONS} from "./review";

const ACTOR = {name: "Kurasi pengembang", kind: "import"} as const;
const PREVIEWS = resolve(OUT, "manual");
const apply = hasFlag("apply");

/** The cover at [url] as covers.ts stores them: a JPEG at most 400 px wide. */
async function coverJpeg(url: string): Promise<Buffer> {
  const buffer = await getBinary(url);
  if (!buffer) throw new Error(`cover tidak bisa diunduh: ${url}`);
  const {width = 0, height = 0} = await sharp(buffer).metadata();
  if (width < 95 || height < 140) throw new Error(`cover terlalu kecil ${width}x${height}: ${url}`);
  return sharp(buffer)
    .rotate()
    .resize({width: 400, withoutEnlargement: true})
    .flatten({background: "#ffffff"})
    .jpeg({quality: 80, mozjpeg: true})
    .toBuffer();
}

async function uploadCover(bookId: string, url: string, jpeg: Buffer): Promise<CoverChange> {
  const file = getStorage().bucket().file(`books/${bookId}/cover.jpg`);
  await file.save(jpeg, {
    metadata: {
      contentType: "image/jpeg",
      cacheControl: "public, max-age=31536000",
      metadata: {firebaseStorageDownloadTokens: randomUUID()},
    },
  });
  const provider = url.includes("books.google") ? "google" : url.includes("openlibrary.org") ? "openlibrary" : "upload";
  return {url: await downloadUrlOf(file), source: {provider, url, sourceId: null}};
}

/** The catalog has this book already. */
class AlreadyInCatalog extends Error {}

/**
 * Adds [manual] to the catalog, refused (AlreadyInCatalog) when its ID or an
 * active book with the same ISBN-13 or title + first author exists. [suggestion] closes that
 * suggestion in the same transaction. Returns the new book's ID and cover
 * URL, or null without --apply.
 */
async function addBook(
  manual: ManualBook,
  suggestion?: {id: string; check: (t: Transaction) => Promise<void>; close: (t: Transaction, bookId: string) => void},
): Promise<{bookId: string; coverUrl: string} | null> {
  const fields = bookFieldsSchema.parse(manual.book);
  const searchKey = bookKey(fields.title, fields.authors[0]);
  const bookId = `bk_${sha1(fields.isbn13 ?? searchKey).slice(0, 16)}`;
  const label = `"${fields.title}" / ${fields.authors.join(", ")}`;
  if ((await booksCol().doc(bookId).get()).exists) throw new AlreadyInCatalog(`${label}: ${bookId} sudah ada di katalog`);
  const active = booksCol().where("status", "==", "active");
  const same =
    (fields.isbn13 ? (await active.where("isbn13", "==", fields.isbn13).limit(1).get()).docs[0] : undefined) ??
    (await active.where("searchKey", "==", searchKey).limit(1).get()).docs[0];
  if (same) throw new AlreadyInCatalog(`${label}: sudah ada sebagai "${same.get("title")}" (${same.id})`);
  console.log(`  tambah ${label} (${bookId}), ${fields.categories.join(", ")}`);
  const jpeg = await coverJpeg(manual.cover);
  writeFileSync(resolve(PREVIEWS, `${bookId}.jpg`), jpeg);
  if (!apply) return null;

  const cover = await uploadCover(bookId, manual.cover, jpeg);
  await saveBook({
    newId: bookId,
    fields,
    cover,
    actor: ACTOR,
    historyType: "created",
    suggestionId: suggestion?.id,
    check: suggestion?.check,
    also: (transaction) => {
      suggestion?.close(transaction, bookId);
      if (fields.description) transaction.update(booksCol().doc(bookId), {descriptionSource: "review"});
    },
  });
  // Writes by an import actor skip onBookWritten's index update.
  await upsertCatalogEntry(bookId, (await booksCol().doc(bookId).get()).data()!);
  return {bookId, coverUrl: cover.url};
}

async function reviewSuggestions(): Promise<number> {
  const pending = await bookSuggestionsCol().where("status", "==", "pending").get();
  console.log(`${pending.size} saran menunggu`);
  let failed = 0;
  for (const suggestion of pending.docs) {
    const proposed = (suggestion.get("proposed") as Record<string, unknown> | undefined) ?? {};
    const sources = (suggestion.get("from") as SuggestionSource[] | undefined) ?? [];
    const label = `"${proposed.title}" / ${((proposed.authors as string[] | undefined) ?? []).join(", ")} ×${sources.length}`;
    const decision = SUGGESTION_DECISIONS[suggestion.id];
    if (!decision) {
      console.log(`- ${label}: tetap menunggu`);
      continue;
    }
    if (suggestion.get("kind") !== "new") {
      console.log(`- ${label}: bukan saran buku baru, lewati`);
      continue;
    }
    console.log(`- ${label}:`);

    /** As in reviewSuggestion: re-read inside the transaction, then close. */
    const check = async (transaction: Transaction) => {
      const fresh = await transaction.get(suggestion.ref);
      if (fresh.get("status") !== "pending") throw new Error("saran sudah ditinjau");
    };
    const close = (transaction: Transaction, bookId: string) => {
      const now = FieldValue.serverTimestamp();
      transaction.update(suggestion.ref, {
        status: "accepted",
        reviewedBy: ACTOR,
        reviewedAt: now,
        resultBookId: bookId,
        updatedAt: now,
      });
    };

    try {
      if (decision.action === "link") {
        const book = await booksCol().doc(decision.bookId).get();
        if (!book.exists || book.get("status") !== "active") throw new Error(`buku ${decision.bookId} tidak aktif`);
        console.log(`  tautkan ke "${book.get("title")}" (${book.id})`);
        if (!apply) continue;
        await db.runTransaction(async (transaction) => {
          await check(transaction);
          close(transaction, book.id);
          addHistory(transaction, book.id, {
            type: "suggestion_applied",
            by: ACTOR,
            suggestionId: suggestion.id,
            note: "Saran buku baru ditautkan ke buku ini.",
          });
        });
        const linked = await linkSuggestionPrograms(sources, book.id, (book.get("coverUrl") as string | null) ?? null);
        console.log(`    ${linked} program ditautkan`);
        continue;
      }
      const added = await addBook(decision, {id: suggestion.id, check, close});
      if (!added) continue;
      const linked = await linkSuggestionPrograms(sources, added.bookId, added.coverUrl);
      console.log(`    ditambahkan, ${linked} program ditautkan`);
    } catch (error) {
      failed++;
      console.error(`    GAGAL: ${(error as Error).message}`);
    }
  }
  return failed;
}

async function addManualBooks(): Promise<number> {
  console.log(`${MANUAL_BOOKS.length} buku manual`);
  let failed = 0;
  let added = 0;
  for (const manual of MANUAL_BOOKS) {
    try {
      if (await addBook(manual)) added++;
    } catch (error) {
      if (error instanceof AlreadyInCatalog) {
        console.log(`  lewati ${error.message}`);
        continue;
      }
      failed++;
      console.error(`    GAGAL: ${(error as Error).message}`);
    }
  }
  if (apply) console.log(`${added} buku manual ditambahkan`);
  return failed;
}

async function main() {
  ensureDir(PREVIEWS);
  if (!apply) console.log("Tanpa --apply: hanya tinjau.");
  const failed = (await reviewSuggestions()) + (await addManualBooks());
  if (failed) {
    console.error(`${failed} gagal atau dilewati.`);
    process.exitCode = 1;
  }
}

main().then(
  () => process.exit(),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
