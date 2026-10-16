# Play Store listing (default language: Indonesian)

The text below is what is saved in Play Console for the default store
listing. Edit it here first, then paste it into Play Console.

## App name (30 characters max)

Sabu Saku: Jurnal Membaca

## Short description (80 characters max)

Jurnal membaca harian siswa, dengan katalog 1.000+ buku dan komentar guru.

## Full description (4000 characters max)

```text
Sabu Saku (Satu Bulan Satu Buku) adalah jurnal membaca untuk sekolah. Siswa membaca satu buku setiap bulan dan mencatat bacaannya setiap hari. Penanggung jawab di sekolah, seperti guru atau pembina ekstrakurikuler, melihat siapa yang rajin dan siapa yang perlu didampingi, lalu memberi komentar langsung pada jurnal siswa.

KATALOG BUKU BERSAMA

Sekitar 1.200 buku Indonesia lengkap dengan cover: novel, sastra klasik, remaja, puisi, kumpulan cerpen, sejarah, biografi, agama, pengembangan diri, sains, dan lainnya. Katalog dipakai bersama oleh semua sekolah dan dirawat oleh para penanggung jawab.

UNTUK SISWA

• Masuk dengan akun Google, atau dengan email dan password.
• Mulai buku cukup dengan mencari judul atau penulis di katalog.
• Bukunya belum ada? Isi datanya sendiri dan tambahkan foto cover. Foto bisa dipotong dan diputar, lalu diperkecil sebelum dikirim. Bukumu ikut diusulkan ke katalog.
• Jelajahi katalog: rekomendasi sekolahmu dan buku yang sedang ramai dibaca teman-temanmu.
• Isi jurnal dalam satu menit: halaman yang dibaca, lama membaca, dan isi bacaan hari ini.
• Tetap bisa menulis tanpa sinyal. Jurnal terkirim sendiri saat online.
• Lihat progres buku dan streak membaca bertambah dari hari ke hari.
• Dapat notifikasi saat penanggung jawab mengomentari jurnalmu.
• Tutup buku yang selesai dengan ulasan singkat.
• Pilih tampilan terang atau gelap.
• Atur foto profil, kelas, dan ekstrakurikuler sendiri.

UNTUK PENANGGUNG JAWAB

• Dashboard sekolah: siswa yang aktif, perlu perhatian, tidak aktif, dan yang belum punya buku, untuk seluruh sekolah atau per ekstrakurikuler.
• Saring siswa menurut kelas, ekstrakurikuler, dan status, lengkap dengan progres bukunya.
• Tambah siswa cukup dengan email, satu per satu atau lewat berkas CSV. Nama dan kelas boleh dilengkapi siswa sendiri.
• Buka jurnal siswa dan tulis komentar.
• Atur label kelas, ekstrakurikuler, hari libur, dan ambang status.
• Rawat katalog bersama: tambah, ubah, hapus, dan pulihkan buku, termasuk cover-nya.
• Tinjau buku usulan siswa, lalu terapkan ke katalog atau tolak.
• Rekomendasikan buku untuk sekolahmu. Buku rekomendasi tampil paling atas saat siswa mencari.
• Setiap perubahan buku tercatat lengkap di riwayatnya.

PRIVASI

• Hanya email yang didaftarkan sekolah yang bisa membuka data sekolah.
• Data tiap sekolah terpisah. Hanya katalog buku yang dipakai bersama.
• Tanpa iklan dan tanpa ID iklan.
• Data sekolah disimpan di pusat data Google di Jakarta.
• Laporkan komentar, jurnal, buku, atau pengguna yang tidak pantas langsung dari aplikasi; penanggung jawab dan pengembang meninjaunya.
• Hapus akun kapan saja dari menu Profil.

Sabu Saku dipakai lewat sekolah. Ingin sekolahmu ikut? Daftar di sabusaku.web.app/daftar-sekolah
```

## Release notes of 1.2.1 (500 characters max)

```text
Ketentuan penggunaan: setiap pengguna membaca dan menyetujuinya sekali sebelum memakai aplikasi. Tombol Laporkan untuk komentar, jurnal, buku, saran buku, dan pengguna yang tidak pantas. Penanggung jawab melihat dan menyelesaikan laporan di menu Sekolah → Laporan. Statistik pemakaian (analytics) dihapus dari aplikasi, jadi data yang dikumpulkan makin sedikit. Perbaikan kecil lainnya.
```

## Release notes of 1.2.0 (500 characters max)

```text
Katalog buku bersama: lebih dari 1.000 buku Indonesia lengkap dengan cover. Siswa cukup mencari judul saat memulai buku, bisa menjelajah rekomendasi sekolah dan buku populer, serta mengusulkan buku baru dengan foto cover. Penanggung jawab mengelola katalog, meninjau usulan siswa, dan memberi rekomendasi. Tampilan terang dan gelap.
```

## Release notes of 1.1.0 (500 characters max)

```text
Masuk lebih mudah: pakai akun Google atau email dan password, tanpa kode sekolah dan NIS. Foto profil, label kelas dan ekstrakurikuler, serta hapus akun dari menu Profil. Penanggung jawab menambah siswa cukup dengan email.
```

## Release notes of the first release, 1.0.0 (500 characters max)

```text
Rilis pertama Sabu Saku: jurnal membaca harian untuk siswa, dashboard dan komentar untuk guru, serta pengelolaan kelas dan akun untuk admin sekolah.
```

## Graphics

`make_assets.py` builds the listing images in `out/` from the screens in
`raw/` (see its docstring to regenerate). The raws are production screens of
SMA Negeri 1 Sukodadi, taken on 16 Oct 2026 with `tool/screenshots.sh`
(phone 1080x2424, tablet 2560x1600 landscape) and copied in with
`python3 -I store/make_assets.py --import`. Only screens without an email
address are used; check any new one before committing it.

| File | Size | Content |
|---|---|---|
| `icon-512.png` | 512x512 | App icon, a copy of `branding/png/playstore-icon-512.png` |
| `feature-graphic.png` | 1024x500 | Logo, motto, "Jurnal membaca harian siswa, dengan katalog 1.000+ buku", two phones (jelajahi, beranda) |
| `phone-1.png` | 1080x1920 | Siswa: beranda with a new teacher comment |
| `phone-2.png` | 1080x1920 | Siswa: start a book by searching the catalog |
| `phone-3.png` | 1080x1920 | Siswa: jelajahi katalog, popular at school |
| `phone-4.png` | 1080x1920 | Siswa: isi jurnal |
| `phone-5.png` | 1080x1920 | Siswa: journal with the teacher's comment |
| `phone-6.png` | 1080x1920 | Penanggung jawab: dashboard, dark theme |
| `phone-7.png` | 1080x1920 | Penanggung jawab: catalog book detail, recommend |
| `phone-8.png` | 1080x1920 | Penanggung jawab: add students by email |
| `tablet7-1.png` to `tablet7-6.png` | 1920x1200 | Tablet, landscape: siswa beranda, jelajahi, detail buku; dashboard (dark), katalog, komentar jurnal |
| `tablet10-1.png` to `tablet10-6.png` | 2560x1600 | Same six screens at 10-inch size |

All are 24-bit PNG without alpha.

## Other store settings

- Category: Education (Pendidikan)
- Contact email: komunitaskertaskosong9@gmail.com (the developer email of the Play account)
- Website: https://sabusaku.web.app
- Privacy policy: https://sabusaku.web.app/privasi
- Account and data deletion: https://sabusaku.web.app/hapus-data

## App access (Play Console: Konten aplikasi > Detail login)

**OPEN ITEM: no reviewer account exists yet.** Every screen after sign-in
needs an email that a school has registered; the demo school (school code
`demo`, username `2001`) was deleted on 16 Oct 2026. Before submitting 1.2.0:

1. Pick a reviewer email the developer controls (for example a dedicated
   Gmail address) so the verification email can be opened.
2. Register it in a school with the tools in `functions/tools`, in
   production: as a student with `import-students.ts` (CSV
   `email,nama,kelas,ekskul`) and, to let the reviewer see the penanggung
   jawab area too, a second email with `add-guru.ts`.
3. Open the app, tap "Daftar", sign up with that email and a password, and
   verify the email.
4. Put the email(s) and password(s) in Play Console only (not in git), with
   the instructions below.

Play Console asks for the instructions in English, for example:

```text
Sign in with the email and password given above (no school code). On first sign-in the app shows the terms of use: tap "Saya setuju". The student account opens the student area: start a book from the catalog, write today's journal, explore the catalog. The penanggung jawab account opens the teacher area: dashboard, students, catalog, school. Both accounts were registered by a school; accounts whose email is not registered see "Harap Menghubungi Administrator Sekolah". Reporting: the "Laporkan" menu is on comments, journals, books, suggestions and users; teachers review reports in Sekolah > Laporan. No payment, subscription or 2-step verification is needed.
```

## App content declarations

| Declaration | Answer |
|---|---|
| Privacy policy | https://sabusaku.web.app/privasi |
| Ads | No ads |
| Advertising ID | Not used (the `AD_ID` permission is removed in the manifest) |
| Government app | No |
| Financial features | None |
| Health features | None |
| Target audience | 13-15, 16-17 and 18+. Not designed for children under 13 |
| Content rating (IARC) | Everyone / 3+ with "Users interact". See the answers below |
| AI-generated assets | Not labelled: the graphics are real app screens in a layout |

### Content rating questionnaire

Category: all other app types. Contact email: the developer email.

| Question | Answer |
|---|---|
| Rating-relevant content (sex, violence, language) in the app package | No |
| Users can interact or exchange content | Yes (a penanggung jawab/teacher comments on a student's journal) |
| Shared user content is the main content | No (a journal is the student's own record) |
| Public sharing of nudity or real-life graphic violence | No |
| Block users, report users, chat moderation | Report: yes, since 1.2.1 (the "Laporkan" menu on comments, journals, books, suggestions and users; the school's penanggung jawab and the developer review reports). Block: no |
| Interaction limited to invited people | Yes (only the penanggung jawab of the student's school; since 16 Oct 2026 every penanggung jawab of the school, not only the class teacher) |
| Online content from outside the app | No |
| Promotes age-restricted products | No |
| Shares precise location, digital purchases, cash rewards, web browser | No |
| Primarily an educational or news product | Yes |

Submit a new questionnaire when a feature changes one of these answers. The v2 changes (16 Oct 2026) keep every answer the same.

### Data safety

- Collects data: yes. Shares data with third parties: no.
- Encrypted in transit: yes.
- Account creation: yes, in the app. Users sign in with Google or create an
  email + password account (email verified). Data access requires the email to
  be registered by the school.
- In-app account deletion: Profil → Hapus akun.
- Account deletion and data deletion URL: https://sabusaku.web.app/hapus-data

Every data type below is collected, not shared, and not processed
ephemerally. All are required except **Photos, which is optional**: a
profile photo and a cover photo are never needed to use the app. Since
1.2.1 the app has no Firebase Analytics: nothing is collected as App
interactions, and no location of any kind. Users can
ask for any of it to be deleted (account deletion removes the profile photo
and the student's own cover photos; see hapus-data). Book data and covers a
penanggung jawab accepted into the shared catalog stay in the catalog, and
the catalog history keeps the name of the teacher who made each change.

| Data type | Why it is collected | Source in the app |
|---|---|---|
| Name | App functionality, account management | Profile; entered by the school or the user, or taken from the Google account |
| Email address | App functionality, account management | Sign-in (Google or email/password), school membership list |
| Photos (optional) | App functionality | Optional photos uploaded to Firebase Storage: the profile photo (picked by the user or the Google account photo), a student's cover photo for a book entered by hand (camera or gallery), and book covers a penanggung jawab sets in the catalog. Cropped, rotated and compressed on the device |
| User IDs | App functionality, account management | Firebase Auth UID (no NIS or username since 16 Oct 2026) |
| Other info | App functionality | Class and extracurricular labels, role and school, stored with the profile |
| Other in-app messages | App functionality | Teacher comments on a student's journal |
| Other user-generated content | App functionality; fraud prevention, security, and compliance (reports) | Journals, book reviews, books a student suggests for the catalog, catalog edits (the change history names the editor), reports filed with "Laporkan" (reporter name, reason, note, a copy of the reported content) |
| Crash logs | Analytics | Firebase Crashlytics |
| Diagnostics | Analytics | Firebase Crashlytics only (device model, OS version, device state at the crash) |
| Device or other IDs | App functionality, analytics | FCM token (comment notifications), Firebase installation ID (FCM and Crashlytics) |

The terms acceptance (`termsVersion`, `termsAcceptedAt`) is part of the
account record and needs no data type of its own.

Update this table and the Data safety form together whenever an SDK or a
stored field changes.

## Release checklist (1.2.1)

- [ ] Upload the AAB of 1.2.1+4 and paste the 1.2.1 release notes above.
- [ ] Store listing: paste the new full description (PRIVASI: Jakarta
      wording and the reporting bullet).
- [ ] Data safety: re-check the form against the table above (removed: App
      interactions; Diagnostics from Crashlytics only; new: reports under
      Other user-generated content, teacher comments under Other in-app
      messages, labels under Other info).
- [ ] Content rating: retake the questionnaire, users can now report
      content and users.
- [ ] App access: the reviewer instructions mention the terms screen
      ("Saya setuju") and Sekolah > Laporan.
- [ ] Deploy hosting so https://sabusaku.web.app/ketentuan is live before
      the app that links to it is reviewed.

## Release checklist (1.2.0)

- [ ] Upload the AAB of 1.2.0+3 (`pubspec.yaml` version) to the track and
      paste the 1.2.0 release notes above.
- [ ] Store listing: paste the new short and full description.
- [ ] Store listing: replace the graphics with the files in `out/` (icon,
      feature graphic, 8 phone, 6 seven-inch tablet and 6 ten-inch tablet
      screenshots) and delete the v1 screenshots.
- [ ] Data safety: re-check the form against the table above (new: book
      cover photos under Photos; book suggestions and catalog edits under
      Other user-generated content).
- [ ] App access: create the reviewer account(s) and fill in Detail login
      (open item above).
- [ ] Content rating: decide whether "Interaction limited to invited
      people" still holds. Catalog edits by a penanggung jawab, and a
      student's suggested book or cover once a penanggung jawab applies it,
      are seen by users of other schools. Submit a new questionnaire if the
      answer changes.

## Release checklist (1.1.0, 16 Oct 2026)

- Play App Signing SHA-1 and SHA-256 are registered in the Firebase Android
  app (added 16 Oct 2026), next to the debug and upload keys. Google sign-in
  works in builds installed from Google Play only because of these.
- Re-check the Data safety form in Play Console against the table above
  (new: Email address, Photos; User IDs no longer NIS; account creation in app;
  in-app deletion).
- Update App access with a reviewer account (see above).
- Paste the new full description and the 1.1.0 release notes.
- The store screenshots still show v1 screens; retake them when convenient
  (done for 1.2.0).

## Testing track

Closed testing (Alpha) targets Indonesia. On a personal developer account
Google Play requires a closed test with at least 12 testers for 14 days
before it opens production access.
