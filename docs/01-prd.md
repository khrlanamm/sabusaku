# 01 — PRD Sabu Saku (Satu Bulan Satu Buku)

Versi dokumen: 2.0 · 16 Oktober 2026 · Status: berlaku (v1.0 · 7 Oktober 2026)

> Versi 2 mengganti login kode sekolah + NIS dengan email/Google, menghapus peran admin sekolah, dan menjadikan kelas serta ekstrakurikuler sebagai label. Rincian keputusan ada di dokumen 07 §0.

## 1. Ringkasan

Sabu Saku adalah aplikasi Android untuk **jurnal membaca**. Siswa SMA membaca satu buku per bulan dan mencatat hasil bacaan setiap hari. Penanggung jawab (guru atau pembina ekstrakurikuler) memantau progres seluruh siswa sekolahnya dan memberi komentar pada jurnal. Satu aplikasi melayani banyak sekolah (multi-tenant); sekolah dan penanggung jawab pertamanya didaftarkan oleh superadmin di aplikasi (atau developer lewat skrip), bukan lewat pendaftaran mandiri. Sekolah yang tertarik mengisi formulir di `sabusaku.web.app/daftar-sekolah`.

**Fokus V1** (dari gambar rancangan): memastikan siswa benar-benar bisa mengisi jurnal setiap hari dan guru bisa memantaunya dengan mudah.

### Tujuan
- Mencatat proses membaca harian yang bermakna (halaman, durasi, isi bacaan, refleksi).
- Membuat guru tahu siapa yang aktif, perlu perhatian, atau tidak aktif tanpa membuka satu per satu.
- Bekerja baik di jaringan buruk (jurnal bisa ditulis offline).

### Bukan tujuan V1
AI, rekomendasi buku, upload foto selain foto profil, chat siswa–guru, analisis otomatis, integrasi Google Books, iOS, web, pendaftaran sekolah mandiri, pembayaran.

## 2. Peran dan hak akses

| Peran | Didaftarkan oleh | Dipakai lewat | Ringkasan hak |
|---|---|---|---|
| **Developer** | — | Skrip CLI (di luar aplikasi) | Membuat sekolah, menambah dan mengeluarkan penanggung jawab, menangguhkan sekolah |
| **Superadmin** (benevology@gmail.com) | Kode (`SUPERADMIN_EMAILS`) | Aplikasi (menu guru) | Menambah sekolah beserta penanggung jawab pertamanya, berpindah ke sekolah mana pun dan bertindak sebagai penanggung jawabnya. Tidak tampil di daftar penanggung jawab |
| **Penanggung jawab** (`guru`) | Superadmin, developer, atau penanggung jawab lain | Aplikasi (menu guru) | Melihat **semua siswa sekolahnya** beserta jurnal, memberi komentar, menambah siswa lewat email, mengubah nama/kelas/ekstrakurikuler siswa, mengeluarkan siswa dari sekolah, menghapus data siswa, mengelola label kelas dan ekstrakurikuler serta pengaturan sekolah, menambah dan mengeluarkan penanggung jawab lain (bukan dirinya sendiri) |
| **Siswa** | Penanggung jawab (email) | Aplikasi (menu siswa) | Memilih buku bebas, mengisi dan melihat jurnal sendiri, membaca komentar, mengubah nama, kelas, ekstrakurikuler, dan foto profil sendiri |

Akun Firebase Auth dibuat pengguna sendiri (Google, atau daftar email + verifikasi). "Didaftarkan" berarti emailnya dimasukkan ke daftar anggota sekolah (`members/{email}`); tanpa itu akun tidak bisa membuka data apa pun.

Satu email = satu peran, terikat ke paling banyak satu sekolah. Data antar sekolah terisolasi total (lihat dokumen 03).

## 3. Alur utama

**Onboarding sekolah (superadmin):** Sekolah → **Ganti** → **Tambah sekolah**: kode, nama sekolah, nama dan email penanggung jawab pertama. Sekolah baru mendapat ekstrakurikuler awal tanpa kelas; superadmin bisa langsung membukanya untuk menambah kelas. Penanggung jawab lalu menambah kelas, siswa, dan penanggung jawab lain sendiri di aplikasi.

**Onboarding sekolah (developer):** `create-school` → sekolah dengan label kelas dan ekstrakurikuler awal → `add-guru` untuk tiap penanggung jawab → (opsional) `import-students` dari CSV `email,nama,kelas,ekskul`.

**Login:** *Email* + *Password*, atau **Masuk dengan Google**. Tidak ada kode sekolah dan NIS. Setelah masuk, aplikasi memanggil `claimAccount`:
- email belum terverifikasi (daftar email) → layar verifikasi email;
- email tidak ada di daftar sekolah mana pun → pop-up **"Harap Menghubungi Administrator Sekolah"** dengan tautan "Ingin mendaftarkan sekolah Anda? Pelajari di sini" ke `sabusaku.web.app/daftar-sekolah`, lalu keluar;
- nama kosong, siswa tanpa kelas, atau akun Google tanpa password → layar **Lengkapi akun** (nama, kelas, ekstrakurikuler, foto, buat password);
- selain itu → shell sesuai peran.

"Belum punya akun? Daftar" membuat akun email + password dan mengirim email verifikasi. "Lupa password?" mengirim email reset dari Firebase. Field email dan password memicu tawaran "Simpan password" Android.

**Siswa:** login → Beranda → (jika belum ada buku) pilih buku → baca → Isi Jurnal → Simpan → lihat Riwayat → baca komentar guru (notifikasi masuk).

**Penanggung jawab:** login → Dashboard → Daftar Siswa (filter kelas, ekstrakurikuler, status) → Detail Siswa → Detail Jurnal → tulis komentar. Tambah siswa: email wajib, nama/kelas/ekstrakurikuler opsional; siswa yang belum pernah masuk tampil di bagian "Belum masuk".

## 4. Layar dan fitur (V1)

### Siswa — navigasi bawah 4 tab: Beranda · Buku · Jurnal · Profil
| Layar | Isi |
|---|---|
| Beranda | Sapaan, kartu buku bulan ini (cover, judul, halaman, persen), tombol **Isi Jurnal Hari Ini**, komentar guru baru, **statistik** (enam kartu yang semuanya bisa dibuka: jurnal bulan ini → tab Jurnal bulan ini; streak sekarang dan terbaik → halaman Streak dengan kalender; buku selesai → Riwayat buku "Selesai"; total jurnal → tab Jurnal semua waktu; peringkat bulan ini → Peringkat; lencana → Lencana), tiga buku terakhir + **Lihat semua** (Riwayat buku: cari, status, rentang tanggal, buku unik, urutan) |
| Buku Saya | Detail buku aktif: total halaman, mulai, target, progres, tombol Perpanjang / Tandai Selesai / Hentikan, tiga buku sebelumnya. Jika belum ada buku: form **Mulai Buku** (judul, penulis, total halaman, opsional ISBN). Ikon riwayat → Riwayat buku. Buku lama dibuka dengan tanggal, lama membaca, streak buku itu, ulasan akhir, dan jurnalnya |
| Isi Jurnal | Tanggal, halaman dari–sampai (otomatis lanjut dari halaman terakhir), durasi (4 pilihan), informasi penting (wajib), hal menarik (opsional), pertanyaan (opsional) |
| Riwayat Jurnal | Jurnal semua buku per bulan (terbaru atau terlama dulu), disaring per buku, bulan, atau rentang tanggal; tampilan kalender; lencana komentar guru |
| Peringkat | Peringkat sekolah per bulan, tahun, tahun ajaran (1 Juli–30 Juni), atau sepanjang waktu, menurut buku selesai, streak terpanjang dalam periode, atau hari membaca; disaring sekolah, kelas, atau ekskul siswa; posisi sendiri selalu terlihat |
| Lencana | Pencapaian buku, streak, jurnal, tepat waktu, dan ulasan, dengan progresnya |
| Detail Jurnal | Isi jurnal + komentar guru; edit/hapus bila masih dalam jendela edit |
| Profil | Foto profil (ganti, pakai foto Google, hapus), nama, kelas, ekstrakurikuler, ringkasan lencana, atur/ubah password, keluar, hapus akun. Statistik dan riwayat buku pindah ke Beranda (18 Okt 2026) |

Cover buku: tanpa upload di V1; aplikasi membuat **sampul otomatis** (warna dari judul + inisial).

### Penanggung jawab (guru) — navigasi bawah 4 tab: Dashboard · Siswa · Sekolah · Profil
| Layar | Isi |
|---|---|
| Dashboard | Kartu ringkasan seluruh sekolah (siswa, buku aktif, jurnal bulan ini), jumlah Aktif / Perlu perhatian / Tidak aktif / Belum ada buku, daftar siswa yang perlu perhatian |
| Daftar Siswa | Filter kelas, ekstrakurikuler, dan status; pencarian nama; progres per siswa; bagian "Belum masuk" (email terdaftar yang belum pernah login); tombol Tambah siswa dan Impor CSV |
| Peringkat | Sama dengan peringkat siswa, disaring dengan cakupan dashboard (Semua siswa, Binaan saya, kelas, ekskul); ketuk siswa untuk membuka detailnya. Dibuka dari kartu "Peringkat siswa" di Dashboard |
| Detail Siswa | Buku aktif, progres, streak (sekarang dan terbaik), aktivitas terakhir, lencana, riwayat buku, **Lihat semua jurnal**, ubah nama/kelas/ekstrakurikuler, **Keluarkan dari sekolah**, **Hapus data permanen** |
| Detail Jurnal + Komentar | Isi jurnal siswa, daftar komentar, kolom tulis komentar |
| Sekolah | Label kelas (format `XII-A1`, `X-G2`) dan ekstrakurikuler (bisa ditambah), daftar penanggung jawab (tambah dan keluarkan), pengaturan: hari libur, hari netral, ambang status. Superadmin: kode sekolah dan tombol **Ganti** (daftar semua sekolah, **Tambah sekolah**) |
| Profil | Sama dengan profil siswa tanpa statistik membaca |

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
| BR-12 | **Streak** = jumlah hari efektif berurutan yang punya jurnal sampai hari ini, dari jurnal semua buku siswa (ganti buku tidak memutus streak; sejak 18 Okt 2026). Streak putus jika ada hari efektif **sebelum hari ini** tanpa jurnal. Jurnal di hari netral tetap menambah hitungan. Detail buku juga menampilkan streak buku itu saja |
| BR-13 | **Status siswa** dari `d` = jumlah hari efektif sejak jurnal terakhir (atau sejak buku dimulai bila belum ada jurnal) sampai hari ini: **Aktif** `d ≤ 3`, **Perlu perhatian** `4–7`, **Tidak aktif** `> 7`, **Belum ada buku** bila tak ada buku aktif. Status hanya indikator, bukan nilai |
| BR-14 | Penanggung jawab melihat semua siswa dan jurnal **di sekolahnya saja**. Data antar sekolah terisolasi. Satu email hanya bisa terdaftar di satu sekolah |
| BR-15 | Siswa yang dikeluarkan dari sekolah kehilangan akses ke data sekolah, tetapi akun dan jurnalnya tetap ada; menambahkannya lagi mengembalikan riwayatnya. Hapus data permanen dan hapus akun adalah aksi terpisah |
| BR-16 | Password minimal 8 karakter dengan huruf besar, huruf kecil, angka, dan karakter khusus, dibuat pengguna sendiri (dipaksakan juga oleh Firebase Auth). Akun email wajib terverifikasi sebelum bisa membuka data sekolah. Akun Google wajib membuat password di layar Lengkapi akun |
| BR-17 | Komentar guru: banyak komentar per jurnal; guru boleh mengubah/menghapus komentarnya sendiri; siswa hanya membaca. Komentar baru memicu notifikasi ke siswa |
| BR-18 | **Kelas** dan **ekstrakurikuler** adalah label di dokumen sekolah. Satu siswa tepat satu kelas (format `X`/`XI`/`XII`, tanda hubung, huruf dan angka: `XII-A1`, `X-G2`) dan nol atau lebih ekstrakurikuler (awal: Masis-KIR, Paskibra, Pala, PMR). Siswa boleh mengganti kelas dan ekstrakurikulernya sendiri; penanggung jawab boleh menambah label |

Nilai BR-3, BR-4, BR-7 dikunci di aplikasi dan rules (bukan pengaturan sekolah) supaya konsisten. BR-11 dan BR-13 dapat diatur penanggung jawab.

## 6. Kebutuhan non-fungsional
- **Platform:** Android saja (satu aplikasi untuk siswa dan penanggung jawab). minSdk diputuskan saat setup (kandidat 23).
- **Bahasa:** Indonesia saja.
- **Offline:** siswa dapat menulis jurnal tanpa sinyal; data tersinkron saat online. Jurnal yang ditolak saat sinkron (mis. lewat batas BR-3) harus tampak jelas di UI.
- **Kinerja:** Beranda siswa dan Dashboard guru masing-masing dimuat dari 1–2 dokumen ringkasan, bukan menghitung ulang di klien.
- **Keamanan dan privasi:** siswa SMA umumnya di bawah 18 tahun dan jurnal bersifat personal. Isolasi per sekolah, akses minimum per peran, App Check, wilayah data Jakarta, jalur penghapusan data. Lihat dokumen 03.
- **Aksesibilitas:** ukuran sentuh ≥ 48dp, kontras AA, mendukung font besar sistem.
- **Observabilitas:** Crashlytics (tanpa nama, email, atau isi jurnal) dan log Functions terstruktur. Firebase Analytics dilepas di 1.2.1.

## 7. Prioritas (MoSCoW)

- **Must:** login email/Google multi-sekolah, peran, label kelas dan ekstrakurikuler, impor CSV, mulai buku, isi jurnal, riwayat, progres, streak, status, dashboard guru, daftar/detail siswa, komentar, aturan database, offline dasar.
- **Should:** notifikasi komentar, ulasan akhir buku, riwayat buku di Profil, perpanjang target, foto profil, hapus akun dari aplikasi.
- **Could:** Rekap bulanan + ekspor CSV, pengingat harian, mode gelap.
- **Won't (V1):** daftar "belum ada" pada gambar rancangan.

## 8. Kriteria sukses V1
1. Siswa dapat membuat jurnal pertama dalam < 1 menit setelah login pertama dan buku dipilih.
2. Jurnal ke-2 pada tanggal yang sama ditolak oleh database, bukan hanya UI.
3. Penanggung jawab sekolah A tidak dapat membaca data sekolah B; email yang tidak terdaftar tidak dapat membaca apa pun (terbukti oleh pengujian rules).
4. Jurnal yang ditulis offline tersimpan dan tersinkron setelah online.
5. Dashboard penanggung jawab memuat seluruh siswa sekolah dalam 1 query tanpa agregasi di klien selain penghitungan ringan.
