// Step 6 of the book import: writes the reviewed catalog to Firestore and the
// covers to Storage, then rebuilds the search index.
//
//   npx tsx tools/books/import.ts [--emulator] [--dry-run] [--limit N] [--update | --fill-missing]
//
// Reads out/books.json and out/covers/ (run fetch, normalize, enrich, covers
// and report first, and review out/report.md and out/samples.jpg). Without
// --emulator it writes to PRODUCTION.
//
// Idempotent: a book whose ID already exists is skipped unless --update. IDs
// come from the ISBN-13 or the title + first author, so a rerun after adding
// seeds only adds the new books. Each new book gets a "created" history entry
// by "Impor awal". The per-book catalog trigger ignores import writes; the
// index is rebuilt once at the end.
//
// --fill-missing (for a later enrich run): only books that already exist, and
// only those no teacher has edited (updatedBy.kind is still "import"). Sets
// the fields that are empty there and known here, with one history entry
// "updated" listing them ("Pelengkapan data impor"). Covers, status and
// readerCount are never touched.

import {useEmulator} from "../_env";

import {randomUUID} from "node:crypto";
import {resolve} from "node:path";

import {FieldValue} from "firebase-admin/firestore";
import {getDownloadURL, getStorage} from "firebase-admin/storage";

import {bookFieldsSchema} from "../../src/infra/books";
import {rebuildCatalog} from "../../src/infra/catalog";
import {booksCol, db} from "../../src/infra/firebase";
import {OUT, argValue, hasFlag, readJson} from "./common";
import {ImportBook} from "./normalize";

const ACTOR = {name: "Impor awal", kind: "import"} as const;

/** Fields --fill-missing may fill, in the order of the saveBook schema. */
const FILLABLE = [
  "title",
  "subtitle",
  "authors",
  "publisher",
  "publishedYear",
  "isbn13",
  "isbn10",
  "pageCount",
  "categories",
  "description",
] as const;

const isEmpty = (value: unknown) =>
  value === undefined || value === null || value === "" || (Array.isArray(value) && value.length === 0);
const BATCH_BOOKS = 200; // two writes per book, under the 500-write batch limit
const UPLOADS = 8;

async function coverUrl(bookId: string, file: string): Promise<string> {
  const bucket = getStorage().bucket();
  const path = `books/${bookId}/cover.jpg`;
  const token = randomUUID();
  await bucket.upload(resolve(OUT, file), {
    destination: path,
    metadata: {
      contentType: "image/jpeg",
      cacheControl: "public, max-age=31536000",
      metadata: {firebaseStorageDownloadTokens: token},
    },
  });
  try {
    return await getDownloadURL(bucket.file(path));
  } catch {
    const host = useEmulator
      ? `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}`
      : "https://firebasestorage.googleapis.com";
    return `${host}/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
  }
}

async function main() {
  const dryRun = hasFlag("dry-run");
  const update = hasFlag("update");
  const fillMissing = hasFlag("fill-missing");
  if (update && fillMissing) throw new Error("Pilih salah satu: --update atau --fill-missing.");
  const limit = Number(argValue("limit") ?? Infinity);
  const all = readJson<ImportBook[]>(resolve(OUT, "books.json"), []);
  const books = all.slice(0, Number.isFinite(limit) ? limit : all.length);
  const target = useEmulator ? "EMULATOR" : "PRODUKSI";
  console.log(`${books.length} buku → ${target}${dryRun ? " (dry run)" : ""}`);

  // Validate with the same schema as the saveBook callable.
  const valid: {book: ImportBook; fields: ReturnType<typeof bookFieldsSchema.parse>}[] = [];
  for (const book of books) {
    const parsed = bookFieldsSchema.safeParse({
      title: book.title,
      subtitle: book.subtitle,
      authors: book.authors,
      publisher: book.publisher,
      publishedYear: book.publishedYear,
      isbn13: book.isbn13,
      isbn10: book.isbn10,
      pageCount: book.pageCount,
      categories: book.categories,
      description: book.description,
    });
    if (!parsed.success || !book.cover) {
      console.warn(`  lewati "${book.title}": ${parsed.success ? "tanpa cover" : parsed.error.issues[0]?.path.join(".")}`);
      continue;
    }
    valid.push({book, fields: parsed.data});
  }

  const existing = new Set<string>();
  const stored = new Map<string, FirebaseFirestore.DocumentData>();
  for (let i = 0; i < valid.length; i += 300) {
    const refs = valid.slice(i, i + 300).map(({book}) => booksCol().doc(book.id));
    const snaps = fillMissing ? await db.getAll(...refs) : await db.getAll(...refs, {fieldMask: ["status"]});
    for (const snap of snaps) {
      if (!snap.exists) continue;
      existing.add(snap.id);
      if (fillMissing) stored.set(snap.id, snap.data()!);
    }
  }
  if (fillMissing) {
    await fill(valid, stored, dryRun, target);
    return;
  }
  const todo = valid.filter(({book}) => update || !existing.has(book.id));
  console.log(`  valid ${valid.length}, sudah ada ${existing.size}, akan ditulis ${todo.length}`);
  if (dryRun) return;

  let written = 0;
  for (let start = 0; start < todo.length; start += BATCH_BOOKS) {
    const chunk = todo.slice(start, start + BATCH_BOOKS);
    const urls = new Array<string>(chunk.length);
    let next = 0;
    await Promise.all(
      Array.from({length: UPLOADS}, async () => {
        while (next < chunk.length) {
          const index = next++;
          urls[index] = await coverUrl(chunk[index].book.id, chunk[index].book.cover!.file);
        }
      }),
    );

    const batch = db.batch();
    chunk.forEach(({book, fields}, index) => {
      const ref = booksCol().doc(book.id);
      const isNew = !existing.has(book.id);
      batch.set(
        ref,
        {
          ...fields,
          language: "id",
          descriptionSource: book.description ? book.descriptionSource : null,
          coverUrl: urls[index],
          coverSource: {provider: book.cover!.provider, url: book.cover!.url, sourceId: book.cover!.sourceId},
          status: "active",
          searchKey: book.searchKey,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: ACTOR,
          ...(isNew
            ? {readerCount: 0, createdAt: FieldValue.serverTimestamp(), createdBy: ACTOR, version: 1}
            : {version: FieldValue.increment(1)}),
        },
        {merge: true},
      );
      batch.set(ref.collection("history").doc(), {
        type: isNew ? "created" : "updated",
        changes: {},
        by: ACTOR,
        at: FieldValue.serverTimestamp(),
        note: isNew ? "Impor awal katalog" : "Pembaruan impor",
      });
    });
    await batch.commit();
    written += chunk.length;
    console.log(`  ${written}/${todo.length}`);
  }

  const indexed = await rebuildCatalog();
  console.log(`Selesai: ${written} buku ditulis, indeks katalog berisi ${indexed} buku aktif (${target}).`);
}

/** --fill-missing: completes untouched imported books without overwriting anything. */
async function fill(
  valid: {book: ImportBook; fields: Record<string, unknown>}[],
  stored: Map<string, FirebaseFirestore.DocumentData>,
  dryRun: boolean,
  target: string,
): Promise<void> {
  let edited = 0;
  const work: {id: string; patch: Record<string, unknown>; changes: Record<string, {from: unknown; to: unknown}>}[] = [];
  for (const {book, fields} of valid) {
    const current = stored.get(book.id);
    if (!current) continue;
    if (current.updatedBy?.kind !== "import") {
      edited++;
      continue;
    }
    const patch: Record<string, unknown> = {};
    const changes: Record<string, {from: unknown; to: unknown}> = {};
    for (const field of FILLABLE) {
      const value = fields[field];
      if (isEmpty(current[field]) && !isEmpty(value)) {
        patch[field] = value;
        changes[field] = {from: current[field] ?? null, to: value};
      }
    }
    if (patch.description) patch.descriptionSource = book.descriptionSource;
    if (Object.keys(changes).length > 0) work.push({id: book.id, patch, changes});
  }
  const counts = work.flatMap((w) => Object.keys(w.changes)).reduce<Record<string, number>>((acc, field) => {
    acc[field] = (acc[field] ?? 0) + 1;
    return acc;
  }, {});
  console.log(`  lengkapi ${work.length} buku (${edited} dilewati karena sudah diubah PJ):`, counts);
  if (dryRun || work.length === 0) return;

  for (let start = 0; start < work.length; start += BATCH_BOOKS) {
    const batch = db.batch();
    for (const {id, patch, changes} of work.slice(start, start + BATCH_BOOKS)) {
      const ref = booksCol().doc(id);
      batch.update(ref, {
        ...patch,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: ACTOR,
        version: FieldValue.increment(1),
      });
      batch.set(ref.collection("history").doc(), {
        type: "updated",
        changes,
        by: ACTOR,
        at: FieldValue.serverTimestamp(),
        note: "Pelengkapan data impor",
      });
    }
    await batch.commit();
  }
  // Year, pages and categories are part of the search index.
  const indexed = await rebuildCatalog();
  console.log(`Selesai: ${work.length} buku dilengkapi, indeks katalog berisi ${indexed} buku aktif (${target}).`);
}

main().then(
  () => process.exit(0),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
