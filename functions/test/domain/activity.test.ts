// Table from docs/04 §4. October 2026: the 4th, 11th, 18th and 25th are
// Sundays (neutral by default).

import {describe, expect, it} from "vitest";

import {
  computeProgramAggregates,
  computeStatus,
  computeStreak,
  effectiveDaysBetween,
  isOverdue,
  percentOf,
} from "../../src/domain/activity";
import {DEFAULT_SETTINGS, SchoolSettings} from "../../src/domain/types";

const settings = DEFAULT_SETTINGS;
const withHolidays = (...holidays: string[]): SchoolSettings => ({...settings, holidays});

/** Dates `2026-10-<from>` … `2026-10-<to>`, optionally skipping some days. */
function october(from: number, to: number, skip: number[] = []): string[] {
  const dates: string[] = [];
  for (let day = from; day <= to; day++) {
    if (!skip.includes(day)) dates.push(`2026-10-${String(day).padStart(2, "0")}`);
  }
  return dates;
}

describe("effectiveDaysBetween", () => {
  it("menghitung (after, until] tanpa hari Minggu", () => {
    // Mon 5 → Sat 10: Tue..Sat = 5
    expect(effectiveDaysBetween("2026-10-05", "2026-10-10", settings)).toBe(5);
    // Sat 3 → Mon 5: Sunday skipped, Monday counted
    expect(effectiveDaysBetween("2026-10-03", "2026-10-05", settings)).toBe(1);
    expect(effectiveDaysBetween("2026-10-07", "2026-10-07", settings)).toBe(0);
    expect(effectiveDaysBetween("2026-10-07", "2026-10-01", settings)).toBe(0);
  });
  it("melewati hari libur dan hari netral tambahan", () => {
    expect(effectiveDaysBetween("2026-10-05", "2026-10-10", withHolidays("2026-10-07"))).toBe(4);
    const saturdayNeutral = {...settings, neutralWeekdays: [0, 6]};
    expect(effectiveDaysBetween("2026-10-05", "2026-10-12", saturdayNeutral)).toBe(5);
  });
});

describe("computeStreak", () => {
  it("siswa tanpa jurnal sama sekali", () => {
    expect(computeStreak([], "2026-10-07", settings)).toEqual({current: 0, best: 0});
  });

  it("program baru, jurnal pertama hari ini", () => {
    expect(computeStreak(["2026-10-07"], "2026-10-07", settings)).toEqual({current: 1, best: 1});
  });

  it("streak melewati hari Minggu tanpa jurnal", () => {
    // Fri 2, Sat 3, (Sun 4 skipped), Mon 5, Tue 6
    const dates = ["2026-10-02", "2026-10-03", "2026-10-05", "2026-10-06"];
    expect(computeStreak(dates, "2026-10-06", settings)).toEqual({current: 4, best: 4});
  });

  it("jurnal di hari Minggu tetap menambah hitungan", () => {
    const dates = ["2026-10-03", "2026-10-04", "2026-10-05"];
    expect(computeStreak(dates, "2026-10-05", settings)).toEqual({current: 3, best: 3});
  });

  it("streak melewati hari libur sekolah", () => {
    // Wed 7 is a holiday with no journal
    const dates = ["2026-10-05", "2026-10-06", "2026-10-08"];
    expect(computeStreak(dates, "2026-10-08", withHolidays("2026-10-07"))).toEqual({
      current: 3,
      best: 3,
    });
  });

  it("streak putus karena Rabu kosong", () => {
    // Mon 5, Tue 6, (Wed 7 missing), Thu 8
    const dates = ["2026-10-05", "2026-10-06", "2026-10-08"];
    expect(computeStreak(dates, "2026-10-08", settings)).toEqual({current: 1, best: 2});
  });

  it("jurnal yang diisi mundur menutup celah", () => {
    const withGap = ["2026-10-05", "2026-10-06", "2026-10-08"];
    expect(computeStreak(withGap, "2026-10-08", settings).current).toBe(1);
    expect(computeStreak([...withGap, "2026-10-07"], "2026-10-08", settings)).toEqual({
      current: 4,
      best: 4,
    });
  });

  it("hari ini belum menulis tetapi kemarin menulis: streak tetap hidup", () => {
    const dates = ["2026-10-05", "2026-10-06"];
    expect(computeStreak(dates, "2026-10-07", settings)).toEqual({current: 2, best: 2});
  });

  it("melewatkan satu hari efektif penuh mematikan streak, terbaik tetap", () => {
    const dates = ["2026-10-05", "2026-10-06"];
    expect(computeStreak(dates, "2026-10-08", settings)).toEqual({current: 0, best: 2});
  });

  it("jurnal terakhir Sabtu, dicek Senin: Minggu tidak memutus", () => {
    const dates = ["2026-10-02", "2026-10-03"];
    expect(computeStreak(dates, "2026-10-05", settings).current).toBe(2);
    // Tuesday: Monday passed without a journal
    expect(computeStreak(dates, "2026-10-06", settings).current).toBe(0);
  });

  it("melewati pergantian bulan", () => {
    const dates = ["2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02"];
    expect(computeStreak(dates, "2026-10-02", settings)).toEqual({current: 4, best: 4});
  });

  it("streak terbaik berasal dari riwayat, bukan streak sekarang", () => {
    // Run of 5 (Mon 5–Fri 9), gap on Sat 10, then Mon 12–Tue 13
    const dates = [...october(5, 9), "2026-10-12", "2026-10-13"];
    expect(computeStreak(dates, "2026-10-13", settings)).toEqual({current: 2, best: 5});
  });

  it("urutan masukan dan duplikat tidak berpengaruh", () => {
    const dates = ["2026-10-06", "2026-10-05", "2026-10-06"];
    expect(computeStreak(dates, "2026-10-06", settings)).toEqual({current: 2, best: 2});
  });
});

describe("computeStatus", () => {
  const program = (lastJournalDate: string | null, startDate = "2026-10-01") => ({
    startDate,
    lastJournalDate,
  });

  it("tanpa program aktif: belum_mulai", () => {
    expect(computeStatus(null, "2026-10-07", settings)).toEqual({
      status: "belum_mulai",
      daysSinceLastJournal: 0,
    });
  });

  it("jurnal hari ini: aktif dengan d = 0", () => {
    expect(computeStatus(program("2026-10-07"), "2026-10-07", settings)).toEqual({
      status: "aktif",
      daysSinceLastJournal: 0,
    });
  });

  it("program dimulai hari ini tanpa jurnal: aktif dengan d = 1", () => {
    expect(computeStatus(program(null, "2026-10-07"), "2026-10-07", settings)).toEqual({
      status: "aktif",
      daysSinceLastJournal: 1,
    });
  });

  // Last journal Thu 1 Oct. Effective days after it: Fri 2, Sat 3, Mon 5, …
  it.each([
    ["2026-10-05", 3, "aktif"], // Fri, Sat, Mon
    ["2026-10-06", 4, "perlu_perhatian"],
    ["2026-10-09", 7, "perlu_perhatian"],
    ["2026-10-10", 8, "tidak_aktif"],
  ] as const)("batas ambang pada %s: d = %i → %s", (today, days, status) => {
    expect(computeStatus(program("2026-10-01"), today, settings)).toEqual({
      status,
      daysSinceLastJournal: days,
    });
  });

  it("hari Minggu dan libur tidak dihitung dalam ambang", () => {
    // Sat 3 → Mon 5: only Monday counts
    expect(computeStatus(program("2026-10-03"), "2026-10-05", settings).daysSinceLastJournal).toBe(1);
    const holidays = withHolidays("2026-10-05", "2026-10-06");
    expect(computeStatus(program("2026-10-03"), "2026-10-07", holidays).daysSinceLastJournal).toBe(1);
  });

  it("mengikuti ambang yang diatur admin", () => {
    const strict = {...settings, activeMaxDays: 1, attentionMaxDays: 2};
    expect(computeStatus(program("2026-10-05"), "2026-10-07", strict).status).toBe("perlu_perhatian");
    expect(computeStatus(program("2026-10-05"), "2026-10-08", strict).status).toBe("tidak_aktif");
  });
});

describe("computeProgramAggregates", () => {
  it("program tanpa jurnal", () => {
    expect(computeProgramAggregates([], "2026-10-07", settings)).toEqual({
      currentPage: 0,
      journalCount: 0,
      lastJournalDate: null,
      streakCurrent: 0,
      streakBest: 0,
      journalDates: [],
    });
  });

  it("progres adalah halaman tertinggi, membaca ulang tidak menurunkannya", () => {
    // Offline journals can arrive out of order.
    const journals = [
      {date: "2026-10-06", pageEnd: 90},
      {date: "2026-10-05", pageEnd: 40},
      {date: "2026-10-07", pageEnd: 60},
    ];
    expect(computeProgramAggregates(journals, "2026-10-07", settings)).toEqual({
      currentPage: 90,
      journalCount: 3,
      lastJournalDate: "2026-10-07",
      streakCurrent: 3,
      streakBest: 3,
      journalDates: ["2026-10-05", "2026-10-06", "2026-10-07"],
    });
  });
});

describe("percentOf dan isOverdue", () => {
  it("membulatkan ke bawah dan dibatasi 100", () => {
    expect(percentOf(0, 300)).toBe(0);
    expect(percentOf(230, 300)).toBe(76);
    expect(percentOf(299, 300)).toBe(99);
    expect(percentOf(300, 300)).toBe(100);
  });
  it("terlambat hanya setelah tanggal target lewat", () => {
    expect(isOverdue("2026-10-31", "2026-10-31")).toBe(false);
    expect(isOverdue("2026-10-31", "2026-11-01")).toBe(true);
  });
});
