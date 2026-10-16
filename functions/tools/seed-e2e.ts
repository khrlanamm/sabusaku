// Resets the local emulators and seeds the school used by the Flutter
// integration tests (integration_test/). Emulator only.
//
//   npx tsx tools/seed-e2e.ts --emulator --initial <min 8 chars>
//
// Accounts that sign in with a password get `--initial`, which the tests
// receive from tool/e2e.sh as well. Keep these values in sync with
// integration_test/support.dart:
//
//   school   e2e "SMA Uji Coba"; classes XII-A1, XII-A2; default ekskul
//   guru     guru@e2e.test       "Sari Wulandari"  password, joined
//   siswa    siswa@e2e.test      "Raka Pratama"    password, joined, XII-A1, Masis-KIR
//   siswa    baru@e2e.test       (no name, class)  password, not joined yet
//            → the app joins it and sends it to "Lengkapi akun"
//   siswa    google@e2e.test     "Gita Lestari"    roster only; the first sign-in
//            with the emulator's fake Google ID token creates the account (no
//            password), XII-A2:
//            {"sub":"google-e2e","email":"google@e2e.test","email_verified":true}
//   siswa    daftar@e2e.test     roster only, no account (for "Daftar")
//   outsider luar@e2e.test       password, on no roster
//            → "Harap Menghubungi Administrator Sekolah"

import {requireArg, run, useEmulator} from "./_env";

import {auth} from "../src/infra/firebase";
import {addMember, claimMembership} from "../src/infra/members";
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
  await createSchool(E2E_SCHOOL, "SMA Uji Coba", ["XII-A1", "XII-A2"]);

  const roster = [
    {email: "guru@e2e.test", role: "guru", name: "Sari Wulandari", classId: null, extracurriculars: ["Masis-KIR"]},
    {email: "siswa@e2e.test", role: "siswa", name: "Raka Pratama", classId: "XII-A1", extracurriculars: ["Masis-KIR"]},
    {email: "baru@e2e.test", role: "siswa", name: "", classId: null, extracurriculars: []},
    {email: "google@e2e.test", role: "siswa", name: "Gita Lestari", classId: "XII-A2", extracurriculars: []},
    {email: "daftar@e2e.test", role: "siswa", name: "Dewi Anggraini", classId: "XII-A1", extracurriculars: []},
  ] as const;
  for (const row of roster) {
    const result = await addMember(E2E_SCHOOL, {...row, extracurriculars: [...row.extracurriculars]}, row.role, "developer");
    if (!result.ok) throw new Error(`${row.email}: ${result.reason}`);
  }

  const withPassword = async (email: string, displayName?: string) =>
    (await auth.createUser({email, password: initial, emailVerified: true, displayName})).uid;

  // Already joined: sign straight into their shell.
  for (const email of ["guru@e2e.test", "siswa@e2e.test"]) {
    await claimMembership(await withPassword(email), email, null);
  }
  // Joined by the app at first sign-in.
  await withPassword("baru@e2e.test");
  await withPassword("luar@e2e.test", "Orang Luar");

  // google@e2e.test has no account yet: like a real student, the first
  // Google sign-in creates it, and the app then asks for a password.

  console.log(`Seed e2e selesai: sekolah "${E2E_SCHOOL}".`);
});
