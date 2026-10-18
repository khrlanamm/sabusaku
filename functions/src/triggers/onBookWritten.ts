import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {BACKGROUND_OPTIONS} from "../config";

import {sameTime} from "../infra/books";
import {catalogEntry, isIndexed, upsertCatalogEntry} from "../infra/catalog";

/**
 * Keeps the book's entry in the search index (`catalog/shard-{n}`) in step
 * with the catalog: added, changed, removed when deleted, back when restored.
 *
 * Writes made by the bulk import are skipped (it rebuilds the index once at
 * the end); a later reader-count change of an imported book still counts.
 */
export const onBookWritten = onDocumentWritten({document: "books/{bookId}", ...BACKGROUND_OPTIONS}, async (event) => {
  const before = event.data?.before?.exists ? event.data.before.data()! : null;
  const after = event.data?.after?.exists ? event.data.after.data()! : null;

  const importWrite =
    after?.updatedBy?.kind === "import" && (!before || !sameTime(before.updatedAt, after.updatedAt));
  if (importWrite) return;

  const was = isIndexed(before) ? JSON.stringify(catalogEntry(before!)) : null;
  const now = isIndexed(after) ? JSON.stringify(catalogEntry(after!)) : null;
  if (was === now) return;
  await upsertCatalogEntry(event.params.bookId, after);
});
