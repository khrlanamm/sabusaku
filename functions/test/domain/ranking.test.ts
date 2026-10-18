// October 2026: the 4th, 11th, 18th and 25th are Sundays (neutral by default).

import {describe, expect, it} from "vitest";

import {
  ALL_TIME,
  isEmpty,
  livePeriods,
  metricsFor,
  monthPeriod,
  periodById,
  periodsOf,
  periodsWithData,
  rankOf,
  RankMetrics,
  schoolYearOf,
  schoolYearPeriod,
  yearPeriod,
} from "../../src/domain/ranking";
import {DEFAULT_SETTINGS} from "../../src/domain/types";

const settings = DEFAULT_SETTINGS;

function october(from: number, to: number, skip: number[] = []): string[] {
  const dates: string[] = [];
  for (let day = from; day <= to; day++) {
    if (!skip.includes(day)) dates.push(`2026-10-${String(day).padStart(2, "0")}`);
  }
  return dates;
}

describe("periode", () => {
  it("tahun ajaran mulai 1 Juli", () => {
    expect(schoolYearOf("2026-06-30")).toBe(2025);
    expect(schoolYearOf("2026-07-01")).toBe(2026);
    expect(schoolYearOf("2027-01-15")).toBe(2026);
    expect(schoolYearPeriod(2026)).toEqual({
      kind: "schoolYear",
      key: "2026",
      id: "schoolYear-2026",
      from: "2026-07-01",
      to: "2027-06-30",
    });
  });

  it("batas bulan dan tahun", () => {
    expect(monthPeriod("2026-02")).toMatchObject({id: "month-2026-02", from: "2026-02-01", to: "2026-02-28"});
    expect(monthPeriod("2028-02").to).toBe("2028-02-29");
    expect(monthPeriod("2026-12")).toMatchObject({from: "2026-12-01", to: "2026-12-31"});
    expect(yearPeriod(2026)).toMatchObject({id: "year-2026", from: "2026-01-01", to: "2026-12-31"});
  });

  it("satu hari masuk empat periode", () => {
    expect(periodsOf("2026-10-18").map((period) => period.id)).toEqual([
      "month-2026-10",
      "year-2026",
      "schoolYear-2026",
      "all",
    ]);
  });

  it("ID dokumen bolak-balik", () => {
    for (const period of [...periodsOf("2027-03-02"), ALL_TIME]) {
      expect(periodById(period.id)).toEqual(period);
    }
    expect(periodById("month-2026-13")).toBeNull();
    expect(periodById("week-2026")).toBeNull();
  });

  it("periode hidup ikut dua hari ke belakang", () => {
    expect(livePeriods("2026-10-18").map((period) => period.id)).toEqual([
      "month-2026-10",
      "year-2026",
      "schoolYear-2026",
      "all",
    ]);
    // 2 Jan 2027: December 2026 and the year 2026 can still change.
    expect(livePeriods("2027-01-02").map((period) => period.id)).toEqual([
      "month-2027-01",
      "year-2027",
      "schoolYear-2026",
      "all",
      "month-2026-12",
      "year-2026",
    ]);
    // 1 Jul 2027: the school year 2026/2027 can still change.
    expect(livePeriods("2027-07-01").map((period) => period.id)).toContain("schoolYear-2026");
  });
});

describe("metricsFor", () => {
  it("buku dihitung menurut tanggal selesai", () => {
    const input = {journalDates: [], completedDates: ["2026-09-30", "2026-10-02", "2026-10-20"]};
    expect(metricsFor(input, monthPeriod("2026-10"), "2026-10-31", settings).books).toBe(2);
    expect(metricsFor(input, monthPeriod("2026-09"), "2026-10-31", settings).books).toBe(1);
    expect(metricsFor(input, ALL_TIME, "2026-10-31", settings).books).toBe(3);
  });

  it("streak dipotong di awal periode", () => {
    // 25 Sep … 6 Oct without a gap on an effective day.
    const september = ["2026-09-25", "2026-09-26", "2026-09-28", "2026-09-29", "2026-09-30"];
    const input = {journalDates: [...september, ...october(1, 6, [4])], completedDates: []};
    expect(metricsFor(input, monthPeriod("2026-10"), "2026-10-06", settings)).toEqual({
      books: 0,
      streak: 5,
      days: 5,
    });
    expect(metricsFor(input, ALL_TIME, "2026-10-06", settings).streak).toBe(10);
    expect(metricsFor(input, monthPeriod("2026-09"), "2026-10-06", settings).streak).toBe(5);
  });

  it("streak terbaik dalam periode, bukan yang sedang berjalan", () => {
    // 1–3, gap on Mon 5, then 6–7.
    const input = {journalDates: october(1, 7, [4, 5]), completedDates: []};
    expect(metricsFor(input, monthPeriod("2026-10"), "2026-10-07", settings)).toMatchObject({
      streak: 3,
      days: 5,
    });
  });

  it("tanggal ganda dari dua buku dihitung sekali", () => {
    const input = {journalDates: ["2026-10-01", "2026-10-01", "2026-10-02"], completedDates: []};
    expect(metricsFor(input, monthPeriod("2026-10"), "2026-10-02", settings)).toMatchObject({
      streak: 2,
      days: 2,
    });
  });

  it("periode tanpa data kosong", () => {
    const input = {journalDates: october(1, 3), completedDates: []};
    const metrics = metricsFor(input, monthPeriod("2026-11"), "2026-11-02", settings);
    expect(isEmpty(metrics)).toBe(true);
  });
});

describe("periodsWithData", () => {
  it("semua periode yang pernah punya jurnal atau buku selesai", () => {
    const ids = periodsWithData({journalDates: ["2026-06-30"], completedDates: ["2026-07-01"]})
      .map((period) => period.id)
      .sort();
    expect(ids).toEqual([
      "all",
      "month-2026-06",
      "month-2026-07",
      "schoolYear-2025",
      "schoolYear-2026",
      "year-2026",
    ]);
  });
});

describe("rankOf", () => {
  const entry = (books: number, streak: number, days: number): RankMetrics => ({books, streak, days});

  it("peringkat kompetisi dengan pemecah seri", () => {
    const entries = new Map([
      ["a", entry(1, 5, 10)],
      ["b", entry(2, 3, 8)],
      ["c", entry(1, 5, 10)],
      ["d", entry(1, 7, 12)],
    ]);
    expect(Object.fromEntries(rankOf(entries, "books"))).toEqual({b: 1, d: 2, a: 3, c: 3});
    expect(Object.fromEntries(rankOf(entries, "streak"))).toEqual({d: 1, a: 2, c: 2, b: 4});
    expect(Object.fromEntries(rankOf(entries, "days"))).toEqual({d: 1, a: 2, c: 2, b: 4});
  });
});
