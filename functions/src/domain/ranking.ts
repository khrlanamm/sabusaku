// Leaderboard periods and the numbers a student is ranked by (docs/04 §6).
// Pure functions over `yyyy-MM-dd` strings, mirrored by lib/core/time/periods.dart.

import {computeStreak} from "./activity";
import {addDays, monthOf} from "./dates";
import {SchoolSettings} from "./types";

export type PeriodKind = "month" | "year" | "schoolYear" | "all";

export interface Period {
  kind: PeriodKind;
  /** `yyyy-MM` for a month, `yyyy` for a year and for a school year (its first year). */
  key: string | null;
  /** Document ID under `leaderboards`: `month-2026-10`, `year-2026`, `schoolYear-2026`, `all`. */
  id: string;
  /** First and last day, inclusive; null for `all`. */
  from: string | null;
  to: string | null;
}

/** A school year runs from 1 July to 30 June; it is named by its first year. */
export const SCHOOL_YEAR_START_MONTH = 7;

export function schoolYearOf(date: string): number {
  const year = Number(date.slice(0, 4));
  return Number(date.slice(5, 7)) >= SCHOOL_YEAR_START_MONTH ? year : year - 1;
}

export function monthPeriod(month: string): Period {
  const [year, number] = month.split("-").map(Number);
  const last = new Date(Date.UTC(year, number, 0)).getUTCDate();
  return {kind: "month", key: month, id: `month-${month}`, from: `${month}-01`, to: `${month}-${last}`};
}

export function yearPeriod(year: number): Period {
  return {kind: "year", key: `${year}`, id: `year-${year}`, from: `${year}-01-01`, to: `${year}-12-31`};
}

export function schoolYearPeriod(startYear: number): Period {
  return {
    kind: "schoolYear",
    key: `${startYear}`,
    id: `schoolYear-${startYear}`,
    from: `${startYear}-07-01`,
    to: `${startYear + 1}-06-30`,
  };
}

export const ALL_TIME: Period = {kind: "all", key: null, id: "all", from: null, to: null};

/** The four periods a day belongs to. */
export function periodsOf(date: string): Period[] {
  return [
    monthPeriod(monthOf(date)),
    yearPeriod(Number(date.slice(0, 4))),
    schoolYearPeriod(schoolYearOf(date)),
    ALL_TIME,
  ];
}

/** The period of a document ID, or null when the ID is not one. */
export function periodById(id: string): Period | null {
  if (id === "all") return ALL_TIME;
  const month = /^month-(\d{4}-(0[1-9]|1[0-2]))$/.exec(id);
  if (month) return monthPeriod(month[1]);
  const year = /^(year|schoolYear)-(\d{4})$/.exec(id);
  if (!year) return null;
  return year[1] === "year" ? yearPeriod(Number(year[2])) : schoolYearPeriod(Number(year[2]));
}

/**
 * Periods a write today can still change: today's, and those of two days ago
 * because a journal may be written up to two days late (BR-3).
 */
export function livePeriods(today: string): Period[] {
  const byId = new Map<string, Period>();
  for (const period of [...periodsOf(today), ...periodsOf(addDays(today, -2))]) {
    byId.set(period.id, period);
  }
  return [...byId.values()];
}

export interface RankInput {
  /** Every journal date of the student, over all their books. */
  journalDates: readonly string[];
  /** The day (WIB) each finished book was marked finished. */
  completedDates: readonly string[];
}

export interface RankMetrics {
  /** Books finished in the period. */
  books: number;
  /** Longest streak inside the period; a run that started earlier counts from the first day. */
  streak: number;
  /** Days with a journal in the period. */
  days: number;
}

function within(date: string, period: Period): boolean {
  return (period.from === null || date >= period.from) && (period.to === null || date <= period.to);
}

export function metricsFor(
  input: RankInput,
  period: Period,
  today: string,
  settings: SchoolSettings,
): RankMetrics {
  const dates = [...new Set(input.journalDates)].filter((date) => within(date, period));
  return {
    books: input.completedDates.filter((date) => within(date, period)).length,
    // Cut to the period, the longest run of the remaining dates is the
    // longest run inside the period.
    streak: computeStreak(dates, today, settings).best,
    days: dates.filter((date) => date <= today).length,
  };
}

export function isEmpty(metrics: RankMetrics): boolean {
  return metrics.books === 0 && metrics.streak === 0 && metrics.days === 0;
}

/** Every period in which the student has a journal or finished a book. */
export function periodsWithData(input: RankInput): Period[] {
  const byId = new Map<string, Period>();
  for (const date of [...input.journalDates, ...input.completedDates]) {
    for (const period of periodsOf(date)) byId.set(period.id, period);
  }
  return [...byId.values()];
}

export type RankMetric = keyof RankMetrics;

/** Sort keys per metric: the metric itself, then the tie-breakers. */
export const RANK_ORDER: Record<RankMetric, readonly RankMetric[]> = {
  books: ["books", "days", "streak"],
  streak: ["streak", "days", "books"],
  days: ["days", "streak", "books"],
};

/**
 * Standard competition ranking (1, 2, 2, 4) over the metric's sort keys.
 * Returns the rank of every ID.
 */
export function rankOf<T extends RankMetrics>(
  entries: ReadonlyMap<string, T>,
  metric: RankMetric = "books",
): Map<string, number> {
  const keys = RANK_ORDER[metric];
  const compare = (a: T, b: T) => {
    for (const key of keys) {
      if (a[key] !== b[key]) return b[key] - a[key];
    }
    return 0;
  };
  const sorted = [...entries.entries()].sort(([, a], [, b]) => compare(a, b));
  const ranks = new Map<string, number>();
  sorted.forEach(([id, entry], index) => {
    const previous = index > 0 ? sorted[index - 1] : null;
    ranks.set(
      id,
      previous && compare(previous[1], entry) === 0 ? ranks.get(previous[0])! : index + 1,
    );
  });
  return ranks;
}
