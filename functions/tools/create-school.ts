// Registers a school and its first admin.
//
//   npx tsx tools/create-school.ts --code sman1 --name "SMA Negeri 1 Contoh"
//       [--admin admin] [--admin-name "Admin Sekolah"] [--emulator]
//
// The initial password is printed once and is not stored anywhere.

import {arg, requireArg, run, target} from "./_env";

import {isValidSchoolId, isValidUsername, normalizeUsername} from "../src/domain/identity";
import {createSchool} from "../src/infra/schools";

run(async () => {
  const code = requireArg("code").toLowerCase();
  const name = requireArg("name");
  const adminUsername = normalizeUsername(arg("admin") ?? "admin");
  const adminName = arg("admin-name") ?? "Admin Sekolah";

  if (!isValidSchoolId(code)) {
    throw new Error("Kode sekolah harus 3–20 karakter, huruf kecil dan angka saja.");
  }
  if (!isValidUsername(adminUsername)) {
    throw new Error("Username admin tidak valid (3–30 karakter: a-z, 0-9, titik, garis bawah, tanda hubung).");
  }

  const account = await createSchool(code, name, {username: adminUsername, name: adminName});

  console.log(`Sekolah dibuat di ${target()}.`);
  console.log(`  Kode sekolah : ${code}`);
  console.log(`  Nama         : ${name}`);
  console.log(`  Admin        : ${account.username}`);
  console.log(`  Password awal: ${account.password}`);
  console.log("Password ini hanya tampil sekali dan wajib diganti saat login pertama.");
});
