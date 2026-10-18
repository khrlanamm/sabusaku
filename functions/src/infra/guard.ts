import {CallableRequest, HttpsError} from "firebase-functions/v2/https";
import {ZodType} from "zod";

import {normalizeEmail} from "../domain/labels";
import {isSuperadminEmail} from "../domain/superadmin";
import {Role} from "../domain/types";
import {auth, usersCol} from "./firebase";

export interface Caller {
  uid: string;
  role: Role;
  schoolId: string;
}

/**
 * Authorises a callable from the ID token claims, then confirms the account is
 * still in the school: claims of a removed user stay in their token for up to
 * an hour.
 */
export async function requireCaller(
  request: CallableRequest,
  roles: readonly Role[],
): Promise<Caller> {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");

  const {role, schoolId} = request.auth.token as Record<string, unknown>;
  if (
    typeof role !== "string" ||
    typeof schoolId !== "string" ||
    !roles.includes(role as Role)
  ) {
    throw new HttpsError("permission-denied", "Akses ditolak.");
  }

  const profile = await usersCol(schoolId).doc(request.auth.uid).get();
  if (!profile.exists || profile.get("status") !== "active") {
    throw new HttpsError("permission-denied", "Akun tidak aktif.");
  }

  return {uid: request.auth.uid, role: role as Role, schoolId};
}

export interface SuperadminCaller {
  uid: string;
  email: string;
  /** The school the superadmin has open, if any. */
  schoolId: string | null;
}

/**
 * Authorises the superadmin by email (`SUPERADMIN_EMAILS`), not by claim. The
 * email must be proven: verified, or the address of the linked Google
 * account (Google accounts that later added a password show up unverified).
 */
export async function requireSuperadmin(request: CallableRequest): Promise<SuperadminCaller> {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");
  const token = request.auth.token;
  const email = token.email ? normalizeEmail(token.email) : "";
  if (!isSuperadminEmail(email) || !(await emailProven(request.auth.uid, email, token.email_verified))) {
    throw new HttpsError("permission-denied", "Akses ditolak.");
  }
  const schoolId = (token as Record<string, unknown>).schoolId;
  return {
    uid: request.auth.uid,
    email,
    schoolId: typeof schoolId === "string" && schoolId ? schoolId : null,
  };
}

async function emailProven(uid: string, email: string, verified: boolean | undefined) {
  if (verified === true) return true;
  const record = await auth.getUser(uid);
  return record.providerData.some(
    (provider) => provider.providerId === "google.com" && normalizeEmail(provider.email ?? "") === email,
  );
}

export function parseInput<T>(schema: ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new HttpsError("invalid-argument", "Data yang dikirim tidak valid.");
  }
  return result.data;
}
