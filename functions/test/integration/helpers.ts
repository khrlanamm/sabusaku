// Shared setup for suites that run against the Auth, Firestore and Functions
// emulators (started by `firebase emulators:exec`, which also points the
// Admin SDK at them through environment variables).

import {randomUUID} from "node:crypto";

import {deleteApp, FirebaseApp, initializeApp} from "firebase/app";
import {connectAuthEmulator, getAuth, signInWithEmailAndPassword} from "firebase/auth";
import {connectFirestoreEmulator, Firestore, getFirestore} from "firebase/firestore";
import {connectFunctionsEmulator, getFunctions, httpsCallable} from "firebase/functions";

import {REGION} from "../../src/config";
import {pseudoEmail} from "../../src/domain/identity";
import {auth, classesCol} from "../../src/infra/firebase";
import {createAccount, NewAccount} from "../../src/infra/accounts";
import {createSchool} from "../../src/infra/schools";

const PROJECT = process.env.GCLOUD_PROJECT ?? "demo-sabusaku";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099";
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";

/** Sign-in secret shared by every account of a test run; new each run. */
export const PASSWORD = `uji-${randomUUID()}`;

export async function clearEmulators(): Promise<void> {
  await fetch(
    `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    {method: "DELETE"},
  );
  await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT}/accounts`, {
    method: "DELETE",
  });
}

/** Creates an account through the same code path as production. */
export async function addAccount(schoolId: string, input: NewAccount): Promise<string> {
  const account = await createAccount(schoolId, input);
  await auth.updateUser(account.uid, {password: PASSWORD});
  return account.uid;
}

export async function addSchool(schoolId: string): Promise<string> {
  const admin = await createSchool(schoolId, `Sekolah ${schoolId}`, {
    username: "admin",
    name: "Admin Uji",
  });
  await auth.updateUser(admin.uid, {password: PASSWORD});
  return admin.uid;
}

export async function addClass(schoolId: string, id: string, name: string): Promise<void> {
  await classesCol(schoolId).doc(id).set({
    name,
    grade: 12,
    academicYear: "2026/2027",
    teacherIds: [],
    isArchived: false,
  });
}

export interface Client {
  uid: string;
  db: Firestore;
  call<T = unknown>(name: string, data: unknown): Promise<T>;
  close(): Promise<void>;
}

let clientCount = 0;
const openApps: FirebaseApp[] = [];

/** A signed-in client SDK instance, like one phone running the app. */
export async function signIn(
  schoolId: string,
  username: string,
  password = PASSWORD,
): Promise<Client> {
  const app = initializeApp({projectId: PROJECT, apiKey: "fake-api-key"}, `client-${clientCount++}`);
  openApps.push(app);
  const clientAuth = getAuth(app);
  connectAuthEmulator(clientAuth, `http://${AUTH_HOST}`, {disableWarnings: true});
  const db = getFirestore(app);
  const [host, port] = FIRESTORE_HOST.split(":");
  connectFirestoreEmulator(db, host, Number(port));
  const functions = getFunctions(app, REGION);
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);

  const credential = await signInWithEmailAndPassword(
    clientAuth,
    pseudoEmail(schoolId, username),
    password,
  );
  return {
    uid: credential.user.uid,
    db,
    call: async <T>(name: string, data: unknown) =>
      (await httpsCallable(functions, name)(data)).data as T,
    close: () => deleteApp(app),
  };
}

export async function closeClients(): Promise<void> {
  await Promise.all(openApps.splice(0).map((app) => deleteApp(app).catch(() => undefined)));
}

/** Resolves to the callable error code (e.g. `permission-denied`) or "ok". */
export async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
    return "ok";
  } catch (error) {
    return String((error as {code?: string}).code ?? error).replace(/^functions\//, "");
  }
}

/** Polls until `check` returns a value; triggers are asynchronous. */
export async function eventually<T>(
  check: () => Promise<T | undefined | null | false>,
  timeoutMs = 15_000,
): Promise<T> {
  const end = Date.now() + timeoutMs;
  for (;;) {
    const value = await check();
    if (value) return value;
    if (Date.now() > end) throw new Error("Timed out waiting for condition");
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
}

/** WIB calendar date `offset` days from today, as `yyyy-MM-dd`. */
export function wibDate(offset = 0): string {
  const wib = new Date(Date.now() + 7 * 3600_000 + offset * 86400_000);
  return wib.toISOString().slice(0, 10);
}
