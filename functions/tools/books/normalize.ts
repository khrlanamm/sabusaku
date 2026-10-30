// Step 2 of the book import: merges the raw editions in out/candidates.json
// into one record per book, cleans and classifies them, and drops what does
// not belong in a reading catalog.
//
//   npx tsx tools/books/normalize.ts
//
// Writes out/books.json (kept) and out/rejected.json (dropped, with reason).

import {resolve} from "node:path";

import {BOOK_CATEGORIES, bookKey, normalizeSearchText} from "../../src/domain/search";
import {Candidate, OUT, authorMatches, properName, readJson, sha1, writeJson} from "./common";
import {SYNOPSES} from "./private-data";
import {AUTHOR_RENAMES, CATEGORY_OVERRIDES, CORRECTIONS, REJECTED_BOOKS, TITLE_RENAMES} from "./review";
import {Category, SEED_AUTHORS, SEED_TITLES} from "./seeds";
import {WikiBook} from "./wikipedia";

export type CoverProvider = "google" | "openlibrary" | "wikipedia";

export interface ImportBook {
  /** Subjects and categories from all sources, for classify(). */
  subjects?: string[];
  /** Seed category and era, for classify() after enrichment. */
  seedCategory?: Category;
  classic?: boolean;
  translated?: boolean;
  id: string;
  title: string;
  subtitle: string | null;
  authors: string[];
  publisher: string | null;
  publishedYear: number | null;
  isbn13: string | null;
  isbn10: string | null;
  pageCount: number;
  categories: Category[];
  description: string | null;
  language: "id";
  searchKey: string;
  /** Cover URLs to try, best first (covers.ts picks the first that works). */
  coverCandidates: {provider: CoverProvider; url: string; sourceId: string}[];
  /** Filled by covers.ts. */
  cover?: {provider: CoverProvider; url: string; sourceId: string; file: string};
  /** Where the synopsis came from. */
  descriptionSource: "google" | "openlibrary" | "wikipedia" | "review" | null;
  sources: {google?: string[]; openlibrary?: string[]};
  workKey?: string;
  seeds: string[];
  /** For capping prolific authors and ordering enrichment. */
  score: number;
}

interface Rejected {
  id?: string;
  title: string;
  authors: string[];
  reason: string;
}

// ---------------------------------------------------------------- cleaning

const EDITION_NOISE =
  /\s*[([](?:[^)\]]*\b(?:edisi|cetakan|cover|revisi|hard ?cover|soft ?cover|republish|terbaru|new|special|spesial|ed\.|reprint|bonus|ttd|ttd\.|signed|limited|paperback|novel)\b[^)\]]*)[)\]]\s*/gi;

export function cleanTitle(raw: string): string {
  let title = raw.replace(/\s+/g, " ").trim();
  title = title.replace(EDITION_NOISE, " ").trim();
  title = title.replace(/\s*\*\s*(hard|soft) ?cover\b.*$/i, "").trim();
  // "Pangeran Caspian (Prince Caspian)": the original title in brackets
  // after an Indonesian one.
  title = title.replace(/\s*\(([^()]+)\)\s*$/, (whole, inner: string) =>
    looksEnglishTitle(inner) || inner.includes("/") ? "" : whole,
  ).trim();
  // "Robohnya Surau Kami (2025)": a year in brackets is an edition artifact.
  title = title.replace(/\s*[([](1[89]\d\d|20\d\d)[)\]]\s*/g, " ").trim();
  title = title.replace(/\s+[-–]\s+(edisi|cover|cetakan)\b.*$/i, "").trim();
  title = title.replace(/^novel\s*[:\-–]?\s+/i, "").trim();
  title = title.replace(/\s*[:;,/=]\s*$/, "").trim();
  // "5 cm." → "5 cm"
  title = title.replace(/(\w{2,})\.$/u, "$1").trim();
  // "Bumi manusia : sebuah roman" → "Bumi manusia: sebuah roman"
  title = title.replace(/\s+:\s*/g, ": ");
  // Title Case only for ALL CAPS sources ("MUSLiM PRENEUR").
  const letters = title.replace(/[^\p{L}]/gu, "");
  const upper = letters.replace(/[^\p{Lu}]/gu, "").length;
  // Library catalogs use sentence case ("Gajah selalu ingat"); covers and
  // shops use title case, so every other title gets capitalized words too.
  title = letters.length > 3 && upper / letters.length >= 0.75 ? titleCase(title) : capitalizeWords(title);
  return TITLE_RENAMES[normalizeSearchText(title)] ?? title;
}

/**
 * A subtitle worth showing, or null: "Sebuah novel", "A novel", a bracketed
 * original title ("[Death in the clouds]") or a preview marker ("Part 1
 * [ Snackbook ]") say nothing about the book.
 */
export function cleanSubtitle(raw: string | null | undefined, title: string): string | null {
  if (!raw) return null;
  let subtitle = raw.replace(/\s+/g, " ").trim();
  if (/snackbook/i.test(subtitle) || /^[[(].*[\])]$/.test(subtitle)) return null;
  subtitle = subtitle.replace(/(?:^|[:;,]\s*)(?:sebuah|suatu|a)?\s*novel\.?$/i, "").trim();
  if (subtitle.length < 2 || normalizeSearchText(subtitle) === normalizeSearchText(title)) return null;
  return cleanTitle(subtitle).slice(0, 200) || null;
}

/** Main publisher of a co-publishing string; Gramedia spelled one way. */
export function cleanPublisher(raw: string | null | undefined): string | null {
  if (!raw) return null;
  let publisher = raw
    .replace(/\[\[(?:[^\]|]*\|)?([^\]]*)\]?\]?/g, "$1")
    .replace(/[[\]|]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  // Wikipedia infobox leftovers: "* Grasindo", "<small>Bandung: Truedee Books</small>".
  publisher = publisher
    .replace(/<small>\s*\([^)]*\)\s*<\/small>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/^[*•\s]+/, "")
    .replace(/^(?:jakarta|bandung|yogyakarta|surabaya|solo|depok|bogor)\s*:\s*/i, "")
    .replace(/^diterbitkan(?:\s+dan\s+didistribusikan)?\s+oleh\s+/i, "")
    .replace(/\s+/g, " ")
    .trim();
  publisher = publisher.split(/\s*(?:\bbekerja\s?sama\b|\bkerja\s?sama\b|\[dan\])/i)[0].trim();
  if (/^diterbitkan\b/i.test(publisher)) return null;
  if (/^gpu$/i.test(publisher)) publisher = "Gramedia Pustaka Utama";
  // One spelling per Gramedia imprint ("Penerbit PT Gramedia Pustaka Utama, Jakarta").
  if (/^(penerbit\s+)?(pt\.?\s+)?gramedia pustaka( utama)?\b/i.test(publisher)) publisher = "Gramedia Pustaka Utama";
  if (/^(kpg|kpk)\b.*kepustakaan populer|^kepustakaan populer gramedia|^kpg$/i.test(publisher)) {
    publisher = "KPG (Kepustakaan Populer Gramedia)";
  }
  publisher = publisher.replace(/[\s,;:.\-–]+$/, "").trim();
  return publisher.length >= 2 ? publisher.slice(0, 120) : null;
}

const SMALL = new Set([
  "dan", "di", "ke", "dari", "yang", "untuk", "pada", "dalam", "dengan", "bagi", "oleh", "tentang", "kepada", "atau",
  "of", "the", "and", "a", "an", "in", "on", "to", "for", "at", "by", "with", "&",
  // Particles, name links and units: "Allah pun Gembira", "Ali bin Abi Thalib", "5 cm".
  "pun", "bin", "binti", "ibn", "cm", "km", "kg", "vs",
]);

/**
 * Title case that keeps the capitals already there ("K.H.", "PKB", "iPhone"
 * stay): lowercase words get a capital first letter, except the small words
 * of SMALL inside the title, unless they follow a colon.
 */
function capitalizeWords(text: string): string {
  const words = text.split(" ");
  return words
    .map((word, i) => {
      const afterColon = i > 0 && /[:.!?]$/.test(words[i - 1]);
      return word
        .split("-")
        .map((part, j) => {
          const small = (i > 0 || j > 0) && !afterColon && SMALL.has(part);
          if (small || part !== part.toLowerCase()) return part;
          return part.replace(/^(["'(]*)(\p{L})/u, (_, lead: string, letter: string) => lead + letter.toUpperCase());
        })
        .join("-");
    })
    .join(" ");
}

function titleCase(text: string): string {
  return text
    .toLowerCase()
    .split(" ")
    .map((word, i) => {
      if (i > 0 && SMALL.has(word)) return word;
      // Keep roman numerals readable: "ii" → "II".
      if (/^(i{1,3}|iv|v|vi{1,3}|ix|x)$/.test(word) && i > 0) return word.toUpperCase();
      // "ke-deli" → "ke-Deli", "burung-burung" → "Burung-Burung".
      return word
        .split("-")
        .map((part, j) =>
          (i > 0 || j > 0) && j === 0 && SMALL.has(part)
            ? part
            : part.replace(/^(["'(]*)(\p{L})/u, (_, lead: string, letter: string) => lead + letter.toUpperCase()),
        )
        .join("-");
    })
    .join(" ");
}

/** Plain text, no HTML, at most 2000 characters ending on a sentence. */
export function cleanDescription(raw: string | null | undefined): string | null {
  if (!raw) return null;
  let text = raw
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&rsquo;|&lsquo;/g, "'")
    .replace(/&ldquo;|&rdquo;/g, '"')
    .replace(/&[a-z]+;/g, " ")
    .replace(/``|''/g, '"')
    .replace(/"{2,}/g, '"')
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  if (text.length < 40) return null;
  // A Wikipedia disambiguation page, not a synopsis.
  if (/dapat merujuk pada|may refer to/i.test(text)) return null;
  // Mojibake (UTF-8 read as Latin-1) or a store's menu text pasted into a word.
  if (/[ÃÌ][\u0080-\u00ff]|åÉ|â€|\wManga, Manhua & Manhwa/.test(text)) return null;
  if (text.length > 2000) {
    const cut = text.slice(0, 2000);
    const end = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf(".\n"), cut.lastIndexOf("! "), cut.lastIndexOf("? "));
    text = end > 800 ? cut.slice(0, end + 1) : `${cut.slice(0, 1997).trimEnd()}…`;
  }
  return text;
}

// ------------------------------------------------------------ classifying

const CATEGORY_RULES: [RegExp, Category][] = [
  [/comic|graphic novel|manga|komik/i, "Komik"],
  [/poetry|poems|puisi|sajak|syair/i, "Puisi"],
  [/short stor|cerpen|cerita pendek/i, "Kumpulan Cerpen"],
  [/young adult|teen|remaja|teenlit/i, "Remaja"],
  [/juvenile|children|anak-anak|picture book|cerita anak/i, "Anak"],
  [/biograph|autobiograph|memoir|riwayat hidup/i, "Biografi"],
  [/history|sejarah|historical/i, "Sejarah"],
  [/islam|religio|qur'?an|hadith|hadis|tasawuf|tafsir|christian|bible|agama|fiqih|fikih|doa|sholat|shalat/i, "Agama"],
  [/self-help|self help|success|motivat|personal growth|psychology|psikologi|pengembangan diri|parenting|happiness/i, "Pengembangan Diri"],
  [/business|economic|finance|management|marketing|entrepreneur|bisnis|keuangan|investasi|wirausaha/i, "Bisnis"],
  [/political science|social science|politics|sociology|\blaw\b|education|philosophy|filsafat|politik|sosial|culture|anthropolog|essays|esai/i, "Nonfiksi Umum"],
  [/science|physics|chemistry|biology|astronomy|mathemat|technology|nature|sains|fisika|matematika|alam semesta/i, "Sains"],
  [/fiction|novel|roman|fiksi|romance|fantasy|mystery|thriller|detective|horror|love stories/i, "Novel"],
];

/** Weaker title cues, used only when nothing else classifies a book. */
const TITLE_CUES: [RegExp, Category][] = [
  [/\b(muslim|muslimah|islam|rasul|rasulullah|nabi|allah|sahabat|akhlak|adab|syariah|fiqih|fikih|hadits?|sunnah|ramadhan|iman|takwa|zakat|haji|dzikir|hijrah|tauhid|aqidah|sirah|alaihissalam|surga|al-quran|quran|ibadah|dakwah|ulama)\b/i, "Agama"],
  [/\b(yesus|kristus|alkitab|injil|gereja|katolik|santo|santa|doa rosario)\b/i, "Agama"],
  [/\b(revolusi|perang|kerajaan|kemerdekaan|pahlawan|proklamasi|kolonial|majapahit|sriwijaya|mataram|g30s|1965|reformasi)\b/i, "Sejarah"],
  [/\b(fisika|kimia|biologi|astronomi|matematika|sains|alam semesta|teknologi|evolusi|otak|tubuh manusia|kesehatan)\b/i, "Sains"],
  [/\b(bisnis|manajemen|pemasaran|ekonomi|wirausaha|investasi|keuangan|marketing|kepemimpinan|leadership|perusahaan|uang)\b/i, "Bisnis"],
  [/\b(sukses|motivasi|kebiasaan|bahagia|kebahagiaan|karier|percaya diri|kepribadian|inspirasi|hidup lebih)\b/i, "Pengembangan Diri"],
  [/\b(roman|novel|kisah|cinta|misteri|detektif)\b/i, "Novel"],
  [/\b(anak|bocah|kancil)\b/i, "Anak"],
];

/** Publishers that mostly publish one kind of book. */
const PUBLISHER_DEFAULTS: [RegExp, Category][] = [
  [/gema insani|pro-?u media|zikrul hakim|darul haq|pustaka al-kautsar/i, "Agama"],
  [/lingkar pena|gagas ?media|bukune|haru|bentang belia/i, "Novel"],
  [/kanisius|obor|kompas|grafiti|lp3es|ombak/i, "Nonfiksi Umum"],
];

const NONFICTION: Category[] = ["Sejarah", "Biografi", "Agama", "Pengembangan Diri", "Bisnis", "Sains", "Nonfiksi Umum"];

export function classify(
  subjects: string[],
  title: string,
  seedCategory: Category | undefined,
  classic: boolean,
  publisher?: string | null,
): Category[] {
  const found: Category[] = [];
  const push = (category: Category) => {
    if (!found.includes(category)) found.push(category);
  };
  // Strong title signals win over the author's usual category.
  if (/\b(kumpulan )?(puisi|sajak)\b/i.test(title)) push("Puisi");
  if (/\b(kumpulan )?cerpen\b|cerita pendek/i.test(title)) push("Kumpulan Cerpen");
  if (/\b(tafsir|tasawuf|islam|al-?qur'?an|hadis|hadits|doa|sholat|shalat|akhlak|aqidah)\b/i.test(title)) push("Agama");
  if (/\bsejarah\b/i.test(title)) push("Sejarah");
  if (/\bbiografi\b|\bmemoar\b|\botobiografi\b|riwayat hidup|kisah hidup|perjalanan hidup/i.test(title)) push("Biografi");
  if (/\b(dongeng|cerita rakyat|fabel|si kancil)\b/i.test(title)) push("Anak");

  const mapped: Category[] = [];
  for (const subject of subjects) {
    for (const [pattern, category] of CATEGORY_RULES) {
      if (pattern.test(subject) && !mapped.includes(category)) mapped.push(category);
    }
  }

  let primary = seedCategory;
  const fiction = mapped.includes("Novel") || mapped.includes("Kumpulan Cerpen") || mapped.includes("Remaja");
  if (classic && primary && !NONFICTION.includes(primary) && (fiction || mapped.length === 0) && found.length === 0) {
    primary = "Sastra Klasik";
  }
  // A nonfiction author's novel, or a novelist's essay collection.
  if (primary && found.length === 0 && mapped.length > 0) {
    const primaryIsFiction = !NONFICTION.includes(primary);
    const mappedFiction = fiction;
    if (primaryIsFiction !== mappedFiction && mapped[0] !== "Novel") primary = mapped[0];
  }
  if (primary) push(primary);
  for (const category of mapped) push(category);
  if (found.length === 0) {
    for (const [pattern, category] of TITLE_CUES) if (pattern.test(title)) push(category);
  }
  if (found.length === 0 && publisher && /elex media/i.test(publisher) && /\b\d+$|vol\.?\s*\d+|komik/i.test(title)) {
    push("Komik");
  }
  if (found.length === 0 && publisher) {
    const fallback = PUBLISHER_DEFAULTS.find(([pattern]) => pattern.test(publisher))?.[1];
    if (fallback) push(fallback);
  }
  if (found.length === 0) push("Lainnya");
  return found.filter((c) => (BOOK_CATEGORIES as readonly string[]).includes(c)).slice(0, 3);
}

export const googleIsbnCover = (isbn: string) =>
  `https://books.google.com/books/content?vid=ISBN${isbn}&printsec=frontcover&img=1&zoom=1`;

/** Per-author limits for authors outside the seed list. */
const AUTHOR_CAPS: Record<string, number> = {"Tim Buku Tempo": 25};

/** The reviewed categories when there are any, otherwise classify(). */
export function categoriesFor(book: ImportBook): Category[] {
  return (
    CATEGORY_OVERRIDES[book.id] ??
    classify(book.subjects ?? [], book.title, book.seedCategory, !!book.classic, book.publisher)
  );
}

const EN_TITLE_WORDS = /\b(the|and|of|for|with|from|your|you|how|what|why|to)\b/gi;
const ID_TITLE_WORDS = /\b(dan|di|ke|dari|yang|untuk|dengan|para|sang|si|kisah|cerita)\b/gi;

/** "Harry Potter and the Order of the Phoenix" reads English, "… dan Orde Phoenix" not. */
export function looksEnglishTitle(title: string): boolean {
  const en = title.match(EN_TITLE_WORDS)?.length ?? 0;
  const id = title.match(ID_TITLE_WORDS)?.length ?? 0;
  return en >= 1 && id === 0;
}

// ---------------------------------------------------------------- filters

/**
 * Things that are not books to read through: exam drills and school
 * workbooks, reference works, periodicals, theses, sets and summaries,
 * legal texts and English editions. Since 30 Oct 2026 the user wants every
 * other book in the catalog, adult, political, academic and technical ones
 * included, so only these and incomplete records are filtered.
 */
const NOT_READING = new RegExp(
  [
    "\\bsoal\\b", "latihan soal", "\\bujian\\b", "\\butbk\\b", "\\bsbmptn\\b", "\\bcpns\\b", "kunci jawaban",
    "\\blks\\b", "\\bmodul\\b", "bahan ajar", "\\bdiktat\\b", "kurikulum", "buku siswa", "buku guru", "\\bkamus\\b", "ensiklopedi",
    "majalah", "katalog", "prosiding", "skripsi", "\\btesis\\b", "\\bjurnal\\b(?! (harian|kecil))",
    "\\bpaket\\b", "box ?set", "boxset", "bundle", "\\bringkasan\\b", "sinopsis",
    "bahasa indonesia (untuk|kelas|smp|sma)", "kelas (x|xi|xii|[1-9])\\b", "\\bsma\\b", "\\bsmp\\b", "panduan (guru|belajar)",
    "english edition", "edisi bahasa inggris", "^index\\b", "^indeks\\b", "bibliografi",
    "\\bundang-undang\\b", "peraturan", "\\bdirektori\\b", "\\batlas\\b", "\\balmanak\\b",
  ].join("|"),
  "i",
);

/** Publishers of English editions that Open Library sometimes tags Indonesian. */
const FOREIGN_PUBLISHER =
  /penguin|hyperion|random house|harper|knopf|vintage|picador|bloomsbury|scholastic|puffin|macmillan|simon (&|and) schuster|hachette|oxford university|cambridge university|routledge|brill|springer|grove|norton|doubleday|bantam|little,? brown|faber|allen & unwin|tuttle|equinox|lontar foundation|cornell/i;


function rejectReason(book: ImportBook): string | null {
  if (REJECTED_BOOKS[book.id]) return `tinjauan: ${REJECTED_BOOKS[book.id]}`;
  if (book.title.length < 2 || book.title.length > 200) return "judul tidak valid";
  if (book.authors.length === 0) return "tanpa penulis";
  if (book.authors.length > 5) return "antologi banyak penulis";
  if (NOT_READING.test(`${book.title} ${book.subtitle ?? ""}`)) return "bukan bacaan (soal/LKS/kamus/katalog/majalah/paket)";
  if (book.publisher && FOREIGN_PUBLISHER.test(book.publisher)) return "edisi bahasa asing";
  if (/[\u3000-\u9fff\uac00-\ud7af\u0400-\u04ff]/.test(book.authors.join(" "))) return "nama penulis bukan huruf Latin";
  // A missing page count may still be found by enrich.ts.
  if (book.pageCount && (book.pageCount < 10 || book.pageCount > 2000)) return "jumlah halaman di luar 10–2000";
  if (book.coverCandidates.length === 0) return "tanpa cover";
  return null;
}

/**
 * A Wikipedia image can stand for the Indonesian edition: always for an
 * Indonesian original; for a translation only when it comes from an
 * id.wikipedia article with an Indonesian title (en.wikipedia shows the
 * original edition).
 */
function wikiCoverFits(wiki: WikiBook, translated: boolean): boolean {
  if (!wiki.cover) return false;
  if (!translated) return true;
  const file = decodeURIComponent(wiki.cover.url.split("/").pop()?.split("?")[0] ?? "").replace(/[_-]+/g, " ");
  return wiki.cover.lang === "id" && !looksEnglishTitle(wiki.cover.page) && !looksEnglishTitle(file);
}

/** Infobox facts describe the original edition for a translated book. */
function wikiFacts(wiki: WikiBook | undefined, translated: boolean): Partial<WikiBook> {
  if (!wiki || translated) return {};
  return {publisher: wiki.publisher, publishedYear: wiki.publishedYear, isbn13: wiki.isbn13, isbn10: wiki.isbn10};
}

// ------------------------------------------------------------------ merge

const seedAuthorNames = SEED_AUTHORS.map((a) => ({canonical: a.name, aliases: a.aliases ?? [], max: a.max ?? 25, classic: !!a.classic, translated: !!a.translated, category: a.category}));

/** "Toer, Pramoedya Ananta" → "Pramoedya Ananta Toer"; drops a trailing dot. */
function tidyName(raw: string): string {
  let name = raw
    .replace(/\s+/g, " ")
    .replace(/\s*[-–]\s*undifferentiated\b.*$/i, "")
    .replace(/\s*[([](author|editor|ed\.|penulis|penyunting|et al\.?)[)\]]/gi, "")
    .trim()
    .replace(/[,;]$/, "");
  if (/\w{3,}\.$/.test(name)) name = name.slice(0, -1);
  const parts = name.split(", ");
  if (parts.length === 2 && !/\d/.test(name) && !/\b(S\.|M\.|Dr|Prof|Ir|H\.)/.test(parts[1])) {
    name = `${parts[1]} ${parts[0]}`;
  }
  return properName(name);
}

export function canonicalAuthor(name: string): string {
  const seed = seedAuthorNames.find((s) => authorMatches(name, s.canonical, s.aliases));
  if (seed) return seed.canonical;
  const tidy = tidyName(name);
  return AUTHOR_RENAMES[tidy] ?? AUTHOR_RENAMES[normalizeSearchText(tidy)] ?? tidy;
}

function seedFor(name: string) {
  return seedAuthorNames.find((s) => authorMatches(name, s.canonical, s.aliases));
}

function editionScore(c: Candidate): number {
  return (
    (c.coverUrl ? 8 : 0) +
    (c.pageCount ? 4 : 0) +
    (c.isbn13 ? 2 : 0) +
    (c.publisher ? 1 : 0) +
    (c.description ? 1 : 0) +
    (c.source === "openlibrary" ? 0.5 : 0) -
    // The Indonesian edition's title wins over an English one of the same work.
    (looksEnglishTitle(c.title) ? 9 : 0)
  );
}

function main() {
  const candidates = readJson<Candidate[]>(resolve(OUT, "candidates.json"), []);
  const titleSeedCategory = new Map(
    SEED_TITLES.map((s) => [bookKey(cleanTitle(s.title), canonicalAuthor(s.author)), s.category]),
  );

  // Group editions by cleaned title + canonical first author.
  const groups = new Map<string, Candidate[]>();
  for (const c of candidates) {
    const title = cleanTitle(c.title);
    if (!title || c.authors.length === 0) continue;
    const firstAuthor = canonicalAuthor(c.authors[0]);
    const key = bookKey(title, firstAuthor);
    const list = groups.get(key) ?? [];
    list.push({...c, title, authors: [firstAuthor, ...c.authors.slice(1).map(canonicalAuthor)]});
    groups.set(key, list);
  }

  // "Bumi Manusia" and "Bumi Manusia: Sebuah Roman" by the same author are
  // one book, unless several longer titles share the short one (a series).
  const keys = [...groups.keys()];
  const byAuthor = new Map<string, string[]>();
  for (const key of keys) {
    const author = key.split("|")[1];
    byAuthor.set(author, [...(byAuthor.get(author) ?? []), key]);
  }
  for (const authorKeys of byAuthor.values()) {
    for (const short of authorKeys) {
      if (!groups.has(short)) continue;
      const shortTitle = short.split("|")[0];
      const longer = authorKeys.filter(
        (k) => k !== short && groups.has(k) && k.split("|")[0].startsWith(`${shortTitle} `),
      );
      const rawLong = longer.filter((k) => {
        const sample = groups.get(k)![0];
        return /[:–-]/.test(sample.title) || sample.subtitle;
      });
      if (rawLong.length === 1) {
        groups.set(short, [...groups.get(short)!, ...groups.get(rawLong[0])!]);
        groups.delete(rawLong[0]);
      }
    }
  }

  // Editions of one Open Library work under different titles (the English
  // original and the Indonesian translation) are one book.
  const byWork = new Map<string, string[]>();
  for (const [key, editions] of groups) {
    for (const workKey of new Set(editions.map((c) => c.workKey).filter((w): w is string => !!w))) {
      byWork.set(workKey, [...(byWork.get(workKey) ?? []), key]);
    }
  }
  for (const keysOfWork of byWork.values()) {
    const alive = [...new Set(keysOfWork)].filter((k) => groups.has(k));
    if (alive.length < 2) continue;
    const sameAuthor = new Set(alive.map((k) => k.split("|")[1])).size === 1;
    if (!sameAuthor) continue;
    const [primary, ...others] = alive.sort(
      (x, y) => Number(looksEnglishTitle(groups.get(x)![0].title)) - Number(looksEnglishTitle(groups.get(y)![0].title)),
    );
    for (const other of others) {
      groups.set(primary, [...groups.get(primary)!, ...groups.get(other)!]);
      groups.delete(other);
    }
  }

  // Wikipedia articles (wikipedia.ts), merged per book.
  const wikiByKey = new Map<string, WikiBook>();
  for (const record of readJson<WikiBook[]>(resolve(OUT, "wiki-books.json"), [])) {
    const key = bookKey(cleanTitle(record.title), canonicalAuthor(record.author));
    const known = wikiByKey.get(key);
    wikiByKey.set(key, known ? {...record, ...known, cover: known.cover ?? record.cover, synopsis: known.synopsis ?? record.synopsis, pageCount: known.pageCount ?? record.pageCount} : record);
  }
  const wikiFor = (key: string): WikiBook | undefined => {
    if (wikiByKey.has(key)) return wikiByKey.get(key);
    return undefined;
  };
  // A Wikipedia article whose title carries a subtitle the editions lack.
  for (const [key, record] of [...wikiByKey]) {
    if (groups.has(key)) continue;
    const author = key.split("|")[1];
    const main = normalizeSearchText(cleanTitle(record.title).split(":")[0]);
    const candidates = [...groups.keys()].filter((k) => k.split("|")[1] === author && k.split("|")[0] === main);
    if (candidates.length === 1) {
      wikiByKey.set(candidates[0], record);
      wikiByKey.delete(key);
    }
  }
  const usedWiki = new Set<string>();

  // One spelling per publisher: the most frequent one ("Bhuana Ilmu Populer"
  // over "Bhuana Ilmu populer").
  const spellings = new Map<string, Map<string, number>>();
  for (const c of candidates) {
    const publisher = cleanPublisher(c.publisher);
    if (!publisher) continue;
    const key = normalizeSearchText(publisher);
    const counts = spellings.get(key) ?? new Map<string, number>();
    counts.set(publisher, (counts.get(publisher) ?? 0) + 1);
    spellings.set(key, counts);
  }
  const publisherSpelling = (raw: string | null | undefined): string | null => {
    const publisher = cleanPublisher(raw);
    if (!publisher) return null;
    const counts = spellings.get(normalizeSearchText(publisher));
    return counts ? [...counts.entries()].sort((x, y) => y[1] - x[1])[0][0] : publisher;
  };

  const books: ImportBook[] = [];
  const rejected: Rejected[] = [];
  for (const [key, editions] of groups) {
    editions.sort((x, y) => editionScore(y) - editionScore(x));
    const best = editions[0];
    const any = <T>(pick: (c: Candidate) => T | null | undefined): T | null => {
      for (const c of editions) {
        const value = pick(c);
        if (value != null && value !== "") return value;
      }
      return null;
    };
    const firstAuthor = best.authors[0];
    const seed = seedFor(firstAuthor);
    const authors = [...new Set(best.authors.map((n) => n.trim()).filter((n) => n.length >= 2))].slice(0, 6);
    const described = editions
      .map((c) => ({text: cleanDescription(c.description), source: c.source}))
      .filter((d): d is {text: string; source: Candidate["source"]} => !!d.text)
      .sort((x, y) => y.text.length - x.text.length)[0];
    const wiki = wikiFor(key);
    if (wiki) usedWiki.add(key);
    const subjects = editions.flatMap((c) => c.categories);
    const seedCategory = (titleSeedCategory.get(key) ?? seed?.category ?? editions.find((c) => c.seed.category)?.seed.category) as Category | undefined;
    const classic = seed?.classic ?? editions.some((c) => c.seed.classic);
    const translatedBook = seed?.translated ?? editions.some((c) => c.seed.translated);
    const facts = wikiFacts(wiki, translatedBook);
    // Google sometimes reports the preview length; a count under half of
    // what another source says is not trusted.
    const otherPages = [
      ...editions.filter((c) => c.source !== "google").map((c) => c.pageCount),
      translatedBook ? null : wiki?.pageCount,
    ].filter((n): n is number => !!n);
    const bestPages =
      best.source === "google" && best.pageCount && otherPages.some((n) => best.pageCount! < n / 2)
        ? Math.max(...otherPages)
        : best.pageCount;
    const pageCount = bestPages ?? any((c) => c.pageCount) ?? (translatedBook ? null : wiki?.pageCount) ?? null;
    const coverCandidates: ImportBook["coverCandidates"] = editions
      .filter((c) => c.coverUrl)
      .map((c) => ({provider: c.source, url: c.coverUrl!, sourceId: c.sourceId}));
    // The article's image comes last: an edition's own photo is preferred,
    // the Wikipedia cover replaces title-page scans and missing covers.
    if (wiki?.cover && wikiCoverFits(wiki, seed?.translated ?? editions.some((c) => c.seed.translated))) {
      coverCandidates.push({provider: "wikipedia", url: wiki.cover.url, sourceId: wiki.cover.page});
    }
    // Last resort for curated books: Google's public cover image looked up by
    // ISBN (no API quota). It shows the current Indonesian edition, 128 px wide.
    const curated = !!seed || editions.some((c) => c.seed.kind === "title" || c.seed.kind === "author") || !!wiki;
    if (curated) {
      const isbns = [...new Set(editions.flatMap((c) => [c.isbn13, c.isbn10]).filter((v): v is string => !!v))];
      for (const isbn of isbns.slice(0, 3)) {
        coverCandidates.push({provider: "google", url: googleIsbnCover(isbn), sourceId: `ISBN${isbn}`});
      }
    }
    const isbn13 = best.isbn13 ?? any((c) => c.isbn13) ?? facts.isbn13 ?? null;
    // Library catalogues write "Salah asuhan"; the article, the seed list or
    // a Google edition usually has the cover spelling.
    const sameTitle = (other: string) => normalizeSearchText(other) === normalizeSearchText(best.title);
    const seedTitle = SEED_TITLES.find((t) => sameTitle(cleanTitle(t.title)) && authorMatches(firstAuthor, t.author))?.title;
    const wikiTitle = wiki && sameTitle(cleanTitle(wiki.title)) ? cleanTitle(wiki.title) : undefined;
    const googleTitle = editions.find((c) => c.source === "google" && sameTitle(c.title))?.title;
    const shownTitle = seedTitle ? cleanTitle(seedTitle) : wikiTitle ?? googleTitle ?? best.title;
    // A translation's original title in brackets: "Benang Merah (A Study in Scarlet)".
    const stripped = translatedBook
      ? shownTitle.replace(/\s*\(([^()]+)\)\s*$/, (whole, inner: string) =>
          new RegExp(ID_TITLE_WORDS.source, "i").test(inner) ? whole : "",
        )
      : shownTitle;
    const title = stripped.length > 200 ? stripped.slice(0, 200) : stripped;
    const searchKey = bookKey(title, authors[0] ?? "");
    const book: ImportBook = {
      id: `bk_${sha1(isbn13 ?? searchKey).slice(0, 16)}`,
      title,
      subtitle: cleanSubtitle(best.subtitle, title),
      authors: authors.slice(0, 5),
      publisher: publisherSpelling(best.publisher ?? any((c) => c.publisher) ?? facts.publisher),
      publishedYear: best.publishedYear ?? any((c) => c.publishedYear) ?? facts.publishedYear ?? null,
      isbn13,
      isbn10: best.isbn10 ?? any((c) => c.isbn10) ?? facts.isbn10 ?? null,
      pageCount: pageCount ?? 0,
      categories: [],
      description: described?.text ?? wiki?.synopsis ?? null,
      descriptionSource: described ? described.source : wiki?.synopsis ? "wikipedia" : null,
      language: "id",
      searchKey,
      coverCandidates,
      sources: {
        google: editions.filter((c) => c.source === "google").map((c) => c.sourceId),
        openlibrary: editions.filter((c) => c.source === "openlibrary").map((c) => c.sourceId),
      },
      workKey: editions.find((c) => c.workKey)?.workKey,
      seeds: [...new Set([...editions.map((c) => c.seed.name), ...(wiki ? [`wikipedia: ${wiki.pages.id ?? wiki.pages.en}`] : [])])],
      subjects: [...new Set(subjects)].slice(0, 30),
      seedCategory,
      classic,
      translated: seed?.translated ?? editions.some((c) => c.seed.translated),
      score:
        editionScore(best) +
        editions.length +
        (editions.some((c) => c.seed.kind === "title") ? 20 : 0) +
        (best.publishedYear && best.publishedYear >= 2005 ? 1 : 0),
    };
    if (book.publishedYear != null && (book.publishedYear < 1800 || book.publishedYear > 2100)) book.publishedYear = null;
    book.categories = categoriesFor(book);
    const reason = rejectReason(book);
    if (reason) rejected.push({id: book.id, title: book.title, authors: book.authors, reason});
    else books.push(book);
  }

  // Books known only from Wikipedia: kept when the infobox gives the page
  // count and the article has a cover.
  for (const [key, wiki] of wikiByKey) {
    if (usedWiki.has(key) || groups.has(key)) continue;
    const title = cleanTitle(wiki.title);
    const author = canonicalAuthor(wiki.author);
    if (seedFor(author)?.translated && !wikiCoverFits(wiki, true)) {
      rejected.push({title, authors: [author], reason: "hanya edisi asli di Wikipedia, tanpa data edisi Indonesia"});
      continue;
    }
    if (!wiki.pageCount || !wiki.cover) {
      rejected.push({title, authors: [author], reason: `hanya di Wikipedia, tanpa ${wiki.pageCount ? "cover" : "jumlah halaman"}`});
      continue;
    }
    const seed = seedFor(author);
    const searchKey = bookKey(title, author);
    const facts = wikiFacts(wiki, !!seed?.translated);
    const book: ImportBook = {
      id: `bk_${sha1(facts.isbn13 ?? searchKey).slice(0, 16)}`,
      title,
      subtitle: null,
      authors: [author],
      publisher: cleanPublisher(facts.publisher),
      publishedYear: facts.publishedYear ?? null,
      isbn13: facts.isbn13 ?? null,
      isbn10: facts.isbn10 ?? null,
      pageCount: wiki.pageCount,
      categories: [],
      description: wiki.synopsis ?? null,
      descriptionSource: wiki.synopsis ? "wikipedia" : null,
      language: "id",
      searchKey,
      coverCandidates: [{provider: "wikipedia", url: wiki.cover.url, sourceId: wiki.cover.page}],
      sources: {},
      seeds: [`${wiki.title} — ${wiki.author}`, `wikipedia: ${wiki.pages.id ?? wiki.pages.en}`],
      subjects: [],
      seedCategory: (titleSeedCategory.get(key) ?? seed?.category) as Category | undefined,
      classic: seed?.classic ?? false,
      translated: seed?.translated ?? false,
      score: 30,
    };
    book.categories = categoriesFor(book);
    const reason = rejectReason(book);
    if (reason) rejected.push({title, authors: [author], reason});
    else books.push(book);
  }

  // ISBN collisions between different keys: keep the better one.
  const byId = new Map<string, ImportBook>();
  for (const book of books.sort((x, y) => y.score - x.score)) {
    const other = byId.get(book.id);
    if (other && normalizeSearchText(other.title) !== normalizeSearchText(book.title)) {
      // Two different titles share an ISBN (a two-in-one edition, or a
      // wrong record): the second keeps its title-based ID and drops the ISBN.
      book.isbn13 = null;
      book.id = `bk_${sha1(book.searchKey).slice(0, 16)}`;
    }
    if (byId.has(book.id)) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: "duplikat ISBN"});
      continue;
    }
    // The ID may have changed above; reviewed decisions apply to the new one.
    if (REJECTED_BOOKS[book.id]) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: `tinjauan: ${REJECTED_BOOKS[book.id]}`});
      continue;
    }
    byId.set(book.id, book);
  }

  // Cap prolific authors so the catalog stays varied.
  const kept: ImportBook[] = [];
  const count = new Map<string, number>();
  for (const book of byId.values()) {
    const seed = seedFor(book.authors[0]);
    const max = seed?.max ?? AUTHOR_CAPS[book.authors[0]] ?? 12;
    const n = count.get(book.authors[0]) ?? 0;
    if (n >= max && !book.seeds.some((s) => s.includes(" — "))) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: `melebihi batas ${max} buku per penulis`});
      continue;
    }
    count.set(book.authors[0], n + 1);
    kept.push(book);
  }

  for (const book of kept) {
    if (!book.description && SYNOPSES[book.id]) {
      book.description = SYNOPSES[book.id];
      book.descriptionSource = "review";
    }
    const correction = CORRECTIONS[book.id];
    if (!correction) continue;
    Object.assign(book, correction);
    if (correction.title) book.searchKey = bookKey(book.title, book.authors[0] ?? "");
    if (correction.description !== undefined) book.descriptionSource = correction.description ? "review" : null;
  }

  kept.sort((x, y) => x.title.localeCompare(y.title, "id"));
  writeJson(resolve(OUT, "books.json"), kept);
  writeJson(resolve(OUT, "rejected.json"), rejected);
  const reasons = rejected.reduce<Record<string, number>>((acc, r) => {
    acc[r.reason] = (acc[r.reason] ?? 0) + 1;
    return acc;
  }, {});
  console.log(`Buku: ${kept.length} dari ${groups.size} grup (${candidates.length} edisi). Ditolak:`, reasons);
}

if (require.main === module) main();
