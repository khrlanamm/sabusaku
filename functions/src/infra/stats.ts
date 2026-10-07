import {FieldValue} from "firebase-admin/firestore";

import {computeStatus, computeStreak, isOverdue, percentOf} from "../domain/activity";
import {monthOf, wibToday} from "../domain/dates";
import {DEFAULT_SETTINGS, SchoolSettings, StudentStatus} from "../domain/types";
import {classesCol, db, programsCol, schoolRef, statsCol, usersCol} from "./firebase";

export interface StudentProfile {
  uid: string;
  name: string;
  nis: string | null;
  classId: string | null;
  className: string | null;
}

export interface ActiveProgramSummary {
  programId: string;
  title: string;
  author: string;
  totalPages: number;
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
  nis: string | null;
  classId: string | null;
  className: string | null;
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
    nis: profile.nis,
    classId: profile.classId,
    className: profile.className,
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
}

/**
 * Rebuilds a student's whole summary from the profile, programs and journal
 * dates, and overwrites the document so no field can go stale (docs/04 §5).
 * A student who is gone or deactivated has no summary, which removes them
 * from teacher dashboards.
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
    return;
  }

  const classId = (user.get("classId") as string | null) ?? null;
  const [settings, classDoc, programsSnapshot] = await Promise.all([
    options.settings ?? loadSettings(schoolId),
    classId ? classesCol(schoolId).doc(classId).get() : null,
    programsCol(schoolId).where("studentId", "==", studentId).get(),
  ]);
  const programs = programsSnapshot.docs;
  const active = programs.find((program) => program.get("status") === "active") ?? null;

  // Journal dates are only needed from programs that can still matter: the
  // active one, the two most recent, and any with journals this month.
  const monthStart = `${monthOf(today)}-01`;
  const byRecency = programs
    .filter((program) => program.get("lastJournalDate"))
    .sort((a, b) =>
      (b.get("lastJournalDate") as string).localeCompare(a.get("lastJournalDate") as string),
    );
  const relevant = byRecency.filter(
    (program, index) =>
      index < 2 || program.id === active?.id || program.get("lastJournalDate") >= monthStart,
  );
  const datesByProgram = new Map<string, string[]>();
  await Promise.all(
    relevant.map(async (program) => {
      // Journal IDs are their dates, so an empty projection is enough.
      const journals = await program.ref.collection("journals").select().get();
      datesByProgram.set(program.id, journals.docs.map((doc) => doc.id));
    }),
  );
  const allDates = [...datesByProgram.values()].flat();
  const recentDates = [...new Set(allDates)].sort().reverse().slice(0, 5);

  let activeProgram: ActiveProgramSummary | null = null;
  let streakCurrent = 0;
  if (active) {
    // A streak can die without any write, so it is recomputed against today.
    streakCurrent = computeStreak(datesByProgram.get(active.id) ?? [], today, settings).current;
    if (active.get("streakCurrent") !== streakCurrent) {
      // The program may have been erased since it was read.
      await active.ref.update({streakCurrent}).catch(ignoreNotFound);
    }
    const totalPages = active.get("book.totalPages") as number;
    const currentPage = (active.get("currentPage") as number | undefined) ?? 0;
    const targetDate = active.get("targetDate") as string;
    activeProgram = {
      programId: active.id,
      title: active.get("book.title") as string,
      author: active.get("book.author") as string,
      totalPages,
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

  const summary = withTimestamp({
    studentId,
    name: user.get("name") as string,
    nis: (user.get("nis") as string | null) ?? null,
    classId,
    className: classDoc?.exists ? (classDoc.get("name") as string) : null,
    status,
    daysSinceLastJournal,
    activeProgram,
    streakCurrent,
    streakBest: programs.reduce(
      (best, program) => Math.max(best, (program.get("streakBest") as number) ?? 0),
      0,
    ),
    lastJournalDate: recentDates[0] ?? null,
    journalCountMonth: allDates.filter((date) => monthOf(date) === monthOf(today)).length,
    journalCountTotal: sum("journalCount"),
    booksCompleted: programs.filter((program) => program.get("status") === "completed").length,
    recentDates,
  });

  // The student can be erased or deactivated while this refresh is running
  // (the reads above take a moment). Re-checking the profile in the same
  // transaction as the write means a summary can never outlive its student.
  await db.runTransaction(async (transaction) => {
    if (isActiveStudent(await transaction.get(userRef))) {
      transaction.set(statsRef, summary);
    } else {
      transaction.delete(statsRef);
    }
  });
}

const REFRESH_CONCURRENCY = 10;

/** Refreshes every active student of a school. Returns how many. */
export async function refreshSchool(schoolId: string, today = wibToday()): Promise<number> {
  const [settings, students] = await Promise.all([
    loadSettings(schoolId),
    usersCol(schoolId).where("role", "==", "siswa").where("status", "==", "active").select().get(),
  ]);
  const ids = students.docs.map((doc) => doc.id);
  let next = 0;
  const worker = async () => {
    while (next < ids.length) {
      await refreshStudentStats(schoolId, ids[next++], {settings, today});
    }
  };
  await Promise.all(Array.from({length: REFRESH_CONCURRENCY}, worker));
  return ids.length;
}
