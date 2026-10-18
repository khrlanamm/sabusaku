import {FieldValue} from "firebase-admin/firestore";

import {
  compareClassLabels,
  isValidEmail,
  normalizeClassLabel,
  normalizeEmail,
} from "../domain/labels";
import {MAX_CLASSES, MAX_MEMBER_EXTRACURRICULARS, Role} from "../domain/types";
import {forgetStudentCovers} from "./books";
import {
  activeProgramsCol,
  auth,
  db,
  deleteAvatar,
  membersCol,
  programsCol,
  schoolRef,
  statsCol,
  usersCol,
} from "./firebase";
import {forgetReports} from "./reports";
import {removeFromBoards} from "./rankings";
import {refreshStudentStats} from "./stats";

/** `members/{email}`: who may join which school, before and after sign-in. */
export interface MemberInput {
  email: string;
  role: Role;
  name?: string | null;
  /** Raw class text; normalised to a label such as `XII-A1`. */
  classId?: string | null;
  extracurriculars?: string[];
  /** Teachers: raw text of the class they are the homeroom teacher of. */
  homeroomClass?: string | null;
}

export type AddMemberResult =
  | {email: string; ok: true; created: boolean}
  | {email: string; ok: false; reason: string};

/** gRPC ALREADY_EXISTS from `create()`. */
const ALREADY_EXISTS = 6;

export class MemberError extends Error {}

/**
 * Validates a roster row against the school's labels. Returns the cleaned
 * fields, or a reason in Indonesian. Valid class labels the school does not
 * list yet are reported in `newClass` so the caller can add them.
 */
export function cleanMember(
  input: MemberInput,
  school: {classes: string[]; extracurriculars: string[]},
):
  | {
      ok: true;
      email: string;
      name: string;
      classId: string | null;
      extracurriculars: string[];
      homeroomClass: string | null;
      newClass: string | null;
    }
  | {ok: false; email: string; reason: string} {
  const email = normalizeEmail(input.email);
  if (!isValidEmail(email)) return {ok: false, email, reason: "Format email tidak valid."};

  const name = (input.name ?? "").trim().replace(/\s+/g, " ");
  if (name.length > 80) return {ok: false, email, reason: "Nama maksimal 80 karakter."};
  if (name.length === 1) return {ok: false, email, reason: "Nama minimal 2 karakter."};

  let classId: string | null = null;
  let newClass: string | null = null;
  const rawClass = (input.classId ?? "").trim();
  if (rawClass && input.role === "siswa") {
    classId = normalizeClassLabel(rawClass);
    if (!classId) {
      return {ok: false, email, reason: `Kelas "${rawClass}" tidak dikenali. Contoh: XII-A1.`};
    }
    if (!school.classes.includes(classId)) newClass = classId;
  }

  // A homeroom class must already be listed: unlike a student's class, it
  // is picked from the school's list and never adds a label.
  let homeroomClass: string | null = null;
  const rawHomeroom = (input.homeroomClass ?? "").trim();
  if (rawHomeroom && input.role === "guru") {
    homeroomClass = normalizeClassLabel(rawHomeroom);
    if (!homeroomClass || !school.classes.includes(homeroomClass)) {
      return {ok: false, email, reason: `Kelas "${rawHomeroom}" belum ada di sekolah.`};
    }
  }

  const wanted = [...new Set((input.extracurriculars ?? []).map((item) => item.trim()).filter(Boolean))];
  const known = new Map(school.extracurriculars.map((item) => [item.toLowerCase(), item]));
  const extracurriculars: string[] = [];
  for (const item of wanted) {
    const match = known.get(item.toLowerCase());
    if (!match) return {ok: false, email, reason: `Ekskul "${item}" belum ada di sekolah.`};
    if (!extracurriculars.includes(match)) extracurriculars.push(match);
  }
  if (extracurriculars.length > MAX_MEMBER_EXTRACURRICULARS) {
    return {ok: false, email, reason: `Maksimal ${MAX_MEMBER_EXTRACURRICULARS} ekskul.`};
  }

  return {ok: true, email, name, classId, extracurriculars, homeroomClass, newClass};
}

export async function loadSchoolLabels(schoolId: string) {
  const school = await schoolRef(schoolId).get();
  if (!school.exists) throw new MemberError(`Sekolah "${schoolId}" tidak ditemukan.`);
  return {
    classes: (school.get("classes") as string[] | undefined) ?? [],
    extracurriculars: (school.get("extracurriculars") as string[] | undefined) ?? [],
  };
}

/** Adds class labels to the school, keeping the list sorted and bounded. */
export async function addSchoolClasses(schoolId: string, labels: string[]): Promise<void> {
  if (labels.length === 0) return;
  await db.runTransaction(async (transaction) => {
    const ref = schoolRef(schoolId);
    const school = await transaction.get(ref);
    const current = (school.get("classes") as string[] | undefined) ?? [];
    const merged = [...new Set([...current, ...labels])].sort(compareClassLabels);
    if (merged.length > MAX_CLASSES) {
      throw new MemberError(`Sekolah maksimal ${MAX_CLASSES} kelas.`);
    }
    if (merged.length !== current.length) transaction.update(ref, {classes: merged});
  });
}

/**
 * Creates a roster entry. An email already on any roster is refused without
 * saying which school holds it; the same school is reported as `created:
 * false` so imports can be re-run.
 */
export async function addMember(
  schoolId: string,
  cleaned: {
    email: string;
    name: string;
    classId: string | null;
    extracurriculars: string[];
    homeroomClass?: string | null;
  },
  role: Role,
  addedBy: string,
): Promise<AddMemberResult> {
  const ref = membersCol().doc(cleaned.email);
  try {
    await ref.create({
      email: cleaned.email,
      schoolId,
      role,
      name: cleaned.name,
      classId: role === "siswa" ? cleaned.classId : null,
      extracurriculars: cleaned.extracurriculars,
      ...(role === "guru" ? {homeroomClass: cleaned.homeroomClass ?? null} : {}),
      uid: null,
      addedBy,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {email: cleaned.email, ok: true, created: true};
  } catch (error) {
    if ((error as {code?: number}).code !== ALREADY_EXISTS) throw error;
    const existing = await ref.get();
    if (existing.get("schoolId") === schoolId && existing.get("role") === role) {
      return {email: cleaned.email, ok: true, created: false};
    }
    return {email: cleaned.email, ok: false, reason: "Email sudah terdaftar."};
  }
}

export interface ClaimResult {
  role: Role;
  schoolId: string;
}

/**
 * Google serves account photos at 96 px (`…=s96-c`); profile screens need
 * more. Other URLs are returned unchanged.
 */
export function upsizeGooglePhoto(url: string): string {
  return /googleusercontent\.com\//.test(url) ? url.replace(/=s\d+-c$/, "=s400-c") : url;
}

/** The photo of the account's linked Google sign-in, if any. */
async function googlePhotoOf(uid: string, fallback: string | null) {
  const record = await auth.getUser(uid);
  const google = record.providerData.find((provider) => provider.providerId === "google.com");
  const photo = google?.photoURL ?? fallback;
  return {record, photo: photo ? upsizeGooglePhoto(photo) : null};
}

/**
 * Binds a verified sign-in to its roster entry: claims, profile document and,
 * for a student, the summary. Returns null when the email is on no roster.
 *
 * Runs after every Google sign-in, so it writes only what changed. An empty
 * profile photo is filled from the Google account; an existing photo is never
 * replaced.
 */
export async function claimMembership(
  uid: string,
  rawEmail: string,
  tokenPicture: string | null,
): Promise<ClaimResult | null> {
  const email = normalizeEmail(rawEmail);
  const memberRef = membersCol().doc(email);
  const member = await memberRef.get();
  if (!member.exists) return null;

  const role = member.get("role") as Role;
  const schoolId = member.get("schoolId") as string;
  const userRef = usersCol(schoolId).doc(uid);
  const {record, photo} = await googlePhotoOf(uid, tokenPicture);

  const previousUid = (member.get("uid") as string | null) ?? null;
  const previousRef =
    previousUid && previousUid !== uid ? usersCol(schoolId).doc(previousUid) : null;

  const profileChanged = await db.runTransaction(async (transaction) => {
    const user = await transaction.get(userRef);
    const previous = previousRef ? await transaction.get(previousRef) : null;
    const now = FieldValue.serverTimestamp();
    // The email moved to a new account (the old one was deleted): the old
    // profile must not keep showing up as a second student.
    if (previous?.exists && previous.get("status") !== "removed") {
      transaction.update(previous.ref, {status: "removed", updatedAt: now});
    }
    if (member.get("uid") !== uid) transaction.update(memberRef, {uid, updatedAt: now});

    if (!user.exists) {
      transaction.set(userRef, {
        role,
        name: (member.get("name") as string | undefined) ?? "",
        email,
        classId: role === "siswa" ? ((member.get("classId") as string | null) ?? null) : null,
        extracurriculars: (member.get("extracurriculars") as string[] | undefined) ?? [],
        ...(role === "guru"
          ? {homeroomClass: (member.get("homeroomClass") as string | null | undefined) ?? null}
          : {}),
        photoUrl: photo,
        status: "active",
        createdAt: now,
        updatedAt: now,
      });
      return true;
    }

    // Re-joining keeps the profile the user already filled in.
    const patch: Record<string, unknown> = {};
    if (user.get("status") !== "active") patch.status = "active";
    if (user.get("email") !== email) patch.email = email;
    if (user.get("role") !== role) patch.role = role;
    if (!user.get("name") && member.get("name")) patch.name = member.get("name");
    if (role === "siswa" && !user.get("classId") && member.get("classId")) {
      patch.classId = member.get("classId");
    }
    if (role === "guru" && !user.get("homeroomClass") && member.get("homeroomClass")) {
      patch.homeroomClass = member.get("homeroomClass");
    }
    if (!user.get("photoUrl") && photo) patch.photoUrl = photo;
    if (Object.keys(patch).length === 0) return false;
    transaction.update(userRef, {...patch, updatedAt: now});
    return true;
  });

  const claims = record.customClaims ?? {};
  const claimsChanged = claims.role !== role || claims.schoolId !== schoolId;
  if (claimsChanged) await auth.setCustomUserClaims(uid, {role, schoolId});
  if (role === "siswa" && (profileChanged || claimsChanged)) {
    await refreshStudentStats(schoolId, uid);
  }
  return {role, schoolId};
}

/** Removes school claims and ends sessions; the Auth account itself stays. */
export async function revokeSchoolAccess(uid: string): Promise<void> {
  try {
    await auth.setCustomUserClaims(uid, null);
    await auth.revokeRefreshTokens(uid);
  } catch (error) {
    if ((error as {code?: string}).code !== "auth/user-not-found") throw error;
  }
}

/**
 * Takes someone out of a school: roster entry gone, claims cleared, profile
 * marked `removed` (which drops a student's summary through `onUserUpdated`).
 * Journals stay, so adding the same email again restores the history.
 */
export async function removeMember(schoolId: string, email: string): Promise<string | null> {
  const memberRef = membersCol().doc(email);
  const member = await memberRef.get();
  if (!member.exists || member.get("schoolId") !== schoolId) {
    throw new MemberError("Anggota tidak ditemukan.");
  }
  const uid = (member.get("uid") as string | null) ?? null;
  await memberRef.delete();
  if (uid) {
    await revokeSchoolAccess(uid);
    const userRef = usersCol(schoolId).doc(uid);
    if ((await userRef.get()).exists) {
      await userRef.update({status: "removed", updatedAt: FieldValue.serverTimestamp()});
    }
  }
  return uid;
}

/**
 * Permanently deletes a student's data in a school: profile, summary,
 * leaderboard rows, lock, every program with its journals and comments, and
 * the photo. Reports they
 * filed go too, and reports about them lose their copy of the content. The
 * Auth account is not touched here. Returns the number of programs removed.
 */
export async function eraseStudentData(schoolId: string, uid: string): Promise<number> {
  // The profile goes first: triggers fired by the deletes below then find no
  // student and do not rebuild the summary.
  await db.recursiveDelete(usersCol(schoolId).doc(uid));
  await activeProgramsCol(schoolId).doc(uid).delete();
  await statsCol(schoolId).doc(uid).delete();
  await removeFromBoards(schoolId, uid);

  const programs = await programsCol(schoolId).where("studentId", "==", uid).get();
  for (const program of programs.docs) await db.recursiveDelete(program.ref);
  await deleteAvatar(schoolId, uid);
  await forgetStudentCovers(schoolId, uid);
  await forgetReports(uid);
  return programs.size;
}
