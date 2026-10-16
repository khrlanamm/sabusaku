// Step 1 of the book import: finds Indonesian-language editions for the
// seeds and writes every raw match to out/candidates.json.
//
//   npx tsx tools/books/fetch.ts
//
// Sources, in order:
//   1. Open Library, per seed author: works with an Indonesian edition
//      (`language:ind`), with that edition's title, cover, ISBN and publisher.
//   2. Open Library, per seed title (classics and must-haves).
//   3. Google Books, plain-text queries for seed authors and titles that
//      Open Library covers poorly. Google's field operators (intitle:,
//      inauthor:) return nothing for these, and plain results are noisy, so
//      every hit must match the seed author or title.
//   4. Open Library for the extra writers found on Wikipedia (wiki.ts).
// All responses are cached; a rerun only fetches what is new.

import {existsSync, readFileSync} from "node:fs";
import {resolve} from "node:path";

import {normalizeSearchText} from "../../src/domain/search";
import {
  Candidate,
  OUT,
  QuotaExhausted,
  SECRET,
  SeedRef,
  authorMatches,
  getJson,
  googleQueriesLeft,
  isCached,
  isbnsOf,
  readJson,
  writeJson,
  yearOf,
} from "./common";
import {SEED_AUTHORS, SEED_TITLES, SeedAuthor, SeedTitle} from "./seeds";

const OL_FIELDS = [
  "key",
  "title",
  "subtitle",
  "author_name",
  "first_publish_year",
  "number_of_pages_median",
  "cover_i",
  "language",
  "subject",
  "edition_count",
  "editions",
  "editions.key",
  "editions.title",
  "editions.subtitle",
  "editions.cover_i",
  "editions.language",
  "editions.isbn",
  "editions.publisher",
  "editions.publish_date",
].join(",");

interface OlEdition {
  key?: string;
  title?: string;
  subtitle?: string;
  cover_i?: number;
  language?: string[];
  isbn?: string[];
  publisher?: string[];
  publish_date?: string[];
}

interface OlDoc {
  key: string;
  title?: string;
  subtitle?: string;
  author_name?: string[];
  first_publish_year?: number;
  number_of_pages_median?: number;
  cover_i?: number;
  language?: string[];
  subject?: string[];
  edition_count?: number;
  editions?: {docs?: OlEdition[]};
}

/** Publishers of general reading; textbook and academic houses are left out. */
const PUBLISHERS = [
  "Gramedia Pustaka Utama",
  "PT Gramedia Pustaka Utama",
  "Gramedia",
  "Kepustakaan Populer Gramedia",
  "Mizan",
  "Mizan Pustaka",
  "Qanita",
  "Bentang",
  "Bentang Pustaka",
  "GagasMedia",
  "Bukune",
  "Republika",
  "Noura Books",
  "Balai Pustaka",
  "Pustaka Jaya",
  "Dunia Pustaka Jaya",
  "Elex Media Komputindo",
  "Grasindo",
  "Marjin Kiri",
  "Penerbit Buku Kompas",
  "Serambi",
  "Haru",
  "Diva Press",
  "Yayasan Obor Indonesia",
  "Pustaka Utama Grafiti",
  "Lentera Dipantara",
  "Hasta Mitra",
  "Bentang Belia",
  "Matahari",
  "Basabasi",
  "Pustaka Alvabet",
  "Gema Insani",
  "Lingkar Pena",
  "Zikrul Hakim",
  "Kanisius",
];

/** Open Library subjects of general reading, harvested for Indonesian editions. */
const SUBJECTS = [
  "Fiction",
  "Indonesian fiction",
  "Novel",
  "Short stories",
  "Juvenile fiction",
  "Young adult fiction",
  "Romance",
  "Love stories",
  "Fantasy",
  "Detective and mystery stories",
  "Horror",
  "Children's stories",
  "Comic books, strips",
  "Indonesian poetry",
  "Self-help",
  "Success",
  "Biography",
  "Autobiography",
  "Motivation",
];

const quote = (text: string) => `"${text.replace(/"/g, "")}"`;

async function olSearch(q: string, limit = 100, page = 1): Promise<OlDoc[]> {
  const url =
    `https://openlibrary.org/search.json?q=${encodeURIComponent(q)}` +
    `&limit=${limit}&page=${page}&fields=${OL_FIELDS}`;
  const data = await getJson<{docs: OlDoc[]}>(url);
  return data?.docs ?? [];
}

function fromOl(doc: OlDoc, seed: SeedRef): Candidate | null {
  const edition = doc.editions?.docs?.[0];
  const indonesian = edition?.language?.includes("ind") ?? false;
  if (!indonesian) return null;
  const title = (edition?.title ?? doc.title ?? "").trim();
  // The work's own cover may belong to any edition, often a translation
  // ("Salah Asuhan" shows "Never the Twain"). Use it only when every edition
  // of the work is Indonesian.
  const onlyIndonesian = (doc.language ?? []).length > 0 && (doc.language ?? []).every((l) => l === "ind");
  const cover = edition?.cover_i ?? (!seed.translated && onlyIndonesian ? doc.cover_i : undefined);
  const {isbn13, isbn10} = isbnsOf(edition?.isbn);
  return {
    source: "openlibrary",
    sourceId: edition?.key ?? doc.key,
    workKey: doc.key,
    title,
    subtitle: edition?.subtitle ?? null,
    authors: doc.author_name ?? [],
    publisher: edition?.publisher?.[0] ?? null,
    publishedYear: yearOf(edition?.publish_date?.[0]) ?? doc.first_publish_year ?? null,
    pageCount: doc.number_of_pages_median ?? null,
    isbn13,
    isbn10,
    categories: doc.subject?.slice(0, 15) ?? [],
    description: null,
    language: "id",
    coverUrl: cover ? `https://covers.openlibrary.org/b/id/${cover}-L.jpg?default=false` : null,
    seed,
  };
}

interface GoogleItem {
  id: string;
  volumeInfo: {
    title?: string;
    subtitle?: string;
    authors?: string[];
    publisher?: string;
    publishedDate?: string;
    description?: string;
    industryIdentifiers?: {type: string; identifier: string}[];
    pageCount?: number;
    categories?: string[];
    language?: string;
    imageLinks?: Record<string, string>;
  };
}

const googleUrl = (q: string) =>
  `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(q)}` +
  `&langRestrict=id&printType=books&maxResults=40&key=${readGoogleKey()}`;

export async function googleSearch(q: string): Promise<GoogleItem[]> {
  const data = await getJson<{items?: GoogleItem[]}>(googleUrl(q));
  return data?.items ?? [];
}

/** A query asked before costs no quota. */
export const googleCached = (q: string) => isCached(googleUrl(q));

let googleKey: string | undefined;
function readGoogleKey(): string {
  googleKey ??= readFileSync(resolve(SECRET, "books-api-key.txt"), "utf8").trim();
  return googleKey;
}

/** A Google cover at a useful size: no page curl, ~600 px wide. */
export function googleCover(links: Record<string, string> | undefined, id: string): string | null {
  if (!links) return null;
  return `https://books.google.com/books/content?id=${id}&printsec=frontcover&img=1&zoom=1&fife=w600`;
}

export function fromGoogle(item: GoogleItem, seed: SeedRef): Candidate | null {
  const info = item.volumeInfo;
  if (info.language !== "id" || !info.title) return null;
  const ids = (info.industryIdentifiers ?? []).map((i) => i.identifier);
  const {isbn13, isbn10} = isbnsOf(ids);
  return {
    source: "google",
    sourceId: item.id,
    title: info.title.trim(),
    subtitle: info.subtitle ?? null,
    authors: info.authors ?? [],
    publisher: info.publisher ?? null,
    publishedYear: yearOf(info.publishedDate),
    pageCount: info.pageCount ?? null,
    isbn13,
    isbn10,
    categories: info.categories ?? [],
    description: info.description ?? null,
    language: "id",
    coverUrl: googleCover(info.imageLinks, item.id),
    seed,
  };
}

/** Same title: equal after normalisation, or the seed title plus a subtitle. */
export function titleMatches(candidate: string, seed: string): boolean {
  const c = normalizeSearchText(candidate);
  const s = normalizeSearchText(seed);
  if (!c || !s) return false;
  return c === s || c.startsWith(`${s} `) || (s.length >= 12 && c.includes(s));
}

const authorRef = (author: SeedAuthor): SeedRef => ({
  kind: "author",
  name: author.name,
  category: author.category,
  classic: author.classic,
  translated: author.translated,
});

const titleRef = (seed: SeedTitle, translated: boolean): SeedRef => ({
  kind: "title",
  name: `${seed.title} — ${seed.author}`,
  category: seed.category,
  translated,
});

async function main() {
  const candidates: Candidate[] = [];
  const add = (candidate: Candidate | null) => {
    if (candidate && candidate.title) candidates.push(candidate);
  };
  const perAuthor = new Map<string, number>();
  const translatedAuthors = new Set(SEED_AUTHORS.filter((a) => a.translated).map((a) => a.name));
  let googleStopped = false;

  // 1. Open Library per author.
  console.log(`Open Library: ${SEED_AUTHORS.length} penulis`);
  for (const author of SEED_AUTHORS) {
    let found = 0;
    for (const name of [author.name, ...(author.aliases ?? [])]) {
      const docs = await olSearch(`author:${quote(name)} language:ind`);
      for (const doc of docs) {
        if (!(doc.author_name ?? []).some((n) => authorMatches(n, author.name, author.aliases))) continue;
        const candidate = fromOl(doc, authorRef(author));
        if (candidate) {
          add(candidate);
          found++;
        }
      }
      if (found > 0) break;
    }
    perAuthor.set(author.name, found);
    process.stdout.write(`  ${author.name}: ${found}\n`);
  }

  // 2. Open Library per title.
  console.log(`Open Library: ${SEED_TITLES.length} judul`);
  const titleFound = new Map<SeedTitle, boolean>();
  for (const seed of SEED_TITLES) {
    const translated = translatedAuthors.has(seed.author);
    const queries = [
      `title:${quote(seed.title)} author:${quote(seed.author)} language:ind`,
      `title:${quote(seed.title)} language:ind`,
      ...(seed.original ? [`title:${quote(seed.original)} author:${quote(seed.author)} language:ind`] : []),
    ];
    let hit = false;
    for (const q of queries) {
      for (const doc of await olSearch(q, 20)) {
        const authorOk = (doc.author_name ?? []).some((n) => authorMatches(n, seed.author));
        const edition = doc.editions?.docs?.[0];
        const titleOk =
          titleMatches(edition?.title ?? doc.title ?? "", seed.title) ||
          (seed.original ? titleMatches(doc.title ?? "", seed.original) : false);
        if (!authorOk || !titleOk) continue;
        const candidate = fromOl(doc, titleRef(seed, translated));
        if (candidate) {
          add(candidate);
          // Only an edition with a cover settles the title; otherwise Google
          // is asked as well (step 3).
          if (candidate.coverUrl) hit = true;
        }
      }
      if (hit) break;
    }
    titleFound.set(seed, hit);
  }
  console.log(`  judul ditemukan: ${[...titleFound.values()].filter(Boolean).length}/${SEED_TITLES.length}`);

  // 3. Google Books where Open Library is thin.
  try {
    const thinAuthors = SEED_AUTHORS.filter((a) => (perAuthor.get(a.name) ?? 0) < 6);
    console.log(`Google Books: ${thinAuthors.length} penulis tipis, sisa kuota ${googleQueriesLeft()}`);
    for (const author of thinAuthors) {
      // Keep quota for descriptions (enrich.ts); cached answers are free.
      if (!googleCached(author.name) && googleQueriesLeft() < 450) continue;
      for (const item of await googleSearch(author.name)) {
        const authors = item.volumeInfo.authors ?? [];
        if (!authors.some((n) => authorMatches(n, author.name, author.aliases))) continue;
        add(fromGoogle(item, authorRef(author)));
      }
    }
    const missingTitles = SEED_TITLES.filter((s) => !titleFound.get(s));
    console.log(`Google Books: ${missingTitles.length} judul yang belum ketemu`);
    for (const seed of missingTitles) {
      if (!googleCached(`${seed.title} ${seed.author}`) && googleQueriesLeft() < 350) continue;
      const translated = translatedAuthors.has(seed.author);
      for (const item of await googleSearch(`${seed.title} ${seed.author}`)) {
        const info = item.volumeInfo;
        if (!(info.authors ?? []).some((n) => authorMatches(n, seed.author))) continue;
        if (!titleMatches(info.title ?? "", seed.title) && !(seed.original && titleMatches(info.title ?? "", seed.original))) continue;
        add(fromGoogle(item, titleRef(seed, translated)));
      }
    }
  } catch (error) {
    if (!(error instanceof QuotaExhausted)) throw error;
    googleStopped = true;
    console.warn(error.message);
  }

  // 4. Writers from Wikipedia (only on Open Library; at most 8 books each).
  const wikiFile = resolve(OUT, "wiki-seeds.json");
  if (existsSync(wikiFile)) {
    const wiki = readJson<{titles: {title: string; author: string}[]; authors: string[]}>(wikiFile, {
      titles: [],
      authors: [],
    });
    const known = SEED_AUTHORS.flatMap((a) => [a.name, ...(a.aliases ?? [])]);
    const extra = wiki.authors.filter((name) => !known.some((k) => authorMatches(name, k)));
    console.log(`Open Library: ${extra.length} penulis dari Wikipedia, ${wiki.titles.length} judul`);
    for (const name of extra) {
      const docs = await olSearch(`author:${quote(name)} language:ind`, 30);
      let taken = 0;
      for (const doc of docs) {
        if (taken >= 8) break;
        if (!(doc.author_name ?? []).some((n) => authorMatches(n, name))) continue;
        const candidate = fromOl(doc, {kind: "wiki", name});
        if (candidate) {
          add(candidate);
          taken++;
        }
      }
    }
    for (const seed of wiki.titles) {
      for (const doc of await olSearch(`title:${quote(seed.title)} language:ind`, 10)) {
        const edition = doc.editions?.docs?.[0];
        if (!(doc.author_name ?? []).some((n) => authorMatches(n, seed.author))) continue;
        if (!titleMatches(edition?.title ?? doc.title ?? "", seed.title)) continue;
        add(fromOl(doc, {kind: "wiki", name: `${seed.title} — ${seed.author}`}));
      }
    }
  }

  // 5. Indonesian publishers of general reading (fiction, translations,
  // popular nonfiction): every Indonesian edition with a cover. This finds
  // well-known books whose authors are not in the seed lists.
  console.log(`Open Library: ${PUBLISHERS.length} penerbit`);
  for (const publisher of PUBLISHERS) {
    let taken = 0;
    for (let page = 1; page <= 30; page++) {
      const docs = await olSearch(`publisher:${quote(publisher)} language:ind`, 100, page);
      for (const doc of docs) {
        // Only the Indonesian edition's own cover: a translated work's main
        // cover is usually the original edition's.
        const candidate = fromOl(doc, {kind: "publisher", name: publisher, translated: true});
        if (candidate?.coverUrl) {
          add(candidate);
          taken++;
        }
      }
      if (docs.length < 100) break;
    }
    console.log(`  ${publisher}: ${taken}`);
  }

  // 6. Reading subjects (fiction, stories, poetry, self-help, biography):
  // Indonesian editions with their own cover.
  console.log(`Open Library: ${SUBJECTS.length} subjek`);
  for (const subject of SUBJECTS) {
    let taken = 0;
    for (let page = 1; page <= 10; page++) {
      const docs = await olSearch(`subject:${quote(subject)} language:ind`, 100, page);
      for (const doc of docs) {
        const candidate = fromOl(doc, {kind: "subject", name: subject, translated: true});
        if (candidate?.coverUrl) {
          add(candidate);
          taken++;
        }
      }
      if (docs.length < 100) break;
    }
    console.log(`  ${subject}: ${taken}`);
  }

  // 7. The most relevant recent Indonesian editions overall (Open Library
  // ranks well-known books first); these mostly have real cover photos.
  for (const [range, pages] of [
    ["[2010 TO 2025]", 80],
    ["[2000 TO 2009]", 50],
    ["[1980 TO 1999]", 15],
  ] as const) {
    let taken = 0;
    for (let page = 1; page <= pages; page++) {
      const docs = await olSearch(`language:ind first_publish_year:${range}`, 100, page);
      for (const doc of docs) {
        const candidate = fromOl(doc, {kind: "subject", name: `terbit ${range}`, translated: true});
        if (candidate?.coverUrl) {
          add(candidate);
          taken++;
        }
      }
      if (docs.length < 100) break;
    }
    console.log(`  terbit ${range}: ${taken}`);
  }

  writeJson(resolve(OUT, "candidates.json"), candidates);
  const bySource = candidates.reduce<Record<string, number>>((acc, c) => {
    acc[c.source] = (acc[c.source] ?? 0) + 1;
    return acc;
  }, {});
  console.log(`Kandidat: ${candidates.length}`, bySource, googleStopped ? "(Google berhenti: kuota)" : "");
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
