// Suspends or reactivates a school.
//
//   npx tsx tools/set-school-status.ts --code sman1 --status suspended [--emulator]
//
// Suspending disables every account of the school and revokes their sessions.

import {requireArg, run, target} from "./_env";

import {setSchoolStatus} from "../src/infra/schools";

run(async () => {
  const code = requireArg("code").toLowerCase();
  const status = requireArg("status");
  if (status !== "active" && status !== "suspended") {
    throw new Error('--status harus "active" atau "suspended".');
  }

  const accounts = await setSchoolStatus(code, status);
  console.log(`Sekolah ${code} sekarang ${status} di ${target()} (${accounts} akun diperbarui).`);
});
