// Hand-collected catalog data that this public repo must not hold: most of it
// is text from publishers and stores. It lives in the private repo
// sabusaku-catalog-data, cloned to private/ next to this file:
//
//   git clone https://github.com/khrlanamm/sabusaku-catalog-data.git functions/tools/books/private
//
// Without the clone the pipeline runs with none of it.

import {existsSync} from "node:fs";
import {resolve} from "node:path";

import type {ManualBook} from "./review";

const DIR = resolve(__dirname, "private");

function load<T>(file: string, name: string, fallback: T): T {
  const path = resolve(DIR, file);
  if (!existsSync(path)) {
    console.warn(`${file} tidak ada: clone repo data privat ke tools/books/private/. Lanjut tanpa data itu.`);
    return fallback;
  }
  return (require(path) as Record<string, T>)[name];
}

/** Book ID → synopsis. */
export const SYNOPSES = load<Record<string, string>>("manual-synopses.ts", "SYNOPSES", {});

/** Indonesian editions the import pipeline does not find, added by manual.ts. */
export const MANUAL_BOOKS = load<ManualBook[]>("manual-books.ts", "MANUAL_BOOKS", []);
