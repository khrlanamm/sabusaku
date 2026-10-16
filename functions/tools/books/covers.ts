// Step 4 of the book import: downloads one cover per book, rejects
// placeholders and broken images, and stores a JPEG at most 400 px wide in
// out/covers/{bookId}.jpg.
//
//   npx tsx tools/books/covers.ts
//
// Books without a usable cover move from out/books.json to out/rejected.json.

import {writeFileSync} from "node:fs";
import {resolve} from "node:path";

import sharp from "sharp";

import {COVERS, OUT, ensureDir, getBinary, readJson, sha1, writeJson} from "./common";
import {ImportBook} from "./normalize";
import {ACCEPTED_COVERS, REJECTED_COVERS} from "./review";

const CONCURRENCY = 6;

interface Checked {
  ok: boolean;
  reason?: string;
  hash?: string;
}

/** A real cover: big enough, portrait, not a single flat colour. */
async function inspect(buffer: Buffer, provider = "", accepted = false): Promise<Checked> {
  try {
    if (accepted) {
      const tiny = await sharp(buffer).resize(16, 24, {fit: "fill"}).greyscale().raw().toBuffer();
      return {ok: true, hash: sha1(tiny.toString("base64"))};
    }
    const image = sharp(buffer, {failOn: "none"});
    const meta = await image.metadata();
    const width = meta.width ?? 0;
    const height = meta.height ?? 0;
    // Wikipedia keeps non-free covers small (fair use); thumbnails still read.
    const [minW, minH] = [95, 140];
    if (width < minW || height < minH) return {ok: false, reason: `terlalu kecil ${width}x${height}`};
    const ratio = height / width;
    if (ratio < 0.95 || ratio > 2.2) return {ok: false, reason: `bukan proporsi sampul (${ratio.toFixed(2)})`};
    const stats = await image.stats();
    const spread = stats.channels.slice(0, 3).reduce((sum, c) => sum + c.stdev, 0) / 3;
    if (spread < 10) return {ok: false, reason: "gambar polos"};
    // Library scans of a title page or table of contents: almost all white
    // paper, almost no colour.
    const {data} = await sharp(buffer).resize(40, 60, {fit: "fill"}).removeAlpha().raw().toBuffer({resolveWithObject: true});
    let paper = 0;
    let saturation = 0;
    for (let i = 0; i < data.length; i += 3) {
      const [r, g, b] = [data[i], data[i + 1], data[i + 2]];
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      if (min > 200) paper++;
      saturation += max === 0 ? 0 : (max - min) / max;
    }
    const pixels = data.length / 3;
    const white = paper / pixels;
    const colour = saturation / pixels;
    // Wikipedia lead images are real covers, some of them mostly white.
    if (provider !== "wikipedia" && ((colour < 0.01 && white > 0.75) || (white > 0.85 && colour < 0.08))) {
      return {ok: false, reason: "scan halaman judul"};
    }
    // Small-resolution fingerprint to spot placeholders shared by many books.
    const tiny = await sharp(buffer).resize(16, 24, {fit: "fill"}).greyscale().raw().toBuffer();
    return {ok: true, hash: sha1(tiny.toString("base64"))};
  } catch (error) {
    return {ok: false, reason: `rusak (${(error as Error).message})`};
  }
}

async function main() {
  ensureDir(COVERS);
  const books = readJson<ImportBook[]>(resolve(OUT, "books.json"), []);
  const rejected = readJson<{id?: string; title: string; authors: string[]; reason: string}[]>(resolve(OUT, "rejected.json"), []);
  const hashes = new Map<string, string[]>();
  const results = new Map<string, {cover?: ImportBook["cover"]; reason?: string; hash?: string; buffer?: Buffer}>();

  // First pass: the first usable cover of each book. Second pass: books
  // that got a picture shared by three or more books (a placeholder such as
  // Google's grey "no image") try their next cover.
  const placeholders = new Set<string>();
  // A rejected picture often comes back through another URL (Google by
  // volume ID and by ISBN serve the same image): skip it by content too.
  const rejectedHashes = new Set<string>();
  for (const book of books) {
    for (const candidate of book.coverCandidates) {
      if (!REJECTED_COVERS.has(candidate.url)) continue;
      const buffer = await getBinary(candidate.url);
      const check = buffer ? await inspect(buffer, candidate.provider) : null;
      if (check?.hash) rejectedHashes.add(check.hash);
    }
  }
  const choose = async (book: ImportBook) => {
    let lastReason = "tidak ada cover";
    for (const candidate of book.coverCandidates) {
      if (REJECTED_COVERS.has(candidate.url)) {
        lastReason = "cover salah (tinjauan)";
        continue;
      }
      const buffer = await getBinary(candidate.url);
      if (!buffer) {
        lastReason = "cover tidak tersedia";
        continue;
      }
      const check = await inspect(buffer, candidate.provider, ACCEPTED_COVERS.has(candidate.url));
      if (!check.ok) {
        lastReason = `cover ${check.reason}`;
        continue;
      }
      if (placeholders.has(check.hash!)) {
        lastReason = "cover placeholder";
        continue;
      }
      if (rejectedHashes.has(check.hash!)) {
        lastReason = "cover salah (tinjauan)";
        continue;
      }
      results.set(book.id, {cover: {...candidate, file: `covers/${book.id}.jpg`}, hash: check.hash, buffer});
      return;
    }
    results.set(book.id, {reason: lastReason});
  };
  const run = async (list: ImportBook[]) => {
    let next = 0;
    let done = 0;
    await Promise.all(
      Array.from({length: CONCURRENCY}, async () => {
        while (next < list.length) {
          await choose(list[next++]);
          if (++done % 200 === 0) console.log(`  ${done}/${list.length}`);
        }
      }),
    );
  };
  await run(books);
  for (let round = 0; round < 3; round++) {
    hashes.clear();
    for (const [id, result] of results) if (result.hash) hashes.set(result.hash, [...(hashes.get(result.hash) ?? []), id]);
    const shared = [...hashes.entries()].filter(([, ids]) => ids.length >= 3);
    if (shared.length === 0) break;
    for (const [hash] of shared) placeholders.add(hash);
    const retry = books.filter((book) => placeholders.has(results.get(book.id)?.hash ?? ""));
    console.log(`  placeholder: ${shared.length} gambar, ${retry.length} buku dicoba ulang`);
    await run(retry);
  }

  const kept: ImportBook[] = [];
  for (const book of books) {
    const result = results.get(book.id)!;
    if (!result.cover || placeholders.has(result.hash ?? "")) {
      rejected.push({id: book.id, title: book.title, authors: book.authors, reason: result.reason ?? "cover placeholder"});
      continue;
    }
    // Always rewritten: a book's chosen cover can change between runs.
    const jpeg = await sharp(result.buffer!)
      .rotate()
      .resize({width: 400, withoutEnlargement: true})
      .flatten({background: "#ffffff"})
      .jpeg({quality: 80, mozjpeg: true})
      .toBuffer();
    writeFileSync(resolve(COVERS, `${book.id}.jpg`), jpeg);
    kept.push({...book, cover: result.cover});
  }

  writeJson(resolve(OUT, "books.json"), kept);
  writeJson(resolve(OUT, "rejected.json"), rejected);
  console.log(`Cover: ${kept.length} buku punya cover, ${books.length - kept.length} dibuang (${placeholders.size} gambar placeholder).`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
