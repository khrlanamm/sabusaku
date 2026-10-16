import {FieldValue} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {actorFor, addHistory, bookDeleted, bookNotFound, downloadUrlOf} from "../infra/books";
import {booksCol, db} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  bookId: z.string().min(1).max(64),
  path: z.string().min(1).max(512),
});

/**
 * Sets a catalog cover the teacher uploaded to `books/{bookId}/…` (Storage
 * rules let only teachers write there, images under 1 MB).
 */
export const setBookCover = onCall(CALLABLE_OPTIONS, async (request): Promise<{coverUrl: string}> => {
  const caller = await requireCaller(request, ["guru"]);
  const {bookId, path} = parseInput(inputSchema, request.data);
  if (!path.startsWith(`books/${bookId}/`) || path.includes("..")) {
    throw new HttpsError("invalid-argument", "Lokasi gambar cover tidak valid.");
  }
  const file = getStorage().bucket().file(path);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError("not-found", "Gambar cover belum terunggah.");
  const coverUrl = await downloadUrlOf(file);
  const actor = await actorFor(caller);

  await db.runTransaction(async (transaction) => {
    const ref = booksCol().doc(bookId);
    const book = await transaction.get(ref);
    if (!book.exists) throw bookNotFound();
    if (book.get("status") === "deleted") throw bookDeleted();
    const now = FieldValue.serverTimestamp();
    transaction.update(ref, {
      coverUrl,
      coverSource: {provider: "upload", url: null, sourceId: path},
      updatedAt: now,
      updatedBy: actor,
      version: FieldValue.increment(1),
    });
    addHistory(transaction, bookId, {
      type: "cover_changed",
      changes: {coverUrl: {from: book.get("coverUrl") ?? null, to: coverUrl}},
      by: actor,
    });
  });
  return {coverUrl};
});
