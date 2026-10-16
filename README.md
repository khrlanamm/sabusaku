# Sabu Saku

**Satu Bulan Satu Buku**: aplikasi Android jurnal membaca untuk siswa SMA. Siswa membaca satu buku per bulan dan mencatat bacaannya setiap hari; penanggung jawab (guru atau pembina ekstrakurikuler) memantau semua siswa sekolahnya, memberi komentar, dan menambah siswa lewat email. Satu aplikasi melayani banyak sekolah; sekolah dan penanggung jawab didaftarkan developer.

## Masuk

Email + password atau **Masuk dengan Google**, tanpa kode sekolah dan NIS. Akun dibuat pengguna sendiri; data sekolah hanya terbuka bila emailnya ada di `members/{email}` (satu email satu sekolah). Callable `claimAccount` memasang claims `{role, schoolId}`. Email tak terdaftar melihat "Harap Menghubungi Administrator Sekolah" dengan tautan ke [sabusaku.web.app/daftar-sekolah](https://sabusaku.web.app/daftar-sekolah). Akun Google tanpa password, atau profil tanpa nama/kelas, diarahkan ke Lengkapi akun. Kelas (`XII-A1`) dan ekstrakurikuler (`Masis-KIR`) adalah label di dokumen sekolah.

Flutter untuk aplikasi, Firebase (project `sabusaku`, wilayah `asia-southeast2`) untuk seluruh backend. Spesifikasi lengkap ada di [`docs/`](docs/); keputusan yang menyimpang dari rancangan awal dicatat di [`docs/07`](docs/07-keputusan-dan-asumsi.md) bagian 0.

## Struktur

```
lib/
  app/            router (satu redirect untuk login, verifikasi email, Lengkapi akun, peran) dan tema
  core/           model, waktu WIB, galat, widget dan repository bersama
  features/
    auth/         login email/Google, daftar + verifikasi, Lengkapi akun, profil, sesi dari claims
    student/      beranda, buku, jurnal (dengan outbox offline), profil
    teacher/      penanggung jawab: dashboard, siswa (tambah, impor, belum masuk), komentar,
                  sekolah (label kelas/ekskul, pengaturan)
    notifications/ FCM: token perangkat, notifikasi komentar, deep link
functions/
  src/domain/     aturan streak dan status (fungsi murni)
  src/callables/  claimAccount, addStudents, removeStudent, eraseStudent, deleteMyAccount
  src/triggers/   hitung ulang progres dan ringkasan siswa, notifikasi komentar
  src/scheduled/  dailyRefresh (00:10 WIB)
  tools/          skrip developer (lihat di bawah)
  test/           domain (unit), rules, integration (emulator)
firestore.rules   aturan keamanan; setiap kasus di docs/03 §6 diuji otomatis
storage.rules     foto profil schools/{s}/avatars/{uid}.jpg
integration_test/ alur ujung ke ujung di perangkat Android
hosting/          situs sabusaku.web.app: penjelasan, daftar sekolah, privasi, hapus data
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

## Menjalankan

Semua berjalan langsung di **produksi** (project `sabusaku`); tidak ada project dev dan tidak ada sekolah demo. `flutter run` terhubung ke produksi. Untuk mencoba, pakai akun penanggung jawab atau siswa yang terdaftar di sekolah nyata.

Firebase Emulator hanya dipakai tes otomatis (`npm run test:all`, `tool/e2e.sh`); `--dart-define=USE_EMULATORS=true` mengarahkan aplikasi ke emulator lokal.

## Pengujian

| Perintah | Cakupan |
|---|---|
| `flutter analyze && flutter test` | Unit dan widget Flutter |
| `(cd functions && npm test)` | Aturan streak, status, tanggal WIB |
| `(cd functions && npm run test:all)` | Security rules, lalu callable dan trigger, di emulator |
| `tool/e2e.sh` | Alur ujung ke ujung di perangkat Android melawan emulator |

CI (GitHub Actions) menjalankan tiga baris pertama pada setiap push.

## Skrip developer

Dijalankan dari `functions/`. Tanpa `--emulator`, skrip bekerja di **produksi** memakai service account di `secret/`. Hanya skrip ini yang bisa menambah sekolah dan penanggung jawab.

| Skrip | Fungsi |
|---|---|
| `npx tsx tools/create-school.ts --code sman1 --name "SMA Negeri 1 …"` | Mendaftarkan sekolah dengan label ekstrakurikuler awal (Masis-KIR, Paskibra, Pala, PMR) |
| `npx tsx tools/add-guru.ts --school sman1 --email … --name "…"` | Mendaftarkan penanggung jawab |
| `npx tsx tools/remove-guru.ts --email …` | Mengeluarkan penanggung jawab |
| `npx tsx tools/import-students.ts --school sman1 --file secret/siswa.csv` | Impor siswa dari CSV `email,nama,kelas,ekskul` (ekskul dipisah `;`). Simpan berkas berisi data siswa di `secret/` |
| `npx tsx tools/set-school-status.ts --code sman1 --status suspended` | Menangguhkan atau mengaktifkan sekolah |
| `npx tsx tools/export-school.ts --code sman1` | Ekspor seluruh data sekolah ke `secret/exports/` |
| `npx tsx tools/delete-school.ts --code sman1 --confirm sman1` | Menghapus sekolah beserta data dan keanggotaannya. Tidak bisa dibatalkan |

## Deploy

```sh
firebase deploy --only firestore,storage,functions --project sabusaku
firebase deploy --only hosting --project sabusaku            # situs, daftar sekolah, privasi, hapus data
```

## Rilis Android

```sh
flutter build appbundle --release
```

Build release ditandatangani dengan upload keystore bila `secret/key.properties` ada. Folder `secret/` (service account, keystore, data siswa untuk impor) tidak masuk git: simpan cadangannya sendiri.

Masuk dengan Google butuh SHA-1 sertifikat penanda tangan di aplikasi Android Firebase. Terdaftar: debug, upload key, dan **Play App Signing** (sejak 16 Oktober 2026). Bila kunci berubah, tambahkan SHA-nya (`firebase apps:android:sha:create`) lalu unduh ulang `android/app/google-services.json`.

Teks listing dan isian Play Console tercatat di `store/listing.md`. Grafik listing dibuat ulang dengan:

```sh
python3 store/make_assets.py         # hasil di store/out/
```

Tangkapan layar di `store/raw/` masih dari v1 (sekolah demo yang sudah dihapus); ambil ulang dari akun sekolah nyata sebelum memperbarui listing.

App Check sudah terpasang tetapi **belum diaktifkan**. Sebelum Play Integrity tertaut, permintaan token gagal lambat dan menunda login pertama sekitar 20 detik. SHA-256 Play App Signing sudah terdaftar di Firebase. Langkah tersisa: tautkan Play Integrity ke project, build dengan `--dart-define=APP_CHECK=true`, lalu nyalakan enforcement di Firebase Console.
