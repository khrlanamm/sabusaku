import {FieldValue} from "firebase-admin/firestore";

import {compareClassLabels, DEFAULT_EXTRACURRICULARS, normalizeClassLabel} from "../domain/labels";
import {DEFAULT_SETTINGS} from "../domain/types";
import {auth, membersCol, schoolRef, usersCol} from "./firebase";

export type SchoolStatus = "active" | "suspended";

/** School codes, also the `schools/{schoolId}` document ID. */
export const SCHOOL_ID_RE = /^[a-z0-9]{3,30}$/;

/**
 * Creates the school with default settings, the given class labels and the
 * default extracurriculars. Teachers (penanggung jawab) are added separately:
 * by the developer with tools/add-guru.ts, or by a superadmin together with
 * the school (callable `createSchool`).
 */
export async function createSchool(
  schoolId: string,
  name: string,
  classes: string[] = [],
): Promise<void> {
  const labels = classes.map((raw) => {
    const label = normalizeClassLabel(raw);
    if (!label) throw new Error(`Kelas "${raw}" tidak dikenali. Contoh: XII-A1.`);
    return label;
  });
  // create() fails when the code is already taken.
  await schoolRef(schoolId).create({
    name,
    status: "active",
    settings: DEFAULT_SETTINGS,
    classes: [...new Set(labels)].sort(compareClassLabels),
    extracurriculars: DEFAULT_EXTRACURRICULARS,
    createdAt: FieldValue.serverTimestamp(),
  });
}

/**
 * Suspending a school disables every account that joined it and revokes their
 * sessions. Reactivating enables them again. Accounts are the users' own, so
 * nothing is deleted.
 */
export async function setSchoolStatus(
  schoolId: string,
  status: SchoolStatus,
): Promise<number> {
  const ref = schoolRef(schoolId);
  if (!(await ref.get()).exists) throw new Error(`Sekolah "${schoolId}" tidak ditemukan.`);
  await ref.update({status});

  const members = await membersCol().where("schoolId", "==", schoolId).get();
  let changed = 0;
  for (const member of members.docs) {
    const uid = member.get("uid") as string | null;
    if (!uid) continue;
    const profile = await usersCol(schoolId).doc(uid).get();
    const disabled = status === "suspended" || profile.get("status") !== "active";
    try {
      await auth.updateUser(uid, {disabled});
      if (disabled) await auth.revokeRefreshTokens(uid);
      changed++;
    } catch (error) {
      if ((error as {code?: string}).code !== "auth/user-not-found") throw error;
    }
  }
  return changed;
}
