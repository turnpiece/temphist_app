#!/usr/bin/env python3
"""Compose App Store screenshots in the TempHist promo style.

usage: compose_appstore_screenshots.py <raw_dir> <out_dir> <device: iphone69|iphone63|ipad13|androidphone|androidtablet10|androidtablet7>

Each raw simulator capture becomes a canvas of the exact App Store size: a
bold left-aligned headline and a grey subtitle on the dark navy gradient used
by the 1.2 promos, with the screenshot sitting in a rounded dark holder that
bleeds off the bottom. Output is flattened RGB PNG (no alpha), as App Store
Connect requires.

Raw frames are expected to be named as in FRAMES below, captured from:
  iphone69: iPhone 16 Pro Max simulator (1320x2868)
  ipad13:   iPad Pro 13-inch (M5) simulator (2064x2752)
  androidphone: Pixel_10 emulator (1080x2424), for Google Play (9:16 canvas,
            as Play rejects phone screenshots taller than 2:1)
  androidtablet10: Pixel_Tablet emulator in portrait (1600x2560), for the Play
            10-inch tablet slot
  androidtablet7: Nexus 7 (2013) emulator in portrait (1200x1920), for the Play
            7-inch tablet slot
with the status bar overridden (scripts/simulator_screenshots.sh) and the
app showing London, light appearance. iphone63 reuses the iPhone captures at
the 6.1"/6.3" canvas size (1206x2622).

Font: Sora (variable, SIL Open Font License), see scripts/fonts/README.md.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT = Path(__file__).parent / "fonts" / "Sora-Variable.ttf"

FRAMES = [  # (raw file, output name, headline, subtitle)
    ("10-today", "01-today", "Is today unusually warm?",
     "Today vs the same day over the past 50 years"),
    ("11-week", "02-week", "How was this week?",
     "The past week vs the same week over the past 50 years"),
    ("12-month", "03-month", "A month in context.",
     "The past month vs the same month over the past 50 years"),
    ("13-year", "04-year", "The year in perspective.",
     "The past year vs the same 12-month period over the past 50 years"),
    ("15-search-tokyo", "05-search", "Any city in the world.",
     "Search by name and see its temperature history"),
    ("14-picker", "06-picker", "Your places, one tap away.",
     "Your current location, places you've visited and popular cities"),
    ("16-share", "07-share", "Share what you find.",
     "Send any view as a link to a web page showing the same chart"),
]

# canvas (W, H); head/sub = font size as a fraction of W; holder_w = holder
# width as a fraction of W; holder_top = holder top edge as a fraction of H
DEVICES = {
    "iphone69": dict(size=(1320, 2868), head=0.079, sub=0.032, holder_w=0.80, holder_top=0.27),
    "iphone63": dict(size=(1206, 2622), head=0.079, sub=0.032, holder_w=0.80, holder_top=0.27),
    "ipad13": dict(size=(2064, 2752), head=0.058, sub=0.025, holder_w=0.78, holder_top=0.27),
    "androidphone": dict(size=(1080, 1920), head=0.079, sub=0.032, holder_w=0.80, holder_top=0.27),
    "androidtablet10": dict(size=(1600, 2560), head=0.065, sub=0.027, holder_w=0.82, holder_top=0.25),
    "androidtablet7": dict(size=(1200, 1920), head=0.07, sub=0.029, holder_w=0.80, holder_top=0.26),
}

BG_TOP, BG_BOTTOM = (24, 29, 90), (13, 17, 63)  # sampled from the 1.2 promos
WHITE, GREY = (255, 255, 255), (176, 184, 214)
HOLDER_FILL, HOLDER_EDGE = (9, 11, 32), (78, 86, 150)


def font(size: int, weight: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([weight])
    return f


def gradient(width: int, height: int) -> Image.Image:
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / (height - 1)
        colour = tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM))
        draw.line([(0, y), (width, y)], fill=colour)
    return img


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, max_w: int):
    """Greedy word wrap; when that gives exactly two lines, rebalance them so
    the second line isn't a single orphaned word."""
    lines, current = [], ""
    for word in text.split():
        trial = f"{current} {word}".strip()
        if draw.textlength(trial, font=fnt) <= max_w or not current:
            current = trial
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    if len(lines) == 2:
        words = text.split()
        best = min(
            range(1, len(words)),
            key=lambda i: max(
                draw.textlength(" ".join(words[:i]), font=fnt),
                draw.textlength(" ".join(words[i:]), font=fnt),
            ),
        )
        balanced = [" ".join(words[:best]), " ".join(words[best:])]
        if all(draw.textlength(l, font=fnt) <= max_w for l in balanced):
            return balanced
    return lines


def compose(raw: Path, headline: str, subtitle: str, cfg: dict) -> Image.Image:
    width, height = cfg["size"]
    canvas = gradient(width, height)
    draw = ImageDraw.Draw(canvas)
    margin = int(width * 0.07)
    max_w = width - 2 * margin

    head_font = font(int(width * cfg["head"]), 700)
    sub_font = font(int(width * cfg["sub"]), 400)
    y = int(height * 0.058)
    for line in wrap(draw, headline, head_font, max_w):
        draw.text((margin, y), line, font=head_font, fill=WHITE)
        y += int(head_font.size * 1.08)
    y += int(width * 0.022)
    for line in wrap(draw, subtitle, sub_font, int(max_w * 0.9)):
        draw.text((margin, y), line, font=sub_font, fill=GREY)
        y += int(sub_font.size * 1.4)

    # holder: dark bezel with a thin lighter edge, bleeding off the bottom
    holder_w = int(width * cfg["holder_w"])
    hx, hy = (width - holder_w) // 2, int(height * cfg["holder_top"])
    inset = max(10, int(width * 0.009))
    radius = int(holder_w * 0.075)
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rounded_rectangle((hx - 3, hy - 3, hx + holder_w + 3, height + 400),
                         radius=radius + 3, fill=HOLDER_EDGE + (255,))
    ld.rounded_rectangle((hx, hy, hx + holder_w, height + 400),
                         radius=radius, fill=HOLDER_FILL + (255,))
    canvas.paste(layer, (0, 0), layer)

    shot = Image.open(raw).convert("RGB")
    inner_w = holder_w - 2 * inset
    inner_h = int(shot.height * inner_w / shot.width)
    shot = shot.resize((inner_w, inner_h), Image.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *shot.size), radius=radius - inset, fill=255)
    canvas.paste(shot, (hx + inset, hy + inset), mask)
    return canvas


def main() -> None:
    raw_dir, out_dir, device = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    cfg = DEVICES[device]
    out_dir.mkdir(parents=True, exist_ok=True)
    for raw_name, out_name, headline, subtitle in FRAMES:
        raw = raw_dir / f"{raw_name}.png"
        if not raw.exists():
            print("missing", raw)
            continue
        img = compose(raw, headline, subtitle, cfg)
        assert img.size == cfg["size"], img.size
        img.save(out_dir / f"{out_name}.png", optimize=True)
        print("wrote", out_dir / f"{out_name}.png", img.size)


if __name__ == "__main__":
    main()
