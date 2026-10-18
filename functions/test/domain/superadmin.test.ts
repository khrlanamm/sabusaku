import {describe, expect, it} from "vitest";

import {isSuperadminEmail} from "../../src/domain/superadmin";

describe("isSuperadminEmail", () => {
  it("mengenali email superadmin apa pun penulisannya", () => {
    expect(isSuperadminEmail("benevology@gmail.com")).toBe(true);
    expect(isSuperadminEmail("  Benevology@Gmail.COM ")).toBe(true);
  });

  it("menolak email lain dan email kosong", () => {
    expect(isSuperadminEmail("anam160404@gmail.com")).toBe(false);
    expect(isSuperadminEmail("benevology@gmail.co")).toBe(false);
    expect(isSuperadminEmail("")).toBe(false);
    expect(isSuperadminEmail(undefined)).toBe(false);
    expect(isSuperadminEmail(null)).toBe(false);
  });
});
