import {FieldValue} from "firebase-admin/firestore";

import {pseudoEmail} from "../domain/identity";
import {Role} from "../domain/types";
import {auth, classesCol, db, statsCol, usersCol} from "./firebase";
import {generatePassword} from "./passwords";
import {emptyStats, withTimestamp} from "./stats";

export interface NewAccount {
  role: Role;
  name: string;
  username: string;
  /** Students: their single class. */
  classId?: string | null;
  className?: string | null;
  /** Teachers: assigned classes. */
  classIds?: string[];
}

export interface CreatedAccount {
  uid: string;
  username: string;
  password: string;
}

export class UsernameTakenError extends Error {
  constructor(username: string) {
    super(`Username "${username}" sudah dipakai.`);
  }
}

export function claimsFor(schoolId: string, role: Role, classIds: string[] = []) {
  return role === "guru" ? {role, schoolId, classIds} : {role, schoolId};
}

/**
 * Creates the Auth account, its claims, the `users` document and, for a
 * student, the initial `studentStats`. The Auth account is rolled back when a
 * later step fails so a retry can reuse the username.
 */
export async function createAccount(
  schoolId: string,
  input: NewAccount,
): Promise<CreatedAccount> {
  const password = generatePassword();
  let uid: string;
  try {
    const record = await auth.createUser({
      email: pseudoEmail(schoolId, input.username),
      password,
      displayName: input.name,
    });
    uid = record.uid;
  } catch (error) {
    if ((error as {code?: string}).code === "auth/email-already-exists") {
      throw new UsernameTakenError(input.username);
    }
    throw error;
  }

  try {
    const classIds = input.role === "guru" ? (input.classIds ?? []) : [];
    const classId = input.role === "siswa" ? (input.classId ?? null) : null;
    await auth.setCustomUserClaims(uid, claimsFor(schoolId, input.role, classIds));

    const batch = db.batch();
    batch.set(usersCol(schoolId).doc(uid), {
      role: input.role,
      name: input.name,
      username: input.username,
      nis: input.role === "siswa" ? input.username : null,
      classId,
      classIds,
      status: "active",
      mustChangePassword: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (input.role === "siswa") {
      batch.set(
        statsCol(schoolId).doc(uid),
        withTimestamp(
          emptyStats({
            uid,
            name: input.name,
            nis: input.username,
            classId,
            className: input.className ?? null,
          }),
        ),
      );
    }
    for (const id of classIds) {
      batch.update(classesCol(schoolId).doc(id), {teacherIds: FieldValue.arrayUnion(uid)});
    }
    await batch.commit();
  } catch (error) {
    await auth.deleteUser(uid).catch(() => undefined);
    throw error;
  }

  return {uid, username: input.username, password};
}
