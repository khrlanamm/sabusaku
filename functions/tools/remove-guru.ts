// Takes a teacher (penanggung jawab) out of their school. Their own sign-in
// account stays; they lose access to the school.
//
//   npx tsx tools/remove-guru.ts --email guru@gmail.com [--emulator]

import {requireArg, run, target} from "./_env";

import {normalizeEmail} from "../src/domain/labels";
import {membersCol} from "../src/infra/firebase";
import {removeMember} from "../src/infra/members";

run(async () => {
  const email = normalizeEmail(requireArg("email"));
  const member = await membersCol().doc(email).get();
  if (!member.exists) throw new Error(`${email} tidak terdaftar di sekolah mana pun.`);
  if (member.get("role") !== "guru") throw new Error(`${email} bukan penanggung jawab.`);

  const schoolId = member.get("schoolId") as string;
  await removeMember(schoolId, email);
  console.log(`${email} dikeluarkan dari ${schoolId} di ${target()}.`);
});
