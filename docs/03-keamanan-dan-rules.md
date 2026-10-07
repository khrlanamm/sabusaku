# 03 — Keamanan, Autentikasi, dan Security Rules

Berkas terkait: `firebase/firestore.rules` (draft), `firebase/firestore.indexes.json`.

## 1. Autentikasi

### Login username/NIS di atas Firebase Auth
Firebase Auth berbasis email, sedangkan siswa login dengan NIS. Solusinya **email semu yang deterministik**:

```
{username}@{kodeSekolah}.sabusaku.app      contoh: 12345678@sman1.sabusaku.app   (semua huruf kecil)
```

- Tidak ada email yang pernah dikirim, jadi domain tidak perlu dimiliki. Bila punya domain sendiri, pakai itu agar tidak ada pihak lain yang bisa memilikinya.
- Keunikan username per sekolah otomatis dijamin oleh keunikan email Auth.
- Layar login: **Kode Sekolah** (disimpan di perangkat setelah berhasil), **Username/NIS**, **Password**. Pesan galat dibuat seragam ("Kode sekolah, username, atau password salah") agar tidak membocorkan akun mana yang ada.
- Provider yang diaktifkan hanya Email/Password. Pendaftaran mandiri dimatikan secara praktik: klien tidak punya jalur membuat akun (pembuatan lewat Admin SDK di Cloud Functions).
- **Lupa password:** tidak ada reset lewat email. Admin atau guru (untuk siswa di kelasnya) memanggil `resetPassword`, menghasilkan password sementara dan `mustChangePassword = true`.

### Custom claims
Diatur oleh Cloud Functions saat akun dibuat atau penugasan kelas berubah:

| Claim | Nilai |
|---|---|
| `role` | `admin` · `guru` · `siswa` |
| `schoolId` | kode sekolah |
| `classIds` | hanya guru, maks 20 ID pendek |

Setelah claim berubah, klien memanggil `getIdToken(true)` (saat aplikasi dibuka dan saat menerima pesan FCM bertipe `claims_changed`). Menonaktifkan akun memanggil `revokeRefreshTokens`; ID token yang sudah terbit tetap berlaku sampai kedaluwarsa (maks sekitar 1 jam). Ini batas yang diterima pada V1.

### Kebijakan password
Minimal 8 karakter (aktifkan *password policy* di Firebase Auth). Password awal dibuat acak dan ditampilkan sekali ke admin untuk dibagikan (atau diekspor sebagai CSV yang dibagikan lewat share sheet Android). Pengguna wajib menggantinya di login pertama.

## 2. Model otorisasi

| Data | Siswa | Guru | Admin |
|---|---|---|---|
| Profil sendiri | baca | baca | baca |
| Daftar pengguna sekolah | — | — | baca |
| `studentStats` | miliknya | kelas yang ditugaskan | semua (tanpa isi jurnal) |
| `programs`, `journals` | miliknya (tulis dalam aturan BR) | baca kelas yang ditugaskan | **tidak ada akses** |
| `comments` | baca miliknya | buat/ubah/hapus miliknya di kelasnya | tidak ada akses |
| `classes` | baca | baca | CRUD (kecuali `teacherIds`) |
| `schools.settings` | baca | baca | ubah |

Semua jalur tulis yang menyentuh peran, kelas, status akun, claim, dan angka turunan **hanya** lewat Cloud Functions.

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
| BR-14 isolasi | Pemeriksaan `schoolId` pada path dan `classIds` pada claim |

### Pola query yang harus dipatuhi klien (karena "rules bukan filter")
- Siswa: `programs where studentId == uid`; jurnal dibaca per program.
- Guru: `studentStats where classId == X` dan `programs where studentId == S where classId == X`, satu kelas per query.
- **Tidak memakai collection-group query** untuk `journals`/`comments`.

### Catatan perilaku offline
Jurnal ditulis offline akan dikirim saat online. Bila tanggal jurnal sudah melewati batas BR-3 pada saat sinkron (mis. diketik Senin, tersinkron Kamis), server menolaknya. Klien harus mendengarkan kegagalan tulis tertunda dan menampilkan "Jurnal belum terkirim" beserta alasannya, bukan diam-diam.

## 4. Lapisan keamanan lain

| Lapisan | Rencana |
|---|---|
| **App Check** | Provider Play Integrity untuk Firestore, Functions, dan Auth; provider debug untuk emulator/dev. **Perlu keputusan distribusi:** jika aplikasi dibagikan sebagai APK langsung (bukan dari Google Play), verifikasi Play Integrity bisa menolak instalasi tersebut. Verifikasi perilakunya di dokumentasi Firebase sebelum menyalakan enforcement |
| **Wilayah** | Firestore dan Functions di `asia-southeast2` (Jakarta) |
| **Functions** | Setiap callable memeriksa claim `role`/`schoolId` dari `request.auth`, memvalidasi input (skema), membatasi ukuran batch, dan menulis log audit sederhana (`auditLogs` di sisi server saja) |
| **Rahasia** | Tidak ada kunci rahasia di klien. Skrip developer memakai service account lokal yang tidak masuk repositori |
| **Pemisahan lingkungan** | Proyek Firebase terpisah: `dev` dan `prod` |
| **Backup** | Aktifkan *scheduled backups* Firestore (harian) dan *point-in-time recovery* di prod |
| **Pembatasan penyalahgunaan** | Batas panjang teks dan ukuran batch; Firestore dan Auth sudah membatasi percobaan login berulang |

## 5. Privasi dan kepatuhan (siswa di bawah 18 tahun)

Ini bukan nasihat hukum; konfirmasikan dengan pihak sekolah/konsultan hukum sebelum rilis.

- Posisi yang disarankan: **sekolah sebagai pengendali data, aplikasi sebagai pemroses**. Persetujuan orang tua/wali ditangani sekolah (mis. lewat formulir sekolah), dan sekolah yang mendaftarkan akun.
- **Minimisasi data:** hanya nama, NIS, kelas, dan isi jurnal. Tidak ada foto, lokasi, kontak, atau pelacak iklan. Analytics tidak boleh menyertakan nama/NIS/isi jurnal.
- **Admin tidak dapat membaca isi jurnal** (hanya statistik); guru hanya kelas sendiri.
- **Penghapusan data:** callable `eraseStudent` (disediakan sebelum rilis) menghapus akun Auth, profil, `studentStats`, `programs` beserta jurnal dan komentarnya. Dipakai saat siswa lulus atau diminta sekolah.
- **Retensi:** tentukan bersama sekolah (usulan: data siswa dihapus/diarsipkan 1 tahun setelah lulus).
- **Dokumen yang perlu disiapkan sebelum rilis:** kebijakan privasi (Bahasa Indonesia), halaman penghapusan data untuk formulir *Data safety* Google Play, dan pernyataan target audiens aplikasi di Play Console (pengguna remaja). Periksa kebijakan Google Play terbaru untuk aplikasi yang melibatkan anak/remaja.

## 6. Daftar kasus uji rules (wajib, otomatis di CI)

Gunakan `@firebase/rules-unit-testing` dengan Firebase Emulator. Minimal:

**Isolasi**
1. Siswa sekolah A tidak bisa membaca apa pun di sekolah B.
2. Guru kelas 1 tidak bisa membaca `studentStats`, program, jurnal, komentar kelas 2.
3. Admin tidak bisa membaca `journals` dan `comments`.
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
16. Guru kelasnya membuat komentar: lolos. Guru kelas lain: ditolak. Siswa membuat komentar: ditolak.
17. Guru mengubah komentar guru lain: ditolak.
18. Pengguna mengubah `role`, `classId`, `status`: ditolak; mengubah `mustChangePassword` true→false miliknya: lolos.

Catatan teknis untuk pengujian: simulasikan waktu server dengan mengatur jam pada test (atau menulis jurnal dengan ID tanggal relatif terhadap tanggal sistem saat tes berjalan) dan uji khusus batas tengah malam WIB (23:59 vs 00:01).
