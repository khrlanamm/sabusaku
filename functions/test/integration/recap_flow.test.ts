// The monthly recap reads last month's board of each active school and
// notifies every student on it. FCM itself is not called: nobody here has a
// device token.

import {afterAll, beforeAll, describe, expect, it} from "vitest";

import {leaderboardsCol, schoolRef} from "../../src/infra/firebase";
import {sendMonthlyRecaps} from "../../src/scheduled/monthlyRecap";
import {addSchool, clearEmulators, closeClients} from "./helpers";

const row = (books: number, streak: number, days: number) => ({
  name: "Siswa",
  classId: "XII-A1",
  extracurriculars: [],
  books,
  streak,
  days,
});

beforeAll(async () => {
  await clearEmulators();
  await addSchool("sman1");
  await addSchool("sman2");
  await addSchool("sman3");
  await schoolRef("sman3").update({status: "suspended"});
  await leaderboardsCol("sman1")
    .doc("month-2026-10")
    .set({kind: "month", entries: {a: row(1, 5, 20), b: row(0, 2, 3)}});
  await leaderboardsCol("sman1").doc("month-2026-11").set({kind: "month", entries: {a: row(0, 1, 1)}});
  await leaderboardsCol("sman3").doc("month-2026-10").set({kind: "month", entries: {c: row(1, 1, 1)}});
});

afterAll(closeClients);

describe("rekap bulanan", () => {
  it("1 November merekap Oktober untuk siswa di papan sekolah aktif", async () => {
    // 1 Nov 2026, 07:00 WIB.
    expect(await sendMonthlyRecaps(Date.parse("2026-11-01T00:00:00Z"))).toBe(2);
  });

  it("bulan tanpa papan tidak mengirim apa pun", async () => {
    expect(await sendMonthlyRecaps(Date.parse("2026-10-01T00:00:00Z"))).toBe(0);
  });
});
