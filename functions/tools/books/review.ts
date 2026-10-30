// Decisions from the human review of the catalog (review-sheets.ts and the
// title lists), 16 Oct 2026:
//   REJECTED_BOOKS     dropped by normalize.ts (wrong edition, textbook,
//                      adult content, not reading for SMA students, …)
//   REJECTED_COVERS    skipped by covers.ts, which tries the book's next cover
//   CATEGORY_OVERRIDES replace the automatic classification (1–3, primary first)
//   TITLE_RENAMES      canonical titles, keyed by the normalised source title
//   AUTHOR_RENAMES     canonical authors, keyed by the normalised source name
import type {Category} from "./seeds";

/** Book ID → reason. */
export const REJECTED_BOOKS: Record<string, string> = {
  // ---- Review of the books added on 17 Oct 2026 (new IDs of books already in production count as duplicates) ----
  bk_d683f8977266dd5f: "tinjauan: buku teks/kajian akademik", // Menuju Era Wakaf Produktif
  bk_a5b068ad3d24b8f2: "tinjauan: buku teks/kajian akademik", // M. Natsir, Dakwah dan Pemikirannya
  bk_02949da2c9bbeb3f: "tinjauan: buku teks/kajian akademik", // Lihatlah Sang Manusia! (etika Kristen)
  bk_8d24ef112a91f20b: "tinjauan: buku teks/kajian akademik", // Kerukunan Umat Beragama Pilar Utama Kerukunan Berbangsa
  bk_f243b80825222619: "tinjauan: buku teks/kajian akademik", // Ekonomi Politik Media Penyiaran
  bk_ad4b1e1e6c268546: "tinjauan: buku teks/kajian akademik", // Kepuasan Hidup dan Dukungan Sosial Lanjut Usia
  bk_d34b92be59906b38: "tinjauan: buku teks/kajian akademik", // Kura-Kura & Buaya Indonesia dan Papua Nugini
  bk_8eca66e0f1003763: "tinjauan: politik praktis/polemik", // Supersemar Palsu
  bk_610c3b07dea24bc7: "tinjauan: politik praktis/polemik", // Dari Papua Meneropong Indonesia
  bk_6ca69366d12a298e: "tinjauan: politik praktis/polemik", // Membongkar Supersemar!
  bk_b5a87348d25d75c1: "tinjauan: buku teks/kajian akademik", // Mencapai Pertanian yang Lebih Baik
  bk_f6e06e89d874c8fb: "tinjauan: buku teks/kajian akademik", // Identitas Dayak
  bk_e5f4666c2a5a0bfe: "tinjauan: bukan buku utuh (snackbook)", // Charles Lebourne - Orang-Orang Bloomington
  bk_4037da2a8536a7b8: "tinjauan: bukan buku utuh (snackbook)", // Laki-Laki Tua Tanpa Nama - Orang-Orang Bloomington
  bk_b90f39a24170d281: "tinjauan: edisi lain dari buku yang sudah ada", // 5 cm (Hc)
  bk_a8c8f204e16de708: "tinjauan: edisi lain dari buku yang sudah ada", // 9 Summers 10 Autumns (Augmented Hinted Ilustrative Book)
  bk_b5bcdcb741a88e99: "tinjauan: edisi lain dari buku yang sudah ada", // Badai Pasti Berlalu - CU Format Baru
  bk_d021640ef918b505: "tinjauan: bukan buku utuh (cuplikan)", // Geez & Ann #1: Free Chapter
  bk_2d3710b24b973eac: "tinjauan: bukan buku utuh (cuplikan)", // Geez & Ann #2: Free Chapter
  bk_8dd4183fc60f3b20: "tinjauan: politik praktis/polemik", // Tangsel: Dari Politik Gragasan Ke Politik Gagasan
  bk_252a7d250466c316: "tinjauan: buku teks/kajian akademik", // Semangat Nasionalisme dalam Puisi Sebelum Kemerdekaan
  bk_f7c071f968cdd3da: "tinjauan: edisi lain dari buku yang sudah ada", // Classics: Sebatang Kara (Nobody's Boy)
  bk_f711d0551436a8ea: "tinjauan: buku teks/kajian akademik", // Sufisme Jawa
  bk_ff2d03f2926f4cb2: "duplikat: sudah ada sebagai bk_c70a7466f524e8af", // "Membumikan" Al-Qur'an
  bk_a70308d4c5eaf269: "duplikat: sudah ada sebagai bk_d5599c5f588d42ff", // Bilangan Fu
  bk_666d9e9dfb4f08cb: "duplikat: sudah ada sebagai bk_f56fc1f1abf0c110", // Kubah
  bk_75b89165960be70b: "duplikat: sudah ada sebagai bk_4f10875a86b3127b", // Senja di Jakarta
  bk_0a6f24ecee1e2f14: "duplikat: sudah ada sebagai bk_13680be1fda7d8e5", // Seperti Dendam, Rindu Harus Dibayar Tuntas
  // ---- Curation of the production catalog (17 Oct 2026, curate.ts soft-deletes them) ----
  bk_ce95b2ed0bd844a3: "kurasi: konten dewasa", // Saman
  bk_9091dabd2bea65fb: "kurasi: konten dewasa", // Larung
  bk_a2389da179a04b52: "kurasi: konten dewasa", // Pengakuan Eks Parasit Lajang
  bk_c53cef1ffe57f1c8: "kurasi: konten dewasa", // Cerita Cinta Enrico
  bk_472bef9d519b5036: "kurasi: konten dewasa", // Nayla
  bk_447938d611903a14: "kurasi: konten dewasa", // Mereka Bilang, Saya Monyet!
  bk_734b290aa24f1515: "kurasi: konten dewasa", // Cerita Pendek tentang Cerita Cinta Pendek
  bk_1eddb869538e4a4e: "kurasi: konten dewasa", // Pillow Talk
  bk_2f5e80dd6498db2a: "kurasi: konten dewasa", // Mouth To Mouth
  bk_b614646feae1ad0b: "kurasi: konten dewasa", // Good Fight
  bk_d8ae91ac6ff3341e: "kurasi: konten dewasa", // With You
  bk_caa743a96cd6a698: "kurasi: konten dewasa", // Coklat Stroberi
  bk_c0d82a72a5666e29: "kurasi: konten dewasa", // Kuta Bali
  bk_64cb7e67ac9f2513: "kurasi: konten dewasa", // Misteri Perawan Kubur
  bk_5cfe1f51d5ddbe19: "kurasi: konten dewasa", // Nyanyian Maldoror dan Poésies
  bk_693362707e658e9a: "kurasi: konten dewasa", // The Last Don
  bk_4c737fb8ee0779ec: "kurasi: konten dewasa", // Deadline
  bk_a8967eef3bf408b2: "kurasi: bukan buku utuh / bukan bacaan", // A Moment To Love You Chapter 1
  bk_9d88d8a9cf10aa14: "kurasi: bukan buku utuh / bukan bacaan", // Paranormal
  bk_a03b8b3ce034300b: "kurasi: bukan buku utuh / bukan bacaan", // Sebuah Catatan, Untuk Kita Renungkan
  bk_8eade154a27128dd: "kurasi: bukan buku utuh / bukan bacaan", // The Perfect Cakes
  bk_a4b951ddee1bdd4c: "kurasi: bukan buku utuh / bukan bacaan", // Asian Games 2018
  bk_d6eeda54f8f218ef: "kurasi: bukan buku utuh / bukan bacaan", // Hello Shinee
  bk_d96d2225b6c38588: "kurasi: bukan buku utuh / bukan bacaan", // Fikih Manhaji 5 – Haji dan Umrah
  bk_5dec76d629ed9b77: "kurasi: bacaan anak kecil", // Asyiknya Bertualang di Kampung Naga
  bk_0506668876332b48: "kurasi: bacaan anak kecil", // Babi Sombong dan Kuda Kurus
  bk_36b346b86bdf87c9: "kurasi: bacaan anak kecil", // Kreasi Asyik Muslim Cilik
  bk_5ecb754f1c10dd50: "kurasi: bacaan anak kecil", // Nyi Loro Kidul
  bk_01e193382ce88821: "kurasi: bacaan anak kecil", // Animal Antics
  bk_355bd1f0bd1a4f57: "kurasi: bacaan anak kecil", // Sahabiyah Stories for Kids: Meneladani Sifat-Sifat Mulia Sah
  bk_04ebb9204bcafe5b: "kurasi: bacaan anak kecil", // Komik Fiqih Untuk Anak
  bk_5144cb9e19082a51: "kurasi: bacaan anak kecil", // Komik Hari Besar Islam
  bk_c282a85fb88dd935: "kurasi: bacaan anak kecil", // Komik Tadabur Al-Qur`an
  bk_793e56a0139f7b0b: "kurasi: bacaan anak kecil", // Haid Pertamaku
  bk_36567d6c4ac1f0b2: "kurasi: bacaan anak kecil", // Si Untung
  bk_ab2703fb60d74d37: "kurasi: buku teks/teknis", // Syarah Shahih Muslim, Tahqiq Khalil Ma'mun Syiha
  bk_0a128ebfaad7b15d: "kurasi: buku teks/teknis", // Berbagai Aliran di dalam dan di Sekitar Gereja
  bk_3baf4be2f4fece52: "kurasi: buku teks/teknis", // Dekolonisasi Gereja di Indonesia
  bk_2e26a1cbca5d1ec4: "kurasi: buku teks/teknis", // Berkawan Harimau Bersama Alam
  bk_08e40fc369324eaa: "kurasi: buku teks/teknis", // Sepak Bola Indonesia
  bk_f6ab7935f3b7bba9: "kurasi: buku teks/teknis", // Ekologi
  bk_aa418dbf1f1fbf97: "kurasi: buku teks/teknis", // Membidik Pasar Indonesia
  bk_e0252582b70ce31e: "kurasi: buku teks/teknis", // Danger Zone
  bk_5977d3bc7f265f4f: "kurasi: buku teks/teknis", // Hipnoterapi
  bk_a92692d8ecff48f9: "kurasi: buku teks/teknis", // Sejarah Satrya Dalem Cili Ularan dari Majapahit
  bk_388fbe28b49917f7: "kurasi: politik praktis/polemik/judul kasar", // 10 Dosa Besar Soeharto
  bk_b3035d87b0568f30: "kurasi: politik praktis/polemik/judul kasar", // Agenda Mendesak Bangsa
  bk_c368392e0418a763: "kurasi: politik praktis/polemik/judul kasar", // Gerakan Politik Indonesia
  bk_b15fd025216108fa: "kurasi: politik praktis/polemik/judul kasar", // Gus Dur Garis Miring PKB
  bk_681b92c3e96d67c5: "kurasi: politik praktis/polemik/judul kasar", // Mengapa Partai Islam Kalah?
  bk_be9809f46f7aa2a0: "kurasi: politik praktis/polemik/judul kasar", // Sang Pemimpin
  bk_6264830ee7073fd5: "kurasi: politik praktis/polemik/judul kasar", // Bunuh Sang Nabi!
  bk_904c0f5e81fc04cf: "kurasi: politik praktis/polemik/judul kasar", // Umat Islam Menghadapi Tantangan Kristenisasi dan Sekularisas
  bk_5fed3ca829de8a95: "kurasi: politik praktis/polemik/judul kasar", // Jiwo J[a]ncuk
  // ---- Books that came in after the title-case rerun (16 Oct 2026) ----
  bk_8b96295e6634bde9: "tidak relevan untuk siswa SMA", // Istri Kontrak
  bk_6dec0a255e6efa69: "tidak relevan untuk siswa SMA", // Kawin Kontrak
  // ---- Relevance review of every harvested title (16 Oct 2026) ----
  bk_d08a4591e6bed608: "tidak relevan untuk siswa SMA", // (Digital) Executive Legislator
  bk_f8d205c4c1940d6a: "tidak relevan untuk siswa SMA", // 60 Rahasia Jadi Ayah Hebat
  bk_28c38ac1b9b9a376: "tidak relevan untuk siswa SMA", // Adab Bekerja dan Berbisnis
  bk_751cff973af95011: "tidak relevan untuk siswa SMA", // Advertising that sells
  bk_f4746292f6968db3: "tidak relevan untuk siswa SMA", // Agar Ayah Enggak Masuk Neraka
  bk_143a4d694ee8620a: "tidak relevan untuk siswa SMA", // Agar Muslimah Mantap Menikah
  bk_dc9aea6fe0fd2273: "tidak relevan untuk siswa SMA", // Amien Rais menjawab isu-isu politis seputar kiprah kontrover
  bk_330f8aea3ba105d6: "tidak relevan untuk siswa SMA", // Analisis ekonomi politik Indonesia
  bk_62b9fb66af0ea101: "tidak relevan untuk siswa SMA", // Apa Bahayanya Menikah dengan Wanita Nonmuslim?
  bk_fb4d588d9a9022e4: "tidak relevan untuk siswa SMA", // Ayat-Ayat Sehat
  bk_0d516c8b53b5365b: "tidak relevan untuk siswa SMA", // Baby Guide for Muslim
  bk_3065fd6ab170e69f: "tidak relevan untuk siswa SMA", // Baca Kitab manakib Syekh Abdul Qadir Jaelani merusak aqidah 
  bk_28c9d551b07d5458: "tidak relevan untuk siswa SMA", // Bagaimana Anti-kekerasan Melindungi Negara
  bk_5ff51d2ba69e0569: "tidak relevan untuk siswa SMA", // Be G2c
  bk_c39293a007c63a9e: "tidak relevan untuk siswa SMA", // Berani Mencintai Bernyali Menikahi
  bk_932d3e77d517bd34: "tidak relevan untuk siswa SMA", // Berjuta Rasa Menjadi Papah-Mamah Muda
  bk_41c8512cdf8905a8: "tidak relevan untuk siswa SMA", // Bikin Nikah Tak Jadi Masalah
  bk_7e5e7a4547f11a19: "tidak relevan untuk siswa SMA", // BookMagz #1: Aku Siap Menikah Sekarang!
  bk_7d15dfdfef9f0e1e: "tidak relevan untuk siswa SMA", // Budaya korporat dan keunggulan korporasi
  bk_c9b60425f22343a5: "tidak relevan untuk siswa SMA", // Bukan kapitalisme bukan sosialisme
  bk_bde7aa571716dc50: "tidak relevan untuk siswa SMA", // Bumi makin panas
  bk_1e397a125b5ea8b9: "tidak relevan untuk siswa SMA", // BUMN Indonesia
  bk_99a19f540de87e55: "tidak relevan untuk siswa SMA", // Cara Simpel Berinvestasi di Pasar Modal Volume I Edisi Revis
  bk_a92e79d70db9d6be: "tidak relevan untuk siswa SMA", // Cara Simpel Berinvestasi di Pasar Modal Volume II
  bk_67994cb9ec52dd4b: "tidak relevan untuk siswa SMA", // Cendekiawan dan kekuasaan dalam negara Orde Baru
  bk_24a9a08a8408b565: "tidak relevan untuk siswa SMA", // Cerdas Dan Salehkan Bayi Anda Dengan ASI
  bk_c71d874e4232a9c9: "tidak relevan untuk siswa SMA", // Cerdas Mengelola Keuangan
  bk_1e4f9374cc6a26e1: "tidak relevan untuk siswa SMA", // Cerdas Mengelola Keuangan Keluarga
  bk_a1ac21c0c8d4cdc1: "tidak relevan untuk siswa SMA", // Cerita Si Ayam
  bk_cd439ba75101d51f: "tidak relevan untuk siswa SMA", // Cerita Si Katak
  bk_ff7eef0dae1c24fb: "tidak relevan untuk siswa SMA", // Cerita Si Kelinci
  bk_c96bf1275044548f: "tidak relevan untuk siswa SMA", // Cerita Si Kucing
  bk_7804cd8955fa5274: "tidak relevan untuk siswa SMA", // Cerita Si Lebah (SC)
  bk_462f7ce246873e8d: "tidak relevan untuk siswa SMA", // Cerita Si Sapi
  bk_cdf84d88eb25deb7: "tidak relevan untuk siswa SMA", // Cerita Si Singa
  bk_73dce494beb9b192: "tidak relevan untuk siswa SMA", // Cerita Si Siput
  bk_c6408948be6f3abf: "tidak relevan untuk siswa SMA", // Cerita Si Zebra
  bk_a2db908ffd48ead2: "tidak relevan untuk siswa SMA", // Character Building
  bk_d55d414f68abeeeb: "tidak relevan untuk siswa SMA", // Dari anak sampai usia lanjut
  bk_e5b07bca853a5a76: "tidak relevan untuk siswa SMA", // Deforestasi tanpa henti
  bk_29644c80bc37c158: "tidak relevan untuk siswa SMA", // Diet Islami
  bk_f49ae8f64f6cef65: "tidak relevan untuk siswa SMA", // Dilema PKS
  bk_9f7a2790e64efc34: "tidak relevan untuk siswa SMA", // Dinamika pembangunan pertanian dan pedesaan
  bk_d6b18da17b744b23: "tidak relevan untuk siswa SMA", // Dominasi penuh muslihat
  bk_843ea0462d9b6f6c: "tidak relevan untuk siswa SMA", // Easy Copywriting: Contek Abis, Sampai Laris!
  bk_822c57e641c58f7a: "tidak relevan untuk siswa SMA", // Education Games
  bk_5b6ce608ccdc7d7a: "tidak relevan untuk siswa SMA", // Family business responses to future competition
  bk_6b245c5255d4e36c: "tidak relevan untuk siswa SMA", // Fatherman1
  bk_3f79b2bc7bd6fe9d: "tidak relevan untuk siswa SMA", // Feminogr[a]fi
  bk_9fbcf041353bea3f: "tidak relevan untuk siswa SMA", // Franchising, the most practical and excellent way of succeed
  bk_f54b2292b1be7d35: "tidak relevan untuk siswa SMA", // Fundamental Vs Technical
  bk_f61f79e7a98c8dfe: "tidak relevan untuk siswa SMA", // Fundamentalisme, terorisme, dan radikalisme
  bk_4681ce21288dce4d: "tidak relevan untuk siswa SMA", // Gender dan strategi pengarus-utamaannya di Indonesia
  bk_67a4c784c7da5f89: "tidak relevan untuk siswa SMA", // Gerakan perlawanan dari masjid kampus
  bk_7ed1e37eaec6b6d1: "tidak relevan untuk siswa SMA", // Gigi Sehat Ibadah Dahsyat
  bk_a6aa184db1d499d2: "tidak relevan untuk siswa SMA", // Hati-Hati Terhadap Media Yang Merusak Anak
  bk_12c3343e9c4d6355: "tidak relevan untuk siswa SMA", // Hermawan Kartajaya on marketing
  bk_19090d50ee6028cc: "tidak relevan untuk siswa SMA", // Hikmah Mempesona Dari Anakku
  bk_e2d368485a2aeeec: "tidak relevan untuk siswa SMA", // Hukum perjanjian internasional
  bk_fc070fbcebaef57a: "tidak relevan untuk siswa SMA", // Hutan & kehutanan
  bk_f06ad127c5acb139: "tidak relevan untuk siswa SMA", // Ideologi Islam dan utopia
  bk_601e288d3767d86d: "tidak relevan untuk siswa SMA", // Indonesianisasi, dari Gereja Katolik di Indonesia menjadi Ge
  bk_c208fe883c0a9f74: "tidak relevan untuk siswa SMA", // Injil dan marapu
  bk_895ba9deeb8dfbad: "tidak relevan untuk siswa SMA", // Inspired by Indayati Utomo
  bk_ad6c34ae97c412a3: "tidak relevan untuk siswa SMA", // Islam dan dinamika sosial politik di Indonesia
  bk_7235b34b51ff4202: "tidak relevan untuk siswa SMA", // Islam dan kedaulatan rakyat
  bk_460a08ca130e09da: "tidak relevan untuk siswa SMA", // Islam pribumi
  bk_c2f3882933c91b2f: "tidak relevan untuk siswa SMA", // Islam sebagai kritik sosial
  bk_93064e4c70104341: "tidak relevan untuk siswa SMA", // Islam, demokratisasi, dan pemberdayaan civil society
  bk_1f08c27a20f518b7: "tidak relevan untuk siswa SMA", // Istri Cerdas
  bk_1baca87aa5fc94e2: "tidak relevan untuk siswa SMA", // Istriku, Aku Mencintaimu
  bk_4400faab6e90ffb7: "tidak relevan untuk siswa SMA", // Jundullah
  bk_f6c39820cd5303b7: "tidak relevan untuk siswa SMA", // Kabut jihad
  bk_1a389441acfb8939: "tidak relevan untuk siswa SMA", // Kado Pernikahan untuk Istriku
  bk_1ce1b8cb818e8dfd: "tidak relevan untuk siswa SMA", // Kapitalisme televisi dan strategi budaya massa
  bk_dbe807bb11ba8cc7: "tidak relevan untuk siswa SMA", // Karya lengkap Driyarkara
  bk_4a2f1433137bf90f: "tidak relevan untuk siswa SMA", // Kaya Harta, Kaya Amal
  bk_032700729509cfd1: "tidak relevan untuk siswa SMA", // Keajaiban Jihad Harta
  bk_774d8c61b4a21d92: "tidak relevan untuk siswa SMA", // Kebangsaan dan globalisasi dalam diplomasi
  bk_71c56b58a6f0ea9a: "tidak relevan untuk siswa SMA", // Kebhinnekaan masyarakat di Indonesia
  bk_6f3c04ac3f9218aa: "tidak relevan untuk siswa SMA", // Kekhususan rokok Indonesia
  bk_56490aceb4727d4b: "tidak relevan untuk siswa SMA", // Kepemimpinan kharismatis
  bk_266d1f98bf45e05e: "tidak relevan untuk siswa SMA", // Ketika aku mencintaimu
  bk_2c731ccb0ec3adea: "tidak relevan untuk siswa SMA", // Ketika Suami Istri Hidup Bermasalah
  bk_704ea542ea3c1c58: "tidak relevan untuk siswa SMA", // Kiai penghulu Jawa
  bk_27e3ac2faf480c62: "tidak relevan untuk siswa SMA", // Kilas kilau bisnis
  bk_432bebad2b592591: "tidak relevan untuk siswa SMA", // Kisah Wato Wele-Lia Nurat dalam Tradisi Puisi Lisan Flores T
  bk_9434903da207e5ba: "tidak relevan untuk siswa SMA", // Lead by heart
  bk_85a4ab9c0814b04f: "tidak relevan untuk siswa SMA", // Lobi zionis & rezim Bush
  bk_f407da048e1616d0: "tidak relevan untuk siswa SMA", // Mahir Mendongeng
  bk_0751b896d15a6d04: "tidak relevan untuk siswa SMA", // Makin Sehat Dengan Jilbab
  bk_e04053ce7100f724: "tidak relevan untuk siswa SMA", // Manusia Daya
  bk_4d32f4086d48505b: "tidak relevan untuk siswa SMA", // Maubes-Insana
  bk_35a1187a037ebfd2: "tidak relevan untuk siswa SMA", // Megawati Soekarnoputri, harapan dan tantangan di kursi Wapre
  bk_21393282a1d39c02: "tidak relevan untuk siswa SMA", // Membangun pusat-pusat di pinggiran
  bk_d7b9ba8b192a9bbd: "tidak relevan untuk siswa SMA", // Membincangkan feminisme
  bk_d1631e5cb85fa4bc: "tidak relevan untuk siswa SMA", // Memilih bank yang sehat
  bk_45ab5eb725ac9f5e: "tidak relevan untuk siswa SMA", // Memperkenalkan Akhlak Mulia Rasulullah kepada Anak
  bk_57335b99bd974162: "tidak relevan untuk siswa SMA", // Menata pulau-pulau kecil perbatasan
  bk_0fabd5e5463fffe3: "tidak relevan untuk siswa SMA", // Mendidik Anak Laki-Laki
  bk_8c5028fd4d399fe6: "tidak relevan untuk siswa SMA", // Mendidik Anak Perempuan
  bk_c47b6b1d6e245fc9: "tidak relevan untuk siswa SMA", // Mengantisipasi masa depan
  bk_b07cb99102df6385: "tidak relevan untuk siswa SMA", // Mengasah Pola Pikir Anak
  bk_2cdf526c72e9c187: "tidak relevan untuk siswa SMA", // Menghadapi tantangan masa depan
  bk_88d228c7c0f46cd3: "tidak relevan untuk siswa SMA", // Menghadapi tantangan, memperjuangkan kerukunan
  bk_20113bcaf4d7c840: "tidak relevan untuk siswa SMA", // Menghidupkan kembali Jalur Sutra Baru
  bk_fdd23f952508cc00: "tidak relevan untuk siswa SMA", // Menguak hubungan dagang Indonesia-Israel
  bk_0ed13b0baba130b2: "tidak relevan untuk siswa SMA", // Menguak tabir & potensi jamu gendong
  bk_9472d51b2a580dff: "tidak relevan untuk siswa SMA", // Menikah Memuliakan Sunnah
  bk_78aec39fccf267c8: "tidak relevan untuk siswa SMA", // Menjadi Manajer Sukses
  bk_a7fe337bb259f048: "tidak relevan untuk siswa SMA", // Menjadi pemimpin politik
  bk_e1dfad81d2f8de43: "tidak relevan untuk siswa SMA", // Menjadi Suami & Ayah Hebat
  bk_9d50e7b03dd1f3c0: "tidak relevan untuk siswa SMA", // Menuju Halal
  bk_e8f51afd0cc91a80: "tidak relevan untuk siswa SMA", // Menyandera Timur Tengah
  bk_32c37c565e496fc0: "tidak relevan untuk siswa SMA", // Menyelisik Penyimpangan Syi’ah
  bk_0d904410cdd16790: "tidak relevan untuk siswa SMA", // Merah putih arsitektur nusantara
  bk_7f330bdb414a3a19: "tidak relevan untuk siswa SMA", // Mereka bukan thaghut
  bk_7097ea0624088c39: "tidak relevan untuk siswa SMA", // Misykat
  bk_468ff2c448435e68: "tidak relevan untuk siswa SMA", // Moluska padang lamun
  bk_420ada243e1dd073: "tidak relevan untuk siswa SMA", // Multibagger
  bk_b703e1c9baa625ac: "tidak relevan untuk siswa SMA", // Muslim demokrat
  bk_c98cc5fdc0010fc5: "tidak relevan untuk siswa SMA", // Muslim Preneur
  bk_d160970c583173e4: "tidak relevan untuk siswa SMA", // Neoliberalisme
  bk_be2b0654f28ebb54: "tidak relevan untuk siswa SMA", // NKRI bersyariah atau ruang publik yang manusiawi?
  bk_e9bf84da76080b9f: "tidak relevan untuk siswa SMA", // Nyai gowok
  bk_8f4571ebb4787d76: "tidak relevan untuk siswa SMA", // Obat-obatan ramuan tradisional
  bk_9ed2298a8d108a36: "tidak relevan untuk siswa SMA", // Panorama bahasa Indonesia
  bk_7446347d9ecced2b: "tidak relevan untuk siswa SMA", // PARENTime
  bk_cadb801fecc90670: "tidak relevan untuk siswa SMA", // Pasar Modal Syariah
  bk_9fc0ac343c79676b: "tidak relevan untuk siswa SMA", // Pelangi di Bukit Barisan
  bk_995962c59d558df7: "tidak relevan untuk siswa SMA", // Pelarangan buku di Indonesia
  bk_f7e98a575290850c: "tidak relevan untuk siswa SMA", // Pemulung Jalanan Yogyakarta
  bk_ef3066b5c687bbcc: "tidak relevan untuk siswa SMA", // Percikan Filsafat
  bk_53704674fa3e20eb: "tidak relevan untuk siswa SMA", // Perjalanan menjumpai Tuhan
  bk_373ce80c41de42c1: "tidak relevan untuk siswa SMA", // Perkembangan tafsir al-Qur'an di Indonesia
  bk_4123ccd877593ffa: "tidak relevan untuk siswa SMA", // Pernak-Pernik Romantis
  bk_1ae33ef0b596ecac: "tidak relevan untuk siswa SMA", // Pesantren masa depan
  bk_ae4f9defbd22e3cb: "tidak relevan untuk siswa SMA", // Piagam perjuangan kebangsaan
  bk_85c697596f7da690: "tidak relevan untuk siswa SMA", // Pijar-pijar filsafat
  bk_6929ccc513a47449: "tidak relevan untuk siswa SMA", // Poligami yang tak melukai hati?
  bk_957d867a767b7ec6: "tidak relevan untuk siswa SMA", // Politik identitas etnis
  bk_fc76d8b5159a01b8: "tidak relevan untuk siswa SMA", // Politik Kristen di Indonesia
  bk_000ccbbc361910c2: "tidak relevan untuk siswa SMA", // Presidensialisme setengah hati
  bk_65373178f0395892: "tidak relevan untuk siswa SMA", // Prof. Dr. Mgr. N.J.C. Geise, O.F.M., juragan visioner
  bk_46972663545a5280: "tidak relevan untuk siswa SMA", // Profil budaya politik Indonesia
  bk_c76368423111a579: "tidak relevan untuk siswa SMA", // Profit Konsisten Dengan Ichimoku Kinko Hyo
  bk_d2a3d3519abbce74: "tidak relevan untuk siswa SMA", // Psikologi Pernikahan: Menyelami Rahasia Pernikahan
  bk_d9cd6e92979c62dd: "tidak relevan untuk siswa SMA", // Rakyat memantau ibukota, rakyat memantau Jokowi Basuki
  bk_b37fc90804af00f7: "tidak relevan untuk siswa SMA", // Reinventing pembangunan
  bk_5edf0aa05b8f92c5: "tidak relevan untuk siswa SMA", // Revolusi sistem pendidikan nasional dengan metode e-learning
  bk_b87d1ec0cc3889a0: "tidak relevan untuk siswa SMA", // Rumah Melayu
  bk_d13c307f792d91f1: "tidak relevan untuk siswa SMA", // SANTRI-PESANTREN INDONESIA ; Siaga Jiwa Raga Menuju Indonesi
  bk_063aa3fcf5141a2e: "tidak relevan untuk siswa SMA", // Saya tidak ingin poligami tapi harus poligami
  bk_4f64af6f1d7c621b: "tidak relevan untuk siswa SMA", // Seandainya saya isteri Aa Gym
  bk_3991695403634fe2: "tidak relevan untuk siswa SMA", // Sehat & Bugar Berobat Dengan Alam
  bk_a1fc09a78c09d223: "tidak relevan untuk siswa SMA", // Sehat Itu Nikmat
  bk_ec35472cfc530d2e: "tidak relevan untuk siswa SMA", // Sejarah Pemerintahan Kota Surabaya Sejak Masa Kolonial Sampa
  bk_54b21ca4dfff6dd8: "tidak relevan untuk siswa SMA", // Sejarah perjumpaan Kristen dan Islam di Indonesia
  bk_1e478c36081f6e76: "tidak relevan untuk siswa SMA", // Senam Sehat Prana
  bk_4b525a2708fcfb59: "tidak relevan untuk siswa SMA", // Seputar dewan paroki
  bk_bf2df13a676ddd50: "tidak relevan untuk siswa SMA", // Sesudah filsafat
  bk_33db395ebc13fe1f: "tidak relevan untuk siswa SMA", // Strategi-strategi pembangunan masyarakat
  bk_4994b5d79857697b: "tidak relevan untuk siswa SMA", // Tata upacara dan wicara
  bk_8ffefe4c0fa93b7b: "tidak relevan untuk siswa SMA", // Technical Analysis For Mega Profit
  bk_9d3a53720ef6d6f2: "tidak relevan untuk siswa SMA", // Teologi & praksis komunitas post modern
  bk_0dfa64c5a0afa72a: "tidak relevan untuk siswa SMA", // Teologi, pendidikan & pembebasan
  bk_6154c14b5a43926d: "tidak relevan untuk siswa SMA", // The jongos ways
  bk_d20b9482f9ad2bd9: "tidak relevan untuk siswa SMA", // The Lean Startup
  bk_dab6a04342d98970: "tidak relevan untuk siswa SMA", // The Super Scalper
  bk_1cded82b7da97cfe: "tidak relevan untuk siswa SMA", // The untold stories
  bk_b43c95864814d63d: "tidak relevan untuk siswa SMA", // The untold story of Ryan
  bk_67053120b492cd14: "tidak relevan untuk siswa SMA", // Transmigrasi di Indonesia, 1905-1985
  bk_7b79bf6d13d325b3: "tidak relevan untuk siswa SMA", // Trust
  bk_38e77fd5439b4f5b: "tidak relevan untuk siswa SMA", // Tuaiannya sungguh banyak
  bk_8945a941508588c9: "tidak relevan untuk siswa SMA", // Tuntunan Tabligh
  bk_7967278d9558696b: "tidak relevan untuk siswa SMA", // Ulama & kekuasaan
  bk_bb62787457d353da: "tidak relevan untuk siswa SMA", // Value Investing
  bk_87376c6cf4ef93b9: "tidak relevan untuk siswa SMA", // Who Wants to be a Smiling Investor
  bk_fbc0769c66fae1c0: "tidak relevan untuk siswa SMA", // Wife Diary
  bk_bbf59342d61dec8b: "tidak relevan untuk siswa SMA", // Yang Terus di Garis Lurus
  bk_b98f0e5a7aa38dbb: "edisi bahasa asing", // Scorpia
  // ---- Review of the seed authors' other works and Wikipedia books ----
  bk_0750942c09e3c9bc: "konten dewasa", // Tuhan, Izinkan Aku Menjadi Pelacur!
  bk_10ec417147e77521: "buku teks/kajian akademik", // Sejarah Indonesia
  bk_362b407ba07f299a: "tidak relevan untuk siswa SMA", // Suami sempurna
  bk_6b56255fed7df793: "judul tidak valid", // Lihat daftar isi Yel
  bk_7783fc0975c6fc9f: "tidak relevan untuk siswa SMA", // Memasuki era BUMN multinational coorporation
  bk_c72ab9c055a33aed: "tidak relevan untuk siswa SMA", // Eksplorasi kreativitas dua dasawarsa Anne Avantie
  bk_cc4035257950fe1a: "duplikat (pakai Supernova 1)", // Supernova
  bk_d4a42618d401e2be: "tidak relevan untuk siswa SMA", // Marketing in crisis
  bk_de70df8525df301d: "tidak relevan untuk siswa SMA", // Mutasi DNA powerhouse
  bk_eef5ddd1c5613885: "tidak relevan untuk siswa SMA", // Begini harusnya bisnis!
  bk_f64021feae83d9f8: "tidak relevan untuk siswa SMA", // Istriku seribu
  bk_0f124f673318aa67: "tidak ada cover yang benar", // Patiwangi
  bk_b3b6ed318f9a183f: "tidak ada cover yang benar", // Inul!
  // ---- Category review of every book ----
  bk_337cab22262bf361: "tidak relevan untuk siswa SMA (buku pengobatan herbal)", // Solusi Alami Sehatkan Diri
  bk_49e15f5cc0359538: "duplikat (Rantau 1 Muara)", // Rantau muara
  bk_1d7378fad074d5ce: "tidak relevan untuk siswa SMA (buku balita)", // My Baby Reads ! I Like Beach Because…
  bk_c88117f3bb4fddef: "tidak relevan untuk siswa SMA (buku balita)", // My Baby Reads ! I Love You Because…
  bk_acfd79d367e99044: "tidak relevan untuk siswa SMA (buku balita)", // My Baby Reads ! Is That A Bug ?
  bk_ac1baa526f3cfcc3: "tidak relevan untuk siswa SMA (buku balita)", // My Baby Reads ! Is That My Belly Button ?
  bk_89a5c297905866b9: "tidak relevan untuk siswa SMA (buku balita)", // My Baby Reads ! Where Is My Tail ?
  bk_701b80c38ae2f894: "duplikat (Arsitektur yang Lain, Sebuah Kritik Arsitektur)", // Arsitektur yang lain
  bk_bbf899c2b8ecd362: "tidak relevan untuk siswa SMA (kitab primbon)", // Syamsul Ma'arif
  bk_019e9f87c56a5d58: "tidak relevan untuk siswa SMA (kerajinan)", // Origami Tanks
  bk_3af32f26c9099952: "duplikat (Di Bawah Lindungan Ka'bah)", // Di Bawah Lindungan Kabah
  bk_876df4c2ec2c8465: "tidak relevan untuk siswa SMA (pengasuhan)", // Dari Abah Ihsan
  bk_55a0100e1d30f9b7: "tidak relevan untuk siswa SMA (pengasuhan)", // 40 Hari Mengatasi Kecanduan Game pada Anak
  bk_1747371656b46f9a: "duplikat (Autumn in Paris)", // MetroPop: Autumn In Paris
  bk_ab3bc34c7b7b2f08: "duplikat (Membangkitkan Energi Qolbu)", // Membangkitkan energi qolbu
  bk_cc332584363d33a9: "duplikat edisi Inggris (Harry Potter dan Orde Phoenix)", // Harry Potter and the order of the Phoenix
  bk_72484a07a8291d33: "duplikat (Kambing dan Hujan)", // Kambing & hujan
  bk_02fedc65fcc0a5b8: "duplikat (Petualangan Tom Sawyer)", // Petualangan Tom Saeyer
  bk_7146e9bf3bb3aeee: "duplikat (Petualangan Tom Sawyer)", // Seri Sastra Dunia: Petualangan Tom Sawyer
  bk_85448cc5cc414220: "duplikat (Azab dan Sengsara)", // Azab Dan Sengsara ( Indonesian Edition )
  bk_0374f12124b63b96: "konten dewasa", // Jakarta undercover
  bk_a60c5e30b6528068: "tidak relevan untuk siswa SMA (pernikahan)", // Barakallahu Laka: Bahagianya Merayakan Cinta
  bk_7a8f04ace80057f8: "tidak relevan untuk siswa SMA (pernikahan)", // Ketika Aku dan Kamu Jadi Kita
  bk_b6e7323bb06daca0: "tidak relevan untuk siswa SMA (pernikahan)", // Nikmatnya Pacaran Setelah Pernikahan
  bk_558342c78c00a01d: "judul tidak valid (bukan karya Tan Malaka)", // Madilog: Makan Daging Cilok
  // ---- Cover review ----
  bk_ab6490cfe82c61be: "edisi bahasa asing", // 15 Février 1839
  bk_229ab7ac730bd5c6: "edisi bahasa asing", // 5 Wealthy Research Topics and Changes for the Future: Buildi
  bk_878201a3181fa376: "edisi bahasa asing", // 5 Wealthy Research Topics and Changes for the Future: iandro
  bk_675585dac8958bb8: "bukan bacaan umum (katalog/kamus/panduan)", // A Comprehensive Indonesian-English Dictionary
  bk_4f4dd1a1d68d20af: "edisi bahasa asing", // Abraham Lincoln (1809-1865), Presiden Amerika Serikat jang k
  bk_578ded6360e14a21: "bukan bacaan umum (katalog/kamus/panduan)", // Add Me on Facebook!
  bk_bfe78ba8a7b2107a: "buku teks/kajian akademik", // Alternatif Kebijakan Pengaturan Hak Atas Tanah Beserta Bangu
  bk_4cbb80c33e9a9b22: "bukan bacaan umum (katalog/kamus/panduan)", // An English-Indonesian-Chinese Dictionary
  bk_af62619026f4e369: "edisi bahasa asing", // And the War Is Over
  bk_514357694cc47cd3: "buku teks/kajian akademik", // Anjak Piutang
  bk_020ef5a46c082faa: "buku teks/kajian akademik", // Antropologi Hukum Indonesia
  bk_ed11b12aa9a7ed59: "buku teks/kajian akademik", // Arbitrase dan Mediasi di Indonesia
  bk_1479bf330634ab5f: "buku teks/kajian akademik", // Arsitektur Radakng: Kehidupan Komunal dan Dayak Kanayatn
  bk_427f3daacfa82ded: "buku teks/kajian akademik", // Aspek-Aspek Hukum Perbankan di Indonesia
  bk_918c72442d437c3c: "edisi bahasa asing", // Bali in the 19th Century
  bk_b06fbc21c69499e9: "buku teks/kajian akademik", // Bangunan Air
  bk_e8bcc43fddbe0b0e: "bukan bacaan umum (katalog/kamus/panduan)", // Batik dan Mitra =
  bk_437411d8372a4c9e: "edisi bahasa asing", // Ben Has Something to Say
  bk_369b8c4e58d72e53: "buku teks/kajian akademik", // Buku Pintar Kepabeanan
  bk_2360eb1e38ef867f: "bukan bacaan umum (katalog/kamus/panduan)", // Cerita Boga Indonesia
  bk_850397e74819f1ad: "buku teks/kajian akademik", // Change Management dalam Reformasi Birokrasi
  bk_5804d3ffa9b83c22: "bukan bacaan umum (katalog/kamus/panduan)", // Cindai, Pengembaraan Kain Patola India.
  bk_767fc7e2b05165b1: "konten dewasa", // Cinta 24 Jam =
  bk_3bd69a5bb68f4d5b: "konten dewasa", // Cinta Abadi
  bk_45cefab5fc13aaf1: "edisi bahasa asing", // Classical Sociological Theory
  bk_85ceed125cc5330b: "edisi bahasa asing", // Counseling Theory and Practice
  bk_f05d1603a468a12b: "bukan bacaan umum (katalog/kamus/panduan)", // Crypto Cash Machine
  bk_08568b855cdbd1c1: "edisi bahasa asing", // Dang Xia De Li Liang
  bk_86d5c1a0f591da51: "buku teks/kajian akademik", // Dasar Mekanika Tanah
  bk_2626867ae47ce541: "buku teks/kajian akademik", // Dasar Penilaian Properti Rumah Mewah: Investasi, Kapitalisai
  bk_16ce12dbd4d116dc: "buku teks/kajian akademik", // Delik-Delik Tertentu (Speciale Delicten) dalam Kuhp
  bk_4d21ed3aa1589533: "konten dewasa", // Demi Kehormatan (Honor Bound)
  bk_52080942d47974a8: "buku teks/kajian akademik", // Desa Mawa Cara
  bk_c1accc879dd2b14a: "buku teks/kajian akademik", // Desain Hidraulik Bangunan Irigasi
  bk_fd54adcb071c3550: "edisi bahasa asing", // Digital Marketing
  bk_d38ce0067a885f19: "buku teks/kajian akademik", // Drainase Perkotaan
  bk_1c80932d52b84161: "edisi bahasa asing", // Droit Penal General
  bk_57b35f6cceb8620d: "edisi bahasa asing", // Earth Dance
  bk_0c06a764fcf5a42c: "buku teks/kajian akademik", // Fonetik dan Fonologi Melodi Bahasa: Prosodi
  bk_6e8c096517d2adad: "konten dewasa", // Garis Tepi Seorang Lesbian
  bk_afea59839ebbcf3a: "buku teks/kajian akademik", // Garis-Garis Besar Hukum Gereja
  bk_7b33a62c1a8ba5a1: "buku teks/kajian akademik", // Gender dan Administrasi Publik
  bk_c93376f0c1aa949a: "bukan bacaan umum (katalog/kamus/panduan)", // Glosarium Keuangan
  bk_913e93514be5b00a: "buku teks/kajian akademik", // Good E-Government
  bk_7ac2b5a0fb640d9d: "buku teks/kajian akademik", // Hamengku Buwono IX dan Sistem Birokrasi Pemerintahan Yogyaka
  bk_45c12fde7196b328: "buku teks/kajian akademik", // Hidrologi Teknik
  bk_ee1571cc97cfdd49: "konten dewasa", // Hitam Putih Prostitusi
  bk_958f0bde8c4233b8: "buku teks/kajian akademik", // Hukum Media Massa Nasional
  bk_c1cb4f4290171add: "buku teks/kajian akademik", // Hukum Perbatasan Darat Antarnegara
  bk_3aed716e293ac9e1: "buku teks/kajian akademik", // Hukum Persaingan Usaha
  bk_aaf5d3953be3de1b: "buku teks/kajian akademik", // Hukum Waris Adat
  bk_876de66f49387aee: "konten dewasa", // I Love You, Om---
  bk_8895d40561a7a076: "buku teks/kajian akademik", // Industrialisasi dan Wiraswasta
  bk_6d55447c96f2b2dd: "edisi bahasa asing", // Introduction to Alkaloids
  bk_c143b4914185cd1d: "konten dewasa", // Jangan Main-Main (Dengan Kelaminmu)
  bk_363c6b489d288a7d: "buku teks/kajian akademik", // Kejaksaan RI
  bk_3303f1489c33f6b5: "konten dewasa", // Kekasih Night Wind
  bk_292e2a6304643d19: "buku teks/kajian akademik", // Kelas Kata dalam Bahasa Indonesia
  bk_c2d7451a9a3f5a0f: "bukan bacaan umum (katalog/kamus/panduan)", // Kesehatan dan Keselamatan Kerja
  bk_6d9e6926c32a9504: "buku teks/kajian akademik", // Keteknikan Videografi
  bk_c39be54fe293da87: "buku teks/kajian akademik", // Kewiraan untuk Mahasiswa
  bk_e0a6d9904a7bb842: "edisi bahasa asing", // Kill the Radio (Visible Poets)
  bk_eaf8339254f16d98: "konten dewasa", // Lelaki Terindah =
  bk_cde5f8d73b9ec8e3: "edisi bahasa asing", // Living Islam
  bk_789ba7159e749cd7: "bukan bacaan umum (katalog/kamus/panduan)", // Mahir Berbahasa Spanyol dalam Sepekan
  bk_30497698749ed3cf: "buku teks/kajian akademik", // Manajemen Periklanan
  bk_4e6a42523e3399e9: "buku teks/kajian akademik", // Mediasi Nonlitigasi Terhadap Sengketa Medik Dengan Konsep Wi
  bk_68ac9883d194408d: "edisi bahasa asing", // Megatrends 2000
  bk_01457cd60316bbd4: "buku teks/kajian akademik", // Mekanika Bahan, Jilid 2
  bk_4da45aea851f5cb0: "buku teks/kajian akademik", // Mekanika Teknik
  bk_78363b690bbd398d: "konten dewasa", // Menaklukkan Sang Dokter
  bk_e32d7950ff87ee97: "buku teks/kajian akademik", // Menegakkan Hukum dan Hak Warga Negara
  bk_f68297cb9cddaeed: "buku teks/kajian akademik", // Merancang dan Merencana Lapangan Terbang
  bk_137f4b56fbde34b6: "buku teks/kajian akademik", // Metode Perancangan Arsitektur
  bk_bb015727121b06a1: "buku teks/kajian akademik", // Monograph Identifikasi Mood Ibu Postpartum Menggunakan Skala
  bk_9991d550ec1f4cca: "buku teks/kajian akademik", // Neurologi Klinis Dasar
  bk_374f4f8d73541157: "buku teks/kajian akademik", // OJK dan Pengawasan Mikroprudensial
  bk_b93a80998301ae1e: "edisi bahasa asing", // On Call
  bk_7cb3b35e222623c0: "buku teks/kajian akademik", // Paradigma Baru Pembangunan Pertanian
  bk_fb286c37b6dce1b9: "buku teks/kajian akademik", // Paradigma Sosiologi Sastra
  bk_66030cca15f9d633: "buku teks/kajian akademik", // Pelanggaran Ham dalam Hukum Keadaan Darurat di Indonesia
  bk_360e5fcbdf7f9582: "buku teks/kajian akademik", // Penerjemahan Berdasar Makna (Pedoman untuk Pemadanan Antarba
  bk_998206f5d21470ec: "buku teks/kajian akademik", // Pengelolaan Lalu Lintas dan Angkutan Jalan
  bk_8512e89a09aab4dc: "buku teks/kajian akademik", // Perbandingan Sistem Ekonomi
  bk_e9e567eb4f5d03b6: "buku teks/kajian akademik", // Perbankan
  bk_cafbe9f3b73eee8b: "buku teks/kajian akademik", // Perbankan Islam dan Kedudukannya dalam Tata Hukum Perbankan 
  bk_963ad8b673eb7b12: "buku teks/kajian akademik", // Perkawinan menurut Islam dan Katolik
  bk_59d8f395c63a6046: "buku teks/kajian akademik", // Perlindungan Hak Asasi Saksi dan Korban dalam Proses Peradil
  bk_c007b03c55b8007b: "buku teks/kajian akademik", // Perpustakaan Digital dari a Sampai Z
  bk_080bc2af6ecdda1d: "konten dewasa", // Petualangan Celana dalam
  bk_ff440b53812f8251: "buku teks/kajian akademik", // Pokok-Pokok Filsafat Hukum
  bk_7838c3a9ffc3307c: "bukan bacaan umum (katalog/kamus/panduan)", // Smart Breastfeeding Mother
  bk_08bf6eed31380354: "buku teks/kajian akademik", // Sosiologi Hukum dalam Masyarakat
  bk_fd84deef545d92e9: "edisi bahasa asing", // Sri Sumarah and Other Stories
  bk_b00e05cad5df8dbe: "buku teks/kajian akademik", // Stereotip Etnis dalam Masyarakat Multietnis
  bk_9681275a0af1baa0: "buku teks/kajian akademik", // Strategi dan Inovasi Model Bisnis Meningkatkan Kinerja Usaha
  bk_98f7d7f349b536bb: "buku teks/kajian akademik", // Struktur Bangunan Bertingkat Tinggi
  bk_1b694252ae1ecc3b: "konten dewasa", // Tango
  bk_976925ee11a5e0f2: "buku teks/kajian akademik", // Teknik Gambar Bangunan untuk SMK, Jilid 1
  bk_9680c27bcf18b880: "buku teks/kajian akademik", // Tema Cerita Pendek Indonesia Tahun 1950-1060
  bk_d001ccec5223eded: "konten dewasa", // Tentang Cinta
  bk_dcaf812453f85716: "bukan bacaan umum (katalog/kamus/panduan)", // Tenun Ikat =
  bk_dccb0ebca9fd3de3: "edisi bahasa asing", // The Complete Poetry and Prose of Chairil Anwar.
  bk_c49e05a9949afcea: "edisi bahasa asing", // The Ecology of Sulawesi
  bk_e65bf88d2ee6309f: "edisi bahasa asing", // The Psychology of Money
  bk_4771b3c25a5ced7c: "edisi bahasa asing", // Trading Chaos
  bk_509d2ba0650223c7: "bukan bacaan umum (katalog/kamus/panduan)", // Urban / Culture: Cp Biennale 2005
  bk_275e5cb89eef56d1: "buku teks/kajian akademik", // Usaha Perbankan dalam Perspektif Hukum
  bk_57f13946c0c0bfc5: "buku teks/kajian akademik", // Wajah Jasa Konstruksi Indonesia
  bk_a3e3e77b3a0bdeeb: "edisi bahasa asing", // どんどんつながる漢字練習帳 初級
  bk_0198b45718d0e7f5: "buku teks/kajian akademik", // Rencana Anggaran Biaya
  bk_440c83d933bfa2b3: "bukan bacaan umum (katalog/kamus/panduan)", // 7 Jam Belajar ArchiCAD 8 untuk Orang Awam
  bk_4c63928c58a7cd5f: "buku teks/kajian akademik", // Kedudukan Hukum Islam dalam Sistem Hukum Indonesia
  bk_5afea7a6470b8301: "bukan bacaan umum (katalog/kamus/panduan)", // Pameran Seni Rupa
  bk_60e18701d9d85404: "buku teks/kajian akademik", // Tahapan dan Langkah-langkah Penelitian
  bk_725ff1b172edcf60: "buku teks/kajian akademik", // Hukum Perwakilan dan Kuasa
  bk_73bd0297fb6a70c0: "edisi bahasa asing", // The Indonesian Language
  bk_7b60efd58dd7c2a4: "edisi bahasa asing", // Village At War
  bk_9207645aa1e6e326: "bukan bacaan umum (katalog/kamus/panduan)", // Karya Arsitek Indonesia.
  bk_9bbf357a45be0b60: "edisi bahasa asing", // A biological assessment of the Wapoga River area of northwes
  bk_ac9909f7dd1879d2: "buku teks/kajian akademik", // Memahami Hukum di Indonesia
  bk_cd7d144915f64874: "buku teks/kajian akademik", // Referensi Bagi Hakim Peradilan Agama Tentang Kekerasan dalam
  bk_d65e87ef4f8e96e2: "bukan bacaan umum (katalog/kamus/panduan)", // Indonesian Phrase Book & Dictionary
  bk_e5fb8ce962c60b2d: "buku teks/kajian akademik", // Taksonomi dan Bioekologi Lalat Buat Penting di Indonesia (Di
  bk_f766932dbaef94f1: "buku teks/kajian akademik", // Hukum Kepailitan Selayang Pandang
  bk_fe77e18441949047: "buku teks/kajian akademik", // Sejarah dan kedudukan BW di Indonesia
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
  bk_7a593ee32f580cfb: "tinjauan: konten dewasa", // Tuhan, Izinkan Aku Menjadi Pelacur!
  bk_dad5b5d2634fb90c: "tinjauan: konten dewasa", // Centhini, Tambangraras-Amongraga
  bk_1dead35b81273f58: "tinjauan: bacaan anak kecil", // Batu Belah Batu Bertangkup
  bk_ec77b20f8eeb1ec9: "tinjauan: bacaan anak kecil", // Buku Abjad ABC Binatang
  bk_5ed170731ee32969: "tinjauan: bacaan anak kecil", // Hadiah Alam
  bk_e2e1ae32c05ca413: "tinjauan: bacaan anak kecil", // Nyi Rambut Kasih
  bk_475f7cc3003768dc: "tinjauan: bacaan anak kecil", // Persahabatan
  bk_caa8951fb83410b9: "tinjauan: bacaan anak kecil", // Ratu Sejati dan Lutung Baik Hati
  bk_fdf2e9023a2e2b8b: "tinjauan: politik praktis/polemik", // Dia: Sebentuk Potret Diri Megawati Soekarnoputri
  bk_116e9bac4d35f14f: "tinjauan: politik praktis/polemik", // Perang Yang Tidak Akan Kita Menangkan
  bk_1f5def9a1ac665f3: "tinjauan: politik praktis/polemik", // Blok Pembangkang
  bk_09b499c3d4f2bde0: "tinjauan: buku teks/kajian akademik", // Diksi dan Gaya Bahasa
  bk_06f8c8da67a34f9b: "tinjauan: buku teks/kajian akademik", // Getar Gender
  bk_39b49b0ecfff7df8: "tinjauan: buku teks/kajian akademik", // Hak Kekayaan Intelektual
  bk_fa5850ef71d52163: "tinjauan: buku teks/kajian akademik", // Jalan Rel
  bk_d3cf6859b57083c5: "tinjauan: buku teks/kajian akademik", // Karya Lengkap Abdullah Abdul Kadir Munsyi
  bk_87fd41f650810b68: "tinjauan: buku teks/kajian akademik", // Kumpulan Karangan (Drijarkara)
  bk_686302c5f4dc9adf: "tinjauan: buku teks/kajian akademik", // Penggunaan Bahasa Indonesia Ragam Tulis
  bk_e1a5f82390f64db0: "tinjauan: buku teks/kajian akademik", // Prosa Tradisional
  bk_bac77b7f3b81699a: "tinjauan: buku teks/kajian akademik", // Riau Sebagai Pusat Bahasa dan Kebudayaan Melayu
  bk_5385287841173454: "tinjauan: buku teks/kajian akademik", // Ritumpanna Wélenrénngé
  bk_9c68323b4b2b9adb: "tinjauan: buku teks/kajian akademik", // Sejarah Pemikiran Hak-Hak Asasi Manusia
  bk_774cfb30b5783967: "tinjauan: buku teks/kajian akademik", // Teater Lenong Betawi
  bk_9d4d20d6c2b3696c: "tinjauan: buku teks/kajian akademik", // Teori Ekonomi, Politik Ekonomi dan Orde Ekonomi
  bk_11ce32c8a8f6d51c: "tinjauan: buku teks/kajian akademik", // Sunda Sebelum Perang
  bk_70af8e91637c7b9b: "tinjauan: buku teks/kajian akademik", // Ornamen Rumah Adat Batak Toba
  bk_8621a1f1a22d6cb5: "bukan bacaan umum (katalog/kamus/panduan)", // Tentang Sejumlah Orang Sulawesi Selatan
  bk_a195d740dedf98a6: "bukan bacaan umum (katalog/kamus/panduan)", // Kabar Baik (traktat)
  bk_07f315bfb91c418b: "bukan bacaan umum (katalog/kamus/panduan)", // Umat Allah Menegaskan Arah
  bk_d36528d5e6ce6dbb: "tinjauan: terbitan mandiri luar negeri", // Semanyun Senyuman Mahasiswa
  // Foreign-language editions found in the catalog (30 Oct 2026), none with readers.
  bk_0bbf8ae36912c40b: "kurasi: edisi bahasa asing", // Rich Dad Poor Dad (Business Plus)
  bk_115d35c6af82168c: "kurasi: edisi bahasa asing", // Firedom
  bk_5787acde4a5e3fe9: "kurasi: edisi bahasa asing", // Across the Nightingale Floor (Riverhead)
  bk_8fa66a1b89b77235: "kurasi: edisi bahasa asing", // Neighbourhood Tales
  bk_346776a26373eaae: "kurasi: edisi bahasa asing", // Personality Plus (Monarch)
  bk_fe70a22066d436d8: "kurasi: edisi bahasa asing", // Never Let Me Go (Faber cover)
  bk_ff236145addc576a: "kurasi: edisi bahasa asing", // Being Indonesian (written in English)
  bk_3d49ead6af1f17f1: "kurasi: buku teks/kajian akademik", // Sunda: Dalam Jaring Esterika Suara-Suara Kelas (literary criticism)
};

/** Cover URLs that show the wrong book, a person, a placeholder or a page. */
export const REJECTED_COVERS = new Set<string>([
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
  bk_2c1dbe3d9d78f0a2: ["Biografi"], // Mencari Makna Hidupku: Bunga Rampai Perjalanan Sujatin Kartowijono
  bk_d06d8491fe089b3f: ["Puisi"], // Nyanyian Integrasi Bangsa
  bk_0b7fcd9ca2ccae06: ["Puisi"], // Ghirah Gatha
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
  bk_f933facfdf67ad7c: {isbn13: null}, // Anak Semua Bangsa, Hasta Mitra 1980: Penguin's ISBN for the English translation
  bk_670bc324ae232ee6: {title: "Rectoverso"}, // was "Rectosrev"
  bk_31ca0c23675b01c8: {title: "Catatan Masa Lalu Banten"}, // was "Catatan Masalalu Banten"
  bk_ebd2b781a9973254: {authors: ["Goenawan Mohamad"]}, // Eksotopi: was "Gunawan Mohamad"
  bk_f565098068727b23: {authors: ["H. Krafft", "F. Wiggers", "Kwee Tek Hoay", "Lie Kim Hok", "Rustam Effendi"]}, // Antologi Drama Indonesia 1: was "Lie Kom Hok"
  // A book about David Tobing, written by Rita Triana Budiarti.
  bk_d385b9015fb8ab64: {authors: ["Rita Triana Budiarti"]},
  bk_e543af6abc95dfea: {isbn13: null}, // Biografi Daripada Soeharto: the ISBN belongs to "Chic & modis kerudung"
  bk_8326add768e01788: {isbn13: null}, // Refrein di Sudut Dam: the ISBN belongs to a Bentang translation of Tears of the Giraffe
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
