// The notification each student gets on the first of the month about the
// month before (docs/04 §3).

import {RankMetrics} from "./ranking";

const MONTHS = [
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember",
];

/** "Oktober 2026" for `2026-10`. */
export function monthName(month: string): string {
  return `${MONTHS[Number(month.slice(5, 7)) - 1]} ${month.slice(0, 4)}`;
}

/**
 * "Rekap membaca Oktober 2026" / "1 buku selesai, 22 hari membaca, streak
 * terbaik 12 hari. Peringkat #4 dari 120 siswa di sekolahmu."
 */
export function recapMessage(
  month: string,
  metrics: RankMetrics,
  rank: number,
  of: number,
): {title: string; body: string} {
  const parts = [
    ...(metrics.books > 0 ? [`${metrics.books} buku selesai`] : []),
    `${metrics.days} hari membaca`,
    `streak terbaik ${metrics.streak} hari`,
  ];
  return {
    title: `Rekap membaca ${monthName(month)}`,
    body: `${parts.join(", ")}. Peringkat #${rank} dari ${of} siswa di sekolahmu.`,
  };
}
