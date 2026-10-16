// Profile photos in Cloud Storage: schools/{schoolId}/avatars/{uid}.jpg.

import {readFileSync} from "node:fs";
import {resolve} from "node:path";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {deleteObject, getBytes, ref, uploadBytes} from "firebase/storage";
import {afterAll, beforeAll, beforeEach, describe, it} from "vitest";

import {OTHER_SCHOOL, SCHOOL} from "./helpers";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-sabusaku",
    storage: {rules: readFileSync(resolve(__dirname, "../../../storage.rules"), "utf8")},
  });
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearStorage();
});

const photo = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const jpeg = {contentType: "image/jpeg"};
const path = (uid: string, school = SCHOOL) => `schools/${school}/avatars/${uid}.jpg`;
const storageOf = (uid: string, claims: Record<string, unknown>) =>
  env.authenticatedContext(uid, claims).storage();

describe("foto profil", () => {
  const student = () => storageOf("siswa1", {role: "siswa", schoolId: SCHOOL});

  it("pemilik mengunggah, mengganti, dan menghapus fotonya", async () => {
    const mine = ref(student(), path("siswa1"));
    await assertSucceeds(uploadBytes(mine, photo, jpeg));
    await assertSucceeds(uploadBytes(mine, photo, jpeg));
    await assertSucceeds(deleteObject(mine));
  });

  it("hanya gambar di bawah 1 MB, hanya di jalurnya sendiri", async () => {
    await assertFails(uploadBytes(ref(student(), path("siswa1")), photo, {contentType: "text/plain"}));
    await assertFails(
      uploadBytes(ref(student(), path("siswa1")), new Uint8Array(1024 * 1024 + 1), jpeg),
    );
    await assertFails(uploadBytes(ref(student(), path("siswa2")), photo, jpeg));
    await assertFails(uploadBytes(ref(student(), path("siswa1", OTHER_SCHOOL)), photo, jpeg));
    await assertFails(uploadBytes(ref(student(), `schools/${SCHOOL}/lain/siswa1.jpg`), photo, jpeg));
    await assertFails(
      uploadBytes(ref(env.unauthenticatedContext().storage(), path("siswa1")), photo, jpeg),
    );
  });

  it("anggota sekolah melihat foto; orang luar tidak", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), path("siswa1")), photo, jpeg);
    });
    const teacher = storageOf("guru1", {role: "guru", schoolId: SCHOOL});
    await assertSucceeds(getBytes(ref(teacher, path("siswa1"))));
    await assertFails(getBytes(ref(storageOf("guru9", {role: "guru", schoolId: OTHER_SCHOOL}), path("siswa1"))));
    await assertFails(getBytes(ref(storageOf("ghost", {}), path("siswa1"))));
    await assertFails(deleteObject(ref(teacher, path("siswa1"))));
  });
});

describe("cover buku milik siswa", () => {
  const cover = (uid: string, school = SCHOOL) => `schools/${school}/programCovers/${uid}/1700000000.jpg`;
  const student = () => storageOf("siswa1", {role: "siswa", schoolId: SCHOOL});

  it("siswa mengunggah dan menghapus cover di foldernya sendiri", async () => {
    const mine = ref(student(), cover("siswa1"));
    await assertSucceeds(uploadBytes(mine, photo, jpeg));
    await assertSucceeds(getBytes(mine));
    await assertSucceeds(deleteObject(mine));
  });

  it("bukan gambar, terlalu besar, atau folder orang lain ditolak", async () => {
    await assertFails(uploadBytes(ref(student(), cover("siswa1")), photo, {contentType: "text/plain"}));
    await assertFails(
      uploadBytes(ref(student(), cover("siswa1")), new Uint8Array(1024 * 1024 + 1), jpeg),
    );
    await assertFails(uploadBytes(ref(student(), cover("siswa2")), photo, jpeg));
    await assertFails(uploadBytes(ref(student(), cover("siswa1", OTHER_SCHOOL)), photo, jpeg));
  });

  it("anggota sekolah melihatnya; sekolah lain tidak; orang lain tidak menghapus", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), cover("siswa1")), photo, jpeg);
    });
    const teacher = storageOf("guru1", {role: "guru", schoolId: SCHOOL});
    await assertSucceeds(getBytes(ref(teacher, cover("siswa1"))));
    await assertFails(
      getBytes(ref(storageOf("guru9", {role: "guru", schoolId: OTHER_SCHOOL}), cover("siswa1"))),
    );
    await assertFails(deleteObject(ref(teacher, cover("siswa1"))));
  });
});

describe("cover katalog", () => {
  const path = "books/bk_laskar/cover-1700000000.jpg";
  const teacher = (school = SCHOOL) => storageOf("guru1", {role: "guru", schoolId: school});

  it("guru sekolah mana pun mengunggah; anggota mana pun melihat", async () => {
    await assertSucceeds(uploadBytes(ref(teacher(OTHER_SCHOOL), path), photo, jpeg));
    await assertSucceeds(getBytes(ref(storageOf("siswa1", {role: "siswa", schoolId: SCHOOL}), path)));
    await assertFails(getBytes(ref(storageOf("ghost", {}), path)));
  });

  it("siswa, bukan gambar, terlalu besar, dan menghapus ditolak", async () => {
    await assertFails(
      uploadBytes(ref(storageOf("siswa1", {role: "siswa", schoolId: SCHOOL}), path), photo, jpeg),
    );
    await assertFails(uploadBytes(ref(teacher(), path), photo, {contentType: "text/plain"}));
    await assertFails(uploadBytes(ref(teacher(), path), new Uint8Array(1024 * 1024 + 1), jpeg));
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), path), photo, jpeg);
    });
    await assertFails(deleteObject(ref(teacher(), path)));
  });
});
