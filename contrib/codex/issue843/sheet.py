"""Arrange native Godot screenshots, with labelled nearest-neighbour details.

python sheet.py CAPTURE_DIR OUTPUT.jpg
"""
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

captures, output = map(Path, sys.argv[1:])
sheet = Image.new('RGB', (1280, 720), '#101014')
draw = ImageDraw.Draw(sheet)
font_path = 'C:/Windows/Fonts/segoeui.ttf'


def text(at, message, size=19, color='#dce1e7'):
    draw.text(at, message, font=ImageFont.truetype(font_path, size), fill=color)


text((20, 8), 'KB1CC | Squadron spacing follows the hull', 25)
text((20, 44), 'Same sheet mesh, flight phase and camera: range 170, FOV 45, 33.9 degrees above the board.', 17)
sources = {mode: Image.open(captures / (mode + '.png')).convert('RGB') for mode in ['before', 'after']}
bounds = []
for source in sources.values():
    background = Image.new('RGB', source.size, source.getpixel((0, 0)))
    mask = ImageChops.difference(source, background).convert('L').point(lambda v: 255 if v > 8 else 0)
    bounds.append(mask.getbbox())
assert all(bounds), 'Capture has no visible craft'
cx = (min(b[0] for b in bounds) + max(b[2] for b in bounds)) // 2
cy = (min(b[1] for b in bounds) + max(b[3] for b in bounds)) // 2
detail_box = (cx - 120, cy - 60, cx + 120, cy + 60)
assert all(b[0] >= detail_box[0] and b[1] >= detail_box[1] and b[2] <= detail_box[2] and b[3] <= detail_box[3] for b in bounds), 'Detail crop would clip the wing'
for x, mode, label in [(0, 'before', 'BEFORE | fixed formation'), (640, 'after', 'AFTER | measured hull clearance')]:
    source = sources[mode]
    text((x + 20, 78), label, 21)
    # The middle 640 x 280 pixels of the original 1080p frame, unchanged.
    native = source.crop((640, 400, 1280, 680))
    sheet.paste(native, (x, 112))
    text((x + 20, 116), 'Battle camera | native pixels', 15)
    detail = source.crop(detail_box).resize((480, 240), Image.Resampling.NEAREST)
    sheet.paste(detail, (x + 80, 440))
    text((x + 20, 408), 'KB1CC detail | 2x native pixels', 17)
text((20, 692), 'Unpainted issue 793 sheet geometry. Only formation spacing changes. Code: corsair_KB1CC.', 16)
output.parent.mkdir(parents=True, exist_ok=True)
sheet.save(output, quality=94)
print(output)
