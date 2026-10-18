import {CallableRequest, HttpsError} from "firebase-functions/v2/https";
import {ZodType} from "zod";

import {isSuperadmin} from "../config";
import {Role} from "../domain/types";
import {usersCol} from "./firebase";

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

export interface Superadmin {
  uid: string;
  email: string;
  name: string;
  picture: string | null;
}

/**
 * Authorises a superadmin callable from the verified email of the ID token,
 * so it works before the account has joined any school.
 */
export function requireSuperadmin(request: CallableRequest): Superadmin {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan masuk kembali.");
  const token = request.auth.token;
  if (token.email_verified !== true || !isSuperadmin(token.email)) {
    throw new HttpsError("permission-denied", "Akses ditolak.");
  }
  return {
    uid: request.auth.uid,
    email: token.email!.trim().toLowerCase(),
    name: typeof token.name === "string" && token.name.trim().length >= 2 ? token.name.trim() : "Superadmin",
    picture: typeof token.picture === "string" ? token.picture : null,
  };
}

export function parseInput<T>(schema: ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new HttpsError("invalid-argument", "Data yang dikirim tidak valid.");
  }
  return result.data;
}
