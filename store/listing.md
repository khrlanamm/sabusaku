# Play Store listing (default language: Indonesian)

The text below is what is saved in Play Console for the default store
listing. Edit it here first, then paste it into Play Console.

## App name (30 characters max)

Sabu Saku: Jurnal Membaca

## Short description (80 characters max)

Satu bulan satu buku. Jurnal membaca harian siswa SMA yang dipantau guru.

## Full description (4000 characters max)

```text
Sabu Saku (Satu Bulan Satu Buku) adalah jurnal membaca untuk sekolah. Siswa membaca satu buku setiap bulan dan mencatat bacaannya setiap hari. Penanggung jawab di sekolah, seperti guru atau pembina ekstrakurikuler, melihat siapa yang rajin dan siapa yang perlu didampingi, lalu memberi komentar langsung pada jurnal siswa.

UNTUK SISWA

• Masuk dengan akun Google, atau dengan email dan password.
• Pilih buku sendiri. Satu buku aktif, dengan target selesai di akhir bulan.
• Isi jurnal dalam satu menit: halaman yang dibaca, lama membaca, dan isi bacaan hari ini.
• Lihat progres buku dan streak membaca bertambah dari hari ke hari.
• Dapat notifikasi saat penanggung jawab mengomentari jurnalmu.
• Tetap bisa menulis tanpa sinyal. Jurnal terkirim sendiri saat online.
• Atur foto profil, kelas, dan ekstrakurikuler sendiri.

UNTUK PENANGGUNG JAWAB

• Dashboard sekolah: siswa yang aktif, perlu perhatian, tidak aktif, dan yang belum punya buku.
• Saring siswa menurut kelas, ekstrakurikuler, dan status, lengkap dengan progres bukunya.
• Tambah siswa cukup dengan email. Nama dan kelas boleh dilengkapi siswa sendiri.
• Buka jurnal siswa dan tulis komentar.
• Atur label kelas, ekstrakurikuler, hari libur, dan ambang status.

PRIVASI

• Hanya email yang didaftarkan sekolah yang bisa membuka data sekolah.
• Data tiap sekolah terpisah. Tanpa iklan dan tanpa ID iklan.
• Data disimpan di pusat data Jakarta.
• Hapus akun kapan saja dari menu Profil.

Sabu Saku dipakai lewat sekolah. Ingin sekolahmu ikut? Daftar di sabusaku.web.app/daftar-sekolah
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

Raw screens in `raw/` came from v1.0.0 with the demo school (its capture
script, `tool/store-screenshots.sh`, was removed with the demo school on
16 Oct 2026). They still show the v1 admin role and school-code login. Retake
them from a real school account before the next listing update. `make_assets.py` builds the listing images in `out/`:

- `icon-512.png` (512x512)
- `feature-graphic.png` (1024x500)
- `phone-1.png` to `phone-8.png` (1080x1920)
- `tablet7-1.png` to `tablet7-6.png` (1080x1920)
- `tablet10-1.png` to `tablet10-6.png` (1440x2560)

## Other store settings

- Category: Education (Pendidikan)
- Contact email: komunitaskertaskosong9@gmail.com (the developer email of the Play account)
- Website: https://sabusaku.web.app
- Privacy policy: https://sabusaku.web.app/privasi
- Account and data deletion: https://sabusaku.web.app/hapus-data

## App access (Play Console: Konten aplikasi > Detail login)

**Needs an update before the next review.** The v1 instructions used the demo
school (school code `demo`, username `2001`), which was deleted on 16 Oct 2026.
Reviewers now need an email address registered in a school's `members` list,
with a password: register a reviewer email (as student and, if wanted, as
penanggung jawab via `add-guru`), sign in once to set the password, then put
those credentials here and in Play Console. Play Console asks for this text in
English, for example:

```text
Sign in with the email and password given above (no school code). The app opens the student area. The account was registered by the school; accounts whose email is not registered see "Harap Menghubungi Administrator Sekolah". No payment, subscription or 2-step verification is needed.
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
| Block users, report users, chat moderation | No |
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

Every data type below is collected, not shared, not processed ephemerally,
and required (users cannot turn it off).

| Data type | Why it is collected | Source in the app |
|---|---|---|
| Name | App functionality, account management | Profile; entered by the school or the user, or taken from the Google account |
| Email address | App functionality, account management | Sign-in (Google or email/password), school membership list |
| Photos | App functionality | Profile photo, optional (picked by the user or the Google account photo) |
| User IDs | App functionality, account management | Firebase Auth UID (no NIS or username since 16 Oct 2026) |
| Other user-generated content | App functionality | Journals, book reviews, teacher comments |
| App interactions | Analytics | Firebase Analytics |
| Crash logs | Analytics | Firebase Crashlytics |
| Diagnostics | Analytics | Firebase Crashlytics and Analytics |
| Device or other IDs | App functionality, analytics | FCM token, Firebase installation ID |

Class and extracurricular labels are stored with the profile; they fall under
"Other info" only if Play Console asks, and are not shared.

Update this table and the Data safety form together whenever an SDK or a
stored field changes.

## Release checklist (1.1.0, 16 Oct 2026)

- Play App Signing SHA-1 and SHA-256 are registered in the Firebase Android
  app (added 16 Oct 2026), next to the debug and upload keys. Google sign-in
  works in builds installed from Google Play only because of these.
- Re-check the Data safety form in Play Console against the table above
  (new: Email address, Photos; User IDs no longer NIS; account creation in app;
  in-app deletion).
- Update App access with a reviewer account (see above).
- Paste the new full description and the 1.1.0 release notes.
- The store screenshots still show v1 screens; retake them when convenient.

## Testing track

Closed testing (Alpha) targets Indonesia. On a personal developer account
Google Play requires a closed test with at least 12 testers for 14 days
before it opens production access.
