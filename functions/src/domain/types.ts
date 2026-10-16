export type Role = "guru" | "siswa";
export const ROLES: readonly Role[] = ["guru", "siswa"];

export interface SchoolSettings {
  /** 0 = Sunday … 6 = Saturday. Neutral days never break a streak. */
  neutralWeekdays: number[];
  /** School holidays as `yyyy-MM-dd`. */
  holidays: string[];
  activeMaxDays: number;
  attentionMaxDays: number;
}

export const DEFAULT_SETTINGS: SchoolSettings = {
  neutralWeekdays: [0],
  holidays: [],
  activeMaxDays: 3,
  attentionMaxDays: 7,
};

export type StudentStatus = "aktif" | "perlu_perhatian" | "tidak_aktif" | "belum_mulai";

export const MAX_STUDENTS_PER_CALL = 100;
export const MAX_CLASSES = 200;
export const MAX_EXTRACURRICULARS = 50;
/** Extracurriculars one person can belong to. */
export const MAX_MEMBER_EXTRACURRICULARS = 10;
