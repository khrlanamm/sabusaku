// Reviews the students' "new book" suggestions as the developer, with the
// same effect as a teacher's review in the app (reviewSuggestion): the book
// joins the catalog, or is linked to the catalog book it really is, and the
// students' programs point at it.
//
//   npx tsx tools/books/suggestions.ts [--apply] [--emulator]
//
// Without --apply it lists the pending suggestions, what SUGGESTION_DECISIONS
// in review.ts does with each, and writes the chosen covers to
// out/suggestions/ for a look. Against PRODUCTION unless --emulator.
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
  copyCoverToCatalog,
  CoverChange,
  downloadUrlOf,
  linkSuggestionPrograms,
  saveBook,
  SuggestionSource,
} from "../../src/infra/books";
import {upsertCatalogEntry} from "../../src/infra/catalog";
import {booksCol, bookSuggestionsCol, db} from "../../src/infra/firebase";
import {OUT, ensureDir, getBinary, hasFlag, sha1} from "./common";
import {SUGGESTION_DECISIONS} from "./review";

const ACTOR = {name: "Kurasi pengembang", kind: "import"} as const;
const PREVIEWS = resolve(OUT, "suggestions");

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

async function main() {
  const apply = hasFlag("apply");
  ensureDir(PREVIEWS);
  const pending = await bookSuggestionsCol().where("status", "==", "pending").get();
  console.log(`${pending.size} saran menunggu${apply ? "" : " (tanpa --apply: hanya tinjau)"}`);

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

    /** As in reviewSuggestion: re-read inside the transaction, then close. */
    const stillPending = async (transaction: Transaction) => {
      const fresh = await transaction.get(suggestion.ref);
      if (fresh.get("status") !== "pending") throw new Error("saran sudah ditinjau");
    };
    const accept = (transaction: Transaction, bookId: string) => {
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
        console.log(`- ${label}: tautkan ke "${book.get("title")}" (${book.id})`);
        if (!apply) continue;
        await db.runTransaction(async (transaction) => {
          await stillPending(transaction);
          accept(transaction, book.id);
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

      const fields = bookFieldsSchema.parse(decision.book);
      const bookId = `bk_${sha1(fields.isbn13 ?? bookKey(fields.title, fields.authors[0])).slice(0, 16)}`;
      console.log(`- ${label}: tambah "${fields.title}" (${bookId}), ${fields.categories.join(", ")}`);
      if ((await booksCol().doc(bookId).get()).exists) throw new Error(`ID ${bookId} sudah dipakai buku lain`);
      const jpeg =
        decision.cover === "suggestion"
          ? await sharp((await getStorage().bucket().file(proposed.coverPath as string).download())[0]).jpeg().toBuffer()
          : await coverJpeg(decision.cover);
      writeFileSync(resolve(PREVIEWS, `${bookId}.jpg`), jpeg);
      if (!apply) continue;

      const cover: CoverChange =
        decision.cover === "suggestion"
          ? {
              url: await copyCoverToCatalog(proposed.coverPath as string, bookId),
              source: {provider: "suggestion", url: null, sourceId: suggestion.id},
            }
          : await uploadCover(bookId, decision.cover, jpeg);
      await saveBook({
        newId: bookId,
        fields,
        cover,
        actor: ACTOR,
        historyType: "created",
        suggestionId: suggestion.id,
        check: stillPending,
        also: (transaction) => {
          accept(transaction, bookId);
          if (fields.description) transaction.update(booksCol().doc(bookId), {descriptionSource: "review"});
        },
      });
      const linked = await linkSuggestionPrograms(sources, bookId, cover.url);
      // Writes by an import actor skip onBookWritten's index update.
      await upsertCatalogEntry(bookId, (await booksCol().doc(bookId).get()).data()!);
      console.log(`    ditambahkan, ${linked} program ditautkan`);
    } catch (error) {
      failed++;
      console.error(`    GAGAL: ${(error as Error).message}`);
    }
  }
  if (failed) process.exitCode = 1;
}

main().then(
  () => process.exit(),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
