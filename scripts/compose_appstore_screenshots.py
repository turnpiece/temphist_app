#!/usr/bin/env python3
"""Compose captioned App Store screenshots from raw simulator captures.

usage: compose_appstore_screenshots.py <raw_dir> <out_dir> <device: iphone|ipad>

Each frame becomes a canvas of the exact App Store size: a caption band on
the frame's own background colour, with the raw screenshot below it (rounded
corners). Output is flattened RGB PNG (no alpha), as App Store Connect needs.

Raw frames are expected to be named as in FRAMES below, captured from:
  iPhone: iPhone 16 Pro Max simulator (1320x2868, App Store 6.9")
  iPad:   iPad Pro 13-inch (M5) simulator (2064x2752)
with the status bar overridden (scripts/simulator_screenshots.sh) and the
app showing London, light appearance.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FRAMES = [  # (raw file, output name, caption)
    ("10-today", "01-today", "Today vs the same day\nover the past 50 years"),
    ("11-week", "02-week", "The past week vs the same\nweek over the past 50 years"),
    ("12-month", "03-month", "The past month vs the same\nmonth over the past 50 years"),
    ("13-year", "04-year", "The past year vs the same 12-month\nperiod over the past 50 years"),
    ("15-search-tokyo", "05-search", "Search any city\nin the world"),
    ("14-picker", "06-picker", "Your places, popular\ncities, recent searches"),
    ("16-share", "07-share", "Share any view\nwith a link"),
]

# canvas (W, H), caption band height as a fraction of W, screenshot scale,
# starting font size as a fraction of W (shrunk to fit, see fit_font_size)
DEVICES = {
    "iphone": dict(size=(1320, 2868), band=0.30, scale=0.92, font=0.072),
    "ipad": dict(size=(2064, 2752), band=0.17, scale=0.86, font=0.052),
}

FONT_PATH = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_BOLD_INDEX = 1


def rounded(im: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *im.size), radius=radius, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def fit_font_size(cfg: dict) -> int:
    """One font size for the whole set: the largest at which every caption fits."""
    width = cfg["size"][0]
    size = int(width * cfg["font"])
    limit = width * 0.90
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    while size > 20:
        font = ImageFont.truetype(FONT_PATH, size, index=FONT_BOLD_INDEX)
        widest = max(
            probe.textlength(line, font=font)
            for _, _, caption in FRAMES
            for line in caption.split("\n")
        )
        if widest <= limit:
            break
        size -= 2
    return size


def compose(raw: Path, caption: str, cfg: dict) -> Image.Image:
    width, height = cfg["size"]
    shot = Image.open(raw).convert("RGB")
    bg = shot.getpixel((shot.width // 2, 12))  # the app's own top background colour
    canvas = Image.new("RGB", (width, height), bg)

    band_h = int(width * cfg["band"])
    font = ImageFont.truetype(FONT_PATH, cfg["font_px"], index=FONT_BOLD_INDEX)
    draw = ImageDraw.Draw(canvas)
    lines = caption.split("\n")
    line_h = int(font.size * 1.18)
    y = (band_h - line_h * len(lines)) // 2 + int(width * 0.02)
    for line in lines:
        w = draw.textlength(line, font=font)
        draw.text(((width - w) / 2, y), line, font=font, fill=(255, 255, 255))
        y += line_h

    sw = int(width * cfg["scale"])
    sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    framed = rounded(shot, radius=int(sw * 0.055))
    canvas.paste(framed, ((width - sw) // 2, band_h), framed)
    return canvas


def main() -> None:
    raw_dir, out_dir, device = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    cfg = dict(DEVICES[device])
    cfg["font_px"] = fit_font_size(cfg)
    print("caption font size:", cfg["font_px"])
    out_dir.mkdir(parents=True, exist_ok=True)
    for raw_name, out_name, caption in FRAMES:
        raw = raw_dir / f"{raw_name}.png"
        if not raw.exists():
            print("missing", raw)
            continue
        img = compose(raw, caption, cfg)
        assert img.size == cfg["size"], img.size
        img.save(out_dir / f"{out_name}.png", optimize=True)
        print("wrote", out_dir / f"{out_name}.png", img.size)


if __name__ == "__main__":
    main()
