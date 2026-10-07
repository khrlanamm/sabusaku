import {readFileSync} from "node:fs";
import {resolve} from "node:path";

import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {doc, Firestore, setDoc} from "firebase/firestore";

export const SCHOOL = "sman1";
export const OTHER_SCHOOL = "sman2";
export const CLASS_1 = "kelas1";
export const CLASS_2 = "kelas2";

export async function createEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: "demo-sabusaku",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8"),
    },
  });
}

export type Db = Firestore;

/** Firestore handles for each actor used across the rules suites. */
export function actors(env: RulesTestEnvironment) {
  const as = (uid: string, claims: Record<string, unknown>) =>
    env.authenticatedContext(uid, claims).firestore() as unknown as Db;
  return {
    admin: as("admin1", {role: "admin", schoolId: SCHOOL}),
    teacher1: as("guru1", {role: "guru", schoolId: SCHOOL, classIds: [CLASS_1]}),
    teacher2: as("guru2", {role: "guru", schoolId: SCHOOL, classIds: [CLASS_2]}),
    student: as("siswa1", {role: "siswa", schoolId: SCHOOL}),
    classmate: as("siswa2", {role: "siswa", schoolId: SCHOOL}),
    outsider: as("siswa9", {role: "siswa", schoolId: OTHER_SCHOOL}),
    otherAdmin: as("admin9", {role: "admin", schoolId: OTHER_SCHOOL}),
    noClaims: as("ghost", {}),
    badRole: as("ghost2", {role: "kepsek", schoolId: SCHOOL}),
    anonymous: env.unauthenticatedContext().firestore() as unknown as Db,
  };
}

const userDoc = (role: string, name: string, extra: Record<string, unknown> = {}) => ({
  role,
  name,
  username: name.toLowerCase().replace(/\s+/g, ""),
  nis: null,
  classId: null,
  classIds: [],
  status: "active",
  mustChangePassword: true,
  ...extra,
});

/** Writes the baseline school, users and classes with rules disabled. */
export async function seedSchool(env: RulesTestEnvironment): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Db;
    const settings = {
      neutralWeekdays: [0],
      holidays: [],
      activeMaxDays: 3,
      attentionMaxDays: 7,
    };
    for (const school of [SCHOOL, OTHER_SCHOOL]) {
      await setDoc(doc(db, `schools/${school}`), {
        name: `Sekolah ${school}`,
        status: "active",
        settings,
      });
    }
    const users = `schools/${SCHOOL}/users`;
    await setDoc(doc(db, `${users}/admin1`), userDoc("admin", "Admin Satu"));
    await setDoc(
      doc(db, `${users}/guru1`),
      userDoc("guru", "Guru Satu", {classIds: [CLASS_1]}),
    );
    await setDoc(
      doc(db, `${users}/guru2`),
      userDoc("guru", "Guru Dua", {classIds: [CLASS_2]}),
    );
    await setDoc(
      doc(db, `${users}/siswa1`),
      userDoc("siswa", "Siswa Satu", {classId: CLASS_1, nis: "1001"}),
    );
    await setDoc(
      doc(db, `${users}/siswa2`),
      userDoc("siswa", "Siswa Dua", {classId: CLASS_1, nis: "1002"}),
    );
    await setDoc(
      doc(db, `schools/${OTHER_SCHOOL}/users/siswa9`),
      userDoc("siswa", "Siswa Luar", {classId: "kelasx", nis: "9001"}),
    );
    for (const [id, name] of [
      [CLASS_1, "XII IPA 1"],
      [CLASS_2, "XII IPA 2"],
    ]) {
      await setDoc(doc(db, `schools/${SCHOOL}/classes/${id}`), {
        name,
        grade: 12,
        academicYear: "2026/2027",
        teacherIds: [],
        isArchived: false,
      });
    }
  });
}

/** WIB calendar date `offset` days from today, as `yyyy-MM-dd`. */
export function wibDate(offset = 0): string {
  const wib = new Date(Date.now() + 7 * 3600_000 + offset * 86400_000);
  return wib.toISOString().slice(0, 10);
}
