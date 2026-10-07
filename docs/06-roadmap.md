# 06 — Roadmap Pengembangan

Urutan disusun agar **setiap milestone menghasilkan sesuatu yang bisa dijalankan dan diuji**, dan risiko terbesar (rules, multi-sekolah, offline, perhitungan streak) ditangani lebih awal. Estimasi untuk **satu developer penuh waktu** dan hanya perkiraan kasar (±40%); perbarui setelah M0–M1 selesai.

| M | Nama | Estimasi | Hasil yang bisa didemokan |
|---|---|---|---|
| M0 | Fondasi | 3–5 hari | Proyek Flutter + Firebase (dev/prod), emulator, CI, tema dan komponen dasar, ikon + splash terpasang, skrip `create-school` |
| M1 | Autentikasi & multi-sekolah | 5–7 hari | Login kode sekolah + username, claims, routing per peran, wajib ganti password, rules dasar + tes |
| M2 | Admin: kelas & pengguna | 6–8 hari | Kelas, impor CSV guru/siswa, penugasan guru, nonaktif, reset password, ekspor kredensial |
| M3 | Siswa: buku & jurnal | 8–10 hari | Mulai buku, isi jurnal (aturan BR-1…7), riwayat, edit/hapus H+1, offline, Beranda |
| M4 | Perhitungan server | 4–6 hari | `onJournalWritten`, `studentStats`, streak/status, `dailyRefresh`, tes unit domain lengkap |
| M5 | Guru | 7–9 hari | Dashboard, daftar siswa (filter), detail siswa, detail jurnal, komentar |
| M6 | Notifikasi, Profil, penyempurnaan | 5–7 hari | FCM komentar, Profil siswa (statistik + riwayat buku), ulasan akhir, perpanjang target, Rekap (opsional) |
| M7 | Pengerasan & rilis | 7–10 hari | Tes rules lengkap, App Check enforcement, Crashlytics, uji perangkat, penghapusan data, dokumen privasi, uji coba tertutup di sekolah |

Total sekitar **7–10 minggu** hingga rilis uji coba. Fitur Could dan semua daftar "belum ada" di luar jadwal ini.

## Rincian dan kriteria selesai

### M0 — Fondasi
- Buat dua proyek Firebase, aktifkan Blaze, Firestore Jakarta, Auth Email/Password.
- Flutter: flavor dev/prod, struktur folder (dokumen 05), tema dari palet logo, font Poppins, router kosong per peran.
- `firebase.json` dengan emulator (Auth, Firestore, Functions), CI GitHub Actions.
- `flutter_launcher_icons` + `flutter_native_splash` dari `branding/`.
- **Selesai bila:** aplikasi kosong berjalan di Android dengan ikon dan splash baru, terhubung ke emulator, CI hijau.

### M1 — Autentikasi & multi-sekolah
- Callable `createUsers` versi awal (hanya admin pertama lewat skrip), `create-school`.
- Layar login, penyimpanan kode sekolah, pemetaan galat, ganti password wajib, keluar.
- Guard router berdasarkan claim, shell kosong 3 peran.
- `firestore.rules` bagian `schools`, `users`, isolasi sekolah + tes #1, #4, #18.
- **Selesai bila:** admin hasil `create-school` login, dipaksa ganti password, dan masuk shell admin; pengguna sekolah lain tidak bisa membaca data sekolah ini.

### M2 — Admin
- CRUD kelas (arsip, bukan hapus), pengaturan sekolah (libur, hari netral, ambang).
- Impor CSV: templat dapat diunduh, pratinjau + validasi per baris (galat per baris yang jelas), kirim per batch, hasil + ekspor kredensial lewat share sheet.
- Tugaskan guru ke kelas (`setTeacherClasses`), pindah kelas, nonaktif/aktif, reset password.
- **Selesai bila:** admin dapat menyiapkan satu sekolah demo (2 kelas, 2 guru, 30 siswa) hanya lewat aplikasi.

### M3 — Siswa
- Mulai buku (batch program + kunci aktif), sampul otomatis, Buku Saya.
- Form jurnal: tanggal 3 pilihan, halaman otomatis lanjut, durasi, teks, validasi sinkron dengan rules; mode ubah; hapus.
- Riwayat berpaginasi, Detail Jurnal, Beranda (sementara menghitung dari data lokal sampai M4).
- Rules `programs`, `journals`, `activePrograms` + tes #5–#15.
- Offline: tulis jurnal tanpa sinyal, penanda menunggu sinkron, penanganan penolakan.
- **Selesai bila:** siswa dapat membaca satu bulan penuh secara simulasi; jurnal kedua pada hari yang sama ditolak server; mode pesawat berfungsi.

### M4 — Perhitungan server
- Modul `domain/` (streak, status, tanggal WIB) dengan tabel uji lengkap.
- Trigger jurnal/program/pengguna, `refreshStudentStats`, `dailyRefresh` (jadwal 00:10 WIB).
- Beranda siswa memakai `studentStats`.
- **Selesai bila:** semua kasus uji domain lulus; mengubah jam skenario (emulator) menghasilkan status yang benar; streak melewati Minggu dan libur.

### M5 — Guru
- Dashboard (kartu + daftar perlu perhatian), Daftar Siswa (filter kelas/status, pencarian), Detail Siswa, Detail Jurnal, komentar (buat/ubah/hapus).
- Rules `studentStats`, `comments` + tes #2, #16, #17.
- **Selesai bila:** guru dengan 2 kelas melihat gabungan siswa; tidak ada data kelas lain yang bocor (tes otomatis).

### M6 — Notifikasi, Profil, penyempurnaan
- Penyimpanan token, `onCommentCreated`, deep link, badge komentar baru di Beranda/Riwayat.
- Profil siswa: statistik, riwayat buku, ubah password. Ulasan akhir + selesai/hentikan/perpanjang.
- Rekap bulanan per kelas + ekspor CSV *(jika waktu)*.

### M7 — Pengerasan & rilis
- Seluruh tes rules (dokumen 03 §6) di CI; uji beban ringan data seed (mis. 5 sekolah × 400 siswa).
- App Check enforcement (setelah memutuskan jalur distribusi), backup terjadwal, alarm.
- `eraseStudent`, kebijakan privasi, formulir *Data safety*, aset toko (ikon 512, grafik fitur, tangkapan layar).
- Uji coba tertutup 1 sekolah selama 2–4 minggu; kumpulkan umpan balik; perbaiki.
- **Selesai bila:** semua kriteria sukses PRD §8 terpenuhi di perangkat nyata.

## Risiko utama dan mitigasinya

| Risiko | Mitigasi |
|---|---|
| Rules salah sehingga data bocor/tertolak | Tes rules otomatis sejak M1; tinjau setiap perubahan rules dengan tes |
| Jurnal offline ditolak diam-diam | Penanganan kegagalan tulis tertunda di M3; uji skenario "tulis Senin, sinkron Kamis" |
| Streak/status salah di tepi hari | Logika murni berbasis string tanggal WIB + tabel uji; satu `WibClock` |
| App Check memblokir APK non-Play | Putuskan jalur distribusi sebelum M7; uji enforcement bertahap (mode *monitor* dulu) |
| Impor CSV berantakan (nama/NIS tak konsisten) | Pratinjau + validasi per baris; templat CSV baku; username kembar dilaporkan jelas |
| Skema berubah setelah ada data | Tambah field bersifat aditif; versi skema `schemaVersion` di dokumen sekolah bila perlu migrasi |
| Kelelahan pengguna (jurnal terlalu panjang) | Hanya satu field wajib; ukur waktu isi di uji coba |

## Setelah V1 (kandidat, urutan usulan)
1. Pengingat harian (FCM terjadwal, dapat dimatikan siswa).
2. Rekap dan ekspor PDF untuk wali kelas.
3. Mode gelap.
4. Katalog buku sekolah + pencarian (Google Books) dan upload sampul.
5. Rekomendasi buku, gamifikasi ringan — hanya bila data uji coba mendukung.
