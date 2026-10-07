// Resets the local emulators and seeds the school used by the Flutter
// integration tests (integration_test/). Emulator only.
//
//   npx tsx tools/seed-e2e.ts --emulator
//
// Every account gets the same known initial password so the tests can sign in.

import {run, useEmulator} from "./_env";

import {auth} from "../src/infra/firebase";
import {createSchool} from "../src/infra/schools";

export const E2E_SCHOOL = "e2e";
export const E2E_PASSWORD = "awal1234";

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

  await clearEmulators();

  const admin = await createSchool(E2E_SCHOOL, "SMA Uji Coba", {
    username: "admin",
    name: "Admin Uji",
  });
  await auth.updateUser(admin.uid, {password: E2E_PASSWORD});

  console.log(`Seed e2e selesai: sekolah "${E2E_SCHOOL}", password awal "${E2E_PASSWORD}".`);
});
