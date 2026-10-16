// Exports everything stored for a school as one JSON file, for a school's
// data request or as a copy before deletion (docs/04 §6).
//
//   npx tsx tools/export-school.ts --code sman1 [--out path.json] [--emulator]
//
// The file holds personal data of minors. It is written under secret/, which
// is not in git; hand it over through a channel the school approves.

import {arg, requireArg, run, secretDir, target} from "./_env";

import {mkdirSync, writeFileSync} from "node:fs";
import {dirname, join} from "node:path";

import {DocumentData, Timestamp} from "firebase-admin/firestore";

import {wibToday} from "../src/domain/dates";
import {membersCol, programsCol, schoolRef, statsCol, usersCol} from "../src/infra/firebase";

/** Timestamps become ISO strings so the file is plain JSON. */
function plain(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(plain);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, plain(item)]));
  }
  return value;
}

const withId = (doc: {id: string; data(): DocumentData}) => ({
  id: doc.id,
  ...(plain(doc.data()) as object),
});

run(async () => {
  const code = requireArg("code").toLowerCase();
  const school = await schoolRef(code).get();
  if (!school.exists) throw new Error(`Sekolah "${code}" tidak ditemukan.`);

  const [users, members, stats, programs] = await Promise.all([
    usersCol(code).get(),
    membersCol().where("schoolId", "==", code).get(),
    statsCol(code).get(),
    programsCol(code).get(),
  ]);

  let journalCount = 0;
  const programData = [];
  for (const program of programs.docs) {
    const journals = await program.ref.collection("journals").get();
    const journalData = [];
    for (const journal of journals.docs) {
      const comments = await journal.ref.collection("comments").get();
      journalData.push({...withId(journal), comments: comments.docs.map(withId)});
    }
    journalCount += journals.size;
    programData.push({...withId(program), journals: journalData});
  }

  const output = {
    exportedAt: new Date().toISOString(),
    school: withId(school as never),
    // Device tokens are credentials for push delivery, not school data.
    users: users.docs.map(withId),
    members: members.docs.map(withId),
    studentStats: stats.docs.map(withId),
    programs: programData,
  };

  const file = arg("out") ?? join(secretDir, "exports", `${code}-${wibToday()}.json`);
  mkdirSync(dirname(file), {recursive: true});
  writeFileSync(file, JSON.stringify(output, null, 2));

  console.log(`Ekspor sekolah "${code}" dari ${target()}:`);
  console.log(`  ${users.size} pengguna, ${members.size} anggota daftar, ${programs.size} buku, ${journalCount} jurnal`);
  console.log(`  Berkas: ${file}`);
});
