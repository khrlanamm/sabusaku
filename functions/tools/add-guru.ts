// Adds a teacher (penanggung jawab) to a school's roster. Only the developer
// does this; teachers cannot add or remove each other.
//
//   npx tsx tools/add-guru.ts --school sman1sukodadi --email guru@gmail.com
//       --name "Sugito, S.T., M.Pd." [--ekskul "Masis-KIR"] [--emulator]
//
// No account or password is created. The teacher signs in with Google (or
// signs up with this email) and the app joins them to the school. `--ekskul`
// records the extracurriculars they supervise.

import {listArg, requireArg, run, target} from "./_env";

import {
  addMember,
  cleanMember,
  claimMembership,
  loadSchoolLabels,
} from "../src/infra/members";
import {auth} from "../src/infra/firebase";

run(async () => {
  const schoolId = requireArg("school").toLowerCase();
  const labels = await loadSchoolLabels(schoolId);
  const cleaned = cleanMember(
    {
      email: requireArg("email"),
      role: "guru",
      name: requireArg("name"),
      extracurriculars: listArg("ekskul"),
    },
    labels,
  );
  if (!cleaned.ok) throw new Error(cleaned.reason);
  if (cleaned.name.length < 2) throw new Error("Nama minimal 2 karakter.");

  const result = await addMember(schoolId, cleaned, "guru", "developer");
  if (!result.ok) throw new Error(`${cleaned.email}: ${result.reason}`);

  // Someone who already has an account with this email joins right away;
  // otherwise the app does it at their first sign-in.
  const existing = await auth.getUserByEmail(cleaned.email).catch(() => null);
  if (existing?.emailVerified) await claimMembership(existing.uid, cleaned.email, null);

  console.log(
    `${result.created ? "Ditambahkan" : "Sudah terdaftar"} di ${target()}: ` +
      `${cleaned.name} <${cleaned.email}> sebagai penanggung jawab ${schoolId}.`,
  );
});
