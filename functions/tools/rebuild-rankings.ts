// Rebuilds every leaderboard of a school from its history: fills each
// program's `journalDates` from its journals, writes one board per month,
// year and school year that has data plus the all-time board, removes boards
// of periods without data, then refreshes every student's summary (the
// streak runs across books). Triggers and the nightly refresh keep the
// boards current afterwards; run this once after deploying them, or after
// fixing data by hand.
//
//   npx tsx tools/rebuild-rankings.ts [--school sman1sukodadi] [--dry-run] [--emulator]

import {arg, hasFlag, run, target} from "./_env";

import {wibToday} from "../src/domain/dates";
import {isEmpty, livePeriods, metricsFor, Period, periodsWithData} from "../src/domain/ranking";
import {db, leaderboardsCol, programsCol, usersCol} from "../src/infra/firebase";
import {Boards, ProgramDates, rankInputOf, writeBoards} from "../src/infra/rankings";
import {loadSettings, refreshSchool} from "../src/infra/stats";

run(async () => {
  const only = arg("school")?.toLowerCase();
  const dryRun = hasFlag("dry-run");
  const schools = only ? [only] : (await db.collection("schools").select().get()).docs.map((doc) => doc.id);
  const today = wibToday();

  for (const schoolId of schools) {
    const settings = await loadSettings(schoolId);

    const programs = await programsCol(schoolId).get();
    const byStudent = new Map<string, ProgramDates[]>();
    let filled = 0;
    for (const program of programs.docs) {
      const journals = await program.ref.collection("journals").select().get();
      const dates = journals.docs.map((doc) => doc.id).sort();
      if (JSON.stringify(program.get("journalDates") ?? null) !== JSON.stringify(dates)) {
        filled++;
        if (!dryRun) await program.ref.update({journalDates: dates});
      }
      const studentId = program.get("studentId") as string;
      if (!byStudent.has(studentId)) byStudent.set(studentId, []);
      byStudent.get(studentId)!.push({data: program.data(), dates});
    }

    const students = await usersCol(schoolId)
      .where("role", "==", "siswa")
      .where("status", "==", "active")
      .get();
    const boards: Boards = new Map();
    const periods = new Map<string, Period>(livePeriods(today).map((period) => [period.id, period]));
    for (const user of students.docs) {
      const input = rankInputOf(byStudent.get(user.id) ?? []);
      const profile = {
        name: (user.get("name") as string | undefined) ?? "",
        classId: (user.get("classId") as string | null | undefined) ?? null,
        extracurriculars: (user.get("extracurriculars") as string[] | undefined) ?? [],
      };
      for (const period of periodsWithData(input)) {
        const metrics = metricsFor(input, period, today, settings);
        if (isEmpty(metrics)) continue;
        periods.set(period.id, period);
        if (!boards.has(period.id)) boards.set(period.id, new Map());
        boards.get(period.id)!.set(user.id, {...profile, ...metrics});
      }
    }

    const stale = (await leaderboardsCol(schoolId).select().get()).docs.filter(
      (doc) => !periods.has(doc.id),
    );

    console.log(
      `${schoolId} di ${target()}${dryRun ? " (dry run)" : ""}: ` +
        `${programs.size} program (${filled} journalDates diisi), ${students.size} siswa aktif`,
    );
    for (const id of [...periods.keys()].sort()) {
      console.log(`  ${id}: ${boards.get(id)?.size ?? 0} siswa`);
    }
    for (const doc of stale) console.log(`  ${doc.id}: dihapus`);
    if (dryRun) continue;

    await writeBoards(schoolId, [...periods.values()], boards);
    await Promise.all(stale.map((doc) => doc.ref.delete()));
    const refreshed = await refreshSchool(schoolId, today);
    console.log(`  ringkasan ${refreshed} siswa dihitung ulang`);
  }
});
