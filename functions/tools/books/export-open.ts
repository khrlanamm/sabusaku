// Exports the facts of the catalog for the public repo khrlanamm/buku-indonesia.
// A one-time step: after it, the YAML files in that repo are the source of truth.
//
//   npx tsx tools/books/export-open.ts --out /path/to/books.ndjson --report /path/to/report.json
//
// Reads production (books only, no student data) and the local caches. It
// writes nothing to Firestore. Every field needs a basis other than Google,
// whose API terms forbid building databases from its content:
//
//   - a hand correction (CORRECTIONS), which always wins, even when it is null;
//   - a hand-checked record (MANUAL_BOOKS, SUGGESTION_DECISIONS);
//   - an Open Library value, compared at the edition level where possible;
//   - a Wikipedia infobox value, for books Open Library does not know.
//
// A field with no such basis takes the Open Library value when there is one,
// or null, and is listed in needsCheck. Synopses and cover files never leave:
// the output is built from a fixed list of fields.

import "../_env";

import {readdirSync, readFileSync, writeFileSync} from "node:fs";
import {resolve} from "node:path";

import {bookKey, normalizeSearchText} from "../../src/domain/search";
import {db} from "../../src/infra/firebase";
import {Candidate, OUT, argValue, authorMatches, getJson, readJson, sha1, yearOf} from "./common";
import {ImportBook, canonicalAuthor, classify, cleanPublisher, cleanSubtitle, cleanTitle, looksEnglishTitle} from "./normalize";
import {MANUAL_BOOKS, SYNOPSES} from "./private-data";
import {CATEGORY_OVERRIDES, CORRECTIONS, REJECTED_BOOKS, SUGGESTION_DECISIONS} from "./review";
import {Category} from "./seeds";
import {WikiBook} from "./wikipedia";

type Field = "title" | "subtitle" | "authors" | "publisher" | "year" | "isbn13" | "pages" | "categories";

interface OpenBook {
  id: string;
  title: string;
  subtitle: string | null;
  authors: string[];
  publisher: string | null;
  year: number | null;
  isbn13: string | null;
  pages: number | null;
  language: string;
  categories: string[];
  reviewed: boolean;
  needsCheck: Field[];
  sources: string[];
  openLibrary: {work: string | null; edition: string | null; coverId: number | null} | null;
}

interface OlEdition {
  key: string;
  title?: string;
  subtitle?: string;
  isbn: string[];
  publishers: string[];
  years: number[];
  coverId?: number;
  work?: string;
}

interface OlWork {
  key: string;
  authors: string[];
  medianPages?: number;
  editionCount: number;
  languages: string[];
  subjects: string[];
  title?: string;
}

const norm = normalizeSearchText;

function closeText(a: string | null | undefined, b: string | null | undefined): boolean {
  const x = norm(a ?? "");
  const y = norm(b ?? "");
  return !!x && !!y && (x === y || x.startsWith(`${y} `) || y.startsWith(`${x} `));
}

function isValidIsbn13(value: string): boolean {
  if (!/^\d{13}$/.test(value)) return false;
  let sum = 0;
  for (let i = 0; i < 12; i++) sum += Number(value[i]) * (i % 2 === 0 ? 1 : 3);
  return (10 - (sum % 10)) % 10 === Number(value[12]);
}

/** Every Open Library fact seen in the search cache. */
function loadOpenLibrary() {
  const dir = resolve(OUT, "cache", "openlibrary.org");
  const editions = new Map<string, OlEdition>();
  const works = new Map<string, OlWork>();
  for (const name of readdirSync(dir)) {
    const cached = JSON.parse(readFileSync(resolve(dir, name), "utf8")) as {body?: {docs?: any[]} | null};
    for (const doc of cached.body?.docs ?? []) {
      const known = works.get(doc.key);
      works.set(doc.key, {
        key: doc.key,
        title: doc.title ?? known?.title,
        authors: doc.author_name ?? known?.authors ?? [],
        medianPages: doc.number_of_pages_median ?? known?.medianPages,
        editionCount: doc.edition_count ?? known?.editionCount ?? 1,
        languages: doc.language ?? known?.languages ?? [],
        subjects: doc.subject ?? known?.subjects ?? [],
      });
      for (const edition of doc.editions?.docs ?? []) {
        if (!edition.key) continue;
        const years = (edition.publish_date ?? []).map((d: string) => yearOf(d)).filter(Boolean) as number[];
        editions.set(edition.key, {
          key: edition.key,
          title: edition.title,
          subtitle: edition.subtitle,
          isbn: (edition.isbn ?? []).map((v: string) => v.replace(/[^0-9Xx]/g, "").toUpperCase()),
          publishers: edition.publisher ?? [],
          years,
          coverId: edition.cover_i,
          work: doc.key,
        });
      }
    }
  }
  return {editions, works};
}

const olKey = (key: string | null | undefined) => key?.split("/").pop() ?? null;

/** The record of one edition, for its own page count. Cached, so a rerun costs nothing. */
async function editionPages(editionKey: string): Promise<number | null> {
  const record = await getJson<{number_of_pages?: number}>(`https://openlibrary.org${editionKey}.json`, {emptyOn: [404]});
  return record?.number_of_pages ?? null;
}

/** Categories from Open Library subjects only: enrich.ts mixed Google's into book.subjects. */
function openCategories(subjects: string[], title: string, book: Partial<ImportBook>, publisher: string | null): Category[] {
  return classify(subjects, title, book.seedCategory, !!book.classic, publisher) as Category[];
}

async function main() {
  const outFile = argValue("out");
  const reportFile = argValue("report");
  if (!outFile || !reportFile) throw new Error("Wajib: --out dan --report");
  if (!Object.keys(SYNOPSES).length || !MANUAL_BOOKS.length) {
    throw new Error("Data privat kosong: clone sabusaku-catalog-data ke tools/books/private/ dulu.");
  }

  const local = new Map(readJson<ImportBook[]>(resolve(OUT, "books.json"), []).map((b) => [b.id, b]));
  const candidates = readJson<Candidate[]>(resolve(OUT, "candidates.json"), []);
  const rejected = readJson<{id?: string; title: string; authors: string[]; reason: string}[]>(resolve(OUT, "rejected.json"), []);
  const wiki = readJson<WikiBook[]>(resolve(OUT, "wiki-books.json"), []);
  const {editions, works} = loadOpenLibrary();
  console.log(`Open Library: ${editions.size} edisi, ${works.size} karya`);

  const editionByIsbn = new Map<string, OlEdition>();
  for (const edition of editions.values()) for (const isbn of edition.isbn) if (!editionByIsbn.has(isbn)) editionByIsbn.set(isbn, edition);
  const wikiByKey = new Map(wiki.map((w) => [bookKey(cleanTitle(w.title), canonicalAuthor(w.author)), w]));
  const handIsbns = new Set<string>();
  for (const manual of MANUAL_BOOKS) if (manual.book.isbn13) handIsbns.add(manual.book.isbn13);
  for (const decision of Object.values(SUGGESTION_DECISIONS)) {
    if (decision.action === "create" && decision.book.isbn13) handIsbns.add(decision.book.isbn13);
  }

  const snapshot = await db
    .collection("books")
    .where("status", "==", "active")
    .select("title", "subtitle", "authors", "publisher", "publishedYear", "isbn13", "pageCount", "categories", "language", "searchKey")
    .get();

  const out: OpenBook[] = [];
  const held: {id: string; title: string; authors: string[]; reason: string}[] = [];
  const counts: Record<string, number> = {};
  const count = (key: string) => (counts[key] = (counts[key] ?? 0) + 1);
  const coverIdOf = (url: string | undefined) => Number(url?.match(/\/b\/id\/(\d+)/)?.[1]) || null;

  for (const doc of snapshot.docs) {
    const b = doc.data();
    const id = doc.id;
    const lb = local.get(id);
    const correction = (CORRECTIONS[id] ?? {}) as Record<string, unknown>;
    const hand = (field: string) => field in correction;
    const prod = {
      title: b.title as string,
      subtitle: (b.subtitle ?? null) as string | null,
      authors: (b.authors ?? []) as string[],
      publisher: (b.publisher ?? null) as string | null,
      year: (b.publishedYear ?? null) as number | null,
      isbn13: (b.isbn13 ?? null) as string | null,
      pages: (b.pageCount ?? null) as number | null,
    };
    const categoriesProd = (b.categories ?? []) as string[];

    // Hand-checked records keep their facts, with no text and no cover.
    if (prod.isbn13 && handIsbns.has(prod.isbn13)) {
      const edition = editionByIsbn.get(prod.isbn13);
      out.push({
        id,
        ...prod,
        language: "id",
        categories: categoriesProd,
        reviewed: true,
        needsCheck: [],
        sources: ["hand-checked"],
        openLibrary: edition ? {work: olKey(edition.work), edition: olKey(edition.key), coverId: null} : null,
      });
      count("hand-checked");
      continue;
    }

    // The Open Library records behind this book.
    const ids = new Set(lb?.sources?.openlibrary ?? []);
    const rows = candidates.filter((c) => c.source === "openlibrary" && (ids.has(c.sourceId) || (lb?.workKey && c.workKey === lb.workKey)));
    const editionList: OlEdition[] = [...ids].map((k) => editions.get(k)).filter((e): e is OlEdition => !!e);
    if (prod.isbn13 && editionByIsbn.has(prod.isbn13)) editionList.push(editionByIsbn.get(prod.isbn13)!);
    const workKey = lb?.workKey ?? editionList.find((e) => e.work)?.work;
    const work = workKey ? works.get(workKey) : undefined;
    if (workKey) for (const edition of editions.values()) if (edition.work === workKey && !editionList.includes(edition)) editionList.push(edition);

    const wikiFacts = wikiByKey.get(bookKey(prod.title, prod.authors[0] ?? ""));
    const hasOpen = editionList.length > 0 || rows.length > 0;
    const googleSource = (lb?.sources?.google ?? []).length > 0;

    if (!hasOpen && googleSource && !hand("title")) {
      held.push({id, title: prod.title, authors: prod.authors, reason: "Google satu-satunya sumber"});
      count("held: google only");
      continue;
    }

    const needsCheck: Field[] = [];
    const sources = new Set<string>();
    const mark = (field: Field) => needsCheck.push(field);

    // Title.
    const openTitles = [...editionList.map((e) => e.title), work?.title, ...rows.map((r) => r.title)].filter(Boolean) as string[];
    const titleOk = hand("title") || openTitles.some((t) => closeText(t, prod.title) || closeText(cleanTitle(t), prod.title)) || closeText(wikiFacts?.title, prod.title);
    if (!titleOk) {
      held.push({id, title: prod.title, authors: prod.authors, reason: "judul tidak terkonfirmasi"});
      count("held: title not confirmed");
      continue;
    }
    if (hand("title")) sources.add("hand-checked");
    else if (openTitles.length) sources.add("open-library");
    else sources.add("wikipedia");

    // Authors: only names with a basis, or Open Library's list marked for a check.
    const openAuthors = [...(work?.authors ?? []), ...rows.flatMap((r) => r.authors)];
    let authors = prod.authors;
    if (hand("authors")) {
      sources.add("hand-checked");
    } else {
      const backed = prod.authors.filter(
        (name) => openAuthors.some((n) => authorMatches(n, name) || closeText(canonicalAuthor(n), name)) || closeText(wikiFacts?.author, name),
      );
      if (backed.length === prod.authors.length && backed.length > 0) {
        // Open Library joins all editions, so a translator can pass as an author of a mixed work.
        const languages = work?.languages ?? [];
        if (languages.length > 1 && (work?.editionCount ?? 1) > 1 && (work?.authors.length ?? 0) > 1) mark("authors");
      } else if (backed.length > 0) {
        authors = backed;
        mark("authors");
      } else if (openAuthors.length) {
        authors = [...new Set(openAuthors.map(canonicalAuthor))].slice(0, 5);
        mark("authors");
      } else if (wikiFacts?.author) {
        authors = [wikiFacts.author];
        mark("authors");
      } else {
        held.push({id, title: prod.title, authors: prod.authors, reason: "penulis tanpa sumber selain Google"});
        count("held: author without basis");
        continue;
      }
    }

    // The edition this record stands for.
    const edition =
      (prod.isbn13 && editionList.find((e) => e.isbn.includes(prod.isbn13!))) ||
      editionList.find((e) => ids.has(e.key)) ||
      editionList[0];

    // Publisher.
    let publisher: string | null = prod.publisher;
    const openPublishers = [...editionList.flatMap((e) => e.publishers), ...rows.map((r) => r.publisher)].filter(Boolean) as string[];
    const publisherMatches = (p: string) => {
      const x = norm(p);
      const y = norm(prod.publisher ?? "");
      return !!x && !!y && (x.includes(y) || y.includes(x));
    };
    if (hand("publisher")) {
      sources.add("hand-checked");
    } else if (prod.publisher && !openPublishers.some(publisherMatches) && !closeText(wikiFacts?.publisher, prod.publisher)) {
      publisher = cleanPublisher(edition?.publishers[0]) ?? null;
      mark("publisher");
    } else if (!prod.publisher) {
      publisher = cleanPublisher(edition?.publishers[0]) ?? null;
      if (!publisher) mark("publisher");
    }

    // Year.
    let year: number | null = prod.year;
    const openYears = [...editionList.flatMap((e) => e.years), ...rows.map((r) => r.publishedYear)].filter(Boolean) as number[];
    if (hand("publishedYear")) {
      sources.add("hand-checked");
    } else if (prod.year && !openYears.includes(prod.year) && wikiFacts?.publishedYear !== prod.year) {
      year = edition?.years[0] ?? null;
      mark("year");
    } else if (!prod.year) {
      year = edition?.years[0] ?? null;
      if (!year) mark("year");
    }

    // ISBN: a correction that clears it stays cleared. A wrong check digit is never published.
    let isbn13: string | null = prod.isbn13;
    if (hand("isbn13")) {
      sources.add("hand-checked");
    } else if (prod.isbn13) {
      const openIsbns = new Set([...editionList.flatMap((e) => e.isbn), ...rows.map((r) => r.isbn13)].filter(Boolean) as string[]);
      if (!openIsbns.has(prod.isbn13) && wikiFacts?.isbn13 !== prod.isbn13) {
        isbn13 = edition?.isbn.find((v) => /^\d{13}$/.test(v)) ?? null;
        mark("isbn13");
      }
    }
    if (isbn13 && !isValidIsbn13(isbn13)) {
      isbn13 = null;
      if (!needsCheck.includes("isbn13")) mark("isbn13");
      count("isbn cleared: bad check digit");
    }

    // Pages: the median of a work with many editions says nothing about this edition.
    let pages: number | null = prod.pages;
    if (hand("pageCount")) {
      sources.add("hand-checked");
    } else if ((work?.editionCount ?? 1) > 1 && edition) {
      const own = await editionPages(edition.key);
      if (own == null) {
        pages = null;
        mark("pages");
      } else if (own !== prod.pages) {
        pages = own;
        mark("pages");
      }
    } else if (hasOpen) {
      const median = work?.medianPages ?? rows.find((r) => r.pageCount)?.pageCount ?? null;
      if (median !== prod.pages) {
        pages = median;
        mark("pages");
      }
    } else if (wikiFacts?.pageCount !== prod.pages) {
      pages = wikiFacts?.pageCount ?? null;
      mark("pages");
    }

    // Subtitle: dropped without a basis, since a book without one is complete.
    let subtitle: string | null = prod.subtitle;
    if (hand("subtitle")) {
      sources.add("hand-checked");
    } else if (prod.subtitle) {
      const openSubtitles = editionList.map((e) => e.subtitle).filter(Boolean) as string[];
      const inTitle = openTitles.some((t) => norm(t).includes(norm(prod.subtitle!)));
      if (!openSubtitles.some((s) => closeText(s, prod.subtitle)) && !inTitle) subtitle = null;
    }

    // Categories: the reviewed ones, otherwise classified again from open subjects.
    let categories = categoriesProd;
    if (!CATEGORY_OVERRIDES[id] && !hand("categories")) {
      const subjects = [...(work?.subjects ?? []), ...rows.flatMap((r) => r.categories)];
      categories = openCategories(subjects, prod.title, lb ?? {}, publisher);
      if (categories.length === 0 || categories[0] === "Lainnya") {
        categories = ["Lainnya"];
        mark("categories");
      }
    }

    if (needsCheck.length) count("partial");
    else if (hasOpen) count("clean: open library");
    else count("clean: wikipedia or hand");

    const coverId = lb?.cover?.provider === "openlibrary" ? coverIdOf(lb.cover.url) : null;
    out.push({
      id,
      title: prod.title,
      subtitle,
      authors,
      publisher,
      year,
      isbn13,
      pages,
      language: "id",
      categories,
      reviewed: true,
      needsCheck: [...new Set(needsCheck)],
      sources: [...sources],
      openLibrary: hasOpen ? {work: olKey(workKey), edition: olKey(edition?.key), coverId} : null,
    });
  }

  // ---- Tier 2: dropped from the app only because of its cover.
  const onlyCover = /^(tanpa cover|cover )|tidak ada cover|hanya di Wikipedia, tanpa cover/i;
  const takenIsbn = new Set(out.map((b) => b.isbn13).filter(Boolean));
  const takenKey = new Set(out.map((b) => bookKey(b.title, b.authors[0] ?? "")));
  const groups = new Map<string, Candidate[]>();
  for (const c of candidates) {
    if (c.source !== "openlibrary" || c.authors.length === 0) continue;
    const key = bookKey(cleanTitle(c.title), canonicalAuthor(c.authors[0]));
    groups.set(key, [...(groups.get(key) ?? []), c]);
  }
  const seen = new Set<string>();
  for (const row of rejected) {
    if (!onlyCover.test(row.reason) && !row.reason.includes("cover salah")) continue;
    if (row.id && REJECTED_BOOKS[row.id]) continue;
    const key = bookKey(row.title, row.authors[0] ?? "");
    if (seen.has(key) || takenKey.has(key)) continue;
    seen.add(key);
    const rows = groups.get(key);
    if (!rows) {
      count("tier2 skip: no open library row");
      continue;
    }
    // One edition's own facts, never a mix.
    const best = rows.find((r) => r.isbn13 && r.publisher && r.publishedYear && r.pageCount);
    if (!best || !isValidIsbn13(best.isbn13!)) {
      count("tier2 skip: incomplete edition");
      continue;
    }
    if (takenIsbn.has(best.isbn13!)) {
      count("tier2 skip: isbn already taken");
      continue;
    }
    const title = cleanTitle(best.title);
    if (looksEnglishTitle(title)) {
      count("tier2 skip: english title");
      continue;
    }
    const needsCheck: Field[] = [];
    const work = best.workKey ? works.get(best.workKey) : undefined;
    let pages: number | null = best.pageCount ?? null;
    if ((work?.editionCount ?? 1) > 1) {
      pages = await editionPages(best.sourceId);
      if (pages == null) needsCheck.push("pages");
    }
    const authors = [...new Set(best.authors.map(canonicalAuthor))].filter((n) => n.length >= 2).slice(0, 5);
    if ((work?.languages.length ?? 0) > 1 && (work?.editionCount ?? 1) > 1 && (work?.authors.length ?? 0) > 1) needsCheck.push("authors");
    const publisher = cleanPublisher(best.publisher);
    const subjects = rows.flatMap((r) => r.categories);
    let categories: string[] = CATEGORY_OVERRIDES[row.id ?? ""] ?? classify(subjects, title, best.seed.category as Category | undefined, !!best.seed.classic, publisher);
    if (categories.length === 0 || categories[0] === "Lainnya") {
      categories = ["Lainnya"];
      needsCheck.push("categories");
    }
    if (!publisher) needsCheck.push("publisher");
    takenIsbn.add(best.isbn13!);
    takenKey.add(key);
    out.push({
      id: row.id ?? `bk_${sha1(best.isbn13!).slice(0, 16)}`,
      title,
      subtitle: cleanSubtitle(best.subtitle, title),
      authors,
      publisher,
      year: best.publishedYear ?? null,
      isbn13: best.isbn13!,
      pages,
      language: "id",
      categories,
      reviewed: false,
      needsCheck,
      sources: ["open-library"],
      // Its cover was rejected, so no cover is linked.
      openLibrary: {work: olKey(best.workKey), edition: olKey(best.sourceId), coverId: null},
    });
    count("tier2");
  }

  writeFileSync(outFile, out.map((b) => JSON.stringify(b)).join("\n") + "\n");
  writeFileSync(reportFile, JSON.stringify({counts, held, needsCheck: out.filter((b) => b.needsCheck.length).length, total: out.length}, null, 1));
  console.log(counts);
  console.log(`Ditulis: ${out.length} buku, ${held.length} ditahan, dari ${snapshot.size} aktif`);
}

main().then(
  () => process.exit(0),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
