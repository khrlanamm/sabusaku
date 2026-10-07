// Fills a demo school: 2 classes, 2 teachers, 10 students and a few weeks of
// journals covering every status, for UI work, demos and store review.
//
//   npx tsx tools/seed-demo.ts [--code demo] [--password <min 8 chars>] [--emulator]
//
// All demo accounts share one password and skip the forced password change.
// The credentials are written to secret/demo-credentials.csv.
// Remove the school again with tools/delete-school.ts.

import {arg, run, secretDir, target} from "./_env";

import {randomInt} from "node:crypto";
import {mkdirSync, writeFileSync} from "node:fs";
import {join} from "node:path";

import {FieldValue} from "firebase-admin/firestore";

import {computeProgramAggregates, effectiveDayChecker} from "../src/domain/activity";
import {addDays, endOfMonth, monthOf, wibToday} from "../src/domain/dates";
import {isValidSchoolId} from "../src/domain/identity";
import {DEFAULT_SETTINGS} from "../src/domain/types";
import {createAccount} from "../src/infra/accounts";
import {
  activeProgramsCol,
  auth,
  classesCol,
  db,
  programsCol,
  schoolRef,
  usersCol,
} from "../src/infra/firebase";
import {generatePassword} from "../src/infra/passwords";
import {createSchool} from "../src/infra/schools";
import {refreshSchool} from "../src/infra/stats";

const CLASSES = [
  {id: "xi-ipa-1", name: "XI IPA 1", grade: 11},
  {id: "xi-ips-1", name: "XI IPS 1", grade: 11},
];

const TEACHERS = [
  {username: "guru1", name: "Sari Wulandari", classIds: ["xi-ipa-1", "xi-ips-1"]},
  {username: "guru2", name: "Budi Hartono", classIds: ["xi-ips-1"]},
];

/**
 * `lastGap`: effective days since the last journal (0 = wrote today).
 * `skipEvery`: leaves a gap every n-th effective day, which breaks streaks.
 * `finished`: also has a completed book from the previous month.
 * `overdue`: never extended the target, so the book shows as "Terlambat".
 */
interface Reader {
  username: string;
  name: string;
  classId: string;
  book?: {title: string; author: string; totalPages: number};
  lastGap?: number;
  skipEvery?: number;
  pagesPerDay?: number;
  finished?: {title: string; author: string; totalPages: number};
  overdue?: boolean;
}

const STUDENTS: Reader[] = [
  {username: "2001", name: "Raka Pratama", classId: "xi-ipa-1", lastGap: 0, pagesPerDay: 14,
    book: {title: "Laskar Pelangi", author: "Andrea Hirata", totalPages: 529},
    finished: {title: "Negeri 5 Menara", author: "Ahmad Fuadi", totalPages: 423}},
  {username: "2002", name: "Dewi Lestari Putri", classId: "xi-ipa-1", lastGap: 0, pagesPerDay: 18,
    book: {title: "Bumi", author: "Tere Liye", totalPages: 440}},
  {username: "2003", name: "Fajar Nugroho", classId: "xi-ipa-1", lastGap: 1, skipEvery: 4, pagesPerDay: 10,
    book: {title: "Bumi Manusia", author: "Pramoedya Ananta Toer", totalPages: 535}},
  {username: "2004", name: "Siti Nurhaliza", classId: "xi-ipa-1", lastGap: 5, pagesPerDay: 12,
    book: {title: "Ronggeng Dukuh Paruk", author: "Ahmad Tohari", totalPages: 408}},
  {username: "2005", name: "Yoga Saputra", classId: "xi-ipa-1"},
  {username: "2006", name: "Anisa Rahmawati", classId: "xi-ips-1", lastGap: 0, pagesPerDay: 16,
    book: {title: "Hujan", author: "Tere Liye", totalPages: 320},
    finished: {title: "Pulang", author: "Tere Liye", totalPages: 400}},
  {username: "2007", name: "Bima Aditya", classId: "xi-ips-1", lastGap: 2, skipEvery: 3, pagesPerDay: 9,
    book: {title: "Cantik Itu Luka", author: "Eka Kurniawan", totalPages: 505}},
  {username: "2008", name: "Citra Maharani", classId: "xi-ips-1", lastGap: 6, pagesPerDay: 11,
    book: {title: "Perahu Kertas", author: "Dee Lestari", totalPages: 444}},
  {username: "2009", name: "Dimas Anggara", classId: "xi-ips-1", lastGap: 11, pagesPerDay: 8, overdue: true,
    book: {title: "Sang Pemimpi", author: "Andrea Hirata", totalPages: 292}},
  {username: "2010", name: "Eka Prasetyo", classId: "xi-ips-1"},
];

const NOTES = [
  "Tokoh utama mulai menyadari bahwa pendidikan adalah jalan untuk mengubah hidupnya.",
  "Bab ini menceritakan persahabatan para tokoh dan cara mereka saling menguatkan.",
  "Penulis menggambarkan suasana kampung dengan sangat rinci sehingga terasa nyata.",
  "Konflik mulai muncul ketika tokoh utama harus memilih antara keluarga dan cita-citanya.",
  "Ada kilas balik ke masa kecil tokoh yang menjelaskan mengapa ia begitu gigih belajar.",
  "Bagian ini memperkenalkan tokoh baru yang membawa sudut pandang berbeda tentang kehidupan.",
];
const REFLECTIONS = [
  "Perjuangan tokoh utama sangat menginspirasi.",
  "Saya suka cara penulis menyelipkan humor di tengah cerita yang serius.",
  "",
  "Deskripsi tempatnya membuat saya ingin berkunjung ke sana.",
];
const QUESTIONS = [
  "Mengapa tokoh utama tetap bersekolah meskipun fasilitasnya terbatas?",
  "",
  "Apa yang akan terjadi jika ia memilih jalan yang lain?",
  "",
];
const DURATIONS = ["lt15", "15to30", "30to60", "gt60"];
const pick = <T>(list: readonly T[], index: number): T => list[index % list.length];

/** Writes one book with its journals and derived fields. */
async function writeProgram(
  schoolId: string,
  uid: string,
  reader: Reader,
  book: NonNullable<Reader["book"]>,
  options: {startDate: string; endDate: string; status: "active" | "completed"; today: string},
): Promise<string> {
  const isEffective = effectiveDayChecker(DEFAULT_SETTINGS);
  const programRef = programsCol(schoolId).doc();
  const perDay = reader.pagesPerDay ?? 12;
  const completed = options.status === "completed";
  // A book carried over from last month was extended to the end of this one,
  // unless the reader is the "overdue" example.
  const extended =
    !completed && !reader.overdue && monthOf(options.startDate) !== monthOf(options.today);

  const journals: {date: string; pageStart: number; pageEnd: number}[] = [];
  let page = 0;
  let effectiveIndex = 0;
  for (let day = options.startDate; day <= options.endDate; day = addDays(day, 1)) {
    if (!isEffective(day)) continue;
    effectiveIndex++;
    if (reader.skipEvery && effectiveIndex % reader.skipEvery === 0) continue;
    if (page >= book.totalPages) break;
    const pageEnd = Math.min(book.totalPages, page + perDay + (effectiveIndex % 5));
    journals.push({date: day, pageStart: page + 1, pageEnd});
    page = pageEnd;
  }
  // A finished book ends on its last page.
  if (completed && journals.length > 0) journals[journals.length - 1].pageEnd = book.totalPages;

  const writer = db.bulkWriter();
  journals.forEach((journal, index) => {
    const reflection = pick(REFLECTIONS, index);
    const question = pick(QUESTIONS, index + 1);
    void writer.set(programRef.collection("journals").doc(journal.date), {
      studentId: uid,
      date: journal.date,
      pageStart: journal.pageStart,
      pageEnd: journal.pageEnd,
      durationRange: pick(DURATIONS, index),
      keyInformation: pick(NOTES, index),
      ...(reflection ? {reflection} : {}),
      ...(question ? {question} : {}),
      hasUnreadTeacherComment: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  const aggregates = computeProgramAggregates(journals, options.today, DEFAULT_SETTINGS);
  void writer.set(programRef, {
    studentId: uid,
    classId: reader.classId,
    book,
    month: monthOf(options.startDate),
    startDate: options.startDate,
    targetDate: extended ? endOfMonth(options.today) : endOfMonth(options.startDate),
    extended,
    status: options.status,
    ...(completed
      ? {finalReflection: "Buku yang membuka wawasan saya.", completedAt: FieldValue.serverTimestamp()}
      : {}),
    ...aggregates,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (!completed) void writer.set(activeProgramsCol(schoolId).doc(uid), {programId: programRef.id});
  await writer.close();
  return programRef.id;
}

/** The date `gap` effective days before `today`. */
function effectiveDaysAgo(today: string, gap: number): string {
  const isEffective = effectiveDayChecker(DEFAULT_SETTINGS);
  let day = today;
  for (let remaining = gap; remaining > 0; ) {
    day = addDays(day, -1);
    if (isEffective(day)) remaining--;
  }
  return day;
}

run(async () => {
  const code = (arg("code") ?? "demo").toLowerCase();
  const password = arg("password") ?? `${generatePassword(8)}${randomInt(10, 99)}`;
  if (!isValidSchoolId(code)) throw new Error("Kode sekolah tidak valid.");
  if (password.length < 8) throw new Error("Password minimal 8 karakter.");

  const today = wibToday();
  const credentials: string[][] = [["peran", "nama", "username", "password", "kelas"]];
  const className = (id: string) => CLASSES.find((c) => c.id === id)!.name;

  /** Demo accounts share a password and skip the forced change. */
  const ready = async (uid: string) => {
    await auth.updateUser(uid, {password});
    await usersCol(code).doc(uid).update({mustChangePassword: false});
  };

  const admin = await createSchool(code, "SMA Demo Sabu Saku", {
    username: "admin",
    name: "Admin Demo",
  });
  await ready(admin.uid);
  credentials.push(["admin", "Admin Demo", "admin", password, ""]);

  for (const item of CLASSES) {
    const month = Number(today.slice(5, 7));
    const year = Number(today.slice(0, 4)) - (month >= 7 ? 0 : 1);
    await classesCol(code).doc(item.id).set({
      name: item.name,
      grade: item.grade,
      academicYear: `${year}/${year + 1}`,
      teacherIds: [],
      isArchived: false,
    });
  }

  const teacherUids: Record<string, string> = {};
  for (const teacher of TEACHERS) {
    const account = await createAccount(code, {role: "guru", ...teacher});
    await ready(account.uid);
    teacherUids[teacher.username] = account.uid;
    credentials.push(["guru", teacher.name, teacher.username, password, teacher.classIds.map(className).join("|")]);
  }

  // Books of the current month started on the 1st, or three weeks ago when
  // the month is still young, so there is a history to look at.
  const monthStart = `${monthOf(today)}-01`;
  const startDate = addDays(today, -21) < monthStart ? addDays(today, -21) : monthStart;
  const previousEnd = addDays(startDate, -1);
  const previousStart = addDays(previousEnd, -27);

  let firstJournal: {programId: string; date: string} | undefined;
  for (const student of STUDENTS) {
    const account = await createAccount(code, {
      role: "siswa",
      name: student.name,
      username: student.username,
      classId: student.classId,
      className: className(student.classId),
    });
    await ready(account.uid);
    credentials.push(["siswa", student.name, student.username, password, className(student.classId)]);

    if (student.finished) {
      await writeProgram(code, account.uid, {...student, skipEvery: undefined, pagesPerDay: 22}, student.finished, {
        startDate: previousStart,
        endDate: previousEnd,
        status: "completed",
        today,
      });
    }
    if (student.book) {
      const endDate = effectiveDaysAgo(today, student.lastGap ?? 0);
      const programId = await writeProgram(code, account.uid, student, student.book, {
        startDate,
        endDate,
        status: "active",
        today,
      });
      if (!firstJournal && student.lastGap === 0) firstJournal = {programId, date: endDate};
    }
  }

  // One teacher comment, so the "new comment" badge and the thread have data.
  if (firstJournal) {
    await programsCol(code)
      .doc(firstJournal.programId)
      .collection("journals")
      .doc(firstJournal.date)
      .collection("comments")
      .add({
        teacherId: teacherUids.guru1,
        teacherName: TEACHERS[0].name,
        text: "Ringkasanmu jelas dan runtut. Coba kaitkan dengan pengalamanmu sendiri ya.",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    await programsCol(code)
      .doc(firstJournal.programId)
      .collection("journals")
      .doc(firstJournal.date)
      .update({hasUnreadTeacherComment: true, lastCommentAt: FieldValue.serverTimestamp()});
  }

  const students = await refreshSchool(code, today);
  const school = await schoolRef(code).get();

  mkdirSync(secretDir, {recursive: true});
  const file = join(secretDir, `${code}-credentials.csv`);
  writeFileSync(file, credentials.map((row) => row.join(",")).join("\n") + "\n");

  console.log(`Sekolah demo "${school.get("name")}" dibuat di ${target()}.`);
  console.log(`  Kode sekolah: ${code}`);
  console.log(`  Akun        : admin, guru1, guru2, 2001–2010 (${students} siswa)`);
  console.log(`  Kredensial  : ${file}`);
});
