# Issue 209 round 5: comparison sheets (1080 px wide, phone-readable), round 4's layouts (sheets4.py) with round 4's Ab4 and Hy4 beside
# Ab5, plus the close-up sheet (casemate and drum rack: Hy4's generated parts against Ab5's hand rebuilds, close5.py renders).
# The silhouette sheet is silsheet4.py (Ab5 added to its names).
# usage: python3 sheets5.py RENDER_DIRS(comma) JSON_DIRS(comma) CONCEPT_PNG OUT_DIR CELLS [GODOT_DIR|-] [MAPS_DIR|-] [CLOSE_DIR]
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
RD, JD = sys.argv[1].split(','), sys.argv[2].split(','); CONCEPT, OUT = sys.argv[3:5]; CELLS = sys.argv[5].split(',')
GOD = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] != '-' else None
MAPS = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] != '-' else None
CLOSE = sys.argv[8] if len(sys.argv) > 8 else None
os.makedirs(OUT, exist_ok=True); W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
NAMES = {'Ab': 'Ab round 2  hand hull + B0 baked', 'Ab3': 'Ab3  round 3, rounded hull', 'Hy3': 'Hy3  round 3, Ab3 + AI hero parts',
         'Ab4': 'Ab4  round 4 slab hull, all hand parts', 'Hy4': 'Hy4  Ab4 + AI casemates and drum racks',
         'Ab5': 'Ab5  round 5, hull traced from B0, hand parts'}
HV = 'concept'

def find(name, dirs):
    for d in dirs:
        p = os.path.join(d, name)
        if os.path.exists(p): return p
def meta(c):
    p = find(c + '.json', JD)
    try: return json.load(open(p)) if p else {}
    except ValueError: return {}
def img(c, v):
    p = find(f'{c}_{v}.png', RD); return Image.open(p).convert('RGB') if p else None
def label(c):
    m = meta(c); t = f"{m.get('triangles', 0):,} tris, {m.get('surfaces', '?')} surfaces" if m else ''
    return NAMES.get(c, c), t
def head(title, sub):
    im = Image.new('RGB', (W, 120), BG); d = ImageDraw.Draw(im); d.text((24, 18), title, font=F(38, True), fill=FG); d.text((24, 72), sub, font=F(23), fill=DIM); return im
def bar(c, extra=''):
    im = Image.new('RGB', (W, 52), (28, 30, 36)); d = ImageDraw.Draw(im); a, b = label(c)
    d.text((16, 10), a, font=F(27, True), fill=FG); d.text((W - 16, 14), (b + ('  ' + extra if extra else '')).strip(), font=F(21), fill=DIM, anchor='ra'); return im
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
def content_box(ims, pad=12):
    box = None
    for im in ims:
        if im is None: continue
        a = np.asarray(im, dtype=np.int16); m = np.abs(a - np.median(a[:8, :8].reshape(-1, 3), 0)).max(2) > 22; ys, xs = np.where(m)
        if not len(xs): continue
        b = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    if box is None: return None
    w, h = [i for i in ims if i is not None][0].size
    return (max(0, int(box[0]) - pad), max(0, int(box[1]) - pad), min(w, int(box[2]) + pad), min(h, int(box[3]) + pad))
def concept_img(box=None):
    c = Image.open(CONCEPT).convert('RGBA'); bgi = Image.new('RGBA', c.size, BG + (255,)); bgi.alpha_composite(c); c = bgi.convert('RGB')
    return c.crop(box) if box else c.crop((0, 100, 1024, 840))
def view(c):   # round 3 cells were rendered before the concept camera existed: their hero view stands in, marked
    a = img(c, HV); return (a, img(c, HV + '_clay'), True) if a is not None else (img(c, 'hero'), img(c, 'hero_clay'), False)

def sheets():
    parts = [head('Issue 209 round 5: C15s Hullbreaker cruiser', 'Hull traced from B0. Each cell: paint, then clay, at the concept camera.')]
    V = {x: view(x) for x in CELLS}; cb = content_box([v[0] for v in V.values() if v[2]] + [v[1] for v in V.values() if v[2]])
    parts += [tbar('Concept (the target), its own camera'), fitw(concept_img(cb), W)]
    for x in CELLS:
        a, b, at = V[x]
        if a is None: continue
        if at and cb: a, b = a.crop(cb), b.crop(cb)
        parts += [bar(x, '' if at else '(round 3 hero camera)'), fitw(a, W), fitw(b, W)]
    stack(parts, 'overview.jpg')
    # paint against the concept: the concept beside each cell at the concept's own camera, side by side
    con = concept_img(cb); parts = [head('Paint against the concept', 'Left: the concept. Right: the cell at the concept camera.')]
    for x in CELLS:
        a, b, at = V[x]
        if a is None: continue
        a = a.crop(cb) if at and cb else a
        l, r = fitw(con, W // 2 - 4), fitw(a, W // 2 - 4); h = max(l.height, r.height); row = Image.new('RGB', (W, h + 8), BG)
        row.paste(l, (2, 4)); row.paste(r, (W // 2 + 2, 4)); parts += [bar(x, '' if at else '(round 3 hero camera)'), row]
    stack(parts, 'paint.jpg')
    parts = [head('Battle distance', 'Left: 1:1 at about 180 px of ship. Middle: 2x. Right: blurred greyscale.')]
    for x in CELLS:
        a = img(x, 'battle')
        if a is None: continue
        g = ImageOps.grayscale(a).filter(ImageFilter.GaussianBlur(7.5)).convert('RGB')
        r = Image.new('RGB', (W, 300), BG); z2 = a.crop((100, 65, 300, 195)).resize((400, 260), Image.NEAREST)
        r.paste(a.crop((50, 32, 350, 228)), (6, 52)); r.paste(z2, (318, 20)); r.paste(g.crop((50, 32, 350, 228)), (730, 52))
        parts += [bar(x), r]
    stack(parts, 'battle.jpg')
    for v, title in (('top', 'Close range: top'), ('side', 'Close range: side (port)'), ('below', 'Close range: below')):
        ims = [img(x, v) for x in CELLS] + [img(x, v + '_clay') for x in CELLS]; bb = content_box(ims)
        sub = 'Bow, midship, stern left to right.' if v != 'below' else 'Looking up: stern, midship, bow left to right.'
        parts = [head(title, sub + ' Paint row, then clay row.')]
        for x in CELLS:
            rows = []
            for suf in ('', '_clay'):
                a = img(x, v + suf)
                if a is None: continue
                if bb: a = a.crop(bb)
                w3 = a.width // 3; tiles = [fitw(a.crop((k * w3, 0, (k + 1) * w3, a.height)), W // 3 - 4) for k in range(3)]
                r = Image.new('RGB', (W, tiles[0].height + 4), BG)
                for k, t in enumerate(tiles): r.paste(t, (k * (W // 3) + 2, 2))
                rows.append(r)
            if rows: parts += [bar(x)] + rows
        stack(parts, f'close_{v}.jpg')
    parts = [head('Break test', 'Four break pieces pulled apart. Left: bow quarter. Right: stern quarter.')]
    ims = [img(x, 'break') for x in CELLS] + [img(x, 'break2') for x in CELLS]; bb = content_box(ims)
    for x in CELLS:
        a, b = img(x, 'break'), img(x, 'break2')
        if a is None: continue
        if bb: a, b = a.crop(bb), b.crop(bb)
        a, b = fitw(a, W // 2), fitw(b, W // 2); r = Image.new('RGB', (W, a.height), BG); r.paste(a, (0, 0)); r.paste(b, (W // 2, 0)); parts += [bar(x), r]
    stack(parts, 'break.jpg')

def px(d): return 1080 / (2 * np.tan(np.radians(22.5)) * d)   # ship length on a 1080p screen at d ship lengths (battle camera fov)

def crop_ship(path, d, w, k=.62):
    im = Image.open(path).convert('RGB'); s = max(50, min(int(px(d) * k), 1000)); cx, cy = im.width // 2, im.height // 2
    return im.crop((cx - s, cy - int(s * .62), cx + s, cy + int(s * .62))).resize((w, int(w * .62)), Image.LANCZOS)

def lod_sheet(cells):
    import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
    B = json.load(open(os.path.join(GOD, 'bench209.json'))); HD = B.get('hand_d', [0, 3, 8, 18])
    parts = [head('Godot: level of detail', 'LOD off, Godot auto LOD (1 px), the hand chain. One ship, battle camera angle.')]
    cols = {'off': '#a0a0a5', 'auto': '#6fa8dc', 'hand': '#e69138'}
    for c in cells:
        cd = B['cells'].get(c)
        if not cd: continue
        fig, ax = plt.subplots(figsize=(10.8, 3.6), dpi=100); fig.patch.set_facecolor('#0e0f12'); ax.set_facecolor('#0e0f12')
        for mode in ('off', 'auto', 'hand'):
            sw = cd.get('sweep_' + mode)
            if not sw: continue
            sw = np.array(sw, float); ax.step(px(sw[:, 0]), sw[:, 1] / 1000, where='post', color=cols[mode], lw=2, label={'off': 'LOD off', 'auto': 'Godot auto LOD', 'hand': 'hand chain'}[mode])
        ax.set_xscale('log'); ax.invert_xaxis(); ax.set_xlabel('ship length on a 1080p screen (pixels; at 4K, double); further away to the right', color='#a0a0a5', fontsize=11)
        ax.set_ylabel('thousand triangles\ndrawn (with shadows)', color='#a0a0a5', fontsize=11)
        for s in ax.spines.values(): s.set_color('#3a3c44')
        ax.tick_params(colors='#a0a0a5'); ax.grid(True, color='#24262c', lw=.6)
        top = ax.get_ylim()[1]
        for k, d in enumerate(HD[1:], 1): ax.axvline(px(d), color='#e69138', lw=1, ls='--'); ax.text(px(d), top * .80, f' LOD{k}\n {int(px(d))} px', color='#e69138', fontsize=9)
        ax.axvline(180, color='#a0a0a5', lw=1, ls=':'); ax.text(180, top * .45, ' battle crop', color='#a0a0a5', fontsize=9)
        ax.legend(facecolor='#0e0f12', edgecolor='#3a3c44', labelcolor='#ebebeb', fontsize=10, loc='upper right')
        fig.tight_layout(); p = os.path.join(OUT, f'_lod_{c}.png'); fig.savefig(p, facecolor=fig.get_facecolor()); plt.close(fig)
        parts += [tbar(NAMES.get(c, c), 'switch distances'), fitw(Image.open(p).convert('RGB'), W)]
        # the hand chain at each switch: just before and just after, same zoom
        for k, (a, b) in enumerate(((2.9, 3.1), (7.75, 8.25), (17.4, 18.6)), 1):
            pa, pb = os.path.join(GOD, f'{c}_hand_d{a}.png'), os.path.join(GOD, f'{c}_hand_d{b}.png')
            if not (os.path.exists(pa) and os.path.exists(pb)): continue
            ta, tb = crop_ship(pa, a, W // 2 - 4), crop_ship(pb, b, W // 2 - 4)
            r = Image.new('RGB', (W, ta.height + 34), BG); dr = ImageDraw.Draw(r)
            dr.text((10, 4), f'Switch to LOD{k} at {HD[k]:g} ship lengths ({int(px(HD[k]))} px): before | after, each zoomed to the ship', font=F(19), fill=DIM)
            r.paste(ta, (2, 32)); r.paste(tb, (W // 2 + 2, 32)); parts.append(r)
        for mode, t in (('off', 'LOD off'), ('auto', 'Godot auto LOD')):
            row = []
            for d in ('1.2', '3.0', '8.0', '16.0'):
                q = os.path.join(GOD, f'{c}_{mode}_d{d}.png')
                if os.path.exists(q): row.append(crop_ship(q, float(d), W // 4 - 4))
            if not row: continue
            r = Image.new('RGB', (W, row[0].height + 34), BG); dr = ImageDraw.Draw(r); dr.text((10, 4), t + ': at 1.2, 3, 8 and 16 ship lengths (zoomed to the ship)', font=F(19), fill=DIM)
            for k, t_ in enumerate(row): r.paste(t_, (k * (W // 4) + 2, 32))
            parts.append(r)
        q = os.path.join(GOD, f'{c}_hand_20.png')
        if os.path.exists(q):
            im = Image.open(q).convert('RGB'); parts += [note('Twenty copies, hand chain, the protocol camera (1080p):'), fitw(im.crop((360, 350, 1560, 800)), W)]
    stack(parts, 'lod.jpg')

def maps_sheet(cell):
    names = [(f'{cell}_hull_albedo.png', 'hull albedo (4096)'), (f'{cell}_hull_orm.png', 'hull ORM: occlusion, roughness, metal'),
             (f'{cell}_normal.png', 'hull detail normal (B0, large shape removed)'), (f'{cell}_b0ao.png', 'B0 cavity (trimmed source)'),
             (f'{cell}_parts_albedo.png', 'parts albedo (2048)'), (f'{cell}_parts_orm.png', 'parts ORM')]
    parts = [head(f'{cell}: baked maps', 'Everything the game draws for the paint: two atlases, no procedural shader at run time.')]
    tiles = []
    for f, t in names:
        p = os.path.join(MAPS, f)
        if not os.path.exists(p): continue
        im = Image.open(p).convert('RGB'); im.thumbnail((W // 2 - 8, W // 2 - 8)); tiles.append((t, im))
    for i in range(0, len(tiles), 2):
        r = Image.new('RGB', (W, W // 2 + 30), BG); d = ImageDraw.Draw(r)
        for k, (t, im) in enumerate(tiles[i:i + 2]): r.paste(im, (k * W // 2 + 4, 30)); d.text((k * W // 2 + 8, 4), t, font=F(19), fill=DIM)
        parts.append(r)
    stack(parts, 'maps.jpg')

def close_sheet():
    """casemate and drum rack, Hy4's generated part (left) against Ab5's hand rebuild (right), same lights, same zoom"""
    def ci(c, v):
        p = os.path.join(CLOSE, f'{c}_{v}.png'); return Image.open(p).convert('RGB') if os.path.exists(p) else None
    parts = [head('Close up: generated against hand built', 'Left: Hy4, the generated part. Right: Ab5, the hand rebuild. Same zoom.')]
    for v, t in (('cas', 'Casemate, from the port quarter'), ('casfront', 'Casemate, from ahead'), ('rack', 'Drum rack, from above')):
        for suf, tt in (('', 'paint'), ('_clay', 'clay (shape only)')):
            a, b = ci('Hy4', v + suf), ci('Ab5', v + suf)
            if a is None or b is None: continue
            l, r = fitw(a, W // 2 - 4), fitw(b, W // 2 - 4); row = Image.new('RGB', (W, l.height + 8), BG)
            row.paste(l, (2, 4)); row.paste(r, (W // 2 + 2, 4)); parts += [tbar(f'{t}: {tt}', 'Hy4 | Ab5'), row]
    stack(parts, 'close_parts.jpg')

if __name__ == '__main__':
    sheets()
    if GOD: lod_sheet([c for c in ('Ab4', 'Hy4', 'Ab5') if c in CELLS])
    if MAPS: maps_sheet('Ab5' if 'Ab5' in CELLS else CELLS[-1])
    if CLOSE: close_sheet()
