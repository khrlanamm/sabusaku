import {describe, expect, it} from "vitest";

import {
  addDays,
  daysBetween,
  endOfMonth,
  isDateId,
  monthOf,
  weekdayOf,
  wibToday,
} from "../../src/domain/dates";

describe("wibToday", () => {
  it("23:59 WIB masih hari yang sama", () => {
    expect(wibToday(new Date("2026-10-07T16:59:00Z"))).toBe("2026-10-07");
  });
  it("00:01 WIB sudah hari berikutnya", () => {
    expect(wibToday(new Date("2026-10-07T17:01:00Z"))).toBe("2026-10-08");
  });
  it("melewati pergantian tahun", () => {
    expect(wibToday(new Date("2026-12-31T18:00:00Z"))).toBe("2027-01-01");
  });
});

describe("aritmetika tanggal", () => {
  it("menambah hari melewati batas bulan dan tahun kabisat", () => {
    expect(addDays("2026-10-31", 1)).toBe("2026-11-01");
    expect(addDays("2028-02-28", 1)).toBe("2028-02-29");
    expect(addDays("2027-01-01", -1)).toBe("2026-12-31");
  });
  it("menghitung selisih hari", () => {
    expect(daysBetween("2026-10-05", "2026-10-07")).toBe(2);
    expect(daysBetween("2026-10-07", "2026-10-05")).toBe(-2);
  });
  it("hari dalam minggu: 0 = Minggu", () => {
    expect(weekdayOf("2026-10-04")).toBe(0);
    expect(weekdayOf("2026-10-07")).toBe(3);
    expect(weekdayOf("2026-10-10")).toBe(6);
  });
  it("bulan dan akhir bulan", () => {
    expect(monthOf("2026-10-07")).toBe("2026-10");
    expect(endOfMonth("2026-10-07")).toBe("2026-10-31");
    expect(endOfMonth("2026-02-10")).toBe("2026-02-28");
  });
  it("memvalidasi ID tanggal", () => {
    expect(isDateId("2026-10-07")).toBe(true);
    expect(isDateId("2026-02-30")).toBe(false);
    expect(isDateId("2026-1-7")).toBe(false);
    expect(isDateId(20261007)).toBe(false);
  });
});
