# Issue 726: the named pictures (RULEBOOK 1.2: code name on each, 1280 wide, no taller than 720), from preview.py's renders and
# measure.py's numbers. Plain Python with Pillow.
# usage: python pictures.py OUT_DIR SHIP CONCEPT OLD_PREVIEW_DIR NEW_PREVIEW_DIR [MEASURE_JSON] [note=...]
#        (OLD_PREVIEW_DIR may be "-" when there is no old render: then the concept picture is concept | new)
import os, sys, json
from PIL import Image, ImageDraw, ImageFont

OUT, SHIP, CONCEPT, OLD, NEW = sys.argv[1:6]
rest = sys.argv[6:]; MJ = next((r for r in rest if r.endswith('.json')), None)
kw = dict(x.split('=', 1) for x in rest if '=' in x)
NOTE = kw.get('note', 'sandbox preview: Blender CPU, game light, battle lift 1.25; colours sampled from the concept, never projected')
BG = (22, 22, 24); INK = (240, 232, 218); DIM = (176, 172, 166); ACC = (240, 170, 80)
os.makedirs(OUT, exist_ok=True)


def F(n):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf'):
        if os.path.exists(p): return ImageFont.truetype(p, n)
    return ImageFont.load_default()


def flat(p):
    im = Image.open(p)
    if im.mode == 'RGBA':
        c = Image.new('RGB', im.size, BG); c.paste(im, mask=im.split()[3]); return c
    return im.convert('RGB')


def fit(im, w, h):
    k = min(w / im.width, h / im.height); im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    c = Image.new('RGB', (w, h), BG); c.paste(im, ((w - im.width) // 2, (h - im.height) // 2)); return c


def head(c, title, sub):
    d = ImageDraw.Draw(c); d.text((14, 8), title, fill=INK, font=F(22)); d.text((14, 36), sub, fill=DIM, font=F(14))


def label(c, xy, t):
    ImageDraw.Draw(c).text(xy, t, fill=ACC, font=F(15))


M = json.load(open(MJ)) if MJ else {}
con = flat(CONCEPT); new_b = flat(os.path.join(NEW, 'paint_beauty.png'))
if OLD != '-':
    old_b = flat(os.path.join(OLD, 'paint_beauty.png'))
    c = Image.new('RGB', (1280, 716), BG)
    head(c, f'{SHIP} | trophy patches (issue 726, R252): concept, old stack, new stack, same fitted camera', NOTE)
    cells = [(con, 'concept'), (old_b, 'old stack (main)'), (new_b, 'new stack (opus/issue-726)')]
    pos = [(0, 60), (640, 60), (0, 388)]
    for (im, t), (x, y) in zip(cells, pos):
        c.paste(fit(im, 636, 304), (x + 2, y + 22)); label(c, (x + 10, y + 2), t)
    d = ImageDraw.Draw(c); x, y = 650, 392
    label(c, (x, y), 'measured (measure.py, 960 px wide, glow left out)')
    rows = [('', 'concept', 'old', 'new'),
            ('mean value (0 to 255)', 'mean_value'), ('trophy patch area share', 'patch_share'),
            ('  pale', 'pale_patch_share'), ('  violet', 'violet_patch_share'),
            ('patch size, weighted (% of ship)', 'patch_size_weighted_pct'), ('10 largest patches (% of ship)', 'largest10_mean_pct'),
            ('patches counted', 'patches')]
    keys = [kw.get('kc', 'concept'), kw.get('ko', 'old'), kw.get('kn', 'new')]
    for i, r in enumerate(rows):
        yy = y + 28 + i * 34
        if i == 0:
            for j, t in enumerate(r[1:]): d.text((x + 330 + j * 92, yy), t, fill=INK, font=F(15))
            continue
        d.text((x, yy), r[0], fill=DIM, font=F(15))
        for j, k in enumerate(keys):
            v = M.get(k, {}).get(r[1], '')
            if isinstance(v, float) and r[1].endswith('share'): v = f'{v * 100:.1f}%'
            d.text((x + 330 + j * 92, yy), str(v), fill=INK, font=F(15))
    c.save(os.path.join(OUT, f'{SHIP}_726_concept.jpg'), quality=92)
else:
    c = Image.new('RGB', (1280, 520), BG)
    head(c, f'{SHIP} | trophy patches (issue 726, R252): concept and the new stack, same fitted camera', NOTE)
    c.paste(fit(con, 632, 440), (4, 74)); c.paste(fit(new_b, 632, 440), (644, 74))
    label(c, (10, 54), 'concept'); label(c, (650, 54), 'new stack (opus/issue-726)')
    c.save(os.path.join(OUT, f'{SHIP}_726_concept.jpg'), quality=92)
# the close views: deck and flank, old above new when there is an old render
dk, fl = 'paint_deck.png', 'paint_flank.png'
if os.path.exists(os.path.join(NEW, dk)):
    two = OLD != '-' and os.path.exists(os.path.join(OLD, dk))
    c = Image.new('RGB', (1280, 716 if two else 420), BG)
    head(c, f'{SHIP} | close: the deck (left) and the flank (right)' + (', old stack above, new below' if two else ', new stack'),
         'the trophy grid: cell sizes warped two thirds to twice, rows in stepped bands, a share split again (R240: no repeated tiles or aligned rows)')
    sets = ([(OLD, 'old'), (NEW, 'new')] if two else [(NEW, 'new')])
    for i, (D, t) in enumerate(sets):
        y = 60 + i * 330
        for j, n in enumerate((dk, fl)):
            p = os.path.join(D, n)
            if os.path.exists(p): c.paste(fit(flat(p), 636, 306), (j * 644, y + 22))
            label(c, (j * 644 + 8, y + 2), f'{t} stack, {"deck" if j == 0 else "flank"}')
    c.save(os.path.join(OUT, f'{SHIP}_726_close.jpg'), quality=92)
for n in os.listdir(OUT):
    if n.startswith(SHIP + '_726') and n.endswith('.jpg'):
        im = Image.open(os.path.join(OUT, n)); print(n, im.size); assert im.height <= 720 and im.width <= 1280
