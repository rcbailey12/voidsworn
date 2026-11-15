# Issue 781 (R256: the S8 hull one step lighter): issue 756's three named pictures of the painted S8 (RULEBOOK 1.2: one picture
# per item, its code name on it, 1280 wide, no taller than 720), re-made from preview.py's renders, with the hull medians before
# and after written on the concept picture (MEDIANS: a json with concept_fitted, before and after, each fitted and battle).
# usage: python pictures.py PREVIEW_DIR OUT_DIR MEDIANS_JSON [note=...]
import os, sys
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
P, OUT, MED = sys.argv[1], sys.argv[2], sys.argv[3]
kw = dict(x.split('=', 1) for x in sys.argv[4:] if '=' in x)
import json
M = json.load(open(MED))
NOTE = kw.get('note', 'sandbox preview: Blender CPU, game light, battle lift 1.45 (look.gd)')
BG = (22, 22, 24); INK = (240, 232, 218); DIM = (176, 172, 166); ACC = (240, 170, 80)
CONCEPT = os.path.join(REPO, 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg')
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
    import numpy as np
    a = np.asarray(im.convert('L')); rows = np.where((a > 14).sum(1) > 4)[0]
    cy = int((rows.min() + rows.max()) / 2) if len(rows) else im.height // 2
    y0 = max(0, min(im.height - h, cy - h // 2)); return im.crop((0, y0, im.width, y0 + h))


def head(c, title, sub):
    d = ImageDraw.Draw(c); d.text((14, 8), title, fill=INK, font=F(22)); d.text((14, 36), sub, fill=DIM, font=F(14))


def label(c, xy, t):
    ImageDraw.Draw(c).text(xy, t, fill=ACC, font=F(15))


# 1. the painted ship beside the S8 concept at the fitted camera, the hull medians (sRGB, the ember left out) under it
c = Image.new('RGB', (1280, 590), BG)
head(c, 'voidsworn_S8 | Sunward paint beside the S8 concept, same fitted camera', NOTE)
con = Image.open(CONCEPT).convert('RGB'); bea = Image.open(os.path.join(P, 'paint_beauty.png')).convert('RGB').resize(con.size)
c.paste(fit(con, 632, 440), (4, 70)); c.paste(fit(bea, 632, 440), (644, 70))
label(c, (10, 52), 'S8 concept (colours sampled, never projected)'); label(c, (650, 52), 'S8 painted by the Sunward stack, one step lighter (R256)')
t = lambda v: '(%d,%d,%d)' % tuple(v)
d = ImageDraw.Draw(c)
d.text((14, 518), 'hull median, fitted camera: concept %s | paint before %s, after %s' % (t(M['concept_fitted']), t(M['before']['fitted']),
       t(M['after']['fitted'])), fill=INK, font=F(16))
d.text((14, 544), 'hull median, battle camera 34 degrees: before %s, after %s, target halfway to the concept %s' % (t(M['before']['battle']),
       t(M['after']['battle']), t(M['target_battle'])), fill=INK, font=F(16))
c.save(os.path.join(OUT, 'voidsworn_S8_paint_concept.jpg'), quality=92)

# 2. the radiator spires close, and the port broadside
c = Image.new('RGB', (1280, 718), BG)
head(c, 'voidsworn_S8 | the spires close (top) and the port broadside (bottom)', NOTE)
sp = Image.open(os.path.join(P, 'paint_spires.png')).convert('RGB').resize((1280, 720), Image.LANCZOS)
c.paste(band(sp, 340), (0, 58)); label(c, (10, 62), 'radiator spires: deep ember at the root to hot at the tip, under the glow threshold')
br = Image.open(os.path.join(P, 'paint_broad.png')).convert('RGB').resize((1280, 720), Image.LANCZOS)
c.paste(band(br, 316), (0, 402)); label(c, (10, 406), 'port broadside: forged plates and triangle panels, the five gun ports, frost running points, ember window slits')
c.save(os.path.join(OUT, 'voidsworn_S8_paint_spires_broadside.jpg'), quality=92)

# 3. the battle camera: 34 degrees above the board, port beam, range 170
c = Image.new('RGB', (1280, 716), BG)
head(c, 'voidsworn_S8 | battle camera: 34 degrees above the board, port beam, range 170', NOTE + '; bottom: the game\'s true pixel size')
bt = Image.open(os.path.join(P, 'paint_battle.png')).convert('RGB')
c.paste(band(bt, 470), (0, 58)); label(c, (10, 62), 'long lens (the sheet\'s battle camera), the ship filling the frame')
g = Image.open(os.path.join(P, 'paint_b170.png')).convert('RGB')
import numpy as np
a = np.asarray(g.convert('L')); ys, xs = np.where(a > 14)
cx, cy = (int(xs.mean()), int(ys.mean())) if len(xs) else (320, 180)
crop = g.crop((cx - 200, cy - 90, cx + 200, cy + 90))
c.paste(crop, (10, 530)); label(c, (14, 534), 'true pixels (1920 x 1080 screen)')
z = crop.crop((100, 45, 300, 135)).resize((400, 180), Image.NEAREST); c.paste(z, (440, 530)); label(c, (444, 534), 'the same, 2x')
c.save(os.path.join(OUT, 'voidsworn_S8_paint_battle.jpg'), quality=92)
# evidence: the forward deck and the port flank close (the triangle plates, rivet rows and frost markings at a judgeable size)
dp, fp = os.path.join(P, 'paint_deck.png'), os.path.join(P, 'paint_flank.png')
if os.path.exists(dp) and os.path.exists(fp):
    c = Image.new('RGB', (1280, 440), BG)
    head(c, 'voidsworn_S8 | close: the forward deck (left), the port flank (right)', NOTE)
    c.paste(fit(Image.open(dp).convert('RGB'), 636, 358), (0, 70)); c.paste(fit(Image.open(fp).convert('RGB'), 636, 358), (644, 70))
    label(c, (10, 52), 'triangle plates, rivet rows, the half-sun crest, the spine line'); label(c, (650, 52), 'flank plates, a frost running point, frost deck numbers')
    c.save(os.path.join(OUT, 'voidsworn_S8_paint_close.jpg'), quality=92)
for n in ('voidsworn_S8_paint_concept.jpg', 'voidsworn_S8_paint_spires_broadside.jpg', 'voidsworn_S8_paint_battle.jpg'):
    im = Image.open(os.path.join(OUT, n)); print(n, im.size); assert im.height <= 720
