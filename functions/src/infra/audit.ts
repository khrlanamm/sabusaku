import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";

import {auditCol} from "./firebase";

/**
 * Records who did what. Server-side only: no security rule exposes
 * `auditLogs`. Entries carry IDs and counts, never journal text.
 */
export async function audit(
  schoolId: string,
  actorUid: string,
  action: string,
  details: Record<string, unknown> = {},
): Promise<void> {
  logger.info(action, {schoolId, actorUid, ...details});
  await auditCol(schoolId).add({
    action,
    actorUid,
    details,
    at: FieldValue.serverTimestamp(),
  });
}
