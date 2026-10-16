# 02 — Model Data Firestore

> Diperbarui 16 Oktober 2026 untuk model v2: login email/Google, daftar anggota `members/{email}`, peran `guru`|`siswa`, kelas dan ekstrakurikuler sebagai label, foto profil di Cloud Storage.

Database: Cloud Firestore (mode Native), lokasi **asia-southeast2 (Jakarta)**. Lokasi tidak bisa diubah setelah dibuat, jadi tentukan sejak awal. Semua waktu disimpan sebagai `Timestamp` (UTC); semua **tanggal kalender** disimpan sebagai string `yyyy-MM-dd` dalam WIB.

## 1. Prinsip desain
1. **Isolasi per sekolah lewat path:** semua data sekolah di bawah `schools/{schoolId}`. Rules memeriksa `request.auth.token.schoolId == schoolId`. Satu-satunya koleksi top-level adalah `members/{email}` (daftar anggota); rules mengizinkan penanggung jawab membaca entri yang `schoolId`-nya sama dengan claim.
2. **ID dokumen yang membawa aturan:** jurnal memakai ID tanggal, sehingga "satu jurnal per hari" dijamin database.
3. **Kepemilikan tulis jelas:** data yang diisi pengguna ditulis klien; angka turunan (progres, streak, status) **hanya ditulis Cloud Functions**. Klien tidak bisa memalsukannya (dijaga rules).
4. **Dokumen ringkasan untuk layar padat:** `studentStats` melayani Dashboard guru dan Beranda siswa dengan 1 query.
5. **Hitung ulang, bukan tambah-kurang:** trigger menghitung ulang agregat dari semua jurnal satu buku (maks sekitar 60 dokumen), sehingga idempoten dan tahan terhadap sinkronisasi offline yang datang tidak berurutan.

## 2. Pohon koleksi

```
members/{email}                                 ← daftar anggota, ID = email huruf kecil (1 email = 1 sekolah)
schools/{schoolId}                              ← schoolId = kode sekolah (huruf kecil)
├── users/{uid}                                 ← uid = Firebase Auth UID, dibuat saat klaim
│   └── devices/{tokenHash}                     ← token FCM
├── studentStats/{studentId}                    ← ringkasan (ditulis server)
├── activePrograms/{studentId}                  ← kunci "satu buku aktif per siswa" (BR-1)
└── programs/{programId}                        ← satu buku yang dibaca satu siswa
    └── journals/{yyyy-MM-dd}
        └── comments/{commentId}
```

Cloud Storage: `schools/{schoolId}/avatars/{uid}.jpg` (foto profil, < 1 MB, ditulis pemilik, dibaca anggota sekolah). URL unduhnya disimpan di `users.photoUrl`.

Koleksi `classes` dari v1 dihapus: kelas kini label di dokumen sekolah.

Tidak ada koleksi `books` global di V1: data buku disimpan di dalam `programs` (siswa memilih buku bebas). Katalog/autocomplete dapat ditambahkan nanti tanpa mengubah struktur ini.

## 3. Dokumen

### 3.1 `schools/{schoolId}`
| Field | Tipe | Keterangan |
|---|---|---|
| `name` | string | Nama sekolah |
| `status` | string | `active` · `suspended` (diatur developer) |
| `settings.neutralWeekdays` | int[] | Default `[0]` (Minggu = 0) |
| `settings.holidays` | string[] | Tanggal libur `yyyy-MM-dd` |
| `settings.activeMaxDays` | int | Default 3 |
| `settings.attentionMaxDays` | int | Default 7 |
| `classes` | string[] | Label kelas, format `^(X\|XI\|XII)-[A-Z]{1,2}[0-9]{0,2}$` (mis. `XII-A1`, `X-G2`), maks 200 |
| `extracurriculars` | string[] | Label ekstrakurikuler 2–40 karakter, maks 50. Awal: `Masis-KIR`, `Paskibra`, `Pala`, `PMR` |
| `createdAt` | timestamp | |

Tulis: developer (skrip) dan penanggung jawab (hanya `settings`, `classes`, `extracurriculars`, divalidasi rules). Baca: seluruh anggota sekolah.

Masukan kelas yang diketik bebas (`12  A1`, `XIIC2`, `Xll-A1`, `XD`) dinormalkan ke label baku oleh `normalizeClassLabel` (`lib/core/utils/labels.dart` dan `functions/src/domain/labels.ts`, harus sama).

### 3.1a `members/{email}` — daftar anggota (top-level)
| Field | Tipe | Keterangan |
|---|---|---|
| `email` | string | Sama dengan ID dokumen (huruf kecil, tanpa spasi) |
| `schoolId` | string | Sekolah tempat email ini terdaftar |
| `role` | string | `guru` · `siswa` |
| `name` | string | Boleh kosong; diisi siswa di Lengkapi akun |
| `classId` | string? | Label kelas (siswa) |
| `extracurriculars` | string[] | Label ekstrakurikuler (siswa; untuk guru = yang dibina) |
| `uid` | string? | Terisi saat akun mengklaim keanggotaan |
| `addedBy` | string | UID penanggung jawab, atau `developer` |
| `createdAt`, `updatedAt` | timestamp | |

ID dokumen = email, sehingga satu email otomatis hanya terdaftar di satu sekolah. Dibuat dan dihapus hanya oleh Functions/skrip (`addStudents`, `removeStudent`, `eraseStudent`, `add-guru`). Penanggung jawab boleh membaca entri sekolahnya dan mengubah `name`/`classId`/`extracurriculars` siswa yang belum pernah masuk (`uid == null`). Siswa yang sudah masuk diubah lewat `users/{uid}`.

### 3.2 `schools/{schoolId}/users/{uid}`
| Field | Tipe | Keterangan |
|---|---|---|
| `role` | string | `guru` · `siswa` (tidak bisa diubah klien) |
| `name` | string | Nama lengkap; kosong sampai Lengkapi akun |
| `email` | string | Email akun (huruf kecil) |
| `classId` | string? | Siswa: label kelas, mis. `XII-A1`. Guru: selalu `null` |
| `extracurriculars` | string[] | Label ekstrakurikuler, maks 10, harus ada di daftar sekolah |
| `photoUrl` | string? | Foto profil: URL Cloud Storage atau foto Google. Bila kosong dan akun masuk dengan Google, `claimAccount` mengisinya dengan foto Google; foto yang sudah ada tidak ditimpa |
| `status` | string | `active` · `removed` (dikeluarkan dari sekolah) |
| `createdAt`, `updatedAt` | timestamp | |

Dibuat oleh `claimAccount` saat pengguna pertama kali masuk dengan email yang terdaftar. Pemilik boleh mengubah `name`, `classId`, `extracurriculars`, `photoUrl`; penanggung jawab boleh mengubah `name`, `classId`, `extracurriculars` siswa. `role`, `email`, `status` hanya lewat Functions. Field v1 `username`, `nis`, `classIds`, `mustChangePassword` dihapus.

### 3.3 `schools/{schoolId}/users/{uid}/devices/{tokenHash}`
`token`, `platform` (`android`), `updatedAt`. Ditulis pemilik akun. Dibaca server untuk mengirim FCM; token tidak valid dibersihkan server.

### 3.4 Kelas (dihapus)
Koleksi `classes` v1 tidak dipakai lagi. Kelas adalah label `schools/{schoolId}.classes`; siswa menyimpan labelnya di `users.classId`.

### 3.5 `schools/{schoolId}/programs/{programId}` — satu buku satu siswa
`programId` = ID otomatis.

| Field | Tipe | Ditulis oleh | Keterangan |
|---|---|---|---|
| `studentId` | string | siswa (saat buat) | Tetap |
| `classId` | string | siswa saat buat, lalu server | Label kelas, disalin dari profil siswa; diperbarui server saat siswa ganti kelas (hanya informasi, bukan dasar akses) |
| `book.title` | string | siswa | 2–120 |
| `book.author` | string | siswa | 2–80 |
| `book.totalPages` | int | siswa | 10–2000, tetap setelah dibuat |
| `book.isbn` | string? | siswa | |
| `month` | string | siswa | `yyyy-MM` saat dimulai |
| `startDate` | string | siswa | `yyyy-MM-dd` |
| `targetDate` | string | siswa | Default akhir bulan; dapat diperpanjang sekali (BR-9) |
| `extended` | bool | siswa | |
| `status` | string | siswa | `active` → `completed` / `stopped` |
| `finalReflection` | string? | siswa | Ulasan akhir opsional (maks 1000) |
| `completedAt`, `stoppedAt` | timestamp? | server-assisted | Diisi saat transisi status |
| `currentPage` | int | **server** | Halaman tertinggi dari semua jurnal |
| `journalCount` | int | **server** | |
| `lastJournalDate` | string? | **server** | |
| `streakCurrent`, `streakBest` | int | **server** | |
| `createdAt`, `updatedAt` | timestamp | | |

Saat dibuat, semua field server wajib `0`/`null` (dipaksa rules).

### 3.6 `.../programs/{programId}/journals/{yyyy-MM-dd}`
| Field | Tipe | Keterangan |
|---|---|---|
| `studentId` | string | Harus sama dengan `uid` penulis dan dengan program |
| `date` | string | Harus sama dengan ID dokumen |
| `pageStart`, `pageEnd` | int | BR-5 |
| `durationRange` | string | `lt15` · `15to30` · `30to60` · `gt60` |
| `keyInformation` | string | 30–1000 |
| `reflection` | string? | ≤ 1000 ("Hal yang menarik") |
| `question` | string? | ≤ 1000 ("Pertanyaan") |
| `hasUnreadTeacherComment` | bool | Diisi server `true`; siswa hanya boleh mengubahnya ke `false` |
| `lastCommentAt` | timestamp? | Server |
| `createdAt`, `updatedAt` | timestamp | `createdAt` tidak berubah; `updatedAt` = waktu server |

Rules memeriksa tanggal terhadap waktu server (BR-3, BR-4) dan konsistensi halaman terhadap `totalPages` program.

### 3.7 `.../journals/{date}/comments/{commentId}`
`teacherId`, `teacherName`, `text` (1–1000), `createdAt`, `updatedAt`. Dibuat oleh penanggung jawab sekolah siswa tersebut; penanggung jawab hanya mengubah/menghapus komentarnya sendiri. Dibaca oleh siswa pemilik dan semua penanggung jawab sekolah.

### 3.8 `schools/{schoolId}/studentStats/{studentId}` — ringkasan, ditulis server
| Field | Tipe |
|---|---|
| `studentId`, `name`, `email`, `photoUrl` | |
| `classId` | label kelas |
| `extracurriculars` | string[] |
| `status` | `aktif` · `perlu_perhatian` · `tidak_aktif` · `belum_mulai` |
| `daysSinceLastJournal` | int (hari efektif, BR-13) |
| `activeProgram` | map: `programId`, `title`, `author`, `totalPages`, `currentPage`, `percent`, `targetDate`, `overdue` |
| `streakCurrent`, `streakBest` | int |
| `lastJournalDate` | string? |
| `journalCountMonth` | int (jurnal bulan berjalan) |
| `journalCountTotal` | int |
| `booksCompleted` | int |
| `recentDates` | string[] (5 tanggal jurnal terakhir, untuk "Aktivitas Terakhir") |
| `updatedAt` | timestamp |

Dibaca: siswa pemilik dan semua penanggung jawab sekolah. Dashboard dan daftar siswa = **satu query `studentStats orderBy name`**; filter kelas, ekstrakurikuler, dan status dilakukan di klien.

### 3.9 `schools/{schoolId}/activePrograms/{studentId}`
Dokumen kunci `{ programId }`. Dibuat siswa dalam **batch yang sama** dengan dokumen program baru, dan dihapus dalam batch yang sama saat program selesai/dihentikan. Karena ID = `studentId`, pembuatan kedua otomatis gagal, sehingga BR-1 (satu buku aktif) dijamin database tanpa transaksi server. Sekaligus menjadi cara 1-baca untuk menemukan buku aktif siswa.

## 4. Matriks kepemilikan tulis

| Data | Siswa | Penanggung jawab | Functions / skrip developer |
|---|---|---|---|
| `schools` | — | `settings`, `classes`, `extracurriculars` | buat sekolah, `status` |
| `members` | — | ubah nama/kelas/ekskul siswa yang belum masuk | buat, hapus, `uid` |
| `users` | `name`, `classId`, `extracurriculars`, `photoUrl` miliknya | `name`, `classId`, `extracurriculars` siswa | buat (klaim), `status`, `email`, claims |
| `programs` (isi buku, target, status) | buat + ubah terbatas | — | field turunan, `classId` |
| `activePrograms` | buat/hapus bersama program | — | — |
| `journals` | CRUD dalam jendela BR-3/4 | — | `hasUnreadTeacherComment`, `lastCommentAt` |
| `comments` | — | buat + ubah/hapus miliknya | — |
| `studentStats` | — | — | semua |
| `devices` | CRUD miliknya | CRUD miliknya | bersihkan token mati |
| Storage `avatars/{uid}.jpg` | miliknya | miliknya | hapus saat akun/data dihapus |

## 5. Indeks
Query utama dan kebutuhan indeks (detail JSON ada di `firebase/firestore.indexes.json`):

| Query | Kebutuhan |
|---|---|
| Daftar siswa: `studentStats` `orderBy name` (seluruh sekolah) | Field tunggal (otomatis) |
| Anggota sekolah: `members` `where schoolId == S` `where role == siswa` | Komposit `schoolId` + `role` |
| Riwayat jurnal satu buku: `journals` `orderBy date desc` | Field tunggal (otomatis) |
| Riwayat buku siswa (siswa): `programs` `where studentId == me` `orderBy startDate desc` | Komposit `studentId` + `startDate` |
| Riwayat buku siswa (penanggung jawab): `programs` `where studentId == X` `orderBy startDate desc` | Komposit `studentId` + `startDate` (sama dengan di atas) |
| Komentar baru pada Beranda: `journals` (dalam satu program) `where hasUnreadTeacherComment == true` `orderBy date desc` | Komposit `hasUnreadTeacherComment` + `date` |
| Pengguna per peran: `users` `where role == X` `orderBy name` | Komposit `role` + `name` |

Buku aktif siswa tidak perlu query: baca `activePrograms/{uid}` lalu `programs/{programId}`.

Sengaja **tidak memakai collection-group query** untuk jurnal: rules tidak bisa memeriksa sekolah induk pada query lintas program. Penanggung jawab membuka jurnal siswa dengan menelusuri program siswa tersebut.

## 6. Contoh dokumen

```jsonc
// schools/smaN1/programs/p_8Kd2
{
  "studentId": "u_raka", "classId": "XII-A1",
  "book": { "title": "Laskar Pelangi", "author": "Andrea Hirata", "totalPages": 300 },
  "month": "2026-10", "startDate": "2026-10-01", "targetDate": "2026-10-31", "extended": false,
  "status": "active",
  "currentPage": 230, "journalCount": 18, "lastJournalDate": "2026-10-06",
  "streakCurrent": 8, "streakBest": 8
}

// .../journals/2026-10-06
{
  "studentId": "u_raka", "date": "2026-10-06",
  "pageStart": 216, "pageEnd": 230, "durationRange": "15to30",
  "keyInformation": "Ikal mulai menyadari bahwa pendidikan adalah jalan untuk merubah hidupnya.",
  "reflection": "Perjuangan tokoh utama sangat menginspirasi.",
  "question": "Mengapa tokoh utama tetap sekolah meskipun fasilitasnya terbatas?",
  "hasUnreadTeacherComment": false
}
```

## 7. Batas dan risiko yang sudah dipertimbangkan
- Batas tulis ±1 per detik per dokumen: aman, satu siswa menulis ≤ 1 jurnal per hari ke dokumen berbeda; `studentStats` per siswa diperbarui jarang.
- Ukuran dokumen jauh di bawah 1 MiB.
- Custom claim hanya `{role, schoolId}`, jauh di bawah batas 1000 byte.
- Ganti kelas siswa: `programs.classId` dan `studentStats.classId` diperbarui trigger `onUserUpdated`. Akses tidak berubah karena semua penanggung jawab sekolah melihat semua siswa.
- Satu email satu sekolah dijamin ID dokumen `members/{email}`; `create()` kedua gagal.
- Mengeluarkan siswa (`status: removed`) mencabut claims dan menghapus `studentStats`, tetapi `programs` dan `journals` tetap; klaim ulang memulihkan semuanya.
- Zona waktu: seluruh logika "hari" memakai WIB (tanpa DST). Klien tidak dipercaya untuk tanggal; rules memakai `request.time`.
