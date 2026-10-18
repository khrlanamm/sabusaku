import {describe, expect, it} from "vitest";

import {attentionFor, DigestStudent, digestMessage} from "../../src/domain/digest";

const student = (name: string, extra: Partial<DigestStudent> = {}): DigestStudent => ({
  name,
  classId: "XII-A1",
  extracurriculars: [],
  status: "perlu_perhatian",
  ...extra,
});

describe("attentionFor", () => {
  const changed = [
    student("Raka"),
    student("Gita", {classId: "XII-A2", extracurriculars: ["PMR"], status: "tidak_aktif"}),
    student("Bima", {status: "aktif"}),
    student("Dewi", {classId: "XII-A2"}),
    student("Aldi", {classId: null, extracurriculars: ["Masis-KIR"]}),
  ];

  it("picks the teacher's students who need attention, sorted by name", () => {
    expect(
      attentionFor({homeroomClass: "XII-A1", extracurriculars: ["PMR"]}, changed).map((s) => s.name),
    ).toEqual(["Gita", "Raka"]);
    expect(
      attentionFor({homeroomClass: null, extracurriculars: ["Masis-KIR"]}, changed).map((s) => s.name),
    ).toEqual(["Aldi"]);
  });

  it("a teacher without a group gets nothing", () => {
    expect(attentionFor({homeroomClass: null, extracurriculars: []}, changed)).toEqual([]);
  });
});

describe("digestMessage", () => {
  it.each([
    [["Raka"], "Raka belum menulis jurnal beberapa hari."],
    [["Raka", "Gita"], "Raka dan Gita belum menulis jurnal beberapa hari."],
    [["Raka", "Gita", "Dewi"], "Raka, Gita, dan Dewi belum menulis jurnal beberapa hari."],
    [["Raka", "Gita", "Dewi", "Aldi"], "Raka, Gita, dan 2 lainnya belum menulis jurnal beberapa hari."],
  ])("%j", (names, body) => {
    expect(digestMessage(names)).toEqual({title: `${names.length} siswa binaan perlu perhatian`, body});
  });
});
