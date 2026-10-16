# 02 — Model Data Firestore

> Diperbarui 16 Oktober 2026 untuk model v2: login email/Google, daftar anggota `members/{email}`, peran `guru`|`siswa`, kelas dan ekstrakurikuler sebagai label, foto profil di Cloud Storage.
>
> Diperbarui 17 Oktober 2026 untuk 1.2.1: katalog buku bersama (`books`, `books/{id}/history`, `catalog`, `bookSuggestions`, `schools/{s}/bookStats`, `schools/{s}.recommendedBooks`, cover di Storage), laporan konten dan pengguna (`reports`), dan persetujuan ketentuan (`users.termsVersion`, `users.termsAcceptedAt`).

Database: Cloud Firestore (mode Native), lokasi **asia-southeast2 (Jakarta)**. Lokasi tidak bisa diubah setelah dibuat, jadi tentukan sejak awal. Semua waktu disimpan sebagai `Timestamp` (UTC); semua **tanggal kalender** disimpan sebagai string `yyyy-MM-dd` dalam WIB.

## 1. Prinsip desain
1. **Isolasi per sekolah lewat path:** semua data sekolah di bawah `schools/{schoolId}`. Rules memeriksa `request.auth.token.schoolId == schoolId`. Koleksi top-level hanya untuk data yang memang lintas sekolah atau dicari per email:
   - `members/{email}` (daftar anggota): penanggung jawab membaca entri yang `schoolId`-nya sama dengan claim;
   - katalog buku bersama `books`, `catalog`, `bookSuggestions`: dibaca anggota semua sekolah (`bookSuggestions` hanya penanggung jawab), ditulis hanya Cloud Functions;
   - `reports`: dibaca penanggung jawab sekolah yang tercantum di `reports.schools`, ditulis hanya Cloud Functions.
2. **ID dokumen yang membawa aturan:** jurnal memakai ID tanggal, sehingga "satu jurnal per hari" dijamin database.
3. **Kepemilikan tulis jelas:** data yang diisi pengguna ditulis klien; angka turunan (progres, streak, status) **hanya ditulis Cloud Functions**. Klien tidak bisa memalsukannya (dijaga rules).
4. **Dokumen ringkasan untuk layar padat:** `studentStats` melayani Dashboard guru dan Beranda siswa dengan 1 query.
5. **Hitung ulang, bukan tambah-kurang:** trigger menghitung ulang agregat dari semua jurnal satu buku (maks sekitar 60 dokumen), sehingga idempoten dan tahan terhadap sinkronisasi offline yang datang tidak berurutan.

## 2. Pohon koleksi

```
members/{email}                                 ← daftar anggota, ID = email huruf kecil (1 email = 1 sekolah)
books/{bookId}                                  ← katalog buku bersama semua sekolah (ditulis server)
└── history/{entryId}                           ← riwayat perubahan satu buku (ditulis server)
catalog/shard-{0..3}                            ← indeks pencarian katalog (ditulis server)
bookSuggestions/{suggestionId}                  ← usulan siswa untuk katalog (ditulis server)
reports/{reportId}                              ← laporan konten dan pengguna (ditulis server)
schools/{schoolId}                              ← schoolId = kode sekolah (huruf kecil)
├── users/{uid}                                 ← uid = Firebase Auth UID, dibuat saat klaim
│   └── devices/{tokenHash}                     ← token FCM
├── studentStats/{studentId}                    ← ringkasan (ditulis server)
├── activePrograms/{studentId}                  ← kunci "satu buku aktif per siswa" (BR-1)
├── bookStats/{bookId}                          ← jumlah pembaca buku katalog di sekolah ini (ditulis server)
├── auditLogs/{logId}                           ← log audit (server saja, tanpa rules)
└── programs/{programId}                        ← satu buku yang dibaca satu siswa
    └── journals/{yyyy-MM-dd}
        └── comments/{commentId}
```

Cloud Storage (bucket `sabusaku.firebasestorage.app`, wilayah `asia-southeast2`), semua gambar `image/*` < 1 MB:

| Path | Isi | Tulis | Baca |
|---|---|---|---|
| `schools/{schoolId}/avatars/{uid}.jpg` | Foto profil. URL unduhnya di `users.photoUrl` | pemilik | anggota sekolah |
| `schools/{schoolId}/programCovers/{uid}/{ms}.jpg` | Foto cover yang siswa ambil (kamera atau galeri, dipotong/diputar/dikompres di HP) untuk bukunya sendiri. URL-nya di `programs.book.coverUrl` | siswa pemilik folder | anggota sekolah |
| `books/{bookId}/cover.jpg`, `books/{bookId}/cover-{ms}.jpg` | Cover katalog: hasil impor (`cover.jpg`), unggahan penanggung jawab (dipasang `setBookCover`), atau salinan cover usulan siswa (`reviewSuggestion`) | penanggung jawab mana pun; tidak bisa dihapus dari aplikasi | anggota semua sekolah |

Katalog tidak pernah menunjuk file di `programCovers`: cover usulan disalin ke `books/{bookId}/` dengan token unduh baru, karena siswa bisa menghapus filenya dan file itu hanya terbaca di sekolahnya. URL unduh berisi token, jadi siapa pun yang memegang URL (mis. penanggung jawab sekolah lain yang membuka usulan) bisa menampilkan gambarnya; rules Storage di atas berlaku untuk akses lewat SDK.

Koleksi `classes` dari v1 dihapus: kelas kini label di dokumen sekolah.

Data buku tetap disalin ke `programs.book`, sehingga jurnal tidak bergantung pada katalog. Program yang dipilih dari katalog menyimpan `book.bookId` dan `book.coverUrl`; buku yang diketik sendiri tidak punya `bookId` dan menjadi usulan katalog (§3.13).

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
| `recommendedBooks` | string[] | ID buku katalog yang direkomendasikan sekolah, unik, maks 200. Tampil paling atas saat siswa mencari |
| `createdAt` | timestamp | |

Tulis: developer (skrip) dan penanggung jawab (hanya `settings`, `classes`, `extracurriculars`, `recommendedBooks`, divalidasi rules). Baca: seluruh anggota sekolah.

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
| `termsVersion` | int? | Versi Ketentuan penggunaan (https://sabusaku.web.app/ketentuan) yang disetujui. Tidak ada = 0 (belum setuju). Saat ini `CURRENT_TERMS_VERSION = 1` (`functions/src/domain/terms.ts`, `lib/core/policy/terms.dart`) |
| `termsAcceptedAt` | timestamp? | Waktu server saat versi itu disetujui. Menyetujui versi yang sama lagi tidak mengubahnya |
| `createdAt`, `updatedAt` | timestamp | |

Dibuat oleh `claimAccount` saat pengguna pertama kali masuk dengan email yang terdaftar. Pemilik boleh mengubah `name`, `classId`, `extracurriculars`, `photoUrl`; penanggung jawab boleh mengubah `name`, `classId`, `extracurriculars` siswa. `role`, `email`, `status`, `termsVersion`, `termsAcceptedAt` hanya lewat Functions (`termsVersion`/`termsAcceptedAt` lewat callable `acceptTerms`). Selama `termsVersion < CURRENT_TERMS_VERSION`, aplikasi hanya membuka layar ketentuan. Field v1 `username`, `nis`, `classIds`, `mustChangePassword` dihapus.

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
| `book.title` | string | siswa | 2–200 |
| `book.author` | string | siswa | 2–200 (penulis katalog digabung dengan `, `) |
| `book.totalPages` | int | siswa | 10–2000, tetap setelah dibuat |
| `book.isbn` | string? | siswa | ≤ 20 |
| `book.bookId` | string? | siswa saat buat, lalu server | ID buku katalog bila dipilih dari katalog (rules memastikan `books/{bookId}` ada). Diisi server saat usulan buku baru diterima atau ditautkan (`linkSuggestionPrograms`). Dasar hitungan pembaca |
| `book.coverUrl` | string? | siswa saat buat, lalu server | URL Firebase Storage: cover katalog, atau foto siswa di `programCovers/{uid}/`. Diisi server bersama `book.bookId` |
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

### 3.10 `books/{bookId}` — katalog buku bersama (top-level)
Dipakai semua sekolah. Ditulis **hanya** oleh Cloud Functions (`saveBook`, `deleteBook`, `restoreBook`, `setBookCover`, `reviewSuggestion`) dan alat impor `functions/tools/books`, supaya setiap perubahan masuk riwayat. Dibaca anggota sekolah mana pun (claim `schoolId` dan `role` terisi).

| Field | Tipe | Keterangan |
|---|---|---|
| `title` | string | 2–200 |
| `subtitle` | string? | ≤ 200 |
| `authors` | string[] | 1–5 nama, masing-masing 2–120, unik |
| `publisher` | string? | ≤ 120 |
| `publishedYear` | int? | 1800–2100 |
| `isbn13`, `isbn10` | string? | Hanya angka (ISBN-10 boleh diakhiri `X`) |
| `pageCount` | int | 10–2000 |
| `categories` | string[] | 1–3 dari daftar tetap `BOOK_CATEGORIES` (`functions/src/domain/search.ts`, sama dengan `lib/features/books/domain/book_categories.dart`) |
| `description` | string? | Sinopsis, ≤ 2000 |
| `descriptionSource` | string? | Asal sinopsis hasil impor (`google`, `openlibrary`) |
| `language` | string | `id` |
| `coverUrl` | string? | URL unduh cover di `books/{bookId}/` |
| `coverSource` | map? | `{provider: google\|openlibrary\|upload\|suggestion, url?, sourceId?}` |
| `searchKey` | string | `judul\|penulis pertama`, dinormalkan (`bookKey`). Buku baru ditolak (`already-exists`) bila ada buku aktif dengan `searchKey` atau `isbn13` yang sama |
| `status` | string | `active` · `deleted` (hapus lunak; bisa dipulihkan penanggung jawab sekolah mana pun) |
| `deletedAt`, `deletedBy`, `deleteReason`, `duplicateOf` | | Hanya selama `status == deleted`. `duplicateOf` = ID buku aslinya bila dihapus sebagai duplikat |
| `readerCount` | int | Jumlah program (semua sekolah) yang menunjuk buku ini. Server (`onProgramWritten`) |
| `createdAt`, `createdBy`, `updatedAt`, `updatedBy` | | `*By` = Actor |
| `version` | int | Naik 1 setiap perubahan |

**Actor** (`createdBy`, `updatedBy`, `deletedBy`, `history.by`, `bookSuggestions.reviewedBy`): `{uid?, name, schoolId?, schoolName?, kind: import|guru|siswa}`. Untuk penanggung jawab berisi nama profil dan nama sekolahnya; impor tercatat `{name: "Impor awal", kind: "import"}`.

### 3.11 `books/{bookId}/history/{entryId}`
| Field | Tipe | Keterangan |
|---|---|---|
| `type` | string | `created` · `updated` · `deleted` · `restored` · `cover_changed` · `suggestion_applied` · `suggestion_rejected` |
| `changes` | map | `{field: {from, to}}` |
| `by` | map | Actor |
| `at` | timestamp | Waktu server |
| `suggestionId` | string? | Usulan yang diterapkan atau ditolak |
| `note` | string? | Alasan hapus, atau catatan impor |

Ditulis dalam transaksi yang sama dengan perubahan bukunya (`addHistory`). Dibaca anggota semua sekolah, termasuk nama penanggung jawab dan sekolahnya. Tidak dihapus saat akun penanggung jawab dihapus.

### 3.12 `catalog/shard-{n}` — indeks pencarian (n = 0..3)
Firestore tidak punya pencarian teks penuh, jadi aplikasi membaca empat dokumen ini sekali (tersimpan di cache offline) dan mencari di perangkat.

| Field | Tipe | Keterangan |
|---|---|---|
| `entries.{bookId}` | map | Hanya buku aktif: `t` judul, `a` penulis digabung `, `, `p` jumlah halaman, `y` tahun, `c` URL cover, `g` kategori, `r` `readerCount` |
| `count` | int | Jumlah entri (diisi saat dibangun ulang) |
| `updatedAt` | timestamp | |

Shard = jumlah kode karakter ID buku mod 4 (`shardOf`). Satu entri diperbarui trigger `onBookWritten`; seluruh indeks dibangun ulang oleh `rebuildCatalog` setelah impor (impor melewati trigger). Dibaca anggota semua sekolah.

### 3.13 `bookSuggestions/{suggestionId}` — usulan siswa
Dibuat trigger `onProgramWritten` saat program baru dibuat:
- `new`: buku yang diketik siswa sendiri (tanpa `book.bookId`);
- `edit`: buku katalog yang datanya diubah siswa (judul, penulis, halaman, ISBN), atau diberi foto cover sendiri.

Usulan yang sama (`dedupeKey` sama, masih `pending`) digabung: `count` naik dan sumbernya ditambahkan.

| Field | Tipe | Keterangan |
|---|---|---|
| `kind` | string | `new` · `edit` |
| `bookId` | string? | Buku katalog (`edit`); `null` untuk `new` |
| `proposed` | map | `title`, `authors`, `pageCount`, `isbn13`/`isbn10` sesuai jenis; `coverUrl` + `coverPath` bila ada foto siswa di `programCovers` |
| `dedupeKey` | string | `edit`: `bookId\|usulan`; `new`: `searchKey` |
| `count` | int | Jumlah program yang mengusulkan hal yang sama |
| `from` | map[] | `{schoolId, schoolName, programId}`, maks 50 terakhir. **Tanpa nama siswa**, karena sekolah lain ikut melihat |
| `status` | string | `pending` · `accepted` · `rejected` |
| `reviewedBy`, `reviewedAt`, `resultBookId` | | Diisi `reviewSuggestion` (`apply`, `reject`, `create`, `link`) |
| `createdAt`, `updatedAt` | timestamp | |

Dibaca penanggung jawab sekolah mana pun (siswa tidak). Saat data siswa dihapus, `proposed.coverUrl`/`coverPath` yang menunjuk fotonya dihapus; usulan `pending` yang hanya berisi foto itu ikut terhapus (`forgetStudentCovers`).

### 3.14 `schools/{schoolId}/bookStats/{bookId}`
`readers` (int, program di sekolah ini yang menunjuk buku), `active` (int, yang masih aktif), `updatedAt`. Ditulis trigger `onProgramWritten` mengikuti `book.bookId` dan status program. Dibaca anggota sekolah (untuk "Populer di sekolahmu" dan jumlah pembaca di detail buku). Angka tanpa nama.

### 3.15 `reports/{reportId}` — laporan konten dan pengguna (top-level)
Kebijakan Konten Buatan Pengguna (UGC) Google Play. Dibuat **hanya** oleh callable `reportContent`, diselesaikan oleh `resolveReport` (penanggung jawab) atau `functions/tools/reports.ts` (pengembang, tercatat "Pengembang").

| Field | Tipe | Keterangan |
|---|---|---|
| `kind` | string | `comment` · `journal` · `book` · `suggestion` · `user` |
| `reason` | string | `inappropriate` · `harassment` · `personal_data` · `copyright` · `wrong_data` · `other` |
| `note` | string? | Catatan pelapor, ≤ 500 |
| `status` | string | `open` · `resolved` |
| `reporterId`, `reporterRole`, `reporterName` | string | Pelapor |
| `schoolId` | string | Sekolah pelapor |
| `targetSchoolId` | string? | Sekolah pemilik konten: sekolah pelapor untuk `comment`/`journal`/`user`; `null` untuk `book`/`suggestion` |
| `schools` | string[] | `[schoolId]` ditambah `targetSchoolId` bila berbeda; `[]` untuk laporan tentang penanggung jawab (komentarnya atau dirinya), yang hanya dilihat pengembang. Dasar rules baca dan query daftar laporan |
| `subjectId` | string? | UID orang yang konten atau akunnya dilaporkan (penulis komentar, siswa pemilik jurnal, pengguna); `null` untuk buku/usulan |
| `target` | map | `{programId?, date?, commentId?, bookId?, suggestionId?, userId?}` |
| `snapshot` | map | Salinan saat dilaporkan: komentar `{text, authorName}`; jurnal `{studentName, date, keyInformation}` (300 karakter pertama); buku `{title, authors, coverUrl}`; usulan `{title, coverUrl}`; pengguna `{name, role}` |
| `targetDeleted` | bool | `true` setelah data orang yang dilaporkan dihapus (`snapshot` dikosongkan, `note` jadi null) |
| `createdAt`, `updatedAt` | timestamp | |
| `resolvedAt`, `resolvedBy {uid, name}`, `resolution` | | Saat selesai; `resolution` ≤ 500 |

Aturan pembuatan: komentar boleh dilaporkan siswa pemilik jurnal dan penanggung jawab sekolah itu; jurnal dan usulan hanya penanggung jawab; buku dan pengguna (di sekolah yang sama) siapa saja. Konten atau akun sendiri tidak bisa dilaporkan. Maks 20 laporan per pelapor dalam 24 jam (`resource-exhausted`). Setiap laporan dan penyelesaian tercatat di `auditLogs`.

Baca: penanggung jawab yang claim `schoolId`-nya ada di `schools`. Siswa tidak bisa membaca laporan, termasuk laporannya sendiri.

Penghapusan (`forgetReports`, dipanggil `eraseStudentData` dan `deleteMyAccount`): laporan dengan `reporterId == uid` dihapus; laporan dengan `subjectId == uid` tetap ada dengan `snapshot = {}`, `note = null`, dan `targetDeleted = true`. `tools/delete-school.ts` menghapus laporan yang `schools`-nya memuat sekolah itu.

### 3.16 `schools/{schoolId}/auditLogs/{logId}`
`action`, `actorUid`, `details` (ID dan jumlah, tanpa teks jurnal), `at`. Ditulis `audit()` di Functions; tidak ada rules yang membukanya ke klien.

## 4. Matriks kepemilikan tulis

| Data | Siswa | Penanggung jawab | Functions / skrip developer |
|---|---|---|---|
| `schools` | — | `settings`, `classes`, `extracurriculars`, `recommendedBooks` | buat sekolah, `status` |
| `members` | — | ubah nama/kelas/ekskul siswa yang belum masuk | buat, hapus, `uid` |
| `users` | `name`, `classId`, `extracurriculars`, `photoUrl` miliknya | `name`, `classId`, `extracurriculars` siswa | buat (klaim), `status`, `email`, claims, `termsVersion`/`termsAcceptedAt` (`acceptTerms`) |
| `programs` (isi buku, target, status) | buat + ubah terbatas | — | field turunan, `classId`, `book.bookId`/`book.coverUrl` saat usulan diterima |
| `activePrograms` | buat/hapus bersama program | — | — |
| `journals` | CRUD dalam jendela BR-3/4 | — | `hasUnreadTeacherComment`, `lastCommentAt` |
| `comments` | — | buat + ubah/hapus miliknya | — |
| `studentStats` | — | — | semua |
| `devices` | CRUD miliknya | CRUD miliknya | bersihkan token mati |
| `books`, `books/*/history`, `catalog` | — | lewat callable (`saveBook`, `deleteBook`, `restoreBook`, `setBookCover`, `reviewSuggestion`) | semua; impor lewat `tools/books` |
| `bookSuggestions` | tidak langsung: program baru memicu usulan | tinjau lewat `reviewSuggestion` | buat (trigger), tutup |
| `bookStats` | — | — | semua (trigger) |
| `reports` | kirim lewat `reportContent` | kirim lewat `reportContent`, selesaikan lewat `resolveReport` | semua; pengembang menyelesaikan lewat `tools/reports.ts` |
| `auditLogs` | — | — | semua |
| Storage `avatars/{uid}.jpg` | miliknya | miliknya | hapus saat akun/data dihapus |
| Storage `programCovers/{uid}/` | miliknya | — | hapus saat data siswa dihapus |
| Storage `books/{bookId}/` | — | unggah cover (dipasang `setBookCover`) | salin cover usulan, impor |

## 5. Indeks
Query utama dan kebutuhan indeks (detail JSON ada di `firestore.indexes.json` di akar repositori):

| Query | Kebutuhan |
|---|---|
| Daftar siswa: `studentStats` `orderBy name` (seluruh sekolah) | Field tunggal (otomatis) |
| Anggota sekolah: `members` `where schoolId == S` `where role == siswa` | Komposit `schoolId` + `role` |
| Riwayat jurnal satu buku: `journals` `orderBy date desc` | Field tunggal (otomatis) |
| Riwayat buku siswa (siswa): `programs` `where studentId == me` `orderBy startDate desc` | Komposit `studentId` + `startDate` |
| Riwayat buku siswa (penanggung jawab): `programs` `where studentId == X` `orderBy startDate desc` | Komposit `studentId` + `startDate` (sama dengan di atas) |
| Komentar baru pada Beranda: `journals` (dalam satu program) `where hasUnreadTeacherComment == true` `orderBy date desc` | Komposit `hasUnreadTeacherComment` + `date` |
| Pengguna per peran: `users` `where role == X` `orderBy name` | Komposit `role` + `name` |
| Indeks katalog: 4 × `get` `catalog/shard-{n}` | Tidak perlu query |
| Pembaca per buku di sekolah: `schools/{s}/bookStats` (seluruh koleksi, kecil) | Tidak perlu indeks |
| Buku terhapus: `books` `where status == deleted` (diurutkan di perangkat) | Field tunggal; komposit `status` + `deletedAt` desc dan `status` + `title` juga tersedia |
| Usulan tertunda: `bookSuggestions` `where status == pending` (dan `where bookId == X`), diurutkan di perangkat | Hanya kesetaraan, tidak perlu komposit; komposit `status` + `updatedAt` desc dan `bookId` + `status` + `updatedAt` desc tersedia |
| Cek duplikat saat simpan buku: `books` `where status == active` `where isbn13 == X` / `where searchKey == X` | Hanya kesetaraan (gabungan indeks field tunggal) |
| Laporan sekolah (penanggung jawab): `reports` `where schools array-contains S` `orderBy createdAt desc` | Komposit `schools` (array) + `createdAt` desc |
| Batas 20 laporan/hari: `reports` `where reporterId == U` `orderBy createdAt desc` `limit 20` (server) | Komposit `reporterId` + `createdAt` desc |

Buku aktif siswa tidak perlu query: baca `activePrograms/{uid}` lalu `programs/{programId}`.

Query daftar laporan harus memakai `schools array-contains <sekolah sendiri>`: rules hanya mengizinkan dokumen yang `schools`-nya memuat sekolah pembaca, dan "rules bukan filter".

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

// books/b_Lp01 (katalog)
{
  "title": "Laskar Pelangi", "authors": ["Andrea Hirata"], "pageCount": 529,
  "categories": ["Novel"], "language": "id", "status": "active", "readerCount": 12,
  "searchKey": "laskar pelangi|andrea hirata",
  "coverUrl": "https://firebasestorage.googleapis.com/v0/b/sabusaku.firebasestorage.app/o/books%2Fb_Lp01%2Fcover.jpg?alt=media&token=…",
  "updatedBy": { "uid": "u_bu_sri", "name": "Sri Wahyuni", "schoolId": "sman1", "schoolName": "SMA Negeri 1", "kind": "guru" },
  "version": 3
}

// reports/r_9xQ
{
  "kind": "comment", "reason": "harassment", "note": null, "status": "open",
  "reporterId": "u_raka", "reporterRole": "siswa", "reporterName": "Raka Pratama",
  "schoolId": "sman1", "targetSchoolId": "sman1", "schools": ["sman1"], "subjectId": "u_pak_budi",
  "target": { "programId": "p_8Kd2", "date": "2026-10-06", "commentId": "c_1" },
  "snapshot": { "text": "…", "authorName": "Budi Santoso" },
  "targetDeleted": false
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
- Indeks katalog: setiap entri shard sekitar 300 byte (URL cover paling panjang), jadi empat shard muat kira-kira 10.000 buku sebelum mendekati 1 MiB per dokumen (perkiraan, belum diukur). Tambah `CATALOG_SHARDS` (server dan aplikasi bersamaan) bila katalog tumbuh sejauh itu.
- `readerCount` ikut indeks (`r`), jadi setiap program yang mulai atau berganti buku katalog juga menulis satu shard. Di awal bulan, saat banyak siswa mulai buku, penulisan ke empat dokumen shard bisa melebihi ±1 tulis/detik per dokumen sesaat. Batas itu lunak, tetapi trigger tidak memakai `retry`: bila satu penulisan gagal, entri buku itu tertinggal sampai bukunya berubah lagi atau `rebuildCatalog` dijalankan.
- `programs.book` adalah salinan: mengubah atau menghapus buku katalog tidak mengubah program yang sudah ada. Hapus buku katalog selalu lunak (`status: deleted`), sehingga `book.bookId` lama tetap menunjuk dokumen yang ada.
- Laporan menyimpan nama pelapor dan salinan konten. Siapa pun penanggung jawab di sekolah yang tercantum di `schools` bisa membacanya, termasuk penanggung jawab yang dilaporkan.
