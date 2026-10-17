// Applies the review decisions in review.ts to books that are already in the
// catalog, then rebuilds the search index.
//
//   npx tsx tools/books/curate.ts [--apply] [--emulator]
//
// Without --apply it only prints what it would do. Against PRODUCTION unless
// --emulator.
//
//   - REJECTED_BOOKS that are active are soft-deleted (status "deleted", with
//     the reason), exactly as a teacher's "Hapus buku" does: they leave search,
//     programs that use them keep their copy, and any teacher can restore them
//     from "Buku terhapus".
//   - CORRECTIONS and CATEGORY_OVERRIDES are written to books no teacher has
//     edited (updatedBy.kind is still "import"); a teacher's edit always wins.
//
// Every change gets a history entry by "Kurasi pengembang".

import "../_env";

import {resolve} from "node:path";

import {FieldValue} from "firebase-admin/firestore";

import {rebuildCatalog} from "../../src/infra/catalog";
import {booksCol, db} from "../../src/infra/firebase";
import {OUT, hasFlag, readJson} from "./common";
import {ImportBook, cleanDescription} from "./normalize";
import {CATEGORY_OVERRIDES, CORRECTIONS, REJECTED_BOOKS} from "./review";

const ACTOR = {name: "Kurasi pengembang", kind: "import"} as const;

type Changes = Record<string, {from: unknown; to: unknown}>;

const same = (a: unknown, b: unknown) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

async function load(ids: string[]): Promise<Map<string, FirebaseFirestore.DocumentData>> {
  const found = new Map<string, FirebaseFirestore.DocumentData>();
  for (let i = 0; i < ids.length; i += 300) {
    const snaps = await db.getAll(...ids.slice(i, i + 300).map((id) => booksCol().doc(id)));
    for (const snap of snaps) if (snap.exists) found.set(snap.id, snap.data()!);
  }
  return found;
}

async function main() {
  const apply = hasFlag("apply");
  const books = new Map(readJson<ImportBook[]>(resolve(OUT, "books.json"), []).map((b) => [b.id, b]));

  // ---- Soft deletes
  const rejected = await load(Object.keys(REJECTED_BOOKS));
  const deletes = [...rejected].filter(([, data]) => data.status === "active");
  console.log(`Hapus lunak: ${deletes.length} buku aktif dari ${Object.keys(REJECTED_BOOKS).length} keputusan tolak`);
  for (const [id, data] of deletes) {
    const readers = (data.readerCount as number | undefined) ?? 0;
    console.log(`  - ${data.title} (${id})${readers ? `, dipakai ${readers} program` : ""}: ${REJECTED_BOOKS[id]}`);
  }

  // ---- Corrections (CORRECTIONS, plus categories from CATEGORY_OVERRIDES)
  const ids = [...new Set([...Object.keys(CORRECTIONS), ...Object.keys(CATEGORY_OVERRIDES)])];
  const current = await load(ids);
  const patches: {id: string; title: string; patch: Record<string, unknown>; changes: Changes}[] = [];
  for (const id of ids) {
    const data = current.get(id);
    if (!data || data.status !== "active" || data.updatedBy?.kind !== "import") continue;
    const wanted: Record<string, unknown> = {...CORRECTIONS[id]};
    if (CATEGORY_OVERRIDES[id]) wanted.categories = CATEGORY_OVERRIDES[id];
    const patch: Record<string, unknown> = {};
    const changes: Changes = {};
    for (const [field, value] of Object.entries(wanted)) {
      if (same(data[field], value)) continue;
      patch[field] = value;
      changes[field] = {from: data[field] ?? null, to: value};
    }
    if ("description" in patch) patch.descriptionSource = patch.description ? "review" : null;
    if (Object.keys(changes).length) patches.push({id, title: data.title as string, patch, changes});
  }
  // Synopses stored before cleanDescription learned about mojibake and quote artifacts.
  const active = await booksCol().where("status", "==", "active").get();
  for (const doc of active.docs) {
    const data = doc.data();
    if (data.updatedBy?.kind !== "import" || !data.description || patches.some((p) => p.id === doc.id)) continue;
    const cleaned = cleanDescription(data.description as string);
    if (cleaned === data.description) continue;
    patches.push({
      id: doc.id,
      title: data.title as string,
      patch: {description: cleaned, descriptionSource: cleaned ? data.descriptionSource ?? null : null},
      changes: {description: {from: data.description, to: cleaned}},
    });
  }
  console.log(`Koreksi data: ${patches.length} buku`);
  for (const {id, title, changes} of patches) console.log(`  - ${title} (${id}): ${Object.keys(changes).join(", ")}`);

  // books.json must agree, so a later --fill-missing or --update does not undo this.
  const stale = patches.filter(({id, patch}) => {
    const book = books.get(id);
    return book && Object.entries(patch).some(([f, v]) => f !== "descriptionSource" && !same((book as never)[f], v));
  });
  if (stale.length) console.warn(`  Catatan: books.json belum memuat ${stale.length} koreksi; jalankan normalize.ts lagi.`);

  if (!apply) {
    console.log("Dry run. Tambahkan --apply untuk menulis.");
    return;
  }

  const writes = [
    ...deletes.map(([id, data]) => ({
      id,
      update: {
        status: "deleted",
        deletedAt: FieldValue.serverTimestamp(),
        deletedBy: ACTOR,
        deleteReason: REJECTED_BOOKS[id].replace(/^kurasi: /, ""),
        duplicateOf: null,
      },
      history: {
        type: "deleted",
        changes: {status: {from: data.status, to: "deleted"}},
        note: REJECTED_BOOKS[id].replace(/^kurasi: /, ""),
      },
    })),
    ...patches.map(({id, patch, changes}) => ({
      id,
      update: patch,
      history: {type: "updated", changes, note: "Kurasi katalog"},
    })),
  ];
  for (let start = 0; start < writes.length; start += 200) {
    const batch = db.batch();
    for (const {id, update, history} of writes.slice(start, start + 200)) {
      const ref = booksCol().doc(id);
      batch.update(ref, {
        ...update,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: ACTOR,
        version: FieldValue.increment(1),
      });
      batch.set(ref.collection("history").doc(), {...history, by: ACTOR, at: FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
  // The catalog trigger skips writes by kind "import"; rebuild once.
  const indexed = await rebuildCatalog();
  console.log(`Selesai: ${deletes.length} dihapus lunak, ${patches.length} dikoreksi; indeks berisi ${indexed} buku aktif.`);
}

main().then(
  () => process.exit(0),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
