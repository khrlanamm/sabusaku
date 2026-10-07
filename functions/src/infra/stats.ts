import {FieldValue} from "firebase-admin/firestore";

import {StudentStatus} from "../domain/types";

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
