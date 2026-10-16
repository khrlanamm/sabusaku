// Shared helpers of the book catalog import (functions/tools/books/).
//
// Every HTTP response is cached under out/cache/, keyed by URL, so a rerun
// of any step costs no API quota. Google Books allows 1,000 queries a day per
// project; the counter in out/quota-google.json stops the run before that.

import {createHash} from "node:crypto";
import {existsSync, mkdirSync, readFileSync, writeFileSync} from "node:fs";
import {dirname, resolve} from "node:path";

import {normalizeSearchText} from "../../src/domain/search";

export const OUT = resolve(__dirname, "out");
export const CACHE = resolve(OUT, "cache");
export const COVERS = resolve(OUT, "covers");
export const SECRET = resolve(__dirname, "../../../secret");

export const USER_AGENT = "SabuSaku/1.0 (komunitaskertaskosong9@gmail.com)";

/** Google Books: stop well below the 1,000 queries/day project limit. */
const GOOGLE_DAILY_BUDGET = 960;

export function ensureDir(dir: string): void {
  if (!existsSync(dir)) mkdirSync(dir, {recursive: true});
}

export function readJson<T>(file: string, fallback: T): T {
  return existsSync(file) ? (JSON.parse(readFileSync(file, "utf8")) as T) : fallback;
}

export function writeJson(file: string, data: unknown): void {
  ensureDir(dirname(file));
  writeFileSync(file, JSON.stringify(data, null, 1));
}

export const sleep = (ms: number) => new Promise((done) => setTimeout(done, ms));

export function sha1(text: string): string {
  return createHash("sha1").update(text).digest("hex");
}

/** Pacific date: the Google quota day resets at midnight Pacific time. */
function pacificDay(): string {
  return new Date().toLocaleDateString("en-CA", {timeZone: "America/Los_Angeles"});
}

export class QuotaExhausted extends Error {
  constructor() {
    super("Kuota harian Google Books habis untuk run ini; lanjutkan besok (cache tetap terpakai).");
  }
}

const QUOTA_FILE = resolve(OUT, "quota-google.json");

function googleQuota(): {day: string; count: number} {
  const state = readJson(QUOTA_FILE, {day: pacificDay(), count: 0});
  return state.day === pacificDay() ? state : {day: pacificDay(), count: 0};
}

export function googleQueriesLeft(): number {
  return GOOGLE_DAILY_BUDGET - googleQuota().count;
}

const lastCall: Record<string, number> = {};

/** Minimum spacing between live requests per host. */
const SPACING: Record<string, number> = {
  "www.googleapis.com": 700,
  "openlibrary.org": 1100,
  "id.wikipedia.org": 300,
  "en.wikipedia.org": 300,
};

interface FetchOptions {
  /** Treat these HTTP statuses as a cached `null` instead of an error. */
  emptyOn?: number[];
}

/**
 * GET [url] as JSON with an on-disk cache. Google requests count against the
 * daily budget and throw [QuotaExhausted] when it is used up.
 */
export async function getJson<T = unknown>(url: string, options: FetchOptions = {}): Promise<T | null> {
  const host = new URL(url).host;
  // The API key is not part of the cache key.
  const cacheKey = url.replace(/([?&])key=[^&]+/, "$1");
  const file = resolve(CACHE, host, `${sha1(cacheKey)}.json`);
  if (existsSync(file)) return JSON.parse(readFileSync(file, "utf8")).body as T | null;

  if (host === "www.googleapis.com") {
    const quota = googleQuota();
    if (quota.count >= GOOGLE_DAILY_BUDGET) throw new QuotaExhausted();
    writeJson(QUOTA_FILE, {day: quota.day, count: quota.count + 1});
  }

  for (let attempt = 1; ; attempt++) {
    const wait = (lastCall[host] ?? 0) + (SPACING[host] ?? 200) - Date.now();
    if (wait > 0) await sleep(wait);
    lastCall[host] = Date.now();

    let response: Response;
    try {
      response = await fetch(url, {headers: {"User-Agent": USER_AGENT, "Accept": "application/json"}});
    } catch (error) {
      if (attempt >= 4) throw error;
      await sleep(2000 * attempt);
      continue;
    }
    if (response.ok || options.emptyOn?.includes(response.status)) {
      const body = response.ok ? await response.json() : null;
      writeJson(file, {url: cacheKey, at: new Date().toISOString(), body});
      return body as T | null;
    }
    if (response.status === 429 && host === "www.googleapis.com") {
      const text = await response.text();
      if (/per day/i.test(text)) throw new QuotaExhausted();
    }
    if ((response.status === 429 || response.status >= 500) && attempt < 5) {
      await sleep(3000 * attempt);
      continue;
    }
    throw new Error(`HTTP ${response.status} untuk ${cacheKey}`);
  }
}

/** True when [url] was fetched before, so asking again costs no quota. */
export function isCached(url: string): boolean {
  const host = new URL(url).host;
  const cacheKey = url.replace(/([?&])key=[^&]+/, "$1");
  return existsSync(resolve(CACHE, host, `${sha1(cacheKey)}.json`));
}

/** Downloads binary content with a cache (covers). */
export async function getBinary(url: string): Promise<Buffer | null> {
  const host = new URL(url).host;
  const file = resolve(CACHE, `${host}-bin`, `${sha1(url)}.bin`);
  const missing = `${file}.missing`;
  if (existsSync(file)) return readFileSync(file);
  if (existsSync(missing)) return null;
  for (let attempt = 1; attempt <= 4; attempt++) {
    try {
      const response = await fetch(url, {headers: {"User-Agent": USER_AGENT}, redirect: "follow"});
      if (response.status === 404) {
        writeJson(missing, {url});
        return null;
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const buffer = Buffer.from(await response.arrayBuffer());
      ensureDir(dirname(file));
      writeFileSync(file, buffer);
      return buffer;
    } catch (error) {
      if (attempt === 4) {
        console.warn(`  cover gagal: ${url} (${(error as Error).message})`);
        return null;
      }
      await sleep(1500 * attempt);
    }
  }
  return null;
}

/** Names compared without spaces, dots or case: "N.H. Dini" = "Nh. Dini". */
export function compactName(name: string): string {
  return normalizeSearchText(name).replace(/ /g, "");
}

/**
 * True when [candidate] names the same person as [seed] or one of its
 * aliases: equal compact forms, or every word of the seed in the candidate.
 */
export function authorMatches(candidate: string, seed: string, aliases: string[] = []): boolean {
  const c = compactName(candidate);
  if (!c) return false;
  for (const name of [seed, ...aliases]) {
    const s = compactName(name);
    if (!s) continue;
    if (c === s) return true;
    const words = normalizeSearchText(name).split(" ").filter((w) => w.length > 1);
    const cand = normalizeSearchText(candidate).split(" ");
    if (words.length >= 2 && words.every((w) => cand.includes(w))) return true;
  }
  return false;
}

/** Title Case for names in ALL CAPS or all lower case; keeps "S.Pd." etc. */
export function properName(raw: string): string {
  const name = raw.replace(/\s+/g, " ").trim();
  if (name !== name.toUpperCase() && name !== name.toLowerCase()) return name;
  return name
    .toLowerCase()
    .replace(/(^|[\s.\-'])([a-z])/g, (_, sep: string, letter: string) => sep + letter.toUpperCase());
}

export function argValue(name: string): string | undefined {
  const argv = process.argv.slice(2);
  const index = argv.indexOf(`--${name}`);
  const value = index >= 0 ? argv[index + 1] : undefined;
  return value && !value.startsWith("--") ? value : undefined;
}

export const hasFlag = (name: string) => process.argv.slice(2).includes(`--${name}`);

/** Raw edition record from any source, before merging. */
export interface Candidate {
  source: "google" | "openlibrary";
  sourceId: string;
  /** Open Library work key (`/works/OL…W`), for descriptions. */
  workKey?: string;
  title: string;
  subtitle?: string | null;
  authors: string[];
  publisher?: string | null;
  publishedYear?: number | null;
  pageCount?: number | null;
  isbn13?: string | null;
  isbn10?: string | null;
  categories: string[];
  description?: string | null;
  language?: string | null;
  coverUrl?: string | null;
  /** Which seed found it. */
  seed: SeedRef;
}

export interface SeedRef {
  kind: "author" | "title" | "wiki" | "publisher" | "subject";
  name: string;
  /** Category the seed implies when the source gives none. */
  category?: string;
  classic?: boolean;
  translated?: boolean;
}

export function isbnsOf(list: string[] | undefined): {isbn13: string | null; isbn10: string | null} {
  const clean = (list ?? []).map((v) => v.replace(/[^0-9X]/gi, "").toUpperCase());
  const isbn13 =
    clean.find((v) => /^97[89]\d{10}$/.test(v)) ?? clean.find((v) => /^\d{13}$/.test(v)) ?? null;
  const isbn10 = clean.find((v) => /^\d{9}[\dX]$/.test(v)) ?? null;
  return {isbn13, isbn10};
}

export function yearOf(date: string | number | null | undefined): number | null {
  if (date == null) return null;
  const match = String(date).match(/(1[89]\d\d|20\d\d|2100)/);
  return match ? Number(match[1]) : null;
}
