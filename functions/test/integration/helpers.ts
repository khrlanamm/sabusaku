// Shared setup for suites that run against the Auth, Firestore and Functions
// emulators (started by `firebase emulators:exec`, which also points the
// Admin SDK at them through environment variables).

import {randomUUID} from "node:crypto";

import {deleteApp, FirebaseApp, initializeApp} from "firebase/app";
import {
  connectAuthEmulator,
  getAuth,
  GoogleAuthProvider,
  signInWithCredential,
  signInWithEmailAndPassword,
  User,
} from "firebase/auth";
import {connectFirestoreEmulator, Firestore, getFirestore} from "firebase/firestore";
import {connectFunctionsEmulator, getFunctions, httpsCallable} from "firebase/functions";

import {REGION} from "../../src/config";
import {Role} from "../../src/domain/types";
import {auth} from "../../src/infra/firebase";
import {addMember, addSchoolClasses, cleanMember, loadSchoolLabels} from "../../src/infra/members";
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

export async function addSchool(schoolId: string, classes: string[] = ["XII-A1", "XII-A2"]) {
  await createSchool(schoolId, `Sekolah ${schoolId}`, classes);
}

export interface Person {
  email: string;
  role: Role;
  name?: string;
  classId?: string | null;
  extracurriculars?: string[];
}

/** Puts someone on a school roster, the way the developer tools do. */
export async function addToRoster(schoolId: string, person: Person): Promise<void> {
  const cleaned = cleanMember(person, await loadSchoolLabels(schoolId));
  if (!cleaned.ok) throw new Error(cleaned.reason);
  if (cleaned.newClass) await addSchoolClasses(schoolId, [cleaned.newClass]);
  const result = await addMember(schoolId, cleaned, person.role, "developer");
  if (!result.ok) throw new Error(result.reason);
}

/** An email/password account; verified unless stated otherwise. */
export async function addPasswordAccount(email: string, verified = true): Promise<string> {
  return (await auth.createUser({email, password: PASSWORD, emailVerified: verified})).uid;
}

export interface Client {
  uid: string;
  user: User;
  db: Firestore;
  call<T = unknown>(name: string, data?: unknown): Promise<T>;
  /** Calls claimAccount and refreshes the token, like the app after sign-in. */
  join(): Promise<{role: string; schoolId: string}>;
  close(): Promise<void>;
}

let clientCount = 0;
const openApps: FirebaseApp[] = [];

function newApp() {
  const app = initializeApp({projectId: PROJECT, apiKey: "fake-api-key"}, `client-${clientCount++}`);
  openApps.push(app);
  const clientAuth = getAuth(app);
  connectAuthEmulator(clientAuth, `http://${AUTH_HOST}`, {disableWarnings: true});
  const db = getFirestore(app);
  const [host, port] = FIRESTORE_HOST.split(":");
  connectFirestoreEmulator(db, host, Number(port));
  const functions = getFunctions(app, REGION);
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  return {app, clientAuth, db, functions};
}

function clientOf(
  parts: ReturnType<typeof newApp>,
  user: User,
): Client {
  const call = async <T>(name: string, data?: unknown) =>
    (await httpsCallable(parts.functions, name)(data ?? {})).data as T;
  return {
    uid: user.uid,
    user,
    db: parts.db,
    call,
    join: async () => {
      const result = await call<{role: string; schoolId: string}>("claimAccount");
      await user.getIdToken(true);
      return result;
    },
    close: () => deleteApp(parts.app),
  };
}

/** A client signed in with email and password, like one phone running the app. */
export async function signIn(email: string, password = PASSWORD): Promise<Client> {
  const parts = newApp();
  const credential = await signInWithEmailAndPassword(parts.clientAuth, email, password);
  return clientOf(parts, credential.user);
}

/**
 * A client signed in with Google. The Auth emulator accepts an unsigned JSON
 * ID token; `sub` identifies the Google account.
 */
export async function signInWithGoogle(
  email: string,
  options: {sub?: string; picture?: string; name?: string} = {},
): Promise<Client> {
  const parts = newApp();
  const idToken = JSON.stringify({
    sub: options.sub ?? `google-${email}`,
    email,
    email_verified: true,
    name: options.name ?? email.split("@")[0],
    ...(options.picture ? {picture: options.picture} : {}),
  });
  const credential = await signInWithCredential(
    parts.clientAuth,
    GoogleAuthProvider.credential(idToken),
  );
  return clientOf(parts, credential.user);
}

/** Roster entry + verified password account + joined: a ready user. */
export async function addJoined(schoolId: string, person: Person): Promise<Client> {
  await addToRoster(schoolId, person);
  await addPasswordAccount(person.email);
  const client = await signIn(person.email);
  await client.join();
  return client;
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
