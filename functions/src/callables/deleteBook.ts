import {DocumentSnapshot, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {actorFor, addHistory, bookNotFound, mergeBookInto} from "../infra/books";
import {booksCol, db} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  bookId: z.string().min(1).max(64),
  reason: z.string().trim().max(200).optional(),
  duplicateOf: z.string().min(1).max(64).optional(),
});

/**
 * Soft-deletes a catalog book: it leaves search but nothing is erased, and
 * any teacher of any school can restore it from "Buku terhapus". Without
 * `duplicateOf`, programs that already use the book are not touched.
 *
 * With `duplicateOf` the book is merged into that one first: its programs in
 * every school, with their journals and reader counts, and the schools'
 * recommendations move to the original. Restoring the book later does not
 * move them back. The merge runs before the delete so a failed call can be
 * repeated.
 */
export const deleteBook = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 120},
  async (request): Promise<{ok: true; moved: number}> => {
    const caller = await requireCaller(request, ["guru"]);
    const {bookId, reason, duplicateOf} = parseInput(inputSchema, request.data);
    if (duplicateOf === bookId) {
      throw new HttpsError("invalid-argument", "Buku tidak bisa menjadi duplikat dirinya sendiri.");
    }
    const actor = await actorFor(caller);

    const check = (book: DocumentSnapshot, original: DocumentSnapshot | null) => {
      if (!book.exists) throw bookNotFound();
      if (book.get("status") === "deleted") {
        throw new HttpsError("failed-precondition", "Buku ini sudah dihapus.");
      }
      if (original && (!original.exists || original.get("status") === "deleted")) {
        throw new HttpsError("invalid-argument", "Buku aslinya tidak ditemukan di katalog.");
      }
    };

    let moved = 0;
    if (duplicateOf) {
      check(await booksCol().doc(bookId).get(), await booksCol().doc(duplicateOf).get());
      moved = await mergeBookInto(bookId, duplicateOf);
    }

    await db.runTransaction(async (transaction) => {
      const ref = booksCol().doc(bookId);
      const book = await transaction.get(ref);
      const original = duplicateOf ? await transaction.get(booksCol().doc(duplicateOf)) : null;
      check(book, original);
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
      if (original) {
        addHistory(transaction, original.id, {
          type: "merged",
          by: actor,
          note: `Duplikat "${book.get("title")}" digabungkan ke buku ini; ${moved} pembaca dipindah.`,
        });
      }
    });
    return {ok: true, moved};
  },
);
