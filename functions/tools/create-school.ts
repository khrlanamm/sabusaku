// Registers a school. Teachers (penanggung jawab) are added afterwards with
// tools/add-guru.ts and students with tools/import-students.ts or in the app.
//
//   npx tsx tools/create-school.ts --code sman1sukodadi --name "SMA Negeri 1 Sukodadi"
//       [--classes "XII-A1,XII-A2,X-G"] [--emulator]
//
// The school starts with the default extracurriculars (Masis-KIR, Paskibra,
// Pala, PMR); teachers can add more in the app.

import {listArg, requireArg, run, target} from "./_env";

import {DEFAULT_EXTRACURRICULARS} from "../src/domain/labels";
import {createSchool, SCHOOL_ID_RE} from "../src/infra/schools";

run(async () => {
  const code = requireArg("code").toLowerCase();
  const name = requireArg("name");
  if (!SCHOOL_ID_RE.test(code)) {
    throw new Error("Kode sekolah harus 3–30 karakter, huruf kecil dan angka saja.");
  }

  const classes = listArg("classes");
  await createSchool(code, name, classes);

  console.log(`Sekolah dibuat di ${target()}.`);
  console.log(`  Kode  : ${code}`);
  console.log(`  Nama  : ${name}`);
  console.log(`  Kelas : ${classes.length} label`);
  console.log(`  Ekskul: ${DEFAULT_EXTRACURRICULARS.join(", ")}`);
  console.log("Tambahkan penanggung jawab dengan tools/add-guru.ts.");
});
