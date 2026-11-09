# Issue 209 round 4: silhouette.jpg, the concept's outline over each cell at the concept's own fitted camera, with the score.
# Per cell: the red / green overlay from silhouette4.py (green both, red concept only = missing, yellow cell only = extra) and, when the
# cell has a 'concept' render, its clay render with the concept's outline drawn over it. Round 3 against round 4, B0 for reference.
# usage: python3 silsheet4.py SIL_DIR CONCEPT_PNG OUT_JPG CELLS(comma) [RENDER_DIRS(comma)]
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
D, CONCEPT, OUT = sys.argv[1:4]; CELLS = sys.argv[4].split(','); RD = sys.argv[5].split(',') if len(sys.argv) > 5 else []
W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
NAMES = {'B0': 'B0  the concept as one generation (reference)', 'Ab3': 'Ab3  round 3', 'Hy3': 'Hy3  round 3',
         'Ab4': 'Ab4  round 4, slab hull', 'Hy4': 'Hy4  round 4, slab hull + AI parts'}
S = json.load(open(os.path.join(D, 'silhouette_scores.json'))); cam = json.load(open(os.path.join(D, 'concept_camera.json')))

def head(t, s):
    im = Image.new('RGB', (W, 150), BG); d = ImageDraw.Draw(im); d.text((24, 18), t, font=F(38, True), fill=FG)
    for k, line in enumerate(s.split('\n')): d.text((24, 72 + k * 30), line, font=F(22), fill=DIM)
    return im
def bar(t, right=''):
    im = Image.new('RGB', (W, 52), (28, 30, 36)); d = ImageDraw.Draw(im); d.text((16, 10), t, font=F(27, True), fill=FG)
    if right: d.text((W - 16, 12), right, font=F(24, True), fill=(120, 220, 140), anchor='ra')
    return im
def note(t, h=38):
    im = Image.new('RGB', (W, h), BG); ImageDraw.Draw(im).text((16, 8), t, font=F(20), fill=DIM); return im
def fitw(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)

cm = np.asarray(Image.open(CONCEPT).convert('RGBA'))[:, :, 3] > 128
ys, xs = np.nonzero(cm); box = (max(0, xs.min() - 40), max(0, ys.min() - 40), min(1024, xs.max() + 40), min(1024, ys.max() + 40))
cmi = Image.fromarray((cm * 255).astype(np.uint8))
edge = (np.asarray(cmi.filter(ImageFilter.MaxFilter(5))).astype(int) - np.asarray(cmi.filter(ImageFilter.MinFilter(5))).astype(int)) > 0

def render(c):
    for d in RD:
        p = os.path.join(d, f'{c}_concept_clay.png')
        if os.path.exists(p): return Image.open(p).convert('RGB')

p = cam['camera']
parts = [head('Silhouette against the concept', 'The concept outline at its own camera (fitted to the concept image through B0: %.0f%% overlap).\n'
              'Green: both. Red: concept only (missing). Yellow: cell only (extra). Score: overlap (intersection over union).' % (100 * cam['b0_iou']))]
legend = Image.new('RGB', (W, 44), BG); d = ImageDraw.Draw(legend); x = 16
for col, t in (((40, 190, 70), 'both'), ((215, 45, 40), 'concept only (missing)'), ((235, 200, 40), 'cell only (extra)'), ((255, 140, 0), 'concept outline')):
    d.rectangle((x, 12, x + 22, 34), fill=col); d.text((x + 30, 10), t, font=F(20), fill=FG); x += 60 + int(d.textlength(t, font=F(20)))
parts.append(legend)
for c in CELLS:
    if c not in S: continue
    s = S[c]; parts.append(bar(NAMES.get(c, c), f"{s['overlap']:.1f}% overlap"))
    ov = Image.open(os.path.join(D, f'sil_{c}.png')).convert('RGB').crop(box)
    r = render(c)
    if r is not None:
        a = np.asarray(r).copy(); a[edge] = (255, 140, 0); r = Image.fromarray(a).crop(box)
        h = round(ov.height * (W // 2 - 6) / ov.width); row = Image.new('RGB', (W, h + 6), BG)
        row.paste(fitw(ov, W // 2 - 6), (3, 3)); row.paste(fitw(r, W // 2 - 6), (W // 2 + 3, 3)); parts.append(row)
    else: parts.append(fitw(ov, W))
    parts.append(note(f"covers {s['concept_covered']:.1f}% of the concept outline; {s['cell_outside']:.1f}% of the cell lies outside it"))
rows = [(c, S[c]) for c in CELLS if c in S]
t = Image.new('RGB', (W, 60 + 40 * len(rows)), BG); d = ImageDraw.Draw(t)
for k, h in enumerate(('Cell', 'Overlap', 'Concept covered', 'Cell outside')):
    d.text((16 + [0, 430, 610, 850][k], 16), h, font=F(22, True), fill=FG)
for i, (c, s) in enumerate(rows):
    y = 60 + 40 * i
    for k, v in enumerate((NAMES.get(c, c).split('  ')[0], f"{s['overlap']:.1f}%", f"{s['concept_covered']:.1f}%", f"{s['cell_outside']:.1f}%")):
        d.text((16 + [0, 430, 610, 850][k], y), v, font=F(22), fill=FG if k else DIM)
parts += [bar('Scores'), t]
h = sum(q.height for q in parts); out = Image.new('RGB', (W, h), BG); y = 0
for q in parts: out.paste(q, (0, y)); y += q.height
out.save(OUT, quality=88); print('sheet', OUT, out.size)
