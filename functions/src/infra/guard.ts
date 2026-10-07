import {CallableRequest, HttpsError} from "firebase-functions/v2/https";
import {ZodType} from "zod";

import {Role} from "../domain/types";
import {usersCol} from "./firebase";

export interface Caller {
  uid: string;
  role: Role;
  schoolId: string;
  /** Teachers only. */
  classIds: string[];
}

/**
 * Authorises a callable from the ID token claims, then confirms the account is
 * still active: a disabled user's token stays valid for up to an hour.
 */
export async function requireCaller(
  request: CallableRequest,
  roles: readonly Role[],
): Promise<Caller> {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");

  const {role, schoolId, classIds} = request.auth.token as Record<string, unknown>;
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

  return {
    uid: request.auth.uid,
    role: role as Role,
    schoolId,
    classIds: Array.isArray(classIds) ? (classIds as string[]) : [],
  };
}

export function parseInput<T>(schema: ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new HttpsError("invalid-argument", "Data yang dikirim tidak valid.");
  }
  return result.data;
}

/** The target user of an admin action; must belong to the caller's school. */
export async function loadUser(schoolId: string, uid: string) {
  const snapshot = await usersCol(schoolId).doc(uid).get();
  if (!snapshot.exists) throw new HttpsError("not-found", "Pengguna tidak ditemukan.");
  return snapshot;
}
