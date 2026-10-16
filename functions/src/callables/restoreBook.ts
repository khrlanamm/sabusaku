import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {actorFor, addHistory, bookNotFound} from "../infra/books";
import {booksCol, db} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({bookId: z.string().min(1).max(64)});

/** Brings a deleted book back into the catalog. Any teacher of any school. */
export const restoreBook = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["guru"]);
  const {bookId} = parseInput(inputSchema, request.data);
  const actor = await actorFor(caller);

  await db.runTransaction(async (transaction) => {
    const ref = booksCol().doc(bookId);
    const book = await transaction.get(ref);
    if (!book.exists) throw bookNotFound();
    if (book.get("status") !== "deleted") {
      throw new HttpsError("failed-precondition", "Buku ini tidak dalam keadaan terhapus.");
    }
    const now = FieldValue.serverTimestamp();
    transaction.update(ref, {
      status: "active",
      deletedAt: FieldValue.delete(),
      deletedBy: FieldValue.delete(),
      deleteReason: FieldValue.delete(),
      duplicateOf: FieldValue.delete(),
      updatedAt: now,
      updatedBy: actor,
      version: FieldValue.increment(1),
    });
    addHistory(transaction, bookId, {
      type: "restored",
      changes: {status: {from: "deleted", to: "active"}},
      by: actor,
    });
  });
  return {ok: true};
});
