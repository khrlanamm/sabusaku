# 01 — PRD Sabu Saku (Satu Bulan Satu Buku)

Versi dokumen: 1.0 · 7 Oktober 2026 · Status: usulan final untuk persetujuan

## 1. Ringkasan

Sabu Saku adalah aplikasi Android untuk **jurnal membaca**. Siswa SMA membaca satu buku per bulan dan mencatat hasil bacaan setiap hari. Guru memantau progres seluruh siswa di kelasnya dan memberi komentar pada jurnal. Satu aplikasi melayani banyak sekolah (multi-tenant); sekolah didaftarkan oleh developer, bukan lewat pendaftaran mandiri.

**Fokus V1** (dari gambar rancangan): memastikan siswa benar-benar bisa mengisi jurnal setiap hari dan guru bisa memantaunya dengan mudah.

### Tujuan
- Mencatat proses membaca harian yang bermakna (halaman, durasi, isi bacaan, refleksi).
- Membuat guru tahu siapa yang aktif, perlu perhatian, atau tidak aktif tanpa membuka satu per satu.
- Bekerja baik di jaringan buruk (jurnal bisa ditulis offline).

### Bukan tujuan V1
AI, rekomendasi buku, ranking/gamifikasi, upload foto, chat siswa–guru, analisis otomatis, integrasi Google Books, iOS, web, pendaftaran sekolah mandiri, pembayaran.

## 2. Peran dan hak akses

| Peran | Dibuat oleh | Dipakai lewat | Ringkasan hak |
|---|---|---|---|
| **Developer** | — | Skrip CLI (di luar aplikasi) | Membuat sekolah dan admin pertama, menonaktifkan sekolah |
| **Admin sekolah** | Developer | Aplikasi (menu admin) | Kelola kelas, guru, siswa, pengaturan sekolah; impor CSV; reset password. **Tidak membaca isi jurnal** |
| **Guru** | Admin | Aplikasi (menu guru) | Melihat siswa dan jurnal di **kelas yang ditugaskan (banyak kelas)**, memberi komentar, reset password siswa kelasnya |
| **Siswa** | Admin (impor CSV/manual) | Aplikasi (menu siswa) | Memilih buku bebas, mengisi dan melihat jurnal sendiri, membaca komentar guru |

Satu akun = satu peran, terikat ke satu sekolah. Data antar sekolah terisolasi total (lihat dokumen 03).

## 3. Alur utama

**Onboarding sekolah (developer):** `create-school` → sekolah + admin pertama dengan password awal → admin login, ganti password, membuat kelas, mengimpor guru dan siswa, menugaskan guru ke kelas.

**Login:** isi *Kode Sekolah* (diingat di perangkat), *Username/NIS*, *Password*. Aplikasi mengarahkan ke shell sesuai peran. Akun dengan password awal wajib ganti password di login pertama. "Lupa password" menampilkan petunjuk menghubungi admin/guru (tidak ada reset lewat email).

**Siswa:** login → Beranda → (jika belum ada buku) pilih buku → baca → Isi Jurnal → Simpan → lihat Riwayat → baca komentar guru (notifikasi masuk).

**Guru:** login → Dashboard → Daftar Siswa (filter kelas/status) → Detail Siswa → Detail Jurnal → tulis komentar.

## 4. Layar dan fitur (V1)

### Siswa — navigasi bawah 4 tab: Beranda · Buku · Jurnal · Profil
| Layar | Isi |
|---|---|
| Beranda | Sapaan, kartu buku bulan ini (cover, judul, halaman, persen), tombol **Isi Jurnal Hari Ini**, jurnal bulan ini (n/30), streak, badge komentar guru baru |
| Buku Saya | Detail buku aktif: total halaman, mulai, target, progres, tombol Perpanjang / Tandai Selesai / Hentikan. Jika belum ada buku: form **Mulai Buku** (judul, penulis, total halaman, opsional ISBN) |
| Isi Jurnal | Tanggal, halaman dari–sampai (otomatis lanjut dari halaman terakhir), durasi (4 pilihan), informasi penting (wajib), hal menarik (opsional), pertanyaan (opsional) |
| Riwayat Jurnal | Daftar jurnal (terbaru dulu), lencana komentar guru |
| Detail Jurnal | Isi jurnal + komentar guru; edit/hapus bila masih dalam jendela edit |
| Profil | Statistik (total jurnal, buku selesai, streak terbaik), **riwayat buku bulan-bulan sebelumnya**, ubah password, keluar |

Cover buku: tanpa upload di V1; aplikasi membuat **sampul otomatis** (warna dari judul + inisial).

### Guru — navigasi bawah 3 tab: Dashboard · Siswa · Profil
| Layar | Isi |
|---|---|
| Dashboard | Kartu ringkasan (siswa, buku aktif, jurnal bulan ini), jumlah Aktif / Perlu perhatian / Tidak aktif / Belum ada buku, daftar siswa yang perlu perhatian |
| Daftar Siswa | Filter kelas (dari kelas yang ditugaskan) dan status, pencarian nama, progres per siswa |
| Detail Siswa | Buku aktif, progres, streak, aktivitas terakhir, riwayat buku, **Lihat semua jurnal**, tombol reset password |
| Detail Jurnal + Komentar | Isi jurnal siswa, daftar komentar, kolom tulis komentar |
| Rekap *(opsional, fase 6)* | Rekap bulanan per kelas, ekspor CSV |

### Admin sekolah — navigasi bawah 4 tab: Beranda · Kelas · Pengguna · Pengaturan
| Layar | Isi |
|---|---|
| Beranda | Jumlah siswa/guru/kelas, siswa aktif vs tidak aktif (angka saja) |
| Kelas | Tambah/ubah kelas (mis. XII IPA 1, tahun ajaran), tugaskan guru ke kelas |
| Pengguna | Daftar guru dan siswa, tambah manual, **impor CSV**, nonaktifkan/aktifkan, pindah kelas, reset password, ekspor daftar kredensial awal |
| Pengaturan | Hari libur sekolah, hari netral (default Minggu), ambang status (default 3 dan 7 hari), data sekolah |

## 5. Aturan bisnis (final)

| # | Aturan |
|---|---|
| BR-1 | Satu siswa memiliki **maksimal satu buku aktif** pada satu waktu |
| BR-2 | **Satu jurnal per hari per buku** (ID dokumen = tanggal `yyyy-MM-dd`, dijamin di database) |
| BR-3 | Tanggal jurnal: hari ini sampai **2 hari ke belakang**, tidak boleh masa depan. Semua tanggal memakai **WIB (Asia/Jakarta)**, acuan waktu server |
| BR-4 | Jurnal boleh **diedit atau dihapus sampai akhir hari (23:59 WIB) setelah tanggal jurnal (H+1)**. Setelah itu terkunci. Tanggal tidak bisa diubah (hapus lalu buat ulang selama masih dalam jendela) |
| BR-5 | Halaman: `dari ≥ 1`, `sampai ≥ dari`, `sampai ≤ total halaman buku`. Halaman "dari" otomatis diisi `halaman terakhir + 1`; tumpang tindih (membaca ulang) diizinkan. Progres buku = **halaman tertinggi** yang pernah dicatat |
| BR-6 | Durasi: `< 15`, `15–30`, `30–60`, `> 60` menit |
| BR-7 | *Informasi penting* **wajib minimal 30 karakter** (maks 1000). *Hal menarik* dan *pertanyaan* opsional (maks 1000) |
| BR-8 | Buku: judul 2–120, penulis 2–80, total halaman 10–2000, ISBN opsional |
| BR-9 | Target selesai default = akhir bulan (WIB). Boleh **diperpanjang** satu kali sampai akhir bulan berikutnya. Setelah target lewat dan belum selesai, buku tetap aktif dengan label "Terlambat"; siswa bisa melanjutkan, menandai selesai, atau menghentikan |
| BR-10 | **Tandai selesai** hanya tersedia saat progres 100%, dengan ulasan akhir opsional. **Hentikan** tersedia kapan saja. Setelah selesai/dihentikan, siswa bebas memulai buku baru |
| BR-11 | **Hari efektif** = semua hari kecuali hari netral (default Minggu) dan hari libur sekolah. Hari netral tidak memutus streak dan tidak dihitung dalam ambang status |
| BR-12 | **Streak** = jumlah hari efektif berurutan yang punya jurnal sampai hari ini. Streak putus jika ada hari efektif **sebelum hari ini** tanpa jurnal. Jurnal di hari netral tetap menambah hitungan |
| BR-13 | **Status siswa** dari `d` = jumlah hari efektif sejak jurnal terakhir (atau sejak buku dimulai bila belum ada jurnal) sampai hari ini: **Aktif** `d ≤ 3`, **Perlu perhatian** `4–7`, **Tidak aktif** `> 7`, **Belum ada buku** bila tak ada buku aktif. Status hanya indikator, bukan nilai |
| BR-14 | Guru hanya melihat siswa dan jurnal di kelas yang ditugaskan. Admin tidak membaca isi jurnal |
| BR-15 | Akun nonaktif tidak bisa login; datanya tetap tersimpan |
| BR-16 | Password awal acak dan wajib diganti di login pertama; password minimal 8 karakter |
| BR-17 | Komentar guru: banyak komentar per jurnal; guru boleh mengubah/menghapus komentarnya sendiri; siswa hanya membaca. Komentar baru memicu notifikasi ke siswa |

Nilai BR-3, BR-4, BR-7 dikunci di aplikasi dan rules (bukan pengaturan sekolah) supaya konsisten. BR-11 dan BR-13 dapat diatur admin.

## 6. Kebutuhan non-fungsional
- **Platform:** Android saja (satu aplikasi untuk siswa, guru, admin). minSdk diputuskan saat setup (kandidat 23).
- **Bahasa:** Indonesia saja.
- **Offline:** siswa dapat menulis jurnal tanpa sinyal; data tersinkron saat online. Jurnal yang ditolak saat sinkron (mis. lewat batas BR-3) harus tampak jelas di UI.
- **Kinerja:** Beranda siswa dan Dashboard guru masing-masing dimuat dari 1–2 dokumen ringkasan, bukan menghitung ulang di klien.
- **Keamanan dan privasi:** siswa SMA umumnya di bawah 18 tahun dan jurnal bersifat personal. Isolasi per sekolah, akses minimum per peran, App Check, wilayah data Jakarta, jalur penghapusan data. Lihat dokumen 03.
- **Aksesibilitas:** ukuran sentuh ≥ 48dp, kontras AA, mendukung font besar sistem.
- **Observabilitas:** Crashlytics, Analytics tanpa data personal siswa, log Functions terstruktur.

## 7. Prioritas (MoSCoW)

- **Must:** login multi-sekolah, peran, kelas, impor CSV, mulai buku, isi jurnal, riwayat, progres, streak, status, dashboard guru, daftar/detail siswa, komentar, aturan database, offline dasar.
- **Should:** notifikasi komentar, ulasan akhir buku, riwayat buku di Profil, perpanjang target, reset password oleh guru, ekspor kredensial awal.
- **Could:** Rekap bulanan + ekspor CSV, pengingat harian, mode gelap.
- **Won't (V1):** daftar "belum ada" pada gambar rancangan.

## 8. Kriteria sukses V1
1. Siswa dapat membuat jurnal pertama dalam < 1 menit setelah login pertama dan buku dipilih.
2. Jurnal ke-2 pada tanggal yang sama ditolak oleh database, bukan hanya UI.
3. Guru kelas A tidak dapat membaca data kelas B maupun sekolah lain (terbukti oleh pengujian rules).
4. Jurnal yang ditulis offline tersimpan dan tersinkron setelah online.
5. Dashboard guru memuat 36 siswa dalam 1 query tanpa agregasi di klien selain penghitungan ringan.
