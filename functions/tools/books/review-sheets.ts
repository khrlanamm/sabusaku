// Contact sheets of EVERY cover, for a human pass before the import.
//
//   npx tsx tools/books/review-sheets.ts
//
// Writes out/review/sheet-NN.jpg (48 books each, numbered) and
// out/review/index.json (number → book id). With --new, only books whose
// cover changed since the last sheet (new-NN.jpg, index-new.json). Record
// wrong covers and books that do not belong in review.ts, then rerun
// normalize → covers → report.

import {readFileSync} from "node:fs";
import {resolve} from "node:path";

import sharp from "sharp";

import {OUT, ensureDir, readJson, writeJson} from "./common";
import {ImportBook} from "./normalize";

const PER_SHEET = 48;
const COLS = 8;
const W = 160;
const H = 230;
const TEXT = 44;

const escapeXml = (text: string) =>
  text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

async function main() {
  const dir = resolve(OUT, "review");
  ensureDir(dir);
  // --new: only books whose current cover was not seen in a previous review
  // (out/review/reviewed-covers.json maps book id → cover URL).
  const seen = readJson<Record<string, string>>(resolve(dir, "reviewed-covers.json"), {});
  const onlyNew = process.argv.includes("--new");
  const all = readJson<ImportBook[]>(resolve(OUT, "books.json"), []);
  const books = all
    .filter((book) => !onlyNew || seen[book.id] !== book.cover?.url)
    .sort((x, y) => x.id.localeCompare(y.id));
  const index: Record<number, string> = {};
  for (let start = 0, sheet = 1; start < books.length; start += PER_SHEET, sheet++) {
    const chunk = books.slice(start, start + PER_SHEET);
    const composite = (
      await Promise.all(
        chunk.map(async (book, i) => {
          const number = start + i + 1;
          index[number] = book.id;
          const left = (i % COLS) * W;
          const top = Math.floor(i / COLS) * (H + TEXT);
          const cover = await sharp(readFileSync(resolve(OUT, book.cover!.file)))
            .resize(W - 8, H - 8, {fit: "contain", background: "#dddddd"})
            .toBuffer();
          const title = book.title.length > 26 ? `${book.title.slice(0, 25)}…` : book.title;
          const author = (book.authors[0] ?? "").slice(0, 28);
          const svg = `<svg width="${W}" height="${TEXT}" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#ffffff"/>
            <text x="4" y="15" font-family="Helvetica, Arial" font-size="12" font-weight="bold">${number}. ${escapeXml(title)}</text>
            <text x="4" y="32" font-family="Helvetica, Arial" font-size="11" fill="#555555">${escapeXml(author)}</text></svg>`;
          return [
            {input: cover, left: left + 4, top: top + 4},
            {input: Buffer.from(svg), left, top: top + H},
          ];
        }),
      )
    ).flat();
    const rows = Math.ceil(chunk.length / COLS);
    await sharp({create: {width: COLS * W, height: rows * (H + TEXT), channels: 3, background: "#ffffff"}})
      .composite(composite)
      .jpeg({quality: 72})
      .toFile(resolve(dir, `${onlyNew ? "new" : "sheet"}-${String(sheet).padStart(2, "0")}.jpg`));
  }
  writeJson(resolve(dir, onlyNew ? "index-new.json" : "index.json"), index);
  // Everything shown now counts as reviewed for the next --new run.
  writeJson(resolve(dir, "reviewed-covers.json"), {
    ...seen,
    ...Object.fromEntries(books.map((book) => [book.id, book.cover?.url ?? ""])),
  });
  console.log(`${Math.ceil(books.length / PER_SHEET)} lembar untuk ${books.length} buku di ${dir}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
