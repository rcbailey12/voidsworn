# Issue 209 round 1: comparison sheets, 1080 px wide so they read on a phone. Runs anywhere with PIL (not inside Blender).
# usage: python3 sheets.py RENDER_DIR CELLS_JSON_DIR CONCEPT_PNG OUT_DIR [cells, default A,B0,B1,B2,B3]
import os, sys, json
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
R, J, CONCEPT, OUT = sys.argv[1:5]; CELLS = (sys.argv[5] if len(sys.argv) > 5 else 'A,B0,B1,B2,B3').split(',')
os.makedirs(OUT, exist_ok=True); W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
NAMES = {'A': 'A  hand build on AI underlay', 'B0': 'B0  whole hull, one generation', 'B1': 'B1  3 sections + parts',
         'B2': 'B2  6 sections + parts', 'B3': 'B3  parts on a hand-built core', 'B1r': 'B1r  3 raw-crop sections + parts'}
def meta(c):
    p = os.path.join(J, c + '.json'); return json.load(open(p)) if os.path.exists(p) else {}
def img(c, v):
    p = os.path.join(R, f'{c}_{v}.png'); return Image.open(p).convert('RGB') if os.path.exists(p) else None
def label(c):
    m = meta(c); t = f"{m.get('triangles', 0):,} tris, {m.get('surfaces', '?')} surfaces" if m else ''
    return NAMES.get(c, c), t
def head(title, sub):
    im = Image.new('RGB', (W, 120), BG); d = ImageDraw.Draw(im); d.text((24, 18), title, font=F(40, True), fill=FG); d.text((24, 72), sub, font=F(24), fill=DIM); return im
def bar(c, extra=''):
    im = Image.new('RGB', (W, 52), (28, 30, 36)); d = ImageDraw.Draw(im); a, b = label(c)
    d.text((16, 10), a, font=F(28, True), fill=FG); d.text((W - 16, 14), (b + ('  ' + extra if extra else '')).strip(), font=F(22), fill=DIM, anchor='ra'); return im
def stack(parts, name):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, (0, y)); y += p.height
    out.save(os.path.join(OUT, name), quality=88); print('sheet', name, out.size)
def fitw(im, w):
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def content_box(ims, pad=12):
    """the union box of everything that is not background, so every cell is cropped the same way"""
    import numpy as np
    box = None
    for im in ims:
        if im is None: continue
        a = np.asarray(im, dtype=np.int16); m = np.abs(a - np.median(a[:8, :8].reshape(-1, 3), 0)).max(2) > 22; ys, xs = np.where(m)
        if not len(xs): continue
        b = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    if box is None: return None
    w, h = ims[0].size
    return (max(0, int(box[0]) - pad), max(0, int(box[1]) - pad), min(w, int(box[2]) + pad), min(h, int(box[3]) + pad))

# 1. overview: the concept, then each cell at the concept's angle, paint and clay
parts = [head('Issue 209 round 1: C15s Hullbreaker cruiser', 'Same paint, lights and cameras on every cell. Each cell: paint, then clay.')]
c = Image.open(CONCEPT).convert('RGBA'); bgi = Image.new('RGBA', c.size, BG + (255,)); bgi.alpha_composite(c); c = bgi.convert('RGB').crop((0, 100, 1024, 840))
cb = Image.new('RGB', (W, 52), (28, 30, 36)); ImageDraw.Draw(cb).text((16, 10), 'Concept (the target)', font=F(28, True), fill=FG); parts += [cb, fitw(c, W)]
heroes = [img(x, 'hero') for x in CELLS] + [img(x, 'hero_clay') for x in CELLS]; hb = content_box(heroes)
for x in CELLS:
    a, b = img(x, 'hero'), img(x, 'hero_clay')
    if a is None: continue
    if hb: a, b = a.crop(hb), b.crop(hb)
    parts += [bar(x), fitw(a, W), fitw(b, W)]
stack(parts, 'overview.jpg')

# 2. battle crop: 1:1 at about 180 px of ship length (1080p), shown at 1:1 and 2x, with the blurred greyscale (Rec.709, sigma 7.5)
parts = [head('Battle distance', 'Left: 1:1 crop at about 180 px of ship. Middle: same, 2x. Right: blurred greyscale.')]
for x in CELLS:
    a = img(x, 'battle')
    if a is None: continue
    g = ImageOps.grayscale(a).filter(ImageFilter.GaussianBlur(7.5)).convert('RGB')
    r = Image.new('RGB', (W, 300), BG); z2 = a.crop((100, 65, 300, 195)).resize((400, 260), Image.NEAREST)
    r.paste(a.crop((50, 32, 350, 228)), (6, 52)); r.paste(z2, (318, 20)); r.paste(g.crop((50, 32, 350, 228)), (730, 52))
    parts += [bar(x), r]
stack(parts, 'battle.jpg')

# 3. nine-cell close range: one sheet per view; per cell a paint row and a clay row cut in bow / midship / stern thirds
for v, title in (('top', 'Close range: top'), ('side', 'Close range: side (port)'), ('below', 'Close range: below')):
    ims = [img(x, v) for x in CELLS] + [img(x, v + '_clay') for x in CELLS]; bb = content_box(ims)
    parts = [head(title, 'Bow, midship, stern left to right. Each cell: paint row, then clay row.')]
    for x in CELLS:
        rows = []
        for suf in ('', '_clay'):
            a = img(x, v + suf)
            if a is None: continue
            if bb: a = a.crop(bb)
            w3 = a.width // 3; r = None; tiles = [fitw(a.crop((k * w3, 0, (k + 1) * w3, a.height)), W // 3 - 4) for k in range(3)]
            r = Image.new('RGB', (W, tiles[0].height + 4), BG)
            for k, t in enumerate(tiles): r.paste(t, (k * (W // 3) + 2, 2))
            rows.append(r)
        if rows: parts += [bar(x)] + rows
    stack(parts, f'close_{v}.jpg')

# 4. break pieces pulled apart: does the route take the break lines, rim bands and liner cleanly?
parts = [head('Break test', 'Four break pieces pulled apart. Left: bow quarter. Right: stern quarter.')]
ims = [img(x, 'break') for x in CELLS] + [img(x, 'break2') for x in CELLS]; bb = content_box(ims)
for x in CELLS:
    a, b = img(x, 'break'), img(x, 'break2')
    if a is None: continue
    if bb: a, b = a.crop(bb), b.crop(bb)
    a, b = fitw(a, W // 2), fitw(b, W // 2); r = Image.new('RGB', (W, a.height), BG); r.paste(a, (0, 0)); r.paste(b, (W // 2, 0)); parts += [bar(x), r]
stack(parts, 'break.jpg')
