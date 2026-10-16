// Import this first in every tool: it selects the target before the Admin SDK
// is initialised by ../src/infra/firebase.
//
//   --emulator   talk to the local Firebase Emulator Suite
//   (default)    talk to production with the service account in secret/

import {existsSync, readdirSync} from "node:fs";
import {resolve} from "node:path";

const argv = process.argv.slice(2);

export const useEmulator = argv.includes("--emulator");

// Lets the Admin SDK find the default Storage bucket (profile photos).
process.env.FIREBASE_CONFIG ??= JSON.stringify({
  projectId: "sabusaku",
  storageBucket: "sabusaku.firebasestorage.app",
});

if (useEmulator) {
  process.env.GCLOUD_PROJECT ??= "sabusaku";
  process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= "127.0.0.1:9199";
} else if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  const dir = resolve(__dirname, "../../secret");
  const key = existsSync(dir)
    ? readdirSync(dir).find((file) => /adminsdk.*\.json$/.test(file))
    : undefined;
  if (!key) {
    console.error("Service account tidak ditemukan di secret/. Pakai --emulator atau set GOOGLE_APPLICATION_CREDENTIALS.");
    process.exit(1);
  }
  process.env.GOOGLE_APPLICATION_CREDENTIALS = resolve(dir, key);
}

/** True when `--name` is present. */
export const hasFlag = (name: string) => argv.includes(`--${name}`);

/** Value of `--name value`, if present. */
export function arg(name: string): string | undefined {
  const index = argv.indexOf(`--${name}`);
  const value = index >= 0 ? argv[index + 1] : undefined;
  return value && !value.startsWith("--") ? value : undefined;
}

export function requireArg(name: string): string {
  const value = arg(name);
  if (!value) {
    console.error(`Argumen --${name} wajib diisi.`);
    process.exit(1);
  }
  return value;
}

export const secretDir = resolve(__dirname, "../../secret");

/** Comma-separated list argument, trimmed, empty items dropped. */
export function listArg(name: string): string[] {
  return (arg(name) ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export function target(): string {
  return useEmulator ? "EMULATOR" : "PRODUKSI";
}

export function run(main: () => Promise<void>): void {
  main().then(
    () => process.exit(0),
    (error) => {
      console.error(error instanceof Error ? error.message : error);
      process.exit(1);
    },
  );
}
