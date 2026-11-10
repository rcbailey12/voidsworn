# Issue 209 round 8: the sheets from the PC renders (out8b Ab8 = the second bake, out7 Ab7), the battle captures (out8b fire, round 7's
# out7b) and the far side stills (out8b, round 7's out7c); out8 (the first bake, bow deck olive) only for the before and after, about 2000 px wide, battle camera first (outside audit pass 2, finding 4). Made from sheets7pc.py.
# The bow sheet adds the traced deck line, the two fit tries and the battle camera outline (SIL holds outline_thirds.json,
# silhouette_scores.json, outline_battle.json and the overlays; TRY holds the sandbox views of both tries).
#   battle.jpg     (a) the game's own camera at true pixel size (Ab8 in the game, r 170, 1920x1080), then the studio battle camera
#   paint.jpg      (b) concept, Ab7, Ab8 at the concept camera under the concept rig, then region by region with colour samples
#   hull_side.jpg  (c) the bow hull side close crop: concept, Ab7, Ab8
#   bow.jpg        (d) the bow: concept, Ab7, Ab8 at the concept camera and from the side, outline per third, inner edges
#   bow_blink.gif  (d) concept and Ab8 at the concept camera, alternating
#   far_side.jpg   (e) top, below and the starboard side, Ab7 and Ab8
#   weapons.jpg    (f) each weapon group: concept, Ab7, Ab8 and Ab8 clay at the same crop of the concept camera
#   overview.jpg   (g) Ab8 paint and clay: concept camera, side, top, below
#   fire.jpg       (h) the battle capture: Ab8 firing its port casemates, game camera and close
# usage: python3 sheets8.py UPLOADS_OPUS209_DIR CONCEPT.webp SIL_DIR OUT_DIR TRY_VIEWS.png
import os, sys, json, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
U, CONCEPT, SIL, OUT, TRY = sys.argv[1:6]
os.makedirs(OUT, exist_ok=True); W = 2000; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (165, 165, 170); WARN = (230, 180, 100)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
R7, R8, FIRE, R8C, R7C = os.path.join(U, 'out7'), os.path.join(U, 'out8b'), os.path.join(U, 'out8b', 'fire'), os.path.join(U, 'out8b', 'r'), os.path.join(U, 'out7c', 'r')
R8A = os.path.join(U, 'out8')
FIRE7 = os.path.join(U, 'out7b', 'fire')
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
a6, a7 = P(R7 + '/r', 'Ab7_concept_cl.png'), P(R8 + '/r', 'Ab8_concept_cl.png')
a6s, a7s = P(R7 + '/r', 'Ab7_concept.png'), P(R8 + '/r', 'Ab8_concept.png')
thirds = json.load(open(os.path.join(SIL, 'outline_thirds.json')))['cells']
whole = json.load(open(os.path.join(SIL, 'silhouette_scores.json')))

# ---- (a) battle distance: both ships in the game at the default camera, true pixel size, then 2x crops and the studio battle camera
cx, cy = 950, 605
def gframe(fire): return Image.open(os.path.join(fire, 'raw_after_game', 'frame_00000.jpg')).convert('RGB')
g7, g8 = gframe(FIRE7), gframe(FIRE)
one = lambda g: g.crop((cx - 480, cy - 270, cx + 480, cy + 270))                                  # 1:1, true pixel size
two_ = lambda g: g.crop((cx - 240, cy - 160, cx + 240, cy + 110)).resize((960, 540), Image.LANCZOS)
top = Image.new('RGB', (W, 560), BG); top.paste(lab(one(g7), 'Ab7 (round 7), game camera 1:1', 26), (20, 10)); top.paste(lab(one(g8), 'Ab8 (round 8), game camera 1:1', 26), (1020, 10))
top2 = Image.new('RGB', (W, 560), BG); top2.paste(lab(two_(g7), 'Ab7, 2x', 26), (20, 10)); top2.paste(lab(two_(g8), 'Ab8, 2x', 26), (1020, 10))
gs = Image.open(os.path.join(FIRE, 'stills', 'after_game_fire0_smoke.png')).convert('RGB')
fire2 = Image.new('RGB', (W, 560), BG); fire2.paste(lab(two_(gs), 'Ab8 firing, 2x', 26), (520, 10))
def bat(d, c):
    b = P(d + '/r', f'{c}_battle.png'); return b, b.resize((800, 520), Image.LANCZOS)
b6, b62 = bat(R7, 'Ab7'); b7, b72 = bat(R8, 'Ab8')
mid = Image.new('RGB', (W, 300), BG)
mid.paste(lab(b6, 'Ab7 1:1', 22), (180, 20)); mid.paste(lab(b7, 'Ab8 1:1', 22), (1180, 20))
two = Image.new('RGB', (W, 540), BG); two.paste(lab(b62, 'Ab7 2x', 26), (120, 10)); two.paste(lab(b72, 'Ab8 2x', 26), (1080, 10))
stack([head('Battle distance first', 'Both ships in the game itself, default camera (r 170), 1920x1080, over the real sky; about 180 px of ship.',
            ['Judge the paint here first: the deck colour, the red front against the dark back, the rust blotches.']),
       top, top2, fire2, text(['Studio battle camera (Blender, round 4 rig), Ab7 beside Ab8, over studio grey:']), mid, two], 'battle.jpg')

# ---- (b) paint: whole frame, then region by region
def means(im):
    a = np.asarray(im.resize((1024, 1024))).astype(float); return {k: a[y0:y1, x0:x1].reshape(-1, 3).mean(0) for k, (x0, y0, x1, y1) in REG.items()}
mc, m6, m7 = means(concept((0, 0, 0))), means(a6), means(a7)
parts = [head('Paint against the concept', 'Concept camera. Concept rig (one high key, weak fill, the painting\'s own light) unless marked studio.'),
         row([lab(C.crop(VIEW), 'Concept'), lab(a7.crop(VIEW), 'Ab8 (round 8)')]), row([lab(a6.crop(VIEW), 'Ab7 (round 7)'), lab(a7s.crop(VIEW), 'Ab8, studio rig')])]
pend = []
for k, b in REG.items():
    pad = 30; bb = (b[0] - pad, b[1] - pad, b[2] + pad, b[3] + pad)
    for im, m, t in ((C, mc, 'concept'), (a6, m6, 'Ab7'), (a7, m7, 'Ab8')):
        c = crop1024(im, bb).resize((420, round(420 * (bb[3] - bb[1]) / (bb[2] - bb[0]))), Image.NEAREST)
        d = ImageDraw.Draw(c); s_ = 420 / (bb[2] - bb[0]); d.rectangle((pad * s_, pad * s_, c.width - pad * s_, c.height - pad * s_), outline=(255, 255, 255), width=2)
        col = tuple(int(round(v)) for v in m[k]); sw = Image.new('RGB', (c.width, 40), col)
        ImageDraw.Draw(sw).text((8, 6), f'{k.replace("_", " ")}: {t}', font=F(21, True), fill=(255, 255, 255) if sum(col) < 380 else (0, 0, 0))
        cc = Image.new('RGB', (c.width, c.height + 40)); cc.paste(c, (0, 0)); cc.paste(sw, (0, c.height)); pend.append(cc)
    if len(pend) == 6: parts.append(row(pend)); pend = []
if pend: parts.append(row(pend + [Image.new('RGB', pend[0].size, BG)] * (6 - len(pend))))
parts.append(text(['Each region: concept, Ab7, Ab8 (concept rig), the white box is the sampled patch, the bar its mean colour.'], 23))
json.dump({k: dict(concept=[round(x) for x in mc[k]], Ab7=[round(x) for x in m6[k]], Ab8=[round(x) for x in m7[k]]) for k in REG},
          open(os.path.join(OUT, 'paint_regions.json'), 'w'), indent=1)
# in the game itself (R160: judge the paint in the game, not only in Blender): the default camera frame, 4x nearest, sampled patches
GREG = dict(bow_hood_top=(1006, 597, 1030, 607), bow_deck=(1010, 617, 1040, 630), midship_deck=(940, 590, 972, 600), aft_side=(880, 610, 915, 625))
gpend, gres = [], {}
for nm, fdir in (('Ab7', FIRE7), ('Ab8', FIRE)):
    g = gframe(fdir); ga = np.asarray(g).astype(float); c = g.crop((840, 550, 1080, 680)); s4 = 4
    c = c.resize((c.width * s4, c.height * s4), Image.NEAREST); d = ImageDraw.Draw(c)
    for k, (x0, y0, x1, y1) in GREG.items():
        m = ga[y0:y1, x0:x1].reshape(-1, 3).mean(0); gres.setdefault(k, {})[nm] = [int(round(v)) for v in m]
        d.rectangle(((x0 - 840) * s4, (y0 - 550) * s4, (x1 - 840) * s4, (y1 - 550) * s4), outline=(0, 255, 0), width=3)
        d.text(((x0 - 840) * s4 + 4, (y0 - 550) * s4 - 26), k.replace('_', ' '), font=F(20, True), fill=(0, 255, 0))
    gpend.append(lab(c, nm + ' in the game, default camera, 4x', 26))
parts.append(text(['In the game itself (round 7 Ab7 beside round 8 Ab8), the default camera frame at 4x, no smoothing. Green boxes are sampled:'], 25, FG))
parts.append(row(gpend))
sw = []
for k, v in gres.items():
    for nm in ('Ab7', 'Ab8'):
        col = tuple(v[nm]); b = Image.new('RGB', (480, 60), col)
        ImageDraw.Draw(b).text((10, 14), f'{k.replace("_", " ")}: {nm} {col}', font=F(22, True), fill=(255, 255, 255))
        sw.append(b)
parts.append(row(sw[:4])); parts.append(row(sw[4:]))
json.dump(gres, open(os.path.join(OUT, 'paint_game.json'), 'w'), indent=1)
# the first bake (out8) beside the second (out8b): the bow deck olive from the UV overlap, then red
if os.path.exists(os.path.join(R8A, 'r', 'Ab8_concept_cl.png')):
    a8a = P(R8A + '/r', 'Ab8_concept_cl.png'); bb8 = (0, 420, 420, 640)
    parts.append(text(['The two PC bakes of Ab8 at the concept camera: the first (out8) baked the bow deck olive from a UV overlap; the second (out8b) after the repair.'], 23, FG))
    parts.append(row([lab(crop1024(a8a, bb8), 'Ab8, first bake (out8)', 13), lab(crop1024(a7, bb8), 'Ab8, second bake (out8b), adopted', 13)]))
stack(parts, 'paint.jpg')

# ---- (c) hull side close
hb = (60, 470, 520, 700)
stack([head('Hull side, close', 'The bow side at the concept camera, where round 6 read as one flat red. 2x of the 1024 frame, then the 4x close-up renders.'),
       row([lab(crop1024(C, hb), 'Concept'), lab(crop1024(a6, hb), 'Ab7')]), row([lab(crop1024(a7, hb), 'Ab8, concept rig'), lab(crop1024(a7s, hb), 'Ab8, studio rig')]),
       row([lab(P(R7 + '/close', 'Ab7_cas_concept.png'), 'Ab7, 4x render'), lab(P(R8 + '/close', 'Ab8_cas_concept.png'), 'Ab8, 4x render')])], 'hull_side.jpg')

# ---- (d) the bow
bb = (0, 330, 640, 740)
t6, t7, t1 = thirds['Ab7'], thirds['Ab8'], thirds.get('Ab8try1')
bt = json.load(open(os.path.join(SIL, 'outline_battle.json')))['cells']
dk = json.load(open(os.path.join(SIL, 'deck_line.json')))
tab = ['Outline per third at the concept camera (bow target 93):  ' + '   '.join(f"{t}: Ab7 {t6[t]['overlap']} / Ab8 {t7[t]['overlap']}" for t in ('bow', 'midship', 'stern')),
       f"Whole ship (gate 90): Ab7 {t6['whole']['overlap']} / Ab8 {t7['whole']['overlap']}" + (f"   (the game export of Ab8: {whole['Ab8game']['overlap']})" if 'Ab8game' in whole else ''),
       'Bow inner edges, model edges within 6 px of a concept edge (target 55): Ab7 %s%% / Ab8 %s%%; median %s / %s px' % (
           t6['bow']['edge_cell_within_6px'], t7['bow']['edge_cell_within_6px'], t6['bow']['edge_cell_to_concept_median_px'], t7['bow']['edge_cell_to_concept_median_px']),
       'Concept bow edges matched by the model within 6 px: Ab7 %s%% / Ab8 %s%%' % (t6['bow']['edge_concept_within_6px'], t7['bow']['edge_concept_within_6px']),
       'Near deck edge to the concept\'s traced deck edge, mean px: Ab7 %s / Ab8 %s (try 1: %s)' % (dk['Ab7'], dk['Ab8'], dk.get('Ab8try1')),
       'Battle cameras against B0 (the shape reference, not the concept), bow / whole: game camera Ab7 %s / %s, Ab8 %s / %s; studio Ab7 %s / %s, Ab8 %s / %s' % (
           bt['Ab7']['game']['bow'], bt['Ab7']['game']['whole'], bt['Ab8']['game']['bow'], bt['Ab8']['game']['whole'],
           bt['Ab7']['studio']['bow'], bt['Ab7']['studio']['whole'], bt['Ab8']['studio']['bow'], bt['Ab8']['studio']['whole'])]
if t1: tab.append('Try 1 (not adopted): bow %s, whole %s, bow edges %s%%, deck edge %s px under the concept\'s' % (t1['bow']['overlap'], t1['whole']['overlap'], t1['bow']['edge_cell_within_6px'], dk.get('Ab8try1')))
sd6, sd7 = P(R7 + '/r', 'Ab7_side.png'), P(R8 + '/r', 'Ab8_side.png')
sc6, sc7 = P(R7 + '/r', 'Ab7_side_clay.png'), P(R8 + '/r', 'Ab8_side_clay.png')
sb = (160, 300, 1100, 950)
th = lambda n: Image.open(os.path.join(SIL, n)).convert('RGB').crop(bb)
tv = Image.open(TRY).convert('RGB')
tryrow = [lab(tv.crop((900 * k, 0, 900 * k + 900, 1440)), t, 26) for k, t in enumerate(('Ab7', 'try 1 (outline only)', 'try 2 = Ab8 (outline + deck line)'))]
stack([head('The bow', 'Concept camera (paint under the concept rig, then clay), then straight from the side. Bow on the left.',
            ['Bow third 90.3 to %s, whole %s to %s; the bow inner edges did not reach 55 percent (see the README, step 1).' % (t7['bow']['overlap'], t6['whole']['overlap'], t7['whole']['overlap'])]),
       row([lab(crop1024(C, bb), 'Concept'), lab(crop1024(a6, bb), 'Ab7'), lab(crop1024(a7, bb), 'Ab8')]),
       row([lab(crop1024(P(R7 + '/r', 'Ab7_concept_clay.png'), bb), 'Ab7 clay'), lab(crop1024(P(R8 + '/r', 'Ab8_concept_clay.png'), bb), 'Ab8 clay'),
            lab(P(R8 + '/close', 'Ab8_bow_concept.png'), 'Ab8 bow guns, 4x')]),
       row([lab(sd6.crop(sb), 'Ab7, side'), lab(sd7.crop(sb), 'Ab8, side')]), row([lab(sc6.crop(sb), 'Ab7, side clay'), lab(sc7.crop(sb), 'Ab8, side clay')]),
       text(tab, 23, FG),
       row([lab(th('thirds_Ab7.png'), 'Ab7 outline'), lab(th('thirds_Ab8.png'), 'Ab8 outline')]),
       text(['Green both, red concept only, yellow model only; white lines split bow, midship and stern (x = +1/6 and -1/6 of the length).'], 23),
       row([lab(th('edges_Ab7.png'), 'Ab7 inner edges'), lab(th('edges_Ab8.png'), 'Ab8 inner edges')]),
       text(['Cyan: the concept\'s edges. Magenta: the model\'s (flat-shaded, so paint does not count). White: both.'], 23),
       row([Image.open(os.path.join(SIL, 'deckline.png')).convert('RGB')]),
       text(['Near deck edge at the concept camera: concept trace (white), Ab7 (yellow), try 1 (orange), Ab8 = try 2 (green).'], 23),
       text(['The two fit tries, flat-shaded (sandbox): over the concept at its camera, from the side, from above.'], 23), row(tryrow)], 'bow.jpg')
bl = [crop1024(C, bb), crop1024(a7, bb)]
bl[0].save(os.path.join(OUT, 'bow_blink.gif'), save_all=True, append_images=[bl[1]], duration=700, loop=0); print('wrote bow_blink.gif')
if os.path.exists(os.path.join(SIL, 'battle_game_Ab8.png')):
    bm = [Image.open(os.path.join(SIL, f'battle_{c}_{n}.png')).convert('RGB') for c in ('game', 'studio') for n in ('Ab7', 'Ab8')]
    stack([head('Outline at the battle cameras', 'Against B0, the shape reference made from the concept (the concept has one camera only). Green both, red B0 only, yellow model only.'),
           row([lab(bm[0], 'game camera, Ab7'), lab(bm[1], 'game camera, Ab8')]), row([lab(bm[2], 'studio battle camera, Ab7'), lab(bm[3], 'studio battle camera, Ab8')])], 'outline_battle.jpg')

# ---- (e) far side
fs = [head('The far side, top and underside', 'Paint judged away from the concept camera too (R160). Studio rig, orthographic.')]
ss = os.path.exists(os.path.join(R8C, 'Ab8_side_s.png'))
if ss:
    fs.append(row([lab(P(R7C, 'Ab7_hero_s.png'), 'Ab7, starboard quarter'), lab(P(R8C, 'Ab8_hero_s.png'), 'Ab8, starboard quarter')]))
    fs.append(row([lab(P(R7C, 'Ab7_side_s.png').crop((0, 250, 2400, 950)), 'Ab7, starboard (bow right)'), lab(P(R8C, 'Ab8_side_s.png').crop((0, 250, 2400, 950)), 'Ab8, starboard (bow right)')]))
else:
    fs.append(text(['No starboard stills: the far side render (out8b) had not landed.'], 26, WARN))
for v in ('top', 'below'):
    fs.append(row([lab(P(R7 + '/r', f'Ab7_{v}.png').crop((0, 250, 2400, 950)), f'Ab7, {v}'), lab(P(R8 + '/r', f'Ab8_{v}.png').crop((0, 250, 2400, 950)), f'Ab8, {v}')]))
stack(fs, 'far_side.jpg')

# ---- (f) weapons
wp = [head('Weapons', 'Same crop of the concept camera in every row: concept, Ab7, Ab8 (and Ab8 clay).', ['Casemates level: Ab7 about 15 degrees forward of the beam, Ab8 8 degrees (aim 0.139, 0.990, 0; Board ruling on PR 341).'])]
for k, (b, t) in CLOSE.items():
    cl = (lambda d, c: P(d + '/close', f'{c}_{k}_clay.png')) if k in ('cas', 'bow') else None
    wp.append(text([t], 28, FG))
    ims = [lab(crop1024(C, b), 'concept', 12), lab(P(R7 + '/close', f'Ab7_{k}_concept.png'), 'Ab7', 26), lab(P(R8 + '/close', f'Ab8_{k}_concept.png'), 'Ab8', 26)]
    if cl: ims.append(lab(cl(R8, 'Ab8'), 'Ab8 clay', 26))
    wp.append(row(ims))
stack(wp, 'weapons.jpg')

# ---- (g) overview
ov = [head('Ab8 overview', 'Concept camera (concept rig), hero, side, top, below (studio rig); paint and clay.')]
ov.append(row([lab(a7.crop(VIEW), 'concept camera'), lab(P(R8 + '/r', 'Ab8_concept_clay_cl.png').crop(VIEW), 'clay')]))
ov.append(row([lab(P(R8 + '/r', 'Ab8_hero.png'), 'hero'), lab(P(R8 + '/r', 'Ab8_hero_clay.png') if os.path.exists(R8 + '/r/Ab8_hero_clay.png') else P(R8 + '/r', 'Ab8_hero.png'), 'hero clay')]))
for v in ('side', 'top', 'below'):
    ov.append(row([lab(P(R8 + '/r', f'Ab8_{v}.png').crop((0, 250, 2400, 950)), v), lab(P(R8 + '/r', f'Ab8_{v}_clay.png').crop((0, 250, 2400, 950)), v + ' clay')]))
stack(ov, 'overview.jpg')

# ---- (h) firing
st = os.path.join(FIRE, 'stills'); S = lambda n: Image.open(os.path.join(st, n)).convert('RGB')
rep = [l.strip() for l in open(os.path.join(FIRE, 'fire_report.txt')) if 'SMOKE_OFFSET' in l][:1]
fr = [head('Ab8 firing its port casemates (step 5)', 'The game\'s own effects, unchanged. Two broadsides at a Hegemony destroyer. Game camera first, then close.',
           ['Where the smoke starts (not in this round, issues 363 and 370): the probe puts the effect mounts 5.9 world units (mean; worst 6.1,',
            'a quarter of the ship\'s length) from the real port muzzles. The effects still fire from the hull-box mounts, not the recipe\'s hard points.'])]
gc = lambda n: S(n).crop((cx - 300, cy - 200, cx + 300, cy + 140))
fr.append(row([lab(gc('after_game_fire0_flash.png'), 'game camera: flash', 24), lab(gc('after_game_fire0_smoke.png'), 'smoke', 24), lab(gc('after_game_fire0_hit.png'), 'hit', 24)]))
fr.append(row([lab(S('after_close_fire0_flash.png'), 'close: flash', 26), lab(S('after_close_fire0_smoke.png'), 'close: smoke', 26)]))
fr.append(row([lab(S('after_close_fire0_flash_crop.png'), 'crop: flash', 26), lab(S('after_close_fire0_smoke_crop.png'), 'crop: smoke', 26)]))
fr.append(text(['Probe line: ' + (rep[0] if rep else 'none')[:150], 'No clips this round (smoke placement is out of scope); the 45-frame captures are on the PC in opus209\\out8b\\fire.'], 22))
stack(fr, 'fire.jpg')
