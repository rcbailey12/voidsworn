"""Place the two stamped c170 look-bench shield strips on one review sheet."""

import argparse
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools"))
from picture_provenance import Review

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("fitted", type=Path)
parser.add_argument("egg", type=Path)
parser.add_argument("out", type=Path)
args = parser.parse_args()

sheet = Image.new("RGB", (1280, 628), "#10151e")
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 22)
review = Review("installed in game")
for y, source, label in [
    (0, args.fitted, "H9_23  /  FITTED DEFAULT  /  CAMERA 170"),
    (260, args.egg, "H9_23  /  EGG OPTION  /  CAMERA 170"),
]:
    strip = review.open(source)
    draw.text((40, y + 5), label, fill="#f1e8d9", font=font)
    sheet.paste(strip, (40, y + 36))
    for cell, time in enumerate(["Torpedo impact", "+0.1 s", "+0.3 s", "+0.6 s"]):
        draw.text((50 + 300 * cell, y + 237), time, fill="#f1e8d9", font=font)
review.save(sheet, args.out)
