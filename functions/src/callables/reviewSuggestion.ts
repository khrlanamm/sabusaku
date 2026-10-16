import {FieldValue, Transaction} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {
  actorFor,
  addHistory,
  bookDeleted,
  bookNotFound,
  copyCoverToCatalog,
  CoverChange,
  linkSuggestionPrograms,
  newBookId,
  saveBook,
  SuggestionSource,
} from "../infra/books";
import {booksCol, bookSuggestionsCol, db} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

/** Proposed fields a teacher can apply to a catalog book. */
const APPLICABLE = ["title", "authors", "pageCount", "isbn13", "isbn10", "publisher", "coverUrl"];

const inputSchema = z.object({
  id: z.string().min(1).max(64),
  action: z.enum(["apply", "reject", "create", "link"]),
  /** apply: which proposed fields to take (all when absent). */
  fields: z.array(z.enum(APPLICABLE as [string, ...string[]])).min(1).optional(),
  /** create: the book as the teacher edited it (defaults from the proposal). */
  book: z.record(z.string(), z.unknown()).optional(),
  /** link: the existing catalog book the suggested one really is. */
  bookId: z.string().min(1).max(64).optional(),
});

const alreadyReviewed = () => new HttpsError("failed-precondition", "Saran ini sudah ditinjau.");

/**
 * A teacher's decision on a student's suggestion:
 *   - `apply` (edit): take some or all proposed fields into the catalog book;
 *     a proposed cover is copied into the catalog's own Storage folder;
 *   - `reject`: close it, noted in the book's history when there is a book;
 *   - `create` (new): add the suggested book to the catalog;
 *   - `link` (new): it is a book the catalog already has.
 * After `create` and `link`, the students' programs point at the catalog book.
 */
export const reviewSuggestion = onCall(
  {...CALLABLE_OPTIONS, timeoutSeconds: 120},
  async (request): Promise<{bookId?: string}> => {
    const caller = await requireCaller(request, ["guru"]);
    const input = parseInput(inputSchema, request.data);
    const actor = await actorFor(caller);

    const suggestionRef = bookSuggestionsCol().doc(input.id);
    const suggestion = await suggestionRef.get();
    if (!suggestion.exists) throw new HttpsError("not-found", "Saran tidak ditemukan.");
    if (suggestion.get("status") !== "pending") throw alreadyReviewed();
    const kind = suggestion.get("kind") as "edit" | "new";
    const proposed = (suggestion.get("proposed") as Record<string, unknown> | undefined) ?? {};
    const sources = (suggestion.get("from") as SuggestionSource[] | undefined) ?? [];

    /** Re-reads the suggestion inside the transaction: two teachers may race. */
    const stillPending = async (transaction: Transaction) => {
      const fresh = await transaction.get(suggestionRef);
      if (fresh.get("status") !== "pending") throw alreadyReviewed();
    };
    const close = (
      transaction: Transaction,
      status: "accepted" | "rejected",
      resultBookId: string | null,
    ) => {
      const now = FieldValue.serverTimestamp();
      transaction.update(suggestionRef, {
        status,
        reviewedBy: actor,
        reviewedAt: now,
        resultBookId,
        updatedAt: now,
      });
    };

    switch (input.action) {
      case "apply": {
        if (kind !== "edit") {
          throw new HttpsError("invalid-argument", "Saran buku baru ditambahkan atau ditautkan, bukan diterapkan.");
        }
        const bookId = suggestion.get("bookId") as string;
        const picked = (input.fields ?? Object.keys(proposed)).filter(
          (field) => APPLICABLE.includes(field) && field in proposed,
        );
        if (picked.length === 0) {
          throw new HttpsError("invalid-argument", "Pilih minimal satu perubahan untuk diterapkan.");
        }
        const patch = Object.fromEntries(
          picked.filter((field) => field !== "coverUrl").map((field) => [field, proposed[field]]),
        );
        let cover: CoverChange | undefined;
        if (picked.includes("coverUrl") && typeof proposed.coverPath === "string") {
          cover = {
            url: await copyCoverToCatalog(proposed.coverPath, bookId),
            source: {provider: "suggestion", url: null, sourceId: input.id},
          };
        }
        await saveBook({
          bookId,
          patch,
          cover,
          actor,
          historyType: "suggestion_applied",
          suggestionId: input.id,
          check: stillPending,
          also: (transaction) => close(transaction, "accepted", bookId),
        });
        return {bookId};
      }

      case "reject": {
        const bookId = (suggestion.get("bookId") as string | null) ?? null;
        await db.runTransaction(async (transaction) => {
          await stillPending(transaction);
          const book = bookId ? await transaction.get(booksCol().doc(bookId)) : null;
          close(transaction, "rejected", null);
          if (book?.exists) {
            const changes = Object.fromEntries(
              Object.entries(proposed)
                .filter(([field]) => field !== "coverPath")
                .map(([field, to]) => [field, {from: book.get(field) ?? null, to}]),
            );
            addHistory(transaction, book.id, {
              type: "suggestion_rejected",
              changes,
              by: actor,
              suggestionId: input.id,
            });
          }
        });
        return {};
      }

      case "create": {
        if (kind !== "new") {
          throw new HttpsError("invalid-argument", "Hanya saran buku baru yang bisa ditambahkan ke katalog.");
        }
        const fields = input.book ?? {
          title: proposed.title,
          authors: proposed.authors,
          pageCount: proposed.pageCount,
          isbn13: proposed.isbn13 ?? null,
          isbn10: proposed.isbn10 ?? null,
          categories: ["Lainnya"],
        };
        const bookId = newBookId();
        let cover: CoverChange | undefined;
        if (typeof proposed.coverPath === "string") {
          cover = {
            url: await copyCoverToCatalog(proposed.coverPath, bookId),
            source: {provider: "suggestion", url: null, sourceId: input.id},
          };
        }
        await saveBook({
          newId: bookId,
          fields,
          cover,
          actor,
          historyType: "created",
          suggestionId: input.id,
          check: stillPending,
          also: (transaction) => close(transaction, "accepted", bookId),
        });
        await linkSuggestionPrograms(sources, bookId, cover?.url ?? null);
        return {bookId};
      }

      case "link": {
        if (kind !== "new") {
          throw new HttpsError("invalid-argument", "Hanya saran buku baru yang bisa ditautkan.");
        }
        const bookId = input.bookId;
        if (!bookId) throw new HttpsError("invalid-argument", "Pilih buku di katalog.");
        let coverUrl: string | null = null;
        await db.runTransaction(async (transaction) => {
          await stillPending(transaction);
          const book = await transaction.get(booksCol().doc(bookId));
          if (!book.exists) throw bookNotFound();
          if (book.get("status") === "deleted") throw bookDeleted();
          coverUrl = (book.get("coverUrl") as string | null | undefined) ?? null;
          close(transaction, "accepted", bookId);
          addHistory(transaction, bookId, {
            type: "suggestion_applied",
            by: actor,
            suggestionId: input.id,
            note: "Saran buku baru ditautkan ke buku ini.",
          });
        });
        await linkSuggestionPrograms(sources, bookId, coverUrl);
        return {bookId};
      }
    }
  },
);
