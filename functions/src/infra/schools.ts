import {FieldValue} from "firebase-admin/firestore";

import {DEFAULT_SETTINGS} from "../domain/types";
import {CreatedAccount, createAccount} from "./accounts";
import {auth, schoolRef, usersCol} from "./firebase";

export type SchoolStatus = "active" | "suspended";

/** Creates the school with default settings and its first admin. */
export async function createSchool(
  schoolId: string,
  name: string,
  admin: {username: string; name: string},
): Promise<CreatedAccount> {
  const ref = schoolRef(schoolId);
  // create() fails when the code is already taken.
  await ref.create({
    name,
    status: "active",
    settings: DEFAULT_SETTINGS,
    createdAt: FieldValue.serverTimestamp(),
  });
  try {
    return await createAccount(schoolId, {
      role: "admin",
      name: admin.name,
      username: admin.username,
    });
  } catch (error) {
    await ref.delete();
    throw error;
  }
}

/**
 * Suspending a school disables every account and revokes their sessions.
 * Reactivating restores only the accounts that were not individually disabled.
 */
export async function setSchoolStatus(
  schoolId: string,
  status: SchoolStatus,
): Promise<number> {
  const ref = schoolRef(schoolId);
  if (!(await ref.get()).exists) throw new Error(`Sekolah "${schoolId}" tidak ditemukan.`);
  await ref.update({status});

  const users = await usersCol(schoolId).get();
  let changed = 0;
  for (const doc of users.docs) {
    const disabled = status === "suspended" || doc.get("status") !== "active";
    await auth.updateUser(doc.id, {disabled});
    if (disabled) await auth.revokeRefreshTokens(doc.id);
    changed++;
  }
  return changed;
}
