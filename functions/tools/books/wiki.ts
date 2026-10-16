// Widens the seed lists from Indonesian Wikipedia (CC BY-SA metadata only):
// novels in "Kategori:Novel Indonesia" (and its per-author subcategories)
// with the author named in their infobox, and the writers listed under
// "Kategori:Novelis Indonesia", "Kategori:Penyair Indonesia" and
// "Kategori:Cerpenis Indonesia".
//
//   npx tsx tools/books/wiki.ts
//
// Writes out/wiki-seeds.json; fetch.ts reads it when present.

import {resolve} from "node:path";

import {OUT, getJson, writeJson} from "./common";

const API = "https://id.wikipedia.org/w/api.php";
const API_EN = "https://en.wikipedia.org/w/api.php";

/** en.wikipedia categories of Indonesian books, walked three levels deep. */
const EN_CATEGORIES = [
  "Category:Indonesian novels",
  "Category:Balai Pustaka books",
  "Category:Indonesian non-fiction books",
  "Category:Indonesian short story collections",
  "Category:Indonesian poetry collections",
];

interface Member {
  title: string;
  ns: number;
}

async function members(category: string, lang: "id" | "en" = "id"): Promise<Member[]> {
  const all: Member[] = [];
  let cont: string | undefined;
  do {
    const url =
      `${lang === "en" ? API_EN : API}?action=query&list=categorymembers&format=json&cmlimit=500` +
      `&cmtitle=${encodeURIComponent(category)}` +
      (cont ? `&cmcontinue=${encodeURIComponent(cont)}` : "");
    const data = await getJson<{
      query: {categorymembers: Member[]};
      continue?: {cmcontinue: string};
    }>(url);
    all.push(...(data?.query.categorymembers ?? []));
    cont = data?.continue?.cmcontinue;
  } while (cont);
  return all;
}

/** "[[Achdiat Karta Mihardja]]" or "[[A|B]]" → "Achdiat Karta Mihardja" / "B". */
function cleanLink(raw: string): string {
  return raw
    .split(/\|\s*\w+\s*=/)[0]
    .replace(/<ref[\s\S]*?(<\/ref>|\/>)/g, "")
    .replace(/<br\s*\/?>.*$/i, "")
    .replace(/\[\[([^\]|]+\|)?([^\]]+)\]\]/g, "$2")
    .replace(/\{\{[^}]*\}\}/g, "")
    .replace(/'''?/g, "")
    .split(/,| dan | & /)[0]
    .trim();
}

/** Page title without the "(novel)" disambiguation. */
function cleanTitle(title: string): string {
  return title.replace(/\s*\((novel|buku|novel [^)]*)\)\s*$/i, "").trim();
}

async function infoboxAuthors(titles: string[]): Promise<Map<string, string>> {
  const found = new Map<string, string>();
  for (let i = 0; i < titles.length; i += 50) {
    const batch = titles.slice(i, i + 50);
    const url =
      `${API}?action=query&prop=revisions&rvprop=content&rvslots=main&format=json` +
      `&titles=${encodeURIComponent(batch.join("|"))}`;
    const data = await getJson<{
      query: {pages: Record<string, {title: string; revisions?: {slots: {main: {"*": string}}}[]}>};
    }>(url);
    for (const page of Object.values(data?.query.pages ?? {})) {
      const text = page.revisions?.[0]?.slots.main["*"] ?? "";
      const match = text.match(/\|\s*(author|pengarang|penulis)\s*=\s*([^\n]+)/i);
      const author = match ? cleanLink(match[2]) : "";
      if (author.length >= 2) found.set(page.title, author);
    }
  }
  return found;
}

async function main() {
  // Novels: the main category, plus its per-author subcategories.
  const top = await members("Kategori:Novel Indonesia");
  const byAuthor = await members("Kategori:Novel Indonesia menurut penulis");
  const novelPages = new Set(top.filter((m) => m.ns === 0).map((m) => m.title));
  for (const sub of [...byAuthor, ...top].filter((m) => m.ns === 14)) {
    if (!/Novel (oleh|karya)/.test(sub.title)) continue;
    for (const page of await members(sub.title)) if (page.ns === 0) novelPages.add(page.title);
  }
  const authors = await infoboxAuthors([...novelPages]);
  const titles = [...novelPages]
    .filter((page) => authors.has(page))
    .map((page) => ({title: cleanTitle(page), author: authors.get(page)!, page}));

  // Writers.
  const writerNames = new Set<string>();
  for (const category of [
    "Kategori:Novelis Indonesia",
    "Kategori:Penyair Indonesia",
    "Kategori:Cerpenis Indonesia",
    "Kategori:Sastrawan Indonesia",
  ]) {
    for (const page of await members(category)) {
      if (page.ns === 0) writerNames.add(page.title.replace(/\s*\([^)]*\)$/, ""));
    }
  }

  // en.wikipedia: Indonesian novels and books, with their original titles.
  const enTitles: {title: string; author: string; en: string}[] = [];
  const seenCategories = new Set<string>();
  const enPages = new Set<string>();
  const skipCategory = /adapted into films|works based on|films|television/i;
  const walk = async (category: string, depth: number) => {
    if (seenCategories.has(category) || depth > 3 || skipCategory.test(category)) return;
    seenCategories.add(category);
    for (const member of await members(category, "en")) {
      if (member.ns === 0) enPages.add(member.title);
      else if (member.ns === 14) await walk(member.title, depth + 1);
    }
  };
  for (const category of EN_CATEGORIES) await walk(category, 0);
  const pagesList = [...enPages];
  for (let i = 0; i < pagesList.length; i += 50) {
    const batch = pagesList.slice(i, i + 50);
    const url =
      `${API_EN}?action=query&prop=revisions&rvprop=content&rvslots=main&format=json&redirects=1` +
      `&titles=${encodeURIComponent(batch.join("|"))}`;
    const data = await getJson<{
      query: {pages: Record<string, {title: string; revisions?: {slots: {main: {"*": string}}}[]}>};
    }>(url);
    for (const page of Object.values(data?.query.pages ?? {})) {
      const text = page.revisions?.[0]?.slots.main["*"] ?? "";
      if (!/\{\{\s*infobox (book|novel|short story|poetry)/i.test(text)) continue;
      const author = cleanLink(text.match(/\|\s*author\s*=\s*([^\n]+)/i)?.[1] ?? "");
      const original = cleanLink(text.match(/\|\s*(title_orig|orig_title|original_title)\s*=\s*([^\n]+)/i)?.[2] ?? "");
      const title = original || cleanTitle(page.title);
      if (author.length >= 2 && title.length >= 2) enTitles.push({title, author, en: page.title});
    }
  }

  const file = resolve(OUT, "wiki-seeds.json");
  writeJson(file, {titles, enTitles, authors: [...writerNames].sort()});
  console.log(
    `Wikipedia: ${titles.length} novel (id) dan ${enTitles.length} buku (en) dengan penulis, ${writerNames.size} penulis → ${file}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
