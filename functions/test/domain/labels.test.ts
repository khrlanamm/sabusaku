import {describe, expect, it} from "vitest";

import {
  compareClassLabels,
  isValidEmail,
  isValidSchoolId,
  normalizeClassLabel,
  normalizeEmail,
  normalizeExtracurricular,
} from "../../src/domain/labels";

describe("normalizeClassLabel", () => {
  // What students of SMA Negeri 1 Sukodadi actually typed.
  it.each([
    ["12  A1", "XII-A1"],
    ["XII-A2 ", "XII-A2"],
    ["XII-b2", "XII-B2"],
    ["12 C1 ", "XII-C1"],
    ["XI A4", "XI-A4"],
    ["X-G", "X-G"],
    ["XD", "X-D"],
    ["XIIC2", "XII-C2"],
    ["Xll-A1", "XII-A1"],
    ["X-G2", "X-G2"],
    ["10 IPA", null],
    ["XII", null],
    ["XI", null],
    ["kelas dua belas", null],
    ["", null],
  ])("%j → %j", (raw, expected) => {
    expect(normalizeClassLabel(raw)).toBe(expected);
  });

  it("mengurutkan per tingkat lalu huruf", () => {
    expect(["XII-A1", "X-G", "XI-B2", "X-D", "XII-A10"].sort(compareClassLabels)).toEqual([
      "X-D",
      "X-G",
      "XI-B2",
      "XII-A1",
      "XII-A10",
    ]);
  });
});

describe("email dan ekskul", () => {
  it("email dinormalkan dan divalidasi", () => {
    expect(normalizeEmail("  Alfin@Gmail.COM ")).toBe("alfin@gmail.com");
    expect(isValidEmail("alfin@gmail.com")).toBe(true);
    expect(isValidEmail("bukan-email")).toBe(false);
    expect(isValidEmail("a b@gmail.com")).toBe(false);
    expect(isValidEmail("a/b@gmail.com")).toBe(false);
  });

  it("label ekskul dirapikan", () => {
    expect(normalizeExtracurricular("  Masis   KIR ")).toBe("Masis KIR");
    expect(normalizeExtracurricular("P")).toBeNull();
    expect(normalizeExtracurricular("x".repeat(41))).toBeNull();
  });
});

describe("kode sekolah", () => {
  it.each([
    ["sman1sukodadi", true],
    ["e2e", true],
    ["a".repeat(30), true],
    ["ab", false],
    ["a".repeat(31), false],
    ["SMAN1", false],
    ["sman-1", false],
    ["sman 1", false],
    ["", false],
  ])("%j → %j", (code, expected) => {
    expect(isValidSchoolId(code)).toBe(expected);
  });
});
