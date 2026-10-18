import {FieldValue, Timestamp} from "firebase-admin/firestore";

import {computeStatus, computeStreak, isOverdue, percentOf} from "../domain/activity";
import {monthOf, wibToday} from "../domain/dates";
import {isEmpty, livePeriods, metricsFor} from "../domain/ranking";
import {DEFAULT_SETTINGS, SchoolSettings, StudentStatus} from "../domain/types";
import {db, programsCol, schoolRef, statsCol, usersCol} from "./firebase";
import {
  Boards,
  rankInputOf,
  RankEntry,
  removeFromBoards,
  writeBoards,
  writeStudentEntries,
} from "./rankings";

export interface StudentProfile {
  uid: string;
  name: string;
  email: string;
  photoUrl: string | null;
  /** Class label, e.g. `XII-A1`. */
  classId: string | null;
  extracurriculars: string[];
}

export interface ActiveProgramSummary {
  programId: string;
  title: string;
  author: string;
  totalPages: number;
  /** The book's cover (catalog copy or the student's own photo), if any. */
  coverUrl: string | null;
  currentPage: number;
  percent: number;
  startDate: string;
  targetDate: string;
  extended: boolean;
  overdue: boolean;
}

export interface StudentStatsData {
  studentId: string;
  name: string;
  email: string;
  photoUrl: string | null;
  classId: string | null;
  extracurriculars: string[];
  status: StudentStatus;
  daysSinceLastJournal: number;
  activeProgram: ActiveProgramSummary | null;
  streakCurrent: number;
  streakBest: number;
  lastJournalDate: string | null;
  journalCountMonth: number;
  journalCountTotal: number;
  booksCompleted: number;
  recentDates: string[];
}

/** Summary of a student who has not started any book yet. */
export function emptyStats(profile: StudentProfile): StudentStatsData {
  return {
    studentId: profile.uid,
    name: profile.name,
    email: profile.email,
    photoUrl: profile.photoUrl,
    classId: profile.classId,
    extracurriculars: profile.extracurriculars,
    status: "belum_mulai",
    daysSinceLastJournal: 0,
    activeProgram: null,
    streakCurrent: 0,
    streakBest: 0,
    lastJournalDate: null,
    journalCountMonth: 0,
    journalCountTotal: 0,
    booksCompleted: 0,
    recentDates: [],
  };
}

export function withTimestamp(stats: StudentStatsData) {
  return {...stats, updatedAt: FieldValue.serverTimestamp()};
}

function isActiveStudent(user: FirebaseFirestore.DocumentSnapshot): boolean {
  return user.exists && user.get("role") === "siswa" && user.get("status") === "active";
}

/** gRPC NOT_FOUND: the document was deleted between the read and the write. */
function ignoreNotFound(error: unknown): void {
  if ((error as {code?: number}).code !== 5) throw error;
}

export async function loadSettings(schoolId: string): Promise<SchoolSettings> {
  const school = await schoolRef(schoolId).get();
  return {...DEFAULT_SETTINGS, ...(school.get("settings") as Partial<SchoolSettings> | undefined)};
}

interface RefreshOptions {
  /** Pass when refreshing many students of one school to avoid re-reading it. */
  settings?: SchoolSettings;
  today?: string;
  /**
   * Collects the student's leaderboard rows here instead of writing them, so
   * a refresh of the whole school writes each board once.
   */
  boards?: Boards;
}

/** A program's journal dates: the server-written list, or the journals themselves. */
async function journalDatesOf(program: FirebaseFirestore.QueryDocumentSnapshot): Promise<string[]> {
  const dates = program.get("journalDates") as string[] | undefined;
  if (dates) return dates;
  // Written before `journalDates` existed and not rebuilt yet. Journal IDs
  // are their dates, so an empty projection is enough.
  const journals = await program.ref.collection("journals").select().get();
  return journals.docs.map((doc) => doc.id);
}

/**
 * Rebuilds a student's whole summary from the profile, programs and journal
 * dates, and overwrites the document so no field can go stale (docs/04 §5).
 * Also updates the student's rows on the boards a write today can change.
 * A student who is gone or removed from the school has no summary and no
 * rows, which removes them from teacher dashboards and every leaderboard.
 */
export async function refreshStudentStats(
  schoolId: string,
  studentId: string,
  options: RefreshOptions = {},
): Promise<void> {
  const today = options.today ?? wibToday();
  const statsRef = statsCol(schoolId).doc(studentId);

  const userRef = usersCol(schoolId).doc(studentId);
  const user = await userRef.get();
  if (!isActiveStudent(user)) {
    await statsRef.delete();
    await removeFromBoards(schoolId, studentId);
    return;
  }

  const [settings, programsSnapshot] = await Promise.all([
    options.settings ?? loadSettings(schoolId),
    programsCol(schoolId).where("studentId", "==", studentId).get(),
  ]);
  const programs = programsSnapshot.docs;
  const active = programs.find((program) => program.get("status") === "active") ?? null;

  const withDates = await Promise.all(
    programs.map(async (program) => ({program, dates: await journalDatesOf(program)})),
  );
  const rankInput = rankInputOf(withDates.map(({program, dates}) => ({data: program.data(), dates})));
  // The streak runs on across books: every journal of the student counts.
  const allDates = rankInput.journalDates;
  const recentDates = [...allDates].reverse().slice(0, 5);
  const streak = computeStreak(allDates, today, settings);

  let activeProgram: ActiveProgramSummary | null = null;
  if (active) {
    // The book's own streak can die without any write, so it is recomputed
    // against today.
    const activeDates = withDates.find(({program}) => program.id === active.id)?.dates ?? [];
    const bookStreak = computeStreak(activeDates, today, settings).current;
    if (active.get("streakCurrent") !== bookStreak) {
      // The program may have been erased since it was read.
      await active.ref.update({streakCurrent: bookStreak}).catch(ignoreNotFound);
    }
    const totalPages = active.get("book.totalPages") as number;
    const currentPage = (active.get("currentPage") as number | undefined) ?? 0;
    const targetDate = active.get("targetDate") as string;
    activeProgram = {
      programId: active.id,
      title: active.get("book.title") as string,
      author: active.get("book.author") as string,
      totalPages,
      coverUrl: (active.get("book.coverUrl") as string | null | undefined) ?? null,
      currentPage,
      percent: percentOf(currentPage, totalPages),
      startDate: active.get("startDate") as string,
      targetDate,
      extended: active.get("extended") === true,
      overdue: isOverdue(targetDate, today),
    };
  }

  const {status, daysSinceLastJournal} = computeStatus(
    active
      ? {
          startDate: active.get("startDate") as string,
          lastJournalDate: (active.get("lastJournalDate") as string | null) ?? null,
        }
      : null,
    today,
    settings,
  );

  const sum = (field: string) =>
    programs.reduce((total, program) => total + ((program.get(field) as number) ?? 0), 0);

  const profile = {
    name: (user.get("name") as string | undefined) ?? "",
    classId: (user.get("classId") as string | null | undefined) ?? null,
    extracurriculars: (user.get("extracurriculars") as string[] | undefined) ?? [],
  };

  const summary = withTimestamp({
    studentId,
    ...profile,
    email: (user.get("email") as string | undefined) ?? "",
    photoUrl: (user.get("photoUrl") as string | null | undefined) ?? null,
    status,
    daysSinceLastJournal,
    activeProgram,
    streakCurrent: streak.current,
    streakBest: streak.best,
    lastJournalDate: recentDates[0] ?? null,
    journalCountMonth: allDates.filter((date) => monthOf(date) === monthOf(today)).length,
    journalCountTotal: sum("journalCount"),
    booksCompleted: programs.filter((program) => program.get("status") === "completed").length,
    recentDates,
  });

  // The student can be erased or deactivated while this refresh is running
  // (the reads above take a moment). Re-checking the profile in the same
  // transaction as the write means a summary can never outlive its student.
  // `statusChangedAt` survives the overwrite while the status stays; the
  // morning digest to teachers picks the students whose status just changed.
  const stillActive = await db.runTransaction(async (transaction) => {
    const current = await transaction.get(userRef);
    const previous = await transaction.get(statsRef);
    if (!isActiveStudent(current)) {
      transaction.delete(statsRef);
      return false;
    }
    const unchanged = previous.exists && previous.get("status") === status;
    transaction.set(statsRef, {
      ...summary,
      statusChangedAt: unchanged
        ? ((previous.get("statusChangedAt") as Timestamp | undefined) ?? null)
        : FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!stillActive) {
    await removeFromBoards(schoolId, studentId);
    return;
  }

  const entries = new Map<string, RankEntry | null>();
  for (const period of livePeriods(today)) {
    const metrics = metricsFor(rankInput, period, today, settings);
    entries.set(period.id, isEmpty(metrics) ? null : {...profile, ...metrics});
  }
  if (options.boards) {
    for (const [id, entry] of entries) {
      if (!entry) continue;
      if (!options.boards.has(id)) options.boards.set(id, new Map());
      options.boards.get(id)!.set(studentId, entry);
    }
  } else {
    await writeStudentEntries(schoolId, studentId, entries);
  }
}

const REFRESH_CONCURRENCY = 10;

/**
 * Refreshes every active student of a school, then rewrites the boards a
 * write today can change. Returns how many students.
 */
export async function refreshSchool(schoolId: string, today = wibToday()): Promise<number> {
  const [settings, students] = await Promise.all([
    loadSettings(schoolId),
    usersCol(schoolId).where("role", "==", "siswa").where("status", "==", "active").select().get(),
  ]);
  const ids = students.docs.map((doc) => doc.id);
  const boards: Boards = new Map();
  let next = 0;
  const worker = async () => {
    while (next < ids.length) {
      await refreshStudentStats(schoolId, ids[next++], {settings, today, boards});
    }
  };
  await Promise.all(Array.from({length: REFRESH_CONCURRENCY}, worker));
  await writeBoards(schoolId, livePeriods(today), boards);
  return ids.length;
}
