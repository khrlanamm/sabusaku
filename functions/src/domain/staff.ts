// Who students see as their homeroom teacher (wali kelas) and their
// extracurricular supervisors (pembina). Students cannot read teacher
// profiles, so the names are copied onto the school document.

export interface TeacherRoles {
  name: string;
  homeroomClass: string | null;
  extracurriculars: string[];
}

/** `schools/{schoolId}.staff`: teacher names per class and extracurricular. */
export interface SchoolStaff {
  homerooms: Record<string, string[]>;
  supervisors: Record<string, string[]>;
}

/** Groups teacher names by label, each list sorted. Nameless teachers are left out. */
export function staffOf(teachers: readonly TeacherRoles[]): SchoolStaff {
  const homerooms: Record<string, string[]> = {};
  const supervisors: Record<string, string[]> = {};
  const add = (map: Record<string, string[]>, label: string, name: string) => {
    (map[label] ??= []).push(name);
  };
  for (const teacher of teachers) {
    const name = teacher.name.trim();
    if (!name) continue;
    if (teacher.homeroomClass) add(homerooms, teacher.homeroomClass, name);
    for (const label of new Set(teacher.extracurriculars)) add(supervisors, label, name);
  }
  for (const map of [homerooms, supervisors]) {
    for (const names of Object.values(map)) names.sort((a, b) => a.localeCompare(b, "id"));
  }
  return {homerooms, supervisors};
}
