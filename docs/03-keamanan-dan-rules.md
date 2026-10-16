# 03 — Keamanan, Autentikasi, dan Security Rules

Berkas terkait: `firestore.rules`, `storage.rules`, `firestore.indexes.json`. Diperbarui 16 Oktober 2026 untuk model v2.

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

## 2. Model otorisasi

| Data | Siswa | Penanggung jawab (guru) |
|---|---|---|
| Profil sendiri | baca; ubah nama, kelas, ekskul, foto | baca; ubah nama, foto |
| Profil siswa sekolahnya | — | baca semua; ubah nama, kelas, ekskul |
| `members` sekolahnya | — | baca; ubah siswa yang belum masuk |
| `studentStats` | miliknya | semua di sekolahnya |
| `programs`, `journals` | miliknya (tulis dalam aturan BR) | baca semua di sekolahnya |
| `comments` | baca miliknya | buat/ubah/hapus miliknya |
| `schools` (`settings`, `classes`, `extracurriculars`) | baca | ubah |
| Foto profil (Storage) | tulis miliknya, baca sekolahnya | tulis miliknya, baca sekolahnya |

Peran admin sekolah dihapus. Menambah sekolah dan penanggung jawab hanya lewat skrip developer. Menambah, mengeluarkan, dan menghapus data siswa lewat callable (`addStudents`, `removeStudent`, `eraseStudent`). Claims, `status`, `email`, dan angka turunan **hanya** ditulis Functions.

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

### Pola query yang harus dipatuhi klien (karena "rules bukan filter")
- Siswa: `programs where studentId == uid`; jurnal dibaca per program.
- Penanggung jawab: `studentStats orderBy name`, `programs where studentId == S`, `members where schoolId == S where role == siswa`.
- **Tidak memakai collection-group query** untuk `journals`/`comments`.

### Catatan perilaku offline
Jurnal ditulis offline akan dikirim saat online. Bila tanggal jurnal sudah melewati batas BR-3 pada saat sinkron (mis. diketik Senin, tersinkron Kamis), server menolaknya. Klien harus mendengarkan kegagalan tulis tertunda dan menampilkan "Jurnal belum terkirim" beserta alasannya, bukan diam-diam.

## 4. Lapisan keamanan lain

| Lapisan | Rencana |
|---|---|
| **App Check** | Provider Play Integrity untuk Firestore, Functions, dan Auth; provider debug untuk emulator/dev. **Perlu keputusan distribusi:** jika aplikasi dibagikan sebagai APK langsung (bukan dari Google Play), verifikasi Play Integrity bisa menolak instalasi tersebut. Verifikasi perilakunya di dokumentasi Firebase sebelum menyalakan enforcement |
| **Wilayah** | Firestore dan Functions di `asia-southeast2` (Jakarta) |
| **Storage** | `schools/{s}/avatars/{uid}.jpg`: tulis hanya pemilik, `image/*`, < 1 MB; baca hanya anggota sekolah |
| **Functions** | Setiap callable memeriksa claim `role`/`schoolId` dari `request.auth` (`claimAccount` memeriksa `email_verified`), memvalidasi input (skema), membatasi ukuran batch, dan menulis log audit sederhana (`auditLogs` di sisi server saja) |
| **Rahasia** | Tidak ada kunci rahasia di klien. Skrip developer memakai service account lokal yang tidak masuk repositori |
| **Pemisahan lingkungan** | Satu project produksi `sabusaku`. Tes otomatis memakai Firebase Emulator secara lokal; tidak ada project dev atau sekolah demo |
| **Backup** | Aktifkan *scheduled backups* Firestore (harian) dan *point-in-time recovery* di prod |
| **Pembatasan penyalahgunaan** | Batas panjang teks dan ukuran batch; Firestore dan Auth sudah membatasi percobaan login berulang |

## 5. Privasi dan kepatuhan (siswa di bawah 18 tahun)

Ini bukan nasihat hukum; konfirmasikan dengan pihak sekolah/konsultan hukum sebelum rilis.

- Posisi yang disarankan: **sekolah sebagai pengendali data, aplikasi sebagai pemroses**. Persetujuan orang tua/wali ditangani sekolah (mis. lewat formulir sekolah), dan sekolah yang mendaftarkan email siswa.
- **Minimisasi data:** nama, email, kelas, ekstrakurikuler, foto profil opsional, dan isi jurnal. Tidak ada NIS, lokasi, kontak, atau pelacak iklan. Analytics tidak boleh menyertakan nama/email/isi jurnal.
- Penanggung jawab hanya melihat siswa sekolahnya sendiri.
- **Penghapusan data:** `eraseStudent` (penanggung jawab) menghapus keanggotaan, profil, `studentStats`, `programs` beserta jurnal dan komentarnya, dan foto profil, tanpa menghapus akun Auth milik siswa. `deleteMyAccount` (Profil → Hapus akun, wajib Google Play karena akun dibuat di aplikasi) menghapus data yang sama lalu akun Auth. `removeStudent` hanya mencabut akses.
- **Retensi:** tentukan bersama sekolah (usulan: data siswa dihapus/diarsipkan 1 tahun setelah lulus).
- **Dokumen yang perlu disiapkan sebelum rilis:** kebijakan privasi (Bahasa Indonesia), halaman penghapusan data untuk formulir *Data safety* Google Play, dan pernyataan target audiens aplikasi di Play Console (pengguna remaja). Periksa kebijakan Google Play terbaru untuk aplikasi yang melibatkan anak/remaja.

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
19. Penanggung jawab mengubah nama/kelas siswa: lolos; mengubah profil penanggung jawab lain: ditolak.
20. `claimAccount` dengan email belum terverifikasi: ditolak; email tidak terdaftar: `not-found`.
21. `addStudents` dengan email yang sudah terdaftar di sekolah lain: baris ditolak tanpa menyebut sekolah lain.
22. Siswa yang dikeluarkan: claims hilang, akun Auth tetap ada, data jurnal tetap ada.
23. Storage: avatar milik orang lain atau > 1 MB atau bukan gambar: ditolak; anggota sekolah lain tidak bisa membaca.

Catatan teknis untuk pengujian: simulasikan waktu server dengan mengatur jam pada test (atau menulis jurnal dengan ID tanggal relatif terhadap tanggal sistem saat tes berjalan) dan uji khusus batas tengah malam WIB (23:59 vs 00:01).
