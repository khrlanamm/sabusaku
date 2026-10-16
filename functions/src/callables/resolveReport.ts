import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {audit} from "../infra/audit";
import {usersCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";
import {MAX_REPORT_TEXT, resolveReportDoc} from "../infra/reports";

const inputSchema = z.object({
  id: z.string().regex(/^[A-Za-z0-9_-]{1,128}$/),
  resolution: z.string().trim().max(MAX_REPORT_TEXT).nullish(),
});

/**
 * A teacher closes a report filed in, or about, their school, with an
 * optional note on what was done. Resolving it again changes nothing.
 */
export const resolveReport = onCall(CALLABLE_OPTIONS, async (request): Promise<{ok: true}> => {
  const caller = await requireCaller(request, ["guru"]);
  const {id, resolution} = parseInput(inputSchema, request.data);
  const profile = await usersCol(caller.schoolId).doc(caller.uid).get();
  const name = (profile.get("name") as string | undefined) || "Penanggung jawab";

  const resolved = await resolveReportDoc(id, {uid: caller.uid, name}, resolution || null, (report) => {
    const schools = (report.get("schools") as string[] | undefined) ?? [];
    if (!schools.includes(caller.schoolId)) throw new HttpsError("permission-denied", "Akses ditolak.");
  });

  if (resolved) await audit(caller.schoolId, caller.uid, "resolveReport", {reportId: id});
  return {ok: true};
});
