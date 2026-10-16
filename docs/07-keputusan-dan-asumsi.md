# 07 — Keputusan, Asumsi, dan Pertanyaan Tersisa

## 0. Keputusan saat implementasi (7 Oktober 2026)

Bagian ini mengalahkan isi dokumen 01–07 bila berbeda.

| Topik | Di dokumen | Yang dipakai |
|---|---|---|
| Lingkungan (A13) | Dua proyek Firebase + flavor dev/prod | Satu proyek `sabusaku` sebagai produksi. Pengembangan dan tes otomatis memakai Firebase Emulator (`--dart-define=USE_EMULATORS=true`). Tanpa flavor |
| ID aplikasi (Q1) | `id.sabusaku.app` | `com.sabu.saku`, sudah terkunci di Play Console |
| Jalur distribusi (Q2) | — | Google Play |
| Email semu | `{username}@{kode}.sabusaku.app` | `{username}@{kode}.sabusaku.invalid`. TLD `.invalid` tidak akan pernah bisa menerima email, sehingga email reset password (yang bisa dipicu siapa pun pemegang API key) tidak pernah sampai ke pihak mana pun |
| Asumsi A1–A12, Q3–Q7 | Usulan | Ikut usulan |
| Fitur Could (Q9, Q10) | Rekap + CSV, pengingat harian, mode gelap | Tidak dikerjakan di V1 |
| Paket | Remote Config, `connectivity_plus`, `flutter_local_notifications`, `fake_cloud_firestore` | Tidak dipakai. Channel notifikasi dibuat native; notifikasi saat aplikasi terbuka tampil sebagai banner dalam aplikasi |
| Skrip developer | `tools/` di akar | `functions/tools/` (berbagi `node_modules` dan kode dengan Functions) |
| Urutan M3/M4 | UI siswa dulu | Perhitungan server dulu, UI siswa langsung memakai `studentStats` |
| App Check | Aktif dengan Play Integrity | Terpasang tetapi hanya aktif bila di-build dengan `--dart-define=APP_CHECK=true`. Sebelum aplikasi didistribusikan lewat Google Play dan Play Integrity tertaut, permintaan token gagal lambat dan menunda login pertama sekitar 20 detik. Enforcement di server belum dinyalakan |
| Model | `freezed` + `json_serializable` | `freezed` saja; dokumen Firestore dipetakan manual (`fromMap`) |

### 16 Oktober 2026: login email/Google, tanpa admin, label kelas dan ekstrakurikuler

Bagian ini mengalahkan baris di atas dan dokumen 01–06 bila berbeda.

| Topik | Sebelumnya | Yang dipakai |
|---|---|---|
| Login | Kode sekolah + username/NIS + password, email semu `.invalid` | **Email + password** atau **Masuk dengan Google**. Tanpa kode sekolah, NIS, NISN, dan email semu |
| Pembuatan akun | Admin membuat akun dengan password awal acak | Pengguna membuat akun sendiri (Google, atau daftar email + verifikasi email). Akses data hanya bila emailnya ada di `members/{email}`; dipasang lewat callable `claimAccount` |
| Email tak terdaftar | — | Pop-up "Harap Menghubungi Administrator Sekolah" dengan tautan ke `sabusaku.web.app/daftar-sekolah`, lalu keluar |
| Akun Google | — | Wajib membuat password di layar Lengkapi akun (agar bisa masuk dengan email + password juga) |
| Lupa password | Minta admin/guru mereset | Email reset Firebase (template Indonesia, pengirim "Sabu Saku") |
| Simpan password | — | `AutofillGroup` + `finishAutofillContext()` memicu tawaran simpan password Android |
| Peran | admin, guru, siswa | **guru** (penanggung jawab) dan **siswa**. Admin dihapus |
| Sekolah dan penanggung jawab | `create-school` membuat admin pertama | Hanya developer, lewat `create-school`, `add-guru`, `remove-guru`. Guru tidak bisa menambah guru lain |
| Akses guru | Kelas yang ditugaskan (claim `classIds`) | Semua siswa di sekolahnya. Claims hanya `{role, schoolId}` |
| Kelas | Dokumen `classes/{id}` dikelola admin | **Label** di `schools.classes` (format `XII-A1`, `X-G2`), ditambah guru. Satu siswa tepat satu kelas; siswa boleh ganti sendiri |
| Ekstrakurikuler | — | **Label** di `schools.extracurriculars` (awal Masis-KIR, Paskibra, Pala, PMR). Siswa ikut nol atau lebih, boleh ganti sendiri |
| Satu email satu sekolah | — | Dijamin ID dokumen `members/{email}` |
| Tambah siswa | Admin: CSV/manual dengan username | Guru: email wajib, nama/kelas/ekskul opsional; siswa tanpa data lengkap diarahkan ke Lengkapi akun saat masuk |
| Keluarkan siswa | Nonaktifkan akun | `removeStudent`: akses dicabut, akun Auth dan jurnal tetap. `eraseStudent`: data sekolah dihapus, akun Auth tetap |
| Hapus akun | Lewat sekolah/email | Juga dari aplikasi: Profil → Hapus akun (`deleteMyAccount`), wajib Google Play karena akun kini dibuat di aplikasi |
| Foto profil | Tidak ada | Opsional, Cloud Storage `schools/{s}/avatars/{uid}.jpg`. Akun Google tanpa foto memakai foto Google; foto yang ada tidak ditimpa |
| Lingkungan | Produksi + emulator, sekolah demo | **Langsung produksi**. Tidak ada project dev dan sekolah demo; data lama direset setelah diekspor. Emulator hanya untuk tes otomatis lokal |
| Sekolah awal | Demo | SMA Negeri 1 Sukodadi: 2 penanggung jawab (pembina Masis-KIR dan akun uji developer), 20 siswa ekstrakurikuler Masis-KIR, dimasukkan ke `members` sebelum mereka login |
| SHA Android | Debug + upload | Ditambah SHA-1 dan SHA-256 kunci **Play App Signing**, sehingga Masuk dengan Google bekerja di build dari Google Play |
| Pendaftaran sekolah | Email di halaman utama | Halaman `daftar-sekolah` dengan formulir yang membuka aplikasi email (mailto) ke benevology@gmail.com. Pengiriman lewat server menyusul |
| Aturan password | Minimal 8 karakter | Minimal 8 karakter, huruf besar dan kecil, angka, dan karakter khusus. Form menampilkan tiap syarat yang langsung hijau saat terpenuhi (hanya di kolom password, tidak di Ulangi password). Kebijakan yang sama dipaksakan Firebase Auth (Identity Platform, `ENFORCE`); password lama tetap bisa dipakai masuk |

## 1. Keputusan yang sudah Anda tetapkan

| # | Topik | Keputusan |
|---|---|---|
| 1 | Cakupan | Banyak sekolah; sekolah **didaftarkan developer**; tiap sekolah punya peran admin, guru, siswa |
| 2 | Jenjang | SMA dahulu |
| 3 | Pembuatan akun | Admin: impor CSV, reset password oleh admin atau guru |
| 4 | Buku bulan ini | **Siswa memilih bebas** |
| 5 | Guru | **Satu guru memantau banyak kelas** |
| 6 | Isi jurnal mundur | Maks 2 hari ke belakang; edit sampai H+1 |
| 7 | Streak | Hari libur tidak memutus streak |
| 8 | Ambang status | Aktif ≤ 3 hari, Perlu perhatian 4–7, Tidak aktif > 7 |
| 9 | Buku belum selesai saat bulan berganti | Boleh diperpanjang/diteruskan |
| 10 | Platform | Android saja, dashboard guru juga Android |
| 11 | Bahasa | Indonesia saja |
| 12 | Notifikasi komentar | Masuk V1 |
| 13 | Tab Refleksi + Profil | Digabung menjadi **Profil** |
| — | Teknologi | Flutter, Firebase Blaze (BaaS penuh); sumber daya tidak jadi pembatas |
| — | Aset | Logo SVG, ikon aplikasi, splash dengan nama |

## 2. Asumsi yang saya ambil (ubah bila tidak sesuai)

Semua ini sudah tertulis di PRD/rules. Yang bertanda ⚠ paling layak Anda tinjau.

| # | Asumsi | Dampak bila diubah |
|---|---|---|
| A1 | ⚠ **Admin sekolah tidak dapat membaca isi jurnal**, hanya statistik (v2: peran admin dihapus) | Jika admin perlu membaca: tambah aturan baca di rules + layar admin |
| A2 | ⚠ Siswa **boleh menghapus** jurnal sendiri, tetapi hanya dalam jendela edit (H+1) | Jika tidak boleh: hapus aturan `delete` |
| A3 | Hanya *Informasi penting* yang wajib (≥ 30 karakter); *Hal menarik* dan *Pertanyaan* opsional | Jika semua wajib: ubah `validJournalContent` dan form |
| A4 | Hari **Minggu netral** (tidak memutus streak, tidak dihitung ambang) selain tanggal libur yang diisi admin | Jika Sabtu juga netral: ubah `settings.neutralWeekdays` (tanpa kode) |
| A5 | Ambang status dihitung dalam **hari efektif** (bukan hari kalender) | Perubahan hanya di `computeStatus` |
| A6 | Perpanjangan target **sekali**, maks 31 hari; buku tetap aktif walau terlambat; tidak ada penutupan otomatis | Dapat ditambah penutupan otomatis lewat `dailyRefresh` |
| A7 | Satu siswa = satu buku aktif; selesai hanya saat progres 100% (ulasan akhir opsional) | Bila boleh selesai di <100%: ubah syarat `completed` |
| A8 | Komentar guru berupa daftar komentar (bukan satu komentar tunggal), siswa tidak membalas | Balasan siswa = fitur chat, di luar V1 |
| A9 | Sampul buku otomatis (tanpa upload dan tanpa pencarian buku) | Upload/Google Books ada di daftar "belum ada" |
| A10 | Siswa memakai 4 tab: Beranda, Buku, Jurnal, Profil; guru 3 tab; admin 4 tab | Murni UI |
| A11 | Kelas dikelola admin; pindah/naik kelas manual lewat `moveStudentClass` (v2: kelas berupa label, ganti kelas ditulis langsung ke profil) | Naik kelas massal (akhir tahun ajaran) dapat ditambahkan di M2 jika perlu |
| A12 | Wilayah data Jakarta (`asia-southeast2`) | Tidak dapat diubah setelah database dibuat |
| A13 | Dibuat dua lingkungan Firebase: `dev` dan `prod` | Diganti: satu project produksi |

## 3. Pertanyaan tersisa (tidak menghambat perencanaan, tetapi perlu sebelum M0/M7)

Jawab singkat saja; tulis "ikut usulan" bila setuju.

| # | Pertanyaan | Usulan saya |
|---|---|---|
| Q1 | **ID aplikasi Android** (`applicationId`) dan nama pengembang/penerbit | `id.sabusaku.app` (dev: `id.sabusaku.app.dev`); nama penerbit Anda |
| Q2 | **Jalur distribusi:** Google Play (internal/closed testing → produksi) atau APK langsung ke sekolah? Ini memengaruhi App Check (Play Integrity) | Google Play |
| Q3 | Daftar **hari libur nasional/sekolah**: admin mengisi manual, atau saya sertakan daftar bawaan tahun ajaran berjalan? | Admin mengisi manual (daftar bawaan mudah basi) |
| Q4 | Format **CSV impor**: kolom yang tersedia di sekolah (mis. NIS, nama, kelas)? Apakah NIS selalu unik dalam satu sekolah? | Kolom: `peran,nama,username,kelas`; untuk siswa username = NIS |
| Q5 | **Retensi data** setelah siswa lulus | Hapus/arsip 1 tahun setelah lulus (sesuaikan dengan sekolah) |
| Q6 | Apakah guru boleh **reset password siswa** di kelasnya (saya asumsikan ya)? | Ya |
| Q7 | **Tahun ajaran**: apakah perlu "ganti tahun ajaran" massal (arsipkan kelas lama, naikkan siswa)? | Tunda sampai setelah uji coba |
| Q8 | Nama/domain untuk **kebijakan privasi** dan halaman penghapusan data (diperlukan Play Console) | Halaman statis sederhana, dapat saya buatkan |
| Q9 | **Mode gelap** di V1? | Tidak (Could) |
| Q10 | Perlu **ekspor rekap** (CSV/PDF) di V1 atau setelah uji coba? | CSV di M6 bila waktu; PDF setelah V1 |

## 4. Hal yang belum diverifikasi

- `firebase/firestore.rules` **belum dijalankan di emulator** (lingkungan ini tidak memiliki emulator). Perilaku fungsi tanggal (`timestamp.date`, `int()`, pembagian) dan kombinasi `getAfter`/`existsAfter` perlu dipastikan lewat tes (dokumen 03 §6).
- Estimasi roadmap bersifat perkiraan; versi paket dan batas Firebase mengikuti dokumentasi resmi saat proyek dimulai.
- Perilaku App Check Play Integrity untuk APK non-Play perlu dicek di dokumentasi Firebase terbaru sebelum memutuskan jalur distribusi.
