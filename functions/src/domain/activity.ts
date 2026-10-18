// Streak and status rules (PRD BR-11, BR-12, BR-13; docs/04 §4).
// Pure functions over date strings so they can be tested without Firebase.

import {addDays, daysBetween, weekdayOf} from "./dates";
import {SchoolSettings, StudentStatus} from "./types";

/**
 * An effective day is any day that is neither a neutral weekday (Sunday by
 * default) nor a school holiday.
 */
export function effectiveDayChecker(settings: SchoolSettings): (date: string) => boolean {
  const neutral = new Set(settings.neutralWeekdays);
  const holidays = new Set(settings.holidays);
  return (date) => !neutral.has(weekdayOf(date)) && !holidays.has(date);
}

/** Number of effective days after `after` up to and including `until`. */
export function effectiveDaysBetween(
  after: string,
  until: string,
  settings: SchoolSettings,
): number {
  const isEffective = effectiveDayChecker(settings);
  let count = 0;
  for (let day = addDays(after, 1); day <= until; day = addDays(day, 1)) {
    if (isEffective(day)) count++;
  }
  return count;
}

export interface Streak {
  /** Consecutive effective days with a journal, still alive today. */
  current: number;
  /** Longest run in the whole history. */
  best: number;
}

/**
 * Walks the calendar from the first to the last journal date:
 *   - a day with a journal extends the run (also on a neutral day),
 *   - a neutral day without a journal is skipped,
 *   - an effective day without a journal ends the run.
 *
 * The run ending at the last journal is the current streak, unless an
 * effective day before today has since passed without a journal. Today itself
 * never breaks a streak: the student may still write.
 */
export function computeStreak(
  journalDates: readonly string[],
  today: string,
  settings: SchoolSettings,
): Streak {
  const dates = new Set(journalDates.filter((date) => date <= today));
  if (dates.size === 0) return {current: 0, best: 0};

  const sorted = [...dates].sort();
  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const isEffective = effectiveDayChecker(settings);

  let run = 0;
  let best = 0;
  for (let day = first; day <= last; day = addDays(day, 1)) {
    if (dates.has(day)) {
      run++;
      best = Math.max(best, run);
    } else if (isEffective(day)) {
      run = 0;
    }
  }

  const missedSinceLast = effectiveDaysBetween(last, addDays(today, -1), settings);
  return {current: missedSinceLast > 0 ? 0 : run, best};
}

export interface StatusResult {
  status: StudentStatus;
  /** Effective days since the last journal (or since the book started). */
  daysSinceLastJournal: number;
}

/**
 * Status is an indicator, not a grade. `program` is the student's active
 * program, or null when there is none.
 */
export function computeStatus(
  program: {startDate: string; lastJournalDate: string | null} | null,
  today: string,
  settings: SchoolSettings,
): StatusResult {
  if (!program) return {status: "belum_mulai", daysSinceLastJournal: 0};

  // Without a journal the count starts the day the book started.
  const since = program.lastJournalDate ?? addDays(program.startDate, -1);
  const days = effectiveDaysBetween(since, today, settings);
  const status: StudentStatus =
    days <= settings.activeMaxDays
      ? "aktif"
      : days <= settings.attentionMaxDays
        ? "perlu_perhatian"
        : "tidak_aktif";
  return {status, daysSinceLastJournal: days};
}

export interface JournalSummary {
  date: string;
  pageEnd: number;
}

export interface ProgramAggregates {
  /** Highest page ever recorded: re-reading never lowers progress (BR-5). */
  currentPage: number;
  journalCount: number;
  lastJournalDate: string | null;
  streakCurrent: number;
  streakBest: number;
  /**
   * Every journal date, oldest first, so the student's summary and calendar
   * need no read of the journals themselves.
   */
  journalDates: string[];
}

/**
 * Derived fields of a program, recomputed from all of its journals. Being a
 * full recompute it is idempotent and immune to offline journals arriving out
 * of order.
 */
export function computeProgramAggregates(
  journals: readonly JournalSummary[],
  today: string,
  settings: SchoolSettings,
): ProgramAggregates {
  const dates = journals.map((journal) => journal.date);
  const streak = computeStreak(dates, today, settings);
  return {
    currentPage: journals.reduce((max, journal) => Math.max(max, journal.pageEnd), 0),
    journalCount: journals.length,
    lastJournalDate: dates.length ? dates.reduce((a, b) => (a > b ? a : b)) : null,
    streakCurrent: streak.current,
    streakBest: streak.best,
    journalDates: [...dates].sort(),
  };
}

export function percentOf(currentPage: number, totalPages: number): number {
  if (totalPages <= 0) return 0;
  return Math.min(100, Math.floor((currentPage * 100) / totalPages));
}

/** Whether a target date has passed. */
export function isOverdue(targetDate: string, today: string): boolean {
  return daysBetween(targetDate, today) > 0;
}
