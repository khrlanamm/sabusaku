// Puts students on a school's roster from a CSV file.
//
//   npx tsx tools/import-students.ts --school sman1sukodadi --file ../secret/siswa.csv [--emulator]
//
// Header: email,nama,kelas,ekskul   (ekskul: several separated by `;`)
// Class text is normalised (`12 A1` → `XII-A1`) and missing labels are added
// to the school. Students already on this school's roster are reported, not
// changed, so the import can be re-run. The file holds personal data: keep it
// under secret/, never in git.

import {readFileSync} from "node:fs";

import {requireArg, run, target} from "./_env";

import {
  addMember,
  addSchoolClasses,
  claimMembership,
  cleanMember,
  loadSchoolLabels,
} from "../src/infra/members";
import {auth} from "../src/infra/firebase";

/** Minimal RFC 4180 reader: quoted fields may hold commas and quotes. */
function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (quoted) {
      if (char === '"' && text[i + 1] === '"') {
        field += '"';
        i++;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      row.push(field);
      field = "";
    } else if (char === "\n" || char === "\r") {
      if (char === "\r" && text[i + 1] === "\n") i++;
      row.push(field);
      if (row.some((value) => value.trim())) rows.push(row);
      row = [];
      field = "";
    } else {
      field += char;
    }
  }
  row.push(field);
  if (row.some((value) => value.trim())) rows.push(row);
  return rows;
}

run(async () => {
  const schoolId = requireArg("school").toLowerCase();
  const [header, ...lines] = parseCsv(readFileSync(requireArg("file"), "utf8").replace(/^﻿/, ""));
  const columns = header.map((name) => name.trim().toLowerCase());
  const col = (name: string) => columns.indexOf(name);
  if (col("email") < 0) throw new Error("Header CSV wajib punya kolom email (email,nama,kelas,ekskul).");

  const labels = await loadSchoolLabels(schoolId);
  const rows = lines.map((line) =>
    cleanMember(
      {
        email: line[col("email")] ?? "",
        role: "siswa",
        name: col("nama") >= 0 ? line[col("nama")] : null,
        classId: col("kelas") >= 0 ? line[col("kelas")] : null,
        extracurriculars:
          col("ekskul") >= 0 ? (line[col("ekskul")] ?? "").split(";").filter((x) => x.trim()) : [],
      },
      labels,
    ),
  );

  const newClasses = [...new Set(rows.flatMap((row) => (row.ok && row.newClass ? [row.newClass] : [])))];
  await addSchoolClasses(schoolId, newClasses);

  let added = 0;
  let present = 0;
  let failed = 0;
  for (const [index, row] of rows.entries()) {
    const line = index + 2;
    if (!row.ok) {
      failed++;
      console.log(`  baris ${line}: GAGAL ${row.email} — ${row.reason}`);
      continue;
    }
    const result = await addMember(schoolId, row, "siswa", "developer");
    if (!result.ok) {
      failed++;
      console.log(`  baris ${line}: GAGAL ${row.email} — ${result.reason}`);
      continue;
    }
    if (result.created) added++;
    else present++;
    // An account that already exists joins right away.
    const existing = await auth.getUserByEmail(row.email).catch(() => null);
    if (existing?.emailVerified) await claimMembership(existing.uid, row.email, null);
    console.log(
      `  baris ${line}: ${result.created ? "OK" : "sudah ada"} ${row.email} ` +
        `${row.name || "(tanpa nama)"} ${row.classId ?? "(tanpa kelas)"} ${row.extracurriculars.join(";")}`,
    );
  }

  console.log(`Impor ke ${schoolId} di ${target()}: ${added} baru, ${present} sudah ada, ${failed} gagal.`);
  if (newClasses.length) console.log(`Kelas baru: ${newClasses.join(", ")}`);
  if (failed) throw new Error(`${failed} baris gagal; perbaiki lalu jalankan lagi.`);
});
