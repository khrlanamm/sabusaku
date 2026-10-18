// The morning digest to a teacher about their own students ("Binaan saya")
// whose status just became perlu_perhatian or tidak_aktif.

import {StudentStatus} from "./types";

export interface DigestTeacher {
  homeroomClass: string | null;
  extracurriculars: string[];
}

export interface DigestStudent {
  name: string;
  classId: string | null;
  extracurriculars: string[];
  status: StudentStatus;
}

const ATTENTION: ReadonlySet<StudentStatus> = new Set(["perlu_perhatian", "tidak_aktif"]);

/** In the teacher's homeroom class or one of the extracurriculars they supervise. */
export function inGroup(teacher: DigestTeacher, student: DigestStudent): boolean {
  return (
    (teacher.homeroomClass !== null && student.classId === teacher.homeroomClass) ||
    student.extracurriculars.some((label) => teacher.extracurriculars.includes(label))
  );
}

/**
 * The teacher's students among `changed` (students whose status changed
 * recently) that now need attention, sorted by name.
 */
export function attentionFor(
  teacher: DigestTeacher,
  changed: readonly DigestStudent[],
): DigestStudent[] {
  return changed
    .filter((student) => ATTENTION.has(student.status) && inGroup(teacher, student))
    .sort((a, b) => a.name.localeCompare(b.name, "id"));
}

/** "3 siswa binaan perlu perhatian" / "Raka, Gita, dan 1 lainnya belum …". */
export function digestMessage(names: readonly string[]): {title: string; body: string} {
  const shown = names.length > 3 ? names.slice(0, 2) : names;
  const rest = names.length - shown.length;
  const who =
    rest > 0
      ? `${shown.join(", ")}, dan ${rest} lainnya`
      : shown.length > 1
        ? `${shown.slice(0, -1).join(", ")}${shown.length > 2 ? "," : ""} dan ${shown[shown.length - 1]}`
        : shown[0];
  return {
    title: `${names.length} siswa binaan perlu perhatian`,
    body: `${who} belum menulis jurnal beberapa hari.`,
  };
}
