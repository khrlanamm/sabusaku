"""Builds the Play Store listing images from raw app screenshots.

Each image is an HTML page (headline, device mockup, brand colours and
Poppins from assets/fonts) rendered to PNG with headless Chrome, then
flattened to 24-bit PNG because Play rejects images with an alpha channel.
Needs Google Chrome in /Applications and ImageMagick (`magick`).

    python3 -I store/make_assets.py            # render store/out from store/raw
    python3 -I store/make_assets.py --import   # refresh store/raw first, then render

Raw screenshots come from tool/screenshots.sh, which signs in to production
as real accounts and writes Flutter-surface captures (no Android status bar)
to build/screenshots/phone (1080x2424, its default out-dir) and, run on a
10-inch tablet with build/screenshots/tablet as out-dir, 2560x1600 landscape
captures (Android 16 shows the app in landscape on tablets). build/ is
gitignored, which matters because some screens show real email addresses.

`--import` copies only the screens used below from build/screenshots into
store/raw (committed), paints the RETOUCH boxes over them, and deletes the
raws that are no longer used. None of the screens used shows an email
address. If you swap in one that does (such as siswa-profil, guru-profil,
guru-detail-siswa or siswa-ubah-password), add a RETOUCH box over the
address and look at the copy in store/raw before committing it.

Input:  store/raw/phone/*.png    1080x2424
        store/raw/tablet/*.png   2560x1600
Output: store/out/feature-graphic.png        1024x500
        store/out/phone-1..8.png             1080x1920
        store/out/tablet7-1..6.png           1920x1200
        store/out/tablet10-1..6.png          2560x1600
        store/out/icon-512.png               512x512, copy of branding/png/playstore-icon-512.png
"""

import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "build" / "screenshots"
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "out"
FONTS = ROOT / "assets" / "fonts"
BRAND = ROOT / "branding"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Palette of the logo (branding/README.md).
NAVY, NAVY_DEEP, BLUE = "#17365D", "#0F2747", "#2563EB"
GREEN, GREEN_LIGHT, AMBER = "#2FA866", "#5CD08A", "#F5B942"

# The captures start with the empty band where the status bar would be.
# Part of it is cropped so the screen title sits close to the top of the
# mockup, as on a real device.
PHONE = {"dir": "phone", "width": 1080, "height": 2424, "crop_top": 120}
TABLET = {"dir": "tablet", "width": 2560, "height": 1600, "crop_top": 40}

# Boxes (x0, y0, x1, y1) in raw pixels painted with the screen background
# when a raw is imported.
RETOUCH = {
    # A stray glyph above the book title, left over from a transition.
    ("phone", "siswa-isi-jurnal"): [(178, 440, 198, 457)],
}

# Material icons, 24x24 paths.
ICONS = {
    "flame": "M19.48 12.35c-1.57-4.08-7.16-4.3-5.81-10.23.1-.44-.37-.78-.75-.55C9.29 3.71 6.68 8 8.87 13.62c.18.46-.36.89-.75.59-1.81-1.37-2-3.34-1.84-4.75.06-.52-.62-.77-.91-.34C4.69 10.16 4 11.84 4 14.37c.38 5.6 5.11 7.32 6.81 7.54 2.43.31 5.06-.14 6.95-1.87 2.08-1.93 2.84-5.01 1.72-7.69zm-9.28 5.03c1.44-.35 2.18-1.39 2.38-2.31.33-1.43-.96-2.83-.09-5.09.33 1.87 3.27 3.04 3.27 5.08.08 2.53-2.66 4.7-5.56 2.32z",
    "chat": "M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z",
    "check": "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z",
    "bell": "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z",
    "people": "M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z",
    "search": "M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z",
    "book": "M18 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 4h5v8l-2.5-1.5L6 12V4z",
    "star": "M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z",
    "moon": "M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z",
    "pencil": "M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z",
    "plus": "M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z",
    "mail": "M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z",
}

# Each shot: raw file, audience tag, headline (<em> marks the accent words),
# sub line, and floating chips as (icon, colour, text, CSS position).
# Chip texts repeat what the screen itself shows; nothing is invented. The
# sub line may describe the feature around the screen.
PHONE_SHOTS = [
    ("siswa-beranda-komentar", "Untuk siswa", "Satu bulan,<br><em>satu buku</em>",
     "Jurnal membaca harian, dipantau gurumu.",
     [("check", GREEN, "Jurnal hari ini sudah diisi", "right:44px;top:1470px"),
      ("chat", BLUE, "Komentar baru dari guru", "left:44px;top:1630px")]),
    ("siswa-cari-buku", "Untuk siswa", "Cari bukumu,<br><em>langsung ketemu</em>",
     "Judul, penulis, dan cover terisi dari katalog.",
     [("search", BLUE, "Cari atau isi sendiri", "right:44px;top:1385px")]),
    ("siswa-jelajahi", "Untuk siswa", "Temukan<br><em>bacaan berikutnya</em>",
     "Rekomendasi sekolah dan buku populer.",
     [("flame", AMBER, "Populer di sekolahmu", "right:44px;top:990px"),
      ("book", GREEN, "1.198 buku bercover", "right:44px;top:1240px")]),
    ("siswa-isi-jurnal", "Untuk siswa", "Catat bacaanmu<br><em>setiap hari</em>",
     "Tetap bisa disimpan saat tanpa sinyal.",
     [("book", BLUE, "Halaman 1 sampai 48", "right:44px;top:1085px")]),
    ("siswa-jurnal-komentar", "Untuk siswa", "Tanggapan langsung<br><em>dari guru</em>",
     "Notifikasi masuk saat jurnalmu dikomentari.",
     [("chat", BLUE, "\u201cRingkasanmu runtut, Alan.\u201d", "right:44px;top:1775px")]),
    ("guru-dashboard-gelap", "Untuk penanggung jawab", "Pantau sekolahmu<br><em>sekali lihat</em>",
     "Status tiap siswa, dalam tema terang atau gelap.",
     [("people", BLUE, "Saring per ekstrakurikuler", "right:44px;top:1250px")]),
    ("guru-detail-buku", "Untuk penanggung jawab", "Rawat katalog<br><em>bersama</em>",
     "Setiap perubahan buku tercatat di riwayat.",
     [("star", AMBER, "Rekomendasi untuk siswa", "right:44px;top:840px")]),
    ("guru-tambah-siswa", "Untuk penanggung jawab", "Tambah siswa<br><em>cukup dengan email</em>",
     "Satu per satu, atau impor dari CSV.",
     [("mail", BLUE, "Hanya email yang wajib", "right:44px;top:1345px")]),
]
TABLET_SHOTS = [
    ("siswa-beranda", "Untuk siswa", "Satu bulan, <em>satu buku</em>",
     "Jurnal membaca harian untuk siswa, dipantau penanggung jawab di sekolah.",
     [("check", GREEN, "Jurnal hari ini sudah diisi", "right:80px;top:800px"),
      ("book", BLUE, "Halaman 48 dari 534", "left:80px;top:880px")]),
    ("siswa-jelajahi", "Untuk siswa", "Jelajahi <em>katalog bersama</em>",
     "Rekomendasi sekolah dan buku yang ramai dibaca temanmu.",
     [("flame", AMBER, "Populer di sekolahmu", "right:80px;top:540px"),
      ("book", GREEN, "1.198 buku bercover", "right:220px;top:800px")]),
    ("siswa-detail-buku", "Untuk siswa", "Kenali bukunya <em>sebelum mulai</em>",
     "Cover, sinopsis, penerbit, dan berapa temanmu yang membacanya.",
     [("book", BLUE, "Lengkap dengan sinopsis", "right:80px;top:470px")]),
    ("guru-dashboard-gelap", "Untuk penanggung jawab", "Pantau sekolah <em>sekali lihat</em>",
     "Per sekolah atau per ekstrakurikuler, dalam tema terang atau gelap.",
     [("people", BLUE, "Saring per ekstrakurikuler", "right:80px;top:440px")]),
    ("guru-katalog", "Untuk penanggung jawab", "Katalog bersama, <em>rapi terjaga</em>",
     "Tambah dan ubah buku, tinjau saran siswa, beri rekomendasi.",
     [("book", GREEN, "1.198 buku di katalog", "right:80px;top:600px")]),
    ("guru-jurnal-komentar", "Untuk penanggung jawab", "Baca jurnal, <em>beri komentar</em>",
     "Siswa langsung mendapat notifikasi saat jurnalnya dikomentari.",
     [("chat", BLUE, "\u201cRingkasanmu runtut, Alan.\u201d", "right:80px;top:910px")]),
]

# The phone mockups on the feature graphic.
FEATURE_PHONES = ["siswa-jelajahi", "siswa-beranda-komentar"]


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
.sub {{ margin: 22px 0 0; font-weight: 500; font-size: 33px; line-height: 1.4; }}
.dark .sub {{ color: rgba(255, 255, 255, .84); }}
.light .sub {{ color: #47597A; }}

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
    """A device mockup whose screen is `width` px wide, showing `raw`
    without the top `crop_top` px."""
    scale = width / source["width"]
    crop = source["crop_top"] * scale
    height = (source["height"] - source["crop_top"]) * scale
    image = (RAW / source["dir"] / f"{raw}.png").as_uri()
    return f"""
<div class="device" style="padding:{bezel}px;border-radius:{radius}px;width:{width + 2 * bezel}px">
  <div class="screen" style="height:{height:.1f}px;border-radius:{radius - bezel}px">
    <img src="{image}" style="width:{width}px;margin-top:-{crop:.1f}px">
  </div>
</div>"""


def chip(icon, colour, text, position):
    tint = colour + "26"  # the icon colour at 15% as the badge background
    tilt = -3 if position.startswith("left") else 3
    return f"""
<div class="chip" style="{position};transform:rotate({tilt}deg)">
  <span class="ic" style="background:{tint}"><svg viewBox="0 0 24 24"><path fill="{colour}" d="{ICONS[icon]}"/></svg></span>
  {text}
</div>"""


def phone_page(shot, dark):
    """1080x1920: headline on top, the phone below it, cut by the bottom edge."""
    raw, tag, title, sub, chips = shot
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1080px; height: 1920px; }}
.copy {{ position: absolute; left: 0; right: 0; top: 104px; padding: 0 70px; text-align: center; }}
.sub {{ margin-left: auto; margin-right: auto; max-width: 880px; }}
.stage {{ position: absolute; left: 0; right: 0; top: 548px; display: flex; justify-content: center; }}
</style><body class="{"dark" if dark else "light"}">{orbs(1080, 1920)}
<div class="copy"><span class="tag"><i></i>{tag}</span><h1>{title}</h1><p class="sub">{sub}</p></div>
<div class="stage">{device(raw, PHONE, 640, 15, 66)}</div>
{"".join(chip(*c) for c in chips)}"""


def tablet_page(shot, dark):
    """1920x1200 landscape: one-line headline on top, the tablet below it."""
    raw, tag, title, sub, chips = shot
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1920px; height: 1200px; }}
.copy {{ position: absolute; left: 0; right: 0; top: 54px; padding: 0 120px; text-align: center; }}
.tag {{ font-size: 22px; padding: 9px 24px; }}
h1 {{ margin-top: 18px; font-size: 68px; letter-spacing: -1.4px; }}
.sub {{ margin-top: 10px; font-size: 29px; }}
.stage {{ position: absolute; left: 0; right: 0; top: 300px; display: flex; justify-content: center; }}
</style><body class="{"dark" if dark else "light"}">{orbs(1920, 1200)}
<div class="copy"><span class="tag"><i></i>{tag}</span><h1>{title}</h1><p class="sub">{sub}</p></div>
<div class="stage">{device(raw, TABLET, 1340, 16, 40)}</div>
{"".join(chip(*c) for c in chips)}"""


def feature_graphic_page():
    logo = (BRAND / "svg" / "logo-mark-reversed.svg").as_uri()
    back, front = FEATURE_PHONES
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1024px; height: 500px; }}
.brand {{ position: absolute; left: 64px; top: 70px; display: flex; align-items: center; gap: 8px; }}
.brand img {{ width: 120px; height: 120px; margin-left: -16px; }}
.name {{ font-weight: 800; font-size: 56px; line-height: 1; letter-spacing: -1px; }}
.motto {{ margin-top: 8px; font-weight: 600; font-size: 19px; letter-spacing: 2.4px; color: #A9C6FF; text-transform: uppercase; }}
.pitch {{ position: absolute; left: 64px; top: 228px; width: 520px; font-weight: 700; font-size: 30px; line-height: 1.25; letter-spacing: -.4px; }}
.pitch em {{ font-style: normal; color: {GREEN_LIGHT}; }}
.roles {{ position: absolute; left: 64px; top: 346px; display: flex; gap: 10px; }}
.roles span {{ padding: 7px 16px; border-radius: 999px; font-weight: 600; font-size: 16px;
  color: #DCE8FF; background: rgba(255, 255, 255, .12); border: 1.5px solid rgba(255, 255, 255, .20); }}
.phone {{ position: absolute; }}
</style><body class="dark">{orbs(1024, 500)}
<div class="brand"><img src="{logo}"><div><div class="name">Sabu Saku</div><div class="motto">Satu Bulan Satu Buku</div></div></div>
<div class="pitch">Jurnal membaca harian siswa,<br><em>dengan katalog 1.000+ buku</em></div>
<div class="roles"><span>Cari buku</span><span>Isi jurnal</span><span>Komentar guru</span></div>
<div class="phone" style="left:604px;top:84px;transform:rotate(-7deg)">{device(back, PHONE, 214, 7, 28)}</div>
<div class="phone" style="left:790px;top:38px;transform:rotate(6deg)">{device(front, PHONE, 226, 7, 30)}</div>"""


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


def used_raws():
    """(dir, name) of every raw screenshot the listing images use."""
    used = {("phone", shot[0]) for shot in PHONE_SHOTS}
    used |= {("phone", name) for name in FEATURE_PHONES}
    used |= {("tablet", shot[0]) for shot in TABLET_SHOTS}
    return used


def import_raws():
    """Copies the used screens from build/screenshots into store/raw,
    retouched, and removes the raws that are no longer used."""
    used = used_raws()
    for kind, name in sorted(used):
        source = SOURCE / kind / f"{name}.png"
        if not source.exists():
            raise SystemExit(f"{source.relative_to(ROOT)} is missing; run tool/screenshots.sh first")
        target = RAW / kind / f"{name}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        command = ["magick", str(source)]
        boxes = RETOUCH.get((kind, name), [])
        if boxes:
            background = subprocess.run(
                ["magick", str(source), "-format", "%[pixel:p{5,5}]", "info:"],
                check=True, capture_output=True, text=True).stdout.strip()
            command += ["-fill", background]
            for x0, y0, x1, y1 in boxes:
                command += ["-draw", f"rectangle {x0},{y0} {x1},{y1}"]
        # -strip drops metadata such as capture timestamps.
        subprocess.run(command + ["-strip", f"PNG24:{target}"], check=True)
        print(target.relative_to(ROOT))
    for kind in ("phone", "tablet"):
        for stale in sorted((RAW / kind).glob("*.png")):
            if (kind, stale.stem) not in used:
                stale.unlink()
                print(f"removed {stale.relative_to(ROOT)}")


def main():
    if "--import" in sys.argv[1:]:
        import_raws()
    render(feature_graphic_page(), "feature-graphic", 1024, 500)
    for index, shot in enumerate(PHONE_SHOTS, start=1):
        render(phone_page(shot, index % 2 == 1), f"phone-{index}", 1080, 1920)
    for index, shot in enumerate(TABLET_SHOTS, start=1):
        html = tablet_page(shot, index % 2 == 1)
        # Same page at two sizes: 1920x1200 for 7 inch, 2560x1600 for 10 inch.
        render(html, f"tablet7-{index}", 1920, 1200)
        render(html, f"tablet10-{index}", 1920, 1200, scale=4 / 3)
    shutil.copyfile(BRAND / "png" / "playstore-icon-512.png", OUT / "icon-512.png")
    print((OUT / "icon-512.png").relative_to(ROOT))


if __name__ == "__main__":
    main()
