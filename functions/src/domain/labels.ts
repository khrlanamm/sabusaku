/**
 * Class and extracurricular labels. Must stay in sync with
 * lib/core/utils/labels.dart.
 */

/** `X`, `XI` or `XII`, a hyphen, one or two letters, up to two digits. */
export const CLASS_LABEL_RE = /^(X|XI|XII)-[A-Z]{1,2}[0-9]{0,2}$/;

const GRADE_PART = "(XII|XLL|XIL|XLI|XI|XL|X|12|11|10)";

/** Grade and class separated by a hyphen or spaces: `12  A1`, `XI A4`. */
const SEPARATED_RE = new RegExp(`^${GRADE_PART}\\s*[-\\s]\\s*([A-Z]{1,2})\\s*([0-9]{0,2})$`);

/**
 * No separator (`XIIC2`, `XD`). The class letter cannot be I or L there,
 * otherwise `XII` alone would read as `XI-I`.
 */
const JOINED_RE = new RegExp(`^${GRADE_PART}([A-HJKM-Z][A-Z]?)([0-9]{0,2})$`);

const GRADES: Record<string, string> = {
  XII: "XII", XLL: "XII", XIL: "XII", XLI: "XII", "12": "XII",
  XI: "XI", XL: "XI", "11": "XI",
  X: "X", "10": "X",
};

/**
 * Turns what people type (`12  A1`, `XIIC2`, `Xll-A1`, `XI A4`, `XD`) into the
 * canonical label (`XII-A1`, `XII-C2`, `XII-A1`, `XI-A4`, `X-D`). Null when the
 * text is not a class label.
 */
export function normalizeClassLabel(raw: string): string | null {
  const text = raw.trim().toUpperCase();
  const match = SEPARATED_RE.exec(text) ?? JOINED_RE.exec(text);
  if (!match) return null;
  const label = `${GRADES[match[1]]}-${match[2]}${match[3]}`;
  return CLASS_LABEL_RE.test(label) ? label : null;
}

/** Sorts labels by grade (X, XI, XII), then by the rest. */
export function compareClassLabels(a: string, b: string): number {
  const grade = (label: string) =>
    ({X: 10, XI: 11, XII: 12} as Record<string, number>)[label.split("-")[0]] ?? 99;
  return grade(a) - grade(b) || a.localeCompare(b);
}

export const EXTRACURRICULAR_MIN = 2;
export const EXTRACURRICULAR_MAX = 40;
export const DEFAULT_EXTRACURRICULARS = ["Masis-KIR", "Paskibra", "Pala", "PMR"];

/** Trims and collapses spaces; null when too short or too long. */
export function normalizeExtracurricular(raw: string): string | null {
  const label = raw.trim().replace(/\s+/g, " ");
  return label.length >= EXTRACURRICULAR_MIN && label.length <= EXTRACURRICULAR_MAX
    ? label
    : null;
}

/** Lower-case, trimmed address. Also the `members/{email}` document ID. */
export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

const EMAIL_RE = /^[^\s@/]+@[^\s@/]+\.[^\s@/]+$/;

export function isValidEmail(email: string): boolean {
  return email.length <= 254 && EMAIL_RE.test(email);
}
