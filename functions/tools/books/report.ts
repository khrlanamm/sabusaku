// Step 5 of the book import: a review report and a contact sheet.
//
//   npx tsx tools/books/report.ts [--seed 7]
//
// Writes out/report.md (counts, gaps, rejections, 40 random samples) and
// out/samples.jpg (the same 40 covers with their titles) so a person can
// check that covers, titles and authors belong together.

import {readFileSync, writeFileSync} from "node:fs";
import {resolve} from "node:path";

import sharp from "sharp";

import {BOOK_CATEGORIES} from "../../src/domain/search";
import {OUT, argValue, readJson} from "./common";
import {ImportBook} from "./normalize";

const SAMPLE = 40;

/** Deterministic shuffle (mulberry32) so a report can be reproduced. */
function shuffled<T>(items: T[], seed: number): T[] {
  let state = seed >>> 0;
  const random = () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

const escapeXml = (text: string) =>
  text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

function wrap(text: string, width: number, lines: number): string[] {
  const words = text.split(" ");
  const out: string[] = [];
  let line = "";
  for (const word of words) {
    if ((line + " " + word).trim().length > width) {
      out.push(line.trim());
      line = word;
      if (out.length === lines) break;
    } else {
      line += ` ${word}`;
    }
  }
  if (out.length < lines && line.trim()) out.push(line.trim());
  if (out.length === lines && words.join(" ").length > out.join(" ").length) {
    out[lines - 1] = `${out[lines - 1].slice(0, width - 1)}…`;
  }
  return out;
}

async function contactSheet(books: ImportBook[], file: string): Promise<void> {
  const cols = 8;
  const cellW = 180;
  const coverH = 260;
  const textH = 70;
  const rows = Math.ceil(books.length / cols);
  const tiles = await Promise.all(
    books.map(async (book, index) => {
      const cover = await sharp(readFileSync(resolve(OUT, book.cover!.file)))
        .resize(cellW - 10, coverH - 10, {fit: "contain", background: "#ffffff"})
        .toBuffer();
      const caption = [
        ...wrap(`${index + 1}. ${book.title}`, 26, 2),
        ...wrap(book.authors[0] ?? "", 28, 1),
      ];
      const svg = `<svg width="${cellW}" height="${textH}" xmlns="http://www.w3.org/2000/svg">
        <rect width="100%" height="100%" fill="#ffffff"/>
        ${caption
          .map(
            (line, i) =>
              `<text x="5" y="${16 + i * 17}" font-family="Helvetica, Arial, sans-serif" font-size="${i === caption.length - 1 ? 12 : 13}" fill="${i === caption.length - 1 ? "#555555" : "#111111"}" font-weight="${i === caption.length - 1 ? "normal" : "bold"}">${escapeXml(line)}</text>`,
          )
          .join("")}
      </svg>`;
      return {cover, caption: Buffer.from(svg), index};
    }),
  );
  const composite = tiles.flatMap(({cover, caption, index}) => {
    const left = (index % cols) * cellW;
    const top = Math.floor(index / cols) * (coverH + textH);
    return [
      {input: cover, left: left + 5, top: top + 5},
      {input: caption, left, top: top + coverH},
    ];
  });
  await sharp({
    create: {width: cols * cellW, height: rows * (coverH + textH), channels: 3, background: "#ffffff"},
  })
    .composite(composite)
    .jpeg({quality: 80})
    .toFile(file);
}

async function main() {
  const books = readJson<ImportBook[]>(resolve(OUT, "books.json"), []);
  const rejected = readJson<{title: string; authors: string[]; reason: string}[]>(resolve(OUT, "rejected.json"), []);
  const count = <T extends string>(values: T[]) =>
    values.reduce<Record<string, number>>((acc, v) => {
      acc[v] = (acc[v] ?? 0) + 1;
      return acc;
    }, {});

  const primary = count(books.map((b) => b.categories[0]));
  const anyCategory = count(books.flatMap((b) => b.categories));
  const coverProvider = count(books.map((b) => b.cover?.provider ?? "none"));
  const dataSources = count(
    books.map((b) =>
      b.sources.google?.length && b.sources.openlibrary?.length
        ? "openlibrary+google"
        : b.sources.google?.length
          ? "google"
          : "openlibrary",
    ),
  );
  const missing = {
    description: books.filter((b) => !b.description).length,
    isbn13: books.filter((b) => !b.isbn13).length,
    publisher: books.filter((b) => !b.publisher).length,
    publishedYear: books.filter((b) => !b.publishedYear).length,
  };
  const reasons = count(rejected.map((r) => r.reason));
  const authors = count(books.map((b) => b.authors[0]));
  const topAuthors = Object.entries(authors).sort((x, y) => y[1] - x[1]).slice(0, 25);
  const samples = shuffled(books, Number(argValue("seed") ?? 7)).slice(0, SAMPLE);

  const table = (rows: Record<string, number>, order?: readonly string[]) =>
    (order ?? Object.keys(rows).sort((x, y) => rows[y] - rows[x]))
      .filter((k) => rows[k])
      .map((k) => `| ${k} | ${rows[k]} |`)
      .join("\n");

  const md = `# Laporan impor katalog buku

Dibuat ${new Date().toISOString()}. **${books.length} buku** siap diimpor; ${rejected.length} edisi/grup dibuang.

## Kategori utama
| Kategori | Buku |
|---|---|
${table(primary, BOOK_CATEGORIES)}

## Semua kategori (satu buku bisa 1–3)
| Kategori | Buku |
|---|---|
${table(anyCategory, BOOK_CATEGORIES)}

## Sumber
| Cover dari | Buku |
|---|---|
${table(coverProvider)}

| Data dari | Buku |
|---|---|
${table(dataSources)}

## Field kosong
| Field | Buku tanpa field ini |
|---|---|
${table(missing)}

## Penulis terbanyak
| Penulis | Buku |
|---|---|
${topAuthors.map(([name, n]) => `| ${name} | ${n} |`).join("\n")}

## Alasan dibuang
| Alasan | Jumlah |
|---|---|
${table(reasons)}

## ${SAMPLE} contoh acak (sama dengan samples.jpg)
| # | Judul | Penulis | Hal. | Tahun | Penerbit | Kategori | ISBN-13 | Cover |
|---|---|---|---|---|---|---|---|---|
${samples
  .map(
    (b, i) =>
      `| ${i + 1} | ${b.title}${b.subtitle ? `: ${b.subtitle}` : ""} | ${b.authors.join(", ")} | ${b.pageCount} | ${b.publishedYear ?? ""} | ${b.publisher ?? ""} | ${b.categories.join(", ")} | ${b.isbn13 ?? ""} | ${b.cover?.file} (${b.cover?.provider}) |`,
  )
  .join("\n")}
`;
  writeFileSync(resolve(OUT, "report.md"), md);
  await contactSheet(samples, resolve(OUT, "samples.jpg"));
  console.log(`Laporan: ${resolve(OUT, "report.md")}\nContoh: ${resolve(OUT, "samples.jpg")}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
