# Issue 1373: before/after sheet for the rebuilt strike craft (one row per craft, code names on it, 720 px tall).
#   python before_after_sheet.py SHOTS OUT.jpg REV
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

shots, out, rev = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
ROWS = [('ithar_fighter', 'GF1 The Needle', 'Glasswright fighter'), ('ithar_bomber', 'GB1 Needle bomber', 'Glasswright bomber'),
        ('chorus_spore', 'CS1BA2 spore, round G shell', 'Chorus spore'), ('hegemony_bomber', 'HB1 (HF1D family)', 'Navy bomber'),
        ('corsair_fighter', 'KF1 (KB1CC family)', 'Hullbreaker fighter')]
W, H = 1280, 720
sheet = Image.new('RGB', (W, H), (11, 14, 20))
d = ImageDraw.Draw(sheet)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)


def crop(im):
    g = im.convert('L').point(lambda v: 255 if v > 20 else 0)
    box = g.getbbox() or (0, 0) + im.size
    return im.crop((max(0, box[0] - 16), max(0, box[1] - 16), min(im.width, box[2] + 16), min(im.height, box[3] + 16)))


d.text((20, 10), 'Strike craft: code-built today vs. rebuilt from the faction part kits', fill=(235, 238, 245), font=F(24, True))
d.text((20, 42), f'Issue 1373 (R362) | rev {rev} | stage: SHEET BUILT + PAINT BAKE, cloud Godot (compatibility renderer, game look.gd + hull finish); not installed in game yet',
       fill=(160, 170, 185), font=F(13))
d.text((300, 66), 'NOW IN GAME (code boxes)', fill=(200, 200, 210), font=F(15, True))
d.text((800, 66), 'REBUILT FROM THE KIT', fill=(255, 214, 150), font=F(15, True))
rh = (H - 96) // len(ROWS)
for i, (key, code, what) in enumerate(ROWS):
    y = 92 + i * rh
    d.line((10, y - 2, W - 10, y - 2), fill=(40, 48, 60))
    d.text((20, y + rh // 2 - 22), what, fill=(235, 238, 245), font=F(16, True))
    d.text((20, y + rh // 2 + 2), code, fill=(255, 214, 150), font=F(13))
    for j, tag in enumerate(('old', 'new')):
        im = crop(Image.open(shots / f'{tag}_{key}.png').convert('RGB'))
        k = min(470 / im.width, (rh - 10) / im.height)
        im = im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)
        x0 = 240 + j * 510
        sheet.paste(im, (x0 + (500 - im.width) // 2, y + (rh - im.height) // 2))
sheet.save(out, quality=92)
