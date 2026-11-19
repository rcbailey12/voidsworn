# R341: one sheet per Chorus ship for Ryan, 1920 x 720: the current look (top row) above the armoured look (bottom row), at
# the battle camera's distance 170 and 26 and one close-up of the skin, each tile 640 x 360 with its label, the code name on it.
# usage: python3 make_sheet.py VIEWS_DIR CELL CODE_NAME GAME_SHIP BEFORE_TAG AFTER_TAG OUT.jpg
import sys
from PIL import Image, ImageDraw, ImageFont

views, cell, code, game, before, after, out = sys.argv[1:8]
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
try:
    f_lab, f_code = ImageFont.truetype(FONT, 17), ImageFont.truetype(BOLD, 22)
except OSError:
    f_lab = f_code = ImageFont.load_default()
cols = (('R170', 'battle camera, distance 170 (true size)'), ('R26', 'battle camera, distance 26'), ('close', 'close-up of the skin'))
rows = ((before, 'NOW'), (after, 'R341 ARMOUR'))
sheet = Image.new('RGB', (1920, 720), (12, 12, 14))
d = ImageDraw.Draw(sheet)
for r, (tag, row_name) in enumerate(rows):
    for c, (view, what) in enumerate(cols):
        im = Image.open('%s/%s_%s_%s.png' % (views, cell, tag, view)).convert('RGB').resize((640, 360))
        x0, y0 = 640 * c, 360 * r
        sheet.paste(im, (x0, y0))
        label = '%s  |  %s' % (row_name, what)
        w = d.textlength(label, font=f_lab)
        d.rectangle((x0, y0 + 360 - 28, x0 + w + 16, y0 + 360), fill=(0, 0, 0))
        d.text((x0 + 8, y0 + 360 - 25), label, fill=(235, 225, 200), font=f_lab)
for x in (640, 1280):
    d.line((x, 0, x, 720), fill=(70, 70, 70), width=2)
d.line((0, 360, 1920, 360), fill=(70, 70, 70), width=2)
title = '%s (%s)  R341 armour shell, before and after' % (code, game)
w = d.textlength(title, font=f_code)
d.rectangle((0, 0, w + 20, 34), fill=(0, 0, 0))
d.text((10, 5), title, fill=(255, 210, 120), font=f_code)
sheet.save(out, quality=90)
print('[r341] sheet', out)
