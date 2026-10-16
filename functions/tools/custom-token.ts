// Prints a Firebase custom token for an existing account, so a screenshot
// run can sign in as that person without a password or a Google account on
// the device (tool/screenshots.sh).
//
//   npx tsx tools/custom-token.ts --email siswa@gmail.com [--emulator]
//
// The token is valid for one hour and grants the account's own access, the
// same as signing in. Never store or commit it.

import {requireArg, run} from "./_env";

import {auth} from "../src/infra/firebase";

run(async () => {
  const user = await auth.getUserByEmail(requireArg("email").toLowerCase());
  process.stdout.write(await auth.createCustomToken(user.uid));
});
