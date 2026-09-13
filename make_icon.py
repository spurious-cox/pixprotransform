#!/usr/bin/env python3
"""
PixProTransform icon builder
Version: 1.0.0

Turns Tim's square artwork into a macOS icon set that follows Apple's icon
grid, then assembles PixProTransform.icns.

    ~/My_Applications/KBD/venv/bin/python make_icon.py [source.png]

(That venv is used because it has Pillow; the system python3 does not.)

Apple's rule for a macOS app icon is not "fill the canvas". On the 1024pt
grid the artwork sits in an 824x824 rounded square, centred, leaving a
100pt margin on every side. That margin is why Mac icons line up optically
in the Dock and in Finder instead of one looking oversized next to another.
A full-bleed square reads as foreign on macOS -- which is what the raw
artwork is, so it gets placed on the grid here rather than used directly.

Outputs, all under icon/:
    PixProTransform-1024.png    the source artwork, as supplied
    PixProTransform-grid.png    the same art placed on Apple's grid
    PixProTransform.iconset/    the ten PNGs iconutil wants
    PixProTransform.icns        the icon itself
"""

import os
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.join(HERE, "icon")
DEFAULT_SOURCE = os.path.expanduser(
    "~/Pictures/Pixelmator/PixProStuff/PixProTransform.png")

CANVAS = 1024
BODY = 824                      # Apple's macOS icon grid, square silhouette
CORNER_RADIUS = 0.2237          # of the body, not the canvas

ICONSET_FILES = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]


def place_on_grid(art):
    """Scale the artwork to the grid's body and round its corners."""
    art = art.convert("RGBA").resize((BODY, BODY), Image.LANCZOS)

    mask = Image.new("L", (BODY, BODY), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, BODY - 1, BODY - 1],
        radius=int(round(BODY * CORNER_RADIUS)), fill=255)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = (CANVAS - BODY) // 2
    canvas.paste(art, (offset, offset), mask)
    return canvas


def main(argv):
    source = argv[0] if argv else DEFAULT_SOURCE
    if not os.path.exists(source):
        print("error: no artwork at %s" % source, file=sys.stderr)
        return 1

    art = Image.open(source)
    if art.width != art.height:
        print("warning: artwork is %dx%d, not square" % (art.width, art.height),
              file=sys.stderr)

    os.makedirs(ICON_DIR, exist_ok=True)
    art.save(os.path.join(ICON_DIR, "PixProTransform-1024.png"))

    icon = place_on_grid(art)
    icon.save(os.path.join(ICON_DIR, "PixProTransform-grid.png"))

    iconset = os.path.join(ICON_DIR, "PixProTransform.iconset")
    os.makedirs(iconset, exist_ok=True)
    for filename, pixels in ICONSET_FILES:
        icon.resize((pixels, pixels), Image.LANCZOS).save(
            os.path.join(iconset, filename))

    icns = os.path.join(ICON_DIR, "PixProTransform.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns], check=True)
    print("source %dx%d -> %s (%d sizes)" % (
        art.width, art.height, icns, len(ICONSET_FILES)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
