// Resets the local emulators and seeds the school used by the Flutter
// integration tests (integration_test/). Emulator only.
//
//   npx tsx tools/seed-e2e.ts --emulator --initial <min 8 chars>
//
// Every account gets `--initial` as its first sign-in secret, so the tests,
// which receive the same value from tool/e2e.sh, can sign in.

import {requireArg, run, useEmulator} from "./_env";

import {auth} from "../src/infra/firebase";
import {createSchool} from "../src/infra/schools";

export const E2E_SCHOOL = "e2e";

async function clearEmulators(): Promise<void> {
  const project = process.env.GCLOUD_PROJECT;
  const targets = [
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${project}/accounts`,
  ];
  for (const url of targets) {
    const response = await fetch(url, {method: "DELETE"});
    if (!response.ok) throw new Error(`Gagal mengosongkan emulator: ${url} (${response.status})`);
  }
}

run(async () => {
  if (!useEmulator) throw new Error("seed-e2e hanya untuk emulator. Tambahkan --emulator.");

  const initial = requireArg("initial");
  if (initial.length < 8) throw new Error("--initial minimal 8 karakter.");

  await clearEmulators();

  const admin = await createSchool(E2E_SCHOOL, "SMA Uji Coba", {
    username: "admin",
    name: "Admin Uji",
  });
  await auth.updateUser(admin.uid, {password: initial});

  console.log(`Seed e2e selesai: sekolah "${E2E_SCHOOL}".`);
});
