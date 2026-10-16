import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {actorFor, addHistory, bookNotFound} from "../infra/books";
import {booksCol, db} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  bookId: z.string().min(1).max(64),
  reason: z.string().trim().max(200).optional(),
  duplicateOf: z.string().min(1).max(64).optional(),
});

/**
 * Soft-deletes a catalog book: it leaves search but nothing is erased, and
 * any teacher of any school can restore it from "Buku terhapus". Programs
 * that already use the book are not touched. `duplicateOf` names the book
 * this one duplicates.
 */
export const deleteBook = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["guru"]);
  const {bookId, reason, duplicateOf} = parseInput(inputSchema, request.data);
  if (duplicateOf === bookId) {
    throw new HttpsError("invalid-argument", "Buku tidak bisa menjadi duplikat dirinya sendiri.");
  }
  const actor = await actorFor(caller);

  await db.runTransaction(async (transaction) => {
    const ref = booksCol().doc(bookId);
    const book = await transaction.get(ref);
    if (!book.exists) throw bookNotFound();
    if (book.get("status") === "deleted") {
      throw new HttpsError("failed-precondition", "Buku ini sudah dihapus.");
    }
    if (duplicateOf) {
      const original = await transaction.get(booksCol().doc(duplicateOf));
      if (!original.exists || original.get("status") === "deleted") {
        throw new HttpsError("invalid-argument", "Buku aslinya tidak ditemukan di katalog.");
      }
    }
    const now = FieldValue.serverTimestamp();
    transaction.update(ref, {
      status: "deleted",
      deletedAt: now,
      deletedBy: actor,
      deleteReason: reason || null,
      duplicateOf: duplicateOf ?? null,
      updatedAt: now,
      updatedBy: actor,
      version: FieldValue.increment(1),
    });
    addHistory(transaction, bookId, {
      type: "deleted",
      changes: {
        status: {from: "active", to: "deleted"},
        ...(duplicateOf ? {duplicateOf: {from: null, to: duplicateOf}} : {}),
      },
      by: actor,
      note: reason || undefined,
    });
  });
  return {ok: true};
});
