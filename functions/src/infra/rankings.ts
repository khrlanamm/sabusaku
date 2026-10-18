import {FieldPath, FieldValue, Timestamp} from "firebase-admin/firestore";

import {wibToday} from "../domain/dates";
import {Period, periodById, RankInput, RankMetrics} from "../domain/ranking";
import {db, leaderboardsCol} from "./firebase";

/**
 * One row of `leaderboards/{periodId}.entries`: all the whole school sees of a
 * student (docs/02 §3.17). No email, photo or status.
 */
export interface RankEntry extends RankMetrics {
  name: string;
  classId: string | null;
  extracurriculars: string[];
}

/** Entries by period ID, then by student ID. */
export type Boards = Map<string, Map<string, RankEntry>>;

export interface ProgramDates {
  data: FirebaseFirestore.DocumentData;
  /** The program's journal dates. */
  dates: readonly string[];
}

/** What a student is ranked by, from their programs. */
export function rankInputOf(programs: readonly ProgramDates[]): RankInput {
  return {
    journalDates: [...new Set(programs.flatMap((program) => program.dates))].sort(),
    completedDates: programs
      .filter((program) => program.data.status === "completed")
      .map(({data}) => {
        const completedAt = data.completedAt as Timestamp | null | undefined;
        return completedAt
          ? wibToday(completedAt.toDate())
          : ((data.lastJournalDate as string | null | undefined) ?? (data.startDate as string));
      }),
  };
}

function header(period: Period) {
  return {
    kind: period.kind,
    key: period.key,
    from: period.from,
    to: period.to,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/**
 * Puts one student's rows into the given boards, or takes them out where the
 * entry is null. Merged, so other students' rows are left alone.
 */
export async function writeStudentEntries(
  schoolId: string,
  studentId: string,
  entries: ReadonlyMap<string, RankEntry | null>,
): Promise<void> {
  const batch = db.batch();
  for (const [id, entry] of entries) {
    const period = periodById(id);
    if (!period) continue;
    batch.set(
      leaderboardsCol(schoolId).doc(id),
      {...header(period), entries: {[studentId]: entry ?? FieldValue.delete()}},
      {merge: true},
    );
  }
  await batch.commit();
}

/** Takes a student out of every board of the school, past periods included. */
export async function removeFromBoards(schoolId: string, studentId: string): Promise<void> {
  const boards = await leaderboardsCol(schoolId).select().get();
  if (boards.empty) return;
  const batch = db.batch();
  for (const board of boards.docs) {
    batch.update(board.ref, new FieldPath("entries", studentId), FieldValue.delete());
  }
  await batch.commit();
}

/**
 * Overwrites whole boards, one write each: for the nightly refresh (ten
 * students refreshed at a time would otherwise contend for the same
 * documents) and for rebuilds. Rows of students no longer listed disappear.
 */
export async function writeBoards(
  schoolId: string,
  periods: readonly Period[],
  boards: Boards,
): Promise<void> {
  await Promise.all(
    periods.map((period) =>
      leaderboardsCol(schoolId)
        .doc(period.id)
        .set({...header(period), entries: Object.fromEntries(boards.get(period.id) ?? [])}),
    ),
  );
}
