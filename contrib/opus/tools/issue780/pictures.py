# Issue 780: the three named pictures of a painted Hegemony sheet ship (RULEBOOK 1.2: one picture per item, its code name on it,
# 1280 wide, no taller than 720). Plain Python with Pillow, from preview.py's renders.
# usage: python pictures.py PREVIEW_DIR OUT_DIR SHEET CONCEPT_JPG [note=...]
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

P, OUT, SHEET, CONCEPT = sys.argv[1:5]
kw = dict(x.split('=', 1) for x in sys.argv[5:] if '=' in x)
NOTE = kw.get('note', 'sandbox preview: Blender CPU, game light, Hegemony battle lift 0.4 (look.gd)')
BG = (16, 18, 24); INK = (226, 234, 244); DIM = (160, 170, 184); ACC = (120, 196, 255)
os.makedirs(OUT, exist_ok=True)


def F(n):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        if os.path.exists(p): return ImageFont.truetype(p, n)
    return ImageFont.load_default()


def fit(im, w, h):
    k = min(w / im.width, h / im.height); im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    c = Image.new('RGB', (w, h), BG); c.paste(im, ((w - im.width) // 2, (h - im.height) // 2)); return c


def band(im, h):
    """the middle h-high band of a picture, centred on its content (pixels brighter than the background)"""
    a = np.asarray(im.convert('L')); rows = np.where((a > 14).sum(1) > 4)[0]
    cy = int((rows.min() + rows.max()) / 2) if len(rows) else im.height // 2
    y0 = max(0, min(im.height - h, cy - h // 2)); return im.crop((0, y0, im.width, y0 + h))


def head(c, title, sub):
    d = ImageDraw.Draw(c); d.text((14, 8), title, fill=INK, font=F(22)); d.text((14, 36), sub, fill=DIM, font=F(14))


def label(c, xy, t):
    ImageDraw.Draw(c).text(xy, t, fill=ACC, font=F(15))


def img(n):
    return Image.open(os.path.join(P, n + '.png')).convert('RGB')


cell = SHEET.split('_')[-1]
# 1. the painted ship beside its concept at the fitted camera
c = Image.new('RGB', (1280, 520), BG)
head(c, f'{SHEET} | Hegemony paint beside the {cell} concept, same fitted camera', NOTE)
con = Image.open(CONCEPT).convert('RGB'); bea = img('paint_beauty').resize(con.size)
c.paste(fit(con, 632, 440), (4, 74)); c.paste(fit(bea, 632, 440), (644, 74))
label(c, (10, 56), f'{cell} concept (colours sampled from H10, never projected)'); label(c, (650, 56), f'{cell} painted by the Hegemony stack')
c.save(os.path.join(OUT, f'{SHEET}_paint_concept.jpg'), quality=92)

# 2. close: a module band, the port flank's blue line, the stern's nozzle row and one nozzle
c = Image.new('RGB', (1280, 692), BG)
head(c, f'{SHEET} | close: module band, blue line, nozzle row', NOTE)
c.paste(fit(img('paint_band'), 636, 300), (0, 74)); c.paste(fit(img('paint_flank'), 636, 300), (644, 74))
label(c, (10, 56), 'a module band: the even grid, the double seam, a latch row'); label(c, (650, 56), 'port flank: the blue line, broken at a band')
if os.path.exists(os.path.join(P, 'paint_stern_zoom.png')):
    c.paste(fit(img('paint_stern_zoom'), 636, 290), (0, 400)); label(c, (10, 382), 'stern-on: the flat row of rectangular nozzles')
if os.path.exists(os.path.join(P, 'paint_bell.png')):
    c.paste(fit(img('paint_bell'), 636, 290), (644, 400)); label(c, (650, 382), 'one nozzle close: housing, lip, blue-white throat')
c.save(os.path.join(OUT, f'{SHEET}_paint_close.jpg'), quality=92)

# 3. the battle camera: 34 degrees above the board, port beam, range 170
c = Image.new('RGB', (1280, 716), BG)
head(c, f'{SHEET} | battle camera: 34 degrees above the board, port beam, range 170', NOTE + '; bottom: the game\'s true pixel size')
c.paste(band(img('paint_battle'), 470), (0, 58)); label(c, (10, 62), 'long lens (the sheet\'s battle camera), the ship filling the frame')
g = img('paint_cam170')
a = np.asarray(g.convert('L')); ys, xs = np.where(a > 14)
cx, cy = (int(xs.mean()), int(ys.mean())) if len(xs) else (320, 180)
crop = g.crop((cx - 200, cy - 90, cx + 200, cy + 90))
c.paste(crop, (10, 530)); label(c, (14, 534), 'true pixels (1920 x 1080 screen)')
z = crop.crop((100, 45, 300, 135)).resize((400, 180), Image.NEAREST); c.paste(z, (440, 530)); label(c, (444, 534), 'the same, 2x')
c.save(os.path.join(OUT, f'{SHEET}_paint_battle.jpg'), quality=92)
for n in ('concept', 'close', 'battle'):
    im = Image.open(os.path.join(OUT, f'{SHEET}_paint_{n}.jpg')); print(n, im.size); assert im.height <= 720
