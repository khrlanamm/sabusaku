# Play Store listing (default language: Indonesian)

The text below is what is saved in Play Console for the default store
listing. Edit it here first, then paste it into Play Console.

## App name (30 characters max)

Sabu Saku: Jurnal Membaca

## Short description (80 characters max)

Satu bulan satu buku. Jurnal membaca harian siswa SMA yang dipantau guru.

## Full description (4000 characters max)

```text
Sabu Saku (Satu Bulan Satu Buku) adalah jurnal membaca untuk sekolah. Siswa membaca satu buku setiap bulan dan mencatat bacaannya setiap hari. Guru melihat siapa yang rajin dan siapa yang perlu didampingi, lalu memberi komentar langsung pada jurnal siswa.

UNTUK SISWA

• Pilih buku sendiri. Satu buku aktif, dengan target selesai di akhir bulan.
• Isi jurnal dalam satu menit: halaman yang dibaca, lama membaca, dan isi bacaan hari ini.
• Lihat progres buku dan streak membaca bertambah dari hari ke hari.
• Dapat notifikasi saat guru mengomentari jurnalmu.
• Tetap bisa menulis tanpa sinyal. Jurnal terkirim sendiri saat online.
• Riwayat semua buku dan jurnal tersimpan di profil.

UNTUK GURU

• Dashboard kelas: siswa yang aktif, perlu perhatian, tidak aktif, dan yang belum punya buku.
• Daftar siswa dengan filter kelas dan status, lengkap dengan progres bukunya.
• Buka jurnal siswa di kelasmu dan tulis komentar.
• Satu guru bisa memantau banyak kelas.
• Reset password siswa langsung dari aplikasi.

UNTUK SEKOLAH

• Admin membuat kelas, lalu menambah guru dan siswa satu per satu atau impor dari CSV.
• Atur hari libur dan ambang status supaya keaktifan siswa dihitung adil.
• Data tiap sekolah terpisah. Guru hanya melihat kelasnya sendiri, dan admin tidak bisa membaca isi jurnal siswa.

PRIVASI

• Akun dibuat oleh sekolah. Siswa masuk dengan kode sekolah, NIS, dan password.
• Tanpa iklan dan tanpa ID iklan.
• Data disimpan di pusat data Jakarta.
• Sekolah dapat menghapus akun dan seluruh data siswa kapan saja.

Sabu Saku dipakai lewat sekolah. Ingin sekolahmu ikut? Hubungi komunitaskertaskosong9@gmail.com
```

## Release notes of the first release (500 characters max)

```text
Rilis pertama Sabu Saku: jurnal membaca harian untuk siswa, dashboard dan komentar untuk guru, serta pengelolaan kelas dan akun untuk admin sekolah.
```

## Graphics

Raw screens come from `tool/store-screenshots.sh phone|tablet` (production,
demo school) into `raw/`. `make_assets.py` builds the listing images in `out/`:

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

The app needs an account created by a school, so reviewers use the demo
school. Play Console asks for this text in English.

- Name: `Demo school accounts (student, teacher, admin)`
- Username: `2001`
- Password: the shared demo password from `secret/demo-credentials.csv`
  (not in git)
- Other information:

```text
The sign-in screen has three fields. School code (Kode Sekolah): demo. Username: 2001 for a student, guru1 for a teacher, admin for the school admin. All three accounts use the password given above. Each role opens a different part of the app, so please try all three. The app has no sign-up: schools create the accounts. No payment, subscription or 2-step verification is needed.
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
| AI-generated assets | Not labelled: the graphics are real app screens in a layout |

### Data safety

- Collects data: yes. Shares data with third parties: no.
- Encrypted in transit: yes.
- Account creation: username and password (accounts are created by the school admin).
- Account deletion and data deletion URL: https://sabusaku.web.app/hapus-data

Every data type below is collected, not shared, not processed ephemerally,
and required (users cannot turn it off).

| Data type | Why it is collected | Source in the app |
|---|---|---|
| Name | App functionality, account management | Profile created by the school |
| User IDs | App functionality, account management | NIS or username |
| Other user-generated content | App functionality | Journals, book reviews, teacher comments |
| App interactions | Analytics | Firebase Analytics |
| Crash logs | Analytics | Firebase Crashlytics |
| Diagnostics | Analytics | Firebase Crashlytics and Analytics |
| Device or other IDs | App functionality, analytics | FCM token, Firebase installation ID |

Update this table and the Data safety form together whenever an SDK or a
stored field changes.
