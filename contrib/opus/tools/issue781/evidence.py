# Issue 781 evidence picture (for the Board's ruling; RULEBOOK 1.2: the code name on it, 1280 wide, no taller than 720): the S8
# concept against the painted S8 as on main, with the R256 iron step tried at .60, and the what-if of the whole albedo x2.4 (the
# lightening "halfway at the battle camera" asks for), each at the fitted camera (top) and the battle camera (bottom), with the
# hull medians from measure.py written under each.
# usage: python evidence.py OUT.jpg LABEL=PREVIEW_DIR=MEASURE_JSON ...     (Python with Pillow and numpy)
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
OUT = sys.argv[1]; COLS = [a.split('=', 2) for a in sys.argv[2:]]
BG = (22, 22, 24); INK = (240, 232, 218); DIM = (176, 172, 166); ACC = (240, 170, 80)
CON = os.path.join(REPO, 'contrib/codex/design/concept_round5_2026_11/')


def F(n):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        if os.path.exists(p): return ImageFont.truetype(p, n)
    return ImageFont.load_default()


def fit(im, w, h):
    k = min(w / im.width, h / im.height); im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    c = Image.new('RGB', (w, h), BG); c.paste(im, ((w - im.width) // 2, (h - im.height) // 2)); return c


def crop_ship(im, pad=12):
    a = np.asarray(im.convert('L')); ys, xs = np.where(a > 14)
    return im.crop((max(0, xs.min() - pad), max(0, ys.min() - pad), min(im.width, xs.max() + pad), min(im.height, ys.max() + pad)))


t = lambda v: '(%d,%d,%d)' % tuple(v)
n = len(COLS) + 1; W = 1280 // n; TH, BH = 214, 150
c = Image.new('RGB', (1280, 92 + TH + 46 + BH + 50), BG); d = ImageDraw.Draw(c)
d.text((12, 8), 'voidsworn_S8 | issue 781: how far the iron can lighten (sandbox, 1024 maps, game light, lift 1.45)', fill=INK, font=F(20))
d.text((12, 36), 'top: the fitted camera (the concept\'s); bottom: the battle camera, 34 degrees. Medians: sRGB, ember left out.', fill=DIM, font=F(14))
y1 = 82; y2 = y1 + 20 + TH + 26
M0 = json.load(open(COLS[0][2]))
d.text((6, 62), 'S8 concept', fill=ACC, font=F(15))
c.paste(fit(Image.open(CON + 'voidsworn_S8_beauty.jpg').convert('RGB'), W - 8, TH), (4, y1))
d.text((6, y1 + TH + 4), 'median ' + t(M0['fitted']['concept_median']), fill=INK, font=F(14))
d.text((6, y2 - 20), 'sheet side view (no battle view)', fill=ACC, font=F(13))
sh = Image.open(CON + 'voidsworn_S8_sheet.jpg').convert('RGB'); sh = sh.crop((0, sh.height // 2, sh.width, sh.height))
c.paste(fit(sh, W - 8, BH), (4, y2))
for k, (lab, pv, mj) in enumerate(COLS):
    M = json.load(open(mj)); x = (k + 1) * W
    d.text((x + 6, 62), lab, fill=ACC, font=F(15))
    c.paste(fit(crop_ship(Image.open(os.path.join(pv, 'paint_beauty.png')).convert('RGB')), W - 8, TH), (x + 4, y1))
    d.text((x + 6, y1 + TH + 4), 'median ' + t(M['fitted']['paint_median']), fill=INK, font=F(14))
    c.paste(fit(crop_ship(Image.open(os.path.join(pv, 'paint_battle.png')).convert('RGB')), W - 8, BH), (x + 4, y2))
    d.text((x + 6, y2 + BH + 4), 'median ' + t(M['battle']['paint_median']), fill=INK, font=F(14))
d.text((12, c.height - 24), 'battle target "halfway to the concept": ' + t(M0['target_battle']) + ' (from the 2048 battle median (26,27,28) and the concept\'s fitted median)',
       fill=DIM, font=F(14))
c.save(OUT, quality=92); print(OUT, c.size); assert c.height <= 720
