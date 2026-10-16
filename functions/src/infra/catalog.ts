import {FieldValue} from "firebase-admin/firestore";

import {CATALOG_SHARDS, shardOf} from "../domain/search";
import {booksCol, db} from "./firebase";

export {booksCol};

/**
 * The search index of the shared book catalog: four documents
 * `catalog/shard-{n}`, each holding `entries.{bookId}` for the active books
 * whose ID hashes to it. The app reads the four documents once (they stay in
 * its offline cache) and searches on the device; Firestore has no full-text
 * search, and the catalog is small.
 */

/** Compact keys keep the index documents small (lib CatalogEntry.fromMap). */
export interface CatalogEntry {
  /** Title. */
  t: string;
  /** Authors joined with ", ". */
  a: string;
  /** Page count. */
  p: number;
  /** Year of publication. */
  y: number | null;
  /** Cover download URL. */
  c: string | null;
  /** Categories. */
  g: string[];
  /** Number of students who started the book. */
  r: number;
}

export const catalogShardRef = (shard: number) => db.doc(`catalog/shard-${shard}`);

/** The index entry of a `books` document. */
export function catalogEntry(data: FirebaseFirestore.DocumentData): CatalogEntry {
  const authors = Array.isArray(data.authors) ? (data.authors as string[]) : [];
  return {
    t: (data.title as string | undefined) ?? "",
    a: authors.join(", "),
    p: (data.pageCount as number | undefined) ?? 0,
    y: (data.publishedYear as number | null | undefined) ?? null,
    c: (data.coverUrl as string | null | undefined) ?? null,
    g: Array.isArray(data.categories) ? (data.categories as string[]) : [],
    r: (data.readerCount as number | undefined) ?? 0,
  };
}

/** True when the book belongs in the index (it exists and is not deleted). */
export function isIndexed(data: FirebaseFirestore.DocumentData | null | undefined): boolean {
  return Boolean(data) && data!.status !== "deleted";
}

/**
 * Puts one book in its shard, or takes it out when [data] is null or the book
 * is deleted. Only that entry of the shard document changes.
 */
export async function upsertCatalogEntry(
  bookId: string,
  data: FirebaseFirestore.DocumentData | null,
): Promise<void> {
  const entry = isIndexed(data) ? catalogEntry(data!) : FieldValue.delete();
  await catalogShardRef(shardOf(bookId)).set(
    {entries: {[bookId]: entry}, updatedAt: FieldValue.serverTimestamp()},
    {merge: true},
  );
}

/**
 * Rewrites the four shards from every active book. Used after a bulk import
 * (the import skips the per-book trigger) and as a repair tool. Returns the
 * number of books indexed.
 */
export async function rebuildCatalog(): Promise<number> {
  const shards: Record<string, CatalogEntry>[] = Array.from({length: CATALOG_SHARDS}, () => ({}));
  const books = await booksCol().where("status", "==", "active").get();
  for (const book of books.docs) {
    shards[shardOf(book.id)][book.id] = catalogEntry(book.data());
  }
  const batch = db.batch();
  shards.forEach((entries, shard) => {
    batch.set(catalogShardRef(shard), {
      entries,
      count: Object.keys(entries).length,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  return books.size;
}
