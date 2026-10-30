// Decisions from the human review of the catalog (review-sheets.ts and the
// title lists), 16 Oct 2026:
//   REJECTED_BOOKS     dropped by normalize.ts (wrong edition, textbook,
//                      adult content, not reading for SMA students, …)
//   REJECTED_COVERS    skipped by covers.ts, which tries the book's next cover
//   CATEGORY_OVERRIDES replace the automatic classification (1–3, primary first)
//   TITLE_RENAMES      canonical titles, keyed by the normalised source title
//   AUTHOR_RENAMES     canonical authors, keyed by the normalised source name
import type {Category} from "./seeds";

/**
 * Book ID → reason. On 30 Oct 2026 the user decided that adult, political
 * and technical or academic books belong in the catalog: only non-books and
 * incomplete books are kept out. The curation's soft deletes for those
 * reasons were lifted, so curate.ts restores them.
 */
export const REJECTED_BOOKS: Record<string, string> = {
  // ---- Review of the books added on 17 Oct 2026 (new IDs of books already in production count as duplicates) ----
  bk_e5f4666c2a5a0bfe: "tinjauan: bukan buku utuh (snackbook)", // Charles Lebourne - Orang-Orang Bloomington
  bk_4037da2a8536a7b8: "tinjauan: bukan buku utuh (snackbook)", // Laki-Laki Tua Tanpa Nama - Orang-Orang Bloomington
  bk_b90f39a24170d281: "tinjauan: edisi lain dari buku yang sudah ada", // 5 cm (Hc)
  bk_a8c8f204e16de708: "tinjauan: edisi lain dari buku yang sudah ada", // 9 Summers 10 Autumns (Augmented Hinted Ilustrative Book)
  bk_b5bcdcb741a88e99: "tinjauan: edisi lain dari buku yang sudah ada", // Badai Pasti Berlalu - CU Format Baru
  bk_d021640ef918b505: "tinjauan: bukan buku utuh (cuplikan)", // Geez & Ann #1: Free Chapter
  bk_2d3710b24b973eac: "tinjauan: bukan buku utuh (cuplikan)", // Geez & Ann #2: Free Chapter
  bk_f7c071f968cdd3da: "tinjauan: edisi lain dari buku yang sudah ada", // Classics: Sebatang Kara (Nobody's Boy)
  bk_ff2d03f2926f4cb2: "duplikat: sudah ada sebagai bk_c70a7466f524e8af", // "Membumikan" Al-Qur'an
  bk_a70308d4c5eaf269: "duplikat: sudah ada sebagai bk_d5599c5f588d42ff", // Bilangan Fu
  bk_666d9e9dfb4f08cb: "duplikat: sudah ada sebagai bk_f56fc1f1abf0c110", // Kubah
  bk_75b89165960be70b: "duplikat: sudah ada sebagai bk_4f10875a86b3127b", // Senja di Jakarta
  bk_0a6f24ecee1e2f14: "duplikat: sudah ada sebagai bk_13680be1fda7d8e5", // Seperti Dendam, Rindu Harus Dibayar Tuntas
  // ---- Curation of the production catalog (17 Oct 2026, curate.ts soft-deletes them) ----
  bk_a8967eef3bf408b2: "kurasi: bukan buku utuh / bukan bacaan", // A Moment To Love You Chapter 1
  bk_9d88d8a9cf10aa14: "kurasi: bukan buku utuh / bukan bacaan", // Paranormal
  bk_a03b8b3ce034300b: "kurasi: bukan buku utuh / bukan bacaan", // Sebuah Catatan, Untuk Kita Renungkan
  bk_8eade154a27128dd: "kurasi: bukan buku utuh / bukan bacaan", // The Perfect Cakes
  bk_a4b951ddee1bdd4c: "kurasi: bukan buku utuh / bukan bacaan", // Asian Games 2018
  bk_d6eeda54f8f218ef: "kurasi: bukan buku utuh / bukan bacaan", // Hello Shinee
  bk_d96d2225b6c38588: "kurasi: bukan buku utuh / bukan bacaan", // Fikih Manhaji 5 – Haji dan Umrah
  // ---- Books that came in after the title-case rerun (16 Oct 2026) ----
  // ---- Relevance review of every harvested title (16 Oct 2026) ----
  bk_b98f0e5a7aa38dbb: "edisi bahasa asing", // Scorpia
  // ---- Review of the seed authors' other works and Wikipedia books ----
  bk_6b56255fed7df793: "judul tidak valid", // Lihat daftar isi Yel
  bk_cc4035257950fe1a: "duplikat (pakai Supernova 1)", // Supernova
  bk_0f124f673318aa67: "tidak ada cover yang benar", // Patiwangi
  bk_b3b6ed318f9a183f: "tidak ada cover yang benar", // Inul!
  // ---- Category review of every book ----
  bk_49e15f5cc0359538: "duplikat (Rantau 1 Muara)", // Rantau muara
  bk_701b80c38ae2f894: "duplikat (Arsitektur yang Lain, Sebuah Kritik Arsitektur)", // Arsitektur yang lain
  bk_3af32f26c9099952: "duplikat (Di Bawah Lindungan Ka'bah)", // Di Bawah Lindungan Kabah
  bk_1747371656b46f9a: "duplikat (Autumn in Paris)", // MetroPop: Autumn In Paris
  bk_ab3bc34c7b7b2f08: "duplikat (Membangkitkan Energi Qolbu)", // Membangkitkan energi qolbu
  bk_cc332584363d33a9: "duplikat edisi Inggris (Harry Potter dan Orde Phoenix)", // Harry Potter and the order of the Phoenix
  bk_72484a07a8291d33: "duplikat (Kambing dan Hujan)", // Kambing & hujan
  bk_02fedc65fcc0a5b8: "duplikat (Petualangan Tom Sawyer)", // Petualangan Tom Saeyer
  bk_7146e9bf3bb3aeee: "duplikat (Petualangan Tom Sawyer)", // Seri Sastra Dunia: Petualangan Tom Sawyer
  bk_85448cc5cc414220: "duplikat (Azab dan Sengsara)", // Azab Dan Sengsara ( Indonesian Edition )
  bk_558342c78c00a01d: "judul tidak valid (bukan karya Tan Malaka)", // Madilog: Makan Daging Cilok
  // ---- Cover review ----
  bk_ab6490cfe82c61be: "edisi bahasa asing", // 15 Février 1839
  bk_229ab7ac730bd5c6: "edisi bahasa asing", // 5 Wealthy Research Topics and Changes for the Future: Buildi
  bk_878201a3181fa376: "edisi bahasa asing", // 5 Wealthy Research Topics and Changes for the Future: iandro
  bk_675585dac8958bb8: "bukan bacaan umum (katalog/kamus/panduan)", // A Comprehensive Indonesian-English Dictionary
  bk_4f4dd1a1d68d20af: "edisi bahasa asing", // Abraham Lincoln (1809-1865), Presiden Amerika Serikat jang k
  bk_578ded6360e14a21: "bukan bacaan umum (katalog/kamus/panduan)", // Add Me on Facebook!
  bk_4cbb80c33e9a9b22: "bukan bacaan umum (katalog/kamus/panduan)", // An English-Indonesian-Chinese Dictionary
  bk_af62619026f4e369: "edisi bahasa asing", // And the War Is Over
  bk_918c72442d437c3c: "edisi bahasa asing", // Bali in the 19th Century
  bk_e8bcc43fddbe0b0e: "bukan bacaan umum (katalog/kamus/panduan)", // Batik dan Mitra =
  bk_437411d8372a4c9e: "edisi bahasa asing", // Ben Has Something to Say
  bk_2360eb1e38ef867f: "bukan bacaan umum (katalog/kamus/panduan)", // Cerita Boga Indonesia
  bk_5804d3ffa9b83c22: "bukan bacaan umum (katalog/kamus/panduan)", // Cindai, Pengembaraan Kain Patola India.
  bk_45cefab5fc13aaf1: "edisi bahasa asing", // Classical Sociological Theory
  bk_85ceed125cc5330b: "edisi bahasa asing", // Counseling Theory and Practice
  bk_f05d1603a468a12b: "bukan bacaan umum (katalog/kamus/panduan)", // Crypto Cash Machine
  bk_08568b855cdbd1c1: "edisi bahasa asing", // Dang Xia De Li Liang
  bk_fd54adcb071c3550: "edisi bahasa asing", // Digital Marketing
  bk_1c80932d52b84161: "edisi bahasa asing", // Droit Penal General
  bk_57b35f6cceb8620d: "edisi bahasa asing", // Earth Dance
  bk_c93376f0c1aa949a: "bukan bacaan umum (katalog/kamus/panduan)", // Glosarium Keuangan
  bk_6d55447c96f2b2dd: "edisi bahasa asing", // Introduction to Alkaloids
  bk_c2d7451a9a3f5a0f: "bukan bacaan umum (katalog/kamus/panduan)", // Kesehatan dan Keselamatan Kerja
  bk_e0a6d9904a7bb842: "edisi bahasa asing", // Kill the Radio (Visible Poets)
  bk_cde5f8d73b9ec8e3: "edisi bahasa asing", // Living Islam
  bk_789ba7159e749cd7: "bukan bacaan umum (katalog/kamus/panduan)", // Mahir Berbahasa Spanyol dalam Sepekan
  bk_68ac9883d194408d: "edisi bahasa asing", // Megatrends 2000
  bk_b93a80998301ae1e: "edisi bahasa asing", // On Call
  bk_7838c3a9ffc3307c: "bukan bacaan umum (katalog/kamus/panduan)", // Smart Breastfeeding Mother
  bk_fd84deef545d92e9: "edisi bahasa asing", // Sri Sumarah and Other Stories
  bk_dcaf812453f85716: "bukan bacaan umum (katalog/kamus/panduan)", // Tenun Ikat =
  bk_dccb0ebca9fd3de3: "edisi bahasa asing", // The Complete Poetry and Prose of Chairil Anwar.
  bk_c49e05a9949afcea: "edisi bahasa asing", // The Ecology of Sulawesi
  bk_e65bf88d2ee6309f: "edisi bahasa asing", // The Psychology of Money
  bk_4771b3c25a5ced7c: "edisi bahasa asing", // Trading Chaos
  bk_509d2ba0650223c7: "bukan bacaan umum (katalog/kamus/panduan)", // Urban / Culture: Cp Biennale 2005
  bk_a3e3e77b3a0bdeeb: "edisi bahasa asing", // どんどんつながる漢字練習帳 初級
  bk_440c83d933bfa2b3: "bukan bacaan umum (katalog/kamus/panduan)", // 7 Jam Belajar ArchiCAD 8 untuk Orang Awam
  bk_5afea7a6470b8301: "bukan bacaan umum (katalog/kamus/panduan)", // Pameran Seni Rupa
  bk_73bd0297fb6a70c0: "edisi bahasa asing", // The Indonesian Language
  bk_7b60efd58dd7c2a4: "edisi bahasa asing", // Village At War
  bk_9207645aa1e6e326: "bukan bacaan umum (katalog/kamus/panduan)", // Karya Arsitek Indonesia.
  bk_9bbf357a45be0b60: "edisi bahasa asing", // A biological assessment of the Wapoga River area of northwes
  bk_d65e87ef4f8e96e2: "bukan bacaan umum (katalog/kamus/panduan)", // Indonesian Phrase Book & Dictionary
  bk_bb49ee0536e9caed: "tidak ada cover yang benar", // Air Mata Saudaraku
  bk_af1c773623433770: "tidak ada cover yang benar", // Burung Kolibri Merah Dadu
  bk_470d9c2f498a5f4b: "tidak ada cover yang benar", // Istri Konsul
  bk_05940328ef04e081: "tidak ada cover yang benar", // Mochtar Lubis Bicara Lurus
  bk_2f3dbc5f1ae5b681: "tidak ada cover yang benar", // Refleksi dan Gagasan Kebijakan Fiskal
  bk_f96cd6a4184a4cdf: "tidak ada cover yang benar", // Taoko
  // ---- Review of the 30 Oct 2026 run ----
  bk_62c07e2a7f462762: "tinjauan: ebook terbitan penulis tanpa ISBN, bukan edisi cetak", // Dompet Ayah Sepatu Ibu
  bk_237d91ddb8d22f66: "tinjauan: ebook terbitan penulis tanpa ISBN, bukan edisi cetak", // Kami (Bukan) Jongos Berdasi - Unedited Version
  bk_5da40644a4f4a494: "tinjauan: bukan buku utuh (cuplikan)", // Jika Kita Tak Pernah Jadi Apa-Apa: Chapter 1
  bk_f0755583f382426f: "tinjauan: bukan buku utuh (cuplikan)", // Refrain [chapter 2]
  bk_07865356ddd67a89: "tinjauan: edisi lain dari buku yang sudah ada", // Tidak Ada New York Hari Ini (dwibahasa)
  bk_8621a1f1a22d6cb5: "bukan bacaan umum (katalog/kamus/panduan)", // Tentang Sejumlah Orang Sulawesi Selatan
  bk_a195d740dedf98a6: "bukan bacaan umum (katalog/kamus/panduan)", // Kabar Baik (traktat)
  bk_07f315bfb91c418b: "bukan bacaan umum (katalog/kamus/panduan)", // Umat Allah Menegaskan Arah
  // Second run of 30 Oct 2026: not books to read, foreign editions, a duplicate.
  bk_99a894692194406e: "tinjauan: Laporan penelitian fakultas (FKIP Unlam), bukan buku terbit", // Analisis Majas dalam Novel Harimau! Harimau! Karya Mochtar L
  bk_f4bbec4c18918c8f: "tinjauan: Keputusan Menteri Kesehatan (dokumen regulasi pemerintah)", // Indikator Indonesia Sehat 2010 dan Pedoman Penetapan Indikat
  bk_f5d4b33c267f83c3: "tinjauan: Berbahasa Inggris (tata bahasa Indonesia terbitan Routledge)", // Indonesian
  bk_f504d337cf9ef696: "tinjauan: Prosiding seminar (Seminar Konsep Manajemen Indonesia 1979)", // Konsep Manajemen Indonesia
  bk_516584584bb7b1e1: "tinjauan: Profil/direktori anggota DPRD, bukan buku bacaan", // Profil DPRD Provinsi Jawa Barat Periode, 2004-2009
  bk_d20b9482f9ad2bd9: "tinjauan: Edisi bahasa Inggris (ISBN 978-1-5247, Currency/Crown)", // The Lean Startup
  bk_7a593ee32f580cfb: "tinjauan: duplikat (Tuhan, Izinkan Aku Menjadi Pelacur!, edisi Scripta Manent)", // Tuhan, Izinkan Aku Menjadi Pelacur!
  // Foreign-language editions found in the catalog (30 Oct 2026), none with readers.
  bk_0bbf8ae36912c40b: "kurasi: edisi bahasa asing", // Rich Dad Poor Dad (Business Plus)
  bk_346776a26373eaae: "kurasi: edisi bahasa asing", // Personality Plus (Monarch)
  bk_fe70a22066d436d8: "kurasi: edisi bahasa asing", // Never Let Me Go (Faber cover)
};

/** Cover URLs that show the wrong book, a person, a placeholder or a page. */
export const REJECTED_COVERS = new Set<string>([
  // Second run of 30 Oct 2026: photos, logos, screenshots, library bindings and other books.
  "https://books.google.com/books/content?id=84tkAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Kalimat Efektif Bahasa Indonesia, library binding
  "https://covers.openlibrary.org/b/id/14424646-L.jpg?default=false", // Analisis Laporan Keuangan Pemerintah Daerah
  "https://covers.openlibrary.org/b/id/6163241-L.jpg?default=false", // Analisis Majas dalam Novel Harimau! Harimau! Karya Mochtar L
  "https://covers.openlibrary.org/b/id/6452745-L.jpg?default=false", // Antropologi Hukum Indonesia
  "https://covers.openlibrary.org/b/id/6290698-L.jpg?default=false", // Baca Kitab Manakib Syekh Abdul Qadir Jaelani Merusak Aqidah 
  "https://covers.openlibrary.org/b/id/6273676-L.jpg?default=false", // Centhini, Tambangraras-Amongraga
  "https://covers.openlibrary.org/b/id/11856614-L.jpg?default=false", // Desa Mawa Cara
  "https://covers.openlibrary.org/b/id/11969629-L.jpg?default=false", // Filsafat Pendidikan Islam
  "https://covers.openlibrary.org/b/id/3842633-L.jpg?default=false", // Garis-Garis Besar Hukum Gereja
  "https://covers.openlibrary.org/b/id/6252816-L.jpg?default=false", // Hukum Acara Perdata Agama
  "https://covers.openlibrary.org/b/id/6252823-L.jpg?default=false", // Hukum Kepailitan Selayang Pandang
  "https://covers.openlibrary.org/b/id/6252830-L.jpg?default=false", // Hukum Perwakilan dan Kuasa
  "https://covers.openlibrary.org/b/id/6277105-L.jpg?default=false", // Hukum Waris Adat
  "https://covers.openlibrary.org/b/id/14824101-L.jpg?default=false", // Ilmu Negara
  "https://covers.openlibrary.org/b/id/6295128-L.jpg?default=false", // Implementasi Pancasila Sebagai Pandangan Hidup Bangsa dan Da
  "https://covers.openlibrary.org/b/id/6277883-L.jpg?default=false", // Indikator Indonesia Sehat 2010 dan Pedoman Penetapan Indikat
  "https://covers.openlibrary.org/b/id/6425772-L.jpg?default=false", // Kalimat Efektif Bahasa Indonesia
  "https://covers.openlibrary.org/b/id/6824303-L.jpg?default=false", // Kedudukan Hukum Islam dalam Sistem Hukum Indonesia
  "https://covers.openlibrary.org/b/id/6452542-L.jpg?default=false", // Kewiraan untuk Mahasiswa
  "https://covers.openlibrary.org/b/id/12878129-L.jpg?default=false", // Konsep Manajemen Indonesia
  "https://books.google.com/books/content?id=8BEgAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Kumpulan Karangan
  "https://covers.openlibrary.org/b/id/10462369-L.jpg?default=false", // Lembaga-Lembaga Keuangan dan Bank
  "https://covers.openlibrary.org/b/id/5825020-L.jpg?default=false", // Makrifat Burung Surga dan Ilmu Kasampurnan Syekh Siti Jenar
  "https://covers.openlibrary.org/b/id/7238412-L.jpg?default=false", // Manajemen Berbasis Sekolah
  "https://covers.openlibrary.org/b/id/6296664-L.jpg?default=false", // Manajemen Publik
  "https://covers.openlibrary.org/b/id/8277253-L.jpg?default=false", // Neurologi Klinis Dasar
  "https://books.google.com/books/content?id=soqzFe35McEC&printsec=frontcover&img=1&zoom=1&fife=w600", // Ornamen (Ragam Hias) Rumah Adat Batak Toba
  "https://covers.openlibrary.org/b/id/15127325-L.jpg?default=false", // Pancasila Sebagai Ideologi, Azas, dan Dasar Negara
  "https://covers.openlibrary.org/b/id/6375887-L.jpg?default=false", // Panduan Penyelenggaraan Taman Bacaan Masyarakat
  "https://books.google.com/books/content?id=iW5wAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Pembangunan Nasional dalam Perspektif Budaya
  "https://covers.openlibrary.org/b/id/15203125-L.jpg?default=false", // Pendidikan Islam
  "https://covers.openlibrary.org/b/id/12058484-L.jpg?default=false", // Pengantar Hukum Indonesia
  "https://covers.openlibrary.org/b/id/10453339-L.jpg?default=false", // Pengantar Ilmu Hukum Indonesia
  "https://books.google.com/books/content?id=8cMtAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Penggunaan Bahasa Indonesia Ragam Tulis dalam Penyusunan Kar
  "https://books.google.com/books/content?id=pwrYAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Perjanjian Hudaibiyah
  "https://books.google.com/books/content?id=gphkAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Prosa Tradisional
  "https://books.google.com/books/content?id=pCSAAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Riau Sebagai Pusat Bahasa dan Kebudayaan Melayu
  "https://books.google.com/books/content?id=NfSFAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Sejarah Pemikiran Hak-Hak Asasi Manusia di Indonesia
  "https://covers.openlibrary.org/b/id/5545700-L.jpg?default=false", // Sistem Koperasi
  "https://covers.openlibrary.org/b/id/6308196-L.jpg?default=false", // Sosiologi Hukum dalam Masyarakat
  "https://covers.openlibrary.org/b/id/6252833-L.jpg?default=false", // Studi Kasus Hukum Internasional
  "https://books.google.com/books/content?id=RI0tAQAAIAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Sunda Sebelum Perang
  "https://covers.openlibrary.org/b/id/5327793-L.jpg?default=false", // Tango
  "https://covers.openlibrary.org/b/id/5731243-L.jpg?default=false", // Tata Rias & Busana Tari Sunda
  "https://covers.openlibrary.org/b/id/6338568-L.jpg?default=false", // Tema Cerita Pendek Indonesia Tahun 1950-1060
  "https://books.google.com/books/content?id=XiceAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Tema Islam dalam Pertunjukan Rakyat Jawa
  "https://books.google.com/books/content?id=I-_nAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Teori Ekonomi, Politik Ekonomi dan Orde Ekonomi
  "https://covers.openlibrary.org/b/id/5328897-L.jpg?default=false", // Cerita Rakyat Jawa Barat, shows Karnadi Bandar Bangkong
  "https://books.google.com/books/content?id=guQhfqYvU8EC&printsec=frontcover&img=1&zoom=1&fife=w600", // Dari Pendjara ke Pendjara, library binding
  "https://covers.openlibrary.org/b/id/13495632-L.jpg?default=false", // Dibawah Bendera Revolusi, photos of people
  "https://books.google.com/books/content?id=die4AAAAIAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Sepotong Hati di Sudut Kamar, library binding
  "https://books.google.com/books/content?id=z5xkAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Deru Campur Debu, library binding or title-page scan
  "https://books.google.com/books/content?id=Zo-5AAAAIAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Canting, library binding or title-page scan
  "https://books.google.com/books/content?vid=ISBN9789794030875&printsec=frontcover&img=1&zoom=1", // Cinta Olimpiade, library binding or title-page scan
  "https://books.google.com/books/content?id=5XWN0FNrAekC&printsec=frontcover&img=1&zoom=1&fife=w600", // Kampus Maut!, partial scan
  "https://covers.openlibrary.org/b/id/4250547-L.jpg?default=false", // Air Mata Saudaraku
  "https://covers.openlibrary.org/b/id/10618331-L.jpg?default=false", // Alam Kubur
  "https://covers.openlibrary.org/b/id/6280207-L.jpg?default=false", // Antologi Syair Simbolik dalam Sastra Indonesia Lama.
  "https://covers.openlibrary.org/b/id/13164880-L.jpg?default=false", // Arie Smit Memburu Cahaya Bali =
  "https://covers.openlibrary.org/b/id/6279086-L.jpg?default=false", // Ballada Orang-Orang Tercinta
  "https://covers.openlibrary.org/b/id/5548885-L.jpg?default=false", // Batu Belah Batu Bertangkup
  "https://books.google.com/books/content?id=nJ1kAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Berbahasa Baik dan Berbahasa Dengan Baik
  "https://books.google.com/books/content?id=7ZlkAAAAMAAJ&printsec=frontcover&img=1&zoom=1&fife=w600", // Berserah Itu Indah
  "https://covers.openlibrary.org/b/id/13973690-L.jpg?default=false", // Bung Karno dan Tata Dunia Baru
  "https://covers.openlibrary.org/b/id/6463632-L.jpg?default=false", // Burung Kolibri Merah Dadu
  "https://covers.openlibrary.org/b/id/6372793-L.jpg?default=false", // Can Pek Can Der
  "https://covers.openlibrary.org/b/id/3370939-L.jpg?default=false", // Cerita Rakyat dari Cirebon
  "https://covers.openlibrary.org/b/id/10480626-L.jpg?default=false", // Ekonomi Islam
  "https://covers.openlibrary.org/b/id/6697937-L.jpg?default=false", // Emang Gue Pikirin
  "https://covers.openlibrary.org/b/id/6290266-L.jpg?default=false", // Etika Komunikasi
  "https://covers.openlibrary.org/b/id/13133251-L.jpg?default=false", // Filsafat Kemuhammadiyahan
  "https://covers.openlibrary.org/b/id/5913926-L.jpg?default=false", // H.O.S. Cokroaminoto
  "https://covers.openlibrary.org/b/id/5363698-L.jpg?default=false", // Harta & Yayasan Soeharto
  "https://covers.openlibrary.org/b/id/6307484-L.jpg?default=false", // Iblis Nusantara Dajjal Dunia
  "https://covers.openlibrary.org/b/id/6258996-L.jpg?default=false", // Ibu, Tamparlah Mulut Anakmu
  "https://covers.openlibrary.org/b/id/4321849-L.jpg?default=false", // Inul!
  "https://covers.openlibrary.org/b/id/6259020-L.jpg?default=false", // Islam Mazhab Hmi
  "https://covers.openlibrary.org/b/id/3716623-L.jpg?default=false", // Islam, Negara, dan Demokrasi
  "https://covers.openlibrary.org/b/id/13526294-L.jpg?default=false", // Istri Konsul
  "https://covers.openlibrary.org/b/id/13732482-L.jpg?default=false", // Kejahatan Korupsi dan Penegakan Hukum
  "https://covers.openlibrary.org/b/id/6718167-L.jpg?default=false", // Kumpulan Karangan.
  "https://covers.openlibrary.org/b/id/6684869-L.jpg?default=false", // Langit Tiada Batas
  "https://covers.openlibrary.org/b/id/13333970-L.jpg?default=false", // Leadership Quotient
  "https://covers.openlibrary.org/b/id/13867825-L.jpg?default=false", // Masih Bersama Langit
  "https://covers.openlibrary.org/b/id/3716493-L.jpg?default=false", // Membangun Demokrasi
  "https://covers.openlibrary.org/b/id/13438773-L.jpg?default=false", // Membangun Koperasi Pertanian Berbasis Anggota
  "https://covers.openlibrary.org/b/id/13212459-L.jpg?default=false", // Memoar Oei Tjoe Tat
  "https://covers.openlibrary.org/b/id/6258064-L.jpg?default=false", // Memperkokoh Integrasi Bangsa
  "https://covers.openlibrary.org/b/id/6308568-L.jpg?default=false", // Menengok Sejarah Konstitusi Indonesia
  "https://covers.openlibrary.org/b/id/5330966-L.jpg?default=false", // Menjadi Indonesia.
  "https://covers.openlibrary.org/b/id/11304393-L.jpg?default=false", // Merry Riana, Mimpi Sejuta Dollar
  "https://covers.openlibrary.org/b/id/13853007-L.jpg?default=false", // Mochtar Lubis Bicara Lurus
  "https://covers.openlibrary.org/b/id/6355460-L.jpg?default=false", // Nyi Rambut Kasih
  "https://covers.openlibrary.org/b/id/15239302-L.jpg?default=false", // Olenka
  "https://covers.openlibrary.org/b/id/8791026-L.jpg?default=false", // Pandangan Hidup =
  "https://covers.openlibrary.org/b/id/4322038-L.jpg?default=false", // Patiwangi
  "https://covers.openlibrary.org/b/id/6258785-L.jpg?default=false", // Pelurusan Sejarah Indonesia
  "https://covers.openlibrary.org/b/id/6670752-L.jpg?default=false", // Pengertian Pancasila
  "https://covers.openlibrary.org/b/id/5645127-L.jpg?default=false", // Perekonomian Indonesia
  "https://covers.openlibrary.org/b/id/8616074-L.jpg?default=false", // Perjalanan Hidup Empat Kalifah Rasul yang Agung
  "https://covers.openlibrary.org/b/id/6047266-L.jpg?default=false", // Pertempuran Lima Hari Lima Malam di Palembang
  "https://covers.openlibrary.org/b/id/10513793-L.jpg?default=false", // Politik, Budaya, dan Perubahan Sosial
  "https://covers.openlibrary.org/b/id/14361381-L.jpg?default=false", // Refleksi dan Gagasan Kebijakan Fiskal
  "https://covers.openlibrary.org/b/id/14318442-L.jpg?default=false", // Rekayasa Sosial
  "https://covers.openlibrary.org/b/id/4930831-L.jpg?default=false", // Saman
  "https://covers.openlibrary.org/b/id/13339182-L.jpg?default=false", // Sang Guru
  "https://covers.openlibrary.org/b/id/13194747-L.jpg?default=false", // Sarinah
  "https://covers.openlibrary.org/b/id/6288590-L.jpg?default=false", // Sejarah Pemikiran Hak-Hak Asasi Manusia di Indonesia
  "https://covers.openlibrary.org/b/id/6667039-L.jpg?default=false", // Sejarah Sastra Indonesia
  "https://covers.openlibrary.org/b/id/6257984-L.jpg?default=false", // Sufisme Jawa
  "https://covers.openlibrary.org/b/id/14071583-L.jpg?default=false", // Surat dari Palmerah
  "https://covers.openlibrary.org/b/id/14241508-L.jpg?default=false", // Tanbih Al-Masyi
  "https://covers.openlibrary.org/b/id/8725507-L.jpg?default=false", // Taoko
  "https://covers.openlibrary.org/b/id/15252979-L.jpg?default=false", // The 48 Laws of Power
  "https://covers.openlibrary.org/b/id/13452367-L.jpg?default=false", // Tirai Bambu
  "https://covers.openlibrary.org/b/id/4322030-L.jpg?default=false", // Tunjammu Kekasih
  "https://covers.openlibrary.org/b/id/7369760-L.jpg?default=false", // Yang Akan Dilakukan?
  "https://covers.openlibrary.org/b/id/6275507-L.jpg?default=false", // Perilaku Organisasi Polri
  "https://covers.openlibrary.org/b/id/15093786-L.jpg?default=false", // Gerakan Pembaharuan Pemikiran Islam
  "https://covers.openlibrary.org/b/id/5355784-L.jpg?default=false", // Bergerak!
  "https://covers.openlibrary.org/b/id/6590252-L.jpg?default=false", // Aliran dan Paham Sesat di Indonesia
  "https://covers.openlibrary.org/b/id/4296869-L.jpg?default=false", // Ada Apa Dengan Cinta?
  "https://covers.openlibrary.org/b/id/6294391-L.jpg?default=false", // Mari Bung, Rebut Kembali!
  "https://covers.openlibrary.org/b/id/6128216-L.jpg?default=false", // Gus Dur dan Pupusnya Dwi Tunggal
  "https://books.google.com/books/content?vid=ISBN9789798251030&printsec=frontcover&img=1&zoom=1", // Indonesia bagian dari desa saya
  "https://upload.wikimedia.org/wikipedia/id/a/a8/Duniasophie-cover-inggris.JPG?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Dunia Sophie
  "https://upload.wikimedia.org/wikipedia/id/5/58/Surga_yang_Tak_Dirindukan.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Surga yang Tak Dirindukan
  "https://upload.wikimedia.org/wikipedia/id/d/d1/Totto-chan.png?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Totto-chan: Gadis Cilik di Jendela
  "https://upload.wikimedia.org/wikipedia/commons/3/3d/Nemoe_Karma.png?utm_source=en.wikipedia.org&utm_campaign=api&utm_content=original", // Nemoe Karma
  "https://books.google.com/books/content?vid=ISBN9789795410676&printsec=frontcover&img=1&zoom=1", // Kroco
  "https://covers.openlibrary.org/b/id/4250542-L.jpg?default=false", // Kota yang bernama dan tak bernama
  "https://books.google.com/books/content?vid=ISBN9789798615115&printsec=frontcover&img=1&zoom=1", // Sebutir mangga di halaman gereja
  "https://books.google.com/books/content?vid=ISBN9789799073020&printsec=frontcover&img=1&zoom=1", // Tidak
  "https://covers.openlibrary.org/b/id/545567-L.jpg?default=false", // Nyanyi sunyi seorang bisu
  "https://upload.wikimedia.org/wikipedia/commons/9/99/Ebcosette.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Les Misérables
  "https://books.google.com/books/content?vid=ISBN9789794977224&printsec=frontcover&img=1&zoom=1", // Semar mencari raga
  "https://books.google.com/books/content?vid=ISBN9789794590638&printsec=frontcover&img=1&zoom=1", // Bujang jauh
  "https://books.google.com/books/content?vid=ISBN9789795410683&printsec=frontcover&img=1&zoom=1", // Byar pet
  "https://books.google.com/books/content?vid=ISBN9789796697397&printsec=frontcover&img=1&zoom=1", // Garis lurus, garis lengkung
  "https://books.google.com/books/content?vid=ISBN9789794613467&printsec=frontcover&img=1&zoom=1", // Manusia Indonesia
  "https://books.google.com/books/content?vid=ISBN9789796661954&printsec=frontcover&img=1&zoom=1", // Polemik kebudayaan
  "https://books.google.com/books/content?vid=ISBN9789794180082&printsec=frontcover&img=1&zoom=1", // Perkembangan kebatinan di Indonesia
  "https://books.google.com/books/content?vid=ISBN9789794331248&printsec=frontcover&img=1&zoom=1", // Identitas politik umat Islam
  "https://books.google.com/books/content?vid=ISBN9789794442449&printsec=frontcover&img=1&zoom=1", // Ratu Pasemah tak dapat tidur
  "https://books.google.com/books/content?vid=ISBN9789795532699&printsec=frontcover&img=1&zoom=1", // Ziarah malam
  "https://books.google.com/books/content?vid=ISBN9789791140256&printsec=frontcover&img=1&zoom=1", // Mestakung
  "https://books.google.com/books/content?vid=ISBN9789792499513&printsec=frontcover&img=1&zoom=1", // Soeharto sehat
  "https://upload.wikimedia.org/wikipedia/id/1/18/Summer_Breeze.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Summer breeze (poster film)
  "https://upload.wikimedia.org/wikipedia/id/6/68/Emma_poster.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Athirah (poster film)
  "https://upload.wikimedia.org/wikipedia/id/d/d5/Diatas_Sajadah_Cinta.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=original", // Di atas sajadah cinta (poster sinetron)
]);

/**
 * Real covers that the automatic checks reject (plain white or very light
 * designs), approved in the review.
 */
export const ACCEPTED_COVERS = new Set<string>([
  "https://covers.openlibrary.org/b/id/3929331-L.jpg?default=false", // Para Priyayi
  "https://covers.openlibrary.org/b/id/14541663-L.jpg?default=false", // Rindu (Tere Liye)
]);

/** Book ID → categories, primary first. */
export const CATEGORY_OVERRIDES: Record<string, Category[]> = {
  bk_8ebf75f0942f00cc: ["Puisi"], // Dikatakan atau Tidak Dikatakan, Itu Tetap Cinta (kumpulan sajak)
  bk_ea1852fc06289c06: ["Kumpulan Cerpen"], // Dokumen Jibril
  bk_b8d85c28d1a42045: ["Agama"], // Keadilan Ilahi
  bk_670bc324ae232ee6: ["Kumpulan Cerpen"], // Rectosrev
  bk_63950912a488cd23: ["Nonfiksi Umum", "Sejarah"], // Tongkonan
  bk_32ec858b8f983e9b: ["Pengembangan Diri"], // #AboutFriends
  bk_7c1ceb1edf9a44cf: ["Pengembangan Diri"], // #AboutLife
  bk_3ff1f11a3dd27f55: ["Agama", "Pengembangan Diri"], // #mncrgknskl
  bk_388fbe28b49917f7: ["Nonfiksi Umum", "Sejarah"], // 10 dosa besar Soeharto
  bk_27fa3606da2afa16: ["Agama", "Pengembangan Diri"], // 100 nasihat kepemimpinan Aa Gym
  bk_ca8020d3aca12ef3: ["Biografi", "Sejarah"], // 100 Tokoh Abad ke-20
  bk_2e55fb58adaf083f: ["Remaja", "Novel"], // 12 Cerita Glen Anggara
  bk_01cdab32d14b2e23: ["Sains"], // 14 Penyakit Berbahaya Yang Kamu Harus Tahu
  bk_8f31eaeea0d0d91d: ["Agama", "Biografi"], // 150 kisah Ali ibn Abi Thalib
  bk_fe0eb772f8122e0a: ["Novel"], // 1998
  bk_f3e7ec2dfbf20c4d: ["Nonfiksi Umum", "Sejarah"], // 226 Asal-Usul Sejarah
  bk_cd6bd26cbcc2e7b2: ["Pengembangan Diri"], // 366 Reflections of Life
  bk_c401bff144d9125e: ["Bisnis"], // 45 kisah bisnis top pilihan
  bk_199e63ec64a54b38: ["Biografi", "Sejarah", "Agama"], // 50 Pendakwah Pengubah Sejarah
  bk_a276bd72b73b0971: ["Kumpulan Cerpen", "Novel"], // 9 dari Nadira
  bk_b011cb5e1647835f: ["Bisnis", "Biografi"], // 9 jalan pengusaha
  bk_d234242a8ff1b760: ["Nonfiksi Umum"], // 9 jawaban sastra Indonesia
  bk_f43117361a911a91: ["Puisi", "Agama"], // 99 untuk Tuhanku
  bk_bdb48cf133ade6b5: ["Nonfiksi Umum"], // A book about nothing
  bk_be5fd3deab0a2f3a: ["Biografi"], // A child called 'It'
  bk_0782412a520f6490: ["Novel"], // A Game of Thrones
  bk_b887fcc5b36cf434: ["Nonfiksi Umum", "Agama"], // Abdurrahman Wahid selama era lengser
  bk_5787acde4a5e3fe9: ["Novel", "Remaja"], // Across the nightingale floor
  bk_91e862be3c2c6cfe: ["Nonfiksi Umum", "Sejarah"], // Adat Minangkabau Menghadapi Revolusi
  bk_0cc2ea28843c3dbe: ["Remaja", "Novel"], // Aerial
  bk_d8e650fc0da1695f: ["Agama", "Remaja"], // Agar Bidadari Cemburu Padamu
  bk_7b205dd0451ad36e: ["Agama", "Remaja"], // Agar Jatuh Cinta Tak Jadi Bencana
  bk_b3035d87b0568f30: ["Nonfiksi Umum"], // Agenda mendesak bangsa
  bk_363855626bb49192: ["Biografi", "Sejarah"], // Agus Salim
  bk_336a0ce42844fd28: ["Biografi", "Sastra Klasik"], // Aku
  bk_c92675b4fa5e9795: ["Agama", "Pengembangan Diri"], // Aku Dan Hijrah
  bk_d3bfcfa7921386f3: ["Puisi"], // Aku ingin jadi peluru
  bk_9a4bf697ee99ca19: ["Nonfiksi Umum", "Biografi"], // Aku Papua Aku Indonesia
  bk_e1a922cdf2e7b288: ["Kumpulan Cerpen"], // Alamak!
  bk_7fc6948561ca1c0d: ["Novel"], // Anak Bajang Menggiring Angin
  bk_b68d184273b98ed9: ["Biografi"], // Anak lumpur menggapai matahari
  bk_e9b644ab52e81375: ["Novel", "Biografi"], // Anak sejuta bintang
  bk_01e193382ce88821: ["Anak", "Sains"], // Animal Antics
  bk_54af9f797972825c: ["Kumpulan Cerpen"], // Anjing Mengeong, Kucing Menggonggong
  bk_c614ef93c357e60a: ["Kumpulan Cerpen"], // Antara Jimbaran dan Lovina
  bk_4049fd94db1b53b2: ["Novel"], // Antasena dan Antareja
  bk_f565098068727b23: ["Sastra Klasik"], // Antologi Drama Indonesia, Jilid 1 (1895-1930)
  bk_b53874c6a47e9e87: ["Biografi", "Novel"], // Argenteuil
  bk_4b779346fda236df: ["Nonfiksi Umum"], // Arsitektur yang Lain, Sebuah Kritik Arsitektur
  bk_e9f380c8afba5171: ["Novel"], // Arus bawah
  bk_a4b951ddee1bdd4c: ["Nonfiksi Umum"], // Asian Games 2018
  bk_5dec76d629ed9b77: ["Anak", "Novel"], // Asyiknya bertualang di kampung Naga
  bk_013f42f281e01926: ["Novel"], // Atap
  bk_067bc669ce5c4cf3: ["Sastra Klasik", "Novel"], // Atheis
  bk_93296b097def00c8: ["Novel", "Biografi"], // Athirah
  bk_ca03cf8cb4132e4e: ["Pengembangan Diri"], // Atomic Habits: Perubahan Kecil yang Memberikan Hasil Lu
  bk_83e3958793e780e5: ["Novel"], // Avontur
  bk_9ec49dba0965c454: ["Novel", "Agama"], // Ayat-Ayat Cinta
  bk_ab47411aec31532e: ["Sastra Klasik", "Novel"], // Azab dan Sengsara
  bk_a4915106c53032d7: ["Novel", "Remaja"], // Babi ngesot
  bk_0506668876332b48: ["Anak"], // Babi Sombong dan Kuda Kurus
  bk_438b20d87b39469c: ["Nonfiksi Umum"], // Bahasa menunjukkan bangsa
  bk_907df5e2ff61ad92: ["Nonfiksi Umum"], // Balikpapan Dalam Sastra Indonesia
  bk_d85580296b678601: ["Remaja", "Novel"], // Bangun dong, Lupus!
  bk_00a9c7e145d9f0a9: ["Nonfiksi Umum", "Sejarah"], // Batik
  bk_ff236145addc576a: ["Nonfiksi Umum"], // Being Indonesian
  bk_2cc15019a10f36af: ["Biografi"], // Belahan jiwa
  bk_326ac236e48846d3: ["Sastra Klasik", "Novel"], // Belenggu
  bk_cc335bf38c890f9b: ["Biografi", "Agama", "Sejarah"], // Berangkat dari pesantren
  bk_2e26a1cbca5d1ec4: ["Nonfiksi Umum", "Sains"], // Berkawan Harimau Bersama Alam
  bk_b9d4e2fefa771e61: ["Nonfiksi Umum"], // Berkenalan Dengan Existensialisme
  bk_74df08f5d3e5ae3f: ["Nonfiksi Umum", "Biografi"], // Berserah itu indah
  bk_f037dcaa530e105e: ["Novel"], // Bertanya atau mati!
  bk_e796b5e7abf9b00f: ["Kumpulan Cerpen", "Sastra Klasik"], // Bertanya kerbau pada pedati
  bk_c2e2ca5894c3b518: ["Pengembangan Diri"], // Bicara Itu Ada Seninya
  bk_a0803165ab6d8308: ["Kumpulan Cerpen"], // Bidadari yang mengembara
  bk_e22a84a4a7c7da14: ["Novel", "Remaja"], // Bintang Pun Tersenyum
  bk_f0a8b1f165bd203b: ["Sastra Klasik", "Novel"], // Boenga Roos dari Tjikembang
  bk_c4efb11ff78f4b47: ["Remaja", "Novel"], // Brothermaker
  bk_7d6abe17a4094cb4: ["Kumpulan Cerpen"], // Buanglah Hajat Pada Tempatnya
  bk_a066b76a2c8d9755: ["Agama", "Remaja"], // Buktikan cintamu!
  bk_2a64226c66e76809: ["Novel"], // Bulan jingga dalam kepala
  bk_0bf569e79cb7515f: ["Novel", "Agama"], // Bumi Hijrah
  bk_026fb11ed09815ef: ["Biografi", "Sejarah"], // Bung Karno
  bk_4f2af1346ed9a30c: ["Biografi", "Sejarah"], // Bung Tomo, dari 10 Nopember 1945 ke Orde Baru
  bk_e82e218903b8cc83: ["Biografi"], // Burung-burung cakrawala
  bk_a3b78db880ff9123: ["Biografi", "Sejarah"], // Butir-butir padi B.M. Diah
  bk_a004945860ffa136: ["Novel"], // Cadl
  bk_c8521aae2bc28511: ["Agama"], // Cahaya Baru
  bk_435441527ea9beef: ["Novel"], // Cala Ibi
  bk_f0420c978fc4d1e1: ["Nonfiksi Umum"], // Catatan Najwa
  bk_7154a308a63400b7: ["Nonfiksi Umum"], // Catatan Najwa 2
  bk_b579f4982bd3c00d: ["Biografi", "Sejarah"], // Catatan Seorang Demonstran
  bk_fee100b20fe6c1e6: ["Biografi", "Sastra Klasik"], // Catatan-catatan Rendra tahun 1960-an
  bk_888d520a0e07a9dd: ["Novel"], // Celebrity wedding
  bk_c53cef1ffe57f1c8: ["Novel", "Biografi"], // Cerita cinta Enrico
  bk_faa40c6df8497559: ["Sastra Klasik", "Kumpulan Cerpen"], // Cerita dari Digul
  bk_74bced57545f3170: ["Kumpulan Cerpen", "Agama"], // Cerita-cerita pengantin
  bk_55532b6c931ac0be: ["Pengembangan Diri"], // Change Now!
  bk_186d171773fe4e45: ["Novel", "Remaja"], // Cinta Brontosaurus
  bk_721d7891850f8c4f: ["Novel", "Agama"], // Cinta di Langit Qatar
  bk_80664bd12f80994a: ["Remaja", "Novel"], // Cinta Gaya Britney
  bk_a2a18e4857ec802d: ["Remaja", "Novel"], // Cinta Itu Indah, Fren!
  bk_c0155468bea4fe0f: ["Kumpulan Cerpen"], // Cinta tak ada mati
  bk_2f0c77d755dea2da: ["Kumpulan Cerpen"], // Cokelat postmortem
  bk_068f1d4995eb6cb4: ["Kumpulan Cerpen"], // Corat-coret di toilet
  bk_f41389b330ae53cd: ["Biografi"], // Cosmas Batubara, sebuah otobiografi politik
  bk_dad36de46ee8f803: ["Remaja", "Novel"], // Cowok matre
  bk_d03af4ef25c203ef: ["Biografi", "Sejarah"], // Cut Nyak Din
  bk_9ffe0cbf96a6f05e: ["Novel", "Remaja"], // D'Bijis
  bk_3c8dd4510d37b799: ["Nonfiksi Umum"], // Dari Belakang Gawang
  bk_e194cba603b5f7ff: ["Kumpulan Cerpen", "Novel"], // Dari datuk ke sakura emas
  bk_7cd09f95ac1fef65: ["Nonfiksi Umum"], // Dari langit
  bk_f6d87edb683fd998: ["Kumpulan Cerpen"], // Dari mana datangnya mata
  bk_fc26309a33c71b29: ["Biografi", "Novel"], // Dari Parangakik ke Kampuchea
  bk_3d6105231d3e99a0: ["Biografi", "Novel"], // Dari Rue Saint Simon ke Jalan Lembang
  bk_5c9d73fecc5473cf: ["Nonfiksi Umum", "Sejarah"], // Dari Soekarno sampai SBY
  bk_164a7559d2acf655: ["Novel"], // Daylight
  bk_f7319b2f30407179: ["Remaja", "Novel"], // Dear Dylan
  bk_1edc453380d9ecff: ["Novel", "Agama"], // Dear, Imamku
  bk_3baf4be2f4fece52: ["Agama", "Sejarah"], // Dekolonisasi gereja di Indonesia
  bk_b3e1516ec6f9cab2: ["Novel"], // Dendang
  bk_57cc889286a89356: ["Biografi", "Sejarah"], // Detik-detik yang menentukan
  bk_ae0d46184fb672d2: ["Kumpulan Cerpen", "Agama"], // Di atas sajadah cinta
  bk_439a7db67dc2d7cf: ["Sastra Klasik", "Kumpulan Cerpen"], // Di Dalam Lembah Kehidupan
  bk_25aa2be404cd4aff: ["Biografi", "Agama"], // Di Lembah Sungai Nil
  bk_760306e4ab1c84bc: ["Novel", "Agama"], // Di Serambi Makkah
  bk_fc12465b45b69849: ["Sastra Klasik", "Novel"], // Dian yang Tak Kunjung Padam
  bk_da07a7e2afec9a02: ["Novel", "Remaja"], // Dilan
  bk_fd4ead1a47cf86ef: ["Novel", "Remaja"], // Divergent
  bk_55bd857151c3b0cf: ["Anak", "Agama"], // Do Re Mi Hafizhah
  bk_4328fa19c4575544: ["Remaja", "Novel"], // Dokter, pelukis, dan si cowok plin-plan
  bk_aa566051418a1a3c: ["Sastra Klasik", "Novel"], // Drama dari Krakatau
  bk_edb7d9a3d4191108: ["Kumpulan Cerpen"], // Dua dunia
  bk_295ccca74d46b138: ["Novel"], // Dua Muka Daun Pintu
  bk_61742198331c622d: ["Kumpulan Cerpen"], // Dua tengkorak kepala
  bk_780567fa0f730963: ["Kumpulan Cerpen"], // Dunia Perempuan
  bk_4e617b3a766fa678: ["Remaja", "Novel"], // Dylan, I Love You!
  bk_ebd2b781a9973254: ["Nonfiksi Umum"], // Eksotopi
  bk_c1b55566f498861c: ["Remaja", "Novel"], // EL
  bk_ada4db36af6c3d79: ["Remaja", "Novel"], // Elang Selebritis
  bk_d246606112233603: ["Novel"], // Emma
  bk_79e869edbe253188: ["Nonfiksi Umum"], // Enak, gila!
  bk_09793a816adb5a0e: ["Novel"], // Endorphin
  bk_365dfe3fdb03c63e: ["Agama", "Nonfiksi Umum"], // Era Baru Afghanistan
  bk_f3c66fca033bae96: ["Novel", "Remaja"], // Fantasteen Saving Ludo
  bk_d5375471e3d67dac: ["Novel", "Remaja"], // Fantasteen Scary: Teru Teru Bozu
  bk_c3970d38fe9ca4f1: ["Novel", "Remaja"], // Fantasteen Wonderworks
  bk_304796554c02de5b: ["Novel", "Remaja"], // Fantasteen: Ghost Dormitory in Sidney
  bk_1e80e49199acfd4b: ["Kumpulan Cerpen", "Novel"], // Filosofi Kopi
  bk_bc487e9bba93b304: ["Pengembangan Diri", "Nonfiksi Umum"], // Filosofi Teras
  bk_115d35c6af82168c: ["Novel"], // Firedom
  bk_71494ec3613b387c: ["Sains", "Komik"], // Fisika VS Yohanes Surya
  bk_5291fdcf56726e77: ["Novel"], // Gadis Garut
  bk_82ca12ed5c92f682: ["Sastra Klasik", "Novel"], // Gairah untuk hidup dan untuk mati
  bk_0c6461017fc3e729: ["Biografi", "Sejarah"], // Gajah Mada sang pemersatu bangsa
  bk_c3fc6f102270ae09: ["Novel", "Sejarah"], // Gajahmada
  bk_899c6063728af8a8: ["Novel", "Remaja"], // Gaul Jakarta
  bk_82b805fc99ee48fd: ["Nonfiksi Umum", "Sejarah"], // Geger santet Banyuwangi
  bk_99761694a2251ea0: ["Kumpulan Cerpen"], // Gelak sedih
  bk_a56e68b8ae96fdf1: ["Novel"], // Gelang giok naga
  bk_c3b074770c0b0e80: ["Biografi", "Sejarah"], // Gelap-terang hidup Kartini
  bk_3d4b4430a2a8b4a5: ["Nonfiksi Umum"], // Gempa literasi
  bk_3c1b77ab91819c42: ["Kumpulan Cerpen"], // Gerimis senja di sebuah desa dan 12 cerpen lainnya
  bk_33b1292a9b5e5342: ["Agama"], // Ghirah dan tantangan terhadap Islam
  bk_b15fd025216108fa: ["Nonfiksi Umum", "Biografi"], // Gus Dur garis miring PKB
  bk_f557fa2784fce76e: ["Nonfiksi Umum", "Agama"], // Gus Dur menjawab kegelisahan rakyat
  bk_810c3bfa19a24324: ["Novel", "Agama"], // Hafalan Shalat Delisa
  bk_793e56a0139f7b0b: ["Agama", "Remaja"], // Haid Pertamaku
  bk_1db2b1c056895e07: ["Sastra Klasik", "Novel"], // Hari ini tidak ada cinta
  bk_339dfebd56fffb0a: ["Novel"], // Hari-hari yang tersisa
  bk_7a91b036cba2fbf0: ["Sastra Klasik", "Novel"], // Harimau! Harimau!
  bk_aac024a4896629d5: ["Agama", "Nonfiksi Umum"], // Harmoni di negeri seribu agama
  bk_ff9232f7600d5e14: ["Novel", "Remaja"], // Harry Potter dan Batu Bertuah
  bk_25d4a7e5946d45fa: ["Novel", "Remaja"], // Harry Potter dan Kamar Rahasia
  bk_0c9a317e0a61981f: ["Novel", "Remaja"], // Harry Potter dan Orde Phoenix
  bk_4348ecf27a5155fe: ["Novel", "Remaja"], // Harry Potter dan Pangeran Berdarah-Campuran
  bk_6b8dc35b07df8175: ["Novel", "Remaja"], // Harry Potter dan Piala Api
  bk_863d21272c36fec7: ["Novel", "Remaja"], // Harry Potter dan Relikui Kematian
  bk_623bf000cbbd0bba: ["Novel", "Remaja"], // Harry Potter dan Tawanan Azkaban
  bk_6cdf859e640ef2ad: ["Biografi", "Sains"], // Harta bumi Indonesian
  bk_624102696801f1cc: ["Nonfiksi Umum", "Biografi"], // Harus bisa!
  bk_2f477cc44e00f6ef: ["Biografi", "Sejarah"], // Hatta
  bk_d6eeda54f8f218ef: ["Nonfiksi Umum"], // Hello shinee
  bk_f18bff6f02fc74f9: ["Nonfiksi Umum", "Pengembangan Diri"], // Hidup sederhana
  bk_c1d562e86dbb8bc2: ["Agama", "Remaja"], // Hijab I'm in Love
  bk_5a56cf56471cbd96: ["Sastra Klasik", "Novel"], // Hikayat Siti Mariah
  bk_85006b02ca61cf66: ["Sastra Klasik", "Novel"], // Hilanglah si anak hilang
  bk_f51aa83d21e682e0: ["Novel"], // Hitam
  bk_5db129301cc292ef: ["Pengembangan Diri", "Agama"], // How To Master Your Habits
  bk_27c9d8d1d3d249c6: ["Sastra Klasik", "Kumpulan Cerpen"], // Hujan kepagian
  bk_b2f53953091d9704: ["Kumpulan Cerpen"], // Hujan menulis ayam
  bk_d8a10c9f6e38cb08: ["Remaja", "Novel"], // I four you
  bk_e7c061bb6bf778f6: ["Agama", "Biografi"], // Ibrahim ‘Alaihissalam
  bk_779efdd9e40469ae: ["Biografi"], // Ich Komme aus Sewon
  bk_3b93671e975364a7: ["Remaja", "Novel"], // Ih, syereeem!
  bk_5ae16296ae953482: ["Nonfiksi Umum"], // Ilmu ngglethek Prabu Minohek
  bk_0f2529e972dcec92: ["Nonfiksi Umum"], // Imlek tanpa Gus Dur dan 21 tulisan lainnya
  bk_b64a13485aa6eddb: ["Kumpulan Cerpen"], // Indonesia
  bk_f2bd2a024203a163: ["Remaja", "Novel"], // Infinitely yours
  bk_b51ceea5a7f6d897: ["Sejarah", "Agama"], // Inteligensia Muslim dan kuasa
  bk_86d587929ee5cedc: ["Agama", "Nonfiksi Umum"], // Islam dan Dunia Kontemporer
  bk_53e3185aa2c575e2: ["Agama", "Nonfiksi Umum"], // Islamku, Islam anda, Islam kita
  bk_2c5468c73a8ed840: ["Agama", "Remaja"], // I’m a Hero
  bk_01722b64c42130b1: ["Nonfiksi Umum"], // Jakarta
  bk_60b7f24dfd906b6d: ["Sastra Klasik", "Novel"], // Jalan Tak Ada Ujung
  bk_dcd0db22f5259c7f: ["Novel", "Sejarah"], // Janda dari Jirah
  bk_2aceaafaec711966: ["Novel", "Remaja"], // Jangan beri aku narkoba--
  bk_80f5882f11763c3c: ["Pengembangan Diri"], // Jangan Membuat Masalah Kecil Jadi Masalah Besar
  bk_e000c33663770a1e: ["Nonfiksi Umum"], // Jangan tulis kami teroris
  bk_01087f36bb76e8a1: ["Agama"], // Jangan Tunda Taubatmu
  bk_02fd5ee1be38217a: ["Anak", "Novel"], // Janji sepasang merpati
  bk_ebbb877a6e0f186d: ["Novel"], // Jejak laut
  bk_623933592fede22c: ["Nonfiksi Umum", "Agama"], // Jejak tinju pak Kiai
  bk_ec1c403f2e9033a2: ["Biografi", "Sejarah"], // Jejak-jejak pahlawan
  bk_d3bd91b6ef90c679: ["Biografi", "Sejarah"], // Jenderal TNI anumerta Basoeki Rachmat dan Supersemar
  bk_0649b140833e5c83: ["Biografi", "Novel"], // Jepun negerinya Hiroko
  bk_6a256c776fc51c60: ["Agama"], // Jeritan Kubur
  bk_437c7b355c750eff: ["Biografi"], // Jokowi, pemimpin yang rendah hati
  bk_42b88da8e2db6975: ["Agama", "Pengembangan Diri"], // Jomblo To Hero
  bk_913ef2942d3126a8: ["Agama", "Biografi"], // Journey to Baitul Maqdis
  bk_a8d943a466d4d551: ["Novel"], // Julius Caesar
  bk_154d9a3c0eb84a93: ["Biografi", "Agama", "Sejarah"], // K.H. Ahmad Dahlan: Gelegak Dakwah Sang Penggerak
  bk_591cdbcc5b023497: ["Novel"], // Kabut Sutera Ungu
  bk_2b8b1dc9adb7d8a4: ["Nonfiksi Umum", "Agama"], // Kafir liberal
  bk_2f36c31390fc3214: ["Sastra Klasik", "Novel"], // Kalau Ta' Oentoeng
  bk_4a0baf890122ef3c: ["Novel", "Remaja"], // Kambing Jantan
  bk_0ac1ebaebe16eb21: ["Kumpulan Cerpen", "Novel"], // Kangen
  bk_2cb866b40cd04ee8: ["Remaja", "Novel"], // Kapok Deh Jatuh Cinta
  bk_c43bd4fb83922af5: ["Biografi", "Sejarah"], // Kartosoewirjo
  bk_655e57505eb52f3b: ["Sastra Klasik", "Anak"], // Kawan Bergeloet
  bk_aa418f5d935bc9e0: ["Agama", "Nonfiksi Umum"], // Keadilan sosial dalam Islam
  bk_5b2937131885b077: ["Novel"], // Keajaiban Toko Kelontong Namiya (The Miracles of the Na
  bk_6aa19ff64d8f890f: ["Novel"], // Kebaikan Kurawa
  bk_46df1cacb0f773dd: ["Novel"], // Keberangkatan
  bk_297979805050ade6: ["Pengembangan Diri", "Bisnis"], // Keep your lights on!
  bk_0d59643abbac6a87: ["Novel"], // Kekasih gelap
  bk_8e98a13188ab8f61: ["Nonfiksi Umum"], // Kelirumologi genderisme
  bk_1a576d9bdf19f3b0: ["Novel"], // Kembang Gunung Purei
  bk_a8827a03f5ac638f: ["Biografi", "Bisnis"], // Ken & Kaskus
  bk_32dbe762461b80f1: ["Biografi"], // Kenang-Kenangan Hidup
  bk_9fb0d2a49d840d38: ["Biografi"], // Kenangan-Kenanganku di Malaya
  bk_5e46ded02a7f9d50: ["Nonfiksi Umum", "Bisnis"], // Kentut model ekonomi
  bk_f1c5f5962178a0e8: ["Sejarah", "Biografi"], // Kepada bangsaku; karya² bung Karno pada tahun² 1926, 19
  bk_9477f81b2a95062e: ["Nonfiksi Umum"], // Kepada YTH Presiden RI
  bk_64923875e3616376: ["Novel", "Sejarah"], // Kereta api terakhir ke Jogjakarta
  bk_9a2d77d31c3c8c48: ["Kumpulan Cerpen"], // Kereta tidur
  bk_6de9653c9e9e966b: ["Novel", "Agama"], // Ketika Cinta Bertasbih
  bk_81a31bbc1f0e8d85: ["Nonfiksi Umum"], // Ketika jurnalisme dibungkam sastra harus bicara
  bk_187c84dce0c31420: ["Agama", "Pengembangan Diri"], // Ketika Tuhan Tak Lagi Dibutuhkan
  bk_db4ae2f891619ae2: ["Nonfiksi Umum", "Agama"], // Kiai Bejo, kiai untung, kiai hoki
  bk_7b788d222905b7a5: ["Pengembangan Diri"], // Kiat sukses mengarang novel
  bk_3a61b71e9b0fe2b2: ["Agama", "Anak"], // Kisah Ayah dan Anak dalam Al-Qur`an
  bk_58fba4e975b3c0c2: ["Agama", "Sejarah", "Biografi"], // Kisah Khulafaur Rasyidin
  bk_33bfc3c2e3568353: ["Kumpulan Cerpen"], // Kisah orang-orang capricorn
  bk_978d6c5e791c1eee: ["Kumpulan Cerpen"], // Kisah orang-orang Sagitarius
  bk_11680a419b4b4275: ["Kumpulan Cerpen"], // Kisah orang-orang Scorpio
  bk_870a5d50a3fef87a: ["Agama", "Biografi"], // Kisah Para Ulama Terdahulu Mengelola Waktu
  bk_de18e66630d7379b: ["Agama", "Anak"], // Kisah Seru Dalam Juz Amma
  bk_746db7d650e7b3a7: ["Nonfiksi Umum", "Sejarah"], // Kisah Tanah Jawa
  bk_64d59c26954c6971: ["Sejarah", "Agama"], // Kisah-Kisah Pahlawan Nusantara
  bk_fba70012cb971ed7: ["Agama"], // Kisah-Kisah Penggugah Jiwa, Penguat Iman
  bk_e350805e05e647b5: ["Agama"], // Kitab Al-Hikam
  bk_a68d403e7d459add: ["Novel", "Agama"], // Kitab cinta Yusuf Zulaikha
  bk_3133c51da23af4bb: ["Komik", "Agama"], // Komik 100 kebiasaan nabi
  bk_04ebb9204bcafe5b: ["Komik", "Agama", "Anak"], // Komik Fiqih Untuk Anak
  bk_5144cb9e19082a51: ["Komik", "Agama", "Anak"], // Komik Hari Besar Islam
  bk_c282a85fb88dd935: ["Komik", "Agama", "Anak"], // Komik Tadabur Al-Qur`an
  bk_b5b86d86bef1b30b: ["Biografi"], // Kompor mleduk Benyamin S.
  bk_0a5915cb8be11c1f: ["Nonfiksi Umum"], // Komunikasi jenaka
  bk_e16cfd99c060e438: ["Puisi"], // Konsierto di Kyoto
  bk_36b346b86bdf87c9: ["Anak", "Agama"], // Kreasi Asyik Muslim Cilik
  bk_f2b768173ca0b284: ["Kumpulan Cerpen"], // Kritikus Adinan dan cerita lainnya
  bk_506095a103caa4c9: ["Remaja", "Novel"], // Kudeta Sang Marabunta
  bk_566c343a8a4d789f: ["Novel"], // Kumpulan Karya Agatha Christie (The Agatha Christie Exp
  bk_bbbb38fb04d63428: ["Novel"], // Kun-- fayakun
  bk_5c6c88cd598c1884: ["Remaja", "Novel"], // Kupu-kupu tak berkepak
  bk_1b8797a175ac733d: ["Biografi", "Novel"], // La Grande Borne
  bk_7ba98a7890b6ba74: ["Agama", "Pengembangan Diri"], // La Tahzan
  bk_dcf2659ff9a367a9: ["Agama", "Pengembangan Diri"], // Laa Taghdab: Jangan Marah
  bk_894a3f553378de62: ["Kumpulan Cerpen"], // Laki-laki lain dalam secarik surat
  bk_1aae6eb8376b3c66: ["Kumpulan Cerpen"], // Laluba
  bk_96ac1022c69b7b39: ["Biografi", "Novel"], // Langit dan bumi sahabat kami
  bk_b2f7ffdfc9bd6dda: ["Novel"], // Laskar Pelangi
  bk_1950efcf5fc3859d: ["Novel"], // Layang-layang biru
  bk_bb392bcd3531cb80: ["Sastra Klasik", "Novel"], // Layar Terkembang
  bk_cdc1f9ee8d8578bd: ["Sejarah"], // Lekra dan geger 1965
  bk_519ac1435fac6c8f: ["Agama", "Pengembangan Diri"], // Lembaga Hikmat
  bk_d43eff53e15e3eb7: ["Novel"], // Lia Nathalia
  bk_0b15081baab6b9d8: ["Novel", "Remaja"], // Lockwood & Co.: The Screaming Staircase
  bk_390d07b2aad7ccf7: ["Agama", "Pengembangan Diri"], // Love Your Life
  bk_658b10fa31dd1aef: ["Remaja", "Novel"], // Lupus
  bk_3a5e5c515d0fd532: ["Novel"], // Maaf, maaf, maaf
  bk_30d05dc3121a584e: ["Sejarah", "Nonfiksi Umum"], // Madilog
  bk_0dcd9e70fcc4cac5: ["Biografi", "Bisnis"], // Manufacturing hope: bisa!
  bk_9f47dfc6b273f96b: ["Novel", "Remaja"], // Manusia Setengah Salmon
  bk_041e6fe374c4afb5: ["Remaja", "Novel"], // Mariposa
  bk_deccdabf433fb8f9: ["Nonfiksi Umum"], // Markesot bertutur
  bk_c020e3f43ccba028: ["Novel", "Remaja"], // Marmut Merah Jambu
  bk_6b1aa4d5f2868bfd: ["Nonfiksi Umum"], // Masa depan budaya daerah
  bk_bb7ec61ed8daffcb: ["Pengembangan Diri", "Agama"], // Mata Air Inspirasi
  bk_bed57a510bc3c2e7: ["Biografi", "Sejarah"], // Mata air keteladanan
  bk_255a56b6d4cbc85b: ["Biografi"], // Mata hati sang "pioneer" Indonesia
  bk_ac0423bd84f53d49: ["Novel"], // Mata matahari
  bk_a976445bf8377787: ["Novel"], // Matahari
  bk_9a5b1e15db649d68: ["Novel"], // Matahari di Balik Bukit Partisan
  bk_4c42739d1c60d715: ["Komik", "Agama"], // Mbah Wowok dan Kroni-kroninya
  bk_55d1759cbd298212: ["Agama", "Pengembangan Diri"], // Melahirkan Pemimpin Masa Depan
  bk_99b4651887ac1ad9: ["Puisi"], // Melihat Api Bekerja
  bk_749fbc2e8236a1dd: ["Nonfiksi Umum"], // Melihat Pengarang Tidak Bekerja
  bk_544aab4594c52bee: ["Nonfiksi Umum"], // Memahami film
  bk_6d9d8e0e5049f848: ["Sastra Klasik", "Novel"], // Memang Jodoh
  bk_4452c0a01d40f2e0: ["Agama"], // Membangkitkan energi qolbu
  bk_30bb35a3f9a4ff30: ["Sains", "Nonfiksi Umum"], // Membumikan matematika dari kampus ke kampung
  bk_51569c64844c5066: ["Agama", "Nonfiksi Umum"], // Menalar Tuhan
  bk_03246e814c7eabf7: ["Puisi"], // Menampar angin
  bk_2b04331f01fea842: ["Agama", "Nonfiksi Umum"], // Mencari bening mata air
  bk_e92271788fc4284b: ["Agama", "Pengembangan Diri"], // Mencari Ketenangan di Tengah Kesibukan
  bk_33dbd32170c1cf5a: ["Agama"], // Mengaji Al-Hikam
  bk_681b92c3e96d67c5: ["Nonfiksi Umum", "Agama"], // Mengapa partai Islam kalah?
  bk_4565148b50a98ba4: ["Biografi", "Nonfiksi Umum"], // Mengenang hidup orang lain
  bk_8f69ead227030a8c: ["Biografi", "Nonfiksi Umum"], // Menggugat dari balik penjara
  bk_8ea76b9eb57771a0: ["Nonfiksi Umum"], // Menyemai karakter bangsa
  bk_dfecb4d92ad8317a: ["Sejarah", "Nonfiksi Umum"], // Mereka bilang di sini tidak ada Tuhan
  bk_f5527c4fb253540e: ["Remaja", "Novel"], // MetroPop Klasik: A Week to Forever
  bk_1a0d584d17639676: ["Biografi", "Agama", "Sejarah"], // Mgr. Albertus Sugiyopranoto
  bk_1a515dff9425c5e6: ["Novel", "Remaja"], // Milea
  bk_dec2e50c7fc8fead: ["Novel", "Anak"], // Misteri Gambar Tak Bertuan
  bk_115f7d4f7d4fc0fa: ["Agama", "Sejarah"], // Mistik dan makrifat Sunan Kalijaga
  bk_e765832f8de11ad1: ["Nonfiksi Umum", "Sejarah"], // Mitologi Kanjeng Ratu Kidul
  bk_a7c9a346251243df: ["Agama"], // Mukjizat-mukjizat Bunda Maria
  bk_cd4a34803db4bbf0: ["Remaja", "Novel"], // My friends, my dreams
  bk_56a93dab46b89531: ["Pengembangan Diri", "Bisnis"], // Myelin
  bk_39a1d35ac4d5c343: ["Novel", "Anak"], // Nadya
  bk_1cc909095bb99f22: ["Sejarah", "Biografi"], // Napak tilas ke Belanda
  bk_bc0a2714dd99cf95: ["Biografi", "Sejarah"], // Natsir
  bk_472bef9d519b5036: ["Novel"], // Nayla
  bk_555757dd9299f2b0: ["Agama", "Nonfiksi Umum"], // Negara dalam Perspektif Islam
  bk_12672bc920a52066: ["Nonfiksi Umum", "Sejarah"], // Negara paripurna
  bk_8fa66a1b89b77235: ["Kumpulan Cerpen"], // Neighbourhood tales
  bk_925419995c781149: ["Bisnis", "Pengembangan Diri"], // Ngomongin UANG
  bk_6b8858107247e88b: ["Novel"], // Nineteen Eighty-Four
  bk_07a4ecbcb46858ba: ["Novel", "Sejarah"], // Niskala
  bk_c9e5daa4ad9dbbd4: ["Biografi", "Sejarah"], // Njoto
  bk_5f60f3f4338e1161: ["Puisi", "Sastra Klasik"], // Nyanyi Sunyi
  bk_5cfe1f51d5ddbe19: ["Puisi"], // Nyanyian Maldoror dan Poésies
  bk_dd68738bc40d9e9e: ["Agama", "Nonfiksi Umum"], // Nyepi
  bk_5ecb754f1c10dd50: ["Anak"], // Nyi Loro Kidul
  bk_cb2cf62c46b1d164: ["Sastra Klasik", "Novel"], // Nyonya & nyonya
  bk_8f82176179969b0d: ["Novel"], // Nyonya jetset
  bk_ee7606150162915a: ["Novel", "Biografi"], // Obama Anak Menteng
  bk_b7ee1d59193282ab: ["Remaja", "Novel"], // Olga
  bk_0e09d21143779f31: ["Nonfiksi Umum"], // Orang-orang kampus
  bk_15e48b7b87c471b6: ["Puisi"], // Otopsi Syair
  bk_6912ac041b7c1678: ["Novel"], // Pada Sebuah Kapal
  bk_a9ddb92568bcef28: ["Biografi", "Sejarah"], // Pahlawan samudera, Kapten Samadikun
  bk_f9bc8bd60e8e622e: ["Biografi", "Sejarah"], // Pak Harto
  bk_b7531b98b3f7ab53: ["Novel"], // Panah patah Sangkuriang
  bk_e7dda183ed624c6f: ["Biografi", "Sejarah"], // Pangeran Antasari
  bk_9870807123b8ae8b: ["Novel", "Sejarah"], // Pangeran Cakrabuana
  bk_94e8da3577fdf656: ["Novel", "Sejarah"], // Pangeran Diponegoro
  bk_9f71b8344f4a8531: ["Puisi"], // Pantun Melayu
  bk_84b33f74c7fac33b: ["Agama", "Nonfiksi Umum"], // Paradigma Islam
  bk_849c6481ed509f06: ["Novel"], // Paradoks Waktu
  bk_c30d93678e6e4331: ["Kumpulan Cerpen"], // Parang tak berulu
  bk_9d88d8a9cf10aa14: ["Novel"], // Paranormal
  bk_52028074322fa164: ["Agama"], // Pedihnya Sakaratul Maut Gelapnya Malam Pertama Di Alam 
  bk_ecda8cf3a63aa6ef: ["Nonfiksi Umum", "Bisnis"], // Pelajaran dari Tiongkok
  bk_0936178b02ad1ef6: ["Nonfiksi Umum", "Sejarah"], // Pencak silat
  bk_cae1b8e146087b19: ["Nonfiksi Umum", "Sejarah"], // Pendudukan gedung DPR/MPR
  bk_e2323b6161a7b38c: ["Novel"], // Penelusuran Benang Merah (A Study in Scarlet) *Hard Cov
  bk_a2389da179a04b52: ["Novel", "Biografi"], // Pengakuan eks parasit lajang
  bk_a1d8f601c86f7929: ["Puisi", "Sastra Klasik"], // Pengakuan Pariyem
  bk_03dfd1eb1c8cd019: ["Novel", "Remaja"], // Perahu Kertas
  bk_88ee99bed6e07f41: ["Sastra Klasik", "Kumpulan Cerpen"], // Percikan Revolusi Subuh
  bk_15c8d0853d164fde: ["Sastra Klasik", "Kumpulan Cerpen"], // Perempuan
  bk_357c9db9fbe4b234: ["Kumpulan Cerpen"], // Perempuan di kamar sebelah
  bk_ad64f69176ffe856: ["Novel"], // Perempuan lain
  bk_144e4f4baaf892ba: ["Novel"], // Perjalanan ke negeri damai
  bk_25f3fb1b9b089d68: ["Sejarah", "Agama"], // Perjuangan Yang Dilupakan
  bk_9d48c007d8abde26: ["Kumpulan Cerpen"], // Persekongkolan ahli makrifat
  bk_346776a26373eaae: ["Pengembangan Diri"], // Personality plus
  bk_45063ece07e824c4: ["Nonfiksi Umum"], // Petruk jadi guru
  bk_5c2e22ab03d71c37: ["Novel", "Anak"], // Petualangan Huckleberry Finn
  bk_9cba2223b08c3982: ["Novel"], // Pintu
  bk_2ced774ff246b5a5: ["Novel"], // Pintu Terlarang
  bk_7860057b3d469ff9: ["Nonfiksi Umum", "Sejarah"], // Pit onthel
  bk_23485b6d3209c4ac: ["Nonfiksi Umum"], // Politik ideologi dan sastra hibrida
  bk_19047c2511d87c04: ["Biografi", "Novel"], // Pondok baca kembali ke Semarang
  bk_1c48241e581bbde1: ["Novel", "Agama"], // Prahara Buddenovsky
  bk_b65d373ccac8e814: ["Novel"], // Pride & Prejudice
  bk_536af73a5ba704da: ["Agama", "Nonfiksi Umum"], // Prisma pemikiran Gus Dur
  bk_5bb820d32acddf75: ["Nonfiksi Umum"], // Proses pelapukan
  bk_4fc8393d51bc6df2: ["Puisi"], // Puisi mbeling
  bk_1d7734a447bfeef7: ["Puisi"], // Puisi mbeling
  bk_071cc4b28bf49048: ["Novel"], // Puya ke Puya
  bk_64d5804c4a7839b0: ["Novel", "Remaja"], // Radikus makankakus
  bk_68ce891f1e3e6aa4: ["Anak", "Novel"], // Rahasia di Pulau Karang
  bk_d4f2ee5f4a6ce276: ["Agama"], // Rahasia Jiwa-jiwa di Api Penyucian
  bk_fe3416aec1a2ce86: ["Novel", "Sejarah"], // Rahasia Meede
  bk_d4b55c8f2e952de4: ["Nonfiksi Umum"], // Rakyat (bukan) tumbal (kekuasaan & kekerasan)
  bk_760d0d91e699f2ef: ["Novel"], // Ramayana
  bk_019c5c23b9dd56f3: ["Novel", "Sejarah"], // Rara Mendut: Sebuah Trilogi
  bk_4e5b7f247c732450: ["Nonfiksi Umum", "Sejarah"], // Ratu Kidul
  bk_f0f4977f13ecc008: ["Novel"], // Rawa
  bk_5b31436756b513ce: ["Pengembangan Diri", "Biografi"], // Reach Your Dreams
  bk_58fc6f95ac0f10ff: ["Novel", "Remaja"], // Red
  bk_8326add768e01788: ["Puisi"], // Refrein di sudut dam
  bk_3dbfd82e0b859c04: ["Novel", "Agama"], // Rembulan Di Padang Cinta
  bk_cc7e63a023a2d5dd: ["Kumpulan Cerpen", "Sastra Klasik"], // Robohnya Surau Kami
  bk_4cb3e75b230b878b: ["Novel"], // Rumus Kebenaran Musim Panas (A Midsummer's Equation)
  bk_a12bd46e9df2f463: ["Kumpulan Cerpen"], // Sagra
  bk_355bd1f0bd1a4f57: ["Agama", "Anak", "Biografi"], // Sahabiyah Stories for Kids: Meneladani Sifat-Sifat Muli
  bk_0ef83234e25db4c1: ["Sains", "Anak"], // Sainspedia
  bk_ce95b2ed0bd844a3: ["Novel"], // Saman
  bk_7d5a90646bd74610: ["Biografi", "Bisnis"], // Sang burung biru
  bk_d8452a893121664c: ["Novel", "Sejarah", "Agama"], // Sang Pangeran dan Janissary Terakhir
  bk_31644d7932aff20c: ["Nonfiksi Umum", "Biografi"], // Sang Pemimpin
  bk_35b40c117ca27d5a: ["Novel", "Biografi", "Sejarah"], // Sang pencerah
  bk_adc6a8f01a271714: ["Novel"], // Sang Raja Jin
  bk_7dc3ff5b6f471e80: ["Novel", "Remaja"], // Saraswati
  bk_fe254160aa171b9d: ["Biografi", "Sejarah"], // Sarwo Edhie dan misteri 1965
  bk_5d3ed6a73928e1a9: ["Nonfiksi Umum"], // Sastra, moral, dan kreativitas
  bk_189c32b282679792: ["Biografi", "Sastra Klasik"], // Saya terbakar amarah sendirian
  bk_a03b8b3ce034300b: ["Novel"], // Sebuah catatan, Untuk Kita Renungkan
  bk_a629434db53a82f0: ["Novel"], // Secret love
  bk_8b434cc94c7ed16d: ["Nonfiksi Umum", "Agama"], // Sedang Tuhan pun cemburu
  bk_d6a200a5a3da2c61: ["Biografi", "Novel"], // Sekayu
  bk_ca1c04dbba5b50d6: ["Nonfiksi Umum"], // Sekolah
  bk_02d8b5f437ee0896: ["Novel", "Agama"], // Selamat Malam Kabutku Sayang
  bk_0c398d8fa34c5757: ["Biografi", "Pengembangan Diri"], // Selasa Bersama Morrie
  bk_868e748655dca42a: ["Novel"], // Selebriti
  bk_e424fa627ec485d9: ["Sejarah", "Nonfiksi Umum"], // Semerbak bunga di Bandung Raya
  bk_8ee2e0d1a597d606: ["Biografi"], // Semua berawal dengan keteladanan
  bk_012fa02dee7c8c7c: ["Kumpulan Cerpen", "Sejarah"], // Semua untuk Hindia
  bk_2979e9b89a4f3735: ["Novel"], // Sengkarut meja makan
  bk_8ed0551051c79ad7: ["Sastra Klasik", "Novel"], // Sengsara Membawa Nikmat
  bk_3191f03ee0025af0: ["Pengembangan Diri"], // Seni Berbicara Kepada Siapa Saja, Kapan Saja, di Mana S
  bk_4f10875a86b3127b: ["Sastra Klasik", "Novel"], // Senja di Jakarta
  bk_463266fc4481f679: ["Novel", "Sejarah"], // Senopati Pamungkas
  bk_94dd243eb1ff2a92: ["Novel"], // Seorang lelaki di Waimital
  bk_08e40fc369324eaa: ["Nonfiksi Umum", "Sejarah"], // Sepak bola Indonesia
  bk_7b5f29fe05f180b3: ["Remaja", "Novel"], // Seratus Bunga Mawar untuk Mr. Valentine
  bk_5a780a857c159e62: ["Biografi", "Sejarah"], // Seratus Tokoh Yang Paling Berpengaruh Dalam Sejarah
  bk_3c8c1d6724b2e3aa: ["Kumpulan Cerpen"], // Seribu kunang-kunang di Manhattan
  bk_843f43745b47356d: ["Nonfiksi Umum"], // Seruling jiwa
  bk_db73c6b21b8adaab: ["Kumpulan Cerpen", "Remaja"], // Serupa Daun, Kita pun Gugur
  bk_730f6bfc1a3f2d91: ["Biografi", "Sejarah"], // Sewindu dekat Bung Karno
  bk_b1d09561136dce45: ["Novel"], // Si Anak Cahaya
  bk_47b8d7194fe1c8c1: ["Novel", "Anak"], // Si anak panah
  bk_89164c658caa93ad: ["Komik"], // Si Juki
  bk_36567d6c4ac1f0b2: ["Anak"], // Si Untung
  bk_2afe3d402dfd7cd0: ["Nonfiksi Umum", "Puisi"], // Sihir Rendra
  bk_0227ada5309f2c84: ["Biografi", "Agama"], // Sine qua non, dancing with the holy spirit, 1964-2014
  bk_07b61079c47b95c1: ["Nonfiksi Umum"], // Singgasana dan kutu busuk
  bk_0f26cac551b02e85: ["Novel", "Sejarah"], // Soegija, 100% Indonesia
  bk_d5ceb0cf37ead3fa: ["Nonfiksi Umum"], // Still more about nothing
  bk_308c2d14580cf21b: ["Agama"], // Sufi pinggiran
  bk_9c4392b0322591e5: ["Anak", "Biografi"], // Suir Syam Anak Petani
  bk_576a0621c79ccd50: ["Pengembangan Diri", "Bisnis"], // Sukses tanpa gelar
  bk_79ebe2ef30d4ccad: ["Puisi"], // Suluk
  bk_8c221607cb772665: ["Remaja", "Novel"], // Summer breeze
  bk_824bb32f3317b394: ["Biografi", "Agama"], // Surat kepada anjing hitam
  bk_98539dbf97af01d7: ["Puisi"], // Surat untuk ayah
  bk_5fd0ac22bb947700: ["Novel", "Sejarah"], // Sutasoma
  bk_88bf7a84239969c7: ["Biografi", "Sejarah"], // Tahta untuk rakyat
  bk_4a91816ebda56553: ["Nonfiksi Umum"], // Tak enteni keplokmu
  bk_ac053910dcc1915e: ["Novel"], // Tambo
  bk_d2d6bad93af3ff2d: ["Kumpulan Cerpen"], // Tanah baru, tanah air kedua
  bk_291532f915cd4c3e: ["Novel"], // Tanah Tabu
  bk_6ea7e6036d1f597d: ["Remaja", "Novel"], // Tangkaplah daku, kau kujitak!
  bk_733ef382a686bdf2: ["Agama"], // Tasauf, Perkembangan dan Pemurniannya
  bk_66b4ed1f2cae29a6: ["Remaja", "Novel"], // TeenLit: Marshmallow Cokelat
  bk_d4b06c85b8733452: ["Novel"], // Tempias di beranda
  bk_1bba2be389b0087d: ["Novel"], // Tentang Kamu
  bk_34068cdd811efe43: ["Agama"], // Terjemahan Al Hikam
  bk_38df67bc3a016d3a: ["Agama", "Pengembangan Diri"], // Tersenyumlah
  bk_d264e1926f4bbb5d: ["Pengembangan Diri"], // The Art of Dealing with People
  bk_d9131ee7cb37cc0d: ["Sains"], // The Body
  bk_8d9eb3db6980da4c: ["Novel", "Anak"], // The Chronicles of Narnia: Pangeran Caspian (Prince Casp
  bk_6d17291371f1a161: ["Novel", "Anak"], // The Chronicles of Narnia: Pertempuran Terakhir (The Las
  bk_50fc1e493ba2fc69: ["Novel", "Anak"], // The Chronicles of Narnia: Petualangan Dawn Treader (The
  bk_58f59e5c0cb763f2: ["Novel"], // The Fellowship of the Ring
  bk_5270075f1b4c55b7: ["Novel", "Remaja"], // The Hate U Give
  bk_697b285ea3817b7a: ["Bisnis", "Biografi"], // The leadership secrets of Soekarno
  bk_19e1c6059d59d00a: ["Novel"], // The lunch gossip
  bk_49d5071a7cddd09f: ["Novel", "Sains"], // The Martian
  bk_07782c8320288ecc: ["Novel", "Remaja"], // The Midnight Star
  bk_8eade154a27128dd: ["Anak"], // The Perfect Cakes
  bk_02079e91f9f7a9a9: ["Novel"], // The Perfect World of Miwako Sumida
  bk_9d810c7b282e4842: ["Novel"], // The Return of the King
  bk_99652a58736732d1: ["Novel", "Sejarah"], // The rise of Majapahit
  bk_3ed5c849bbd0d889: ["Novel", "Remaja"], // The Rose Society
  bk_4e993ba1f93b2a8f: ["Novel", "Remaja"], // The Young Elites
  bk_7c92fa75b1282d50: ["Novel"], // Ti amo, Tia Amoria
  bk_6ca1b84830461573: ["Novel", "Remaja"], // Timun Jelita
  bk_960955fcd157c7fa: ["Remaja", "Novel"], // Titanium
  bk_131b643d895377a2: ["Sastra Klasik", "Novel"], // Tjerita Si Tjonat
  bk_ebbd101cf46f6e91: ["Biografi", "Sejarah"], // Tjokroaminoto
  bk_931c650619c83149: ["Anak", "Novel"], // Toki si Kelinci Bertopi
  bk_27eda2db2deb8d4b: ["Novel", "Remaja"], // Tolong, Radith membuat saya bego!
  bk_afc50b05a6985dca: ["Nonfiksi Umum", "Sejarah"], // Tongkonan (rumah adat Toraja)
  bk_c7c9242a75376f5b: ["Remaja", "Novel"], // Topan Marabunta
  bk_176d47b39b380100: ["Remaja", "Novel"], // Topi-topi centil
  bk_f7f948d534d83208: ["Remaja", "Novel"], // Trust Me!!
  bk_61a5add425e45842: ["Novel"], // Tuan besar
  bk_96918e2d7ac863f0: ["Sastra Klasik", "Novel"], // Tuan Direktur
  bk_458efd233a8fbdfa: ["Novel"], // Tuyul anakku
  bk_15c65b602710f402: ["Nonfiksi Umum", "Pengembangan Diri"], // Twitografi Asma Nadia
  bk_6037a22fb4f31dbf: ["Agama", "Pengembangan Diri"], // Ubah Cara Berpikir: Faa Inna Ma’al ‘Usri Yusra
  bk_1c6b04e66feaaaa4: ["Novel"], // Ular Tangga
  bk_904c0f5e81fc04cf: ["Agama"], // Umat Islam menghadapi tantangan Kristenisasi dan sekula
  bk_7a0d467b5fd79d97: ["Pengembangan Diri", "Bisnis"], // Unlimited Wealth: 17 Hari Menuju Kebebasan Finansial
  bk_f5fd06c1c2aea28e: ["Bisnis", "Pengembangan Diri"], // Untuk Indonesia yang kuat
  bk_ceeb5abea7574c0b: ["Novel"], // Upacara
  bk_b53fd14a9aed64dd: ["Agama", "Pengembangan Diri"], // Upgrade!
  bk_f19ed1b7e899a502: ["Remaja", "Novel"], // VOC (Vacaran On Cinta-cintaan)
  bk_6c8eda50013db7be: ["Biografi", "Sejarah"], // Warkop
  bk_2da53030097bf9d7: ["Kumpulan Cerpen"], // Warna kita
  bk_9de2fca1d9069d4b: ["Nonfiksi Umum", "Sejarah"], // Wawancara imajiner dengan Bung Karno
  bk_b3530ee7ecd8c7c3: ["Nonfiksi Umum"], // Wayang kulit purwa gaya Yogyakarta
  bk_a0bdba238e49c6d2: ["Agama", "Remaja"], // Why not?
  bk_c24f70018bdf00d5: ["Biografi", "Sejarah"], // Wiji Thukul
  bk_52de1f1903271248: ["Biografi"], // Wimar Witoelar
  bk_fdf32413c344e49d: ["Biografi", "Nonfiksi Umum"], // Yang datang telanjang
  bk_164e836d85fb416f: ["Agama"], // Yaumul Qiyamah
  bk_38d0b844fd16e26e: ["Biografi"], // Yuni Shara & cangkir kopi
  bk_e7ebb3afc1415e84: ["Nonfiksi Umum", "Sejarah"], // Zaman peralihan
  bk_4e205071e10690f3: ["Novel"], // Zat
  bk_a1489fae246601c5: ["Biografi", "Nonfiksi Umum"], // Di Atas Siang di Bawah Malam (renungan eks-tapol, bukan buku anak)
  bk_faadfc3ec56f79f6: ["Remaja", "Novel"], // Artemis Fowl
  bk_e2c9383f1334c24d: ["Novel"], // Jodoh (Fahd Pahdepie)
  bk_b2adcbe0743665a0: ["Remaja"], // Cinta Olimpiade (Hilman)
  bk_d8c737fa6b62ce04: ["Remaja"], // Tragedi Sinemata (Hilman)
  bk_0e5f9ddb09d108d7: ["Nonfiksi Umum", "Agama"], // Humor Ngaji Kaum Santri
  bk_7a4b8031314beca9: ["Puisi"], // Matahari-Matahari Kecil: Pilihan Sajak
  // Review of the 30 Oct 2026 run
  bk_537da5f566f1c802: ["Puisi"], // Tidak Ada New York Hari Ini
  bk_79778833e1217d83: ["Agama"], // 7 Malam Pertama di Alam Kubur
  bk_696ccfa38fd2d88d: ["Kumpulan Cerpen"], // Cerita Rakyat Jawa Barat
  bk_1917f696340d6967: ["Nonfiksi Umum", "Sejarah"], // Pandangan Hidup (Tan Malaka)
  bk_1727709630d2909d: ["Novel"], // Sepotong Hati di Sudut Kamar
  bk_55293b0908d49009: ["Agama", "Remaja"], // Ngefriend Sama Islam
  bk_0523619ce5b0a2bc: ["Novel", "Anak"], // Kokokan Mencari Arumbawangi
  bk_eb9e2a90f979d47e: ["Kumpulan Cerpen"], // Tugu Kemakmuran
  // Books left as "Lainnya" (30 Oct 2026)
  bk_017d315acfd549f5: ["Bisnis", "Biografi"], // The Ciputra's Way
  bk_20cfd4e6df4fa66a: ["Novel"], // The Darkness of Gatotkaca
  bk_37fb561c7fbdc607: ["Remaja", "Novel"], // Mimi Elektrik
  bk_87a0642aef025b3d: ["Kumpulan Cerpen"], // Dunia di Kepala Alice
  bk_bd5c9aba1a235359: ["Kumpulan Cerpen"], // Lipstik dalam Tas Doni
  bk_f767d779232939b7: ["Nonfiksi Umum"], // Ideologi Politik dan Teater Modern Indonesia
  bk_f85b4f5055478c01: ["Sejarah"], // Di Bawah Lentera Merah
  bk_8f7eea18d53902df: ["Puisi"], // Angin Sumilir: Javanese guritan
  bk_b732737250359663: ["Novel"], // Meretas Ungu
  bk_243d0b7c5137ab47: ["Biografi"], // Interupsi!
  bk_13e867aed168e993: ["Nonfiksi Umum"], // Romansa Cyber
  bk_6aa80f0228219f06: ["Nonfiksi Umum"], // Uap
  bk_0bc34942b592f005: ["Nonfiksi Umum"], // BOR
  bk_c056f168a5829053: ["Kumpulan Cerpen"], // Sarapan Pagi Penuh Dusta
  bk_9539da1be7923617: ["Kumpulan Cerpen"], // Dua Tangisan pada Satu Malam
  bk_0495c3e0387450a2: ["Novel"], // Jamangilak Tak Pernah Menangis
  bk_2c1dbe3d9d78f0a2: ["Biografi"], // Mencari Makna Hidupku: Bunga Rampai Perjalanan Sujatin Kartowijono
  bk_d06d8491fe089b3f: ["Puisi"], // Nyanyian Integrasi Bangsa
  bk_0b7fcd9ca2ccae06: ["Puisi"], // Ghirah Gatha
  // Second run of 30 Oct 2026 (adult, political, academic and technical books admitted)
  bk_6b78bba280c92c4e: ["Novel", "Remaja"], // Area X
  bk_513b19d517556f06: ["Novel"], // Bella Donna Nova
  bk_6159d35ebbdfcf14: ["Novel"], // Sintren
  bk_ef82acd8b537f531: ["Novel"], // Warrior
  bk_d08a4591e6bed608: ["Nonfiksi Umum"], // (Digital) Executive Legislator
  bk_51caf60a06f6f003: ["Nonfiksi Umum"], // 100 Efek Spektakuler Photoshop
  bk_2d2fbefb8d269601: ["Nonfiksi Umum"], // 100 Film
  bk_cacd84d187db4723: ["Agama"], // 200 Fikih Praktis Sehari-Hari
  bk_55a0100e1d30f9b7: ["Pengembangan Diri"], // 40 Hari Mengatasi Kecanduan Game pada Anak
  bk_69c8a8cadaccf8ee: ["Anak", "Agama"], // 40 Kisah Pengantar Tidur
  bk_f8d205c4c1940d6a: ["Agama", "Pengembangan Diri"], // 60 Rahasia Jadi Ayah Hebat
  bk_28c38ac1b9b9a376: ["Agama", "Bisnis"], // Adab Bekerja dan Berbisnis
  bk_751cff973af95011: ["Bisnis"], // Advertising That Sells
  bk_f4746292f6968db3: ["Agama", "Pengembangan Diri"], // Agar Ayah Enggak Masuk Neraka
  bk_143a4d694ee8620a: ["Agama"], // Agar Muslimah Mantap Menikah
  bk_a24a9ac8168247e8: ["Bisnis"], // Akuntansi Biaya
  bk_2dbf09afd33de4e1: ["Sains", "Nonfiksi Umum"], // Algoritma & Pemrograman dalam Bahasa Pascal dan C Edisi Revi
  bk_bfe78ba8a7b2107a: ["Nonfiksi Umum"], // Alternatif Kebijakan Pengaturan Hak Atas Tanah Beserta Bangu
  bk_dc9aea6fe0fd2273: ["Nonfiksi Umum", "Biografi"], // Amien Rais Menjawab Isu-Isu Politis Seputar Kiprah Kontrover
  bk_067760428976e433: ["Nonfiksi Umum"], // Analisa Situasi Sistem Peradilan Pidana Anak (Juvenile Justi
  bk_330f8aea3ba105d6: ["Bisnis", "Nonfiksi Umum"], // Analisis Ekonomi Politik Indonesia
  bk_72eadec76c2ca205: ["Bisnis"], // Analisis Laporan Keuangan
  bk_42a522afb9d39ac6: ["Nonfiksi Umum"], // Anatomi Lelucon di Indonesia
  bk_514357694cc47cd3: ["Bisnis"], // Anjak Piutang
  bk_62b9fb66af0ea101: ["Agama"], // Apa Bahayanya Menikah dengan Wanita Nonmuslim?
  bk_fe9ff6732885ac0e: ["Sains", "Nonfiksi Umum"], // Aplikasi Analisis Multivariate
  bk_ed11b12aa9a7ed59: ["Nonfiksi Umum"], // Arbitrase dan Mediasi di Indonesia
  bk_1479bf330634ab5f: ["Nonfiksi Umum"], // Arsitektur Radakng: Kehidupan Komunal dan Dayak Kanayatn
  bk_427f3daacfa82ded: ["Nonfiksi Umum", "Bisnis"], // Aspek-Aspek Hukum Perbankan di Indonesia
  bk_fb4d588d9a9022e4: ["Agama", "Sains"], // Ayat-Ayat Sehat
  bk_0d516c8b53b5365b: ["Agama"], // Baby Guide for Muslim
  bk_28c9d551b07d5458: ["Nonfiksi Umum"], // Bagaimana Anti-Kekerasan Melindungi Negara
  bk_9e51b75246a13fa5: ["Kumpulan Cerpen"], // Bahaya Merokok di Ranjang
  bk_b06fbc21c69499e9: ["Nonfiksi Umum", "Sains"], // Bangunan Air
  bk_9fcb5fdb576a04bb: ["Bisnis", "Agama"], // Bank Syariah
  bk_a60c5e30b6528068: ["Agama"], // Barakallahu Laka: Bahagianya Merayakan Cinta
  bk_1dead35b81273f58: ["Anak"], // Batu Belah Batu Bertangkup
  bk_5ff51d2ba69e0569: ["Bisnis"], // Be G2c
  bk_eef5ddd1c5613885: ["Bisnis", "Pengembangan Diri"], // Begini Harusnya Bisnis!
  bk_c39293a007c63a9e: ["Agama"], // Berani Mencintai Bernyali Menikahi
  bk_932d3e77d517bd34: ["Agama", "Pengembangan Diri"], // Berjuta Rasa Menjadi Papah-Mamah Muda
  bk_41c8512cdf8905a8: ["Agama"], // Bikin Nikah Tak Jadi Masalah
  bk_1f5def9a1ac665f3: ["Sejarah", "Nonfiksi Umum"], // Blok Pembangkang
  bk_7e5e7a4547f11a19: ["Agama"], // BookMagz #1: Aku Siap Menikah Sekarang!
  bk_7d15dfdfef9f0e1e: ["Bisnis"], // Budaya Korporat dan Keunggulan Korporasi
  bk_c9b60425f22343a5: ["Agama", "Nonfiksi Umum"], // Bukan Kapitalisme Bukan Sosialisme
  bk_ec77b20f8eeb1ec9: ["Anak"], // Buku Abjad ABC Binatang
  bk_465c127eab807616: ["Novel", "Remaja"], // Buku Panduan Matematika Terapan
  bk_088c0ffdcdaab303: ["Nonfiksi Umum"], // Buku Panduan Suling Sunda Lubang 11 Multi Laras dan Surupan
  bk_369b8c4e58d72e53: ["Nonfiksi Umum", "Bisnis"], // Buku Pintar Kepabeanan
  bk_d37f97761d6a6476: ["Nonfiksi Umum"], // Buku Praktis Mendeley untuk Mahasiswa
  bk_bde7aa571716dc50: ["Sains", "Nonfiksi Umum"], // Bumi Makin Panas
  bk_1e397a125b5ea8b9: ["Bisnis", "Nonfiksi Umum"], // BUMN Indonesia
  bk_933afb275da0ba10: ["Bisnis"], // Cara Mudah Memahami Laporan Keuangan
  bk_99a19f540de87e55: ["Bisnis"], // Cara Simpel Berinvestasi di Pasar Modal Volume I Edisi Revis
  bk_a92e79d70db9d6be: ["Bisnis"], // Cara Simpel Berinvestasi di Pasar Modal Volume II
  bk_67994cb9ec52dd4b: ["Nonfiksi Umum", "Sejarah"], // Cendekiawan dan Kekuasaan dalam Negara Orde Baru
  bk_24a9a08a8408b565: ["Agama", "Sains"], // Cerdas Dan Salehkan Bayi Anda Dengan ASI
  bk_c71d874e4232a9c9: ["Bisnis"], // Cerdas Mengelola Keuangan
  bk_1e4f9374cc6a26e1: ["Bisnis"], // Cerdas Mengelola Keuangan Keluarga
  bk_a1ac21c0c8d4cdc1: ["Anak", "Agama"], // Cerita Si Ayam
  bk_cd439ba75101d51f: ["Anak", "Agama"], // Cerita Si Katak
  bk_ff7eef0dae1c24fb: ["Anak", "Agama"], // Cerita Si Kelinci
  bk_c96bf1275044548f: ["Anak", "Agama"], // Cerita Si Kucing
  bk_7804cd8955fa5274: ["Anak", "Agama"], // Cerita Si Lebah
  bk_462f7ce246873e8d: ["Anak", "Agama"], // Cerita Si Sapi
  bk_cdf84d88eb25deb7: ["Anak", "Agama"], // Cerita Si Singa
  bk_73dce494beb9b192: ["Anak", "Agama"], // Cerita Si Siput
  bk_c6408948be6f3abf: ["Anak", "Agama"], // Cerita Si Zebra
  bk_850397e74819f1ad: ["Nonfiksi Umum", "Bisnis"], // Change Management dalam Reformasi Birokrasi
  bk_a2db908ffd48ead2: ["Agama", "Pengembangan Diri"], // Character Building
  bk_767fc7e2b05165b1: ["Novel"], // Cinta 24 Jam
  bk_3bd69a5bb68f4d5b: ["Novel"], // Cinta Abadi
  bk_876df4c2ec2c8465: ["Pengembangan Diri", "Agama"], // Dari Abah Ihsan
  bk_d55d414f68abeeeb: ["Nonfiksi Umum"], // Dari Anak Sampai Usia Lanjut
  bk_610c3b07dea24bc7: ["Nonfiksi Umum"], // Dari Papua Meneropong Indonesia
  bk_86d5c1a0f591da51: ["Sains", "Nonfiksi Umum"], // Dasar Mekanika Tanah
  bk_2626867ae47ce541: ["Bisnis"], // Dasar Penilaian Properti Rumah Mewah: Investasi, Kapitalisai
  bk_c617521a9a0fb5f3: ["Agama"], // Dasar-Dasar Ilmu Al-Qur'an
  bk_e5b07bca853a5a76: ["Nonfiksi Umum", "Sains"], // Deforestasi Tanpa Henti
  bk_16ce12dbd4d116dc: ["Nonfiksi Umum"], // Delik-Delik Tertentu (Speciale Delicten) dalam KUHP
  bk_4d21ed3aa1589533: ["Novel"], // Demi Kehormatan
  bk_c1accc879dd2b14a: ["Nonfiksi Umum", "Sains"], // Desain Hidraulik Bangunan Irigasi
  bk_fdf2e9023a2e2b8b: ["Biografi"], // Dia
  bk_29644c80bc37c158: ["Agama", "Sains"], // Diet Islami
  bk_09b499c3d4f2bde0: ["Nonfiksi Umum"], // Diksi dan Gaya Bahasa
  bk_f49ae8f64f6cef65: ["Nonfiksi Umum", "Agama"], // Dilema PKS
  bk_9f7a2790e64efc34: ["Nonfiksi Umum"], // Dinamika Pembangunan Pertanian dan Pedesaan
  bk_d6b18da17b744b23: ["Nonfiksi Umum"], // Dominasi Penuh Muslihat
  bk_d38ce0067a885f19: ["Nonfiksi Umum", "Sains"], // Drainase Perkotaan
  bk_843ea0462d9b6f6c: ["Bisnis"], // Easy Copywriting: Contek Abis, Sampai Laris!
  bk_822c57e641c58f7a: ["Nonfiksi Umum"], // Education Games
  bk_f243b80825222619: ["Nonfiksi Umum", "Bisnis"], // Ekonomi Politik Media Penyiaran
  bk_c72ab9c055a33aed: ["Biografi"], // Eksplorasi Kreativitas Dua Dasawarsa Anne Avantie
  bk_5b6ce608ccdc7d7a: ["Bisnis"], // Family Business Responses to Future Competition
  bk_6b245c5255d4e36c: ["Agama", "Pengembangan Diri"], // Fatherman1
  bk_3f79b2bc7bd6fe9d: ["Nonfiksi Umum"], // Feminogr[a]fi
  bk_0e424e6ae3be48e9: ["Agama"], // Filsafat Pendidikan Islam
  bk_0c06a764fcf5a42c: ["Nonfiksi Umum"], // Fonetik dan Fonologi Melodi Bahasa: Prosodi
  bk_9fbcf041353bea3f: ["Bisnis"], // Franchising, the Most Practical and Excellent Way of Succeed
  bk_f54b2292b1be7d35: ["Bisnis"], // Fundamental vs Technical
  bk_f61f79e7a98c8dfe: ["Nonfiksi Umum", "Agama"], // Fundamentalisme, Terorisme, dan Radikalisme
  bk_6e8c096517d2adad: ["Novel"], // Garis Tepi Seorang Lesbian
  bk_7b33a62c1a8ba5a1: ["Nonfiksi Umum"], // Gender dan Administrasi Publik
  bk_4681ce21288dce4d: ["Nonfiksi Umum"], // Gender dan Strategi Pengarus-Utamaannya di Indonesia
  bk_67a4c784c7da5f89: ["Nonfiksi Umum", "Agama", "Sejarah"], // Gerakan Perlawanan dari Masjid Kampus
  bk_06f8c8da67a34f9b: ["Nonfiksi Umum", "Agama"], // Getar Gender
  bk_7ed1e37eaec6b6d1: ["Agama", "Sains"], // Gigi Sehat Ibadah Dahsyat
  bk_913e93514be5b00a: ["Nonfiksi Umum"], // Good E-Government
  bk_ba22bf217a87a1b1: ["Komik", "Remaja"], // Grey & Jingga
  bk_5ed170731ee32969: ["Anak", "Novel"], // Hadiah Alam
  bk_39b49b0ecfff7df8: ["Nonfiksi Umum"], // Hak Kekayaan Intelektual
  bk_7ac2b5a0fb640d9d: ["Sejarah", "Biografi"], // Hamengku Buwono IX dan Sistem Birokrasi Pemerintahan Yogyaka
  bk_a6aa184db1d499d2: ["Agama", "Pengembangan Diri"], // Hati-Hati Terhadap Media Yang Merusak Anak
  bk_12c3343e9c4d6355: ["Bisnis"], // Hermawan Kartajaya on Marketing
  bk_45c12fde7196b328: ["Sains", "Nonfiksi Umum"], // Hidrologi Teknik
  bk_19090d50ee6028cc: ["Agama"], // Hikmah Mempesona Dari Anakku
  bk_ee1571cc97cfdd49: ["Nonfiksi Umum"], // Hitam Putih Prostitusi
  bk_641f963b881f27f0: ["Bisnis", "Agama"], // HRD Syariah
  bk_958f0bde8c4233b8: ["Nonfiksi Umum"], // Hukum Media Massa Nasional
  bk_c1cb4f4290171add: ["Nonfiksi Umum"], // Hukum Perbatasan Darat Antarnegara
  bk_fb6d54ec43d09061: ["Agama", "Nonfiksi Umum"], // Hukum Perdata Islam di Indonesia
  bk_55aa4002c7db9815: ["Agama", "Nonfiksi Umum"], // Hukum Perdata Islam di Indonesia
  bk_e2d368485a2aeeec: ["Nonfiksi Umum"], // Hukum Perjanjian Internasional
  bk_3aed716e293ac9e1: ["Nonfiksi Umum", "Bisnis"], // Hukum Persaingan Usaha
  bk_879399dfb4987fc3: ["Agama", "Nonfiksi Umum"], // Hukum Pidana Islam
  bk_917424904fb686ed: ["Nonfiksi Umum"], // Hukum Tata Negara Indonesia
  bk_fc070fbcebaef57a: ["Nonfiksi Umum", "Sains"], // Hutan & Kehutanan
  bk_876de66f49387aee: ["Novel"], // I Love You, Om---
  bk_f6e06e89d874c8fb: ["Nonfiksi Umum"], // Identitas Dayak
  bk_f06ad127c5acb139: ["Agama", "Nonfiksi Umum"], // Ideologi Islam dan Utopia
  bk_601e288d3767d86d: ["Agama", "Sejarah"], // Indonesianisasi, dari Gereja Katolik di Indonesia Menjadi Ge
  bk_8895d40561a7a076: ["Bisnis"], // Industrialisasi dan Wiraswasta
  bk_c208fe883c0a9f74: ["Agama", "Sejarah"], // Injil dan Marapu
  bk_895ba9deeb8dfbad: ["Biografi", "Pengembangan Diri"], // Inspired by Indayati Utomo
  bk_cee1d2265764b82b: ["Agama", "Nonfiksi Umum"], // Integrasi Ilmu dan Agama
  bk_ad6c34ae97c412a3: ["Agama", "Nonfiksi Umum"], // Islam dan Dinamika Sosial Politik di Indonesia
  bk_7235b34b51ff4202: ["Agama", "Nonfiksi Umum"], // Islam dan Kedaulatan Rakyat
  bk_460a08ca130e09da: ["Agama"], // Islam Pribumi
  bk_34ee7062a1d7a528: ["Agama"], // Islam Rahmatan Lil 'Alamin
  bk_c2f3882933c91b2f: ["Agama", "Nonfiksi Umum"], // Islam Sebagai Kritik Sosial
  bk_93064e4c70104341: ["Agama", "Nonfiksi Umum"], // Islam, Demokratisasi, dan Pemberdayaan Civil Society
  bk_1f08c27a20f518b7: ["Agama"], // Istri Cerdas
  bk_8b96295e6634bde9: ["Novel"], // Istri Kontrak
  bk_f64021feae83d9f8: ["Agama", "Nonfiksi Umum"], // Istriku Seribu
  bk_1baca87aa5fc94e2: ["Agama"], // Istriku, Aku Mencintaimu
  bk_0374f12124b63b96: ["Nonfiksi Umum"], // Jakarta Undercover
  bk_fa5850ef71d52163: ["Nonfiksi Umum", "Sains"], // Jalan Rel
  bk_c143b4914185cd1d: ["Kumpulan Cerpen"], // Jangan Main-Main (Dengan Kelaminmu)
  bk_4400faab6e90ffb7: ["Agama"], // Jundullah
  bk_f6c39820cd5303b7: ["Novel", "Agama"], // Kabut Jihad
  bk_1a389441acfb8939: ["Agama"], // Kado Pernikahan untuk Istriku
  bk_ff32470b8e0d31fe: ["Nonfiksi Umum"], // Kajian Serba Linguistik
  bk_1ce1b8cb818e8dfd: ["Nonfiksi Umum"], // Kapitalisme Televisi dan Strategi Budaya Massa
  bk_d3cf6859b57083c5: ["Sastra Klasik", "Biografi"], // Karya Lengkap Abdullah Abdul Kadir Munsyi
  bk_dbe807bb11ba8cc7: ["Nonfiksi Umum"], // Karya Lengkap Driyarkara
  bk_6dec0a255e6efa69: ["Novel"], // Kawin Kontrak
  bk_4a2f1433137bf90f: ["Bisnis", "Agama"], // Kaya Harta, Kaya Amal
  bk_9362a2ebe5d5bb2d: ["Bisnis"], // Ke Mana Investasi?
  bk_032700729509cfd1: ["Agama"], // Keajaiban Jihad Harta
  bk_774d8c61b4a21d92: ["Nonfiksi Umum"], // Kebangsaan dan Globalisasi dalam Diplomasi
  bk_71c56b58a6f0ea9a: ["Nonfiksi Umum"], // Kebhinnekaan Masyarakat di Indonesia
  bk_da81ecdae90865e1: ["Puisi"], // Kebijakan dalam 1001 Pantun
  bk_2d1b753f1d9a57e0: ["Bisnis"], // Kebijakan Moneter dan Fiskal di Indonesia
  bk_73c6597525200e8a: ["Nonfiksi Umum"], // Kebijakan Pendidikan yang Unggul
  bk_d9999cebf645221a: ["Nonfiksi Umum"], // Kebijakan Perikanan dan Kelautan
  bk_64a0484cbc516260: ["Nonfiksi Umum"], // KEBIJAKAN PUBLIK FORMULASI Kebijakan Publik
  bk_363c6b489d288a7d: ["Nonfiksi Umum"], // Kejaksaan RI
  bk_3303f1489c33f6b5: ["Novel"], // Kekasih Night Wind
  bk_6f3c04ac3f9218aa: ["Nonfiksi Umum"], // Kekhususan Rokok Indonesia
  bk_292e2a6304643d19: ["Nonfiksi Umum"], // Kelas Kata dalam Bahasa Indonesia
  bk_56490aceb4727d4b: ["Agama", "Biografi"], // Kepemimpinan Kharismatis
  bk_ad4b1e1e6c268546: ["Nonfiksi Umum"], // Kepuasan Hidup dan Dukungan Sosial Lanjut Usia
  bk_8d24ef112a91f20b: ["Agama"], // Kerukunan Umat Beragama Pilar Utama Kerukunan Berbangsa
  bk_6d9e6926c32a9504: ["Nonfiksi Umum"], // Keteknikan Videografi
  bk_7a8f04ace80057f8: ["Agama"], // Ketika Aku dan Kamu Jadi Kita
  bk_266d1f98bf45e05e: ["Agama"], // Ketika Aku Mencintaimu
  bk_2c731ccb0ec3adea: ["Agama"], // Ketika Suami Istri Hidup Bermasalah
  bk_704ea542ea3c1c58: ["Sejarah", "Agama"], // Kiai Penghulu Jawa
  bk_27e3ac2faf480c62: ["Bisnis"], // Kilas Kilau Bisnis
  bk_75ec5396113b9c6a: ["Sains"], // Kimia Dasar II
  bk_432bebad2b592591: ["Nonfiksi Umum", "Puisi"], // Kisah Wato Wele-Lia Nurat dalam Tradisi Puisi Lisan Flores T
  bk_5c09ba721a4c7e3b: ["Nonfiksi Umum"], // Komunikasi Estetik
  bk_8cbe654b0de7ab57: ["Nonfiksi Umum"], // Konflik dan Integrasi Politik Gerakan Aceh Merdeka
  bk_110ef86bb1fbad4c: ["Sejarah"], // Kronik Revolusi Indonesia
  bk_d34b92be59906b38: ["Sains"], // Kura-Kura & Buaya Indonesia dan Papua Nugini
  bk_3c4e367ca6110b4b: ["Bisnis", "Biografi"], // Laskar Pejuang 9 Wanita Wirausaha
  bk_9434903da207e5ba: ["Biografi", "Bisnis"], // Lead by Heart
  bk_eaf8339254f16d98: ["Novel"], // Lelaki Terindah
  bk_02949da2c9bbeb3f: ["Agama"], // Lihatlah Sang Manusia!
  bk_85a4ab9c0814b04f: ["Nonfiksi Umum"], // Lobi Zionis & Rezim Bush
  bk_a5b068ad3d24b8f2: ["Biografi", "Agama"], // M. Natsir, Dakwah dan Pemikirannya
  bk_f407da048e1616d0: ["Nonfiksi Umum"], // Mahir Mendongeng
  bk_0751b896d15a6d04: ["Agama", "Sains"], // Makin Sehat Dengan Jilbab
  bk_ddf281e48596d34e: ["Bisnis", "Sains"], // Manajemen Kesehatan
  bk_ac84284638fc4303: ["Nonfiksi Umum", "Bisnis"], // Manajemen Pendidikan Kontemporer
  bk_30497698749ed3cf: ["Bisnis"], // Manajemen Periklanan
  bk_e04053ce7100f724: ["Sejarah", "Nonfiksi Umum"], // Manusia Daya
  bk_d4a42618d401e2be: ["Bisnis"], // Marketing in Crisis
  bk_4d32f4086d48505b: ["Nonfiksi Umum"], // Maubes-Insana
  bk_4e6a42523e3399e9: ["Nonfiksi Umum"], // Mediasi Nonlitigasi Terhadap Sengketa Medik dengan Konsep Wi
  bk_35a1187a037ebfd2: ["Biografi", "Nonfiksi Umum"], // Megawati Soekarnoputri, Harapan dan Tantangan di Kursi Wapre
  bk_01457cd60316bbd4: ["Sains"], // Mekanika Bahan, Jilid 2
  bk_4da45aea851f5cb0: ["Sains"], // Mekanika Teknik
  bk_edaa4a4826cf479c: ["Novel"], // Melisa
  bk_ac9909f7dd1879d2: ["Nonfiksi Umum"], // Memahami Hukum di Indonesia
  bk_7783fc0975c6fc9f: ["Bisnis"], // Memasuki Era BUMN Multinational Coorporation
  bk_acdca0b9177ee92e: ["Nonfiksi Umum"], // Membaca Sastra
  bk_21393282a1d39c02: ["Nonfiksi Umum"], // Membangun Pusat-Pusat di Pinggiran
  bk_d7b9ba8b192a9bbd: ["Agama", "Nonfiksi Umum"], // Membincangkan Feminisme
  bk_6ca69366d12a298e: ["Sejarah"], // Membongkar Supersemar!
  bk_d1631e5cb85fa4bc: ["Bisnis"], // Memilih Bank yang Sehat
  bk_45ab5eb725ac9f5e: ["Agama", "Anak"], // Memperkenalkan Akhlak Mulia Rasulullah kepada Anak
  bk_78363b690bbd398d: ["Novel"], // Menaklukkan Sang Dokter
  bk_57335b99bd974162: ["Nonfiksi Umum"], // Menata Pulau-Pulau Kecil Perbatasan
  bk_b5a87348d25d75c1: ["Nonfiksi Umum"], // Mencapai Pertanian yang Lebih Baik
  bk_0fabd5e5463fffe3: ["Agama", "Pengembangan Diri"], // Mendidik Anak Laki-Laki
  bk_8c5028fd4d399fe6: ["Agama", "Pengembangan Diri"], // Mendidik Anak Perempuan
  bk_e32d7950ff87ee97: ["Nonfiksi Umum"], // Menegakkan Hukum dan Hak Warga Negara
  bk_c47b6b1d6e245fc9: ["Agama"], // Mengantisipasi Masa Depan
  bk_b07cb99102df6385: ["Agama", "Pengembangan Diri"], // Mengasah Pola Pikir Anak
  bk_0cccc7cd3d96a148: ["Sains", "Pengembangan Diri"], // Mengenal Kesehatan Jiwa: Versi PDF Tunggal
  bk_2cdf526c72e9c187: ["Nonfiksi Umum"], // Menghadapi Tantangan Masa Depan
  bk_88d228c7c0f46cd3: ["Agama"], // Menghadapi Tantangan, Memperjuangkan Kerukunan
  bk_20113bcaf4d7c840: ["Sejarah", "Agama"], // Menghidupkan Kembali Jalur Sutra Baru
  bk_fdd23f952508cc00: ["Nonfiksi Umum"], // Menguak Hubungan Dagang Indonesia-Israel
  bk_0ed13b0baba130b2: ["Sains", "Nonfiksi Umum"], // Menguak Tabir & Potensi Jamu Gendong
  bk_9472d51b2a580dff: ["Agama"], // Menikah Memuliakan Sunnah
  bk_78aec39fccf267c8: ["Bisnis", "Pengembangan Diri"], // Menjadi Manajer Sukses
  bk_a7fe337bb259f048: ["Nonfiksi Umum"], // Menjadi Pemimpin Politik
  bk_e1dfad81d2f8de43: ["Agama", "Pengembangan Diri"], // Menjadi Suami & Ayah Hebat
  bk_d683f8977266dd5f: ["Agama", "Bisnis"], // Menuju Era Wakaf Produktif
  bk_9d50e7b03dd1f3c0: ["Agama"], // Menuju Halal
  bk_e8f51afd0cc91a80: ["Nonfiksi Umum"], // Menyandera Timur Tengah
  bk_32c37c565e496fc0: ["Agama"], // Menyelisik Penyimpangan Syi’ah
  bk_0d904410cdd16790: ["Nonfiksi Umum"], // Merah Putih Arsitektur Nusantara
  bk_f68297cb9cddaeed: ["Nonfiksi Umum", "Sains"], // Merancang dan Merencana Lapangan Terbang
  bk_7f330bdb414a3a19: ["Agama"], // Mereka Bukan Thaghut
  bk_fc13c2327fd678d7: ["Sains"], // Metode Numerik
  bk_137f4b56fbde34b6: ["Nonfiksi Umum"], // Metode Perancangan Arsitektur
  bk_609500a4bf61f543: ["Nonfiksi Umum"], // Metodologi Penelitian Kuantitatif
  bk_7097ea0624088c39: ["Agama"], // Misykat
  bk_b6302ed13406acb4: ["Nonfiksi Umum"], // Model Pembelajaran Anak Usia Dini
  bk_468ff2c448435e68: ["Sains"], // Moluska Padang Lamun
  bk_bb015727121b06a1: ["Sains"], // Monograph Identifikasi Mood Ibu Postpartum Menggunakan Skala
  bk_420ada243e1dd073: ["Bisnis"], // Multibagger
  bk_b703e1c9baa625ac: ["Nonfiksi Umum", "Agama"], // Muslim Demokrat
  bk_c98cc5fdc0010fc5: ["Agama", "Bisnis"], // Muslim Preneur
  bk_de70df8525df301d: ["Bisnis"], // Mutasi DNA Powerhouse
  bk_1d7378fad074d5ce: ["Anak"], // My Baby Reads ! I Like Beach Because…
  bk_c88117f3bb4fddef: ["Anak"], // My Baby Reads ! I Love You Because…
  bk_acfd79d367e99044: ["Anak"], // My Baby Reads ! Is That A Bug ?
  bk_ac1baa526f3cfcc3: ["Anak"], // My Baby Reads ! Is That My Belly Button ?
  bk_89a5c297905866b9: ["Anak"], // My Baby Reads ! Where Is My Tail ?
  bk_d160970c583173e4: ["Bisnis", "Nonfiksi Umum"], // Neoliberalisme
  bk_b6e7323bb06daca0: ["Agama"], // Nikmatnya Pacaran Setelah Pernikahan
  bk_be2b0654f28ebb54: ["Nonfiksi Umum", "Agama"], // NKRI Bersyariah atau Ruang Publik yang Manusiawi?
  bk_e9bf84da76080b9f: ["Novel"], // Nyai Gowok
  bk_e2e1ae32c05ca413: ["Anak"], // Nyi Rambut Kasih
  bk_8f4571ebb4787d76: ["Sains", "Nonfiksi Umum"], // Obat-Obatan Ramuan Tradisional
  bk_374f4f8d73541157: ["Bisnis"], // OJK dan Pengawasan Mikroprudensial
  bk_775ab81012e02408: ["Nonfiksi Umum"], // Orang Sakai di Riau
  bk_019e9f87c56a5d58: ["Nonfiksi Umum"], // Origami Tanks
  bk_daa1186f5ebd5bf6: ["Nonfiksi Umum"], // Otonomi Daerah
  bk_e5947f6035226dba: ["Bisnis"], // Pajak dan Strategi Bisnis
  bk_7c843daa2bde4572: ["Nonfiksi Umum"], // Pancasila Budaya Bangsa Indonesia
  bk_9f1f53fc85a39c5a: ["Nonfiksi Umum"], // Panduan Membangun Rumah
  bk_e27adb48c7fd1e0e: ["Nonfiksi Umum"], // Panduan Pengendalian Kebakaran Hutan dan Lahan Gambut
  bk_9ed2298a8d108a36: ["Nonfiksi Umum"], // Panorama Bahasa Indonesia
  bk_7cb3b35e222623c0: ["Nonfiksi Umum"], // Paradigma Baru Pembangunan Pertanian
  bk_fb286c37b6dce1b9: ["Nonfiksi Umum"], // Paradigma Sosiologi Sastra
  bk_7446347d9ecced2b: ["Pengembangan Diri"], // PARENTime
  bk_cadb801fecc90670: ["Bisnis", "Agama"], // Pasar Modal Syariah
  bk_66030cca15f9d633: ["Nonfiksi Umum"], // Pelanggaran HAM dalam Hukum Keadaan Darurat di Indonesia
  bk_9fc0ac343c79676b: ["Agama", "Sejarah"], // Pelangi di Bukit Barisan
  bk_995962c59d558df7: ["Nonfiksi Umum"], // Pelarangan Buku di Indonesia
  bk_d2030e30ab3c858b: ["Nonfiksi Umum", "Bisnis"], // Pelelangan Jasa Kontruksi
  bk_b93e46da1e749643: ["Nonfiksi Umum"], // Pembangunan Pertanian
  bk_a6d176a4bbe9cdf9: ["Bisnis", "Biografi"], // Pembelajaran T.P. Rachmat
  bk_f7e98a575290850c: ["Nonfiksi Umum"], // Pemulung Jalanan Yogyakarta
  bk_8ea2936deb044e61: ["Nonfiksi Umum"], // Pendidikan Indonesia
  bk_d0ae81e7cd40109b: ["Agama"], // Pendidikan Islam
  bk_360e5fcbdf7f9582: ["Nonfiksi Umum"], // Penerjemahan Berdasar Makna (Pedoman untuk Pemadanan Antarba
  bk_7960e998257cc511: ["Nonfiksi Umum"], // Pengantar Ilmu Perang
  bk_2bd3248add886d51: ["Bisnis", "Nonfiksi Umum"], // Pengantar ke Jalan Ekonomi Sosiologi
  bk_2c499ab826dd5497: ["Nonfiksi Umum"], // Pengantar Sastra Rakyat Minangkabau
  bk_371b51d4c71eb6c2: ["Agama"], // Pengantar Teologi Agama-Agama
  bk_998206f5d21470ec: ["Nonfiksi Umum"], // Pengelolaan Lalu Lintas dan Angkutan Jalan
  bk_3cf6880bc7e0155d: ["Bisnis"], // Pengembangan Koperasi
  bk_19b28bcad8df0170: ["Bisnis"], // Penghitungan Pajak Penghasilan Pasal 21 Pegawai
  bk_116e9bac4d35f14f: ["Sejarah"], // Perang Yang Tidak Akan Kita Menangkan
  bk_8512e89a09aab4dc: ["Bisnis", "Agama"], // Perbandingan Sistem Ekonomi
  bk_e9e567eb4f5d03b6: ["Bisnis"], // Perbankan
  bk_cafbe9f3b73eee8b: ["Bisnis", "Agama"], // Perbankan Islam dan Kedudukannya dalam Tata Hukum Perbankan 
  bk_ef3066b5c687bbcc: ["Nonfiksi Umum"], // Percikan Filsafat
  bk_53704674fa3e20eb: ["Agama"], // Perjalanan Menjumpai Tuhan
  bk_963ad8b673eb7b12: ["Agama"], // Perkawinan Menurut Islam dan Katolik
  bk_373ce80c41de42c1: ["Agama", "Sejarah"], // Perkembangan Tafsir Al-Qur'an di Indonesia
  bk_59d8f395c63a6046: ["Nonfiksi Umum"], // Perlindungan Hak Asasi Saksi dan Korban dalam Proses Peradil
  bk_4123ccd877593ffa: ["Agama"], // Pernak-Pernik Romantis
  bk_c007b03c55b8007b: ["Nonfiksi Umum"], // Perpustakaan Digital dari A Sampai Z
  bk_475f7cc3003768dc: ["Anak", "Novel"], // Persahabatan
  bk_771bae4049c933a3: ["Agama", "Nonfiksi Umum"], // Pesantren
  bk_1ae33ef0b596ecac: ["Agama", "Nonfiksi Umum"], // Pesantren Masa Depan
  bk_080bc2af6ecdda1d: ["Kumpulan Cerpen"], // Petualangan Celana dalam
  bk_ae4f9defbd22e3cb: ["Sejarah", "Agama"], // Piagam Perjuangan Kebangsaan
  bk_85c697596f7da690: ["Nonfiksi Umum"], // Pijar-Pijar Filsafat
  bk_ff440b53812f8251: ["Nonfiksi Umum"], // Pokok-Pokok Filsafat Hukum
  bk_6929ccc513a47449: ["Agama"], // Poligami yang Tak Melukai Hati?
  bk_957d867a767b7ec6: ["Nonfiksi Umum"], // Politik Identitas Etnis
  bk_fc76d8b5159a01b8: ["Agama", "Nonfiksi Umum"], // Politik Kristen di Indonesia
  bk_000ccbbc361910c2: ["Nonfiksi Umum"], // Presidensialisme Setengah Hati
  bk_b345a0806747cc8f: ["Puisi", "Sastra Klasik"], // Priangan Si Jelita
  bk_65373178f0395892: ["Biografi", "Agama"], // Prof. Dr. Mgr. N.J.C. Geise, O.F.M., Juragan Visioner
  bk_46972663545a5280: ["Nonfiksi Umum"], // Profil Budaya Politik Indonesia
  bk_c76368423111a579: ["Bisnis"], // Profit Konsisten dengan Ichimoku Kinko Hyo
  bk_cce6d57717833109: ["Pengembangan Diri", "Agama"], // Psikologi Pasangan: Manajemen Konflik Rumah Tangga
  bk_d2a3d3519abbce74: ["Pengembangan Diri", "Agama"], // Psikologi Pernikahan: Menyelami Rahasia Pernikahan
  bk_e83f3855a129b646: ["Nonfiksi Umum"], // Rakyat & Negara dalam Pengadaan Tanah untuk Pembangunan
  bk_d9cd6e92979c62dd: ["Nonfiksi Umum"], // Rakyat Memantau Ibukota, Rakyat Memantau Jokowi Basuki
  bk_caa8951fb83410b9: ["Anak"], // Ratu Sejati dan Lutung Baik Hati
  bk_cd7d144915f64874: ["Nonfiksi Umum", "Agama"], // Referensi bagi Hakim Peradilan Agama tentang Kekerasan dalam
  bk_cdde22c916926262: ["Nonfiksi Umum"], // Reinventing Indonesia
  bk_b37fc90804af00f7: ["Nonfiksi Umum"], // Reinventing Pembangunan
  bk_0198b45718d0e7f5: ["Nonfiksi Umum"], // Rencana Anggaran Biaya
  bk_2630e709a0cec40a: ["Nonfiksi Umum"], // Resistensi Gaya Hidup
  bk_5edf0aa05b8f92c5: ["Nonfiksi Umum"], // Revolusi Sistem Pendidikan Nasional dengan Metode E-Learning
  bk_c76bac81c01591bc: ["Kumpulan Cerpen"], // Rezim Seks
  bk_09168c84171febb5: ["Agama"], // Risalah Kubro Mujarrobat Walisanga
  bk_5385287841173454: ["Sastra Klasik"], // Ritumpanna Wélenrénngé
  bk_b87d1ec0cc3889a0: ["Nonfiksi Umum"], // Rumah Melayu
  bk_d13c307f792d91f1: ["Agama", "Nonfiksi Umum"], // SANTRI-PESANTREN INDONESIA ; Siaga Jiwa Raga Menuju Indonesi
  bk_b67022f6b42f0c31: ["Nonfiksi Umum"], // Sastra dan Ilmu Sastra ; Pengantar Teori Sastra
  bk_063aa3fcf5141a2e: ["Agama"], // Saya Tidak Ingin Poligami Tapi Harus Poligami
  bk_4f64af6f1d7c621b: ["Agama"], // Seandainya Saya Isteri Aa Gym
  bk_3991695403634fe2: ["Sains", "Agama"], // Sehat & Bugar Berobat Dengan Alam
  bk_a1fc09a78c09d223: ["Sains", "Agama"], // Sehat Itu Nikmat
  bk_fe77e18441949047: ["Nonfiksi Umum", "Sejarah"], // Sejarah dan Kedudukan BW di Indonesia
  bk_10ec417147e77521: ["Sejarah"], // Sejarah Indonesia
  bk_4884839156de546b: ["Sejarah"], // Sejarah Kecil "Petite Histoire" Indonesia
  bk_ec35472cfc530d2e: ["Sejarah"], // Sejarah Pemerintahan Kota Surabaya Sejak Masa Kolonial Sampa
  bk_54b21ca4dfff6dd8: ["Agama", "Sejarah"], // Sejarah Perjumpaan Kristen dan Islam di Indonesia
  bk_1c39e2dc69d4fd56: ["Sejarah", "Nonfiksi Umum"], // Sejarah Perkembangan Arsitektur Kota Islam Banten
  bk_252a7d250466c316: ["Nonfiksi Umum", "Puisi"], // Semangat Nasionalisme dalam Puisi Sebelum Kemerdekaan
  bk_d36528d5e6ce6dbb: ["Kumpulan Cerpen"], // Semanyun Senyuman Mahasiswa
  bk_1e478c36081f6e76: ["Nonfiksi Umum"], // Senam Sehat Prana
  bk_4b525a2708fcfb59: ["Agama"], // Seputar Dewan Paroki
  bk_bf2df13a676ddd50: ["Nonfiksi Umum"], // Sesudah Filsafat
  bk_61cc7a8f4b351626: ["Agama"], // Sex Before Married Jilid 1
  bk_a3813ea8af8ad3dd: ["Agama"], // Sex Before Married Jilid 2
  bk_a010e1029387cea1: ["Komik", "Bisnis"], // Si Juki vs Dompet Kosong
  bk_7e6a112dd5017605: ["Novel", "Nonfiksi Umum"], // Sidang Susila
  bk_2ae071cb3a384b83: ["Agama"], // Sistem Dajjal
  bk_fca2a5518b1f3326: ["Bisnis"], // Sistem Informasi Akuntansi
  bk_9612ec243201ea8c: ["Bisnis"], // Sistem Koperasi
  bk_b2d07c8b2f524d66: ["Bisnis"], // Sistem Moneter dan Perbankan di Indonesia
  bk_b5ddbcb2f83695e7: ["Nonfiksi Umum", "Sains"], // Sistem Pertanian Berkelanjutan
  bk_337cab22262bf361: ["Sains", "Agama"], // Solusi Alami Sehatkan Diri
  bk_675ef348bb4bd0d3: ["Nonfiksi Umum", "Sains"], // Sport Psychometrics
  bk_b00e05cad5df8dbe: ["Nonfiksi Umum"], // Stereotip Etnis dalam Masyarakat Multietnis
  bk_9681275a0af1baa0: ["Bisnis"], // Strategi dan Inovasi Model Bisnis Meningkatkan Kinerja Usaha
  bk_33db395ebc13fe1f: ["Nonfiksi Umum"], // Strategi-Strategi Pembangunan Masyarakat
  bk_98f7d7f349b536bb: ["Nonfiksi Umum", "Sains"], // Struktur Bangunan Bertingkat Tinggi
  bk_67e6e39fc351aff0: ["Nonfiksi Umum", "Bisnis"], // Studi Complex Adaptive System (CAS) Proses Pembentukan Klast
  bk_362b407ba07f299a: ["Kumpulan Cerpen"], // Suami Sempurna
  bk_f711d0551436a8ea: ["Agama", "Sejarah"], // Sufisme Jawa
  bk_8eca66e0f1003763: ["Sejarah"], // Supersemar Palsu
  bk_bbf899c2b8ecd362: ["Agama"], // Syamsul Ma'arif
  bk_60e18701d9d85404: ["Nonfiksi Umum"], // Tahapan dan Langkah-Langkah Penelitian
  bk_ffd657a17debea4e: ["Nonfiksi Umum", "Sejarah"], // Tajuk-Tajuk Mochtar Lubis di Harian Indonesia Raya
  bk_e5fb8ce962c60b2d: ["Sains"], // Taksonomi dan Bioekologi Lalat Buat Penting di Indonesia
  bk_cc0a439512f8b0f9: ["Sejarah", "Biografi"], // Tan Malaka, Gerakan Kiri, dan Revolusi Indonesia
  bk_1b694252ae1ecc3b: ["Kumpulan Cerpen"], // Tango
  bk_8dd4183fc60f3b20: ["Nonfiksi Umum"], // Tangsel: Dari Politik Gragasan Ke Politik Gagasan
  bk_6836c632bf574cae: ["Nonfiksi Umum"], // Tata Bahasa Jawa Mutakhir
  bk_29d64035a03e6d19: ["Nonfiksi Umum"], // Tata Rias Pengantin Gaya Yogyakarta
  bk_4994b5d79857697b: ["Nonfiksi Umum"], // Tata Upacara dan Wicara
  bk_774cfb30b5783967: ["Nonfiksi Umum"], // Teater Lenong Betawi
  bk_8ffefe4c0fa93b7b: ["Bisnis"], // Technical Analysis for Mega Profit
  bk_976925ee11a5e0f2: ["Nonfiksi Umum"], // Teknik Gambar Bangunan untuk SMK, Jilid 1
  bk_d001ccec5223eded: ["Novel"], // Tentang Cinta
  bk_9d3a53720ef6d6f2: ["Agama"], // Teologi & Praksis Komunitas Post Modern
  bk_0dfa64c5a0afa72a: ["Agama", "Nonfiksi Umum"], // Teologi, Pendidikan & Pembebasan
  bk_12dc183363263842: ["Sains"], // Teori dan Aplikasi Metode Elemen Hingga
  bk_6154c14b5a43926d: ["Pengembangan Diri"], // The Jongos Ways
  bk_dab6a04342d98970: ["Bisnis"], // The Super Scalper
  bk_1cded82b7da97cfe: ["Nonfiksi Umum"], // The Untold Stories
  bk_b43c95864814d63d: ["Biografi"], // The Untold Story of Ryan
  bk_67053120b492cd14: ["Sejarah", "Nonfiksi Umum"], // Transmigrasi di Indonesia, 1905-1985
  bk_89df454c48f6b7b5: ["Nonfiksi Umum"], // Trik Praktis Ms Word untuk Menyusun Laporan Penelitian
  bk_7b79bf6d13d325b3: ["Nonfiksi Umum", "Bisnis"], // Trust
  bk_38e77fd5439b4f5b: ["Agama", "Sejarah"], // Tuaiannya Sungguh Banyak
  bk_0750942c09e3c9bc: ["Novel"], // Tuhan, Izinkan Aku Menjadi Pelacur!
  bk_8945a941508588c9: ["Agama"], // Tuntunan Tabligh
  bk_7967278d9558696b: ["Sejarah", "Agama"], // Ulama & Kekuasaan
  bk_dc5af9d35902e8d3: ["Sejarah", "Agama", "Biografi"], // Ulama-Ulama di Garda Depan Perjuangan
  bk_48e0784d66bc9530: ["Biografi", "Sejarah"], // Untuk Negeriku
  bk_275e5cb89eef56d1: ["Nonfiksi Umum", "Bisnis"], // Usaha Perbankan dalam Perspektif Hukum
  bk_bb62787457d353da: ["Bisnis"], // Value Investing
  bk_57f13946c0c0bfc5: ["Nonfiksi Umum", "Bisnis"], // Wajah Jasa Konstruksi Indonesia
  bk_6862e1c2f3e97eec: ["Nonfiksi Umum"], // Wayang Golek Sunda
  bk_87376c6cf4ef93b9: ["Bisnis"], // Who Wants to Be a Smiling Investor
  bk_fbc0769c66fae1c0: ["Agama"], // Wife Diary
  bk_ddf2d8d60ac17868: ["Bisnis", "Pengembangan Diri"], // Wirausaha Muda Mandiri
  bk_f1e6b0709dd14a72: ["Nonfiksi Umum"], // Wiwara
  bk_bbf59342d61dec8b: ["Nonfiksi Umum", "Sejarah"], // Yang Terus di Garis Lurus
};

/** normalizeSearchText(source title) → title to use. */
export const TITLE_RENAMES: Record<string, string> = {
  "miracle menantang mau": "Miracle Menantang Maut",
  "siti nurbaya": "Sitti Nurbaya",
  "siti nurbaya kasih tak sampai": "Sitti Nurbaya",
  "sitti nurbaya kasih tak sampai": "Sitti Nurbaya",
  "kebiasaan atom": "Atomic Habits: Perubahan Kecil yang Memberikan Hasil Luar Biasa",
  "la tahzan jangan bersedih aidh al qarni": "La Tahzan: Jangan Bersedih",
};

/** Source author (as written, or normalised) → author to use. */
export const AUTHOR_RENAMES: Record<string, string> = {
  // Open Library lists some translations under the Arabic script name.
  "عائض القرني": "Aidh al-Qarni",
  // A publisher listed as the author.
  "puspa swara": "Tim Puspa Swara",
  // The Tempo series ("Seri Buku Tempo") lists the publisher as author.
  "kepustakaan populer gramedia": "Tim Buku Tempo",
};

/**
 * Book ID → field values that replace what the sources give (17 Oct 2026):
 * a title that repeats its subtitle, Wikipedia disambiguation pages taken
 * as synopses, and a translator listed as author. normalize.ts applies
 * them; curate.ts writes them to
 * books that no teacher has edited.
 */
export const CORRECTIONS: Record<
  string,
  {
    title?: string;
    subtitle?: string | null;
    authors?: string[];
    publisher?: string;
    publishedYear?: number;
    isbn13?: string | null;
    isbn10?: string | null;
    pageCount?: number;
    description?: string | null;
  }
> = {
  bk_ca03cf8cb4132e4e: {title: "Atomic Habits", subtitle: "Perubahan Kecil yang Memberikan Hasil Luar Biasa"},
  bk_49e859417a3d8420: {title: "Kami (Bukan) Sarjana Kertas"},
  bk_64363070e88550d9: {title: "Masih Ingatkah Kau Jalan Pulang"},
  bk_6de9653c9e9e966b: {
    description:
      "Khairul Azzam, mahasiswa Indonesia di Universitas Al-Azhar, Kairo, bertahun-tahun menunda kuliahnya karena harus berjualan tempe dan bakso untuk menghidupi ibu dan adik-adiknya di Solo. Di tengah kerja kerasnya ia mulai memikirkan pendamping hidup, dan perjalanan cintanya diuji oleh kesabaran, kejujuran, dan keteguhan iman.",
  },
  // Open Library lumps the Catalan translation into the work, with its translator as author (30 Oct 2026).
  bk_f371d7978c36a232: {authors: ["Eka Kurniawan"]},
  bk_537da5f566f1c802: {title: "Tidak Ada New York Hari Ini", subtitle: null},
  // Fields the import left empty, matched to the edition of the stored cover (30 Oct 2026).
  bk_026fb11ed09815ef: {publisher: "Yayasan Bung Karno & Media Pressindo"}, // Bung Karno
  bk_131b643d895377a2: {publishedYear: 1900}, // Tjerita Si Tjonat
  bk_1ad62dfa5a67293d: {publisher: "Iqra"}, // Binatangisme
  bk_1c48241e581bbde1: {publishedYear: 2005}, // Prahara Buddenovsky
  bk_2c1dbe3d9d78f0a2: {publisher: "Sinar Harapan"}, // Mencari Makna Hidupku
  bk_2cb866b40cd04ee8: {publishedYear: 2007}, // Kapok Deh Jatuh Cinta
  bk_30d05dc3121a584e: {publisher: "Narasi", publishedYear: 2010}, // Madilog: the cover is Narasi's, not the 1943 original
  bk_37781dd3f3361cf2: {publisher: "Grasindo", publishedYear: 2018, isbn13: "9786024526986", isbn10: "6024526989"}, // Sebuah Seni untuk Bersikap Bodo Amat
  bk_6fccad0cfb0b219e: {publishedYear: 2019}, // Sang Nabi
  bk_7154a308a63400b7: {publishedYear: 2020}, // Catatan Najwa 2
  bk_a434893e2ee76b2d: {publisher: "Gramedia Pustaka Utama", publishedYear: 2019, isbn13: "9786020636191", isbn10: "6020636194"}, // Kim Ji-Yeong, Lahir Tahun 1982
  bk_edcaa7f83a26851e: {publisher: "Pustaka Pelajar & INSIST Press"}, // Sekolah Itu Candu
  bk_f030e65a8bc91b6a: {publisher: "Diva Press"}, // Pasar
  bk_f1c5f5962178a0e8: {publishedYear: 1959}, // Kepada Bangsaku
  // Divergent: the cover is the Mizan Fantasi edition; 487 pages was the US hardcover.
  bk_fd4ead1a47cf86ef: {publisher: "Mizan Fantasi", publishedYear: 2012, isbn13: "9789794336977", isbn10: "9794336971", pageCount: 543},
  // Mistyped ISBNs: Mizan's prefix is 979-433, Gema Insani's 979-561.
  bk_35b40c117ca27d5a: {isbn13: "9789794335963"}, // Sang Pencerah (was 9787974335963)
  bk_16413bd8d52a7cd9: {isbn13: "9789795611776"}, // Awas! Bahaya Lidah (was 9799795611775)
  bk_670bc324ae232ee6: {title: "Rectoverso"}, // was "Rectosrev"
  bk_fca2a5518b1f3326: {publisher: "Salemba Empat"}, // Sistem Informasi Akuntansi: the publisher field held the translators' names
  bk_e5fb8ce962c60b2d: {title: "Taksonomi dan Bioekologi Lalat Buah Penting di Indonesia", authors: ["Sri Suharni Siwi", "Purnama Hidayat", "Suputa"]}, // "Lalat Buat", three authors in one string
  bk_fe9ff6732885ac0e: {authors: ["Imam Ghozali"]}, // was "Imam ghozali, 2018"
  bk_b6302ed13406acb4: {subtitle: "Membentuk Generasi Cemerlang Harapan Bangsa", authors: ["Isjoni"]}, // "Generaso"; the same author listed twice
  bk_0fabd5e5463fffe3: {authors: ["Syekh Adnan Hasan Shalih Baharits"]}, // Mendidik Anak Laki-Laki: Abdul Mun'im Ibrahim wrote the companion volume
  bk_355bd1f0bd1a4f57: {isbn13: "9786234582208"}, // Sahabiyah Stories for Kids, per Gema Insani
  bk_a6d176a4bbe9cdf9: {authors: ["Ekuslie Goestiandi", "Yusi Avianto Pareanom"]}, // Pembelajaran T.P. Rachmat: a book about him
  bk_5977d3bc7f265f4f: {authors: ["Romy Rafael"]}, // Hipnoterapi: Quit Smoking! (GagasMedia 2006), not R. Cecep Eka Permana
  bk_369b8c4e58d72e53: {isbn13: "9789792230437", authors: ["Abdul Sani", "R. Isis Ismail", "Fx. Suwito Marsam"]}, // Buku Pintar Kepabeanan: the stored ISBN failed its checksum
  bk_895ba9deeb8dfbad: {title: "Inspired by Indayati Oetomo"}, // spelled Oetomo on the cover
  bk_751cff973af95011: {authors: ["Dyah Hasto Palupi", "Teguh Sri Pambudi"]}, // Advertising That Sells: co-author
  bk_4d21ed3aa1589533: {authors: ["Sandra Brown"]}, // Demi Kehormatan: Renee Raudman narrated the audiobook
  bk_38d0b844fd16e26e: {title: "Yuni Shara, 35 Cangkir Kopi"}, // was "Yuni Shara & Cangkir Kopi"
  bk_0696e252848a6faa: {title: "Menjadi Manusia Indonesia"}, // published without "Seutuhnya"
  bk_25928744b24f9a8b: {authors: ["Martha Tilaar", "Wulan Tilaar Widarto"]}, // Leadership Quotient: co-author missing
  bk_31ca0c23675b01c8: {title: "Catatan Masa Lalu Banten"}, // was "Catatan Masalalu Banten"
  bk_ebd2b781a9973254: {authors: ["Goenawan Mohamad"]}, // Eksotopi: was "Gunawan Mohamad"
  bk_f565098068727b23: {authors: ["H. Krafft", "F. Wiggers", "Kwee Tek Hoay", "Lie Kim Hok", "Rustam Effendi"]}, // Antologi Drama Indonesia 1: was "Lie Kom Hok"
  // A book about David Tobing, written by Rita Triana Budiarti.
  bk_d385b9015fb8ab64: {authors: ["Rita Triana Budiarti"]},
  bk_e543af6abc95dfea: {isbn13: null}, // Biografi Daripada Soeharto: the ISBN belongs to "Chic & modis kerudung"
  bk_8326add768e01788: {isbn13: null},
  bk_e765832f8de11ad1: {isbn13: null}, // Mitologi Kanjeng Ratu Kidul: the ISBN belongs to "Dakwah Wali Songo"
  bk_c9e5daa4ad9dbbd4: {isbn13: null}, // Njoto: the ISBN belongs to the Sjahrir book of the same Tempo series // Refrein di Sudut Dam: the ISBN belongs to a Bentang translation of Tears of the Giraffe
  bk_94c39a7abd2651c2: {
    description:
      "Buku kedua kisah Gajah Mada karya Langit Kresna Hariadi. Di tengah perebutan takhta dan intrik di istana Majapahit, Gajah Mada berjuang menjaga keselamatan raja dan keutuhan negeri.",
  },
};

/** A book whose data was checked by hand online, with its cover's image URL. */
export interface ManualBook {
  book: {
    title: string;
    subtitle: string | null;
    authors: string[];
    publisher: string | null;
    publishedYear: number | null;
    isbn13: string | null;
    isbn10: string | null;
    pageCount: number;
    categories: Category[];
    description: string | null;
  };
  cover: string;
}

/**
 * Students' "new book" suggestions reviewed by the developer (manual.ts),
 * keyed by bookSuggestions ID. `create` adds the book; `link` names the
 * catalog book it already is. Suggestions not listed stay pending for the
 * teachers.
 */
export type SuggestionDecision = ({action: "create"} & ManualBook) | {action: "link"; bookId: string};

export const SUGGESTION_DECISIONS: Record<string, SuggestionDecision> = {
  // ---- 30 Oct 2026 ----
  dIZUHMGJ72mfwUJcxjkG: {action: "link", bookId: "bk_f371d7978c36a232"}, // Cantik Itu Luka
  // 133 pages typed: the novel (135), not the poetry collection (120).
  ArLffXvgzBB2AzS8kOlm: {
    action: "create",
    book: {
      title: "Hujan Bulan Juni",
      subtitle: null,
      authors: ["Sapardi Djoko Damono"],
      publisher: "Gramedia Pustaka Utama",
      publishedYear: 2015,
      isbn13: "9786020318431",
      isbn10: "6020318435",
      pageCount: 135,
      categories: ["Novel"],
      description: null,
    },
    cover: "https://books.google.com/books/content?id=Z4xKDwAAQBAJ&printsec=frontcover&img=1&zoom=0",
  },
  // 352 pages typed: the KataDepan edition (the GagasMedia 2023 one has 308).
  WK8Re3JAYk1kc3nJ6rGH: {
    action: "create",
    book: {
      title: "Ingkar",
      subtitle: null,
      authors: ["Boy Candra"],
      publisher: "KataDepan",
      publishedYear: 2020,
      isbn13: "9786237567141",
      isbn10: "6237567143",
      pageCount: 352,
      categories: ["Novel", "Remaja"],
      description: null,
    },
    cover: "https://bukukita.com/babacms/displaybuku/114195_f.jpg",
  },
  bHsfQLo5Q7YyWbVqUdYV: {
    action: "create",
    book: {
      title: "The Alpha Girl's Guide",
      subtitle: "Menjadi Cewek Smart, Independen, dan Anti-Galau",
      authors: ["Henry Manampiring"],
      publisher: "GagasMedia",
      publishedYear: 2020,
      isbn13: "9789797809546",
      isbn10: "9797809544",
      pageCount: 264,
      categories: ["Pengembangan Diri", "Remaja"],
      description: null,
    },
    cover: "https://books.google.com/books/content?id=2SzrDwAAQBAJ&printsec=frontcover&img=1&zoom=0",
  },
  // 518 pages typed: the 2010 translation by Lulu Wijaya (the 2021 reissue has 520).
  DGyPAm1rNfONVZpSwMXo: {
    action: "create",
    book: {
      title: "Good Omens",
      subtitle: "Pertanda-Pertanda Baik",
      authors: ["Neil Gaiman", "Terry Pratchett"],
      publisher: "Gramedia Pustaka Utama",
      publishedYear: 2010,
      isbn13: "9789792256222",
      isbn10: "9792256229",
      pageCount: 518,
      categories: ["Novel"],
      description: null,
    },
    cover: "https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1270825871l/7999784.jpg",
  },
  // The student's photo has a library sticker on it; the publisher's cover is clean.
  GFfq3Vj4m7wJJpM4RM3h: {
    action: "create",
    book: {
      title: "Muazin Pertama di Luar Angkasa",
      subtitle: "Sehimpun Cerpen",
      authors: ["Kiki Sulistyo"],
      publisher: "DIVA Press",
      publishedYear: 2021,
      isbn13: "9786232935808",
      isbn10: "6232935802",
      pageCount: 140,
      categories: ["Kumpulan Cerpen"],
      description: null,
    },
    cover: "https://cdn.gramedia.com/uploads/items/9786232935808.jpg",
  },
  // The student typed the author as "AKU. MUNAFIK SALEH".
  "9dlLkqAXgeEbjBKutrGX": {
    action: "create",
    book: {
      title: "Membangun Karakter dengan Hati Nurani",
      subtitle: "Pendidikan Karakter untuk Generasi Bangsa",
      authors: ["Akh. Muwafik Saleh"],
      publisher: "Erlangga",
      publishedYear: 2012,
      isbn13: "9786022410300",
      isbn10: "6022410304",
      pageCount: 398,
      categories: ["Pengembangan Diri", "Agama"],
      description: null,
    },
    cover:
      "https://lms.dpk.kepriprov.go.id/resources/cover/2023-03-02_MEMBANGUN-KARAKTER-DENGAN-HATI-NURANI-PENDIDIKAN-KARAKTER-UNTUK-GENERASI-BANG_022609.jpg",
  },
  // 162 pages typed; the print edition has 164.
  lKVMKIDYcRAwiBLKpi8V: {
    action: "create",
    book: {
      title: "Aku Kalah, Aku Merindukanmu!",
      subtitle: "Untukmu yang Tak Pernah Mau Kembali",
      authors: ["Coretan Lena"],
      publisher: "Gradien Mediatama",
      publishedYear: 2024,
      isbn13: "9786022083719",
      isbn10: "6022083710",
      pageCount: 164,
      categories: ["Remaja", "Novel"],
      description: null,
    },
    cover: "https://books.google.com/books/content?id=0USFEQAAQBAJ&printsec=frontcover&img=1&zoom=0",
  },
  // Light novel, M&C (Gramedia) 2026: 392 pages, the student typed 388.
  zj00GOixD5mGdoGSFIUu: {
    action: "create",
    book: {
      title: "86 —Eighty Six— Ep. 5",
      subtitle: "Wahai Maut, Janganlah Congkak",
      authors: ["Asato Asato"],
      publisher: "M&C",
      publishedYear: 2026,
      isbn13: "9786230318955",
      isbn10: null,
      pageCount: 392,
      categories: ["Novel", "Remaja"],
      description: null,
    },
    cover: "https://media.mncgramedia.id/images/books/6611/20260226_115446_1774414208.jpg",
  },
};
