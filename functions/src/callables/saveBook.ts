import {onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {actorFor, saveBook as save} from "../infra/books";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({
  bookId: z.string().min(1).max(64).optional(),
  fields: z.record(z.string(), z.unknown()),
});

/**
 * Adds a book to the shared catalog or edits one. Any teacher of any school
 * may do it; the change is recorded in the book's history with their name and
 * school. Errors: `invalid-argument` (the message names the bad field),
 * `already-exists` (`details.bookId` is the existing book), `not-found`,
 * `failed-precondition` (the book is deleted).
 */
export const saveBook = onCall(CALLABLE_OPTIONS, async (request): Promise<{bookId: string}> => {
  const caller = await requireCaller(request, ["guru"]);
  const {bookId, fields} = parseInput(inputSchema, request.data);
  const result = await save({bookId, fields, actor: await actorFor(caller)});
  return {bookId: result.bookId};
});
