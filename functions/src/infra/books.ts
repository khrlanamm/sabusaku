import {randomUUID} from "node:crypto";

import {FieldValue, Timestamp, Transaction} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {HttpsError} from "firebase-functions/v2/https";
import {z} from "zod";

import {BOOK_CATEGORIES, bookKey, normalizeSearchText} from "../domain/search";
import {Caller} from "./guard";
import {booksCol, bookSuggestionsCol, db, programsCol, schoolRef, usersCol} from "./firebase";

/**
 * The shared book catalog (`books/{bookId}`). Every change goes through the
 * Cloud Functions in this file so that each one lands in the book's history
 * (`books/{bookId}/history`) with who made it and from which school.
 */

/** Who changed the catalog. Imported books have kind `import`. */
export interface Actor {
  uid?: string;
  name: string;
  schoolId?: string;
  schoolName?: string;
  kind: "import" | "guru" | "siswa";
}

// ---------------------------------------------------------------------------
// Fields
// ---------------------------------------------------------------------------

const text = (min: number, max: number) => z.string().trim().min(min).max(max);

/** Trimmed text; empty becomes null. */
const optionalText = (max: number) =>
  z.preprocess(
    (value) => (typeof value === "string" ? value.trim() || null : (value ?? null)),
    z.string().max(max).nullable(),
  );

/** Digits only (and a final X for ISBN-10); empty becomes null. */
const isbn = (pattern: RegExp) =>
  z.preprocess(
    (value) =>
      typeof value === "string" ? value.replace(/[\s-]/g, "").toUpperCase() || null : (value ?? null),
    z.string().regex(pattern).nullable(),
  );

export const bookFieldsSchema = z.object({
  title: text(2, 200),
  subtitle: optionalText(200),
  authors: z
    .array(text(2, 120))
    .min(1)
    .max(5)
    .transform((authors) => [...new Set(authors)]),
  publisher: optionalText(120),
  publishedYear: z.preprocess(
    (value) => value ?? null,
    z.number().int().min(1800).max(2100).nullable(),
  ),
  isbn13: isbn(/^\d{13}$/),
  isbn10: isbn(/^\d{9}[\dX]$/),
  pageCount: z.number().int().min(10).max(2000),
  categories: z
    .array(z.enum(BOOK_CATEGORIES))
    .min(1)
    .max(3)
    .transform((categories) => [...new Set(categories)]),
  description: optionalText(2000),
});

export type BookFields = z.infer<typeof bookFieldsSchema>;

export const BOOK_FIELDS = Object.keys(bookFieldsSchema.shape) as (keyof BookFields)[];

const FIELD_MESSAGES: Record<keyof BookFields, string> = {
  title: "Judul harus 2–200 karakter.",
  subtitle: "Subjudul maksimal 200 karakter.",
  authors: "Isi 1–5 penulis, masing-masing 2–120 karakter.",
  publisher: "Penerbit maksimal 120 karakter.",
  publishedYear: "Tahun terbit tidak valid.",
  isbn13: "ISBN-13 harus 13 angka.",
  isbn10: "ISBN-10 harus 10 karakter.",
  pageCount: "Jumlah halaman harus 10–2000.",
  categories: "Pilih 1–3 kategori.",
  description: "Sinopsis maksimal 2000 karakter.",
};

/** Validates and cleans book fields; the error names the first bad field. */
export function parseBookFields(data: unknown): BookFields {
  const result = bookFieldsSchema.safeParse(data);
  if (result.success) return result.data;
  const field = result.error.issues[0]?.path[0] as keyof BookFields | undefined;
  throw new HttpsError(
    "invalid-argument",
    (field && FIELD_MESSAGES[field]) ?? "Data buku tidak valid.",
  );
}

/** The editable fields of a stored book, for merging a partial change. */
export function storedFields(data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  return Object.fromEntries(BOOK_FIELDS.map((field) => [field, data[field] ?? null]));
}

export type Changes = Record<string, {from: unknown; to: unknown}>;

/** Fields whose value differs, as `{field: {from, to}}`. */
export function diffFields(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
  fields: readonly string[] = BOOK_FIELDS,
): Changes {
  const changes: Changes = {};
  for (const field of fields) {
    const from = before[field] ?? null;
    const to = after[field] ?? null;
    if (JSON.stringify(from) !== JSON.stringify(to)) changes[field] = {from, to};
  }
  return changes;
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

export const bookNotFound = () => new HttpsError("not-found", "Buku tidak ditemukan.");
export const bookDeleted = () =>
  new HttpsError("failed-precondition", "Buku ini sudah dihapus. Aktifkan kembali dulu.");

// ---------------------------------------------------------------------------
// Actors and history
// ---------------------------------------------------------------------------

/** The calling teacher as recorded in history: profile name and school name. */
export async function actorFor(caller: Caller): Promise<Actor> {
  const [user, school] = await Promise.all([
    usersCol(caller.schoolId).doc(caller.uid).get(),
    schoolRef(caller.schoolId).get(),
  ]);
  return {
    uid: caller.uid,
    name: (user.get("name") as string | undefined) || "Penanggung jawab",
    schoolId: caller.schoolId,
    schoolName: (school.get("name") as string | undefined) ?? caller.schoolId,
    kind: caller.role,
  };
}

export type HistoryType =
  | "created"
  | "updated"
  | "deleted"
  | "restored"
  | "cover_changed"
  | "suggestion_applied"
  | "suggestion_rejected";

export interface HistoryEntry {
  type: HistoryType;
  changes?: Changes;
  by: Actor;
  suggestionId?: string;
  note?: string;
}

/** Firestore rejects `undefined`; optional fields are left out instead. */
function withoutUndefined<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as T;
}

export function addHistory(transaction: Transaction, bookId: string, entry: HistoryEntry): void {
  transaction.set(
    booksCol().doc(bookId).collection("history").doc(),
    withoutUndefined({
      type: entry.type,
      changes: entry.changes ?? {},
      by: withoutUndefined({...entry.by}),
      at: FieldValue.serverTimestamp(),
      suggestionId: entry.suggestionId,
      note: entry.note,
    }),
  );
}

// ---------------------------------------------------------------------------
// Saving
// ---------------------------------------------------------------------------

/** A new cover for a book: a file under `books/{bookId}/`, never a student's file. */
export interface CoverChange {
  url: string;
  source: {provider: "google" | "openlibrary" | "upload" | "suggestion"; url?: string | null; sourceId?: string | null};
}

export interface SaveOptions {
  /** Absent: a new book. */
  bookId?: string;
  /** ID for a new book, when it must be known before the transaction (cover copy). */
  newId?: string;
  /** Sets the cover in the same change. */
  cover?: CoverChange;
  /** Complete fields (create, or a teacher's full edit). */
  fields?: unknown;
  /** Some fields only, merged into the stored book (applying a suggestion). */
  patch?: Record<string, unknown>;
  actor: Actor;
  historyType?: Extract<HistoryType, "created" | "updated" | "suggestion_applied">;
  suggestionId?: string;
  /** Reads checked inside the transaction before anything is written. */
  check?: (transaction: Transaction) => Promise<void>;
  /** Extra writes in the same transaction, e.g. closing a suggestion. */
  also?: (transaction: Transaction, bookId: string) => void;
}

export interface SaveResult {
  bookId: string;
  changed: boolean;
}

/**
 * Creates or updates a catalog book and records the change in its history,
 * atomically. A new book is refused when an active book with the same ISBN-13
 * or the same title and first author already exists (`already-exists`, with
 * `details.bookId`).
 */
export async function saveBook(options: SaveOptions): Promise<SaveResult> {
  return db.runTransaction(async (transaction) => {
    await options.check?.(transaction);
    const now = FieldValue.serverTimestamp();

    if (!options.bookId) {
      const fields = parseBookFields(options.fields ?? options.patch);
      const searchKey = bookKey(fields.title, fields.authors[0]);
      const active = booksCol().where("status", "==", "active");
      const sameIsbn = fields.isbn13
        ? (await transaction.get(active.where("isbn13", "==", fields.isbn13).limit(1))).docs[0]
        : undefined;
      const sameKey =
        sameIsbn ?? (await transaction.get(active.where("searchKey", "==", searchKey).limit(1))).docs[0];
      if (sameKey) {
        throw new HttpsError("already-exists", "Buku ini sudah ada di katalog.", {
          bookId: sameKey.id,
        });
      }
      const ref = options.newId ? booksCol().doc(options.newId) : booksCol().doc();
      transaction.set(ref, {
        ...fields,
        language: "id",
        coverUrl: options.cover?.url ?? null,
        coverSource: options.cover?.source ?? null,
        searchKey,
        status: "active",
        readerCount: 0,
        createdAt: now,
        createdBy: options.actor,
        updatedAt: now,
        updatedBy: options.actor,
        version: 1,
      });
      addHistory(transaction, ref.id, {
        type: options.historyType === "suggestion_applied" ? "created" : (options.historyType ?? "created"),
        changes: {
          ...diffFields({}, fields),
          ...(options.cover ? {coverUrl: {from: null, to: options.cover.url}} : {}),
        },
        by: options.actor,
        suggestionId: options.suggestionId,
      });
      options.also?.(transaction, ref.id);
      return {bookId: ref.id, changed: true};
    }

    const ref = booksCol().doc(options.bookId);
    const book = await transaction.get(ref);
    if (!book.exists) throw bookNotFound();
    if (book.get("status") === "deleted") throw bookDeleted();

    const before = storedFields(book.data()!);
    const fields = parseBookFields(options.fields ?? {...before, ...options.patch});
    const changes = diffFields(before, fields);
    const oldCover = (book.get("coverUrl") as string | null | undefined) ?? null;
    const cover = options.cover && options.cover.url !== oldCover ? options.cover : undefined;
    if (cover) changes.coverUrl = {from: oldCover, to: cover.url};
    if (Object.keys(changes).length > 0) {
      transaction.update(ref, {
        ...fields,
        ...(cover ? {coverUrl: cover.url, coverSource: cover.source} : {}),
        searchKey: bookKey(fields.title, fields.authors[0]),
        updatedAt: now,
        updatedBy: options.actor,
        version: FieldValue.increment(1),
      });
      addHistory(transaction, ref.id, {
        type: options.historyType ?? "updated",
        changes,
        by: options.actor,
        suggestionId: options.suggestionId,
      });
    }
    options.also?.(transaction, ref.id);
    return {bookId: ref.id, changed: Object.keys(changes).length > 0};
  });
}

// ---------------------------------------------------------------------------
// Suggestions from students
// ---------------------------------------------------------------------------

/** Where a suggestion came from. No student name: other schools see it. */
export interface SuggestionSource {
  schoolId: string;
  schoolName: string;
  programId: string;
}

/** Sources kept per suggestion; `count` keeps counting past it. */
export const MAX_SUGGESTION_SOURCES = 50;

/**
 * Authors as one student typed them ("A, B", "A & B", "A dan B") become a
 * list. "Dan Brown" stays one name: "dan" only separates with spaces around.
 */
export function splitAuthors(raw: string): string[] {
  return [
    ...new Set(
      raw
        .split(/\s*,\s*|\s+&\s+|\s+dan\s+/i)
        .map((author) => author.trim())
        .filter((author) => author.length >= 2),
    ),
  ].slice(0, 5);
}

/** The ISBN field of a program, cleaned and named by its length. */
export function isbnField(raw: unknown): {isbn13: string} | {isbn10: string} | Record<string, never> {
  const value = typeof raw === "string" ? raw.replace(/[^0-9Xx]/g, "").toUpperCase() : "";
  if (/^\d{13}$/.test(value)) return {isbn13: value};
  if (/^\d{9}[\dX]$/.test(value)) return {isbn10: value};
  return {};
}

/** Object with sorted keys, so equal proposals give equal dedupe keys. */
function stableJson(value: Record<string, unknown>): string {
  return JSON.stringify(Object.fromEntries(Object.entries(value).sort(([a], [b]) => a.localeCompare(b))));
}

/** What a program's book proposes compared with its catalog entry (`edit`). */
export function editProposal(
  programBook: Record<string, unknown>,
  catalog: FirebaseFirestore.DocumentData,
): Record<string, unknown> {
  const proposed: Record<string, unknown> = {};
  const title = String(programBook.title ?? "").trim();
  const authors = splitAuthors(String(programBook.author ?? ""));
  const catalogAuthors = (catalog.authors as string[] | undefined) ?? [];
  if (title && normalizeSearchText(title) !== normalizeSearchText(String(catalog.title ?? ""))) {
    proposed.title = title;
  }
  if (
    authors.length > 0 &&
    normalizeSearchText(authors.join(" ")) !== normalizeSearchText(catalogAuthors.join(" "))
  ) {
    proposed.authors = authors;
  }
  if (typeof programBook.totalPages === "number" && programBook.totalPages !== catalog.pageCount) {
    proposed.pageCount = programBook.totalPages;
  }
  const isbn = isbnField(programBook.isbn);
  if ("isbn13" in isbn && isbn.isbn13 !== catalog.isbn13) proposed.isbn13 = isbn.isbn13;
  if ("isbn10" in isbn && isbn.isbn10 !== catalog.isbn10) proposed.isbn10 = isbn.isbn10;
  return proposed;
}

/** A book that is not in the catalog, as proposed by a program (`new`). */
export function newProposal(programBook: Record<string, unknown>): Record<string, unknown> {
  return {
    title: String(programBook.title ?? "").trim(),
    authors: splitAuthors(String(programBook.author ?? "")),
    pageCount: programBook.totalPages ?? null,
    ...isbnField(programBook.isbn),
  };
}

/**
 * Records a suggestion, or adds this source to an identical pending one
 * (same `dedupeKey`), so teachers see one item with a count.
 */
export async function upsertSuggestion(
  suggestion: {kind: "edit" | "new"; bookId: string | null; proposed: Record<string, unknown>},
  source: SuggestionSource,
): Promise<void> {
  const dedupeKey =
    suggestion.kind === "edit"
      ? `${suggestion.bookId}|${stableJson(suggestion.proposed)}`
      : bookKey(
          String(suggestion.proposed.title ?? ""),
          ((suggestion.proposed.authors as string[] | undefined) ?? [])[0] ?? "",
        );
  await db.runTransaction(async (transaction) => {
    const pending = await transaction.get(
      bookSuggestionsCol()
        .where("dedupeKey", "==", dedupeKey)
        .where("status", "==", "pending")
        .limit(1),
    );
    const now = FieldValue.serverTimestamp();
    const existing = pending.docs[0];
    if (existing) {
      const from = [...((existing.get("from") as SuggestionSource[] | undefined) ?? []), source];
      transaction.update(existing.ref, {
        count: FieldValue.increment(1),
        from: from.slice(-MAX_SUGGESTION_SOURCES),
        updatedAt: now,
      });
      return;
    }
    transaction.set(bookSuggestionsCol().doc(), {
      kind: suggestion.kind,
      bookId: suggestion.bookId,
      proposed: suggestion.proposed,
      dedupeKey,
      count: 1,
      from: [source],
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });
  });
}

/**
 * Points the programs a `new` suggestion came from at the catalog book it
 * became, so they count as its readers and show its cover. Programs that
 * already name a book, or no longer exist, are left alone.
 */
export async function linkSuggestionPrograms(
  sources: SuggestionSource[],
  bookId: string,
  coverUrl: string | null,
): Promise<number> {
  let linked = 0;
  for (const source of sources) {
    const ref = programsCol(source.schoolId).doc(source.programId);
    const program = await ref.get();
    if (!program.exists || program.get("book.bookId")) continue;
    await ref.update({"book.bookId": bookId, "book.coverUrl": coverUrl});
    linked++;
  }
  return linked;
}

/** True when two timestamps (or both missing) are the same moment. */
export function sameTime(a: unknown, b: unknown): boolean {
  if (a instanceof Timestamp && b instanceof Timestamp) return a.isEqual(b);
  return a == null && b == null;
}

// ---------------------------------------------------------------------------
// Covers
// ---------------------------------------------------------------------------

/**
 * The Storage path inside a Firebase download URL
 * (`…/v0/b/{bucket}/o/{encoded path}?alt=media&token=…`), or null.
 */
export function storagePathOf(url: unknown): string | null {
  if (typeof url !== "string") return null;
  const match = /\/v0\/b\/[^/]+\/o\/([^?#]+)/.exec(url);
  if (!match) return null;
  try {
    return decodeURIComponent(match[1]);
  } catch {
    return null;
  }
}

/**
 * The cover a student uploaded for their own program, when the URL really
 * points at their upload folder (`schools/{s}/programCovers/{uid}/…`).
 */
export function programCoverPath(url: unknown, schoolId: string, studentId: string): string | null {
  const path = storagePathOf(url);
  const folder = `schools/${schoolId}/programCovers/${studentId}/`;
  return path && path.startsWith(folder) && !path.includes("..") ? path : null;
}

/**
 * Copies a cover file into the catalog's own folder and returns its download
 * URL. A catalog book never points at a student's file: the student may
 * delete it, and only members of their school can read it.
 */
export async function copyCoverToCatalog(fromPath: string, bookId: string): Promise<string> {
  const bucket = getStorage().bucket();
  const source = bucket.file(fromPath);
  const [exists] = await source.exists();
  if (!exists) {
    throw new HttpsError("failed-precondition", "Gambar cover dari saran ini sudah tidak ada.");
  }
  const target = bucket.file(`books/${bookId}/cover-${Date.now()}.jpg`);
  await source.copy(target);
  // The copy carries the student's download token; give it its own.
  return downloadUrlOf(target, {newToken: true});
}

type StorageFile = ReturnType<ReturnType<ReturnType<typeof getStorage>["bucket"]>["file"]>;

/**
 * The Firebase download URL of a Storage file, creating its download token
 * when it has none. Same result as `getDownloadURL` from the Admin SDK, which
 * the Storage emulator refuses to serve without client credentials.
 */
export async function downloadUrlOf(file: StorageFile, options: {newToken?: boolean} = {}): Promise<string> {
  const [metadata] = await file.getMetadata();
  const existing = String(metadata.metadata?.firebaseStorageDownloadTokens ?? "").split(",")[0];
  const token = !options.newToken && existing ? existing : randomUUID();
  if (token !== existing) {
    await file.setMetadata({metadata: {firebaseStorageDownloadTokens: token}});
  }
  const emulator = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  const host = emulator ? `http://${emulator}` : "https://firebasestorage.googleapis.com";
  return `${host}/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

/** A new ID for a catalog book, known before it is written. */
export const newBookId = () => booksCol().doc().id;
