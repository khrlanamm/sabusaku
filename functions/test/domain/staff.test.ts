import {describe, expect, it} from "vitest";

import {staffOf} from "../../src/domain/staff";

describe("staffOf", () => {
  it("groups teacher names by homeroom class and extracurricular, sorted", () => {
    expect(
      staffOf([
        {name: "Sugito, S.T., M.Pd.", homeroomClass: null, extracurriculars: ["Masis-KIR"]},
        {name: "Sari Wulandari", homeroomClass: "XII-A1", extracurriculars: ["PMR", "Masis-KIR"]},
        {name: "Anam", homeroomClass: "XII-A1", extracurriculars: []},
      ]),
    ).toEqual({
      homerooms: {"XII-A1": ["Anam", "Sari Wulandari"]},
      supervisors: {"Masis-KIR": ["Sari Wulandari", "Sugito, S.T., M.Pd."], "PMR": ["Sari Wulandari"]},
    });
  });

  it("leaves out teachers without a name and is empty without roles", () => {
    expect(staffOf([{name: " ", homeroomClass: "X-A1", extracurriculars: ["PMR"]}])).toEqual({
      homerooms: {},
      supervisors: {},
    });
    expect(staffOf([])).toEqual({homerooms: {}, supervisors: {}});
  });
});
