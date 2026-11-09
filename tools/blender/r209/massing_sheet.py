# Issue 209 round 2: the structure compare sheet (first deliverable, R140). Flat-shaded clay, no paint, the nine fixed views
# (bow / midship / stern, from the top, the side and below) for B0 (the concept's whole-hull generation, yaw fixed), round 1's
# Arm A and round 2's corrected structure, plus an overlay row: the new structure with B0's outline drawn over it in orange.
# usage: python3 massing_sheet.py FLAT_DIR CONCEPT_PNG OUT_JPG [CELLS, default b0,A,A2s] [TITLE]
import sys, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
D, CONCEPT, OUT = sys.argv[1:4]; CELLS = (sys.argv[4] if len(sys.argv) > 4 else 'b0,A,A2s').split(',')
TITLE = sys.argv[5] if len(sys.argv) > 5 else 'Issue 209 round 2: structure compare'
W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165); STUDIO = (52, 54, 60)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
NAMES = {'b0': 'B0  the concept as one generation (yaw fixed)', 'A': 'A round 1  hand build', 'A2s': 'Ab round 2  structure',
         'B3s': 'B3 round 2  core for the AI parts', 'A2': 'A round 2  detail rung', 'B3r2': 'B3 round 2  AI parts, detail rung',
         'A3s': 'Ab3 round 3  rounded, layered armour', 'A4s': 'Ab4 round 4  slab hull, silhouette first'}
def load(c, v):
    p = os.path.join(D, f'{c}_{v}.png'); return Image.open(p).convert('RGBA') if os.path.exists(p) else None
def flat(im):
    b = Image.new('RGBA', im.size, STUDIO + (255,)); b.alpha_composite(im); return b.convert('RGB')
def head(t, s):
    im = Image.new('RGB', (W, 120), BG); d = ImageDraw.Draw(im); d.text((24, 18), t, font=F(38, True), fill=FG); d.text((24, 72), s, font=F(23), fill=DIM); return im
def bar(t, right=''):
    im = Image.new('RGB', (W, 50), (28, 30, 36)); d = ImageDraw.Draw(im); d.text((16, 10), t, font=F(26, True), fill=FG)
    if right: d.text((W - 16, 14), right, font=F(21), fill=DIM, anchor='ra')
    return im
def fitw(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def bbox(ims, pad=16):
    box = None
    for im in ims:
        if im is None: continue
        a = np.asarray(im)[:, :, 3] > 8; ys, xs = np.where(a)
        if not len(xs): continue
        b = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    w, h = ims[0].size
    return (max(0, box[0] - pad), max(0, box[1] - pad), min(w, box[2] + pad), min(h, box[3] + pad))
def outline_over(base, ref, col=(255, 140, 0)):
    """base flat render with the silhouette edge of ref drawn over it (3 px)"""
    a = Image.fromarray(((np.asarray(ref)[:, :, 3] > 8) * 255).astype(np.uint8))
    e = np.asarray(a.filter(ImageFilter.MaxFilter(5))).astype(int) - np.asarray(a.filter(ImageFilter.MinFilter(5))).astype(int)
    out = np.asarray(flat(base)).copy(); out[e > 0] = col; return Image.fromarray(out)
def thirds(im, gap=4):
    w3 = im.width // 3; tiles = [fitw(im.crop((k * w3, 0, (k + 1) * w3, im.height)), W // 3 - gap) for k in range(3)]
    r = Image.new('RGB', (W, tiles[0].height + gap), BG)
    for k, t in enumerate(tiles): r.paste(t, (k * (W // 3) + gap // 2, gap // 2))
    return r
def stack(parts, name):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, (0, y)); y += p.height
    out.save(name, quality=88); print('sheet', name, out.size)

parts = [head(TITLE, 'Flat clay, no paint. Orange line: B0\'s outline over the new structure.')]
# hero row: the concept and each cell at the concept's angle, 2 by 2
c = Image.open(CONCEPT).convert('RGBA'); cb = Image.new('RGBA', c.size, BG + (255,)); cb.alpha_composite(c); con = cb.convert('RGB').crop((0, 100, 1024, 840))
HV = 'concept' if all(load(x, 'concept') is not None for x in CELLS) else 'hero'   # round 4: the concept's fitted camera
if HV == 'concept': con = cb.convert('RGB')
heroes = [load(x, HV) for x in CELLS]; hb = bbox([h for h in heroes if h is not None])
if HV == 'concept': con = con.crop(hb)   # same frame as the cells: the concept and the renders line up pixel for pixel
tiles = [('Concept', con)] + [(NAMES.get(x, x).split('  ')[0], flat(h.crop(hb))) for x, h in zip(CELLS, heroes) if h is not None]
tiles.append(('Overlay', outline_over(heroes[-1].crop(hb), heroes[0].crop(hb))))
for i in range(0, len(tiles), 2):
    row = Image.new('RGB', (W, 330), BG); d = ImageDraw.Draw(row)
    for k, (t, im) in enumerate(tiles[i:i + 2]):
        th = im.copy(); th.thumbnail((W // 2 - 8, 290)); row.paste(th, (k * W // 2 + 4 + (W // 2 - 8 - th.width) // 2, 36)); d.text((k * W // 2 + 12, 6), t, font=F(22, True), fill=FG)
    parts.append(row)
for v, title in (('side', 'Side (port)'), ('top', 'Top'), ('below', 'Below')):
    ims = [load(x, v) for x in CELLS]; bb = bbox([i for i in ims if i is not None])
    parts.append(head(title, 'Bow, midship, stern, left to right.' if v != 'below' else 'Looking up: stern, midship, bow, left to right.'))
    for x, im in zip(CELLS, ims):
        if im is None: continue
        parts += [bar(NAMES.get(x, x)), thirds(flat(im.crop(bb)))]
    parts += [bar('Overlay: ' + NAMES.get(CELLS[-1], CELLS[-1]).split('  ')[0] + ' with B0 outline'), thirds(outline_over(ims[-1].crop(bb), ims[0].crop(bb)))]
# round 4: the cross-section, looking aft from ahead of the bow (all cells side by side, same scale)
fr = [load(x, 'front') for x in CELLS]
if all(f is not None for f in fr):
    bb = bbox(fr); parts.append(head('Front (cross-section)', 'Looking aft from ahead of the bow; same scale.'))
    n = len(CELLS); tw = W // n - 6; row = Image.new('RGB', (W, 330), BG); d = ImageDraw.Draw(row)
    for k, (x, im) in enumerate(zip(CELLS, fr)):
        th = flat(im.crop(bb)); th.thumbnail((tw, 280)); row.paste(th, (k * (W // n) + 3 + (tw - th.width) // 2, 40))
        d.text((k * (W // n) + 10, 8), NAMES.get(x, x).split('  ')[0], font=F(22, True), fill=FG)
    parts.append(row)
stack(parts, OUT)
