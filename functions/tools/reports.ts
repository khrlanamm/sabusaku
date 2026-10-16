// Reviews the reports of content and users that people file in the app
// (Google Play's User Generated Content policy asks for ongoing moderation).
// Teachers see their own school's reports in the app; this shows every
// school's.
//
//   npx tsx tools/reports.ts --list [--status open|resolved|all] [--school sman1] [--emulator]
//   npx tsx tools/reports.ts --resolve <id> [--note "Komentar sudah dihapus guru."] [--emulator]
//
// `--list` shows open reports unless `--status` says otherwise, newest first.
// `--resolve` closes a report as "Pengembang"; the note is the resolution
// the school's teachers see.

import {arg, hasFlag, run, target} from "./_env";

import {DocumentSnapshot, Timestamp} from "firebase-admin/firestore";

import {reportsCol} from "../src/infra/firebase";
import {DEVELOPER_RESOLVER, MAX_REPORT_TEXT, resolveReportDoc} from "../src/infra/reports";

const STATUSES = ["open", "resolved", "all"];

/** `yyyy-MM-dd HH:mm` in WIB. */
function wibTime(value: unknown): string {
  if (!(value instanceof Timestamp)) return "-";
  return new Date(value.toMillis() + 7 * 3600_000).toISOString().slice(0, 16).replace("T", " ");
}

function clip(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

/** The reported content in one line, from the copy taken at report time. */
function summary(report: DocumentSnapshot): string {
  if (report.get("targetDeleted")) return "(sudah dihapus)";
  const snapshot = (report.get("snapshot") as Record<string, unknown> | undefined) ?? {};
  switch (report.get("kind")) {
    case "comment":
      return `${snapshot.authorName}: "${snapshot.text}"`;
    case "journal":
      return `${snapshot.studentName} ${snapshot.date}: "${snapshot.keyInformation}"`;
    case "book":
      return `${snapshot.title} (${((snapshot.authors as string[] | undefined) ?? []).join(", ")})`;
    case "suggestion":
      return `${snapshot.title}`;
    case "user":
      return `${snapshot.name} (${snapshot.role})`;
    default:
      return JSON.stringify(snapshot);
  }
}

function printTable(rows: string[][]): void {
  const widths = rows[0].map((_, column) => Math.max(...rows.map((row) => row[column].length)));
  for (const row of rows) {
    console.log(row.map((cell, column) => cell.padEnd(widths[column])).join("  ").trimEnd());
  }
}

async function list(): Promise<void> {
  const status = arg("status") ?? "open";
  if (!STATUSES.includes(status)) throw new Error('--status harus "open", "resolved", atau "all".');
  const school = arg("school")?.toLowerCase();

  const query = school
    ? reportsCol().where("schools", "array-contains", school).orderBy("createdAt", "desc")
    : reportsCol().orderBy("createdAt", "desc");
  const reports = (await query.get()).docs.filter(
    (report) => status === "all" || report.get("status") === status,
  );
  if (reports.length === 0) {
    console.log(`Tidak ada laporan (${status}${school ? `, ${school}` : ""}) di ${target()}.`);
    return;
  }

  // Open reports have no resolution yet; leave the column out for them.
  const withResolution = status !== "open";
  printTable([
    ["ID", "WAKTU (WIB)", "STATUS", "JENIS", "ALASAN", "SEKOLAH", "PELAPOR", "ISI", "CATATAN"].concat(
      withResolution ? ["PENYELESAIAN"] : [],
    ),
    ...reports.map((report) => {
      const row = [
        report.id,
        wibTime(report.get("createdAt")),
        report.get("status") as string,
        report.get("kind") as string,
        report.get("reason") as string,
        ((report.get("schools") as string[] | undefined) ?? []).join(","),
        `${report.get("reporterName") || "-"} (${report.get("reporterRole")})`,
        clip(summary(report), 60),
        clip((report.get("note") as string | null) ?? "", 40),
      ];
      if (!withResolution) return row;
      const by = report.get("resolvedBy") as {name?: string} | undefined;
      const resolution = (report.get("resolution") as string | null | undefined) ?? "";
      return [...row, by ? clip(`${by.name}${resolution ? `: ${resolution}` : ""}`, 50) : ""];
    }),
  ]);
  console.log(`\n${reports.length} laporan di ${target()}.`);
}

async function resolve(id: string): Promise<void> {
  const note = arg("note")?.trim() || null;
  if (note && note.length > MAX_REPORT_TEXT) {
    throw new Error(`--note maksimal ${MAX_REPORT_TEXT} karakter.`);
  }
  const resolved = await resolveReportDoc(id, DEVELOPER_RESOLVER, note);
  console.log(
    resolved
      ? `Laporan ${id} ditandai selesai oleh ${DEVELOPER_RESOLVER.name} di ${target()}.`
      : `Laporan ${id} sudah selesai sebelumnya; tidak ada yang diubah.`,
  );
}

run(async () => {
  const id = arg("resolve");
  if (id) return resolve(id);
  if (hasFlag("list")) return list();
  throw new Error('Pakai --list [--status open|resolved|all] [--school kode] atau --resolve <id> [--note "..."].');
});
