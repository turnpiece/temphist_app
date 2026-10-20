#!/usr/bin/env python3
"""Compose the Google Play listing graphics in the TempHist promo style.

usage: compose_play_graphics.py <raw_dir> <out_dir>

Writes into <out_dir>:
  icon-512.png             512x512 store icon: assets/logo.png on the navy icon
                           background, laid out like the iOS app icon (full
                           square; Play applies its own mask). 32-bit PNG.
  feature-graphic-1024x500.png
                           headline and subtitle on the promo gradient with two
                           phones (Today and Year) bleeding off the bottom.

<raw_dir> holds the emulator captures named as in compose_appstore_screenshots.py
(10-today.png, 13-year.png). Reuses that script's gradient, font and wrapping.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from compose_appstore_screenshots import (  # noqa: E402
    GREY, HOLDER_EDGE, HOLDER_FILL, WHITE, font, gradient, wrap,
)

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/logo.png"  # the multicoloured bars, transparent, flush left
ICON_BG = (0x24, 0x24, 0x56)  # ic_launcher_background
LOGO_X = 204  # puts the bars where the iOS app icon has them

W, H = 1024, 500


def icons(out: Path) -> None:
    canvas = Image.new("RGBA", (1024, 1024), ICON_BG + (255,))
    canvas.alpha_composite(Image.open(LOGO).convert("RGBA"), (LOGO_X, 0))
    canvas.resize((512, 512), Image.LANCZOS).save(out / "icon-512.png", optimize=True)


def phone(canvas: Image.Image, raw: Path, x: int, top: int, width: int) -> None:
    """Rounded dark holder with the capture inside, bleeding off the bottom."""
    inset = 6
    radius = int(width * 0.09)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rounded_rectangle((x - 2, top - 2, x + width + 2, H + 400), radius=radius + 2, fill=HOLDER_EDGE + (255,))
    ld.rounded_rectangle((x, top, x + width, H + 400), radius=radius, fill=HOLDER_FILL + (255,))
    canvas.paste(layer, (0, 0), layer)

    shot = Image.open(raw).convert("RGB")
    inner_w = width - 2 * inset
    shot = shot.resize((inner_w, int(shot.height * inner_w / shot.width)), Image.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *shot.size), radius=radius - inset, fill=255)
    canvas.paste(shot, (x + inset, top + inset), mask)


def feature_graphic(raw_dir: Path, out: Path) -> None:
    canvas = gradient(W, H)
    draw = ImageDraw.Draw(canvas)

    margin = 56
    text_w = 470
    head_font = font(54, 700)
    sub_font = font(23, 400)
    y = 118
    for line in wrap(draw, "Is it warmer than usual?", head_font, text_w):
        draw.text((margin, y), line, font=head_font, fill=WHITE)
        y += int(head_font.size * 1.1)
    y += 14
    for line in wrap(draw, "Any city in the world, against the past 50 years", sub_font, text_w):
        draw.text((margin, y), line, font=sub_font, fill=GREY)
        y += int(sub_font.size * 1.4)

    phone_w = 220
    phone(canvas, raw_dir / "13-year.png", 790, 120, phone_w)
    phone(canvas, raw_dir / "10-today.png", 545, 56, phone_w)

    canvas.save(out / "feature-graphic-1024x500.png", optimize=True)


def main() -> None:
    raw_dir, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    icons(out)
    feature_graphic(raw_dir, out)
    for f in sorted(out.glob("*.png")):
        print("wrote", f, Image.open(f).size)


if __name__ == "__main__":
    main()
