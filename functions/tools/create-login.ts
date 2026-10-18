// Creates or updates an email + password account whose email is already
// verified, for a login nobody signs up for by hand: the Play Console
// reviewer (store/play-console.md §2.2). The password is read from a file, so
// it never reaches the shell history or the terminal.
//
//   npx tsx tools/create-login.ts --email reviewer@gmail.com
//       --password-file ../secret/play-reviewer.txt [--emulator]
//
// The file holds `password: …` on a line of its own; other lines are
// ignored. Put the email on a school's roster with add-guru.ts or
// import-students.ts afterwards: an account that already exists joins the
// school right away.

import {readFileSync} from "node:fs";

import {requireArg, run, target} from "./_env";

import {normalizeEmail} from "../src/domain/labels";
import {auth} from "../src/infra/firebase";

run(async () => {
  const email = normalizeEmail(requireArg("email"));
  const file = readFileSync(requireArg("password-file"), "utf8");
  const password = /^password:\s*(\S+)\s*$/m.exec(file)?.[1];
  if (!password || password.length < 8) {
    throw new Error("Berkas tidak memuat baris `password: …` (minimal 8 karakter).");
  }

  const existing = await auth.getUserByEmail(email).catch(() => null);
  if (existing) {
    await auth.updateUser(existing.uid, {password, emailVerified: true});
  } else {
    await auth.createUser({email, password, emailVerified: true});
  }
  console.log(`${existing ? "Diperbarui" : "Dibuat"} di ${target()}: ${email}, email terverifikasi.`);
});
