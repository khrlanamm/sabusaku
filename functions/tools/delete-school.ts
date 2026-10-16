// Permanently deletes a school: its roster and every document under it.
//
//   npx tsx tools/delete-school.ts --code demo --confirm demo [--emulator]
//
// `--confirm` must repeat the code. There is no undo; export first with
// tools/export-school.ts when the data may be needed.
//
// Sign-in accounts belong to their owners and are kept, only losing their
// school claims. The exception is the old synthetic accounts
// (`…@<code>.sabusaku.invalid`, from before sign-in used real email), which
// nobody can use any more and are deleted.

import {requireArg, run, target} from "./_env";

import {UserRecord} from "firebase-admin/auth";

import {auth, db, membersCol, schoolRef, usersCol} from "../src/infra/firebase";
import {revokeSchoolAccess} from "../src/infra/members";

run(async () => {
  const code = requireArg("code").toLowerCase();
  if (requireArg("confirm").toLowerCase() !== code) {
    throw new Error("--confirm harus sama dengan --code.");
  }

  const school = await schoolRef(code).get();
  if (!school.exists) throw new Error(`Sekolah "${code}" tidak ditemukan.`);

  const [users, members] = await Promise.all([
    usersCol(code).select().get(),
    membersCol().where("schoolId", "==", code).get(),
  ]);
  const uids = new Set(users.docs.map((doc) => doc.id));
  for (const member of members.docs) {
    const uid = member.get("uid") as string | null;
    if (uid) uids.add(uid);
  }

  const synthetic = `@${code}.sabusaku.invalid`;
  const toDelete: string[] = [];
  let kept = 0;
  for (const uid of uids) {
    const record: UserRecord | null = await auth.getUser(uid).catch(() => null);
    if (!record) continue;
    if (record.email?.endsWith(synthetic)) {
      toDelete.push(uid);
    } else if ((record.customClaims ?? {}).schoolId === code) {
      await revokeSchoolAccess(uid);
      kept++;
    }
  }
  // deleteUsers accepts at most 1000 accounts per call.
  for (let start = 0; start < toDelete.length; start += 1000) {
    const result = await auth.deleteUsers(toDelete.slice(start, start + 1000));
    if (result.failureCount > 0) {
      throw new Error(`${result.failureCount} akun lama gagal dihapus; data sekolah belum disentuh.`);
    }
  }

  const batch = db.batch();
  for (const member of members.docs) batch.delete(member.ref);
  await batch.commit();
  await db.recursiveDelete(school.ref);

  console.log(`Sekolah "${code}" dihapus dari ${target()}.`);
  console.log(`  ${members.size} anggota daftar, ${toDelete.length} akun lama dihapus, ${kept} akun dipertahankan.`);
});
