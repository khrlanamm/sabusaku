import {DocumentSnapshot, FieldValue, WriteBatch} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

import {db, reportsCol} from "./firebase";

/**
 * Reports of content and users (`reports/{id}`), which Google Play's User
 * Generated Content policy asks for. Users file them through `reportContent`;
 * the teachers of the schools in `schools` review them in the app, and the
 * developer reviews every school with tools/reports.ts. Only Cloud Functions
 * write them.
 */

export const REPORT_KINDS = ["comment", "journal", "book", "suggestion", "user"] as const;
export type ReportKind = (typeof REPORT_KINDS)[number];

export const REPORT_REASONS = [
  "inappropriate",
  "harassment",
  "personal_data",
  "copyright",
  "wrong_data",
  "other",
] as const;

/** Reports one person may file in 24 hours. */
export const MAX_REPORTS_PER_DAY = 20;

/** Free text on a report: the reporter's note and the resolution. */
export const MAX_REPORT_TEXT = 500;

/** Who closed a report: a teacher, or the developer as "Pengembang". */
export interface Resolver {
  uid: string;
  name: string;
}

export const DEVELOPER_RESOLVER: Resolver = {uid: "developer", name: "Pengembang"};

/**
 * Marks a report resolved. `check` runs on the report first, inside the
 * transaction, and throws to refuse. Resolving a resolved report changes
 * nothing; returns whether this call resolved it.
 */
export async function resolveReportDoc(
  id: string,
  resolver: Resolver,
  resolution: string | null,
  check: (report: DocumentSnapshot) => void = () => undefined,
): Promise<boolean> {
  return db.runTransaction(async (transaction) => {
    const ref = reportsCol().doc(id);
    const report = await transaction.get(ref);
    if (!report.exists) throw new HttpsError("not-found", "Laporan tidak ditemukan.");
    check(report);
    if (report.get("status") === "resolved") return false;
    const now = FieldValue.serverTimestamp();
    transaction.update(ref, {
      status: "resolved",
      resolvedAt: now,
      resolvedBy: resolver,
      resolution,
      updatedAt: now,
    });
    return true;
  });
}

/** Batched writes allow at most 500 operations. */
const BATCH_LIMIT = 500;

/**
 * Forgets what the reports hold about someone whose data is erased or whose
 * account is deleted: the reports they filed go, since they carry the
 * reporter's name; reports about them or their content stay as a moderation
 * record, without the copy (`snapshot` emptied, `targetDeleted` set).
 */
export async function forgetReports(uid: string): Promise<void> {
  const [filed, about] = await Promise.all([
    reportsCol().where("reporterId", "==", uid).get(),
    reportsCol().where("subjectId", "==", uid).get(),
  ]);
  const now = FieldValue.serverTimestamp();
  const writes: ((batch: WriteBatch) => void)[] = [
    ...filed.docs.map((report) => (batch: WriteBatch) => batch.delete(report.ref)),
    ...about.docs
      // A report someone filed about their own content is already deleted above.
      .filter((report) => report.get("reporterId") !== uid)
      .map((report) => (batch: WriteBatch) =>
        // The reporter's note describes the person too.
        batch.update(report.ref, {snapshot: {}, note: null, targetDeleted: true, updatedAt: now}),
      ),
  ];
  for (let start = 0; start < writes.length; start += BATCH_LIMIT) {
    const batch = db.batch();
    for (const write of writes.slice(start, start + BATCH_LIMIT)) write(batch);
    await batch.commit();
  }
}
