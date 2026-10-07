// Calendar dates are `yyyy-MM-dd` strings in WIB everywhere (docs/02). All
// arithmetic here is on calendar days; nothing converts between time zones
// except `wibToday`, the single place "now" becomes a date.

const DAY_MS = 86_400_000;
const WIB_OFFSET_MS = 7 * 3_600_000;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** Today's date in WIB (UTC+7, no daylight saving). */
export function wibToday(now: Date = new Date()): string {
  return new Date(now.getTime() + WIB_OFFSET_MS).toISOString().slice(0, 10);
}

function toDayNumber(date: string): number {
  return Math.round(Date.parse(`${date}T00:00:00Z`) / DAY_MS);
}

function fromDayNumber(day: number): string {
  return new Date(day * DAY_MS).toISOString().slice(0, 10);
}

export function isDateId(value: unknown): value is string {
  return (
    typeof value === "string" &&
    DATE_RE.test(value) &&
    !Number.isNaN(Date.parse(`${value}T00:00:00Z`)) &&
    fromDayNumber(toDayNumber(value)) === value
  );
}

export function addDays(date: string, days: number): string {
  return fromDayNumber(toDayNumber(date) + days);
}

/** Whole days from `from` to `to`; positive when `to` is later. */
export function daysBetween(from: string, to: string): number {
  return toDayNumber(to) - toDayNumber(from);
}

/** 0 = Sunday … 6 = Saturday. */
export function weekdayOf(date: string): number {
  return new Date(`${date}T00:00:00Z`).getUTCDay();
}

/** `yyyy-MM` of the date. */
export function monthOf(date: string): string {
  return date.slice(0, 7);
}

export function endOfMonth(date: string): string {
  const [year, month] = date.split("-").map(Number);
  return new Date(Date.UTC(year, month, 0)).toISOString().slice(0, 10);
}
