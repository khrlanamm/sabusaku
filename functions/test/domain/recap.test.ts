import {describe, expect, it} from "vitest";

import {monthName, recapMessage} from "../../src/domain/recap";

describe("rekap bulanan", () => {
  it("nama bulan", () => {
    expect(monthName("2026-01")).toBe("Januari 2026");
    expect(monthName("2026-10")).toBe("Oktober 2026");
    expect(monthName("2026-12")).toBe("Desember 2026");
  });

  it("dengan buku selesai", () => {
    expect(recapMessage("2026-10", {books: 1, streak: 12, days: 22}, 4, 120)).toEqual({
      title: "Rekap membaca Oktober 2026",
      body: "1 buku selesai, 22 hari membaca, streak terbaik 12 hari. Peringkat #4 dari 120 siswa di sekolahmu.",
    });
  });

  it("tanpa buku selesai, angka buku tidak disebut", () => {
    expect(recapMessage("2026-11", {books: 0, streak: 3, days: 5}, 7, 7).body).toBe(
      "5 hari membaca, streak terbaik 3 hari. Peringkat #7 dari 7 siswa di sekolahmu.",
    );
  });
});
