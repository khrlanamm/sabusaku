# 02 — Model Data Firestore

Database: Cloud Firestore (mode Native), lokasi **asia-southeast2 (Jakarta)**. Lokasi tidak bisa diubah setelah dibuat, jadi tentukan sejak awal. Semua waktu disimpan sebagai `Timestamp` (UTC); semua **tanggal kalender** disimpan sebagai string `yyyy-MM-dd` dalam WIB.

## 1. Prinsip desain
1. **Isolasi per sekolah lewat path:** semua data di bawah `schools/{schoolId}`. Rules memeriksa `request.auth.token.schoolId == schoolId`.
2. **ID dokumen yang membawa aturan:** jurnal memakai ID tanggal, sehingga "satu jurnal per hari" dijamin database.
3. **Kepemilikan tulis jelas:** data yang diisi pengguna ditulis klien; angka turunan (progres, streak, status) **hanya ditulis Cloud Functions**. Klien tidak bisa memalsukannya (dijaga rules).
4. **Dokumen ringkasan untuk layar padat:** `studentStats` melayani Dashboard guru dan Beranda siswa dengan 1 query.
5. **Hitung ulang, bukan tambah-kurang:** trigger menghitung ulang agregat dari semua jurnal satu buku (maks sekitar 60 dokumen), sehingga idempoten dan tahan terhadap sinkronisasi offline yang datang tidak berurutan.

## 2. Pohon koleksi

```
schools/{schoolId}                              ← schoolId = kode sekolah (huruf kecil)
├── users/{uid}                                 ← uid = Firebase Auth UID
│   └── devices/{tokenHash}                     ← token FCM
├── classes/{classId}
├── studentStats/{studentId}                    ← ringkasan (ditulis server)
├── activePrograms/{studentId}                  ← kunci "satu buku aktif per siswa" (BR-1)
└── programs/{programId}                        ← satu buku yang dibaca satu siswa
    └── journals/{yyyy-MM-dd}
        └── comments/{commentId}
```

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
| `createdAt` | timestamp | |

Tulis: developer (skrip) dan admin (hanya `settings.*`). Baca: seluruh anggota sekolah.

### 3.2 `schools/{schoolId}/users/{uid}`
| Field | Tipe | Keterangan |
|---|---|---|
| `role` | string | `admin` · `guru` · `siswa` (tidak bisa diubah) |
| `name` | string | Nama lengkap |
| `username` | string | Huruf kecil `[a-z0-9._-]`, 3–30; untuk siswa = NIS |
| `nis` | string? | Siswa |
| `classId` | string? | Siswa: satu kelas |
| `classIds` | string[] | Guru: kelas yang ditugaskan (maks 20); dicerminkan ke custom claim |
| `status` | string | `active` · `disabled` |
| `mustChangePassword` | bool | `true` sampai pengguna mengganti password |
| `createdAt`, `updatedAt` | timestamp | |

Dibuat/diubah oleh Cloud Functions (callable). Pengguna hanya boleh mengubah `mustChangePassword: true → false` pada dokumennya sendiri. Admin dapat mengubah `name` lewat klien; perubahan peran, kelas, status, dan password selalu lewat callable.

### 3.3 `schools/{schoolId}/users/{uid}/devices/{tokenHash}`
`token`, `platform` (`android`), `updatedAt`. Ditulis pemilik akun. Dibaca server untuk mengirim FCM; token tidak valid dibersihkan server.

### 3.4 `schools/{schoolId}/classes/{classId}`
| Field | Tipe |
|---|---|
| `name` | string (mis. "XII IPA 1") |
| `grade` | int (10–12) |
| `academicYear` | string (mis. "2026/2027") |
| `teacherIds` | string[] (cermin dari `users.classIds`, hanya untuk tampilan) |
| `isArchived` | bool |

Tulis: admin. Baca: anggota sekolah.

### 3.5 `schools/{schoolId}/programs/{programId}` — satu buku satu siswa
`programId` = ID otomatis.

| Field | Tipe | Ditulis oleh | Keterangan |
|---|---|---|---|
| `studentId` | string | siswa (saat buat) | Tetap |
| `classId` | string | siswa saat buat, lalu server | Disalin dari profil siswa; diperbarui server saat pindah kelas |
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
`teacherId`, `teacherName`, `text` (1–1000), `createdAt`, `updatedAt`. Dibuat oleh guru yang menugaskan kelas siswa tersebut; guru hanya mengubah/menghapus komentarnya sendiri. Dibaca oleh siswa pemilik dan guru kelas.

### 3.8 `schools/{schoolId}/studentStats/{studentId}` — ringkasan, ditulis server
| Field | Tipe |
|---|---|
| `studentId`, `name`, `nis`, `classId`, `className` | |
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

Dibaca: siswa pemilik, guru kelas tersebut, admin (tanpa isi jurnal). Dashboard guru = **satu query `where classId == X` per kelas yang ditugaskan**, dijalankan paralel lalu digabung di klien (equality per kelas membuat pembuktian akses di rules pasti; hindari `in`).

### 3.9 `schools/{schoolId}/activePrograms/{studentId}`
Dokumen kunci `{ programId }`. Dibuat siswa dalam **batch yang sama** dengan dokumen program baru, dan dihapus dalam batch yang sama saat program selesai/dihentikan. Karena ID = `studentId`, pembuatan kedua otomatis gagal, sehingga BR-1 (satu buku aktif) dijamin database tanpa transaksi server. Sekaligus menjadi cara 1-baca untuk menemukan buku aktif siswa.

## 4. Matriks kepemilikan tulis

| Data | Siswa | Guru | Admin | Functions |
|---|---|---|---|---|
| `schools` (inti) | — | — | `settings.*` | developer (skrip) |
| `users` | `mustChangePassword`→false | — | `name` | buat/ubah/nonaktif/kelas/claims |
| `classes` | — | — | CRUD | cermin `teacherIds` |
| `programs` (isi buku, target, status) | buat + ubah terbatas | — | — | field turunan, `classId` |
| `activePrograms` | buat/hapus bersama program | — | — | — |
| `journals` | CRUD dalam jendela BR-3/4 | — | — | `hasUnreadTeacherComment`, `lastCommentAt` |
| `comments` | — | buat + ubah/hapus miliknya | — | — |
| `studentStats` | — | — | — | semua |
| `devices` | CRUD miliknya | CRUD miliknya | CRUD miliknya | bersihkan token mati |

## 5. Indeks
Query utama dan kebutuhan indeks (detail JSON ada di `firebase/firestore.indexes.json`):

| Query | Kebutuhan |
|---|---|
| Daftar siswa guru: `studentStats` `where classId == X` `orderBy name` (per kelas) | Komposit `classId` + `name` |
| Filter status: `studentStats` `where classId == X` `where status == Y` `orderBy name` | Komposit `classId` + `status` + `name` |
| Riwayat jurnal satu buku: `journals` `orderBy date desc` | Field tunggal (otomatis) |
| Riwayat buku siswa (siswa): `programs` `where studentId == me` `orderBy startDate desc` | Komposit `studentId` + `startDate` |
| Riwayat buku siswa (guru): `programs` `where studentId == X` `where classId == C` `orderBy startDate desc` | Komposit `studentId` + `classId` + `startDate` |
| Komentar baru pada Beranda: `journals` (dalam satu program) `where hasUnreadTeacherComment == true` `orderBy date desc` | Komposit `hasUnreadTeacherComment` + `date` |
| Pengguna per peran/kelas (admin) | Komposit `role` + `name`, `role` + `classId` + `name` |

Buku aktif siswa tidak perlu query: baca `activePrograms/{uid}` lalu `programs/{programId}`.

Sengaja **tidak memakai collection-group query** untuk jurnal: rules tidak bisa memeriksa kelas induk pada query lintas program. Guru membuka jurnal siswa dengan menelusuri program siswa tersebut.

## 6. Contoh dokumen

```jsonc
// schools/smaN1/programs/p_8Kd2
{
  "studentId": "u_raka", "classId": "xii-ipa-1",
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
- Custom claim maksimal 1000 byte: `classIds` guru dibatasi 20 kelas dengan ID pendek.
- Pindah kelas siswa: `programs.classId` dan `studentStats.classId` diperbarui server; guru lama kehilangan akses ke data siswa tersebut (disengaja, sesuai BR-14).
- Zona waktu: seluruh logika "hari" memakai WIB (tanpa DST). Klien tidak dipercaya untuk tanggal; rules memakai `request.time`.
