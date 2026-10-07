#!/usr/bin/env python3
"""Generator aset branding Sabu Saku (logo, ikon aplikasi, splash).

Menghasilkan SVG (teks sudah diubah menjadi path, jadi tampil sama di mana pun)
dan PNG. Jalankan dari folder branding:

    pip install fonttools cairosvg
    python3 generate_branding.py

Font: Poppins (SIL Open Font License 1.1), ada di folder fonts/.
"""
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
import cairosvg

HERE = os.path.dirname(os.path.abspath(__file__))
SVG_DIR = os.path.join(HERE, "svg")
PNG_DIR = os.path.join(HERE, "png")
os.makedirs(SVG_DIR, exist_ok=True)
os.makedirs(PNG_DIR, exist_ok=True)

# ---------- Palet ----------
NAVY = "#17365D"
NAVY_DEEP = "#0F2747"
NAVY_LIGHT = "#1F4A82"
BLUE = "#2563EB"
BLUE_DARK = "#1D4FC4"
BLUE_MID = "#2F6FD6"
SKY = "#E4EEFF"
GREEN = "#2FA866"
GREEN_LIGHT = "#5CD08A"
TAG_LIGHT = "#9CC2FF"

BOLD = TTFont(os.path.join(HERE, "fonts", "poppins-latin-800-normal.woff"))
MEDIUM = TTFont(os.path.join(HERE, "fonts", "poppins-latin-500-normal.woff"))


def text_path(font, text, size, tracking=0.0):
    """Ubah teks jadi path SVG (origin di baseline kiri). Return (d, lebar)."""
    gs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    s = size / upm
    x = 0.0
    parts = []
    for ch in text:
        g = cmap[ord(ch)]
        pen = SVGPathPen(gs, ntos=lambda v: f"{v:.2f}")
        tp = TransformPen(pen, (s, 0, 0, -s, x, 0))
        gs[g].draw(tp)
        d = pen.getCommands()
        if d:
            parts.append(d)
        x += font["hmtx"][g][0] * s + tracking
    return " ".join(parts), x - tracking


# ---------- Mark (kotak 512, isi sekitar x 70..442, y 78..436) ----------
SCHEMES = {
    "light": dict(  # untuk latar terang
        pageL=BLUE, pageR=BLUE_DARK, cover=NAVY, lines="#FFFFFF", lines_op=0.45,
        stem=GREEN, leafA="#3CC07A", leafB=GREEN),
    "reversed": dict(  # untuk latar navy
        pageL="#FFFFFF", pageR=SKY, cover=BLUE_MID, lines="#9DB9E8", lines_op=0.6,
        stem=GREEN_LIGHT, leafA=GREEN_LIGHT, leafB="#3CC07A"),
    "mono": dict(  # satu warna (ikon tema Android 13)
        pageL="#FFFFFF", pageR="#FFFFFF", cover="#FFFFFF", lines=None, lines_op=0,
        stem="#FFFFFF", leafA="#FFFFFF", leafB="#FFFFFF"),
}

PAGE_L = "M250 218 C210 188 150 180 84 196 L84 372 C150 358 210 366 250 396 Z"
PAGE_R = "M262 218 C302 188 362 180 428 196 L428 372 C362 358 302 366 262 396 Z"
COVER = ("M72 388 C142 374 212 382 256 414 C300 382 370 374 440 388 "
         "L440 410 C370 396 300 404 256 436 C212 404 142 396 72 410 Z")
STEM = "M256 232 L256 154"
LEAF_A = "M256 192 C228 194 204 176 198 148 C230 144 256 162 256 192 Z"
LEAF_B = "M256 154 C258 114 288 86 332 82 C334 124 304 156 256 154 Z"
LINES_L = ["M116 250 Q166 242 216 256", "M116 288 Q166 280 216 294", "M116 326 Q166 318 216 332"]
LINES_R = ["M296 256 Q346 242 396 250", "M296 294 Q346 280 396 288", "M296 332 Q346 318 396 326"]


def mark(scheme, with_lines=True):
    c = SCHEMES[scheme]
    out = [
        f'<path d="{COVER}" fill="{c["cover"]}"/>',
        f'<path d="{PAGE_L}" fill="{c["pageL"]}"/>',
        f'<path d="{PAGE_R}" fill="{c["pageR"]}"/>',
    ]
    if with_lines and c["lines"]:
        for d in LINES_L + LINES_R:
            out.append(f'<path d="{d}" fill="none" stroke="{c["lines"]}" stroke-opacity="{c["lines_op"]}" '
                       f'stroke-width="9" stroke-linecap="round"/>')
    out += [
        f'<path d="{STEM}" fill="none" stroke="{c["stem"]}" stroke-width="12" stroke-linecap="round"/>',
        f'<path d="{LEAF_A}" fill="{c["leafA"]}"/>',
        f'<path d="{LEAF_B}" fill="{c["leafB"]}"/>',
    ]
    return "\n".join(out)


def place(body, cx, cy, scale):
    """Taruh mark 512 sehingga pusat bounding box (256,257) jatuh di (cx,cy)."""
    tx, ty = cx - 256 * scale, cy - 257 * scale
    return f'<g transform="translate({tx:.2f} {ty:.2f}) scale({scale})">\n{body}\n</g>'


def svg(w, h, body, defs="", title="Sabu Saku"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" '
            f'role="img" aria-label="{title}">\n<title>{title}</title>\n'
            f'{"<defs>" + defs + "</defs>" if defs else ""}\n{body}\n</svg>\n')


def bg_gradient(gid="bg"):
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{NAVY_LIGHT}"/><stop offset="1" stop-color="{NAVY_DEEP}"/>'
            f'</linearGradient>')


def save(name, content):
    with open(os.path.join(SVG_DIR, name), "w", encoding="utf-8") as f:
        f.write(content)


def png(svg_name, png_name, w=None, h=None):
    cairosvg.svg2png(url=os.path.join(SVG_DIR, svg_name), write_to=os.path.join(PNG_DIR, png_name),
                     output_width=w, output_height=h)


NAME = "SABU SAKU"
TAGLINE = "Satu Bulan Satu Buku"

# ---------- 1. Logo mark ----------
save("logo-mark.svg", svg(512, 512, mark("light"), title="Sabu Saku"))
save("logo-mark-reversed.svg", svg(512, 512, mark("reversed"), title="Sabu Saku"))
save("logo-mark-mono-white.svg", svg(512, 512, mark("mono"), title="Sabu Saku"))
mono_dark = mark("mono").replace("#FFFFFF", NAVY)
save("logo-mark-mono-navy.svg", svg(512, 512, mono_dark, title="Sabu Saku"))
png("logo-mark.svg", "logo-mark-1024.png", 1024, 1024)

# ---------- 2. Logo horizontal ----------
for variant, scheme, c_name, c_tag in (("", "light", NAVY, BLUE), ("-reversed", "reversed", "#FFFFFF", TAG_LIGHT)):
    d_name, w_name = text_path(BOLD, NAME, 140, tracking=4)
    d_tag, w_tag = text_path(MEDIUM, TAGLINE, 44, tracking=3)
    s = 0.85
    pad = 40
    mark_w = 372 * s
    gap = 40
    width = int(pad + mark_w + gap + max(w_name, w_tag) + pad)
    height = 380
    cy = height / 2
    body = place(mark(scheme), pad + mark_w / 2, cy, s)
    tx = pad + mark_w + gap
    body += f'\n<path transform="translate({tx:.2f} {cy - 4:.2f})" d="{d_name}" fill="{c_name}"/>'
    body += f'\n<path transform="translate({tx + 4:.2f} {cy + 62:.2f})" d="{d_tag}" fill="{c_tag}"/>'
    save(f"logo-horizontal{variant}.svg", svg(width, height, body))
png("logo-horizontal.svg", "logo-horizontal-2400.png", 2400)

# ---------- 3. Lockup bertumpuk (mark + nama), dasar splash ----------
def stacked(width, height, cx, mark_cy, mark_scale, name_size, name_base, tag_size, tag_base):
    d_name, w_name = text_path(BOLD, NAME, name_size, tracking=name_size * 0.03)
    d_tag, w_tag = text_path(MEDIUM, TAGLINE, tag_size, tracking=tag_size * 0.07)
    body = place(mark("reversed"), cx, mark_cy, mark_scale)
    body += f'\n<path transform="translate({cx - w_name / 2:.2f} {name_base})" d="{d_name}" fill="#FFFFFF"/>'
    body += f'\n<path transform="translate({cx - w_tag / 2:.2f} {tag_base})" d="{d_tag}" fill="{TAG_LIGHT}"/>'
    return body

# Splash penuh 1080x1920 (referensi desain + layar sambutan di dalam aplikasi)
body = f'<rect width="1080" height="1920" fill="url(#bg)"/>\n'
body += f'<circle cx="980" cy="160" r="360" fill="#FFFFFF" fill-opacity="0.04"/>\n'
body += f'<circle cx="80" cy="1800" r="420" fill="#FFFFFF" fill-opacity="0.04"/>\n'
body += stacked(1080, 1920, 540, 820, 1.25, 128, 1260, 44, 1340)
save("splash.svg", svg(1080, 1920, body, defs=bg_gradient(), title="Sabu Saku"))
png("splash.svg", "splash-1080x1920.png")

# Lockup transparan (flutter_native_splash `image`, dengan nama)
body = stacked(1152, 1152, 576, 400, 1.25, 128, 840, 44, 920)
save("splash-logo-with-name.svg", svg(1152, 1152, body, title="Sabu Saku"))
png("splash-logo-with-name.svg", "splash-logo-with-name.png")

# Ikon splash Android 12 (960x960, konten harus muat di lingkaran 640)
body = place(mark("reversed", with_lines=False), 480, 480, 1.1)
save("splash-android12-icon.svg", svg(960, 960, body, title="Sabu Saku"))
png("splash-android12-icon.svg", "splash-android12-icon.png")

# ---------- 4. Ikon aplikasi ----------
ICON_SCALE = 1.35  # sudut terjauh ~325px < radius zona aman 338px (lingkaran 66%)
bgrect = '<rect width="1024" height="1024" fill="url(#bg)"/>'
save("app-icon-background.svg", svg(1024, 1024, bgrect, defs=bg_gradient(), title="Sabu Saku"))
fg = place(mark("reversed", with_lines=False), 512, 512, ICON_SCALE)
save("app-icon-foreground.svg", svg(1024, 1024, fg, title="Sabu Saku"))
save("app-icon.svg", svg(1024, 1024, bgrect + "\n" + fg, defs=bg_gradient(), title="Sabu Saku"))
mono = place(mark("mono", with_lines=False), 512, 512, ICON_SCALE)
save("app-icon-monochrome.svg", svg(1024, 1024, mono, title="Sabu Saku"))
# Pratinjau bulat/rounded (hanya untuk dilihat, bukan untuk dipakai)
prev = (f'<clipPath id="r"><rect width="1024" height="1024" rx="230"/></clipPath>'
        f'<g clip-path="url(#r)">{bgrect}{fg}</g>')
save("app-icon-preview-rounded.svg", svg(1024, 1024, prev, defs=bg_gradient(), title="Sabu Saku"))

png("app-icon.svg", "app-icon-1024.png", 1024, 1024)
png("app-icon.svg", "playstore-icon-512.png", 512, 512)
png("app-icon-foreground.svg", "app-icon-foreground-1024.png", 1024, 1024)
png("app-icon-background.svg", "app-icon-background-1024.png", 1024, 1024)
png("app-icon-monochrome.svg", "app-icon-monochrome-1024.png", 1024, 1024)
png("app-icon-preview-rounded.svg", "app-icon-preview-rounded.png", 512, 512)
print("Selesai.")
