/**
 * Text normalisation for book search. Must stay in sync with
 * lib/core/utils/text_search.dart.
 */

/**
 * Lower case, accents removed, anything but letters and digits turned into
 * single spaces: `"Bumi Manusia: Edisi Revisi"` → `"bumi manusia edisi revisi"`.
 */
export function normalizeSearchText(raw: string): string {
  return raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

/**
 * Title and first author, normalised: the key that tells whether two entries
 * are the same book (catalog `searchKey`, suggestion dedupe).
 */
export function bookKey(title: string, firstAuthor: string): string {
  return `${normalizeSearchText(title)}|${normalizeSearchText(firstAuthor)}`;
}

/** Fixed categories, in display order. Must match lib/features/books/domain/book_categories.dart. */
export const BOOK_CATEGORIES = [
  "Novel",
  "Sastra Klasik",
  "Remaja",
  "Puisi",
  "Kumpulan Cerpen",
  "Sejarah",
  "Biografi",
  "Agama",
  "Pengembangan Diri",
  "Sains",
  "Bisnis",
  "Komik",
  "Anak",
  "Nonfiksi Umum",
  "Lainnya",
] as const;

export type BookCategory = (typeof BOOK_CATEGORIES)[number];

/** Catalog index shards (`catalog/shard-{n}`). */
export const CATALOG_SHARDS = 4;

export function shardOf(bookId: string): number {
  let sum = 0;
  for (const char of bookId) sum = (sum + char.charCodeAt(0)) % 1_000_003;
  return sum % CATALOG_SHARDS;
}
