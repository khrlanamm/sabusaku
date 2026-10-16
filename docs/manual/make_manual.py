"""Builds the Sabu Saku user guide for SMA Negeri 1 Sukodadi as one PDF.

Every page is HTML (brand colours, Poppins, phone mockups, numbered pins on
the screenshots, internal links) printed to an A4 PDF with headless Chrome.

    python3 -I docs/manual/make_manual.py

Input:  docs/manual/raw/*.png      full-resolution screenshots (1080x2424),
                                    git-ignored because they hold real emails
        docs/manual/shots/*.jpg    masked, cropped copies made from raw/
        docs/manual/assets/qr-play.svg   QR code to the Play Store listing
        assets/fonts/Poppins-*.ttf, branding/svg/logo-*.svg
Output: docs/manual/panduan-sabu-saku.pdf
        hosting/panduan.pdf        the same file, served at /panduan.pdf

Screenshots come from tool/screenshots.sh (integration_test/
screenshots_test.dart, real production accounts); copy the PNGs into
docs/manual/raw/. A changed PNG is turned into shots/<name>.jpg on the next
run (needs Pillow): MASKS below are painted over it first, then the top
142 px (status bar, or empty app background on Flutter captures) is cropped
and the image is shrunk to 640 px wide.

PRIVACY: every email address in a screenshot must be listed in MASKS before
the screenshot is used. Only masked JPEGs go into shots/ (committed).

Coordinates for pins and masks are in a 401x900 preview of the full raw
screenshot, which is what `sips -Z 900 raw/<name>.png` gives. Fractions are
fine. A mask is (left, top, right, bottom, fill, text): with text, the email
is replaced by that placeholder in the original colour and size; with None,
it becomes a soft rounded bar.

The QR code is static: regenerate it only if the store link changes, e.g.
with `pip install segno` in a throwaway venv and
`segno.make(PLAY_URL, error="m").save("qr-play.svg", border=0, dark="#14233A",
light=None, omitsize=True, xmldecl=False)`.
"""

import html
import pathlib
import re
import shutil
import subprocess
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MANUAL = ROOT / "docs" / "manual"
RAW = MANUAL / "raw"
SHOTS = MANUAL / "shots"
ASSETS = MANUAL / "assets"
OUT = MANUAL / "panduan-sabu-saku.pdf"
HOSTED = ROOT / "hosting" / "panduan.pdf"
FONTS = ROOT / "assets" / "fonts"
BRAND = ROOT / "branding" / "svg"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

APP_VERSION = "1.2.1"
SCHOOL = "SMA Negeri 1 Sukodadi"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.sabu.saku"
HELP_EMAIL = "komunitaskertaskosong9@gmail.com"

# Brand palette (lib/app/theme/colors.dart, branding/README.md).
NAVY, NAVY_DEEP, BLUE, BLUE_DARK = "#17365D", "#0F2747", "#2563EB", "#1D4FC4"
SKY, GREEN, GREEN_LIGHT, AMBER = "#E4EEFF", "#2FA866", "#5CD08A", "#F5B942"
BG, INK, MUTED, OUTLINE = "#F6F8FC", "#14233A", "#55647A", "#D9E1EC"
# Brand green darkened until white text on it passes AA contrast.
GREEN_DEEP = "#1E8048"

# Raw screenshot geometry. The top band is cropped: on device captures it is
# the status bar, on Flutter captures it is empty app background.
RAW_W, RAW_H, STATUS_BAR = 1080, 2424, 142
PREVIEW_W, PREVIEW_H = 401, 900
SHOT_W = 640

# Email addresses painted over before a screenshot is used, in preview
# coordinates: (left, top, right, bottom, fill, placeholder or None).
MASKS = {
    "mulai-pilih-akun-google": [(89.5, 480.5, 217.6, 492.3, "#FFFFFF", None),
                                (89.1, 543.2, 221.3, 555.1, "#FFFFFF", None)],
    "siswa-profil": [(109.9, 169.3, 264.4, 181.2, "#FFFFFF", "nama@gmail.com")],
    "siswa-ubah-password": [(70.9, 145.9, 277.0, 161.9, "#FFFFFF", "nama@gmail.com")],
    "guru-detail-siswa": [(82.4, 172.3, 237.3, 184.2, BG, "nama@gmail.com")],
    "guru-profil": [(110.3, 166.3, 258.8, 178.2, "#FFFFFF", "nama@gmail.com")],
}

# label, accent, text on accent, tint, accent as text on white
ROLES = {
    "mulai": ("Mulai", NAVY, "#FFFFFF", "#E5EBF4", NAVY),
    "siswa": ("Siswa", BLUE, "#FFFFFF", SKY, BLUE),
    "guru": ("Penanggung jawab", GREEN_DEEP, "#FFFFFF", "#E1F4E8", "#1B6B40"),
    "semua": ("Untuk semua", AMBER, INK, "#FDF1D6", "#7A4E00"),
}
SECTIONS = ("mulai", "siswa", "guru", "semua")


def prepare_shots():
    """Masks, crops and shrinks new screenshots from raw/ into shots/."""
    if not RAW.is_dir():
        return
    from PIL import Image, ImageDraw, ImageFont

    SHOTS.mkdir(parents=True, exist_ok=True)
    scale = RAW_W / PREVIEW_W
    for source in sorted(RAW.glob("*.png")):
        target = SHOTS / f"{source.stem}.jpg"
        # A masked shot is also redone when this script (and so MASKS) changes.
        newer = [source] + ([pathlib.Path(__file__)] if source.stem in MASKS else [])
        if target.exists() and all(target.stat().st_mtime >= f.stat().st_mtime for f in newer):
            continue
        image = Image.open(source).convert("RGB")
        draw = ImageDraw.Draw(image)
        for left, top, right, bottom, fill, text in MASKS.get(source.stem, []):
            box = [round(left * scale), round(top * scale), round(right * scale), round(bottom * scale)]
            # The darkest pixel of the original text gives the placeholder colour.
            fill_rgb = tuple(int(fill[i:i + 2], 16) for i in (1, 3, 5))
            region = image.crop(box)
            pixels = [region.getpixel((x, y)) for y in range(region.height) for x in range(region.width)]
            ink = max(pixels, key=lambda p: sum(abs(p[i] - fill_rgb[i]) for i in range(3)))
            pad = 6
            draw.rectangle([box[0] - pad, box[1] - pad, box[2] + pad, box[3] + pad], fill=fill)
            height = box[3] - box[1]
            if text is None:
                bar = round(height * 0.62)
                middle = (box[1] + box[3]) // 2
                draw.rounded_rectangle([box[0], middle - bar // 2, box[2], middle + bar // 2],
                                       radius=bar // 2, fill="#E6E9EE")
                continue
            # Size the placeholder so its glyph box is as tall as the email's.
            size = height
            for _ in range(4):
                font = ImageFont.truetype(str(FONTS / "Poppins-Regular.ttf"), size)
                glyphs = font.getbbox(text)
                size = max(8, round(size * height / (glyphs[3] - glyphs[1])))
            font = ImageFont.truetype(str(FONTS / "Poppins-Regular.ttf"), size)
            glyphs = font.getbbox(text)
            draw.text((box[0] - glyphs[0], box[1] - glyphs[1]), text, font=font, fill=ink)
        image = image.crop((0, STATUS_BAR, RAW_W, RAW_H))
        image = image.resize((SHOT_W, round(SHOT_W * image.height / image.width)), Image.LANCZOS)
        image.save(target, "JPEG", quality=88, optimize=True)
        print("shot", target.relative_to(ROOT))


def shot(name, step, *pins):
    """One screenshot with its caption and pins: (x, y, text) in preview px."""
    return {"name": name, "step": step, "pins": pins}


def note(title, *items, tone="info", ordered=False, shot=None):
    """A box next to the pin notes: a title and bullet (or numbered) items."""
    return {"title": title, "items": items, "tone": tone, "ordered": ordered, "shot": shot}


def page(kind, role, title, intro, shots=(), path=None, tip=None, toc=None, key=None, notes=()):
    return {"kind": kind, "role": role, "title": title, "intro": intro, "shots": list(shots),
            "path": path, "tip": tip, "toc": toc or title, "key": key, "notes": list(notes)}


# Text may link to another page with [[key]], which becomes "halaman N".
PAGES = [
    # ---------------------------------------------------------------- mulai
    page("install", "mulai", "Pasang Sabu Saku",
         "Sabu Saku ada di Google Play untuk HP Android. Gratis, tanpa iklan.",
         [shot("mulai-login", "")],
         key="pasang", toc="Pasang dari Google Play",
         tip="Sabu Saku diperbarui lewat Google Play seperti aplikasi lain. Panduan ini untuk versi " + APP_VERSION + "."),
    page("duo", "mulai", "Masuk dengan Google",
         "Cara paling cepat. Tidak perlu membuat password baru.",
         [shot("mulai-login", "Buka Sabu Saku",
               (64, 672, "Ketuk <b>Masuk dengan Google</b>.")),
          shot("mulai-pilih-akun-google", "Pilih akun",
               (352, 478, "Pilih akun Google yang <b>emailnya didaftarkan sekolah</b>. Selesai, kamu sudah masuk."),
               (330, 592, "Akunnya belum ada di HP? Ketuk <b>Add another account</b>."))],
         path="Layar masuk", key="google",
         tip="Pertama kali masuk? Setujui dulu <b>Ketentuan Penggunaan</b> ([[ketentuan]]), lalu <b>Lengkapi akun</b> "
             "([[lengkapi]]). Muncul pesan <b>Harap Menghubungi Administrator Sekolah</b>? Lihat [[email]]."),
    page("tour", "mulai", "Masuk dengan email",
         "Untuk akun yang sudah punya password, atau yang tidak memakai Google.",
         [shot("mulai-login", "",
               (372, 418, "Ketik <b>email</b> dan <b>password</b>."),
               (36, 578, "Ketuk <b>Masuk</b>."),
               (226, 531, "<b>Lupa password?</b> Ketik emailmu, lalu <b>Kirim</b>. Tautan untuk membuat password baru dikirim ke email itu."),
               (318, 738, "Belum punya akun dan tidak memakai Google? Ketuk <b>Daftar</b>, lihat [[daftar]]."))],
         path="Layar masuk", key="email",
         notes=[note("Muncul “Harap Menghubungi Administrator Sekolah”?",
                     "Artinya email itu belum didaftarkan di sekolah mana pun.",
                     "Hubungi <b>penanggung jawab Sabu Saku</b> di sekolah dan minta emailmu ditambahkan.",
                     "Setelah ditambahkan, masuk lagi dengan email yang sama.", tone="warn"),
                note("Akun Google tidak punya password?",
                     "Tidak perlu <b>Lupa password</b>. Pakai <b>Masuk dengan Google</b> saja.")],
         tip="Pertama kali masuk? Layar <b>Ketentuan Penggunaan</b> muncul dulu, lihat [[ketentuan]]. "
             "Email dari Sabu Saku tidak ada di kotak masuk? Periksa folder <b>Spam</b>.",
         toc="Masuk dengan email, lupa password"),
    page("tour", "mulai", "Daftar dengan email",
         "Tidak memakai Google? Buat akun dengan email yang didaftarkan sekolah, lalu verifikasi emailnya.",
         [shot("mulai-daftar", "",
               (372, 252, "Pakai email yang <b>didaftarkan sekolahmu</b>. Punya akun Google dengan email itu? Kembali, pilih Masuk dengan Google."),
               (372, 430, "Ketik email."),
               (300, 494, "Buat password."),
               (330, 562, "Bulatan berubah hijau saat syaratnya terpenuhi."),
               (300, 652, "Ketik ulang password yang sama."),
               (36, 720, "Ketuk <b>Daftar</b>."))],
         path="Layar masuk › Daftar", key="daftar",
         notes=[note("Lalu verifikasi email",
                     "Layar <b>Cek email kamu</b> muncul.",
                     "Buka email dari Sabu Saku, lalu ketuk tautan verifikasinya. Belum datang? Periksa folder Spam, "
                     "atau ketuk <b>Kirim ulang email</b>.",
                     "Kembali ke aplikasi dan ketuk <b>Saya sudah verifikasi</b>.",
                     "Layar <b>Ketentuan Penggunaan</b> muncul, lihat [[ketentuan]].", ordered=True)],
         toc="Daftar dan verifikasi email"),
    page("tour", "mulai", "Setujui ketentuan",
         "Sebelum mulai, setiap pengguna, siswa maupun penanggung jawab, menyetujui aturan memakai Sabu Saku.",
         [shot("mulai-ketentuan", "",
               (355, 322, "Enam aturan singkat: pakai akunmu sendiri, tulis dengan sopan dan dengan kata-katamu sendiri, "
                          "jangan melecehkan atau membuka data pribadi orang lain."),
               (357, 607, "Lihat yang melanggar? Pakai menu <b>Laporkan</b>, lihat [[laporkan]]."),
               (305, 708, "<b>Baca selengkapnya</b>: ketentuan lengkap di situs Sabu Saku."),
               (40, 770, "Ketuk <b>Saya setuju</b>. Lalu layar <b>Lengkapi akun</b> muncul, lihat [[lengkapi]]."),
               (250, 819, "Belum mau setuju? Ketuk <b>Keluar</b>. Sabu Saku baru bisa dipakai setelah ketentuan disetujui."))],
         path="Setelah masuk", key="ketentuan",
         notes=[note("Kapan layar ini muncul?",
                     "Setelah pertama kali masuk, sebelum <b>Lengkapi akun</b>.",
                     "Lagi saat ketentuannya berubah. Baca yang baru, lalu ketuk <b>Saya setuju</b>.",
                     "Mau membacanya lagi? Buka <b>Profil › Ketentuan penggunaan</b>."),
                note("Ketentuan lengkap",
                     "<b>sabusaku.web.app/ketentuan</b>: konten yang dilarang, cara melapor, dan sanksinya.",
                     tone="plain")],
         toc="Setujui ketentuan penggunaan"),
    page("tour", "mulai", "Lengkapi akun dan password",
         "Setelah ketentuan disetujui, layar Lengkapi akun muncul. Syarat password di sana sama dengan layar Ubah password ini.",
         [shot("siswa-ubah-password", "",
               (300, 217, "<b>Password saat ini</b> hanya diminta saat mengganti password lama."),
               (300, 281, "Ketik password baru."),
               (330, 350, "Syarat: minimal 8 karakter, huruf besar dan kecil, angka, dan karakter khusus. Yang terpenuhi jadi <b>hijau</b>."),
               (300, 438, "Ketik ulang password yang sama."),
               (36, 510, "Ketuk <b>Simpan password</b>."))],
         path="Profil › Ubah password", key="lengkapi",
         notes=[note("Isi layar Lengkapi akun",
                     "<b>Nama lengkap</b>.",
                     "<b>Kelas</b> dari daftar sekolah, misalnya XII-A1.",
                     "<b>Ekstrakurikuler</b>: Masis-KIR, Paskibra, Pala, PMR. Boleh lebih dari satu, boleh tidak ada.",
                     "<b>Foto</b>, kalau mau.",
                     "Masuk dengan Google? <b>Buat password</b> juga, supaya bisa masuk dengan email.",
                     "Ketuk <b>Simpan dan lanjutkan</b>.")],
         toc="Lengkapi akun, password kuat"),

    # ---------------------------------------------------------------- siswa
    page("divider", "siswa", "Siswa",
         "Pilih satu buku setiap bulan, catat bacaanmu setiap hari, dan baca komentar dari guru.",
         [shot("siswa-beranda", "")], key="siswa"),
    page("tour", "siswa", "Beranda",
         "Semua yang perlu kamu tahu hari ini ada di satu layar.",
         [shot("siswa-beranda-komentar", "",
               (365, 160, "<b>Buku bulan ini</b>: cover, judul, dan penulis."),
               (330, 237, "Progres: halaman terakhir yang kamu catat."),
               (280, 291, "Sudah menulis hari ini? Tanda centang muncul, ketuk <b>Lihat</b>. Belum? Ketuk <b>Isi Jurnal Hari Ini</b>."),
               (172, 372, "Jumlah jurnal bulan ini."),
               (362, 372, "<b>Streak</b>: hari berturut-turut kamu menulis jurnal."),
               (300, 498, "<b>Komentar baru dari guru</b>. Ketuk untuk membacanya."),
               (200, 833, "Menu: <b>Beranda</b>, <b>Buku</b>, <b>Jurnal</b>, <b>Profil</b>."))],
         path="Tab Beranda",
         tip="Lewat dari target selesai? Label <b>Terlambat</b> muncul di kartu buku."),
    page("duo", "siswa", "Mulai buku dari katalog",
         "Katalog berisi sekitar 1.200 buku Indonesia, lengkap dengan cover. Cari dulu di sana.",
         [shot("siswa-mulai-buku", "Buka Mulai Buku",
               (318, 193, "Target selesai: <b>akhir bulan ini</b>."),
               (372, 234, "Ketik judul atau penulis."),
               (330, 290, "Tidak ketemu? Isi data sendiri, lihat [[sendiri]]."),
               (250, 738, "Belum tahu mau baca apa? Ada <b>Jelajahi katalog</b> di bawah.")),
          shot("siswa-cari-buku", "Pilih bukunya",
               (300, 234, "Hasil muncul saat kamu mengetik."),
               (300, 325, "Ketuk bukunya untuk memilih."))],
         path="Tab Buku", key="mulai-buku",
         tip="Belum punya buku? Tab <b>Buku</b> langsung membuka layar <b>Mulai Buku</b>."),
    page("tour", "siswa", "Periksa, lalu mulai membaca",
         "Data buku dari katalog langsung terisi. Periksa sebentar, lalu mulai.",
         [shot("siswa-buku-dipilih", "",
               (372, 140, "<b>Dari katalog</b>: data sudah terisi."),
               (240, 190, "<b>Ganti buku</b>: kembali ke pencarian."),
               (372, 200, "<b>Foto cover</b>: pakai foto sampul bukumu sendiri."),
               (372, 292, "Isian boleh diubah. Perubahan hanya untuk bukumu dan dikirim sebagai <b>saran</b> ke penanggung jawab."),
               (372, 441, "<b>Jumlah halaman</b> tidak bisa diubah setelah buku dimulai."),
               (40, 596, "Ketuk <b>Mulai membaca</b>. Butuh koneksi internet."))],
         path="Tab Buku › pilih buku",
         tip="Satu buku aktif dalam satu waktu. Mau ganti buku setelah mulai? Hentikan dulu, lihat [[buku-saya]].",
         toc="Periksa lalu mulai membaca"),
    page("tour", "siswa", "Tidak ketemu? Isi sendiri",
         "Bukumu belum ada di katalog? Isi datanya sendiri. Bukunya sekaligus diusulkan ke katalog.",
         [shot("siswa-isi-data-sendiri", "",
               (252, 188, "<b>Tambah foto</b> cover dari kamera atau galeri. Bisa dipotong dan diputar. Opsional."),
               (372, 249, "Judul buku."),
               (372, 313, "Penulis. Lebih dari satu? Pisahkan dengan koma."),
               (372, 397, "Jumlah halaman: <b>10 sampai 2000</b>. Tidak bisa diubah setelah buku dimulai."),
               (372, 480, "ISBN boleh dikosongkan."),
               (372, 536, "Buku ini dikirim sebagai <b>saran</b> ke katalog."),
               (40, 607, "Ketuk <b>Mulai membaca</b>."))],
         path="Tab Buku › Tidak ketemu? Isi data buku sendiri", key="sendiri",
         tip="Foto cover dikecilkan dulu di HP sebelum dikirim, jadi hemat kuota.",
         toc="Isi data buku sendiri"),
    page("duo", "siswa", "Jelajahi katalog",
         "Belum tahu mau baca apa? Lihat pilihan sekolah dan buku yang sedang ramai dibaca.",
         [shot("siswa-jelajahi", "Jelajahi",
               (372, 140, "Cari judul atau penulis."),
               (372, 196, "Pilih kategori."),
               (215, 244, "<b>Populer di sekolahmu</b>: buku yang sedang dibaca temanmu."),
               (190, 490, "<b>Semua buku</b> di katalog.")),
          shot("siswa-jelajahi-klasik", "Satu kategori",
               (205, 177, "Jumlah buku di kategori ini."),
               (372, 230, "Ketuk buku untuk melihat detailnya."))],
         path="Tab Buku › Jelajahi katalog", key="jelajahi",
         tip="Buku pilihan penanggung jawab tampil paling atas di bagian <b>Rekomendasi sekolah</b>."),
    page("tour", "siswa", "Detail buku",
         "Kenali bukunya dulu sebelum memilih.",
         [shot("siswa-detail-buku", "",
               (377, 110, "<b>⋮</b> › <b>Laporkan buku</b>: datanya salah atau isinya tidak pantas? Lihat [[laporkan]]."),
               (318, 342, "Judul, penulis, dan kategori."),
               (330, 478, "Berapa siswa yang membacanya, dan berapa dari sekolahmu."),
               (330, 555, "Penerbit, tahun terbit, halaman, dan ISBN."),
               (110, 672, "<b>Sinopsis</b>. Ketuk <b>Selengkapnya</b> untuk membaca semuanya."),
               (200, 878, "Gulir ke bawah, lalu ketuk <b>Baca buku ini</b>."))],
         path="Jelajahi katalog › ketuk buku", key="detail-buku-siswa",
         tip="Tombol <b>Baca buku ini</b> baru bisa diketuk kalau kamu tidak sedang membaca buku lain."),
    page("tour", "siswa", "Isi jurnal harian",
         "Satu jurnal untuk satu hari. Catat halaman yang kamu baca dan isi bacaannya.",
         [shot("siswa-isi-jurnal", "",
               (372, 134, "Pilih tanggal: <b>Hari ini</b>, <b>Kemarin</b>, atau <b>2 hari lalu</b>, asal tidak sebelum buku dimulai."),
               (170, 228, "<b>Dari halaman</b> terisi sendiri, lanjut dari jurnal terakhir."),
               (372, 228, "<b>Sampai halaman</b>: paling banyak sejumlah halaman buku."),
               (170, 390, "<b>Durasi membaca</b>: kurang dari 15, 15–30, 30–60, atau lebih dari 60 menit."),
               (225, 433, "<b>Informasi penting</b>: isi bacaan hari ini, minimal 30 karakter. Penghitung di bawahnya membantu."),
               (240, 633, "<b>Hal yang menarik</b> dan <b>Pertanyaan</b> boleh kosong. Semua isian maksimal 1000 karakter."))],
         path="Tab Jurnal › Isi Jurnal", key="jurnal",
         tip="Tidak ada sinyal? Tetap ketuk <b>Simpan</b>. Jurnal tersimpan di HP dan terkirim sendiri saat online."),
    page("duo", "siswa", "Riwayat jurnal dan komentar guru",
         "Semua jurnalmu tersimpan. Komentar guru muncul di bawah jurnal yang dikomentari.",
         [shot("siswa-riwayat-jurnal", "Riwayat Jurnal",
               (240, 122, "Buku yang sedang dibaca."),
               (372, 160, "Jurnal terbaru di atas. Ketuk untuk membukanya."),
               (245, 748, "<b>Isi Jurnal</b>: tulis jurnal baru.")),
          shot("siswa-jurnal-komentar", "Jurnal dan komentar",
               (320, 193, "Halaman dan durasi membaca."),
               (165, 628, "<b>Komentar guru</b> untuk jurnal ini."),
               (320, 683, "Nama guru, isi komentar, dan waktunya. Ketuk <b>⋮</b> untuk melaporkan, lihat [[laporkan]]."))],
         path="Tab Jurnal",
         tip="Pertanyaan <b>Aktifkan notifikasi?</b> muncul? Ketuk <b>Izinkan</b>. Kamu diberi tahu setiap kali guru berkomentar.",
         toc="Riwayat jurnal, komentar guru"),
    page("duo", "siswa", "Ubah atau hapus jurnal",
         "Salah ketik? Jurnal masih bisa diubah atau dihapus sampai akhir hari berikutnya.",
         [shot("siswa-jurnal-komentar", "Buka jurnalnya",
               (292, 80, "Ikon pensil: <b>ubah</b> jurnal."),
               (377, 114, "Ikon tempat sampah: <b>hapus</b> jurnal. Komentar guru ikut terhapus.")),
          shot("siswa-ubah-jurnal", "Ubah isinya",
               (252, 196, "Tanda <b>mengubah jurnal</b>."),
               (372, 253, "Ubah halaman, durasi, atau isinya, lalu ketuk <b>Simpan perubahan</b> di bawah."))],
         path="Tab Jurnal › ketuk jurnal",
         tip="Contoh: jurnal hari Jumat bisa diubah sampai Sabtu malam. Setelah itu jurnal terkunci dan ikonnya hilang."),
    page("tour", "siswa", "Buku Saya",
         "Pantau progres bukumu dan selesaikan sebelum target.",
         [shot("siswa-buku-saya", "",
               (200, 300, "<b>Progres</b> dari jurnal terakhirmu."),
               (340, 415, "Tanggal mulai, <b>target selesai</b>, dan jumlah hari berjurnal."),
               (40, 541, "<b>Tandai Selesai</b> aktif setelah jurnalmu mencapai halaman terakhir. Boleh tulis ulasan akhir."),
               (40, 617, "<b>Perpanjang target</b>: sekali saja, sampai akhir bulan berikutnya, paling lama 31 hari."),
               (290, 668, "<b>Hentikan buku</b> kapan saja. Buku dan jurnalnya tetap ada di riwayat."))],
         path="Tab Buku", key="buku-saya",
         tip="Setelah buku selesai atau dihentikan, kamu bisa memulai buku baru dari tab <b>Buku</b>."),
    page("tour", "siswa", "Laporkan komentar atau buku",
         "Ada komentar atau buku yang melanggar ketentuan? Laporkan dari aplikasi.",
         [shot("siswa-laporkan-komentar", "",
               (268, 428, "Laporan tentang penanggung jawab, komentarnya atau dirinya, hanya dibaca <b>pengembang Sabu Saku</b>."),
               (330, 516, "Pilih <b>alasannya</b>: tidak pantas, perundungan, data pribadi orang lain, hak cipta, atau lainnya."),
               (355, 760, "<b>Catatan</b> boleh dikosongkan, paling banyak 500 karakter."),
               (40, 862, "Ketuk <b>Kirim laporan</b>. Pesan <b>Laporan terkirim</b> muncul."))],
         path="Jurnal › ⋮ pada komentar guru", key="laporkan",
         notes=[note("Yang bisa dilaporkan",
                     "<b>Komentar guru</b>: buka jurnalnya, ketuk <b>⋮</b> pada komentar, lalu <b>Laporkan komentar</b> "
                     "atau <b>Laporkan pengguna</b>.",
                     "<b>Buku katalog</b>: di Detail buku ketuk <b>⋮</b> › <b>Laporkan buku</b>. Ada alasan tambahan "
                     "<b>Data buku salah</b>, lihat [[detail-buku-siswa]]."),
                note("Siapa yang membaca?",
                     "Laporan tentang penanggung jawab hanya dibaca pengembang. Guru yang kamu laporkan tidak melihatnya.",
                     "Laporan buku dibaca penanggung jawab sekolah dan pengembang.", tone="plain"),
                note("Melapor dengan jujur",
                     "Laporan palsu, atau laporan berulang untuk mengganggu orang lain, juga melanggar ketentuan.",
                     "Ada bahaya langsung bagi seseorang? Segera beri tahu guru atau orang tua.", tone="warn")],
         toc="Laporkan komentar atau buku"),
    page("tour", "siswa", "Profil",
         "Statistik membaca, riwayat buku, dan pengaturan akunmu.",
         [shot("siswa-profil", "",
               (36, 140, "Ketuk foto: <b>pilih dari galeri</b>, <b>ambil foto</b>, atau <b>pakai foto Google</b>."),
               (372, 240, "Ketuk pensil untuk mengubah <b>kelas</b> dan <b>ekskul</b>."),
               (195, 330, "Total jurnal, buku selesai, dan streak terbaik."),
               (150, 503, "<b>Riwayat buku</b>: semua buku yang pernah kamu baca."),
               (300, 697, "<b>Tema</b>: Terang, Gelap, atau Ikuti perangkat."),
               (372, 765, "Notifikasi komentar guru belum aktif? Ketuk <b>Aktifkan</b>."))],
         path="Tab Profil", key="profil",
         notes=[note("Tema gelap",
                     "Nyaman untuk membaca malam hari. Pilihan tema tersimpan di HP ini.",
                     shot="siswa-beranda-gelap"),
                note("Gulir ke bawah",
                     "<b>Ketentuan penggunaan</b> dan <b>Kebijakan privasi</b>: dibuka di situs Sabu Saku.",
                     "<b>Ubah nama</b> dan <b>Ubah password</b>.",
                     "<b>Keluar</b> dari akun di HP ini.",
                     "<b>Hapus akun</b>: buku, jurnal, dan komentar guru ikut terhapus permanen. Ketik HAPUS untuk memastikan.")],
         toc="Profil dan tema gelap"),

    # ----------------------------------------------------------------- guru
    page("divider", "guru", "Penanggung jawab",
         "Pantau keaktifan siswa, beri komentar pada jurnal, kelola siswa dan katalog buku sekolah.",
         [shot("guru-dashboard-gelap", "")], key="guru"),
    page("tour", "guru", "Dashboard",
         "Ringkasan keaktifan siswa di sekolah Anda.",
         [shot("guru-dashboard", "",
               (372, 200, "Saring: <b>Semua siswa</b> atau satu ekskul."),
               (372, 255, "Jumlah siswa, <b>Buku aktif</b>, dan <b>Jurnal bulan ini</b>."),
               (372, 400, "Siswa yang <b>belum masuk aplikasi</b>. Ketuk untuk melihat daftarnya."),
               (200, 545, "<b>Status siswa</b>. Ketuk satu status untuk melihat siswanya."),
               (165, 757, "<b>Perlu perhatian</b>: yang paling lama tidak menulis di atas."),
               (240, 833, "Menu: Dashboard, Siswa, Buku, Sekolah, Profil."))],
         path="Tab Dashboard", key="dashboard",
         notes=[note("Arti status",
                     '<span class="chip ok">Aktif</span> paling lama 3 hari efektif tanpa jurnal.',
                     '<span class="chip warn">Perlu perhatian</span> 4–7 hari efektif tanpa jurnal.',
                     '<span class="chip bad">Tidak aktif</span> lebih dari 7 hari efektif.',
                     '<span class="chip none">Belum ada buku</span> belum memulai buku.',
                     "Hari netral dan hari libur tidak dihitung. Angkanya bisa diatur, lihat [[pengaturan]].",
                     tone="plain")]),
    page("tour", "guru", "Daftar siswa",
         "Cari dan saring siswa, lalu buka detailnya.",
         [shot("guru-siswa", "",
               (372, 137, "Cari nama atau email."),
               (340, 188, "Saring menurut <b>kelas</b> dan <b>ekskul</b>."),
               (372, 236, "Saring menurut status."),
               (372, 280, "<b>Belum masuk</b>: sudah didaftarkan, belum pernah masuk. Ketuk untuk membuka daftarnya."),
               (240, 384, "Kelas, ekskul, status, dan progres buku. Ketuk untuk membuka detail siswa."),
               (245, 748, "<b>Tambah</b>: satu per satu atau impor CSV."))],
         path="Tab Siswa", key="daftar-siswa",
         tip="Siswa yang belum masuk bisa diubah datanya atau dihapus dari daftar. Ketuk namanya di bagian <b>Belum masuk</b>."),
    page("duo", "guru", "Tambah siswa",
         "Cukup email. Nama dan kelas dilengkapi siswa sendiri saat pertama masuk.",
         [shot("guru-tambah-siswa", "Satu per satu",
               (372, 270, "Hanya <b>email</b> yang wajib."),
               (372, 333, "Nama dan kelas boleh kosong."),
               (330, 550, "Ekskul boleh lebih dari satu."),
               (40, 684, "<b>Tambah baris</b> untuk siswa lain, lalu <b>Tambahkan siswa</b>.")),
          shot("guru-impor-csv", "Impor CSV",
               (372, 215, "Kolom: <b>email,nama,kelas,ekskul</b>. Hanya email yang wajib."),
               (40, 551, "<b>Bagikan templat CSV</b> untuk contoh berkasnya."),
               (40, 608, "<b>Pilih berkas CSV</b>, periksa, lalu impor."))],
         path="Tab Siswa › Tambah", key="tambah-siswa",
         tip="Setelah ditambahkan, siswa masuk dengan email itu lewat <b>Masuk dengan Google</b> atau <b>Daftar</b>.",
         toc="Tambah siswa, impor CSV"),
    page("tour", "guru", "Detail siswa",
         "Buku aktif, keaktifan, dan riwayat buku satu siswa.",
         [shot("guru-detail-siswa", "",
               (377, 106, "<b>⋮</b> › <b>Laporkan pengguna</b>: nama, foto, atau perilaku siswa melanggar ketentuan, lihat [[laporan]]."),
               (290, 165, "Nama, kelas, ekskul, email, dan status."),
               (255, 216, "<b>Ubah nama, kelas, ekskul</b>."),
               (372, 330, "<b>Buku aktif</b>. Ketuk untuk membaca jurnalnya."),
               (372, 410, "Streak, jurnal bulan ini, dan buku selesai."),
               (180, 563, "<b>Aktivitas terakhir</b>."),
               (150, 667, "<b>Riwayat buku</b>. Ketuk buku untuk melihat semua jurnalnya."),
               (40, 847, "<b>Keluarkan dari sekolah</b>: akun, jurnal, dan riwayat bukunya tetap disimpan."))],
         path="Tab Siswa › ketuk siswa", key="detail-siswa",
         notes=[note("Hapus data permanen",
                     "Tombolnya paling bawah. Semua buku, jurnal, dan komentar siswa di sekolah ini hilang selamanya.",
                     "Ketik <b>HAPUS</b> untuk memastikan. Akun siswanya sendiri tetap ada.", tone="warn"),
                note("Keluarkan atau hapus?",
                     "Pilih <b>Keluarkan</b> bila siswa pindah. Datanya kembali bila emailnya ditambahkan lagi.")]),
    page("duo", "guru", "Jurnal siswa dan komentar",
         "Baca jurnal siswa dan beri tanggapan. Siswa langsung mendapat notifikasi.",
         [shot("guru-jurnal-siswa", "Daftar jurnal",
               (240, 122, "Buku dan statusnya."),
               (372, 160, "Ketuk jurnal untuk membacanya.")),
          shot("guru-jurnal-komentar", "Baca dan komentari",
               (377, 110, "<b>⋮</b> › <b>Laporkan jurnal</b>, lihat [[laporan]]."),
               (320, 193, "Halaman dan durasi membaca."),
               (320, 683, "Komentar Anda. Ketuk <b>⋮</b> untuk <b>Ubah</b> atau <b>Hapus</b>."),
               (290, 843, "Tulis komentar, lalu ketuk tombol kirim."))],
         path="Detail siswa › Buku aktif", key="jurnal-guru",
         tip="Tanggapi isi bacaannya atau jawab pertanyaan siswa. Komentar singkat pun membuat siswa semangat.",
         toc="Jurnal siswa dan komentar"),
    page("tour", "guru", "Sekolah",
         "Laporan, label kelas dan ekstrakurikuler yang dipilih siswa, serta daftar penanggung jawab.",
         [shot("guru-sekolah", "",
               (330, 150, "Nama sekolah Anda."),
               (320, 210, "<b>Laporan</b> dari siswa dan penanggung jawab. Angkanya: laporan yang perlu ditinjau, lihat [[laporan]]."),
               (120, 322, "<b>Kelas</b>: siswa memilih kelasnya dari daftar ini. Format: XII-A1, X-G2."),
               (262, 322, "<b>Tambah</b> label baru. Ketuk <b>✕</b> untuk menghapus label."),
               (190, 681, "<b>Ekstrakurikuler</b>: siswa boleh ikut lebih dari satu, atau tidak sama sekali."))],
         path="Tab Sekolah", key="sekolah",
         notes=[note("Label yang dihapus",
                     "Tidak bisa dipilih lagi. Siswa yang sudah memakainya tetap memakai label itu sampai diganti."),
                note("Gulir ke bawah",
                     "<b>Penanggung jawab</b> sekolah ini, ditambahkan oleh pengembang Sabu Saku.",
                     "<b>Pengaturan status siswa</b>: hari netral, ambang status, dan hari libur. Lihat [[pengaturan]].")],
         toc="Sekolah: laporan, kelas, ekskul"),
    page("tour", "guru", "Pengaturan status",
         "Atur kapan siswa dianggap aktif, perlu perhatian, atau tidak aktif.",
         [shot("guru-pengaturan-sekolah", "",
               (372, 208, "<b>Hari netral</b>, bawaannya Minggu: tidak memutus streak dan tidak dihitung dalam ambang status."),
               (372, 408, "<b>Ambang status</b>: atur dengan − dan +. Bawaannya 3 dan 7 hari."),
               (200, 531, "<b>Hari libur sekolah</b>: ketuk <b>Tambah</b>. Hari libur juga tidak dihitung."),
               (40, 616, "Ketuk <b>Simpan pengaturan</b>. Status semua siswa dihitung ulang."))],
         path="Sekolah › Pengaturan status siswa", key="pengaturan",
         notes=[note("Contoh",
                     "Siswa menulis jurnal hari Sabtu, lalu Senin. Minggu hari netral, jadi streak-nya tidak putus.",
                     "Hari efektif = semua hari selain hari netral dan hari libur sekolah.", tone="plain")],
         toc="Pengaturan status siswa"),
    page("tour", "guru", "Katalog buku",
         "Satu katalog dipakai bersama semua sekolah. Perubahan Anda terlihat oleh semua sekolah.",
         [shot("guru-katalog", "",
               (295, 80, "<b>Saran dari siswa</b>. Angka muncul bila ada saran yang menunggu."),
               (377, 110, "<b>Buku terhapus</b>."),
               (300, 137, "Cari judul atau penulis."),
               (372, 192, "Pilih kategori."),
               (190, 244, "Buku rekomendasi sekolah Anda tampil paling atas."),
               (372, 290, "Ketuk buku untuk membuka detailnya."),
               (300, 722, "<b>Tambah buku</b> baru ke katalog."))],
         path="Tab Buku", key="katalog"),
    page("tour", "guru", "Detail buku dan rekomendasi",
         "Rapikan data buku dan pilih buku yang direkomendasikan untuk siswa Anda.",
         [shot("guru-detail-buku", "",
               (292, 80, "Ikon pensil: <b>Ubah data buku</b>."),
               (377, 108, "<b>⋮</b> › <b>Laporkan buku</b>: isinya tidak pantas atau perlu diperiksa pengembang. Lihat [[laporan]]."),
               (140, 262, "Ikon kamera: <b>Ganti cover</b>. Foto bisa dipotong dan diputar."),
               (372, 330, "Data buku, jumlah pembaca, dan siapa yang terakhir mengubahnya."),
               (160, 856, "<b>★ Rekomendasikan</b>: buku tampil paling atas saat siswa mencari."))],
         path="Tab Buku › ketuk buku", key="detail-buku",
         notes=[note("Rekomendasikan 10–20 buku",
                     "Pilihan yang jelas membantu siswa yang belum tahu mau membaca apa.", tone="accent"),
                note("Gulir ke bawah",
                     "Tombol <b>Ubah</b> dan <b>Hapus</b>, lihat [[terhapus]].",
                     "<b>Saran menunggu</b> untuk buku ini, lihat [[saran]].",
                     "<b>Riwayat</b>: setiap perubahan, siapa, dan kapan.")],
         toc="Detail buku, rekomendasi"),
    page("tour", "guru", "Tambah buku",
         "Buku yang belum ada bisa langsung ditambahkan ke katalog.",
         [shot("guru-tambah-buku", "",
               (290, 268, "<b>Tambah cover</b> dari kamera atau galeri. Bisa dipotong dan diputar. Opsional."),
               (372, 325, "<b>Judul</b> wajib. Subjudul boleh kosong."),
               (372, 450, "<b>Penulis</b> wajib, minimal satu. Pisahkan dengan koma."),
               (200, 594, "<b>Jumlah halaman</b> wajib: 10–2000. Tahun terbit boleh kosong."),
               (372, 690, "ISBN-13 dan ISBN-10 boleh kosong."),
               (150, 775, "<b>Kategori</b>: pilih 1 sampai 3."))],
         path="Tab Buku › Tambah buku",
         notes=[note("Gulir ke bawah",
                     "<b>Sinopsis</b> boleh kosong. Ketuk <b>Simpan buku</b>.",
                     "Bukunya ternyata sudah ada? Sabu Saku memberi tahu dan menawarkan membuka buku itu.")]),
    page("tour", "guru", "Saran dari siswa",
         "Siswa ikut merapikan katalog. Anda yang memutuskan.",
         [shot("guru-saran", "",
               (255, 430, "Belum ada saran. Bila ada, daftarnya muncul di sini."))],
         path="Tab Buku › ikon kotak masuk", key="saran",
         notes=[note("Ubah data",
                     "Siswa mengubah data buku katalog, misalnya judul atau jumlah halaman.",
                     "Anda melihat <b>Sekarang</b> dan <b>Usulan</b> per isian. Centang yang benar, lalu <b>Terapkan</b>. Atau <b>Tolak</b>."),
                note("Buku baru",
                     "Siswa mengisi buku yang belum ada di katalog.",
                     "<b>Tambahkan ke katalog</b>: data terisi dari saran, rapikan dulu.",
                     "<b>Gabungkan ke buku yang ada</b>: bukunya ternyata sudah ada.",
                     "<b>Tolak</b>: buku tidak ditambahkan."),
                note("Di mana saran muncul",
                     "Ikon kotak masuk di <b>Katalog Buku</b>. Angkanya menunjukkan saran yang menunggu.",
                     "Detail buku, di bagian <b>Saran menunggu</b>.",
                     "Setiap keputusan tercatat di riwayat buku.", tone="plain"),
                note("Saran tidak pantas?",
                     "Buka sarannya, ketuk <b>⋮</b> › <b>Laporkan saran</b>, lihat [[laporan]]. Tolak juga sarannya.",
                     tone="warn")]),
    page("tour", "guru", "Hapus buku dan Buku terhapus",
         "Menghapus buku tidak menghilangkan apa pun. Buku bisa diaktifkan kembali.",
         [shot("guru-buku-terhapus", "",
               (255, 445, "Buku yang dihapus muncul di sini."))],
         path="Tab Buku › ikon tempat sampah", key="terhapus",
         notes=[note("Cara menghapus",
                     "Buka detail buku, ketuk <b>Hapus</b>.",
                     "Boleh beri alasan, misalnya data salah. Bisa juga tandai <b>Duplikat dari…</b> buku lain.",
                     "Ketuk <b>Hapus</b> sekali lagi.", ordered=True),
                note("Yang terjadi",
                     "Buku pindah ke <b>Buku terhapus</b> dan tidak muncul di pencarian siswa.",
                     "Siswa yang sudah membacanya tidak terpengaruh.",
                     "Penanggung jawab sekolah mana pun bisa mengembalikannya."),
                note("Mengaktifkan kembali",
                     "Buka <b>Buku terhapus</b> dari ikon di Katalog Buku.",
                     "Ketuk <b>Aktifkan</b> pada bukunya, lalu <b>Aktifkan</b> lagi.",
                     "Buku kembali muncul di katalog dan pencarian siswa.", ordered=True, tone="plain")],
         toc="Hapus buku, Buku terhapus"),
    page("tour", "guru", "Laporan dan moderasi",
         "Siswa dan penanggung jawab bisa melaporkan konten yang melanggar ketentuan. Anda meninjau laporan sekolah Anda.",
         [shot("guru-laporan", "",
               (170, 138, "<b>Terbuka</b>: belum ditangani. <b>Selesai</b>: sudah ditandai selesai, beserta tindakannya."),
               (245, 465, "Belum ada laporan. Bila ada, kartunya muncul di sini."))],
         path="Sekolah › Laporan", key="laporan",
         notes=[note("Isi kartu laporan",
                     "Jenis, <b>alasan</b>, dan salinan konten saat dilaporkan.",
                     "Catatan dan nama <b>pelapor</b>, serta waktunya.",
                     "<b>Buka</b>: langsung ke konten yang dilaporkan.",
                     "<b>Tandai selesai</b>: tulis tindakan yang diambil, boleh kosong."),
                note("Melaporkan sendiri",
                     "Ketuk <b>⋮</b> di Jurnal siswa, Detail siswa, Detail buku, atau Tinjau saran.",
                     "Pilih alasannya, lalu <b>Kirim laporan</b>. <b>Data buku salah</b> khusus untuk buku dan saran.",
                     shot="guru-laporkan-buku"),
                note("Tindakan yang bisa diambil",
                     "Ubah atau hapus buku, lihat [[terhapus]]. Tolak saran, lihat [[saran]].",
                     "Ubah data siswa, keluarkan, atau hapus datanya, lihat [[detail-siswa]].", tone="plain"),
                note("Laporan tentang penanggung jawab",
                     "Komentar atau akun penanggung jawab yang dilaporkan hanya dibaca pengembang Sabu Saku, "
                     "tidak muncul di sini.", tone="warn")],
         toc="Laporan dan moderasi"),
    page("tour", "guru", "Profil penanggung jawab",
         "Foto, ekskul yang dibina, pengaturan, dan akun Anda.",
         [shot("guru-profil", "",
               (36, 140, "Ketuk foto untuk menggantinya."),
               (190, 257, "<b>Ekskul yang dibina</b>, diatur oleh pengembang Sabu Saku."),
               (300, 397, "<b>Tema</b>: Terang, Gelap, atau Ikuti perangkat."),
               (300, 492, "<b>Ketentuan penggunaan</b> dan <b>Kebijakan privasi</b>, dibuka di situs Sabu Saku."),
               (300, 643, "<b>Ubah nama</b>, <b>Ubah password</b>, dan <b>Keluar</b>."),
               (165, 781, "<b>Hapus akun</b>. Komentar yang sudah Anda tulis tetap tersimpan."))],
         path="Tab Profil",
         notes=[note("Tema gelap",
                     "Semua layar ikut gelap, termasuk katalog. Pilihan tema tersimpan di HP ini.",
                     shot="guru-katalog-gelap")],
         toc="Profil dan tema gelap"),

    # ---------------------------------------------------------------- semua
    page("rules", "semua", "Aturan penting",
         "Ringkasan aturan Sabu Saku. Aturan buku dan jurnal dijaga aplikasi dengan sendirinya.",
         key="aturan"),
    page("tips", "semua", "Enam tips", "Supaya Sabu Saku terasa ringan dipakai setiap hari.",
         toc="Tips"),
    page("missions", "semua", "Kartu misi",
         "Coba satu per satu, lalu centang. Setelah semua tercentang, kamu sudah menguasai Sabu Saku.",
         key="misi"),
    page("help", "semua", "Bantuan", "Ada yang macet atau membingungkan? Ini tempat bertanya.",
         key="bantuan"),
]

RULES = [
    ("Akun dan ketentuan", "mulai", [
        "Masuk dengan email yang <b>didaftarkan sekolah</b>, lewat Google atau email dan password.",
        "Satu email untuk satu sekolah.",
        "Setujui <b>ketentuan penggunaan</b> sebelum mulai: sabusaku.web.app/ketentuan.",
        "Lihat yang melanggar? Pakai menu <b>Laporkan</b>.",
        "Password minimal 8 karakter: huruf besar dan kecil, angka, dan karakter khusus.",
        "Akun bisa dihapus kapan saja dari <b>Profil › Hapus akun</b>.",
    ]),
    ("Buku", "siswa", [
        "<b>Satu buku aktif</b> dalam satu waktu.",
        "Target selesai: akhir bulan saat buku dimulai.",
        "Perpanjang target <b>sekali</b>, sampai akhir bulan berikutnya, paling lama 31 hari.",
        "Jumlah halaman 10–2000, tidak bisa diubah setelah buku dimulai.",
        "Tandai selesai setelah jurnal mencapai halaman terakhir. Hentikan buku kapan saja.",
    ]),
    ("Jurnal", "siswa", [
        "<b>Satu jurnal untuk satu hari.</b>",
        "Untuk hari ini atau sampai 2 hari ke belakang, tidak sebelum buku dimulai.",
        "Informasi penting minimal 30 karakter. Tiap isian maksimal 1000 karakter.",
        "Bisa diubah atau dihapus sampai akhir hari berikutnya, lalu terkunci.",
        "Bisa disimpan tanpa sinyal, terkirim saat online.",
    ]),
    ("Status dan streak", "guru", [
        "<b>Aktif</b>: paling lama 3 hari efektif tanpa jurnal.",
        "<b>Perlu perhatian</b>: 4–7 hari. <b>Tidak aktif</b>: lebih dari 7 hari.",
        "<b>Belum ada buku</b>: belum memulai buku.",
        "Hari netral (bawaannya Minggu) dan hari libur sekolah tidak dihitung dan tidak memutus streak.",
        "Ambang status dan hari netral diatur penanggung jawab.",
    ]),
]

TIPS = [
    ("Sedikit, tapi setiap hari",
     "Jurnal singkat setiap hari lebih baik daripada jurnal panjang seminggu sekali. Streak-mu terus bertambah."),
    ("Tanpa sinyal tetap bisa",
     "Jurnal tersimpan di HP dan terkirim sendiri saat online. Memulai buku dan membuka katalog butuh internet."),
    ("Izinkan notifikasi",
     "Siswa diberi tahu saat guru mengomentari jurnalnya. Tidak ada notifikasi lain."),
    ("Rekomendasikan 10–20 buku",
     "Untuk penanggung jawab: buku rekomendasi tampil paling atas saat siswa mencari, jadi siswa cepat memilih."),
    ("Ganti HP? Masuk lagi",
     "Semua buku dan jurnal tersimpan di akun. Masuk dengan email yang sama di HP baru, datanya kembali."),
    ("Aman untuk semua",
     "Tanpa iklan, dan data tiap sekolah terpisah. Ikuti ketentuan di <b>sabusaku.web.app/ketentuan</b>. "
     "Ada yang melanggar? Pakai menu <b>Laporkan</b>."),
]

MISSIONS = {
    "siswa": [
        "Pasang Sabu Saku dan masuk dengan email sekolah",
        "Baca dan setujui ketentuan",
        "Lengkapi nama, kelas, dan ekskul",
        "Pasang foto profil",
        "Jelajahi katalog dan buka satu detail buku",
        "Mulai satu buku",
        "Isi jurnal hari ini, minimal 30 karakter",
        "Izinkan notifikasi komentar guru",
        "Baca komentar guru di jurnalmu",
        "Coba tema gelap dari Profil",
        "Isi jurnal 7 hari berturut-turut",
    ],
    "guru": [
        "Baca dan setujui ketentuan",
        "Buka Dashboard dan saring per ekskul",
        "Periksa label kelas dan ekskul di tab Sekolah",
        "Tambah satu siswa dengan email",
        "Impor beberapa siswa dari berkas CSV",
        "Ingatkan siswa yang belum masuk",
        "Buka detail siswa dan baca jurnalnya",
        "Tulis komentar pada jurnal siswa",
        "Rekomendasikan 10 buku di katalog",
        "Tinjau saran dari siswa",
        "Buka Sekolah › Laporan",
        "Periksa hari netral dan tambah hari libur",
    ],
}

# One month in Sabu Saku, shown under the rules.
FLOW = [
    ("Awal bulan", "Pilih buku dari katalog dan mulai membaca. Target: akhir bulan."),
    ("Setiap hari", "Isi jurnal: halaman, durasi, dan isi bacaan hari itu."),
    ("Guru menanggapi", "Penanggung jawab membaca jurnal dan memberi komentar."),
    ("Akhir bulan", "Sampai halaman terakhir? Tandai selesai. Belum? Perpanjang sekali."),
]

# Questions that come up often, on the help page.
FAQ = [
    ("Lupa mengisi jurnal kemarin?", "Buka Isi Jurnal lalu pilih <b>Kemarin</b> atau <b>2 hari lalu</b>."),
    ("Salah memilih buku?", "Buka <b>Buku Saya › Hentikan buku</b>, lalu mulai buku lain."),
    ("Jurnal belum terkirim?", "Jurnal tersimpan di HP dan terkirim sendiri saat ada sinyal."),
    ("Lupa password?", "Di layar masuk ketuk <b>Lupa password?</b>, atau pakai Masuk dengan Google."),
]

ARROW = ('<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" '
         'stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>')


def lcg(seed):
    """A tiny deterministic random source, so the shelf looks the same on every run."""
    state = seed

    def next_value():
        nonlocal state
        state = (state * 1103515245 + 12345) % 2147483648
        return state / 2147483648
    return next_value


SPROUT = ('<path d="M256 232 L256 154" fill="none" stroke="{stem}" stroke-width="12" stroke-linecap="round"/>'
          '<path d="M256 192 C228 194 204 176 198 148 C230 144 256 162 256 192 Z" fill="{left}"/>'
          '<path d="M256 154 C258 114 288 86 332 82 C334 124 304 156 256 154 Z" fill="{right}"/>')


def bookshelf(width, height, colors, shelf, shelf_h, low, high, sprout, seed=11):
    """A row of book spines standing on a shelf, with a sprout from the logo.

    `colors` is a list of (spine, band) pairs. The sprout grows from the
    shortest book near three quarters of the width."""
    rnd = lcg(seed)
    widths = (9, 10, 11, 12, 13, 15, 17)
    base = height - shelf_h
    books, x, last = [], 1.0, -1
    while x < width:
        w = widths[int(rnd() * len(widths))] * (high / 26) ** 0.5
        h = low + rnd() * (high - low)
        pick = int(rnd() * len(colors))
        if pick == last:
            pick = (pick + 1) % len(colors)
        last = pick
        books.append((x, w, h, colors[pick], rnd()))
        x += w + max(1.4, w * 0.13)
    target = width * 0.74
    near = [b for b in books if abs(b[0] - target) < width * 0.08]
    sprout_book = min(near, key=lambda b: b[2]) if near else None
    parts = []
    for x, w, h, (spine, band), r in books:
        top = base - h
        lean = r < 0.07 and h < high * 0.9
        group = f'<g transform="rotate(-9 {x + w:.1f} {base})">' if lean else "<g>"
        radius = min(2.2, w / 5)
        group += f'<rect x="{x:.1f}" y="{top:.1f}" width="{w:.1f}" height="{h + 1:.1f}" rx="{radius:.1f}" fill="{spine}"/>'
        stripe = max(1.2, h * 0.07)
        group += f'<rect x="{x:.1f}" y="{top + h * 0.16:.1f}" width="{w:.1f}" height="{stripe:.1f}" fill="{band}"/>'
        if r > 0.45:
            group += f'<rect x="{x:.1f}" y="{base - h * 0.2:.1f}" width="{w:.1f}" height="{stripe:.1f}" fill="{band}"/>'
        if r > 0.8 and h > high * 0.6:
            group += (f'<rect x="{x + w * 0.28:.1f}" y="{top + h * 0.36:.1f}" width="{w * 0.44:.1f}" '
                      f'height="{h * 0.26:.1f}" rx="{w * 0.12:.1f}" fill="{band}"/>')
        parts.append(group + "</g>")
    if sprout_book:
        x, w, h, _, _ = sprout_book
        size = high * 0.5 / 150
        left = x + w / 2 - 256 * size
        top = base - h - 232 * size + 1
        parts.append(f'<g transform="translate({left:.1f} {top:.1f}) scale({size:.4f})">'
                     + SPROUT.format(**sprout) + "</g>")
    parts.append(f'<rect x="0" y="{base:.1f}" width="{width}" height="{shelf_h}" fill="{shelf}"/>')
    return (f'<svg class="shelf" viewBox="0 0 {width} {height}" width="{width}" height="{height}" '
            f'preserveAspectRatio="xMinYMax slice" xmlns="http://www.w3.org/2000/svg">{"".join(parts)}</svg>')


LIGHT_BOOKS = [(NAVY, "#3C5C86"), (BLUE, "#6E98F2"), (BLUE_DARK, "#5F86DE"), ("#B9CEF6", "#E4EEFF"),
               (GREEN, "#7FD3A3"), (NAVY_DEEP, "#36507A"), (AMBER, "#FBDD9C"), ("#8FB0F0", "#C9DAFB")]
DARK_BOOKS = [(BLUE, "#6E98F2"), ("#9DB9E8", "#D3E1F8"), (GREEN_LIGHT, "#A8E8C2"), ("#2F6FD6", "#7FA6EC"),
              (SKY, "#FFFFFF"), (AMBER, "#FBDD9C"), ("#4C82E8", "#8FB0F0"), (GREEN, "#7FD3A3"), ("#C9DAFB", "#FFFFFF")]
SPROUT_LIGHT = {"stem": GREEN, "left": "#3CC07A", "right": GREEN}
SPROUT_DARK = {"stem": GREEN_LIGHT, "left": GREEN_LIGHT, "right": "#8BE0AE"}

SHELF = bookshelf(794, 34, LIGHT_BOOKS, NAVY, 4, 13, 25, SPROUT_LIGHT)
SHELF_COVER = bookshelf(794, 96, DARK_BOOKS, "#2F6FD6", 8, 38, 70, SPROUT_DARK, seed=5)


def divider_shelf():
    """The shelf in tints of white, for the coloured section openers."""
    tints = [("rgba(255,255,255,.9)", "rgba(255,255,255,.55)"), ("rgba(255,255,255,.45)", "rgba(255,255,255,.75)"),
             ("rgba(255,255,255,.7)", "rgba(255,255,255,.35)"), ("rgba(255,255,255,.3)", "rgba(255,255,255,.6)")]
    leaves = {"stem": "#FFFFFF", "left": "rgba(255,255,255,.85)", "right": "#FFFFFF"}
    return bookshelf(794, 34, tints, "rgba(255,255,255,.9)", 4, 13, 25, leaves)


def font_faces():
    weights = {400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold", 800: "ExtraBold"}
    return "".join(f'@font-face {{ font-family: Poppins; font-weight: {weight}; '
                   f'src: url("{(FONTS / f"Poppins-{name}.ttf").as_uri()}"); }}\n'
                   for weight, name in weights.items())


CSS = font_faces() + f"""
@page {{ size: 210mm 297mm; margin: 0; }}
* {{ box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
html, body {{ margin: 0; padding: 0; background: {BG}; }}
body {{ font: 400 13px/1.45 Poppins, sans-serif; color: {INK}; }}
a {{ color: inherit; text-decoration: none; }}
b {{ font-weight: 600; }}
.page {{ position: relative; width: 210mm; height: 297mm; overflow: hidden; background: {BG};
  page-break-after: always; break-after: page; padding: 60px 48px 0; }}
.page:last-child {{ page-break-after: auto; break-after: auto; }}
a.ref {{ color: {BLUE}; font-weight: 600; border-bottom: 1.5px solid #B8CDF8; }}

/* A row of book spines on a shelf along the top edge. */
.shelf {{ position: absolute; top: 0; left: 0; display: block; }}

.head {{ display: flex; align-items: center; gap: 10px; }}
.tab {{ display: inline-flex; align-items: center; gap: 8px; height: 26px; padding: 0 12px 0 4px; border-radius: 13px;
  background: var(--accent); color: var(--on); font: 600 10.5px/1 Poppins; letter-spacing: 1px; text-transform: uppercase; }}
.tab i {{ display: grid; place-items: center; min-width: 18px; height: 18px; padding: 0 3px; border-radius: 9px;
  background: var(--on); color: var(--accent); font: 700 10px/1 Poppins; font-style: normal; letter-spacing: 0; }}
.crumb {{ display: inline-flex; align-items: center; height: 26px; padding: 0 12px; border-radius: 13px; margin-left: auto;
  border: 1.5px solid {OUTLINE}; background: #fff; font: 500 10.5px/1 Poppins; color: {MUTED}; white-space: nowrap; }}
h1 {{ margin: 12px 0 0; font: 700 28px/1.15 Poppins; letter-spacing: -.6px; color: {NAVY}; }}
.intro {{ margin: 5px 0 0; max-width: 620px; font-size: 13.6px; line-height: 1.45; color: {MUTED}; }}

.pin {{ display: grid; place-items: center; flex: none; width: 24px; height: 24px; border-radius: 50%;
  background: {AMBER}; color: {INK}; font: 700 12px/1 Poppins; }}
/* Shadows have hard edges on purpose. Chrome prints a blurred shadow as a
   masked image, and the macOS PDF viewer draws those as grey boxes. */
.device {{ position: relative; background: {NAVY_DEEP}; box-shadow: 7px 9px 0 #DCE4F0; }}
.screen {{ position: relative; overflow: hidden; background: {BG}; aspect-ratio: {RAW_W} / {RAW_H - STATUS_BAR}; }}
.screen img {{ display: block; width: 100%; }}
.screen .pin {{ position: absolute; width: 25px; height: 25px; margin: -12.5px 0 0 -12.5px; font-size: 12.5px;
  box-shadow: 0 0 0 2.5px #fff, 0 0 0 4px {INK}; }}

.legend {{ list-style: none; margin: 12px 0 0; padding: 0 2px; display: grid; gap: 6px; }}
.legend li {{ display: flex; gap: 9px; align-items: flex-start; font-size: 12.4px; line-height: 1.42; }}
.legend .pin {{ width: 20px; height: 20px; font-size: 10.5px; margin-top: 0; }}

/* Two screenshots side by side. */
.duo {{ display: grid; grid-template-columns: 1fr 40px 1fr; margin-top: 18px; }}
.duo .col {{ width: 100%; }}
.duo .step {{ display: flex; align-items: center; gap: 8px; height: 26px; margin-bottom: 10px;
  font: 600 14px/1 Poppins; color: {NAVY}; }}
.duo .step i {{ display: grid; place-items: center; width: 24px; height: 24px; border-radius: 8px;
  background: var(--tint); color: var(--accent-text); font: 700 12px/1 Poppins; font-style: normal; }}
.duo .device {{ width: 290px; margin: 0 auto; padding: 8px; border-radius: 34px; }}
.duo .screen {{ border-radius: 26px; }}
.duo .next {{ display: grid; place-items: center; width: 32px; height: 32px; margin: 316px auto 0; border-radius: 50%;
  background: var(--accent); color: var(--on); }}

/* One screenshot with its notes next to it. */
.tour {{ display: grid; grid-template-columns: 356px 1fr; gap: 24px; margin-top: 20px; align-items: start; }}
.tour .device {{ width: 356px; padding: 9px; border-radius: 40px; }}
.tour .screen {{ border-radius: 31px; }}
.tour .legend {{ margin: 4px 0 0; gap: 7px; padding: 0; }}
.tour .legend li {{ padding: 9px 12px; border-radius: 13px; background: #fff; border: 1.5px solid {OUTLINE};
  font-size: 12.4px; line-height: 1.42; }}
.tour .legend .pin {{ width: 22px; height: 22px; font-size: 11.5px; }}

.note {{ margin-top: 10px; padding: 11px 14px 12px; border-radius: 14px; background: var(--tint); font-size: 12.2px; line-height: 1.42; }}
.note h3 {{ margin: 0 0 5px; font: 600 13px/1.3 Poppins; color: var(--accent-text); }}
.note ul, .note ol {{ margin: 0; padding: 0; list-style: none; display: grid; gap: 4px; }}
.note li {{ position: relative; padding-left: 14px; }}
.note ul li::before {{ content: ""; position: absolute; left: 2px; top: 7px; width: 5px; height: 5px; border-radius: 50%;
  background: var(--accent-text); }}
.note ol {{ counter-reset: step; }}
.note ol li {{ padding-left: 24px; counter-increment: step; }}
.note ol li::before {{ content: counter(step); position: absolute; left: 0; top: 1px; display: grid; place-items: center;
  width: 17px; height: 17px; border-radius: 6px; background: var(--accent); color: var(--on); font: 700 9.5px/1 Poppins; }}
.note.warn {{ background: #FDECEB; }}
.note.warn h3 {{ color: #A1241D; }}
.note.warn ul li::before {{ background: #A1241D; }}
.note.plain {{ background: #fff; border: 1.5px solid {OUTLINE}; }}
.note.accent {{ background: #FFF4D9; }}
.note.accent h3 {{ color: #7A4E00; }}
.note.accent ul li::before {{ background: {AMBER}; }}
.note.with-shot {{ display: grid; grid-template-columns: 92px 1fr; gap: 12px; align-items: center; }}
.note .mini {{ width: 92px; padding: 4px; border-radius: 15px; box-shadow: 4px 5px 0 #C9D6EA; }}
.note .mini .screen {{ border-radius: 11px; }}
.note li:has(.chip) {{ padding-left: 0; }}
.note li:has(.chip)::before {{ display: none; }}
.chip {{ display: inline-block; margin-right: 4px; padding: 1px 8px; border-radius: 10px; font: 600 11px/1.5 Poppins; }}
.chip.ok {{ background: #E3F5EA; color: #1B6B40; }}
.chip.warn {{ background: #FFF1CC; color: #7A4E00; }}
.chip.bad {{ background: #FDE7E6; color: #A1241D; }}
.chip.none {{ background: #ECEFF4; color: #465163; }}

.tip {{ display: flex; gap: 10px; align-items: flex-start; margin-top: 12px; padding: 10px 14px; border-radius: 14px;
  background: #FFF4D9; font-size: 12.4px; line-height: 1.42; }}
.tip em {{ flex: none; font: 700 10px/1 Poppins; font-style: normal; letter-spacing: .8px; text-transform: uppercase;
  padding: 5px 8px; border-radius: 8px; background: {AMBER}; color: {INK}; margin-top: 1px; }}
.page .tip.low {{ position: absolute; left: 48px; right: 48px; bottom: 56px; margin: 0; }}

.foot {{ position: absolute; left: 48px; right: 48px; bottom: 18px; height: 26px; display: flex; align-items: center;
  justify-content: space-between; font: 500 10.5px/1 Poppins; color: #8592A6; }}
.foot .mark {{ display: flex; align-items: center; gap: 6px; font: 700 13px/1 Poppins; letter-spacing: -.2px; color: {NAVY}; }}
.foot .mark img {{ width: 22px; height: 22px; }}
.foot .mark span {{ margin-left: 4px; font: 500 10.5px/1 Poppins; letter-spacing: 0; color: #8592A6; }}
.foot .home {{ padding: 6px 12px; border-radius: 12px; border: 1.5px solid {OUTLINE}; background: #fff; color: {MUTED}; }}
.foot .num {{ display: grid; place-items: center; min-width: 26px; height: 26px; padding: 0 6px; border-radius: 13px;
  background: {NAVY}; color: #fff; font: 600 11px/1 Poppins; }}

/* Cover */
.cover {{ background: {NAVY}; color: #fff; padding: 0; }}
.cover .glow {{ position: absolute; border-radius: 50%; }}
.cover .logo {{ position: absolute; left: 52px; top: 64px; width: 300px; }}
.cover .kicker {{ position: absolute; left: 60px; top: 262px; font: 600 12px/1 Poppins; letter-spacing: 2.6px;
  text-transform: uppercase; color: {GREEN_LIGHT}; }}
.cover h1 {{ position: absolute; left: 57px; top: 286px; width: 420px; margin: 0; font: 800 58px/1.04 Poppins;
  letter-spacing: -2px; color: #fff; }}
.cover h1 span {{ color: {GREEN_LIGHT}; }}
.cover .school {{ position: absolute; left: 60px; top: 432px; display: inline-flex; align-items: center; gap: 9px;
  padding: 8px 14px 8px 10px; border-radius: 14px; background: #22446F; border: 1.5px solid #34598A;
  font: 600 14px/1.2 Poppins; }}
.cover .school svg {{ flex: none; }}
.cover .sub {{ position: absolute; left: 60px; top: 490px; width: 330px; font: 400 14.5px/1.5 Poppins; color: #C9D7EC; }}
.cover .roles {{ position: absolute; left: 60px; top: 590px; display: grid; gap: 9px; }}
.cover .roles a {{ display: flex; align-items: center; gap: 12px; width: 318px; padding: 10px 14px 10px 10px; border-radius: 16px;
  background: #1F4069; border: 1.5px solid #2E5585; font: 600 14px/1.2 Poppins; }}
.cover .roles i {{ display: grid; place-items: center; width: 34px; height: 34px; border-radius: 11px; font: 700 14px/1 Poppins;
  font-style: normal; }}
.cover .roles small {{ display: block; margin-top: 2px; font: 400 11.2px/1.25 Poppins; color: #AFC2DE; }}
.cover .roles .go {{ margin-left: auto; color: {GREEN_LIGHT}; display: grid; }}
.cover .stage {{ position: absolute; left: 446px; top: 190px; transform: rotate(5deg); }}
.cover .device {{ width: 304px; padding: 10px; border-radius: 40px; background: #0A1B33; box-shadow: 13px 15px 0 #0D2342; }}
.cover .screen {{ border-radius: 30px; }}
.cover .badge {{ position: absolute; display: flex; align-items: center; gap: 9px; padding: 9px 14px 9px 9px; border-radius: 15px;
  background: #fff; color: {NAVY}; font: 600 13px/1.2 Poppins; box-shadow: 5px 6px 0 #0D2342; }}
.cover .badge i {{ display: grid; place-items: center; width: 28px; height: 28px; border-radius: 9px; font-style: normal; }}
.cover .ver {{ position: absolute; left: 60px; bottom: 116px; font: 500 11.5px/1 Poppins; color: #9FB3D1; }}
.cover .shelf {{ top: auto; bottom: 0; }}

/* Contents */
.toc {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px 18px; margin-top: 16px; align-items: start; }}
.toc .column {{ display: grid; gap: 14px; }}
.toc section {{ padding: 13px 16px 10px; border-radius: 18px; background: #fff; border: 1.5px solid {OUTLINE}; }}
.toc h2 {{ display: flex; align-items: center; gap: 9px; margin: 0 0 6px; font: 600 15.5px/1 Poppins; color: {NAVY}; }}
.toc h2 i {{ width: 12px; height: 12px; border-radius: 4px; background: var(--accent); }}
.toc h2 a {{ margin-left: auto; font: 500 10.5px/1 Poppins; color: var(--accent-text); }}
.toc a.row {{ display: flex; align-items: baseline; gap: 8px; padding: 3.6px 0; font-size: 12.4px; line-height: 1.25; }}
.toc a.row u {{ flex: 1; border-bottom: 1.5px dotted #C3CEDD; transform: translateY(-3px); text-decoration: none; }}
.toc a.row b {{ font: 600 11.5px/1 Poppins; color: var(--accent-text); }}
.how {{ display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; margin-top: 14px; padding: 12px 16px; border-radius: 18px;
  background: #E8EEF7; }}
.how div {{ display: flex; gap: 9px; align-items: center; font-size: 11.6px; line-height: 1.35; }}
.how .box {{ flex: none; width: 18px; height: 18px; border-radius: 5px; border: 2px solid {NAVY}; background: #fff; }}
.how .link {{ flex: none; display: grid; place-items: center; width: 24px; height: 24px; border-radius: 8px; background: {BLUE}; color: #fff; }}

.quick {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px 18px; margin-top: 14px; }}
.quick section {{ padding: 13px 16px 14px; border-radius: 18px; background: var(--tint); }}
.quick h2 {{ margin: 0 0 9px; font: 600 13px/1.2 Poppins; color: var(--accent-text); }}
.quick .path {{ display: flex; flex-wrap: wrap; gap: 6px; }}
.quick .path a {{ display: inline-flex; align-items: center; gap: 6px; padding: 5px 10px 5px 5px; border-radius: 10px;
  background: #fff; font: 500 11.4px/1.2 Poppins; }}
.quick .path a b {{ display: grid; place-items: center; min-width: 20px; height: 20px; padding: 0 4px; border-radius: 7px;
  background: var(--accent); color: var(--on); font: 600 10.5px/1 Poppins; }}

/* Section opener */
.divider {{ background: var(--accent); color: var(--on); padding: 0; }}
.divider .big {{ position: absolute; left: 52px; top: 82px; font: 800 150px/1 Poppins; letter-spacing: -8px;
  color: color-mix(in srgb, var(--on) 18%, var(--accent)); }}
.divider .label {{ position: absolute; left: 60px; top: 262px; font: 600 12px/1 Poppins; letter-spacing: 2.6px; text-transform: uppercase;
  color: color-mix(in srgb, var(--on) 78%, var(--accent)); }}
.divider h1 {{ position: absolute; left: 57px; top: 284px; width: 380px; margin: 0; font: 700 50px/1.06 Poppins; letter-spacing: -1.6px;
  color: var(--on); }}
.divider .sub {{ position: absolute; left: 60px; width: 330px; font: 400 14.5px/1.5 Poppins;
  color: color-mix(in srgb, var(--on) 90%, var(--accent)); }}
.divider .list {{ position: absolute; left: 60px; width: 336px; display: grid; }}
.divider .list a {{ display: flex; justify-content: space-between; gap: 10px; padding: 5px 0; font: 500 12.6px/1.25 Poppins;
  border-bottom: 1px solid color-mix(in srgb, var(--on) 26%, var(--accent)); }}
.divider .list a b {{ font-weight: 700; }}
.divider .stage {{ position: absolute; left: 456px; top: 190px; transform: rotate(4deg); }}
.divider .device {{ width: 300px; padding: 9px; border-radius: 38px; background: {NAVY_DEEP};
  box-shadow: 12px 14px 0 color-mix(in srgb, var(--accent) 72%, #000); }}
.divider .screen {{ border-radius: 29px; }}
.divider .foot, .divider .foot .mark, .divider .foot .mark span {{ color: var(--on); }}
.divider .foot .home {{ background: transparent; color: var(--on); border-color: color-mix(in srgb, var(--on) 45%, var(--accent)); }}
.divider .foot .num {{ background: var(--on); color: var(--accent); }}

/* Install */
.install {{ display: grid; grid-template-columns: 1fr 280px; gap: 28px; margin-top: 22px; align-items: start; }}
.play {{ padding: 22px; border-radius: 24px; background: {NAVY}; color: #fff; }}
.play .qr {{ display: grid; grid-template-columns: 158px 1fr; gap: 20px; align-items: center; }}
.play .code {{ padding: 13px; border-radius: 18px; background: #fff; }}
.play .code img {{ display: block; width: 132px; height: 132px; }}
.play h2 {{ margin: 0 0 6px; font: 700 19px/1.2 Poppins; }}
.play p {{ margin: 0; font-size: 12.6px; line-height: 1.45; color: #C9D7EC; }}
.play .url {{ display: block; margin-top: 16px; padding: 10px 13px; border-radius: 12px; background: #22446F;
  font: 500 11.3px/1.35 Poppins; color: #fff; }}
.play .url b {{ display: block; margin-bottom: 2px; font: 600 10px/1.2 Poppins; letter-spacing: 1.4px; text-transform: uppercase; color: {GREEN_LIGHT}; }}
.steps {{ list-style: none; margin: 18px 0 0; padding: 0; display: grid; gap: 9px; counter-reset: step; }}
.steps li {{ position: relative; padding: 11px 14px 11px 48px; border-radius: 14px; background: #fff; border: 1.5px solid {OUTLINE};
  font-size: 12.8px; line-height: 1.42; counter-increment: step; }}
.steps li::before {{ content: counter(step); position: absolute; left: 13px; top: 10px; display: grid; place-items: center;
  width: 24px; height: 24px; border-radius: 8px; background: {NAVY}; color: #fff; font: 700 12px/1 Poppins; }}
.install .phone .device {{ width: 280px; padding: 8px; border-radius: 34px; }}
.install .phone .screen {{ border-radius: 26px; }}
.install .phone p {{ margin: 12px 4px 0; font-size: 12.2px; line-height: 1.42; color: {MUTED}; }}
.need {{ margin-top: 22px; }}
.need h2 {{ margin: 0 0 10px; font: 600 16px/1.2 Poppins; color: {NAVY}; }}
.need > div {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }}
.need article {{ padding: 14px 16px; border-radius: 16px; background: var(--tint); }}
.need i {{ display: grid; place-items: center; width: 36px; height: 36px; border-radius: 11px; background: {NAVY}; color: #fff; }}
.need p {{ margin: 10px 0 0; font-size: 12.4px; line-height: 1.45; }}

/* Rules */
.rules {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 20px; }}
.rules article {{ padding: 16px 18px 16px; border-radius: 20px; background: #fff; border: 1.5px solid {OUTLINE}; }}
.rules h2 {{ display: flex; align-items: center; gap: 10px; margin: 0 0 10px; font: 600 17px/1.2 Poppins; color: {NAVY}; }}
.rules h2 i {{ display: grid; place-items: center; width: 30px; height: 30px; border-radius: 10px; font-style: normal;
  background: var(--accent); color: var(--on); }}
.rules ul {{ margin: 0; padding: 0; list-style: none; display: grid; gap: 8px; }}
.rules li {{ position: relative; padding-left: 18px; font-size: 12.6px; line-height: 1.45; }}
.rules li::before {{ content: ""; position: absolute; left: 2px; top: 6px; width: 8px; height: 8px; border-radius: 3px;
  background: var(--tint); border: 1.5px solid var(--accent-text); }}

.flow {{ margin-top: 14px; padding: 16px 18px 18px; border-radius: 20px; background: {NAVY}; color: #fff; }}
.flow h2 {{ margin: 0 0 12px; font: 600 17px/1.2 Poppins; }}
.flow ol {{ margin: 0; padding: 0; list-style: none; display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }}
.flow li {{ position: relative; padding: 12px 12px 13px; border-radius: 14px; background: #22446F; }}
.flow li i {{ display: grid; place-items: center; width: 26px; height: 26px; border-radius: 9px; font: 700 12px/1 Poppins; font-style: normal; }}
.flow h3 {{ margin: 9px 0 3px; font: 600 13.4px/1.25 Poppins; }}
.flow p {{ margin: 0; font-size: 11.6px; line-height: 1.45; color: #C9D7EC; }}

/* Tips */
.cards {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 22px; }}
.cards article {{ position: relative; padding: 20px 22px; border-radius: 20px; background: #fff; border: 1.5px solid {OUTLINE}; min-height: 214px; }}
.cards article i {{ display: grid; place-items: center; width: 38px; height: 38px; border-radius: 12px; font: 700 17px/1 Poppins;
  font-style: normal; }}
.cards h3 {{ margin: 14px 0 6px; font: 600 18px/1.2 Poppins; letter-spacing: -.2px; color: {NAVY}; }}
.cards p {{ margin: 0; font-size: 13.8px; line-height: 1.55; color: #46556B; }}
.more {{ display: flex; align-items: center; justify-content: space-between; gap: 20px; margin-top: 16px; padding: 16px 20px;
  border-radius: 20px; background: {NAVY}; color: #fff; }}
.more h3 {{ margin: 0 0 3px; font: 600 16px/1.2 Poppins; }}
.more p {{ margin: 0; font-size: 12.6px; color: #C9D7EC; }}
.more a {{ flex: none; padding: 11px 16px; border-radius: 14px; background: {AMBER}; color: {INK}; font: 600 13px/1 Poppins; }}

/* Missions */
.missions {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 20px; }}
.missions section {{ padding: 16px 18px 12px; border-radius: 20px; background: #fff; border: 1.5px solid {OUTLINE}; }}
.missions h2 {{ display: flex; align-items: center; justify-content: space-between; margin: 0 0 8px; font: 600 17px/1 Poppins; color: {NAVY}; }}
.missions h2 span {{ padding: 5px 9px; border-radius: 9px; background: var(--accent); color: var(--on); font: 600 10px/1 Poppins; letter-spacing: .8px; }}
.missions label {{ display: flex; gap: 11px; align-items: flex-start; padding: 10px 0; font-size: 13.4px; line-height: 1.4;
  border-top: 1px solid #EDF1F6; }}
.missions label:first-of-type {{ border-top: 0; }}
.missions .box {{ flex: none; width: 19px; height: 19px; margin-top: 0; border-radius: 6px; border: 2px solid var(--accent-text); background: #fff; }}
.month {{ margin-top: 14px; padding: 14px 18px 16px; border-radius: 20px; background: #fff; border: 1.5px solid {OUTLINE}; }}
.month h3 {{ margin: 0; font: 600 15px/1.2 Poppins; color: {NAVY}; }}
.month p {{ margin: 2px 0 10px; font-size: 12px; color: {MUTED}; }}
.month .days {{ display: grid; grid-template-columns: repeat(16, 1fr); gap: 6px; }}
.month .days span {{ display: grid; place-items: end start; height: 32px; padding: 3px 5px; border-radius: 8px;
  border: 1.5px solid #B9C8DE; font: 600 9.5px/1 Poppins; color: #8592A6; }}
.done {{ margin-top: 14px; padding: 16px 20px; border-radius: 20px; background: {AMBER}; color: {INK}; }}
.done h3 {{ margin: 0 0 3px; font: 600 17px/1.2 Poppins; }}
.done p {{ margin: 0; font-size: 12.8px; line-height: 1.45; }}

/* Help */
.help {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 20px; }}
.help article {{ padding: 18px 20px; border-radius: 20px; background: #fff; border: 1.5px solid {OUTLINE}; }}
.help article.wide {{ grid-column: span 2; }}
.help h2 {{ margin: 12px 0 6px; font: 600 17px/1.2 Poppins; color: {NAVY}; }}
.help p {{ margin: 0; font-size: 12.8px; line-height: 1.5; color: #46556B; }}
.help .icon {{ display: grid; place-items: center; width: 38px; height: 38px; border-radius: 12px; }}
.help .button {{ display: inline-flex; align-items: center; gap: 8px; margin-top: 12px; padding: 10px 14px; border-radius: 12px;
  background: {BLUE}; color: #fff; font: 600 12.6px/1 Poppins; }}
.help .button.light {{ background: {SKY}; color: {BLUE_DARK}; }}
.help ul {{ margin: 8px 0 0; padding: 0; list-style: none; display: grid; gap: 6px; }}
.help li {{ position: relative; padding-left: 16px; font-size: 12.6px; line-height: 1.45; color: #46556B; }}
.help li::before {{ content: ""; position: absolute; left: 2px; top: 7px; width: 6px; height: 6px; border-radius: 50%; background: {GREEN}; }}
.help .faq h2 {{ margin: 0 0 10px; }}
.help dl {{ margin: 0; display: grid; grid-template-columns: 1fr 1fr; gap: 10px 22px; }}
.help dl div {{ padding: 10px 12px; border-radius: 12px; background: {BG}; }}
.help dt {{ font: 600 12.8px/1.3 Poppins; color: {NAVY}; }}
.help dd {{ margin: 3px 0 0; font-size: 12.2px; line-height: 1.42; color: #46556B; }}
.help .share {{ display: grid; grid-template-columns: 112px 1fr; gap: 18px; align-items: center; }}
.help .share .code {{ padding: 10px; border-radius: 14px; border: 1.5px solid {OUTLINE}; }}
.help .share img {{ display: block; width: 90px; height: 90px; }}
.help .share h2 {{ margin-top: 0; }}
.help .links {{ display: flex; flex-wrap: wrap; gap: 8px; }}
.thanks {{ display: flex; align-items: center; gap: 18px; margin-top: 14px; padding: 18px 22px; border-radius: 20px; background: {NAVY}; color: #fff; }}
.thanks img {{ width: 64px; height: 64px; flex: none; }}
.thanks h3 {{ margin: 0 0 3px; font: 600 17px/1.2 Poppins; }}
.thanks p {{ margin: 0; font-size: 12.8px; line-height: 1.45; color: #C9D7EC; }}
"""


def role_style(role):
    _, accent, on, tint, accent_text = ROLES[role]
    return f"--accent:{accent};--on:{on};--tint:{tint};--accent-text:{accent_text}"


def link_refs(text, keys):
    """Turns [[key]] into a link to that page."""
    def replace(match):
        number = keys[match.group(1)]
        return f'<a class="ref" href="#p{number}">halaman {number}</a>'
    return re.sub(r"\[\[([\w-]+)\]\]", replace, text)


def device(item, pins=True, cls="device"):
    marks = ""
    if pins:
        for number, (x, y, _) in enumerate(item["pins"], start=1):
            left = x / PREVIEW_W * 100
            top = (y / PREVIEW_H * RAW_H - STATUS_BAR) / (RAW_H - STATUS_BAR) * 100
            marks += f'<span class="pin" style="left:{left:.2f}%;top:{top:.2f}%">{number}</span>'
    source = (SHOTS / f"{item['name']}.jpg").as_uri()
    return f'<div class="{cls}"><div class="screen"><img src="{source}">{marks}</div></div>'


def legend(item, keys):
    rows = "".join(f'<li><span class="pin">{number}</span><span>{link_refs(text, keys)}</span></li>'
                   for number, (_, _, text) in enumerate(item["pins"], start=1))
    return f'<ol class="legend">{rows}</ol>'


def render_notes(spec, keys):
    out = ""
    for item in spec["notes"]:
        tag = "ol" if item["ordered"] else "ul"
        rows = "".join(f"<li>{link_refs(text, keys)}</li>" for text in item["items"])
        body = f"<h3>{item['title']}</h3><{tag}>{rows}</{tag}>"
        if item["shot"]:
            mini = device({"name": item["shot"], "pins": ()}, pins=False, cls="device mini")
            out += f'<div class="note with-shot {item["tone"]}">{mini}<div>{body}</div></div>'
        else:
            out += f'<div class="note {item["tone"]}">{body}</div>'
    return out


def header(spec, number):
    label = ROLES[spec["role"]][0]
    crumb = f'<span class="crumb">{html.escape(spec["path"])}</span>' if spec["path"] else ""
    return f"""<div class="head"><span class="tab"><i>{number}</i>{label}</span>{crumb}</div>
<h1>{spec['title']}</h1><p class="intro">{spec['intro']}</p>"""


def footer(number, dark=False):
    mark = (BRAND / ("logo-mark-reversed.svg" if dark else "logo-mark.svg")).as_uri()
    return f"""<div class="foot"><span class="mark"><img src="{mark}">Sabu Saku<span>Buku panduan</span></span>
<a class="home" href="#isi">Daftar isi</a><span class="num">{number}</span></div>"""


def tip(spec, keys, low=False):
    if not spec["tip"]:
        return ""
    return f'<div class="tip{" low" if low else ""}"><em>Tips</em><span>{link_refs(spec["tip"], keys)}</span></div>'


def render_duo(spec, number, keys):
    first, second = spec["shots"]
    columns = ""
    for index, item in enumerate((first, second), start=1):
        columns += f"""<div class="col"><div class="step"><i>{index}</i>{item['step']}</div>
{device(item)}{legend(item, keys)}</div>"""
        if index == 1:
            columns += f'<div class="next">{ARROW}</div>'
    return f"""{header(spec, number)}<div class="duo">{columns}</div>{tip(spec, keys, low=True)}"""


def render_tour(spec, number, keys):
    item = spec["shots"][0]
    return f"""{header(spec, number)}<div class="tour">{device(item)}<div>{legend(item, keys)}
{render_notes(spec, keys)}{tip(spec, keys)}</div></div>"""


def section_pages(pages, role):
    return [(number, spec) for number, spec in pages if spec["role"] == role and spec["kind"] != "divider"]


def render_divider(spec, number, pages):
    order = ("siswa", "guru").index(spec["role"]) + 1
    entries = section_pages(pages, spec["role"])
    links = "".join(f'<a href="#p{n}"><span>{s["toc"]}</span><b>{n}</b></a>' for n, s in entries)
    # Longer titles wrap to two lines; the text below moves down with them.
    lines = 2 if len(spec["title"]) > 12 else 1
    sub_top = 284 + lines * 53 + 22
    list_top = sub_top + 104
    return f"""{divider_shelf()}<div class="big">0{order}</div><div class="label">Bagian {order}</div>
<h1>{spec['title']}</h1><p class="sub" style="top:{sub_top}px">{spec['intro']}</p>
<div class="list" style="top:{list_top}px">{links}</div>
<div class="stage">{device(spec['shots'][0], pins=False)}</div>"""


SCHOOL_ICON = ('<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#5CD08A" stroke-width="2" '
               'stroke-linejoin="round"><path d="M2 9.5 12 4l10 5.5-10 5.5z"/><path d="M6 12v5c3.5 2.6 8.5 2.6 12 0v-5"/></svg>')
COMMENT = ('<svg viewBox="0 0 24 24" width="17" height="17" fill="#2563EB"><path d="M4 4h16v12H7l-3 3z"/></svg>')


def render_cover(pages):
    logo = (BRAND / "logo-horizontal-reversed.svg").as_uri()
    openers = {s["role"]: n for n, s in pages if s["kind"] == "divider"}
    firsts = {role: section_pages(pages, role)[0][0] for role in ("mulai", "semua")}
    targets = {**firsts, **openers}
    notes = {"mulai": "Pasang, masuk, dan lengkapi akun", "siswa": "Pilih buku, isi jurnal, baca komentar",
             "guru": "Pantau siswa, komentar, katalog", "semua": "Aturan, tips, kartu misi, bantuan"}
    roles = ""
    for role in SECTIONS:
        label, accent, on, _, _ = ROLES[role]
        icon_bg, icon_fg = ("#FFFFFF", NAVY) if role == "mulai" else (accent, on)
        roles += f"""<a href="#p{targets[role]}"><i style="background:{icon_bg};color:{icon_fg}">{label[0]}</i>
<span>{label}<small>{notes[role]}</small></span><span class="go">{ARROW}</span></a>"""
    return f"""<div class="page cover">
<div class="glow" style="left:430px;top:-160px;width:560px;height:560px;background:#1C3E69"></div>
<div class="glow" style="left:-220px;top:760px;width:520px;height:520px;background:#14315A"></div>
<img class="logo" src="{logo}">
<div class="kicker">Buku panduan</div><h1>Cara pakai <span>Sabu Saku</span></h1>
<div class="school">{SCHOOL_ICON}Untuk {SCHOOL}</div>
<p class="sub">Panduan bergambar untuk siswa dan penanggung jawab. Ikuti nomor kuning pada tiap gambar.</p>
<div class="roles">{roles}</div>
<div class="stage">{device({'name': 'siswa-beranda-komentar', 'pins': ()}, pins=False)}
<div class="badge" style="left:-64px;top:478px;transform:rotate(-7deg)"><i style="background:{SKY}">{COMMENT}</i>Komentar baru dari guru</div>
</div>
<div class="ver">Untuk aplikasi Sabu Saku versi {APP_VERSION}</div>{SHELF_COVER}</div>"""


# The first pages to read, by role, on the contents page.
QUICK = {"siswa": ["pasang", "google", "lengkapi", "mulai-buku", "jurnal"],
         "guru": ["google", "dashboard", "tambah-siswa", "detail-buku", "jurnal-guru"]}


def quick_path(pages, role, title, keys):
    numbers = {spec["key"]: (number, spec) for number, spec in pages if spec["key"]}
    steps = "".join(f'<a href="#p{numbers[key][0]}"><b>{numbers[key][0]}</b>{numbers[key][1]["toc"].split(",")[0]}</a>'
                    for key in keys)
    return f"""<section style="{role_style(role)}"><h2>Jalur cepat: {title}</h2><div class="path">{steps}</div></section>"""


def render_toc(pages):
    def block(role, title):
        rows = "".join(f'<a class="row" href="#p{n}"><span>{s["toc"]}</span><u></u><b>{n}</b></a>'
                       for n, s in section_pages(pages, role))
        opener = next((n for n, s in pages if s["role"] == role and s["kind"] == "divider"), None)
        start = f'<a href="#p{opener}">Pembuka</a>' if opener else ""
        return f"""<section style="{role_style(role)}"><h2><i></i>{title}{start}</h2>{rows}</section>"""
    left = block("mulai", "Mulai dari sini") + block("siswa", "Siswa")
    right = block("guru", "Penanggung jawab") + block("semua", "Untuk semua")
    link_icon = ('<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.4" '
                 'stroke-linecap="round"><path d="M10 14a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/>'
                 '<path d="M14 10a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/></svg>')
    return f"""<div class="page" id="isi" style="{role_style('mulai')}">{SHELF}
<div class="head"><span class="tab"><i>2</i>Daftar isi</span></div>
<h1>Mau belajar yang mana?</h1>
<p class="intro">Ketuk judul untuk langsung ke halamannya. Tombol <b>Daftar isi</b> di bawah tiap halaman membawamu kembali ke sini.</p>
<div class="how"><div><span class="pin">1</span><span>Nomor kuning di gambar cocok dengan nomor di penjelasannya.</span></div>
<div><span class="link">{link_icon}</span><span>Tulisan biru seperti <a class="ref" href="#isi">halaman 2</a> bisa diketuk.</span></div>
<div><span class="box"></span><span>Kotak di Kartu misi untuk dicentang setelah mencoba.</span></div></div>
<div class="toc"><div class="column">{left}</div><div class="column">{right}</div></div>
<div class="quick">{quick_path(pages, 'siswa', 'Siswa baru', QUICK['siswa'])}{quick_path(pages, 'guru', 'Penanggung jawab baru', QUICK['guru'])}</div>
{footer(2)}</div>"""


NEED_ICONS = [
    '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">'
    '<rect x="6" y="2.5" width="12" height="19" rx="2.5"/><path d="M10.5 18.5h3"/></svg>',
    '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="m4 7 8 6 8-6"/></svg>',
    '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<path d="M2 9.5 12 4l10 5.5-10 5.5z"/><path d="M6 12v5c3.5 2.6 8.5 2.6 12 0v-5"/></svg>',
]


def render_install(spec, number, keys):
    qr = (ASSETS / "qr-play.svg").as_uri()
    return f"""{header(spec, number)}<div class="install"><div>
<div class="play"><div class="qr"><div class="code"><img src="{qr}"></div><div>
<h2>Pindai untuk memasang</h2><p>Arahkan kamera HP ke kode ini. Google Play terbuka langsung di halaman Sabu Saku.</p></div></div>
<a class="url" href="{PLAY_URL}"><b>Atau buka tautan</b>{PLAY_URL.replace('https://', '').replace('apps/', 'apps/<wbr>')}</a></div>
<ol class="steps">
<li>Pindai kode, atau buka <b>Google Play</b> dan cari <b>Sabu Saku: Jurnal Membaca</b>.</li>
<li>Ketuk <b>Instal</b>, tunggu sampai selesai.</li>
<li>Ketuk <b>Buka</b>. Layar masuk muncul.</li>
<li>Masuk dengan email yang didaftarkan sekolah, lihat {link_refs('[[google]]', keys)}.</li></ol>
</div>
<div class="phone">{device(spec['shots'][0], pins=False)}<p>Setelah dibuka: layar masuk. Pilih Google atau email.</p></div></div>
<div class="need"><h2>Yang perlu disiapkan</h2><div>
<article><i>{NEED_ICONS[0]}</i><p><b>HP Android</b> dan koneksi internet.</p></article>
<article><i>{NEED_ICONS[1]}</i><p>Email yang sudah <b>didaftarkan sekolah</b>. Siswa didaftarkan oleh penanggung jawab Sabu Saku.</p></article>
<article><i>{NEED_ICONS[2]}</i><p><b>Penanggung jawab</b> didaftarkan oleh pengembang Sabu Saku.</p></article></div></div>
{tip(spec, keys, low=True)}"""


RULE_ICONS = {
    "Akun dan ketentuan": '<circle cx="12" cy="8" r="4"/><path d="M4 21c.8-4.2 3.9-6.5 8-6.5s7.2 2.3 8 6.5"/>',
    "Buku": '<path d="M12 6.5C9.8 4.8 6.5 4.3 3 5v13c3.5-.7 6.8-.2 9 1.5 2.2-1.7 5.5-2.2 9-1.5V5c-3.5-.7-6.8-.2-9 1.5z"/>'
            '<path d="M12 6.5v13"/>',
    "Jurnal": '<path d="M4 6h11M4 11h11M4 16h6"/><path d="m14 19 6-6 2 2-6 6h-2z"/>',
    "Status dan streak": '<path d="M5 20V12M12 20V5M19 20v-9"/>',
}


def render_rules(spec, number, keys):
    icons = {key: f'<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" '
                  f'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">{path}</svg>'
             for key, path in RULE_ICONS.items()}
    cards = ""
    for title, role, items in RULES:
        rows = "".join(f"<li>{text}</li>" for text in items)
        cards += f"""<article style="{role_style(role)}"><h2><i>{icons[title]}</i>{title}</h2><ul>{rows}</ul></article>"""
    colors = [(BLUE, "#fff"), (BLUE_DARK, "#fff"), (GREEN_DEEP, "#fff"), (AMBER, INK)]
    steps = "".join(f'<li><i style="background:{bg};color:{fg}">{index}</i><h3>{title}</h3><p>{text}</p></li>'
                    for index, ((title, text), (bg, fg)) in enumerate(zip(FLOW, colors), start=1))
    return f"""{header(spec, number)}<div class="rules">{cards}</div>
<div class="flow"><h2>Satu bulan, satu buku</h2><ol>{steps}</ol></div>"""


def render_tips(spec, number, keys):
    palette = [(BLUE, "#fff"), (GREEN_DEEP, "#fff"), (AMBER, INK)]
    cards = ""
    for index, (title, body) in enumerate(TIPS):
        background, text = palette[index % 3]
        cards += f"""<article><i style="background:{background};color:{text}">{index + 1}</i>
<h3>{title}</h3><p>{body}</p></article>"""
    return f"""{header(spec, number)}<div class="cards">{cards}</div>
<div class="more"><div><h3>Masih bingung?</h3><p>Tanya penanggung jawab di sekolah, atau lihat halaman Bantuan.</p></div>
<a href="#p{keys['bantuan']}">Buka Bantuan</a></div>"""


def render_missions(spec, number, keys):
    blocks = ""
    for role in ("siswa", "guru"):
        rows = "".join(f'<label><span class="box"></span><span>{text}</span></label>' for text in MISSIONS[role])
        blocks += f"""<section style="{role_style(role)}">
<h2>{ROLES[role][0]}<span>{len(MISSIONS[role])} MISI</span></h2>{rows}</section>"""
    days = "".join(f"<span>{day}</span>" for day in range(1, 32))
    return f"""{header(spec, number)}<div class="missions">{blocks}</div>
<div class="month"><h3>Pelacak satu bulan</h3><p>Centang setiap hari kamu menulis jurnal. Hari netral boleh dilewati.</p>
<div class="days">{days}</div></div>
<div class="done"><h3>Semua tercentang? Hebat!</h3>
<p>Sabu Saku siap menemani satu buku setiap bulan. Ceritakan pengalamanmu ke penanggung jawab atau ke <b>{HELP_EMAIL}</b>.</p></div>"""


def render_help(spec, number, keys):
    qr = (ASSETS / "qr-play.svg").as_uri()
    mark = (BRAND / "logo-mark-reversed.svg").as_uri()
    people = ('<svg viewBox="0 0 24 24" width="20" height="20" fill="#1B6B40"><circle cx="9" cy="8" r="3.4"/>'
              '<path d="M2.5 19c.6-3.6 3.2-5.6 6.5-5.6s5.9 2 6.5 5.6z"/><circle cx="17" cy="9" r="2.6"/>'
              '<path d="M16.2 13.6c2.7-.2 4.8 1.5 5.3 4.4h-4.3c-.2-1.7-.6-3.1-1-4.4z"/></svg>')
    mail = ('<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#1D4FC4" stroke-width="2.2" '
            'stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="3"/><path d="m4 7 8 6 8-6"/></svg>')
    faq = "".join(f"<div><dt>{q}</dt><dd>{a}</dd></div>" for q, a in FAQ)
    return f"""{header(spec, number)}<div class="help">
<article><span class="icon" style="background:#E1F4E8">{people}</span><h2>Akun dan data siswa</h2>
<p>Hubungi <b>penanggung jawab Sabu Saku</b> di sekolah untuk:</p>
<ul><li>email belum terdaftar, atau ingin memakai email lain;</li><li>kelas atau ekskul yang belum ada di daftar;</li>
<li>siswa yang pindah atau keluar.</li></ul></article>
<article><span class="icon" style="background:{SKY}">{mail}</span><h2>Masalah aplikasi dan saran</h2>
<p>Kirim email ke pengembang. Ceritakan sekolahmu, apa yang diketuk, dan apa yang terjadi. Tangkapan layar sangat membantu.</p>
<a class="button" href="mailto:{HELP_EMAIL}">{HELP_EMAIL}</a></article>
<article class="wide faq"><h2>Sering ditanyakan</h2><dl>{faq}</dl></article>
<article class="wide"><div class="share"><div class="code"><img src="{qr}"></div><div>
<h2>Situs Sabu Saku</h2>
<p>Informasi aplikasi, ketentuan penggunaan, kebijakan privasi, dan cara menghapus akun beserta datanya. Kode QR di samping membuka Sabu Saku di Google Play, untuk dibagikan ke teman.</p>
<div class="links"><a class="button" href="https://sabusaku.web.app">sabusaku.web.app</a>
<a class="button light" href="https://sabusaku.web.app/ketentuan">sabusaku.web.app/ketentuan</a>
<a class="button light" href="https://sabusaku.web.app/privasi">sabusaku.web.app/privasi</a>
<a class="button light" href="https://sabusaku.web.app/hapus-data">sabusaku.web.app/hapus-data</a></div></div></div></article></div>
<div class="thanks"><img src="{mark}"><div><h3>Satu Bulan Satu Buku</h3>
<p>Terima kasih sudah membaca bersama Sabu Saku di {SCHOOL}. Selamat membaca!</p></div></div>"""


def build_html():
    # Page 1 is the cover and page 2 the contents.
    pages = list(enumerate(PAGES, start=3))
    keys = {spec["key"]: number for number, spec in pages if spec["key"]}
    renderers = {"duo": render_duo, "tour": render_tour, "install": render_install, "rules": render_rules,
                 "tips": render_tips, "missions": render_missions, "help": render_help}
    body = render_cover(pages) + render_toc(pages)
    for number, spec in pages:
        kind = spec["kind"]
        if kind == "divider":
            inner = render_divider(spec, number, pages)
        else:
            inner = SHELF + renderers[kind](spec, number, keys)
        body += f"""<div class="page {kind if kind == 'divider' else ''}" id="p{number}" style="{role_style(spec['role'])}">
{inner}{footer(number, dark=kind == 'divider')}</div>"""
    return f'<!doctype html><html lang="id"><meta charset="utf-8"><title>Buku Panduan Sabu Saku</title><style>{CSS}</style>{body}</html>'


def check_pins():
    """Warns about pins that would sit on the cropped status bar or off screen."""
    top = STATUS_BAR / RAW_H * PREVIEW_H + 12
    for spec in PAGES:
        for item in spec["shots"]:
            for x, y, _ in item["pins"]:
                if not (12 <= x <= PREVIEW_W - 12 and top <= y <= PREVIEW_H - 12):
                    print(f"warning: pin ({x}, {y}) on {item['name']} is cut off")


def print_pdf(document):
    with tempfile.TemporaryDirectory() as work:
        source = pathlib.Path(work) / "manual.html"
        source.write_text(document, encoding="utf-8")
        OUT.unlink(missing_ok=True)
        chrome = subprocess.Popen(
            [CHROME, "--headless=new", "--disable-gpu", "--allow-file-access-from-files",
             f"--user-data-dir={work}/profile", "--no-pdf-header-footer", "--virtual-time-budget=8000",
             f"--print-to-pdf={OUT}", source.as_uri()],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Headless Chrome writes the file and then sometimes fails to exit, so
        # wait for the file to stop growing rather than for the process.
        deadline = time.monotonic() + 120
        size = -1
        while time.monotonic() < deadline and chrome.poll() is None:
            current = OUT.stat().st_size if OUT.exists() else 0
            if current > 0 and current == size:
                break
            size = current
            time.sleep(2)
        if chrome.poll() is None:
            chrome.kill()
        chrome.wait()
        if not OUT.exists() or OUT.stat().st_size == 0:
            raise SystemExit("Chrome did not write the PDF")
        print(OUT.relative_to(ROOT), f"{OUT.stat().st_size / 1e6:.1f} MB")


def main():
    prepare_shots()
    names = {item["name"] for spec in PAGES for item in spec["shots"]}
    names |= {n["shot"] for spec in PAGES for n in spec["notes"] if n["shot"]}
    names.add("siswa-beranda-komentar")
    missing = sorted(name for name in names if not (SHOTS / f"{name}.jpg").exists())
    if missing:
        raise SystemExit(f"Missing screenshots in {SHOTS.relative_to(ROOT)}: {', '.join(missing)}")
    check_pins()
    document = build_html()
    broken = sorted(set(re.findall(r'href="#([\w-]+)"', document)) - set(re.findall(r'id="([\w-]+)"', document)))
    if broken:
        raise SystemExit(f"Links to missing pages: {', '.join(broken)}")
    print_pdf(document)
    shutil.copyfile(OUT, HOSTED)
    print(HOSTED.relative_to(ROOT))


if __name__ == "__main__":
    main()
