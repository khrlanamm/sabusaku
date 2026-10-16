"""Builds the Play Store listing images from raw app screenshots.

Each image is an HTML page (headline, device mockup, brand colours and
fonts) rendered to PNG with headless Chrome, then flattened to 24-bit PNG
because Play rejects images with an alpha channel.

    python3 -I store/make_assets.py

Input:  store/raw/phone/*.png    1080x2424, captured on a phone (v1 came from the removed tool/store-screenshots.sh)
        store/raw/tablet/*.png   1600x2560, captured on a 10-inch tablet
Output: store/out/               feature graphic, phone and tablet screenshots
"""

import pathlib
import shutil
import subprocess
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "out"
FONTS = ROOT / "assets" / "fonts"
BRAND = ROOT / "branding"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Palette of the logo (branding/README.md).
NAVY, NAVY_DEEP, BLUE = "#17365D", "#0F2747", "#2563EB"
GREEN, GREEN_LIGHT, AMBER = "#2FA866", "#5CD08A", "#F5B942"

# The Android status bar is cropped from the raw screenshots so the
# emulator's clock and icons do not show in the listing.
PHONE = {"dir": "phone", "width": 1080, "height": 2424, "status_bar": 142}
TABLET = {"dir": "tablet", "width": 1600, "height": 2560, "status_bar": 142}

ICONS = {
    "flame": "M19.48 12.35c-1.57-4.08-7.16-4.3-5.81-10.23.1-.44-.37-.78-.75-.55C9.29 3.71 6.68 8 8.87 13.62c.18.46-.36.89-.75.59-1.81-1.37-2-3.34-1.84-4.75.06-.52-.62-.77-.91-.34C4.69 10.16 4 11.84 4 14.37c.38 5.6 5.11 7.32 6.81 7.54 2.43.31 5.06-.14 6.95-1.87 2.08-1.93 2.84-5.01 1.72-7.69zm-9.28 5.03c1.44-.35 2.18-1.39 2.38-2.31.33-1.43-.96-2.83-.09-5.09.33 1.87 3.27 3.04 3.27 5.08.08 2.53-2.66 4.7-5.56 2.32z",
    "chat": "M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z",
    "check": "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z",
    "cloud": "M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM14 13v4h-4v-4H7l5-5 5 5h-3z",
    "bell": "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z",
    "people": "M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z",
    "shield": "M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-2 16l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z",
}

# Each shot: raw file, audience tag, headline (<em> marks the accent words),
# sub line, and floating chips as (icon, colour, text, side, top).
# Chip texts repeat what the screen itself shows; nothing is invented.
PHONE_SHOTS = [
    ("siswa-beranda", "Untuk siswa", "Satu bulan,<br><em>satu buku</em>",
     "Jurnal membaca harian untuk siswa SMA.",
     [("flame", AMBER, "Streak 19 hari", "right", 1010),
      ("chat", BLUE, "Komentar baru dari guru", "left", 1530)]),
    ("siswa-isi-jurnal", "Untuk siswa", "Catat bacaanmu<br><em>setiap hari</em>",
     "Halaman, durasi, dan isi bacaan dalam satu menit.",
     [("cloud", BLUE, "Bisa disimpan tanpa sinyal", "left", 1690)]),
    ("siswa-komentar", "Untuk siswa", "Tanggapan langsung<br><em>dari guru</em>",
     "Notifikasi masuk saat jurnalmu dikomentari.",
     [("bell", AMBER, "Komentar dari Sari Wulandari", "right", 1420)]),
    ("siswa-riwayat", "Untuk siswa", "Semua jurnal<br><em>tersimpan rapi</em>",
     "Satu jurnal setiap hari, dari halaman pertama sampai terakhir.",
     [("check", GREEN, "Satu jurnal per hari", "left", 1560)]),
    ("siswa-profil", "Untuk siswa", "Lihat kebiasaan<br><em>membacamu tumbuh</em>",
     "Streak, total jurnal, dan buku yang sudah selesai.",
     [("flame", AMBER, "Streak terbaik 19 hari", "right", 1250)]),
    ("guru-dashboard", "Untuk guru", "Pantau seluruh kelas<br><em>sekali lihat</em>",
     "Siapa yang aktif dan siapa yang perlu perhatian.",
     [("people", BLUE, "10 siswa · 2 kelas", "left", 1640)]),
    ("guru-jurnal", "Untuk guru", "Baca jurnal siswa,<br><em>beri komentar</em>",
     "Progres, streak, dan riwayat buku tiap siswa.",
     [("chat", GREEN, "Komentar sampai ke siswa", "right", 1540)]),
    ("admin-pengguna", "Untuk sekolah", "Kelola kelas<br><em>dan akun</em>",
     "Impor guru dan siswa dari CSV. Data tiap sekolah terpisah.",
     [("shield", GREEN, "Data sekolah terisolasi", "left", 1500)]),
]
TABLET_SHOTS = [
    ("siswa-beranda", "Untuk siswa", "Satu bulan,<br><em>satu buku</em>",
     "Jurnal membaca harian untuk siswa SMA.",
     [("flame", AMBER, "Streak 19 hari", "right", 930)]),
    ("siswa-isi-jurnal", "Untuk siswa", "Catat bacaanmu<br><em>setiap hari</em>",
     "Halaman, durasi, dan isi bacaan dalam satu menit.",
     [("cloud", BLUE, "Bisa disimpan tanpa sinyal", "left", 1560)]),
    ("siswa-komentar", "Untuk siswa", "Tanggapan langsung<br><em>dari guru</em>",
     "Notifikasi masuk saat jurnalmu dikomentari.",
     [("bell", AMBER, "Komentar dari Sari Wulandari", "right", 1250)]),
    ("guru-dashboard", "Untuk guru", "Pantau seluruh kelas<br><em>sekali lihat</em>",
     "Siapa yang aktif dan siapa yang perlu perhatian.",
     [("people", BLUE, "10 siswa · 2 kelas", "left", 1560)]),
    ("guru-siswa", "Untuk guru", "Setiap siswa,<br><em>progresnya jelas</em>",
     "Saring per kelas dan status, cari berdasarkan nama.",
     [("check", GREEN, "Status dihitung otomatis", "right", 1560)]),
    ("admin-pengguna", "Untuk sekolah", "Kelola kelas<br><em>dan akun</em>",
     "Impor guru dan siswa dari CSV. Data tiap sekolah terpisah.",
     [("shield", GREEN, "Data sekolah terisolasi", "left", 1560)]),
]


def font_face(weight, name):
    return (f'@font-face {{ font-family: Poppins; font-weight: {weight}; '
            f'src: url("{(FONTS / f"Poppins-{name}.ttf").as_uri()}"); }}')


BASE_CSS = "\n".join([
    font_face(400, "Regular"), font_face(500, "Medium"), font_face(600, "SemiBold"),
    font_face(700, "Bold"), font_face(800, "ExtraBold"),
]) + f"""
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; overflow: hidden; }}
body {{ position: relative; font-family: Poppins, sans-serif; }}

/* Backgrounds echo the splash: a navy gradient with soft light, or its
   daylight counterpart. */
.dark {{
  color: #fff;
  background:
    radial-gradient(60% 42% at 100% 0%, rgba(86, 146, 240, .62), transparent 70%),
    radial-gradient(55% 40% at 0% 100%, rgba(47, 168, 102, .34), transparent 70%),
    linear-gradient(165deg, #1D457A 0%, {NAVY} 46%, {NAVY_DEEP} 100%);
}}
.light {{
  color: {NAVY};
  background:
    radial-gradient(60% 42% at 100% 0%, rgba(37, 99, 235, .20), transparent 70%),
    radial-gradient(55% 40% at 0% 100%, rgba(47, 168, 102, .20), transparent 70%),
    linear-gradient(180deg, #F8FBFF 0%, #E4EEFF 100%);
}}
.orb {{ position: absolute; border-radius: 50%; }}
.dark .orb {{ background: rgba(255, 255, 255, .055); }}
.light .orb {{ background: rgba(37, 99, 235, .07); }}

.copy {{ position: absolute; left: 0; right: 0; text-align: center; }}
.tag {{
  display: inline-flex; align-items: center; gap: 12px;
  padding: 10px 26px; border-radius: 999px;
  font-weight: 600; font-size: 25px; letter-spacing: 3px; text-transform: uppercase;
}}
.tag i {{ width: 12px; height: 12px; border-radius: 50%; background: {GREEN_LIGHT}; }}
.dark .tag {{ color: #CFE0FF; background: rgba(255, 255, 255, .11); border: 1.5px solid rgba(255, 255, 255, .20); }}
.light .tag {{ color: {BLUE}; background: #fff; border: 1.5px solid #CFE0FF; }}
.light .tag i {{ background: {GREEN}; }}
h1 {{ margin: 26px 0 0; font-weight: 800; font-size: 78px; line-height: 1.08; letter-spacing: -1.6px; }}
h1 em {{ font-style: normal; }}
.dark h1 em {{ color: {GREEN_LIGHT}; }}
.light h1 em {{ color: {BLUE}; }}
.sub {{ margin: 22px auto 0; max-width: 860px; font-weight: 500; font-size: 33px; line-height: 1.4; }}
.dark .sub {{ color: rgba(255, 255, 255, .84); }}
.light .sub {{ color: #47597A; }}

.stage {{ position: absolute; left: 0; right: 0; display: flex; justify-content: center; }}
.device {{ background: #0A1930; }}
.dark .device {{ box-shadow: 0 50px 100px rgba(4, 12, 30, .55), inset 0 0 0 2px rgba(255, 255, 255, .12); }}
.light .device {{ box-shadow: 0 50px 100px rgba(23, 54, 93, .30), inset 0 0 0 2px rgba(255, 255, 255, .10); }}
.screen {{ overflow: hidden; background: #F6F8FC; }}
.screen img {{ display: block; }}

.chip {{
  position: absolute; display: flex; align-items: center; gap: 16px;
  padding: 16px 30px 16px 18px; border-radius: 26px;
  background: #fff; color: {NAVY}; font-weight: 600; font-size: 29px; white-space: nowrap;
  box-shadow: 0 22px 50px rgba(4, 12, 30, .30);
}}
.chip .ic {{ width: 58px; height: 58px; border-radius: 18px; display: grid; place-items: center; }}
.chip svg {{ width: 34px; height: 34px; }}
"""


def orbs(width, height):
    """Soft circles like the ones on the splash screen."""
    return f"""
<div class="orb" style="width:{width * .78:.0f}px;height:{width * .78:.0f}px;right:-{width * .30:.0f}px;top:-{width * .34:.0f}px"></div>
<div class="orb" style="width:{width * .62:.0f}px;height:{width * .62:.0f}px;left:-{width * .28:.0f}px;top:{height * .56:.0f}px"></div>"""


def device(raw, source, width, bezel, radius):
    """A device mockup `width` px wide showing `raw` without its status bar."""
    scale = width / source["width"]
    crop = source["status_bar"] * scale
    height = (source["height"] - source["status_bar"]) * scale
    image = (RAW / source["dir"] / f"{raw}.png").as_uri()
    return f"""
<div class="device" style="padding:{bezel}px;border-radius:{radius}px;width:{width + 2 * bezel}px">
  <div class="screen" style="height:{height:.1f}px;border-radius:{radius - bezel}px">
    <img src="{image}" style="width:{width}px;margin-top:-{crop:.1f}px">
  </div>
</div>"""


def chip(icon, colour, text, side, top):
    tint = colour + "26"  # the icon colour at 15% as the badge background
    tilt = -3 if side == "left" else 3
    return f"""
<div class="chip" style="{side}:44px;top:{top}px;transform:rotate({tilt}deg)">
  <span class="ic" style="background:{tint}"><svg viewBox="0 0 24 24"><path fill="{colour}" d="{ICONS[icon]}"/></svg></span>
  {text}
</div>"""


def screenshot_page(shot, source, dark, device_width, bezel, radius, stage_top):
    raw, tag, title, sub, chips = shot
    theme = "dark" if dark else "light"
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1080px; height: 1920px; }}
.copy {{ top: 104px; padding: 0 70px; }}
.stage {{ top: {stage_top}px; }}
</style><body class="{theme}">{orbs(1080, 1920)}
<div class="copy"><span class="tag"><i></i>{tag}</span><h1>{title}</h1><p class="sub">{sub}</p></div>
<div class="stage">{device(raw, source, device_width, bezel, radius)}</div>
{"".join(chip(*c) for c in chips)}"""


def feature_graphic_page():
    logo = (BRAND / "svg" / "logo-mark-reversed.svg").as_uri()
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1024px; height: 500px; }}
.brand {{ position: absolute; left: 58px; top: 92px; display: flex; align-items: center; gap: 8px; }}
.brand img {{ width: 132px; height: 132px; margin-left: -18px; }}
.name {{ font-weight: 800; font-size: 62px; line-height: 1; letter-spacing: -1px; }}
.motto {{ margin-top: 8px; font-weight: 600; font-size: 22px; letter-spacing: 2.4px; color: #A9C6FF; text-transform: uppercase; }}
.pitch {{ position: absolute; left: 58px; top: 266px; width: 520px; font-weight: 700; font-size: 32px; line-height: 1.22; letter-spacing: -.5px; }}
.pitch em {{ font-style: normal; color: {GREEN_LIGHT}; }}
.roles {{ position: absolute; left: 58px; top: 378px; display: flex; gap: 10px; }}
.roles span {{ padding: 7px 18px; border-radius: 999px; font-weight: 600; font-size: 17px;
  color: #DCE8FF; background: rgba(255, 255, 255, .12); border: 1.5px solid rgba(255, 255, 255, .20); }}
.phone {{ position: absolute; }}
</style><body class="dark">{orbs(1024, 500)}
<div class="brand"><img src="{logo}"><div><div class="name">Sabu Saku</div><div class="motto">Satu Bulan Satu Buku</div></div></div>
<div class="pitch">Jurnal membaca harian untuk<br><em>siswa, guru, dan sekolah</em></div>
<div class="roles"><span>Catat bacaan</span><span>Pantau kelas</span><span>Beri komentar</span></div>
<div class="phone" style="left:596px;top:86px;transform:rotate(-7deg)">{device('guru-dashboard', PHONE, 218, 7, 28)}</div>
<div class="phone" style="left:786px;top:36px;transform:rotate(6deg)">{device('siswa-beranda', PHONE, 232, 7, 30)}</div>"""


def render(html, name, width, height, scale=1.0):
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        page = pathlib.Path(work) / "page.html"
        page.write_text(html, encoding="utf-8")
        target = OUT / f"{name}.png"
        target.unlink(missing_ok=True)
        chrome = subprocess.Popen(
            [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
             "--allow-file-access-from-files", f"--user-data-dir={work}/profile",
             f"--force-device-scale-factor={scale}", f"--window-size={width},{height}",
             "--virtual-time-budget=4000", f"--screenshot={target}", page.as_uri()],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Headless Chrome writes the screenshot and then sometimes fails to
        # exit, so wait for the file rather than for the process.
        deadline = time.monotonic() + 40
        while time.monotonic() < deadline and chrome.poll() is None:
            if target.exists() and target.stat().st_size > 0:
                time.sleep(1.5)  # let Chrome finish writing
                break
            time.sleep(0.3)
        if chrome.poll() is None:
            chrome.kill()
        chrome.wait()
        if not target.exists():
            raise SystemExit(f"Chrome did not render {name}")
        # Play accepts JPEG or 24-bit PNG only: drop the alpha channel.
        subprocess.run(["magick", str(target), "-alpha", "off", f"PNG24:{target}"], check=True)
        print(target.relative_to(ROOT))


def main():
    render(feature_graphic_page(), "feature-graphic", 1024, 500)
    for index, shot in enumerate(PHONE_SHOTS, start=1):
        render(screenshot_page(shot, PHONE, index % 2 == 1, 640, 15, 66, 548), f"phone-{index}", 1080, 1920)
    for index, shot in enumerate(TABLET_SHOTS, start=1):
        html = screenshot_page(shot, TABLET, index % 2 == 1, 880, 20, 46, 548)
        # Same page at two sizes: 1080x1920 for 7 inch, 1440x2560 for 10 inch.
        render(html, f"tablet7-{index}", 1080, 1920)
        render(html, f"tablet10-{index}", 1080, 1920, scale=4 / 3)
    shutil.copyfile(BRAND / "png" / "playstore-icon-512.png", OUT / "icon-512.png")


if __name__ == "__main__":
    main()
