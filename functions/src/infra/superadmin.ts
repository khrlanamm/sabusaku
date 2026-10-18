import {FieldValue} from "firebase-admin/firestore";

import {auth, db, schoolRef, usersCol} from "./firebase";
import {ClaimResult, googlePhotoOf} from "./members";

/**
 * The school the superadmin opens on sign-in: the one open now while it
 * exists, otherwise the first active school by name. Null when there is no
 * school yet.
 */
export async function pickSchool(current: string | null): Promise<string | null> {
  if (current && (await schoolRef(current).get()).exists) return current;
  // Few schools: sorted here rather than with a composite index.
  const active = await db.collection("schools").where("status", "==", "active").select("name").get();
  const first = active.docs
    .map((doc) => ({id: doc.id, name: (doc.get("name") as string | undefined) ?? doc.id}))
    .sort((a, b) => a.name.localeCompare(b.name, "id"))[0];
  return first?.id ?? null;
}

/**
 * Opens a school for the superadmin: a teacher profile there, marked
 * `superadmin` so it stays out of the teacher list, `staff` and the digest,
 * then claims for that school. A new profile copies the name, photo and
 * accepted terms from the school the superadmin comes from. The profile left
 * behind stays active: the app is still listening to it until the new token
 * arrives.
 */
export async function enterSchool(
  uid: string,
  email: string,
  schoolId: string,
  fromSchoolId: string | null,
): Promise<ClaimResult> {
  const profileRef = usersCol(schoolId).doc(uid);
  const fromRef =
    fromSchoolId && fromSchoolId !== schoolId ? usersCol(fromSchoolId).doc(uid) : null;
  const {record, photo} = await googlePhotoOf(uid, null);

  await db.runTransaction(async (transaction) => {
    const profile = await transaction.get(profileRef);
    const from = fromRef ? await transaction.get(fromRef) : null;
    const now = FieldValue.serverTimestamp();

    if (!profile.exists) {
      const copy = (field: string) => (from?.exists ? from.get(field) : undefined);
      const termsVersion = copy("termsVersion") as number | undefined;
      transaction.set(profileRef, {
        role: "guru",
        name: (copy("name") as string | undefined) || record.displayName || "",
        email,
        classId: null,
        extracurriculars: [],
        homeroomClass: null,
        photoUrl: (copy("photoUrl") as string | null | undefined) || photo,
        status: "active",
        superadmin: true,
        ...(termsVersion
          ? {termsVersion, termsAcceptedAt: copy("termsAcceptedAt") ?? now}
          : {}),
        createdAt: now,
        updatedAt: now,
      });
      return;
    }

    const patch: Record<string, unknown> = {};
    if (profile.get("status") !== "active") patch.status = "active";
    if (profile.get("superadmin") !== true) patch.superadmin = true;
    if (profile.get("role") !== "guru") patch.role = "guru";
    if (profile.get("email") !== email) patch.email = email;
    if (!profile.get("photoUrl") && photo) patch.photoUrl = photo;
    if (Object.keys(patch).length > 0) transaction.update(profileRef, {...patch, updatedAt: now});
  });

  const claims = record.customClaims ?? {};
  if (claims.role !== "guru" || claims.schoolId !== schoolId || claims.superadmin !== true) {
    await auth.setCustomUserClaims(uid, {role: "guru", schoolId, superadmin: true});
  }
  return {role: "guru", schoolId};
}
