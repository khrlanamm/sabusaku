"""Builds the Play Store listing images from raw app screenshots.

Each image is an HTML page (tagline, app screen, brand colours and Poppins
from assets/fonts) rendered to PNG with headless Chrome, then flattened to
24-bit PNG because Play rejects images with an alpha channel.
Needs Google Chrome in /Applications and ImageMagick (`magick`).

    python3 -I store/make_assets.py            # render store/out from store/raw
    python3 -I store/make_assets.py --import   # refresh store/raw first, then render

The phone and tablet screenshots follow Play's preview asset guidance
(support.google.com/googleplay/android-developer/answer/9866151): the app
screen is shown as it is, without a device frame, and the tagline (audience
pill, one-line headline and one short sub line) stays in a band at the top
that takes at most 20% of the image height. Before rendering, each page is
loaded once more to measure that band (from the top edge down to the top of
the app screen) and the width of the headline and sub line; the build
fails if the band is taller than 20% or a line does not fit on one line.
There are no floating badges over the screens. The texts avoid
"terbaik/#1/baru/gratis/diskon" claims and calls to action, and describe
only what the app does. The feature graphic is a separate asset type and
keeps its tilted phone mockups.

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

import html as htmllib
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import NamedTuple

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "build" / "screenshots"
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "out"
FONTS = ROOT / "assets" / "fonts"
BRAND = ROOT / "branding"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Play: taglines must not take up more than 20% of the image.
MAX_TAGLINE = 0.20

# Palette of the logo (branding/README.md).
NAVY, NAVY_DEEP, BLUE = "#17365D", "#0F2747", "#2563EB"
GREEN, GREEN_LIGHT = "#2FA866", "#5CD08A"

# The captures start with the empty band where the status bar would be.
# Most of it is cropped so the screen title sits close to the top edge of
# the screen, as on a real device. On the phone screens with a bottom
# navigation bar, the bar starts at raw row 2183; `nav_top` skips three
# rows of its blank top padding so that the content the bar covers does
# not bleed into its edge when the screen is scaled down.
PHONE = {"dir": "phone", "width": 1080, "height": 2424, "crop_top": 120, "nav_top": 2186}
TABLET = {"dir": "tablet", "width": 2560, "height": 1600, "crop_top": 40}

# The phone screen on a 1080x1920 screenshot: 814x1568 px, which holds
# 2080 raw rows, as much as an 18:9 phone (1080x2160) shows below its
# status bar. Longer screens are cut at the bottom like on such a phone:
# a screen with a navigation bar keeps the bar and loses the end of the
# content above it.
PHONE_FRAME = {"top": 296, "width": 814, "height": 1568, "radius": 44}

# Boxes (x0, y0, x1, y1) in raw pixels painted with the screen background
# when a raw is imported.
RETOUCH = {
    # A stray glyph above the book title, left over from a transition.
    ("phone", "siswa-isi-jurnal"): [(178, 440, 198, 457)],
}



class Shot(NamedTuple):
    """One screenshot: raw file, audience tag, headline (<em> marks the
    accent words) and sub line, each kept to one line. The headline and
    sub line describe what the screen shows or the feature around it;
    nothing is invented. `top` is the first raw row shown (0: the crop_top
    of the device); on the phone it is chosen so that the bottom of the
    frame cuts between two rows of the UI, not through text, and never
    through what the headline is about. `nav` keeps the navigation bar."""
    raw: str
    tag: str
    title: str
    sub: str
    top: int = 0
    nav: bool = False


PHONE_SHOTS = [
    Shot("siswa-beranda-komentar", "Untuk siswa", "Satu bulan, <em>satu buku</em>",
         "Jurnal membaca harian, dipantau gurumu.", top=152, nav=True),
    Shot("siswa-cari-buku", "Untuk siswa", "Cari bukumu <em>di katalog</em>",
         "Judul, penulis, dan cover langsung terisi.", top=100, nav=True),
    Shot("siswa-jelajahi", "Untuk siswa", "Temukan <em>bacaan berikutnya</em>",
         "Lihat yang populer di sekolahmu dan seluruh katalog.", top=146),
    Shot("siswa-isi-jurnal", "Untuk siswa", "Catat bacaanmu <em>setiap hari</em>",
         "Tetap bisa disimpan saat tanpa sinyal.", top=144),
    Shot("siswa-jurnal-komentar", "Untuk siswa", "Tanggapan <em>dari gurumu</em>",
         "Notifikasi masuk saat jurnalmu dikomentari.", top=135),
    Shot("guru-dashboard-gelap", "Untuk penanggung jawab", "Pantau siswa <em>sekali lihat</em>",
         "Status tiap siswa, dalam tema terang atau gelap.", top=136, nav=True),
    Shot("guru-detail-buku", "Untuk penanggung jawab", "Rawat katalog <em>bersama</em>",
         "Setiap perubahan buku tercatat di riwayat.", top=150),
    Shot("guru-tambah-siswa", "Untuk penanggung jawab", "Tambah siswa <em>cukup email</em>",
         "Satu per satu, atau impor dari CSV.", top=135),
]
# Tablet screens are shown whole, navigation bar included.
TABLET_SHOTS = [
    Shot("siswa-beranda", "Untuk siswa", "Satu bulan, <em>satu buku</em>",
         "Jurnal membaca harian untuk siswa, dipantau penanggung jawab di sekolah."),
    Shot("siswa-jelajahi", "Untuk siswa", "Jelajahi <em>katalog bersama</em>",
         "Lihat yang populer di sekolahmu, atau telusuri per kategori."),
    Shot("siswa-detail-buku", "Untuk siswa", "Kenali bukunya <em>sebelum mulai</em>",
         "Cover, sinopsis, penerbit, dan berapa temanmu yang membacanya."),
    Shot("guru-dashboard-gelap", "Untuk penanggung jawab", "Pantau sekolah <em>sekali lihat</em>",
         "Per sekolah atau per ekstrakurikuler, dalam tema terang atau gelap."),
    Shot("guru-katalog", "Untuk penanggung jawab", "Katalog bersama, <em>rapi terjaga</em>",
         "Tambah dan ubah buku, tinjau saran siswa, beri rekomendasi."),
    Shot("guru-jurnal-komentar", "Untuk penanggung jawab", "Baca jurnal, <em>beri komentar</em>",
         "Siswa langsung mendapat notifikasi saat jurnalnya dikomentari."),
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
    radial-gradient(60% 42% at 100% 0%, rgba(37, 99, 235, .24), transparent 70%),
    radial-gradient(55% 40% at 0% 100%, rgba(47, 168, 102, .22), transparent 70%),
    linear-gradient(180deg, #EEF4FF 0%, #D6E4FF 100%);
}}
.orb {{ position: absolute; border-radius: 50%; }}
.dark .orb {{ background: rgba(255, 255, 255, .055); }}
.light .orb {{ background: rgba(37, 99, 235, .07); }}

.tag {{
  display: inline-flex; align-items: center; gap: 12px;
  padding: 10px 26px; border-radius: 999px;
  font-weight: 600; font-size: 25px; line-height: 1.2; letter-spacing: 3px; text-transform: uppercase;
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

/* The device mockups of the feature graphic. */
.device {{ background: #0A1930; }}
.dark .device {{ box-shadow: 0 50px 100px rgba(4, 12, 30, .55), inset 0 0 0 2px rgba(255, 255, 255, .12); }}
.screen {{ overflow: hidden; background: #F6F8FC; }}
.screen img {{ display: block; }}

/* The app screen of the phone and tablet screenshots: no device frame,
   just the screen with rounded corners and a soft shadow. */
.copy {{ position: absolute; left: 0; right: 0; text-align: center; }}
.shot {{ position: absolute; overflow: hidden; background: #F6F8FC; }}
.shot img {{ display: block; }}
.shot .bar {{ position: absolute; left: 0; right: 0; bottom: 0; overflow: hidden; }}
.dark .shot {{ box-shadow: 0 36px 80px rgba(4, 12, 30, .50), 0 0 0 2px rgba(255, 255, 255, .10); }}
.light .shot {{ box-shadow: 0 30px 70px rgba(23, 54, 93, .26), 0 0 0 2px rgba(23, 54, 93, .10); }}
"""

# Runs in the page and leaves its measurements in <html data-measure>,
# which `measure` reads back from Chrome's --dump-dom output.
MEASURE_JS = """
<script>
document.fonts.ready.then(() => {
  const box = el => el.getBoundingClientRect();
  // Width of a line of text if it were not allowed to wrap.
  const natural = sel => {
    const el = document.querySelector(sel);
    el.style.whiteSpace = 'nowrap';
    const range = document.createRange();
    range.selectNodeContents(el);
    const width = range.getBoundingClientRect().width;
    el.style.whiteSpace = '';
    return width;
  };
  const copy = document.querySelector('.copy');
  const style = getComputedStyle(copy);
  const parts = [...copy.children].map(box);
  document.documentElement.dataset.measure = JSON.stringify({
    height: box(document.body).height,
    textTop: Math.min(...parts.map(p => p.top)),
    textBottom: Math.max(...parts.map(p => p.bottom)),
    screenTop: box(document.querySelector('.shot')).top,
    room: copy.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight),
    h1: natural('h1'),
    sub: natural('.sub'),
  });
});
</script>"""


def orbs(width, height):
    """Soft circles like the ones on the splash screen."""
    return f"""
<div class="orb" style="width:{width * .78:.0f}px;height:{width * .78:.0f}px;right:-{width * .30:.0f}px;top:-{width * .34:.0f}px"></div>
<div class="orb" style="width:{width * .62:.0f}px;height:{width * .62:.0f}px;left:-{width * .28:.0f}px;top:{height * .56:.0f}px"></div>"""


def device(raw, source, width, bezel, radius):
    """A device mockup whose screen is `width` px wide, showing `raw`
    without the top `crop_top` px. Used on the feature graphic only."""
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


def screen(shot, source, left, top, width, height, radius):
    """The app screen itself at (left, top), `width` x `height` px: the raw
    scaled to `width` from row `shot.top` down, cut at `height`. With
    `shot.nav` the navigation bar stays at the bottom and the content above
    it is cut instead."""
    scale = width / source["width"]
    first = shot.top or source["crop_top"]
    image = (RAW / source["dir"] / f"{shot.raw}.png").as_uri()
    layers = f'<img src="{image}" style="width:{width}px;margin-top:-{first * scale:.2f}px">'
    end, limit = first + height / scale, source["height"]
    if shot.nav:
        bar = source["nav_top"]
        layers += (f'<div class="bar" style="height:{(source["height"] - bar) * scale:.2f}px">'
                   f'<img src="{image}" style="width:{width}px;margin-top:-{bar * scale:.2f}px"></div>')
        end, limit = end - (source["height"] - bar), bar
    if end > limit + 0.5:
        raise SystemExit(f"{shot.raw}: the frame reaches below the screenshot; lower `top`")
    return f"""
<div class="shot" style="left:{left}px;top:{top}px;width:{width}px;height:{height}px;border-radius:{radius}px">
  {layers}
</div>"""


def copy_block(shot):
    return (f'<div class="copy"><span class="tag"><i></i>{shot.tag}</span>'
            f'<h1>{shot.title}</h1><p class="sub">{shot.sub}</p></div>')


def phone_page(shot, dark):
    """1080x1920: the tagline band on top, the app screen below it."""
    frame = PHONE_FRAME
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1080px; height: 1920px; }}
.copy {{ top: 58px; padding: 0 60px; }}
.tag {{ font-size: 22px; padding: 8px 22px; letter-spacing: 2.6px; gap: 11px; }}
.tag i {{ width: 11px; height: 11px; }}
h1 {{ margin-top: 18px; font-size: 60px; line-height: 1.12; letter-spacing: -1.2px; }}
.sub {{ margin-top: 8px; font-size: 30px; line-height: 1.35; }}
</style><body class="{"dark" if dark else "light"}">{orbs(1080, 1920)}
{copy_block(shot)}
{screen(shot, PHONE, (1080 - frame["width"]) // 2, frame["top"], frame["width"], frame["height"], frame["radius"])}
{MEASURE_JS}"""


def tablet_page(shot, dark):
    """1920x1200 landscape: the tagline band on top, the whole app screen
    below it."""
    top, bottom = 212, 40
    height = 1200 - top - bottom
    width = round(height * TABLET["width"] / (TABLET["height"] - TABLET["crop_top"]))
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body {{ width: 1920px; height: 1200px; }}
.copy {{ top: 36px; padding: 0 120px; }}
.tag {{ font-size: 18px; padding: 6px 18px; letter-spacing: 2.4px; gap: 10px; }}
.tag i {{ width: 10px; height: 10px; }}
h1 {{ margin-top: 12px; font-size: 52px; line-height: 1.12; letter-spacing: -1.1px; }}
.sub {{ margin-top: 4px; font-size: 25px; line-height: 1.35; }}
</style><body class="{"dark" if dark else "light"}">{orbs(1920, 1200)}
{copy_block(shot)}
{screen(shot, TABLET, (1920 - width) // 2, top, width, height, 32)}
{MEASURE_JS}"""


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


def run_chrome(page, work, width, height, args, done, stdout=subprocess.DEVNULL):
    """Opens `page` in headless Chrome with `args` and returns once `done()`
    holds. Headless Chrome sometimes does its job and then fails to exit,
    so this waits for the result rather than for the process."""
    process = subprocess.Popen(
        [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--allow-file-access-from-files", f"--user-data-dir={work}/profile",
         f"--window-size={width},{height}", "--virtual-time-budget=4000",
         *args, page.as_uri()],
        stdout=stdout, stderr=subprocess.DEVNULL)
    deadline = time.monotonic() + 40
    while time.monotonic() < deadline and process.poll() is None:
        if done():
            time.sleep(1.5)  # let Chrome finish writing
            break
        time.sleep(0.3)
    if process.poll() is None:
        process.kill()
    process.wait()


def measure(html, name, width, height):
    """Loads the page in Chrome, prints how much of the height the tagline
    band takes and returns what breaks the rules: a band taller than
    MAX_TAGLINE or a headline or sub line that does not fit on one line.
    The band runs from the top edge to the top of the app screen, so it
    includes the margins around the text."""
    with tempfile.TemporaryDirectory() as work:
        page = pathlib.Path(work) / "page.html"
        page.write_text(html, encoding="utf-8")
        dump = pathlib.Path(work) / "dom.html"
        with dump.open("w") as stdout:
            run_chrome(page, work, width, height, ["--dump-dom"],
                       lambda: "</html>" in dump.read_text(errors="replace"), stdout)
        found = re.search(r'data-measure="([^"]*)"', dump.read_text(errors="replace"))
    if not found:
        raise SystemExit(f"{name}: Chrome did not report the measurements")
    m = json.loads(htmllib.unescape(found.group(1)))
    band = m["screenTop"] / m["height"]
    text = (m["textBottom"] - m["textTop"]) / m["height"]
    print(f"{name}: tagline band {m['screenTop']:.0f} of {m['height']:.0f} px = {band:.1%} "
          f"(text itself {text:.1%}); headline {m['h1']:.0f}, sub line {m['sub']:.0f} "
          f"of {m['room']:.0f} px")
    errors = []
    if band > MAX_TAGLINE:
        errors.append(f"{name}: the tagline band takes {band:.1%} of the height, "
                      f"more than {MAX_TAGLINE:.0%}")
    if m["textBottom"] > m["screenTop"]:
        errors.append(f"{name}: the tagline runs into the app screen")
    for line in ("h1", "sub"):
        if m[line] > m["room"]:
            errors.append(f"{name}: the {'headline' if line == 'h1' else 'sub line'} "
                          f"does not fit on one line; shorten it")
    return errors


def render(html, name, width, height, scale=1.0):
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        page = pathlib.Path(work) / "page.html"
        page.write_text(html, encoding="utf-8")
        target = OUT / f"{name}.png"
        target.unlink(missing_ok=True)
        run_chrome(page, work, width, height,
                   [f"--force-device-scale-factor={scale}", f"--screenshot={target}"],
                   lambda: target.exists() and target.stat().st_size > 0)
        if not target.exists():
            raise SystemExit(f"Chrome did not render {name}")
        # Play accepts JPEG or 24-bit PNG only: drop the alpha channel.
        subprocess.run(["magick", str(target), "-alpha", "off", f"PNG24:{target}"], check=True)
        print(target.relative_to(ROOT))


def used_raws():
    """(dir, name) of every raw screenshot the listing images use."""
    used = {("phone", shot.raw) for shot in PHONE_SHOTS}
    used |= {("phone", name) for name in FEATURE_PHONES}
    used |= {("tablet", shot.raw) for shot in TABLET_SHOTS}
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
    # Measure every page first, so a tagline that breaks the rule stops
    # the build before any image in store/out is replaced.
    phones = [(f"phone-{i}", phone_page(shot, i % 2 == 1))
              for i, shot in enumerate(PHONE_SHOTS, start=1)]
    tablets = [(i, tablet_page(shot, i % 2 == 1))
               for i, shot in enumerate(TABLET_SHOTS, start=1)]
    errors = [error for name, html in phones for error in measure(html, name, 1080, 1920)]
    errors += [error for index, html in tablets
               for error in measure(html, f"tablet-{index}", 1920, 1200)]
    if errors:
        raise SystemExit("\n".join(errors))
    render(feature_graphic_page(), "feature-graphic", 1024, 500)
    for name, html in phones:
        render(html, name, 1080, 1920)
    for index, html in tablets:
        # Same page at two sizes: 1920x1200 for 7 inch, 2560x1600 for 10 inch.
        render(html, f"tablet7-{index}", 1920, 1200)
        render(html, f"tablet10-{index}", 1920, 1200, scale=4 / 3)
    shutil.copyfile(BRAND / "png" / "playstore-icon-512.png", OUT / "icon-512.png")
    print((OUT / "icon-512.png").relative_to(ROOT))


if __name__ == "__main__":
    main()
