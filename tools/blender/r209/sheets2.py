# Issue 209 round 2: comparison sheets (1080 px wide, phone-readable). Same layouts as round 1's sheets.py (overview, battle crop,
# close views in nine cells, break view), with round 1 and round 2 cells side by side, plus the Godot LOD and cost sheet.
# usage: python3 sheets2.py RENDER_DIRS(comma) JSON_DIRS(comma) CONCEPT_PNG OUT_DIR CELLS [GODOT_DIR]
import os, sys, json
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
RD, JD = sys.argv[1].split(','), sys.argv[2].split(','); CONCEPT, OUT = sys.argv[3:5]; CELLS = sys.argv[5].split(',')
GOD = sys.argv[6] if len(sys.argv) > 6 else None
os.makedirs(OUT, exist_ok=True); W = 1080; BG = (14, 15, 18); FG = (235, 235, 235); DIM = (160, 160, 165)
F = lambda s, b=False: ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if b else ''), s)
NAMES = {'A': 'A round 1  hand build', 'B3': 'B3 round 1  AI parts, hand core', 'A2': 'A round 2  structure + detail rung',
         'B3r2': 'B3 round 2  AI parts on the new core', 'Ab': 'Ab  new hull + B0 detail baked in', 'B0r2': 'B0  whole generation (control)',
         'A2s': 'A round 2  structure only'}
def find(name, dirs):
    for d in dirs:
        p = os.path.join(d, name)
        if os.path.exists(p): return p
def meta(c):
    p = find(c + '.json', JD); return json.load(open(p)) if p else {}
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
def stack(parts, name):
    h = sum(p.height for p in parts); out = Image.new('RGB', (W, h), BG); y = 0
    for p in parts: out.paste(p, (0, y)); y += p.height
    out.save(os.path.join(OUT, name), quality=88); print('sheet', name, out.size)
def fitw(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
def content_box(ims, pad=12):
    import numpy as np
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

def sheets():
    parts = [head('Issue 209 round 2: C15s Hullbreaker cruiser', 'Same paint, lights and cameras as round 1. Each cell: paint, then clay.')]
    c = Image.open(CONCEPT).convert('RGBA'); bgi = Image.new('RGBA', c.size, BG + (255,)); bgi.alpha_composite(c); c = bgi.convert('RGB').crop((0, 100, 1024, 840))
    cb = Image.new('RGB', (W, 52), (28, 30, 36)); ImageDraw.Draw(cb).text((16, 10), 'Concept (the target)', font=F(27, True), fill=FG); parts += [cb, fitw(c, W)]
    heroes = [img(x, 'hero') for x in CELLS] + [img(x, 'hero_clay') for x in CELLS]; hb = content_box(heroes)
    for x in CELLS:
        a, b = img(x, 'hero'), img(x, 'hero_clay')
        if a is None: continue
        if hb: a, b = a.crop(hb), b.crop(hb)
        parts += [bar(x), fitw(a, W), fitw(b, W)]
    stack(parts, 'overview.jpg')
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

def lod_sheet(cells):
    """Godot: the LOD switch distances (triangles drawn by camera distance, one ship) and stills with LOD on and off"""
    import numpy as np
    import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
    B = json.load(open(os.path.join(GOD, 'bench209.json'))); L = B['length_world']
    parts = [head('Godot: level of detail', "Godot's automatic LOD, default 1 px threshold. One ship, battle camera angle.")]
    for c in cells:
        cd = B['cells'].get(c)
        if not cd or 'sweep_on' not in cd: continue
        sw = np.array(cd['sweep_on'], float); off = np.array(cd['sweep_off'], float)
        px = L * 1080 / (2 * np.tan(np.radians(22.5)) * sw[:, 0] * L)   # ship length on a 1080p screen, pixels
        fig, ax = plt.subplots(figsize=(10.8, 3.3), dpi=100); fig.patch.set_facecolor('#0e0f12'); ax.set_facecolor('#0e0f12')
        ax.step(px, sw[:, 1] / 1000, where='post', color='#6fa8dc', lw=2)
        ax.set_xscale('log'); ax.invert_xaxis(); ax.set_xlabel('ship length on a 1080p screen (pixels); further away to the right', color='#a0a0a5', fontsize=11)
        ax.set_ylabel('thousand triangles\ndrawn (with shadows)', color='#a0a0a5', fontsize=11)
        for s in ax.spines.values(): s.set_color('#3a3c44')
        ax.tick_params(colors='#a0a0a5'); ax.grid(True, color='#24262c', lw=.6)
        for xb in (180,): ax.axvline(xb, color='#a0a0a5', lw=1, ls=':'); ax.text(xb, ax.get_ylim()[1] * .92, ' battle crop', color='#a0a0a5', fontsize=10)
        ax.set_title(f'{NAMES.get(c, c)}: LOD off draws {int(off[:, 1].max() / 1000)}k at every distance', color='#ebebeb', fontsize=13, loc='left')
        fig.tight_layout(); p = os.path.join(OUT, f'_lod_{c}.png'); fig.savefig(p, facecolor=fig.get_facecolor()); plt.close(fig)
        parts += [tbar(NAMES.get(c, c), 'LOD switch distances'), fitw(Image.open(p).convert('RGB'), W)]
        # stills: LOD off over LOD on, four distances, cropped round the ship
        row_off, row_on = [], []
        for d in ('1.2', '3.0', '8.0', '16.0'):
            for lod, row in (('off', row_off), ('on', row_on)):
                q = os.path.join(GOD, f'{c}_lod{lod}_d{d}.png')
                if not os.path.exists(q): continue
                im = Image.open(q).convert('RGB'); s = 1080 / (2 * np.tan(np.radians(22.5)) * float(d)) * .65
                cx, cy = 960, 540; s = max(60, min(int(s), 1000)); row.append(im.crop((cx - s, cy - int(s * .6), cx + s, cy + int(s * .6))).resize((W // 4 - 4, int((W // 4 - 4) * .6))))
        for t, row in (('LOD off', row_off), ('LOD on', row_on)):
            if not row: continue
            r = Image.new('RGB', (W, row[0].height + 34), BG); dr = ImageDraw.Draw(r); dr.text((10, 4), t + ': at 1.2, 3, 8 and 16 ship lengths (each still zoomed to the ship)', font=F(19), fill=DIM)
            for k, t_ in enumerate(row): r.paste(t_, (k * (W // 4) + 2, 32))
            parts.append(r)
    stack(parts, 'lod.jpg')

if __name__ == '__main__':
    sheets()
    if GOD: lod_sheet([c for c in ('A2', 'B3r2', 'Ab') if c in CELLS])
