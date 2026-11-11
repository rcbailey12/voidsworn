# Issue 209 round 7: the sheets (1080 px wide, phone-readable), built from the sandbox previews (preview7.py) or, with the same
# file names, from the PC run's renders.
#   paint.jpg       concept, Ab6, Ab7 at the concept camera under the concept rig, Ab7 under the studio rig, region colours
#   hull_side.jpg   the close crop of the bow hull side at the concept camera: concept, Ab6, Ab7 (where round 6 read flat)
#   bow.jpg         the bow: concept, Ab6, Ab7 at the concept camera (paint and clay) and from the side
#   weapons.jpg     the casemates with level barrels and the bow guns: concept, Ab6, Ab7 at the same crop of the concept camera
#   overview.jpg    Ab7 in paint and clay: concept camera, side, top, below (studio rig)
#   battle.jpg      Ab6 and Ab7 at the battle camera: 1:1, 2x, blurred greyscale
#   silhouette.jpg  the concept outline over Ab6 and Ab7 with the scores (silhouette4.py overlays)
# usage: python3 sheets7.py FIN_DIR CONCEPT_RGBA_PNG SIL_DIR SHEET_DIR [note="Sandbox preview ..."]
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
FIN, CONCEPT, SIL, OUT = sys.argv[1:5]
NOTE = next((x.split('=', 1)[1] for x in sys.argv[5:] if x.startswith('note=')), 'Sandbox preview: CPU render, paint not baked. The PC run redoes these at full quality.')
os.makedirs(OUT, exist_ok=True); W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
REG = dict(bow_side=(100, 560, 180, 620), bow_deck=(200, 470, 300, 520), bow_lower=(100, 640, 200, 690), cas_plate=(200, 530, 240, 560),
           aft_top=(700, 380, 850, 420), aft_side=(640, 430, 760, 470), sponson=(520, 470, 600, 560), drum=(540, 390, 600, 410), cargo=(700, 480, 780, 560))
def P(name): return Image.open(os.path.join(FIN, name)).convert('RGB')
def concept(bg=BG):
    c = Image.open(CONCEPT).convert('RGBA'); b = Image.new('RGBA', c.size, bg + (255,)); b.alpha_composite(c); return b.convert('RGB')
def head(title, sub):
    im = Image.new('RGB', (W, 150), BG); d = ImageDraw.Draw(im); d.text((24, 16), title, font=F(38, True), fill=FG); d.text((24, 68), sub, font=F(22), fill=DIM)
    d.text((24, 104), NOTE, font=F(19), fill=(200, 170, 110)); return im
def lab(im, t, size=24):
    im = im.copy(); d = ImageDraw.Draw(im); w = d.textlength(t, font=F(size, True)); d.rectangle((0, im.height - size - 16, w + 24, im.height), fill=(14, 15, 18))
    d.text((12, im.height - size - 10), t, font=F(size, True), fill=FG); return im
def fit(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def stack(parts, name, q=86):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, ((W - p.width) // 2 if p.width < W else 0, y)); y += p.height
    out.save(os.path.join(OUT, name), quality=q); print('wrote', name, out.size)
def row(ims, gap=6):
    w = (W - gap * (len(ims) - 1)) // len(ims); ims = [fit(i, w) for i in ims]; h = max(i.height for i in ims); out = Image.new('RGB', (W, h), BG)
    for k, i in enumerate(ims): out.paste(i, (k * (w + gap), 0))
    return out
def means(im):
    a = np.asarray(im.resize((1024, 1024))).astype(float); return {k: a[y0:y1, x0:x1].reshape(-1, 3).mean(0) for k, (x0, y0, x1, y1) in REG.items()}

C = concept(); C1 = C.resize((1024, 1024), Image.LANCZOS)
VIEW = (0, 250, 1024, 800)      # the ship's band of the concept frame
# ---- paint
a6, a7, a7s = P('Ab6_concept_cl.png'), P('Ab7_concept_cl.png'), P('Ab7_concept.png')
mc, m6, m7 = means(concept((0, 0, 0))), means(a6), means(a7)
tab = Image.new('RGB', (W, 60 + 34 * len(REG)), BG); d = ImageDraw.Draw(tab)
d.text((16, 10), 'Region colours (mean sRGB, same pixels of each image, concept rig)', font=F(22, True), fill=FG)
for j, t in enumerate(('concept', 'Ab6', 'Ab7')): d.text((250 + j * 280, 40), t, font=F(20, True), fill=DIM)
for k, n in enumerate(REG):
    y = 66 + k * 34; d.text((16, y), n.replace('_', ' '), font=F(21), fill=FG)
    for j, m in enumerate((mc, m6, m7)):
        col = tuple(int(round(v)) for v in m[n]); d.rectangle((250 + j * 280, y, 300 + j * 280, y + 26), fill=col); d.text((310 + j * 280, y + 2), str(col), font=F(19), fill=DIM)
json.dump({k: dict(concept=[round(x) for x in mc[k]], Ab6=[round(x) for x in m6[k]], Ab7=[round(x) for x in m7[k]]) for k in REG}, open(os.path.join(OUT, 'paint_regions.json'), 'w'), indent=1)
stack([head('Paint against the concept', 'Same camera as the concept. Concept rig: one high key, weak fill (the painting\'s own light).'),
       lab(fit(C1.crop(VIEW), W), 'Concept'), lab(fit(a6.crop(VIEW), W), 'Ab6 (round 6)'), lab(fit(a7.crop(VIEW), W), 'Ab7 (round 7), concept rig'),
       lab(fit(a7s.crop(VIEW), W), 'Ab7, studio rig (rounds 1 to 6)'), tab], 'paint.jpg')
# ---- hull side close crop
box = (60, 470, 520, 700); cc = fit(C.crop(tuple(int(v * C.width / 1024) for v in box)), W)
stack([head('Hull side, close', 'The bow side at the concept camera, where round 6 read as one flat red.'),
       lab(cc, 'Concept'), lab(fit(P('Ab6_concept_cl_crop.png'), W), 'Ab6 (round 6)'), lab(fit(P('Ab7_concept_cl_crop.png'), W), 'Ab7: plate lines, rust gradient, olive lower hull')], 'hull_side.jpg')
# ---- bow
bb = (0, 330, 640, 740); cb = C.crop(tuple(int(v * C.width / 1024) for v in bb))
stack([head('The bow', 'Concept camera (paint, then clay), then straight from the side.'),
       lab(fit(cb, W), 'Concept'),
       row([lab(P('Ab6b_concept_cl_crop.png'), 'Ab6', 40), lab(P('Ab7b_concept_cl_crop.png'), 'Ab7', 40)]),
       row([lab(P('Ab6b_concept_clay_crop.png'), 'Ab6 clay', 40), lab(P('Ab7b_concept_clay_crop.png'), 'Ab7 clay', 40)]),
       row([lab(P('Ab6_bowside_clay.png'), 'Ab6, side', 52), lab(P('Ab7_bowside_clay.png'), 'Ab7, side', 52)]),
       row([lab(P('Ab6_bowside.png'), 'Ab6, side', 52), lab(P('Ab7_bowside.png'), 'Ab7, side', 52)])], 'bow.jpg')
# ---- weapons: crops of the 2048 bow renders (frame box bb), concept at the same boxes
def sub(im, b):      # b in 1024 concept-frame px; im covers bb
    s = im.width / (bb[2] - bb[0]); return im.crop((int((b[0] - bb[0]) * s), int((b[1] - bb[1]) * s), int((b[2] - bb[0]) * s), int((b[3] - bb[1]) * s)))
parts = [head('Weapons', 'Casemates level, 15 degrees forward of the beam. Same crop of the concept camera in every row.')]
for b, t in (((170, 480, 510, 690), 'Bow casemates'), ((120, 385, 420, 535), 'Twin bow guns and the hood')):
    cw = C.crop(tuple(int(v * C.width / 1024) for v in b))
    parts += [lab(fit(cw, W), t + ': concept'), row([lab(sub(P('Ab6b_concept_cl_crop.png'), b), 'Ab6', 30), lab(sub(P('Ab7b_concept_cl_crop.png'), b), 'Ab7', 30)]),
              row([lab(sub(P('Ab6b_concept_clay_crop.png'), b), 'Ab6 clay', 30), lab(sub(P('Ab7b_concept_clay_crop.png'), b), 'Ab7 clay', 30)])]
stack(parts, 'weapons.jpg')
# ---- overview
ov = [head('Ab7 overview', 'Paint and clay: concept camera, side, top, below (studio rig).')]
ov.append(row([lab(P('Ab7_concept.png').crop(VIEW), 'concept camera', 36), lab(P('Ab7_concept_clay.png').crop(VIEW), 'clay', 36)]))
for v in ('side', 'top', 'below'):
    a, b = P(f'Ab7_{v}.png'), P(f'Ab7_{v}_clay.png'); cy = a.height // 2; hh = int(a.height * (.30 if v == 'side' else .26))
    ov.append(row([lab(a.crop((0, cy - hh, a.width, cy + hh)), v, 60), lab(b.crop((0, cy - hh, b.width, cy + hh)), v + ' clay', 60)]))
stack(ov, 'overview.jpg')
# ---- battle distance
def trio(im):
    g = ImageOps.grayscale(im).filter(ImageFilter.GaussianBlur(1.2)).convert('RGB'); big = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
    out = Image.new('RGB', (W, big.height), BG); out.paste(im, (10, (big.height - im.height) // 2)); out.paste(big.crop((big.width // 2 - 250, 0, big.width // 2 + 250, big.height)), (300, 0))
    out.paste(g.resize((g.width, g.height)), (W - g.width - 10 if g.width < 270 else 810, (big.height - g.height) // 2)); return out
def trio2(im):
    big = im.resize((im.width * 2, im.height * 2), Image.LANCZOS); g = ImageOps.grayscale(im).filter(ImageFilter.GaussianBlur(1.2)).convert('RGB')
    a = im.crop((100, 40, 300, 220)); b = big.crop((200, 80, 600, 440)); c = g.crop((100, 40, 300, 220)).resize((400, 360), Image.LANCZOS)
    out = Image.new('RGB', (W, 360), BG); out.paste(a, (30, 90)); out.paste(b, (260, 0)); out.paste(c, (670, 0)); return out
stack([head('Battle distance', 'About 180 px of ship, as in a battle: 1:1, 2x, and blurred greyscale at 2x.'),
       lab(trio2(P('Ab6_battle.png')), 'Ab6'), lab(trio2(P('Ab7_battle.png')), 'Ab7')], 'battle.jpg')
# ---- silhouette
sc = json.load(open(os.path.join(SIL, 'silhouette_scores.json')))
sp = [head('Outline at the concept camera', 'Green: both. Red: concept only. Yellow: ship only. The gate is 90 percent overlap.')]
sp.append(row([lab(Image.open(os.path.join(SIL, f'sil_{c}.png')).convert('RGB').crop((0, 100, 1024, 840)), f"{c}: {sc[c]['overlap']} percent", 44) for c in ('Ab6', 'Ab7')]))
stack(sp, 'silhouette.jpg')
