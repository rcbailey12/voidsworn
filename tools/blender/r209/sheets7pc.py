# Issue 209 round 7: the sheets from the PC renders (out7 Ab7, out6f Ab6), the round 7 battle capture (out7b) and the far side
# stills (out7c), about 2000 px wide, battle camera first (outside audit pass 2, finding 4).
#   battle.jpg     (a) the game's own camera at true pixel size (Ab7 in the game, r 170, 1920x1080), then the studio battle camera
#   paint.jpg      (b) concept, Ab6, Ab7 at the concept camera under the concept rig, then region by region with colour samples
#   hull_side.jpg  (c) the bow hull side close crop: concept, Ab6, Ab7
#   bow.jpg        (d) the bow: concept, Ab6, Ab7 at the concept camera and from the side, outline per third, inner edges
#   bow_blink.gif  (d) concept and Ab7 at the concept camera, alternating
#   far_side.jpg   (e) top, below and the starboard side, Ab6 and Ab7
#   weapons.jpg    (f) each weapon group: concept, Ab6, Ab7 and Ab7 clay at the same crop of the concept camera
#   overview.jpg   (g) Ab7 paint and clay: concept camera, side, top, below
#   fire.jpg       (h) the battle capture: Ab7 firing its port casemates, game camera and close
# usage: python3 sheets7pc.py UPLOADS_OPUS209_DIR CONCEPT.webp SIL_DIR OUT_DIR
import os, sys, json, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
U, CONCEPT, SIL, OUT = sys.argv[1:5]
os.makedirs(OUT, exist_ok=True); W = 2000; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (165, 165, 170); WARN = (230, 180, 100)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
R6, R7, FIRE, R7C = os.path.join(U, 'out6f'), os.path.join(U, 'out7'), os.path.join(U, 'out7b', 'fire'), os.path.join(U, 'out7c', 'r')
REG = dict(bow_side=(100, 560, 180, 620), bow_deck=(200, 470, 300, 520), bow_lower=(100, 640, 200, 690), cas_plate=(200, 530, 240, 560),
           aft_top=(700, 380, 850, 420), aft_side=(640, 430, 760, 470), sponson=(520, 470, 600, 560), drum=(540, 390, 600, 410), cargo=(700, 480, 780, 560))
CLOSE = dict(cas=((170, 470, 510, 700), 'Bow casemates'), bow=((130, 380, 410, 530), 'Twin bow guns and hood'),
             drums=((330, 250, 730, 460), 'Drum racks and tower'), aft=((680, 200, 1010, 430), 'Aft drums and turrets'))
VIEW = (0, 250, 1024, 800)


def flat(im, bg=BG):
    im = im.convert('RGBA'); b = Image.new('RGBA', im.size, bg + (255,)); b.alpha_composite(im); return b.convert('RGB')
def P(d, n): return flat(Image.open(os.path.join(d, n)))
def concept(bg=BG): return flat(Image.open(CONCEPT), bg).resize((1024, 1024), Image.LANCZOS)
def head(title, sub, lines=()):
    h = 130 + 34 * len(lines); im = Image.new('RGB', (W, h), BG); d = ImageDraw.Draw(im)
    d.text((28, 18), title, font=F(46, True), fill=FG); d.text((28, 80), sub, font=F(27), fill=DIM)
    for k, t in enumerate(lines): d.text((28, 122 + 34 * k), t, font=F(25), fill=WARN)
    return im
def lab(im, t, size=30):
    im = im.copy(); d = ImageDraw.Draw(im); w = d.textlength(t, font=F(size, True))
    d.rectangle((0, im.height - size - 18, w + 26, im.height), fill=BG); d.text((13, im.height - size - 11), t, font=F(size, True), fill=FG); return im
def fit(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def row(ims, gap=8):
    w = (W - gap * (len(ims) - 1)) // len(ims); ims = [fit(i, w) for i in ims]; h = max(i.height for i in ims); out = Image.new('RGB', (W, h + gap), BG)
    for k, i in enumerate(ims): out.paste(i, (k * (w + gap), 0))
    return out
def text(lines, size=26, color=DIM):
    im = Image.new('RGB', (W, 20 + (size + 12) * len(lines)), BG); d = ImageDraw.Draw(im)
    for k, t in enumerate(lines): d.text((28, 10 + (size + 12) * k), t, font=F(size), fill=color)
    return im
def stack(parts, name, q=86):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, ((W - p.width) // 2 if p.width < W else 0, y)); y += p.height
    out.save(os.path.join(OUT, name), quality=q, optimize=True); print('wrote', name, out.size, flush=True)
def crop1024(im, b): s = im.width / 1024; return im.crop(tuple(int(v * s) for v in b))

C = concept()
a6, a7 = P(R6 + '/r', 'Ab6_concept_cl.png'), P(R7 + '/r', 'Ab7_concept_cl.png')
a6s, a7s = P(R6 + '/r', 'Ab6_concept.png'), P(R7 + '/r', 'Ab7_concept.png')
thirds = json.load(open(os.path.join(SIL, 'outline_thirds.json')))['cells']
whole = json.load(open(os.path.join(SIL, 'silhouette_scores.json')))

# ---- (a) battle distance
g0 = Image.open(os.path.join(FIRE, 'raw_after_game', 'frame_00000.jpg')).convert('RGB')
gs = Image.open(os.path.join(FIRE, 'stills', 'after_game_fire0_smoke.png')).convert('RGB')
cx, cy = 940, 560
g1 = g0.crop((cx - 480, cy - 270, cx + 480, cy + 270))             # 1:1, true pixel size
g2 = gs.crop((cx - 240, cy - 135, cx + 240, cy + 135)).resize((960, 540), Image.LANCZOS)
top = Image.new('RGB', (W, 560), BG); top.paste(lab(g1, 'Game camera, 1:1 (true size)', 26), (20, 10)); top.paste(lab(g2, '2x, firing', 26), (1020, 10))
def bat(d, c):
    b = P(d + '/r', f'{c}_battle.png'); return b, b.resize((800, 520), Image.LANCZOS)
b6, b62 = bat(R6, 'Ab6'); b7, b72 = bat(R7, 'Ab7')
mid = Image.new('RGB', (W, 300), BG)
mid.paste(lab(b6, 'Ab6 1:1', 22), (180, 20)); mid.paste(lab(b7, 'Ab7 1:1', 22), (1180, 20))
two = Image.new('RGB', (W, 540), BG); two.paste(lab(b62, 'Ab6 2x', 26), (120, 10)); two.paste(lab(b72, 'Ab7 2x', 26), (1080, 10))
gb = lambda b: ImageOps.grayscale(b).filter(ImageFilter.GaussianBlur(2)).convert('RGB').crop((150, 60, 650, 460))
grey = Image.new('RGB', (W, 420), BG); grey.paste(lab(gb(b62), 'Ab6 2x, blurred grey', 22), (270, 10)); grey.paste(lab(gb(b72), 'Ab7 2x, blurred grey', 22), (1230, 10))
stack([head('Battle distance first', 'Top: Ab7 in the game itself, default camera (r 170), 1920x1080, over the real sky; the ship is about 180 px long.',
            ['Ab6 never went into the game, so the side by side below is the studio battle camera (same angle, about 180 px of ship).']),
       top, text(['Studio battle camera (Blender, round 4 rig), Ab6 beside Ab7, over studio grey:']), mid, two, grey], 'battle.jpg')

# ---- (b) paint: whole frame, then region by region
def means(im):
    a = np.asarray(im.resize((1024, 1024))).astype(float); return {k: a[y0:y1, x0:x1].reshape(-1, 3).mean(0) for k, (x0, y0, x1, y1) in REG.items()}
mc, m6, m7 = means(concept((0, 0, 0))), means(a6), means(a7)
parts = [head('Paint against the concept', 'Concept camera. Concept rig (one high key, weak fill, the painting\'s own light) unless marked studio.'),
         row([lab(C.crop(VIEW), 'Concept'), lab(a7.crop(VIEW), 'Ab7 (round 7)')]), row([lab(a6.crop(VIEW), 'Ab6 (round 6)'), lab(a7s.crop(VIEW), 'Ab7, studio rig')])]
pend = []
for k, b in REG.items():
    pad = 30; bb = (b[0] - pad, b[1] - pad, b[2] + pad, b[3] + pad)
    for im, m, t in ((C, mc, 'concept'), (a6, m6, 'Ab6'), (a7, m7, 'Ab7')):
        c = crop1024(im, bb).resize((420, round(420 * (bb[3] - bb[1]) / (bb[2] - bb[0]))), Image.NEAREST)
        d = ImageDraw.Draw(c); s_ = 420 / (bb[2] - bb[0]); d.rectangle((pad * s_, pad * s_, c.width - pad * s_, c.height - pad * s_), outline=(255, 255, 255), width=2)
        col = tuple(int(round(v)) for v in m[k]); sw = Image.new('RGB', (c.width, 40), col)
        ImageDraw.Draw(sw).text((8, 6), f'{k.replace("_", " ")}: {t}', font=F(21, True), fill=(255, 255, 255) if sum(col) < 380 else (0, 0, 0))
        cc = Image.new('RGB', (c.width, c.height + 40)); cc.paste(c, (0, 0)); cc.paste(sw, (0, c.height)); pend.append(cc)
    if len(pend) == 6: parts.append(row(pend)); pend = []
if pend: parts.append(row(pend + [Image.new('RGB', pend[0].size, BG)] * (6 - len(pend))))
parts.append(text(['Each region: concept, Ab6, Ab7 (concept rig), the white box is the sampled patch, the bar its mean colour.'], 23))
json.dump({k: dict(concept=[round(x) for x in mc[k]], Ab6=[round(x) for x in m6[k]], Ab7=[round(x) for x in m7[k]]) for k in REG},
          open(os.path.join(OUT, 'paint_regions.json'), 'w'), indent=1)
stack(parts, 'paint.jpg')

# ---- (c) hull side close
hb = (60, 470, 520, 700)
stack([head('Hull side, close', 'The bow side at the concept camera, where round 6 read as one flat red. 2x of the 1024 frame, then the 4x close-up renders.'),
       row([lab(crop1024(C, hb), 'Concept'), lab(crop1024(a6, hb), 'Ab6')]), row([lab(crop1024(a7, hb), 'Ab7, concept rig'), lab(crop1024(a7s, hb), 'Ab7, studio rig')]),
       row([lab(P(R6 + '/close', 'Ab6_cas_concept.png'), 'Ab6, 4x render'), lab(P(R7 + '/close', 'Ab7_cas_concept.png'), 'Ab7, 4x render')])], 'hull_side.jpg')

# ---- (d) the bow
bb = (0, 330, 640, 740)
t6, t7 = thirds['Ab6'], thirds['Ab7']
tab = ['Outline overlap per third at the concept camera (gate 90):  ' + '   '.join(f"{t}: Ab6 {t6[t]['overlap']} / Ab7 {t7[t]['overlap']}" for t in ('bow', 'midship', 'stern')),
       f"Whole ship: Ab6 {whole['Ab6']['overlap']} / Ab7 {whole['Ab7']['overlap']} (the game export of Ab7: {whole['Ab7game']['overlap']})",
       'Inner edges, bow third: model edges within 6 px of a concept edge: Ab6 %s%% / Ab7 %s%%; median distance %s / %s px' % (
           t6['bow']['edge_cell_within_6px'], t7['bow']['edge_cell_within_6px'], t6['bow']['edge_cell_to_concept_median_px'], t7['bow']['edge_cell_to_concept_median_px']),
       'Concept edges matched by the model within 6 px, bow third: Ab6 %s%% / Ab7 %s%%' % (t6['bow']['edge_concept_within_6px'], t7['bow']['edge_concept_within_6px'])]
sd6, sd7 = P(R6 + '/r', 'Ab6_side.png'), P(R7 + '/r', 'Ab7_side.png')
sc6, sc7 = P(R6 + '/r', 'Ab6_side_clay.png'), P(R7 + '/r', 'Ab7_side_clay.png')
sb = (160, 300, 1100, 950)
th = lambda n: Image.open(os.path.join(SIL, n)).convert('RGB').crop(bb)
stack([head('The bow', 'Concept camera (paint under the concept rig, then clay), then straight from the side. Bow on the left.', ['By the numbers the bow is not closer than Ab6; see the outline and edge rows.']),
       row([lab(crop1024(C, bb), 'Concept'), lab(crop1024(a6, bb), 'Ab6'), lab(crop1024(a7, bb), 'Ab7')]),
       row([lab(crop1024(P(R6 + '/r', 'Ab6_concept_clay.png'), bb), 'Ab6 clay'), lab(crop1024(P(R7 + '/r', 'Ab7_concept_clay.png'), bb), 'Ab7 clay'),
            lab(P(R7 + '/close', 'Ab7_bow_concept.png'), 'Ab7 bow guns, 4x')]),
       row([lab(sd6.crop(sb), 'Ab6, side'), lab(sd7.crop(sb), 'Ab7, side')]), row([lab(sc6.crop(sb), 'Ab6, side clay'), lab(sc7.crop(sb), 'Ab7, side clay')]),
       text(tab, 25, FG),
       row([lab(th('thirds_Ab6.png'), 'Ab6 outline'), lab(th('thirds_Ab7.png'), 'Ab7 outline')]),
       text(['Green both, red concept only, yellow model only; white lines split bow, midship and stern (x = +1/6 and -1/6 of the length).'], 23),
       row([lab(th('edges_Ab6.png'), 'Ab6 inner edges'), lab(th('edges_Ab7.png'), 'Ab7 inner edges')]),
       text(['Cyan: the concept\'s edges. Magenta: the model\'s (flat-shaded, so paint does not count). White: both.'], 23)], 'bow.jpg')
bl = [crop1024(C, bb), crop1024(a7, bb)]
bl[0].save(os.path.join(OUT, 'bow_blink.gif'), save_all=True, append_images=[bl[1]], duration=700, loop=0); print('wrote bow_blink.gif')

# ---- (e) far side
fs = [head('The far side, top and underside', 'Paint judged away from the concept camera too (R160). Studio rig, orthographic.')]
ss = os.path.exists(os.path.join(R7C, 'Ab7_side_s.png'))
if ss:
    fs.append(row([lab(P(R7C, 'Ab6_hero_s.png'), 'Ab6, starboard quarter'), lab(P(R7C, 'Ab7_hero_s.png'), 'Ab7, starboard quarter')]))
    fs.append(row([lab(P(R7C, 'Ab6_side_s.png').crop((0, 250, 2400, 950)), 'Ab6, starboard (bow right)'), lab(P(R7C, 'Ab7_side_s.png').crop((0, 250, 2400, 950)), 'Ab7, starboard (bow right)')]))
else:
    fs.append(text(['No starboard stills: the far side render (out7c) had not landed.'], 26, WARN))
for v in ('top', 'below'):
    fs.append(row([lab(P(R6 + '/r', f'Ab6_{v}.png').crop((0, 250, 2400, 950)), f'Ab6, {v}'), lab(P(R7 + '/r', f'Ab7_{v}.png').crop((0, 250, 2400, 950)), f'Ab7, {v}')]))
stack(fs, 'far_side.jpg')

# ---- (f) weapons
wp = [head('Weapons', 'Casemates level, 8 degrees forward of the beam. Same crop of the concept camera in every row: concept, Ab6, Ab7, Ab7 clay.')]
for k, (b, t) in CLOSE.items():
    cl = (lambda d, c: P(d + '/close', f'{c}_{k}_clay.png')) if k in ('cas', 'bow') else None
    ims = [lab(crop1024(C, b), t + ': concept', 26), lab(P(R6 + '/close', f'Ab6_{k}_concept.png'), 'Ab6', 26), lab(P(R7 + '/close', f'Ab7_{k}_concept.png'), 'Ab7', 26)]
    if cl: ims.append(lab(cl(R7, 'Ab7'), 'Ab7 clay', 26))
    wp.append(row(ims))
stack(wp, 'weapons.jpg')

# ---- (g) overview
ov = [head('Ab7 overview', 'Concept camera (concept rig), hero, side, top, below (studio rig); paint and clay.')]
ov.append(row([lab(a7.crop(VIEW), 'concept camera'), lab(P(R7 + '/r', 'Ab7_concept_clay_cl.png').crop(VIEW), 'clay')]))
ov.append(row([lab(P(R7 + '/r', 'Ab7_hero.png'), 'hero'), lab(P(R7 + '/r', 'Ab7_hero_clay.png') if os.path.exists(R7 + '/r/Ab7_hero_clay.png') else P(R7 + '/r', 'Ab7_hero.png'), 'hero clay')]))
for v in ('side', 'top', 'below'):
    ov.append(row([lab(P(R7 + '/r', f'Ab7_{v}.png').crop((0, 250, 2400, 950)), v), lab(P(R7 + '/r', f'Ab7_{v}_clay.png').crop((0, 250, 2400, 950)), v + ' clay')]))
stack(ov, 'overview.jpg')

# ---- (h) firing
st = os.path.join(FIRE, 'stills'); S = lambda n: Image.open(os.path.join(st, n)).convert('RGB')
rep = [l.strip() for l in open(os.path.join(U, 'out7b', 'fire', 'fire_report.txt')) if 'SMOKE_OFFSET' in l][:1]
fr = [head('Ab7 firing its port casemates (step 5)', 'The game\'s own effects, unchanged. Two broadsides at a Hegemony destroyer. Game camera first, then close.',
           ['Where the smoke starts: on the deck near the centreline, about 6.4 world units (a quarter of the ship\'s length) inboard',
            'and above the real port barrels. The effects still fire from the hull-box mounts, not from the recipe\'s hard points.'])]
gc = lambda n: S(n).crop((cx - 300, cy - 200, cx + 300, cy + 140))
fr.append(row([lab(gc('after_game_fire0_flash.png'), 'game camera: flash', 24), lab(gc('after_game_fire0_smoke.png'), 'smoke', 24), lab(gc('after_game_fire0_hit.png'), 'hit', 24)]))
fr.append(row([lab(S('after_close_fire0_flash.png'), 'close: flash', 26), lab(S('after_close_fire0_smoke.png'), 'close: smoke', 26)]))
fr.append(row([lab(S('after_close_fire0_flash_crop.png'), 'crop: flash', 26), lab(S('after_close_fire0_smoke_crop.png'), 'crop: smoke', 26)]))
fr.append(text(['Probe line: ' + (rep[0] if rep else 'none')[:150], 'Clips: docs/shots/ship_pipeline/route209/round7/fire_game.mp4 and fire_close.mp4 (12 fps).'], 22))
stack(fr, 'fire.jpg')
