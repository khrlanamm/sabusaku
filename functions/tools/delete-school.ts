// Permanently deletes a school: every account and every document under it.
//
//   npx tsx tools/delete-school.ts --code demo --confirm demo [--emulator]
//
// `--confirm` must repeat the code. There is no undo; export first with
// tools/export-school.ts when the data may be needed.

import {requireArg, run, target} from "./_env";

import {auth, db, schoolRef, usersCol} from "../src/infra/firebase";

run(async () => {
  const code = requireArg("code").toLowerCase();
  if (requireArg("confirm").toLowerCase() !== code) {
    throw new Error("--confirm harus sama dengan --code.");
  }

  const school = await schoolRef(code).get();
  if (!school.exists) throw new Error(`Sekolah "${code}" tidak ditemukan.`);

  const users = await usersCol(code).select().get();
  const uids = users.docs.map((doc) => doc.id);
  // deleteUsers accepts at most 1000 accounts per call.
  for (let start = 0; start < uids.length; start += 1000) {
    const result = await auth.deleteUsers(uids.slice(start, start + 1000));
    if (result.failureCount > 0) {
      throw new Error(`${result.failureCount} akun gagal dihapus; data sekolah belum disentuh.`);
    }
  }
  await db.recursiveDelete(school.ref);

  console.log(`Sekolah "${code}" dihapus dari ${target()} (${uids.length} akun).`);
});
