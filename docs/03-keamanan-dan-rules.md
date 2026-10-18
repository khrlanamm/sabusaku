# 03 — Keamanan, Autentikasi, dan Security Rules

Berkas terkait: `firestore.rules`, `storage.rules`, `firestore.indexes.json`. Diperbarui 16 Oktober 2026 untuk model v2, dan 17 Oktober 2026 untuk 1.2.1: katalog buku bersama, laporan konten dan pengguna, persetujuan ketentuan, status App Check, dan Firebase Analytics yang dihapus.

## 1. Autentikasi

### Email/password dan Google, lalu klaim keanggotaan
Provider Firebase Auth yang aktif: **Email/Password** dan **Google**. Akun Auth dibuat pengguna sendiri; server tidak lagi membuat akun atau password.

- **Masuk dengan Google** memakai `google_sign_in` (Credential Manager) dengan web client ID project. Butuh SHA-1 terdaftar: debug, upload key, dan Play App Signing (semuanya terdaftar per 16 Oktober 2026).
- **Daftar dengan email**: `createUserWithEmailAndPassword` lalu `sendEmailVerification`. Email belum terverifikasi tidak bisa mengklaim keanggotaan, sehingga orang yang mendaftarkan email milik orang lain tidak mendapat akses. Bila pemilik asli kemudian masuk dengan Google (Gmail), Firebase menimpa akun email yang belum terverifikasi itu.
- **Lupa password**: `sendPasswordResetEmail` (template Firebase berbahasa Indonesia, pengirim "Sabu Saku"). Email enumeration protection Firebase tetap aktif, jadi pesan galat login seragam.
- **Akun Google tanpa password** diarahkan ke Lengkapi akun untuk membuat password (`linkWithCredential(EmailAuthProvider)`), supaya bisa masuk dengan email dan password juga.
- **Klaim**: setelah login, bila token belum punya claim `schoolId`, aplikasi memanggil `claimAccount`. Server mensyaratkan `email_verified`, mencari `members/{email}`, lalu memasang claims, membuat `users/{uid}`, dan mengisi `members.uid`. Tanpa entri `members`, server mengembalikan `not-found` dan aplikasi menampilkan "Harap Menghubungi Administrator Sekolah".
- Akun yang tidak terdaftar tetap ada di Auth tetapi tidak punya claim, sehingga rules menolak semua akses data.

### Custom claims
Dipasang `claimAccount`, dicabut `removeStudent`/`eraseStudent`/`remove-guru`:

| Claim | Nilai |
|---|---|
| `role` | `guru` · `siswa` |
| `schoolId` | kode sekolah |

Setelah claim berubah, klien memanggil `getIdToken(true)`. Mengeluarkan siswa memanggil `revokeRefreshTokens` dan menandai `users.status = removed`; ID token yang sudah terbit tetap berlaku sampai kedaluwarsa (maks sekitar 1 jam), tetapi aplikasi mendengarkan dokumen profil dan langsung keluar saat status berubah.

### Kebijakan password
Minimal 8 karakter, maksimal 64, dibuat pengguna sendiri.

### Persetujuan ketentuan penggunaan
Ketentuan: https://sabusaku.web.app/ketentuan (`hosting/ketentuan.html`). Versi berlaku `CURRENT_TERMS_VERSION = 1` di `functions/src/domain/terms.ts` dan `lib/core/policy/terms.dart` (harus sama).

- Setelah klaim, router mengecek `users.termsVersion` (tidak ada = 0). Selama lebih kecil dari versi berlaku, semua lokasi diarahkan ke `/ketentuan`. Urutan gerbang: **ketentuan dulu**, lalu Lengkapi akun, lalu area peran, karena nama dan foto profil sudah konten yang dilihat orang lain.
- Layar ketentuan berisi ringkasan, tautan ke halaman lengkap, "Saya setuju" (memanggil `acceptTerms`), dan "Keluar".
- Callable `acceptTerms({version})`: peran `guru` atau `siswa` dengan sekolah; `version` harus sama dengan versi server, kalau tidak `invalid-argument` "Ketentuan sudah diperbarui. Muat ulang aplikasi." (aplikasi lama tidak bisa menyetujui ketentuan baru yang belum ditampilkannya). Mengisi `termsVersion` dan `termsAcceptedAt` (waktu server), idempoten, tercatat di `auditLogs`.
- Kedua field hanya ditulis server: daftar `hasOnly` di rules `users` tidak memuatnya.
- Menaikkan versi (ketentuan berubah) memaksa semua pengguna menyetujui lagi saat membuka aplikasi.

## 2. Model otorisasi

| Data | Siswa | Penanggung jawab (guru) |
|---|---|---|
| Profil sendiri | baca; ubah nama, kelas, ekskul, foto | baca; ubah nama, foto, wali kelas (`homeroomClass`, satu kelas terdaftar atau kosong), ekskul yang dibina |
| Profil siswa sekolahnya | — | baca semua; ubah nama, kelas, ekskul |
| `members` sekolahnya | — | baca; ubah siswa dan guru yang belum masuk; tambah/keluarkan guru lain lewat `addTeacher`/`removeTeacher` (bukan diri sendiri) |
| `studentStats` | miliknya | semua di sekolahnya |
| `programs`, `journals` | miliknya (tulis dalam aturan BR) | baca semua di sekolahnya |
| `comments` | baca miliknya | buat/ubah/hapus miliknya |
| `schools` (`settings`, `classes`, `extracurriculars`, `recommendedBooks`) | baca | ubah |
| `schools.staff` (nama wali kelas dan pembina) | baca | baca; hanya Functions yang menulis |
| Ketentuan (`termsVersion`, `termsAcceptedAt`) | lewat `acceptTerms` | lewat `acceptTerms` |
| Katalog `books`, `books/*/history`, `catalog` (semua sekolah) | baca | baca; ubah lewat callable (`saveBook`, `deleteBook`, `restoreBook`, `setBookCover`) |
| `bookSuggestions` (semua sekolah) | — (usulan dibuat server dari program barunya) | baca; tinjau lewat `reviewSuggestion` |
| `bookStats` sekolahnya | baca | baca |
| `leaderboards` sekolahnya (nama, kelas, ekskul, dan angka membaca semua siswa per periode) | baca satu periode (`get`) | baca satu periode (`get`); hanya Functions yang menulis |
| `reports` | kirim lewat `reportContent` (komentar pada jurnalnya, penulis komentar, buku); tidak bisa membaca | kirim (juga jurnal, usulan, siswa); baca laporan yang `schools`-nya memuat sekolahnya; selesaikan lewat `resolveReport` |
| Foto profil (Storage) | tulis miliknya, baca sekolahnya | tulis miliknya, baca sekolahnya |
| Cover milik siswa `programCovers/{uid}/` (Storage) | tulis miliknya, baca sekolahnya | baca sekolahnya |
| Cover katalog `books/{bookId}/` (Storage) | baca | baca; unggah (tidak bisa menghapus) |

Peran admin sekolah dihapus. Menambah sekolah dan penanggung jawab pertamanya hanya lewat skrip developer; sesudahnya penanggung jawab menambah dan mengeluarkan penanggung jawab lain sekolahnya lewat callable (`addTeacher`, `removeTeacher`), tidak pernah dirinya sendiri. Wali kelas dan ekskul binaan tidak memberi hak akses tambahan: setiap penanggung jawab tetap melihat dan mengelola semua siswa sekolahnya. Menambah, mengeluarkan, dan menghapus data siswa lewat callable (`addStudents`, `removeStudent`, `eraseStudent`). Claims, `status`, `email`, dan angka turunan **hanya** ditulis Functions.

## 3. Cara rules menegakkan aturan bisnis

| Aturan | Mekanisme di rules |
|---|---|
| BR-1 satu buku aktif | Dokumen kunci `activePrograms/{uid}` dibuat/dihapus dalam batch yang sama dengan program (`existsAfter`/`getAfter`) |
| BR-2 satu jurnal per hari | ID dokumen jurnal = tanggal; `create` kedua pada ID yang sama gagal |
| BR-3 rentang tanggal | `daysAgo(date)` antara 0 dan 2, dihitung dari `request.time` + 7 jam (WIB), bukan jam perangkat |
| BR-4 jendela edit | Ubah isi dan hapus hanya bila `daysAgo(date) ≤ 1` |
| BR-5 halaman | `pageEnd ≥ pageStart` dan `pageEnd ≤ book.totalPages` (baca dokumen program) |
| BR-7 panjang teks | `keyInformation` 30–1000 karakter |
| Angka turunan | Daftar `hasOnly` pada `affectedKeys`; field server tidak ada di daftar yang boleh diubah klien |
| BR-14 isolasi | Pemeriksaan `schoolId` claim terhadap path (dan terhadap `members.schoolId`) |
| BR-18 label | `classId` harus ada di `schools.classes`; `extracurriculars` harus himpunan bagian `schools.extracurriculars`, maks 10 |
| Ketentuan | `termsVersion` dan `termsAcceptedAt` tidak ada di daftar `hasOnly` pemilik maupun penanggung jawab, jadi klien tidak bisa mengisinya |
| Katalog bersama | `books`, `history`, `catalog`, `bookSuggestions`: `allow write: if false`; baca `isMember()` (claim `schoolId` dan `role` terisi), `bookSuggestions` hanya `isAnyTeacher()`. Program dari katalog: `book.bookId` harus ada di `books`, `book.coverUrl` harus URL Firebase Storage. `recommendedBooks`: ID unik, maks 200 |
| Laporan | `match /reports/{id} { allow read: if isTeacherOfAny(resource.data.schools); allow write: if false; }`: guru yang claim `schoolId`-nya ada di `schools`. Siswa tidak bisa membaca laporan, termasuk laporannya sendiri. Semua tulis lewat Functions. Laporan tentang penanggung jawab (komentarnya, atau dirinya sebagai pengguna) disimpan dengan `schools: []`, jadi hanya pengembang yang melihatnya lewat `tools/reports.ts`; guru yang dilaporkan tidak bisa melihat pelapornya |

### Pola query yang harus dipatuhi klien (karena "rules bukan filter")
- Siswa: `programs where studentId == uid`; jurnal dibaca per program.
- Penanggung jawab: `studentStats orderBy name`, `programs where studentId == S`, `members where schoolId == S where role == siswa`, `reports where schools array-contains S orderBy createdAt desc`.
- **Tidak memakai collection-group query** untuk `journals`/`comments`.

### Catatan perilaku offline
Jurnal ditulis offline akan dikirim saat online. Bila tanggal jurnal sudah melewati batas BR-3 pada saat sinkron (mis. diketik Senin, tersinkron Kamis), server menolaknya. Klien harus mendengarkan kegagalan tulis tertunda dan menampilkan "Jurnal belum terkirim" beserta alasannya, bukan diam-diam.

## 4. Lapisan keamanan lain

| Lapisan | Rencana |
|---|---|
| **App Check** | **Belum ditegakkan.** Aplikasi hanya mengaktifkan App Check bila dibangun dengan `--dart-define=APP_CHECK=true` (`lib/bootstrap.dart`; Play Integrity di rilis, provider debug di debug); build biasa tidak mengirim token. Semua callable berjalan dengan `enforceAppCheck: false` (`CALLABLE_OPTIONS` di `functions/src/config.ts`). Di konsol, API App Check tidak mengembalikan konfigurasi layanan apa pun untuk project `sabusaku` (dicek 17 Oktober 2026), jadi Firestore, Storage, dan Auth juga tidak ditegakkan. Untuk menyalakan: rilis lewat Google Play, tautkan Play Integrity, bangun dengan `APP_CHECK=true`, pantau metrik App Check, baru ubah `enforceAppCheck` dan enforcement di konsol. APK di luar Google Play akan ditolak setelah itu |
| **Wilayah** | Firestore, bucket Storage `sabusaku.firebasestorage.app`, dan Cloud Functions di `asia-southeast2` (Jakarta). Firebase Authentication, Cloud Messaging (FCM), dan Crashlytics adalah layanan global Google, tidak terikat wilayah |
| **Storage** | `schools/{s}/avatars/{uid}.jpg`: tulis hanya pemilik. `schools/{s}/programCovers/{uid}/…`: tulis/hapus hanya siswa pemilik folder. Keduanya `image/*`, < 1 MB, baca hanya anggota sekolah. `books/{bookId}/…`: unggah hanya guru (sekolah mana pun), `image/*`, < 1 MB, baca anggota sekolah mana pun, tidak bisa dihapus dari klien. Selain itu tertutup |
| **Functions** | Setiap callable memeriksa claim `role`/`schoolId` dari `request.auth` (`claimAccount` memeriksa `email_verified`), memvalidasi input (skema), membatasi ukuran batch, dan menulis log audit sederhana (`auditLogs` di sisi server saja). `reportContent` membatasi 20 laporan per pelapor dalam 24 jam |
| **Analytics** | Firebase Analytics dihapus di 1.2.1 (dependensi, import, dan meta-data `google_analytics_*` di manifest). Tidak ada statistik pemakaian dan tidak ada lokasi. Izin `AD_ID`/ADSERVICES tetap dicabut dengan `tools:node="remove"`. Crashlytics tetap ada, hanya untuk build rilis yang memakai produksi (`lib/bootstrap.dart`) |
| **Rahasia** | Tidak ada kunci rahasia di klien. Skrip developer memakai service account lokal yang tidak masuk repositori |
| **Pemisahan lingkungan** | Satu project produksi `sabusaku`. Tes otomatis memakai Firebase Emulator secara lokal; tidak ada project dev atau sekolah demo |
| **Backup** | Aktif di prod (dicek 17 Oktober 2026): *point-in-time recovery* Firestore 7 hari dan jadwal backup harian dengan retensi 7 hari. Halaman `/hapus-data` menyebut salinan cadangan terhapus paling lama 7 hari; ubah halaman itu bila retensi berubah |
| **Pembatasan penyalahgunaan** | Batas panjang teks dan ukuran batch; Firestore dan Auth sudah membatasi percobaan login berulang |

## 5. Privasi dan kepatuhan (siswa di bawah 18 tahun)

Ini bukan nasihat hukum; konfirmasikan dengan pihak sekolah/konsultan hukum sebelum rilis.

- Posisi yang disarankan: **sekolah sebagai pengendali data, aplikasi sebagai pemroses**. Persetujuan orang tua/wali ditangani sekolah (mis. lewat formulir sekolah), dan sekolah yang mendaftarkan email siswa.
- **Peringkat:** siswa melihat nama, kelas, ekstrakurikuler, serta jumlah buku selesai, streak, dan hari membaca teman sesekolahnya (keputusan 18 Okt 2026). Dokumen `leaderboards` sengaja tidak memuat email, foto, status, atau isi jurnal; profil dan `studentStats` siswa lain tetap tertutup.
- **Minimisasi data:** nama, email, kelas, ekstrakurikuler, foto profil dan foto cover opsional, isi jurnal, dan laporan. Tidak ada NIS, lokasi (juga perkiraan), kontak, statistik pemakaian, atau pelacak iklan. Laporan kerusakan Crashlytics tidak boleh menyertakan nama, email, atau isi jurnal (jangan memanggil `setUserIdentifier`/`log` dengan data itu).
- Penanggung jawab hanya melihat siswa sekolahnya sendiri.
- **Penghapusan data:** `eraseStudent` (penanggung jawab) menghapus keanggotaan, profil, `studentStats`, baris siswa di semua `leaderboards`, `programs` beserta jurnal dan komentarnya, foto profil, dan foto cover milik siswa beserta rujukannya di usulan (`forgetStudentCovers`), tanpa menghapus akun Auth milik siswa. `deleteMyAccount` (Profil → Hapus akun, wajib Google Play karena akun dibuat di aplikasi) menghapus data yang sama lalu akun Auth. Keduanya memanggil `forgetReports`: laporan yang dikirim orang itu dihapus, laporan tentang dia tinggal tanpa salinan konten (`snapshot = {}`, `targetDeleted = true`). `removeStudent` mencabut akses dan mengeluarkan siswa dari semua `leaderboards`; jurnalnya tetap. Buku dan cover yang sudah diterima ke katalog, serta riwayat katalog yang memuat nama penanggung jawab, tetap ada (dijelaskan di `/hapus-data`).
- **Retensi:** tentukan bersama sekolah (usulan: data siswa dihapus/diarsipkan 1 tahun setelah lulus).
- **Dokumen publik** (`hosting/`, https://sabusaku.web.app): `/privasi` (kebijakan privasi), `/ketentuan` (ketentuan penggunaan), `/hapus-data` (penghapusan akun dan data untuk formulir *Data safety*). Ubah halaman itu bersama perubahan data yang dikumpulkan; jawaban Play Console ada di `store/listing.md`. Periksa kebijakan Google Play terbaru untuk aplikasi yang melibatkan remaja.

## 6. Daftar kasus uji rules (wajib, otomatis di CI)

Gunakan `@firebase/rules-unit-testing` dengan Firebase Emulator. Minimal:

**Isolasi**
1. Siswa sekolah A tidak bisa membaca apa pun di sekolah B.
2. Penanggung jawab sekolah A tidak bisa membaca `studentStats`, program, jurnal, komentar, `members` sekolah B.
3. Siswa tidak bisa membaca `members`, profil siswa lain, atau `studentStats` siswa lain.
4. Pengguna tanpa claim (atau claim `role` salah) ditolak di semua koleksi.

**Jurnal**
5. Membuat jurnal hari ini: lolos. Kemarin dan 2 hari lalu: lolos. 3 hari lalu dan besok: ditolak.
6. Membuat jurnal kedua pada tanggal yang sama: ditolak.
7. `pageEnd > totalPages`, `pageEnd < pageStart`, `keyInformation` 29 karakter: ditolak.
8. Siswa lain menulis ke jurnal siswa: ditolak.
9. Edit jurnal tanggal H−1: lolos; H−2: ditolak. Hapus mengikuti aturan yang sama.
10. Siswa menulis `currentPage`, `streakCurrent`, `hasUnreadTeacherComment: true`: ditolak.
11. Tulis ke program berstatus `completed`/`stopped`: ditolak.

**Program**
12. Membuat program kedua saat masih ada yang aktif: ditolak (batch gagal).
13. Membuat program dengan `currentPage` ≠ 0: ditolak.
14. Tandai selesai saat `currentPage < totalPages`: ditolak.
15. Perpanjang target dua kali: ditolak.

**Komentar & akun**
16. Penanggung jawab sekolah siswa membuat komentar: lolos. Penanggung jawab sekolah lain: ditolak. Siswa membuat komentar: ditolak.
17. Guru mengubah komentar guru lain: ditolak.
18. Pengguna mengubah `role`, `email`, `status`: ditolak. Siswa mengubah `classId` ke label yang ada: lolos; ke label yang tidak ada: ditolak. Ekskul di luar daftar sekolah: ditolak.
19. Penanggung jawab mengubah nama/kelas siswa: lolos; mengubah profil penanggung jawab lain: ditolak. Penanggung jawab mengisi `homeroomClass` miliknya dengan kelas terdaftar atau `null`: lolos; kelas tak terdaftar, siswa, atau milik orang lain: ditolak. Undangan guru yang belum masuk: nama/wali kelas/ekskul boleh diubah guru sekolahnya; `classId`, nama kosong, dan guru sekolah lain ditolak. `schools.staff` tidak bisa ditulis klien.
20. `claimAccount` dengan email belum terverifikasi: ditolak; email tidak terdaftar: `not-found`.
21. `addStudents` dengan email yang sudah terdaftar di sekolah lain: baris ditolak tanpa menyebut sekolah lain.
22. Siswa yang dikeluarkan: claims hilang, akun Auth tetap ada, data jurnal tetap ada.
23. Storage: avatar milik orang lain atau > 1 MB atau bukan gambar: ditolak; anggota sekolah lain tidak bisa membaca.

**Katalog, ketentuan, laporan**
24. Anggota sekolah mana pun membaca `books`, riwayat, dan `catalog`; tidak ada klien (termasuk guru) yang menulisnya langsung.
25. `bookSuggestions` dibaca guru sekolah mana pun, tidak oleh siswa. `bookStats` hanya untuk anggota sekolahnya.
26. Guru mengubah `recommendedBooks` sekolahnya; daftar tidak valid, siswa, dan guru sekolah lain ditolak.
27. Program dari katalog: `bookId` yang ada dengan cover Storage diterima; `bookId` yang tidak ada, cover dari luar Storage, atau field asing ditolak.
28. Storage cover siswa: hanya di folder sendiri, gambar < 1 MB, dibaca anggota sekolahnya saja. Cover katalog: guru sekolah mana pun mengunggah, anggota mana pun membaca, siswa dan hapus ditolak.
29. Klien tidak bisa menulis `termsVersion` atau `termsAcceptedAt` (pemilik maupun penanggung jawab).
30. `reports`: guru membaca laporan yang `schools`-nya memuat sekolahnya; guru sekolah lain dan semua siswa (termasuk pelapornya) ditolak; klien tidak bisa membuat, mengubah, atau menghapus laporan.

**Peringkat**
31. `leaderboards`: siswa dan guru sekolahnya membaca satu periode (juga periode yang belum ada); sekolah lain, tanpa claim, dan peran salah ditolak; `list` ditolak; tidak ada klien yang menulis atau menghapus.

Alur callable (`reportContent`, `resolveReport`, `acceptTerms`, `forgetReports`) diuji di `functions/test/integration/reports_flow.test.ts`; `addTeacher`/`removeTeacher` dan `schools.staff` di `members_flow.test.ts`; `statusChangedAt` dan `teacherDigest` di `digest_flow.test.ts`; baris `leaderboards` (jurnal, buku selesai, siswa dikeluarkan, refresh harian) di `reading_flow.test.ts`; `monthlyRecap` di `recap_flow.test.ts`.

Catatan teknis untuk pengujian: simulasikan waktu server dengan mengatur jam pada test (atau menulis jurnal dengan ID tanggal relatif terhadap tanggal sistem saat tes berjalan) dan uji khusus batas tengah malam WIB (23:59 vs 00:01).

## 7. Kepatuhan kebijakan Konten Buatan Pengguna (UGC) Google Play

Jurnal, ulasan, komentar, foto profil, foto cover, usulan buku, dan suntingan katalog adalah konten buatan pengguna. Walau Sabu Saku hanya dipakai di dalam sekolah dan katalognya dibagi antarsekolah, kebijakan UGC Google Play tetap meminta (1) persetujuan ketentuan sebelum pengguna membuat atau mengunggah konten, (2) pelaporan konten dan pengguna dari dalam aplikasi, dan (3) moderasi yang berjalan terus. Cara Sabu Saku memenuhinya:

| Syarat | Implementasi |
|---|---|
| Ketentuan yang melarang konten tidak pantas | `/ketentuan`: konten yang dilarang, cara melapor, moderasi dan sanksi, katalog bersama |
| Disetujui sebelum membuat konten | Gerbang `/ketentuan` sebelum Lengkapi akun dan area peran; `acceptTerms` mencatat `termsVersion` dan `termsAcceptedAt` (§1) |
| Pelaporan di aplikasi | Menu "Laporkan" pada komentar (dan penulisnya), jurnal (guru), buku, saran (guru), dan siswa (guru), lewat `reportContent`. Alasan: konten tidak pantas, pelecehan atau perundungan, data pribadi, hak cipta, data buku salah, lainnya |
| Moderasi oleh sekolah | Penanggung jawab membuka Sekolah → Laporan (`/guru/sekolah/laporan`), melihat laporan terbuka dan selesai, membuka kontennya, bertindak, lalu "Tandai selesai" (`resolveReport`). Tindakan yang tersedia: hapus komentar sendiri, ubah atau hapus lunak buku katalog, tolak usulan, ubah profil siswa, keluarkan siswa (`removeStudent`), hapus data siswa (`eraseStudent`) |
| Moderasi oleh pengembang | `functions/tools/reports.ts --list [--status open\|resolved\|all] [--school id]` untuk semua sekolah, `--resolve <id> --note "…"` (tercatat "Pengembang"). Pengembang menindak lewat Admin SDK: hapus konten, hapus akun, `remove-guru.ts`, `set-school-status.ts`. Jalankan `--list` secara berkala (mis. tiap minggu) supaya laporan yang tidak ditangani sekolah, laporan tentang penanggung jawab, dan laporan katalog tetap tertangani |
| Penyalahgunaan laporan | Maks 20 laporan per pelapor per 24 jam; konten atau akun sendiri tidak bisa dilaporkan |

Risiko yang tersisa:
- Belum ada fitur blokir pengguna. Interaksi hanya antara siswa dan penanggung jawab sekolahnya (komentar), sehingga ditangani lewat laporan dan tindakan sekolah.
- Laporan memuat nama pelapor dan bisa dibaca semua penanggung jawab sekolah itu, termasuk penanggung jawab yang dilaporkan. Halaman `/ketentuan` menyarankan email langsung ke pengembang untuk kasus seperti ini.
- Tidak ada notifikasi laporan baru ke penanggung jawab atau pengembang; jumlah laporan terbuka tampil di kartu Sekolah → Laporan.
