import {logger} from "firebase-functions/v2";
import {MulticastMessage} from "firebase-admin/messaging";

import {messaging, usersCol} from "./firebase";

/** FCM has no emulator; never send real pushes from local runs or tests. */
const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/**
 * Sends to every device of a user and removes tokens FCM reports as dead.
 * Returns the number of devices reached.
 */
export async function sendToUser(
  schoolId: string,
  uid: string,
  message: Omit<MulticastMessage, "tokens">,
): Promise<number> {
  const devices = await usersCol(schoolId).doc(uid).collection("devices").get();
  const tokens = devices.docs.map((doc) => doc.get("token") as string).filter(Boolean);
  if (tokens.length === 0 || isEmulator) return 0;

  const response = await messaging.sendEachForMulticast({...message, tokens});
  await Promise.all(
    response.responses.map((result, index) => {
      if (result.success || !DEAD_TOKEN_CODES.has(result.error?.code ?? "")) return undefined;
      return devices.docs[index].ref.delete();
    }),
  );
  if (response.failureCount > 0) {
    logger.warn("fcm partial failure", {schoolId, failures: response.failureCount});
  }
  return response.successCount;
}

/** Tells the user's devices to refresh their ID token after a claim change. */
export async function notifyClaimsChanged(schoolId: string, uid: string): Promise<void> {
  await sendToUser(schoolId, uid, {
    data: {type: "claims_changed"},
    android: {priority: "high"},
  });
}
