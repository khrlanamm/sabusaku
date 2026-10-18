import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {getStorage} from "firebase-admin/storage";

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();

export const schoolRef = (schoolId: string) => db.doc(`schools/${schoolId}`);
export const usersCol = (schoolId: string) => schoolRef(schoolId).collection("users");
export const statsCol = (schoolId: string) => schoolRef(schoolId).collection("studentStats");
export const programsCol = (schoolId: string) => schoolRef(schoolId).collection("programs");
export const activeProgramsCol = (schoolId: string) =>
  schoolRef(schoolId).collection("activePrograms");
export const auditCol = (schoolId: string) => schoolRef(schoolId).collection("auditLogs");
/** Per school and period: what every student read, readable by the whole school. */
export const leaderboardsCol = (schoolId: string) => schoolRef(schoolId).collection("leaderboards");

/** Top-level roster: `members/{email}`. The ID makes an email belong to one school. */
export const membersCol = () => db.collection("members");

/** The book catalog shared by every school, and what students suggest for it. */
export const booksCol = () => db.collection("books");
export const bookSuggestionsCol = () => db.collection("bookSuggestions");
/** Per school: how many students read each catalog book. */
export const bookStatsCol = (schoolId: string) => schoolRef(schoolId).collection("bookStats");

/** Reports of content and users. Top level: a book report concerns every school. */
export const reportsCol = () => db.collection("reports");

/** Storage path of a profile photo uploaded from the app. */
export const avatarPath = (schoolId: string, uid: string) => `schools/${schoolId}/avatars/${uid}.jpg`;

/**
 * Deletes a profile photo. Missing files and a missing bucket (emulator runs
 * without Storage) are not errors.
 */
export async function deleteAvatar(schoolId: string, uid: string): Promise<void> {
  try {
    await getStorage().bucket().file(avatarPath(schoolId, uid)).delete({ignoreNotFound: true});
  } catch {
    // Storage is optional for this cleanup; the Firestore data is what matters.
  }
}
