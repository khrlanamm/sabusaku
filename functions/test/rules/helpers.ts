import {readFileSync} from "node:fs";
import {resolve} from "node:path";

import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {doc, Firestore, setDoc} from "firebase/firestore";

export const SCHOOL = "sman1";
export const OTHER_SCHOOL = "sman2";
export const CLASS_1 = "XII-A1";
export const CLASS_2 = "XII-A2";
export const EKSKUL = ["Masis-KIR", "Paskibra", "Pala", "PMR"];

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
    teacher1: as("guru1", {role: "guru", schoolId: SCHOOL}),
    teacher2: as("guru2", {role: "guru", schoolId: SCHOOL}),
    student: as("siswa1", {role: "siswa", schoolId: SCHOOL}),
    classmate: as("siswa2", {role: "siswa", schoolId: SCHOOL}),
    outsider: as("siswa9", {role: "siswa", schoolId: OTHER_SCHOOL}),
    otherTeacher: as("guru9", {role: "guru", schoolId: OTHER_SCHOOL}),
    noClaims: as("ghost", {}),
    // The admin role no longer exists.
    badRole: as("ghost2", {role: "admin", schoolId: SCHOOL}),
    anonymous: env.unauthenticatedContext().firestore() as unknown as Db,
  };
}

export const userDoc = (role: string, name: string, extra: Record<string, unknown> = {}) => ({
  role,
  name,
  email: `${name.toLowerCase().replace(/\s+/g, ".")}@sekolah.test`,
  classId: null,
  extracurriculars: [],
  photoUrl: null,
  status: "active",
  ...extra,
});

export const memberDoc = (
  email: string,
  schoolId: string,
  role: string,
  extra: Record<string, unknown> = {},
) => ({
  email,
  schoolId,
  role,
  name: "",
  classId: null,
  extracurriculars: [],
  uid: null,
  addedBy: "developer",
  ...extra,
});

/** Writes the baseline schools, users and roster with rules disabled. */
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
        classes: [CLASS_1, CLASS_2],
        extracurriculars: EKSKUL,
      });
    }
    const users = `schools/${SCHOOL}/users`;
    await setDoc(doc(db, `${users}/guru1`), userDoc("guru", "Guru Satu"));
    await setDoc(doc(db, `${users}/guru2`), userDoc("guru", "Guru Dua"));
    await setDoc(
      doc(db, `${users}/siswa1`),
      userDoc("siswa", "Siswa Satu", {classId: CLASS_1, extracurriculars: ["Masis-KIR"]}),
    );
    await setDoc(doc(db, `${users}/siswa2`), userDoc("siswa", "Siswa Dua", {classId: CLASS_1}));
    await setDoc(
      doc(db, `schools/${OTHER_SCHOOL}/users/siswa9`),
      userDoc("siswa", "Siswa Luar", {classId: CLASS_1}),
    );
    await setDoc(
      doc(db, "members/siswa.satu@sekolah.test"),
      memberDoc("siswa.satu@sekolah.test", SCHOOL, "siswa", {uid: "siswa1", name: "Siswa Satu"}),
    );
    await setDoc(
      doc(db, "members/calon@sekolah.test"),
      memberDoc("calon@sekolah.test", SCHOOL, "siswa"),
    );
    await setDoc(
      doc(db, "members/guru.satu@sekolah.test"),
      memberDoc("guru.satu@sekolah.test", SCHOOL, "guru", {uid: "guru1", name: "Guru Satu"}),
    );
    await setDoc(
      doc(db, "members/luar@sekolah.test"),
      memberDoc("luar@sekolah.test", OTHER_SCHOOL, "siswa"),
    );
  });
}

/** WIB calendar date `offset` days from today, as `yyyy-MM-dd`. */
export function wibDate(offset = 0): string {
  const wib = new Date(Date.now() + 7 * 3600_000 + offset * 86400_000);
  return wib.toISOString().slice(0, 10);
}
