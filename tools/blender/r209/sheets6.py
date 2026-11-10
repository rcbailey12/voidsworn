# Issue 209 round 6: the sheets (1080 px wide, phone-readable).
#   paint.jpg     the concept, Ab5 and Ab6 at the concept's own camera under the concept rig (the concept painting's light: high key,
#                 weak fill), plus Ab6 under the studio rig every earlier round used; region colour samples against the concept
#   weapons.jpg   per weapon group, the same crop of the concept camera: the concept (scaled 4x), Ab5, Ab6 (concept rig), Ab6 clay
#   overview.jpg  Ab6 in paint and clay at the concept camera, side, top and below (studio rig)
#   battle.jpg    Ab5 and Ab6 at the battle camera: 1:1, 2x, blurred greyscale
#   silhouette.jpg the concept outline over Ab5 and Ab6 with the scores (silhouette4.py overlays)
# usage: python3 sheets6.py OUT6_DIR OUT5B_DIR CONCEPT_RGBA_PNG SIL_DIR SHEET_DIR
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
O6, O5, CONCEPT, SIL, OUT = sys.argv[1:6]
os.makedirs(OUT, exist_ok=True); W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
REG = dict(bow_side=(100, 560, 180, 620), bow_deck=(200, 470, 300, 520), bow_lower=(100, 640, 200, 690), cas_plate=(200, 530, 240, 560),
           aft_top=(700, 380, 850, 420), aft_side=(640, 430, 760, 470), sponson=(520, 470, 600, 560), drum=(540, 390, 600, 410), cargo=(700, 480, 780, 560))
CLOSE = dict(cas=(170, 470, 510, 700, 'Bow casemates'), bow=(130, 380, 410, 530, 'Twin bow guns'), drums=(330, 250, 730, 460, 'Drum racks and tower'),
             aft=(680, 200, 1010, 430, 'Aft drums and turrets'))

def head(title, sub):
    im = Image.new('RGB', (W, 120), BG); d = ImageDraw.Draw(im); d.text((24, 18), title, font=F(38, True), fill=FG); d.text((24, 72), sub, font=F(23), fill=DIM); return im
def tbar(t, right=''):
    im = Image.new('RGB', (W, 52), (28, 30, 36)); d = ImageDraw.Draw(im); d.text((16, 10), t, font=F(27, True), fill=FG)
    if right: d.text((W - 16, 14), right, font=F(21), fill=DIM, anchor='ra')
    return im
def note(t, h=40):
    im = Image.new('RGB', (W, h), BG); ImageDraw.Draw(im).text((16, 8), t, font=F(20), fill=DIM); return im
def stack(parts, name):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, (0, y)); y += p.height
    out.save(os.path.join(OUT, name), quality=88); print('sheet', name, out.size)
def fitw(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def row(ims, labels=None, gap=6):
    n = len(ims); w = (W - gap * (n + 1)) // n; ims = [fitw(i, w) for i in ims]; h = max(i.height for i in ims)
    out = Image.new('RGB', (W, h + (34 if labels else 0) + gap), BG); d = ImageDraw.Draw(out)
    for k, im in enumerate(ims):
        x = gap + k * (w + gap); out.paste(im, (x, gap))
        if labels: d.text((x + 4, h + gap + 4), labels[k], font=F(20, True), fill=FG)
    return out
def concept_rgb():
    c = Image.open(CONCEPT).convert('RGBA'); b = Image.new('RGBA', c.size, BG + (255,)); b.alpha_composite(c); return b.convert('RGB')
def load(p): return Image.open(p).convert('RGB') if os.path.exists(p) else None
def crop_box(ims, pad=20):
    a = np.zeros(ims[0].size[::-1], bool)
    for im in ims:
        x = np.asarray(im, np.int16); a |= np.abs(x - np.median(x[:8, :8].reshape(-1, 3), 0)).max(2) > 22
    ys, xs = np.nonzero(a); w, h = ims[0].size
    return (max(0, xs.min() - pad), max(0, ys.min() - pad), min(w, xs.max() + pad), min(h, ys.max() + pad))
def means(im):
    a = np.asarray(im.resize((1024, 1024))).astype(float); return {k: a[y0:y1, x0:x1].reshape(-1, 3).mean(0) for k, (x0, y0, x1, y1) in REG.items()}

# ---------------------------------------------------------------------------------------------------------------- paint
C = concept_rgb(); A5c = load(f'{O6}/r/Ab5_concept_cl.png'); A6c = load(f'{O6}/r/Ab6_concept_cl.png'); A6s = load(f'{O6}/r/Ab6_concept.png')
box = crop_box([C, A6c]); cc = [i.crop(box) for i in (C, A5c, A6c, A6s)]
mc, m5, m6 = means(C), means(A5c), means(A6c)
tab = Image.new('RGB', (W, 40 + 30 * len(REG)), BG); d = ImageDraw.Draw(tab)
d.text((16, 6), 'Region colours (mean sRGB):   concept   |   Ab5   |   Ab6   (concept rig)', font=F(20, True), fill=FG)
for k, n in enumerate(REG):
    y = 38 + 30 * k; d.text((16, y), n.replace('_', ' '), font=F(19), fill=DIM)
    for j, m in enumerate((mc, m5, m6)):
        v = tuple(int(x) for x in m[n]); x = 230 + j * 280; d.rectangle((x, y + 2, x + 40, y + 24), fill=v); d.text((x + 50, y + 2), str(v), font=F(18), fill=DIM)
stack([head('Paint against the concept', 'Same camera as the concept. Concept rig: one high key, weak fill (the painting\'s own light).'),
       row(cc[:2], ['Concept', 'Ab5 (round 5 paint)']), row(cc[2:], ['Ab6 (round 6 paint), concept rig', 'Ab6, studio rig (rounds 1 to 5)']), tab], 'paint.jpg')

# ---------------------------------------------------------------------------------------------------------------- weapons close-up
parts = [head('Weapons close up', 'The same crop of the concept camera for each: concept (4x), Ab5, Ab6, Ab6 clay.')]
for k, (x0, y0, x1, y1, title) in CLOSE.items():
    cc = C.crop((x0, y0, x1, y1)).resize(((x1 - x0) * 4, (y1 - y0) * 4), Image.LANCZOS)
    a5 = load(f'{O6}/close/Ab5_{k}_concept.png'); a6 = load(f'{O6}/close/Ab6_{k}_concept.png'); a6c = load(f'{O6}/close/Ab6_{k}_clay.png')
    ims = [i for i in (cc, a5, a6, a6c) if i is not None]
    parts += [tbar(title), row(ims[:2], ['Concept', 'Ab5']), row(ims[2:], ['Ab6', 'Ab6 clay'])]
stack(parts, 'weapons.jpg')

# ---------------------------------------------------------------------------------------------------------------- overview
ov = [load(f'{O6}/r/Ab6_{v}.png') for v in ('concept', 'concept_clay', 'side', 'side_clay', 'top', 'below')]
b2 = crop_box([ov[0], ov[1]]); top = [i.crop(b2) for i in ov[:2]]
bs = crop_box(ov[2:4]); sides = [i.crop(bs) for i in ov[2:4]]
bt = crop_box(ov[4:6]); tb = [i.crop(bt) for i in ov[4:6]]
stack([head('Ab6 overview', 'Studio rig. Concept camera, side, top and below; paint and clay.'), row(top, ['Concept camera, paint', 'Clay']),
       row(sides[:1], ['Side']), row(sides[1:], ['Side, clay']), row(tb, ['Top', 'Below'])], 'overview.jpg')

# ---------------------------------------------------------------------------------------------------------------- battle
rows = [head('Battle distance', 'The battle camera, ship about 180 px long at 1080p: 1:1, 2x, blurred greyscale.')]
for c, d_ in (('Ab5', O5), ('Ab6', O6)):
    im = load(f'{d_}/r/{c}_battle.png')
    if im is None: continue
    g = ImageOps.grayscale(im).filter(ImageFilter.GaussianBlur(2.2)).convert('RGB')
    rows += [tbar(c), row([im, im.resize((im.width * 2, im.height * 2), Image.NEAREST).crop((im.width // 2, im.height // 2, im.width * 3 // 2, im.height * 3 // 2)), g], ['1:1', '2x', 'blurred grey'])]
stack(rows, 'battle.jpg')

# ---------------------------------------------------------------------------------------------------------------- silhouette
sc = json.load(open(f'{SIL}/silhouette_scores.json'))
ims = [load(f'{SIL}/sil_{c}.png') for c in ('Ab5', 'Ab6')]; bx = crop_box([i for i in ims if i is not None], 10)
lab = [f"{c}: {sc[c]['overlap']} % overlap" for c in ('Ab5', 'Ab6')]
stack([head('Outline at the concept camera', 'Green both, red concept only, yellow ship only. Gate: 90 percent or better.'),
       row([i.crop(bx) for i in ims], lab),
       note(f"Ab6 covers {sc['Ab6']['concept_covered']} % of the concept outline; {sc['Ab6']['cell_outside']} % of Ab6 lies outside it (Ab5: {sc['Ab5']['concept_covered']} and {sc['Ab5']['cell_outside']}).")],
      'silhouette.jpg')
json.dump({k: dict(concept=[round(x) for x in mc[k]], Ab5=[round(x) for x in m5[k]], Ab6=[round(x) for x in m6[k]]) for k in REG}, open(f'{OUT}/paint_regions.json', 'w'), indent=1)
