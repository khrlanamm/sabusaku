import {logger} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {BACKGROUND_OPTIONS} from "../config";

import {addDays, monthOf, wibToday} from "../domain/dates";
import {monthPeriod, rankOf} from "../domain/ranking";
import {recapMessage} from "../domain/recap";
import {db, leaderboardsCol} from "../infra/firebase";
import {sendToUser} from "../infra/notify";
import {RankEntry} from "../infra/rankings";

/** Android notification channel created by the app (MainActivity). */
const CHANNEL_ID = "rekap_bulanan";

/**
 * Sends every student on last month's board of each active school their
 * numbers and rank by books finished (the app's default order). Students
 * without a journal or a finished book last month get nothing. Returns the
 * number of students notified. Exported for tests and manual runs.
 */
export async function sendMonthlyRecaps(now = Date.now()): Promise<number> {
  const today = wibToday(new Date(now));
  const month = monthOf(addDays(`${monthOf(today)}-01`, -1));
  const period = monthPeriod(month);
  const schools = await db.collection("schools").where("status", "==", "active").select().get();
  let notified = 0;
  for (const school of schools.docs) {
    const board = await leaderboardsCol(school.id).doc(period.id).get();
    const entries = new Map(
      Object.entries((board.get("entries") as Record<string, RankEntry> | undefined) ?? {}),
    );
    const ranks = rankOf(entries, "books");
    for (const [studentId, entry] of entries) {
      notified++;
      await sendToUser(school.id, studentId, {
        notification: recapMessage(month, entry, ranks.get(studentId)!, entries.size),
        // Opens the student's leaderboard on that month.
        data: {type: "recap", period: period.id},
        android: {notification: {channelId: CHANNEL_ID}},
      });
    }
  }
  logger.info("monthly recap done", {schools: schools.size, notified, month});
  return notified;
}

/**
 * The first of every month at 07:00 WIB, when the month before is closed:
 * journals may be written up to two days late, so the last day's numbers
 * can still grow until the 2nd. They rarely do, and a recap on the 3rd
 * would feel late. Not retried: a retry could notify twice.
 */
export const monthlyRecap = onSchedule(
  {
    ...BACKGROUND_OPTIONS,
    maxInstances: 1,
    schedule: "0 7 1 * *",
    timeZone: "Asia/Jakarta",
    timeoutSeconds: 540,
    retryCount: 0,
  },
  async () => {
    await sendMonthlyRecaps();
  },
);
