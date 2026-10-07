# Sabu Saku

**Satu Bulan Satu Buku**: aplikasi Android jurnal membaca untuk siswa SMA. Siswa membaca satu buku per bulan dan mencatat bacaannya setiap hari; guru memantau kelasnya dan memberi komentar; admin sekolah mengelola kelas dan akun. Satu aplikasi melayani banyak sekolah.

Flutter untuk aplikasi, Firebase (project `sabusaku`, wilayah `asia-southeast2`) untuk seluruh backend. Spesifikasi lengkap ada di [`docs/`](docs/); keputusan yang menyimpang dari rancangan awal dicatat di [`docs/07`](docs/07-keputusan-dan-asumsi.md) bagian 0.

## Struktur

```
lib/
  app/            router (satu redirect untuk login, ganti password wajib, peran) dan tema
  core/           model, waktu WIB, galat, widget dan repository bersama
  features/
    auth/         login kode sekolah + username/NIS, sesi dari custom claims
    student/      beranda, buku, jurnal (dengan outbox offline), profil
    teacher/      dashboard, daftar dan detail siswa, komentar
    admin/        kelas, pengguna, impor CSV, pengaturan sekolah
    notifications/ FCM: token perangkat, notifikasi komentar, deep link
functions/
  src/domain/     aturan streak dan status (fungsi murni)
  src/callables/  createUsers, resetPassword, setUserActive, setTeacherClasses,
                  moveStudentClass, eraseStudent
  src/triggers/   hitung ulang progres dan ringkasan siswa, notifikasi komentar
  src/scheduled/  dailyRefresh (00:10 WIB)
  tools/          skrip developer (lihat di bawah)
  test/           domain (unit), rules, integration (emulator)
firestore.rules   aturan keamanan; setiap kasus di docs/03 §6 diuji otomatis
integration_test/ alur ujung ke ujung di perangkat Android
hosting/          situs sabusaku.web.app: kebijakan privasi dan cara hapus data
store/            teks dan grafik listing Google Play
```

## Prasyarat

Flutter 3.47+, Node 22+, JDK 21 (untuk emulator Firestore), Firebase CLI 15+, dan emulator atau perangkat Android.

```sh
flutter pub get
(cd functions && npm ci)
```

Model dan provider memakai generator. Setelah mengubah berkas beranotasi `@freezed` atau `@riverpod`:

```sh
dart run build_runner build
```

## Menjalankan secara lokal

Pengembangan memakai Firebase Emulator Suite, bukan produksi.

```sh
(cd functions && npm run emulators)                        # terminal 1
(cd functions && npx tsx tools/seed-demo.ts --emulator)    # sekolah contoh
flutter run --dart-define=USE_EMULATORS=true               # terminal 2
```

Login dengan kode sekolah `demo`; akun dan password ada di `secret/demo-credentials.csv`. Tanpa `USE_EMULATORS`, aplikasi terhubung ke produksi.

## Pengujian

| Perintah | Cakupan |
|---|---|
| `flutter analyze && flutter test` | Unit dan widget Flutter |
| `(cd functions && npm test)` | Aturan streak, status, tanggal WIB |
| `(cd functions && npm run test:all)` | Security rules, lalu callable dan trigger, di emulator |
| `tool/e2e.sh` | Alur admin → siswa → guru di perangkat Android melawan emulator |
| `tool/smoke-prod.sh` | Tiga peran login ke **produksi** (sekolah demo), hanya membaca |

CI (GitHub Actions) menjalankan tiga baris pertama pada setiap push.

## Skrip developer

Dijalankan dari `functions/`. Tanpa `--emulator`, skrip bekerja di **produksi** memakai service account di `secret/`.

| Skrip | Fungsi |
|---|---|
| `npx tsx tools/create-school.ts --code sman1 --name "SMA Negeri 1 …"` | Mendaftarkan sekolah dan admin pertamanya; password awal tampil sekali |
| `npx tsx tools/set-school-status.ts --code sman1 --status suspended` | Menangguhkan atau mengaktifkan sekolah |
| `npx tsx tools/seed-demo.ts [--code demo]` | Sekolah demo: 2 kelas, 2 guru, 10 siswa, jurnal beberapa minggu |
| `npx tsx tools/export-school.ts --code sman1` | Ekspor seluruh data sekolah ke `secret/exports/` |
| `npx tsx tools/delete-school.ts --code demo --confirm demo` | Menghapus sekolah beserta semua akunnya. Tidak bisa dibatalkan |

## Deploy

```sh
firebase deploy --only firestore,functions --project sabusaku
firebase deploy --only hosting --project sabusaku            # halaman privasi dan hapus data
```

## Rilis Android

```sh
flutter build appbundle --release
```

Build release ditandatangani dengan upload keystore bila `secret/key.properties` ada. Folder `secret/` (service account, keystore, kredensial demo) tidak masuk git: simpan cadangannya sendiri.

Teks listing dan isian Play Console tercatat di `store/listing.md`. Grafik listing dibuat ulang dengan:

```sh
tool/store-screenshots.sh phone      # layar asli dari sekolah demo di produksi
tool/store-screenshots.sh tablet
python3 store/make_assets.py         # hasil di store/out/
```

App Check sudah terpasang tetapi **belum diaktifkan**. Sebelum Play Integrity tertaut, permintaan token gagal lambat dan menunda login pertama sekitar 20 detik. Setelah AAB pertama diunggah ke Google Play: tautkan Play Integrity ke project, daftarkan SHA-256 Play App Signing di Firebase, build dengan `--dart-define=APP_CHECK=true`, lalu nyalakan enforcement di Firebase Console.
