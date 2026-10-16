import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "zod";

import {CALLABLE_OPTIONS} from "../config";
import {CURRENT_TERMS_VERSION} from "../domain/terms";
import {audit} from "../infra/audit";
import {usersCol} from "../infra/firebase";
import {parseInput, requireCaller} from "../infra/guard";

const inputSchema = z.object({version: z.number().int()});

/**
 * Records that the caller accepted the terms of use in the version the app
 * showed. The app asks before anything else, since a profile photo and name
 * are already seen by others. `termsVersion` and `termsAcceptedAt` are
 * written only here; the rules keep clients from setting them. Accepting the
 * same version again keeps the first acceptance time.
 */
export const acceptTerms = onCall(CALLABLE_OPTIONS, async (request): Promise<{version: number}> => {
  const caller = await requireCaller(request, ["guru", "siswa"]);
  const {version} = parseInput(inputSchema, request.data);
  // An app built for older terms must not accept newer ones unseen.
  if (version !== CURRENT_TERMS_VERSION) {
    throw new HttpsError("invalid-argument", "Ketentuan sudah diperbarui. Muat ulang aplikasi.");
  }

  const ref = usersCol(caller.schoolId).doc(caller.uid);
  if ((await ref.get()).get("termsVersion") !== version) {
    await ref.update({termsVersion: version, termsAcceptedAt: FieldValue.serverTimestamp()});
    await audit(caller.schoolId, caller.uid, "acceptTerms", {version});
  }
  return {version};
});
