// Step 1b of the book import: Wikipedia articles for the seed titles.
//
//   npx tsx tools/books/wikipedia.ts
//
// For every seed title (seeds.ts SEED_TITLES and the novels found by wiki.ts)
// it finds the article on id.wikipedia, then en.wikipedia, and records:
//   - the lead image (MediaWiki pageimages, original size, any licence) as a
//     cover candidate: en.wikipedia often has first-edition covers of the
//     Indonesian classics that Open Library only holds as title-page scans;
//   - page count, publisher, year and ISBN from the infobox;
//   - a synopsis from the id.wikipedia plain-text extract ("Sinopsis",
//     "Alur", … or the lead), at most 1,200 characters.
// normalize.ts attaches these to the matching book, or creates the book from
// them when no Open Library/Google edition exists but the infobox gives the
// page count. Writes out/wiki-books.json; every response is cached.

import {resolve} from "node:path";

import {normalizeSearchText} from "../../src/domain/search";
import {OUT, authorMatches, getJson, isbnsOf, readJson, writeJson, yearOf} from "./common";
import {SEED_TITLES} from "./seeds";

export interface WikiBook {
  title: string;
  author: string;
  /** Page title the data came from, per language. */
  pages: {id?: string; en?: string};
  cover?: {url: string; lang: "id" | "en"; page: string; width: number; height: number};
  pageCount?: number;
  publisher?: string;
  publishedYear?: number;
  isbn13?: string;
  isbn10?: string;
  /** id.wikipedia only. */
  synopsis?: string;
}

interface Target {
  title: string;
  author: string;
  /** Catalog books without a synopsis: id.wikipedia only, no search. */
  synopsisOnly?: boolean;
  /** Known article titles, when the plain title is ambiguous. */
  id?: string;
  en?: string;
}

/** Must-have titles with article names that a plain lookup would miss. */
const HINTS: Target[] = [
  {title: "Sitti Nurbaya", author: "Marah Rusli", id: "Sitti Nurbaya", en: "Sitti Nurbaya"},
  {title: "Belenggu", author: "Armijn Pane", id: "Belenggu (novel)", en: "Belenggu"},
  {title: "Atheis", author: "Achdiat K. Mihardja", id: "Atheis (novel)", en: "Atheis"},
  {title: "Gadis Pantai", author: "Pramoedya Ananta Toer", id: "Gadis Pantai", en: "The Girl from the Coast"},
  {title: "Burung-Burung Manyar", author: "Y.B. Mangunwijaya", id: "Burung-Burung Manyar", en: "The Weaverbirds"},
  {title: "Rumah Kaca", author: "Pramoedya Ananta Toer", id: "Rumah Kaca (novel)", en: "House of Glass (novel)"},
  {title: "Jejak Langkah", author: "Pramoedya Ananta Toer", id: "Jejak Langkah", en: "Footsteps (Toer novel)"},
  {title: "Anak Semua Bangsa", author: "Pramoedya Ananta Toer", id: "Anak Semua Bangsa", en: "Child of All Nations"},
  {title: "Bumi Manusia", author: "Pramoedya Ananta Toer", id: "Bumi Manusia (novel)", en: "This Earth of Mankind"},
  {title: "Dian yang Tak Kunjung Padam", author: "Sutan Takdir Alisjahbana"},
  {title: "Dilan: Dia adalah Dilanku Tahun 1990", author: "Pidi Baiq"},
  {title: "Dilan: Dia adalah Dilanku Tahun 1991", author: "Pidi Baiq"},
  {title: "Milea: Suara dari Dilan", author: "Pidi Baiq"},
  {title: "Padang Bulan", author: "Andrea Hirata"},
  {title: "Habibie & Ainun", author: "B.J. Habibie", id: "Habibie & Ainun (buku)"},
  {title: "Totto-chan: Gadis Cilik di Jendela", author: "Tetsuko Kuroyanagi"},
  {title: "Supernova: Ksatria, Puteri, dan Bintang Jatuh", author: "Dee Lestari", id: "Supernova 1: Kesatria, Putri, & Bintang Jatuh"},
  {title: "Negeri 5 Menara", author: "Ahmad Fuadi", id: "Negeri 5 Menara"},
];

const API = (lang: string) => `https://${lang}.wikipedia.org/w/api.php`;

interface PageInfo {
  title: string;
  missing?: string;
  original?: {source: string; width: number; height: number};
  extract?: string;
  revisions?: {slots: {main: {"*": string}}}[];
}

async function pages(lang: "id" | "en", titles: string[]): Promise<PageInfo[]> {
  const url =
    `${API(lang)}?action=query&format=json&redirects=1&prop=pageimages|extracts|revisions` +
    `&piprop=original&pilicense=any&explaintext=1&exsectionformat=wiki&rvprop=content&rvslots=main` +
    `&titles=${encodeURIComponent(titles.join("|"))}`;
  const data = await getJson<{query?: {pages?: Record<string, PageInfo>}}>(url);
  return Object.values(data?.query?.pages ?? {}).filter((p) => p.missing === undefined);
}

async function search(lang: "id" | "en", query: string): Promise<string[]> {
  const url =
    `${API(lang)}?action=query&format=json&list=search&srlimit=4` +
    `&srsearch=${encodeURIComponent(query)}`;
  const data = await getJson<{query?: {search?: {title: string}[]}}>(url);
  return (data?.query?.search ?? []).map((s) => s.title);
}

const lastName = (author: string) => normalizeSearchText(author).split(" ").filter((w) => w.length > 2).pop() ?? "";

/**
 * The page is about this book: the title matches (or it is the hinted
 * article), it is not the author's or a film's article, and the text names
 * the author.
 */
function isAbout(page: PageInfo, target: Target, hinted: boolean): boolean {
  const pageTitle = normalizeSearchText(page.title.replace(/\s*\([^)]*\)$/, ""));
  const wanted = normalizeSearchText(target.title);
  const mainTitle = normalizeSearchText(target.title.split(":")[0]);
  const titleOk = hinted || pageTitle === wanted || pageTitle === mainTitle;
  if (!titleOk || pageTitle === normalizeSearchText(target.author)) return false;
  if (/\((film|seri|serial|sinetron|lagu|album)[^)]*\)$/i.test(page.title)) return false;
  const lead = (page.extract ?? "").slice(0, 400).toLowerCase();
  if (/\bfilm\b/.test(lead) && !/\b(novel|buku|book|roman|kumpulan)\b/.test(lead)) return false;
  // An article about the film or TV adaptation ("… adalah sebuah film drama
  // … yang diangkat dari novel …"): its image is a poster, its plot the film's.
  if (/\b(adalah|merupakan|is)\s+(sebuah\s+|a\s+|an\s+)?([\w-]+\s+){0,3}(film|sinetron|serial televisi|television series|drama televisi)\b/.test(lead)) {
    return false;
  }
  const wikitext = page.revisions?.[0]?.slots.main["*"] ?? "";
  if (/\{\{\s*(infobox|kotak info)\s+(film|television|televisi|acara televisi)/i.test(wikitext)) return false;
  const text = normalizeSearchText(`${page.extract?.slice(0, 3000) ?? ""} ${page.revisions?.[0]?.slots.main["*"].slice(0, 4000) ?? ""}`);
  const surname = lastName(target.author);
  return Boolean((surname && text.includes(surname)) || authorMatches(text, target.author));
}

async function find(lang: "id" | "en", target: Target): Promise<PageInfo | null> {
  // Full extracts come back for one page per request, so candidates are
  // checked one by one.
  const one = async (title: string) => (await pages(lang, [title]))[0];
  const hinted = lang === "id" ? target.id : target.en;
  const tries = hinted ? [hinted] : [target.title, `${target.title} (novel)`, `${target.title} (buku)`];
  for (const title of tries) {
    const page = await one(title);
    if (page && isAbout(page, target, !!hinted)) return page;
  }
  if (hinted || target.synopsisOnly) return null;
  for (const title of (await search(lang, `${target.title} ${target.author}`)).slice(0, 3)) {
    const page = await one(title);
    if (page && isAbout(page, target, false)) return page;
  }
  return null;
}

/** Value of an infobox field such as `| pages = 252`. */
function infobox(wikitext: string, keys: string[]): string | undefined {
  for (const key of keys) {
    const match = wikitext.match(new RegExp(`\\|\\s*${key}\\s*=\\s*([^\\n|]+)`, "i"));
    const value = match?.[1]
      ?.replace(/<ref[\s\S]*$/i, "")
      .replace(/\[\[(?:[^\]|]*\|)?([^\]]+)\]\]/g, "$1")
      .replace(/\{\{[^}]*\}\}/g, "")
      .replace(/'''?/g, "")
      .trim();
    if (value) return value;
  }
  return undefined;
}

const SYNOPSIS_SECTIONS = /^==+\s*(sinopsis|alur|alur cerita|ringkasan|ringkasan cerita|jalan cerita|cerita|isi|plot)\s*==+\s*$/im;

/** Plain text of the synopsis section, or of the lead, at most 1,200 characters. */
export function synopsisFrom(extract: string): string | undefined {
  let text: string | undefined;
  const match = extract.match(SYNOPSIS_SECTIONS);
  if (match && match.index !== undefined) {
    const rest = extract.slice(match.index + match[0].length);
    const next = rest.search(/^==[^=]/m);
    text = (next >= 0 ? rest.slice(0, next) : rest).replace(/^===.*===\s*$/gm, "");
  }
  if (!text || text.trim().length < 120) {
    const first = extract.search(/^==/m);
    text = first >= 0 ? extract.slice(0, first) : extract;
  }
  text = text.replace(/\n{2,}/g, "\n\n").replace(/[ \t]+/g, " ").trim();
  if (text.length < 80) return undefined;
  if (text.length > 1200) {
    const cut = text.slice(0, 1200);
    const end = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf(".\n"), cut.lastIndexOf("! "), cut.lastIndexOf("? "));
    text = end > 300 ? cut.slice(0, end + 1) : cut.slice(0, cut.lastIndexOf(" ")) + "…";
  }
  return text;
}

const IMAGE = /\.(jpe?g|png)(\?|$)/i;

async function main() {
  const wikiSeeds = readJson<{
    titles: {title: string; author: string; page?: string}[];
    enTitles?: {title: string; author: string; en: string}[];
  }>(resolve(OUT, "wiki-seeds.json"), {titles: []});
  const targets = new Map<string, Target>();
  const add = (target: Target) => {
    const key = `${normalizeSearchText(target.title)}|${normalizeSearchText(target.author)}`;
    targets.set(key, {...targets.get(key), ...target});
  };
  for (const seed of SEED_TITLES) add({title: seed.title, author: seed.author});
  for (const seed of wikiSeeds.titles) add({title: seed.title, author: seed.author, id: seed.page});
  for (const seed of wikiSeeds.enTitles ?? []) add({title: seed.title, author: seed.author, en: seed.en});
  for (const hint of HINTS) add(hint);
  // Every catalog book still without a synopsis (from the last normalize run):
  // an id.wikipedia article under its exact title may have one.
  for (const book of readJson<{title: string; authors: string[]; description: string | null}[]>(
    resolve(OUT, "books.json"),
    [],
  )) {
    if (book.description || !book.authors[0]) continue;
    const key = `${normalizeSearchText(book.title)}|${normalizeSearchText(book.authors[0])}`;
    if (!targets.has(key)) targets.set(key, {title: book.title, author: book.authors[0], synopsisOnly: true});
  }

  const results: WikiBook[] = [];
  for (const target of targets.values()) {
    const idPage = await find("id", target);
    const enPage = target.synopsisOnly ? null : await find("en", target);
    if (!idPage && !enPage) continue;
    // A synopsis-only lookup without a synopsis adds nothing.
    if (target.synopsisOnly && !idPage?.extract) continue;
    const record: WikiBook = {title: target.title, author: target.author, pages: {id: idPage?.title, en: enPage?.title}};
    for (const [lang, page] of [["id", idPage], ["en", enPage]] as const) {
      if (!page) continue;
      const image = page.original;
      if (!record.cover && image && IMAGE.test(image.source) && image.height > image.width) {
        record.cover = {url: image.source, lang, page: page.title, width: image.width, height: image.height};
      }
      const text = page.revisions?.[0]?.slots.main["*"] ?? "";
      const pagesValue = infobox(text, ["pages", "halaman", "jumlah halaman", "jumlah_halaman", "tebal"]);
      const count = Number(pagesValue?.match(/\d{2,4}/)?.[0]);
      if (!record.pageCount && count >= 10 && count <= 2000) record.pageCount = count;
      record.publisher ??= infobox(text, ["publisher", "penerbit"])?.slice(0, 120);
      record.publishedYear ??= yearOf(infobox(text, ["release_date", "pub_date", "tanggal_terbit", "tanggal terbit", "terbit", "published"])) ?? undefined;
      const isbn = isbnsOf([infobox(text, ["isbn"]) ?? ""]);
      record.isbn13 ??= isbn.isbn13 ?? undefined;
      record.isbn10 ??= isbn.isbn10 ?? undefined;
      if (lang === "id" && !record.synopsis && page.extract) record.synopsis = synopsisFrom(page.extract);
    }
    results.push(record);
  }

  const file = resolve(OUT, "wiki-books.json");
  writeJson(file, results);
  const withCover = results.filter((r) => r.cover).length;
  const withSynopsis = results.filter((r) => r.synopsis).length;
  console.log(
    `Wikipedia: ${results.length}/${targets.size} judul ditemukan, ${withCover} dengan gambar, ${withSynopsis} dengan sinopsis → ${file}`,
  );
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
