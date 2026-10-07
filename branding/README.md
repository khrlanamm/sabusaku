# Branding Sabu Saku

Logo: **buku terbuka dengan tunas** — membaca yang tumbuh dari bulan ke bulan. Nama dan slogan memakai Poppins (SIL OFL 1.1, lisensi bebas pakai, termasuk komersial). Teks pada semua SVG sudah diubah menjadi path, jadi tampil sama di perangkat/aplikasi mana pun tanpa font terpasang.

## Palet

| Nama | Hex | Pakai untuk |
|---|---|---|
| Navy | `#17365D` | Teks nama, sampul buku, latar ikon/splash |
| Navy dalam | `#0F2747` | Ujung gradien latar |
| Biru | `#2563EB` | Halaman buku, tombol utama, slogan |
| Biru tua | `#1D4FC4` | Halaman kanan (kedalaman) |
| Langit | `#E4EEFF` | Halaman pada latar gelap |
| Hijau | `#2FA866` | Tunas, status aktif |
| Hijau muda | `#5CD08A` | Tunas pada latar gelap |
| Amber | `#F5B942` | Aksen streak/peringatan (tidak ada di logo) |

## Isi folder

### `svg/` (sumber utama, vektor)
| Berkas | Kegunaan |
|---|---|
| `logo-mark.svg` | Logo saja, untuk latar terang |
| `logo-mark-reversed.svg` | Logo saja, untuk latar navy/gelap |
| `logo-mark-mono-navy.svg`, `logo-mark-mono-white.svg` | Satu warna (cetak, stempel, watermark) |
| `logo-horizontal.svg` | Logo + nama + slogan, latar terang |
| `logo-horizontal-reversed.svg` | Versi untuk latar gelap |
| `app-icon.svg` | Ikon aplikasi 1024×1024 (latar penuh, tanpa sudut membulat; sistem yang memotong bentuknya) |
| `app-icon-foreground.svg` | Lapisan depan *adaptive icon* (transparan, di dalam zona aman) |
| `app-icon-background.svg` | Lapisan belakang *adaptive icon* (gradien navy) |
| `app-icon-monochrome.svg` | Lapisan ikon bertema Android 13+ |
| `app-icon-preview-rounded.svg` | Hanya pratinjau bentuk membulat, bukan untuk dipakai |
| `splash.svg` | Desain layar splash penuh 1080×1920 **dengan nama** |
| `splash-logo-with-name.svg` | Logo + nama transparan untuk splash bawaan (Android < 12) |
| `splash-android12-icon.svg` | Ikon splash Android 12+ (muat di lingkaran 640 dari 960) |

### `png/` (hasil render siap pakai)
`app-icon-1024.png`, `playstore-icon-512.png` (ikon Google Play), `app-icon-foreground-1024.png`, `app-icon-background-1024.png`, `app-icon-monochrome-1024.png`, `splash-1080x1920.png`, `splash-logo-with-name.png`, `splash-android12-icon.png`, `logo-mark-1024.png`, `logo-horizontal-2400.png`, `app-icon-preview-rounded.png`.

Catatan: `app-icon-foreground`, `app-icon-monochrome`, `splash-android12-icon`, dan `splash-logo-with-name` berlatar **transparan** dengan unsur putih; di penampil berlatar putih sebagian tampak hilang. Lihat `app-icon-1024.png` dan `splash-1080x1920.png` untuk tampilan jadi di atas latar navy.

### Lainnya
`generate_branding.py` membuat ulang semua berkas di atas (`pip install fonttools cairosvg`, lalu `python3 generate_branding.py`). Ubah warna/geometri di berkas itu lalu jalankan ulang. `fonts/` berisi Poppins ExtraBold dan Medium (lisensi OFL).

## Pemasangan di Flutter

Letakkan folder ini di akar proyek Flutter, lalu tambahkan ke `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: any   # gunakan versi stabil terbaru
  flutter_native_splash: any

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "branding/png/app-icon-1024.png"
  adaptive_icon_background: "branding/png/app-icon-background-1024.png"
  adaptive_icon_foreground: "branding/png/app-icon-foreground-1024.png"
  adaptive_icon_monochrome: "branding/png/app-icon-monochrome-1024.png"

flutter_native_splash:
  color: "#17365D"
  image: "branding/png/splash-logo-with-name.png"
  android_12:
    color: "#17365D"
    image: "branding/png/splash-android12-icon.png"
```

Jalankan `dart run flutter_launcher_icons` dan `dart run flutter_native_splash:create`.

**Catatan splash:** Android 12 ke atas hanya mengizinkan **ikon** pada splash sistem, tidak bisa menampilkan teks nama. Nama muncul pada Android < 12 (lewat `splash-logo-with-name.png`) dan pada layar sambutan Flutter singkat yang menirukan `svg/splash.svg` (dengan paket `flutter_svg`), ditampilkan sesaat sebelum login/beranda. Periksa ukuran logo splash di perangkat nyata; bila terlalu besar, kecilkan konten pada PNG.

## Aturan pakai singkat
- Beri ruang kosong di sekeliling logo minimal setengah tinggi tunas.
- Ukuran minimum: logo saja 24 px lebar; logo horizontal 120 px tinggi (di bawah itu slogan tidak terbaca, pakai logo saja).
- Jangan memutar, meregangkan, mengubah warna di luar palet, atau meletakkan versi terang di atas latar gelap (pakai `-reversed`).
- Ikon aplikasi memakai versi **tanpa garis halaman** agar tetap jelas di ukuran kecil.
