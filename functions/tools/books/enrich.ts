// Step 3 of the book import: fills what the first pass left empty.
//
//   npx tsx tools/books/enrich.ts
//
//   1. Page counts from Open Library edition records.
//   2. Synopsis, categories, ISBN, publisher and pages from Google Books, one
//      plain-text query per book ("title author"), most important books first,
//      until the daily quota runs out (rerun tomorrow to continue: the cache
//      keeps every answer).
//   3. Synopsis from the Open Library work when it is in Indonesian.
// Then books still without a page count are rejected.

import {resolve} from "node:path";

import {OUT, QuotaExhausted, authorMatches, getJson, googleQueriesLeft, isbnsOf, readJson, writeJson, yearOf} from "./common";
import {fromGoogle, googleCached, googleSearch, titleMatches} from "./fetch";
import {ImportBook, categoriesFor, cleanDescription, cleanPublisher} from "./normalize";

const ID_WORDS = ["yang", "dan", "di", "dengan", "ini", "itu", "dari", "untuk", "tidak", "ke", "dalam", "akan", "ia", "mereka", "kisah"];
const EN_WORDS = ["the", "and", "of", "to", "is", "in", "that", "with", "his", "her", "this", "from"];

/** True when [text] reads as Indonesian rather than English. */
export function looksIndonesian(text: string): boolean {
  const words = text.toLowerCase().match(/[a-z]+/g) ?? [];
  if (words.length < 8) return false;
  const id = words.filter((w) => ID_WORDS.includes(w)).length;
  const en = words.filter((w) => EN_WORDS.includes(w)).length;
  return id >= 3 && id > en * 1.5;
}

interface OlEditionRecord {
  number_of_pages?: number;
  pagination?: string;
  publishers?: string[];
  publish_date?: string;
  isbn_13?: string[];
  isbn_10?: string[];
  languages?: {key: string}[];
}

async function olPages(book: ImportBook): Promise<number | null> {
  for (const key of book.sources.openlibrary ?? []) {
    if (!key.startsWith("/books/")) continue;
    const record = await getJson<OlEditionRecord>(`https://openlibrary.org${key}.json`, {emptyOn: [404]});
    const pages = record?.number_of_pages ?? Number(record?.pagination?.match(/(\d{2,4})\s*(p|hlm|halaman)/i)?.[1] ?? NaN);
    if (pages && Number.isFinite(pages)) return pages;
  }
  if (book.workKey) {
    const list = await getJson<{entries?: OlEditionRecord[]}>(
      `https://openlibrary.org${book.workKey}/editions.json?limit=50`,
      {emptyOn: [404]},
    );
    const indonesian = (list?.entries ?? []).filter((e) => (e.languages ?? []).some((l) => l.key === "/languages/ind"));
    for (const edition of indonesian) if (edition.number_of_pages) return edition.number_of_pages;
  }
  return null;
}

async function olDescription(workKey: string): Promise<string | null> {
  const work = await getJson<{description?: string | {value?: string}}>(`https://openlibrary.org${workKey}.json`, {
    emptyOn: [404],
  });
  const raw = typeof work?.description === "string" ? work.description : work?.description?.value;
  const text = cleanDescription(raw);
  return text && looksIndonesian(text) ? text : null;
}

async function main() {
  const file = resolve(OUT, "books.json");
  const books = readJson<ImportBook[]>(file, []);
  const rejected = readJson<{id?: string; title: string; authors: string[]; reason: string}[]>(resolve(OUT, "rejected.json"), []);

  // 1. Pages from Open Library.
  const noPages = books.filter((b) => !b.pageCount);
  console.log(`Halaman dari Open Library: ${noPages.length} buku`);
  for (const book of noPages) {
    const pages = await olPages(book);
    if (pages) book.pageCount = pages;
  }

  // 2. Google Books, most important first.
  const order = [...books].sort((x, y) => y.score - x.score);
  let googleDone = 0;
  try {
    for (const book of order) {
      if (book.description && book.pageCount && book.isbn13) continue;
      if (!googleCached(`${book.title} ${book.authors[0]}`) && googleQueriesLeft() <= 5) continue;
      const items = await googleSearch(`${book.title} ${book.authors[0]}`);
      googleDone++;
      const match = items.find(
        (item) =>
          titleMatches(item.volumeInfo.title ?? "", book.title) &&
          (item.volumeInfo.authors ?? []).some((n) => authorMatches(n, book.authors[0])),
      );
      if (!match) continue;
      const g = fromGoogle(match, {kind: "title", name: book.title});
      if (!g) continue;
      const description = cleanDescription(g.description);
      if (!book.description && description && looksIndonesian(description)) {
        book.description = description;
        book.descriptionSource = "google";
      }
      if (!book.pageCount && g.pageCount) book.pageCount = g.pageCount;
      if (!book.isbn13 && g.isbn13) book.isbn13 = g.isbn13;
      if (!book.isbn10 && g.isbn10) book.isbn10 = g.isbn10;
      if (!book.publisher && g.publisher) book.publisher = cleanPublisher(g.publisher);
      if (!book.publishedYear && g.publishedYear) book.publishedYear = g.publishedYear;
      if (g.categories.length) book.subjects = [...new Set([...(book.subjects ?? []), ...g.categories])];
      if (g.coverUrl && !book.coverCandidates.some((c) => c.provider === "google")) {
        book.coverCandidates.push({provider: "google", url: g.coverUrl, sourceId: g.sourceId});
      }
      book.sources.google = [...new Set([...(book.sources.google ?? []), g.sourceId])];
    }
  } catch (error) {
    if (!(error instanceof QuotaExhausted)) throw error;
    console.warn(error.message);
  }
  console.log(`Google Books: ${googleDone} kueri, sisa kuota ${googleQueriesLeft()}`);

  // 3. Indonesian synopsis from the Open Library work.
  for (const book of books) {
    if (book.description || !book.workKey || book.translated) continue;
    book.description = await olDescription(book.workKey);
    book.descriptionSource = book.description ? "openlibrary" : null;
  }

  // Classify again with everything learned; drop books still without pages.
  const kept: ImportBook[] = [];
  for (const book of books) {
    book.categories = categoriesFor(book);
    if (book.publishedYear != null) book.publishedYear = yearOf(book.publishedYear);
    if (!book.pageCount) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: "tanpa jumlah halaman"});
      continue;
    }
    if (book.pageCount < 10 || book.pageCount > 2000) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: "jumlah halaman di luar 10–2000"});
      continue;
    }
    const {isbn13} = isbnsOf(book.isbn13 ? [book.isbn13] : []);
    book.isbn13 = isbn13;
    kept.push(book);
  }

  writeJson(file, kept);
  writeJson(resolve(OUT, "rejected.json"), rejected);
  const withDescription = kept.filter((b) => b.description).length;
  console.log(`Lengkap halaman: ${kept.length} buku (${withDescription} dengan sinopsis).`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
