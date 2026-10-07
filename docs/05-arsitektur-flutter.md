# 05 — Arsitektur Aplikasi Flutter

Satu aplikasi Android, tiga "shell" menurut peran (siswa, guru, admin). Versi paket tidak dikunci di dokumen ini: gunakan versi stabil terbaru saat proyek dibuat dan kunci lewat `pubspec.lock`.

## 1. Keputusan teknis

| Aspek | Pilihan | Alasan |
|---|---|---|
| State management | **Riverpod** (dengan generator) | Teruji, mudah dites, cocok dengan stream Firestore |
| Navigasi | **go_router** dengan `redirect` berbasis peran | Satu pintu untuk status login, ganti-password-wajib, dan deep link notifikasi |
| Model | **freezed** + **json_serializable** | Immutable, `copyWith`, serialisasi aman |
| Data | Firestore (cache offline aktif), Auth, Functions, Messaging, App Check, Crashlytics, Remote Config | BaaS penuh sesuai keputusan |
| Arsitektur | **Feature-first + lapisan** (presentation / domain / data) | Fitur terisolasi, mudah dikerjakan bertahap |
| Waktu | Utilitas WIB tunggal (`WibClock`) | Satu-satunya tempat mengubah "sekarang" menjadi tanggal `yyyy-MM-dd` |
| Font | Poppins (di-bundle sebagai aset, tidak diunduh saat runtime) | Konsisten dengan logo dan tahan offline |
| Lint | `flutter_lints` (atau `very_good_analysis`) | Disiplin gaya |
| Flavor | `dev` dan `prod` (proyek Firebase berbeda) | Aman dari mencampur data |

**Paket utama:** `flutter_riverpod`, `riverpod_annotation`, `go_router`, `freezed_annotation`, `json_annotation`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging`, `firebase_app_check`, `firebase_crashlytics`, `firebase_remote_config`, `flutter_local_notifications`, `intl`, `shared_preferences`, `csv`, `file_picker`, `share_plus`, `connectivity_plus`. Dev: `build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `mocktail`, `fake_cloud_firestore` (opsional), `flutter_launcher_icons`, `flutter_native_splash`.

## 2. Struktur folder

```
lib/
  main_dev.dart  main_prod.dart  bootstrap.dart
  app/
    app.dart                    # MaterialApp.router, tema, locale id_ID
    router/                     # app_router.dart, route_names.dart, guards
    theme/                      # colors.dart, typography.dart, theme.dart (token dari palet logo)
  core/
    firebase/                   # providers: auth, firestore, functions, messaging
    time/                       # wib_clock.dart, date_format.dart
    errors/                     # app_exception.dart, pemetaan pesan galat Indonesia
    widgets/                    # tombol, kartu, empty state, skeleton, progress, sampul buku otomatis
    utils/                      # validators, debouncer, csv_parser
  features/
    auth/
      data/ domain/ presentation/   # login, ganti password wajib, sesi & claims
    student/
      home/  book/  journal/  history/  profile/
    teacher/
      dashboard/  students/  student_detail/  journal_detail/  recap/
    admin/
      home/  classes/  users/  import_csv/  settings/
    notifications/              # FCM, channel, deep link
  l10n/                         # string Indonesia (ARB) bila dipakai
test/                           # unit + widget
integration_test/               # alur utama dengan emulator
```

Aturan lapisan di tiap fitur:
- **presentation:** widget + controller Riverpod (tanpa akses Firebase langsung).
- **domain:** model dan aturan murni (mis. `JournalForm.validate`, `ProgressCalculator`) — dites unit tanpa Firebase.
- **data:** repository yang membungkus Firestore/Functions; mengembalikan model domain. Repository diberi antarmuka agar bisa diganti di tes.

## 3. Sesi, peran, dan navigasi

```
AuthState: unauthenticated | loading | authenticated(user, role, schoolId, mustChangePassword)

redirect:
  belum login                    → /login
  mustChangePassword             → /ganti-password
  role == siswa                  → /siswa/...   (StudentShell, 4 tab)
  role == guru                   → /guru/...    (TeacherShell, 3 tab)
  role == admin                  → /admin/...   (AdminShell, 4 tab)
  akses lintas peran             → kembali ke beranda perannya
```
- Peran dibaca dari **custom claim** (sumber utama), profil dari `schools/{schoolId}/users/{uid}`.
- Deep link dari notifikasi: `/siswa/jurnal/:programId/:date`.
- `StatefulShellRoute` menjaga state tiap tab.

## 4. Pola data per layar

| Layar | Sumber data | Pola |
|---|---|---|
| Beranda siswa | `studentStats/{uid}` (stream) | 1 dokumen berisi buku aktif, progres, streak, jumlah jurnal bulan ini |
| Buku Saya | `activePrograms/{uid}` → `programs/{id}` | Stream; form Mulai Buku menulis program + kunci aktif dalam satu `WriteBatch` |
| Isi Jurnal | program aktif + (opsional) jurnal tanggal terpilih | `pageStart` default = `currentPage + 1`; tanggal 3 pilihan (hari ini, kemarin, 2 hari lalu); jurnal tanggal itu sudah ada → mode ubah |
| Riwayat | `journals orderBy date desc limit 20` | Paginasi dengan `startAfter` |
| Dashboard guru | `studentStats where classId == X` per kelas, paralel | Hitung kartu di klien dari daftar (≤ beberapa ratus dokumen) |
| Detail siswa (guru) | `studentStats/{id}`, `programs where studentId & classId`, `journals` | Baca saja |
| Admin › Pengguna | `users where role == X orderBy name` | Aksi lewat callable |

**Offline:** persistensi Firestore aktif (bawaan Android) dengan batas cache yang ditentukan. Tulis jurnal memakai penulisan standar (masuk antrean saat offline). Tampilkan penanda "menunggu sinkron" memakai `metadata.hasPendingWrites` dan tangani kegagalan sinkron (lihat dokumen 03).

**Validasi ganda:** aturan form di domain klien mencerminkan rules (BR-3, 4, 5, 7) agar pengguna mendapat pesan jelas sebelum server menolak.

## 5. Desain sistem

**Token** (dari logo): `navy #17365D`, `navyDeep #0F2747`, `blue #2563EB`, `blueDark #1D4FC4`, `sky #E4EEFF`, `green #2FA866`, `greenLight #5CD08A`, `amber #F5B942` (streak/peringatan). Status siswa: hijau (aktif), kuning/amber (perlu perhatian), merah (tidak aktif), abu-abu (belum ada buku) — selalu disertai ikon/teks, bukan warna saja.

**Komponen bersama:** `BookCover` (sampul otomatis dari judul), `ProgressBar`, `StatusChip`, `StatCard`, `StreakBadge`, `EmptyState`, `ErrorState` (dengan tombol coba lagi), `SkeletonList`, `ConfirmDialog`.

**Aksesibilitas:** target sentuh ≥ 48dp, kontras AA, label semantik untuk pembaca layar, hormati ukuran font sistem. Mode gelap: ditunda (Could).

## 6. Notifikasi (FCM)
- Minta izin notifikasi (Android 13+) setelah login siswa, dengan penjelasan singkat sebelum dialog sistem.
- Simpan token ke `users/{uid}/devices/{hash}`; perbarui saat token berganti; hapus saat logout.
- Channel Android `komentar_guru`. Pesan latar belakang membuka layar detail jurnal lewat deep link.

## 7. Penanganan galat
Satu `AppException` dengan kode; pemetaan ke pesan Indonesia yang ramah (tidak ada sinyal, sesi berakhir, akses ditolak, jurnal sudah ada, di luar batas tanggal). Semua galat tak terduga ke Crashlytics tanpa data personal. Setiap layar punya keadaan `loading`, `empty`, `error`.

## 8. Pengujian
| Tingkat | Cakupan |
|---|---|
| Unit | Validasi jurnal/buku, progres, `WibClock` (termasuk 23:59/00:01), parser CSV impor, redirect router |
| Widget | Form jurnal (validasi), kartu beranda, daftar siswa dengan filter, login |
| Integrasi | Alur dengan Firebase Emulator: login → mulai buku → jurnal → komentar |
| Rules & Functions | Lihat dokumen 03 dan 04 (di CI) |
| Manual | Perangkat Android kelas bawah, mode pesawat (offline), font besar, rotasi layar |

## 9. Penyiapan awal (checklist M0)
1. Dua proyek Firebase (`sabusaku-dev`, `sabusaku-prod`), paket Blaze, Firestore `asia-southeast2`.
2. `flutterfire configure` per flavor; `applicationId` Android (usulan: `id.sabusaku.app`, dengan sufiks `.dev` untuk dev) — **konfirmasi**.
3. `firebase init` (Firestore, Functions, Emulators, App Check).
4. Aktifkan Crashlytics, App Check (debug dulu), password policy Auth.
5. Pasang ikon dan splash dari folder `branding/` (lihat `branding/README.md`).
6. CI: `flutter analyze`, `flutter test`, tes rules, tes functions.
