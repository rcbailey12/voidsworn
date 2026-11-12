# Build sheet layout (issue 532). Plain python with Pillow and numpy (no Blender).
#   python layout.py <render dir> <repo root> <out dir>
# Reads <render dir>/<code>_model.json and the renders build.py wrote, measures length, beam and height off the
# orthographic renders themselves (so the printed numbers are what the views show), annotates every view from the one
# model, and writes sheet.jpg, preview.jpg (720 px tall), the views and feature_table.md into <out dir>.
import sys, os, json, math, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont

RD, REPO, OUT = sys.argv[1:4]
os.makedirs(OUT, exist_ok=True)
M = json.load(open(glob.glob(os.path.join(RD, '*_model.json'))[0]))
CODE = M['code']
GREY = (58, 58, 60)
INK = (232, 228, 218)
DIM = (160, 158, 150)
ACC = (240, 170, 80)
RED = (235, 70, 55)
CYAN = (90, 200, 235)


def font(n, bold=False):
    for f in (('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf'), ('consolab.ttf' if bold else 'consola.ttf'), 'arial.ttf'):
        for d in ('/usr/share/fonts/truetype/dejavu/', 'C:/Windows/Fonts/', ''):
            try:
                return ImageFont.truetype(d + f, n)
            except OSError:
                pass
    return ImageFont.load_default()


OFF = {}
PADS = {'side': (40, 70, 90), 'cutaway': (40, 70, 90), 'top': (110, 80, 90), 'underside': (20, 80, 90), 'bow': (20, 90, 20), 'stern': (20, 70, 20)}


def flat(name):
    im = Image.open(os.path.join(RD, name + '.png')).convert('RGBA')
    sc_ = M['views'].get(name, {}).get('px_per_unit', 40) / 40.0
    l_, t_, b_ = [int(v * sc_) for v in PADS.get(name, (0, 0, 0))]
    bg = Image.new('RGBA', (im.width + 2 * l_, im.height + t_ + b_), GREY + (255,)); bg.alpha_composite(im, (l_, t_))
    a = np.zeros((bg.height, bg.width), bool); a[t_:t_ + im.height, l_:l_ + im.width] = np.asarray(im)[..., 3] > 8
    OFF[name] = (l_, t_)
    return bg.convert('RGB'), a


V = M['views']
L = M['length']; XT = M['x_tip']; ML = M['model_length']


def proj(view, p):
    v = V[view]; k = v['px_per_unit']; W, H = v['res']; ox, oy = OFF.get(view, (0, 0))
    d = np.array(p, float) - np.array(v['centre'])
    return ox + W / 2 + k * float(np.dot(d, v['right'])), oy + H / 2 - k * float(np.dot(d, v['up']))


def station(x):
    return (XT - x) / ML * 100


def extent(alpha, axis):
    idx = np.where(alpha.any(axis=axis))[0]
    return int(idx[0]), int(idx[-1])


def dashed(dr, a, b, fill, w=2, dash=10):
    a = np.array(a, float); b = np.array(b, float); v = b - a; n = np.linalg.norm(v)
    if n < 1:
        return
    for t in np.arange(0, n, dash * 2):
        dr.line([tuple(a + v * t / n), tuple(a + v * min(t + dash, n) / n)], fill=fill, width=w)


def label(dr, xy, s, fnt, fill=INK, box=True):
    x, y = xy
    bb = dr.textbbox((x, y), s, font=fnt)
    if box:
        dr.rectangle((bb[0] - 3, bb[1] - 2, bb[2] + 3, bb[3] + 2), fill=(30, 30, 32))
    dr.text((x, y), s, font=fnt, fill=fill)


k = V['side']['px_per_unit']
SC = k / 40.0
f_s, f_m, f_l, f_xl = font(int(20 * SC)), font(int(26 * SC)), font(int(36 * SC), True), font(int(56 * SC), True)
LH = int(30 * SC)

# ---------------- measured numbers off the renders ----------------
side, a_side = flat('side'); top, a_top = flat('top'); und, a_und = flat('underside')
bow, a_bow = flat('bow'); stern, a_stern = flat('stern'); cut, _ = flat('cutaway')
sx0, sx1 = extent(a_side, 0); sz0, sz1 = extent(a_side, 1)
ty0, ty1 = extent(a_top, 1); tx0, tx1 = extent(a_top, 0)
len_side = (sx1 - sx0 + 1) / k; len_top = (ty1 - ty0 + 1) / k
height = (sz1 - sz0 + 1) / k
# widest beam, from the top render, row by row (fittings included), and of the hull alone at that row
rows = [(r, *np.where(a_top[r])[0][[0, -1]]) for r in range(a_top.shape[0]) if a_top[r].any()]
wr = max(rows, key=lambda t: t[2] - t[1]); beam = (wr[2] - wr[1] + 1) / k
beam_st = (wr[0] - ty0) / (ty1 - ty0) * 100
# bow-on cross-check
bx0, bx1 = extent(a_bow, 0); bz0, bz1 = extent(a_bow, 1)
beam_bow = (bx1 - bx0 + 1) / k; height_bow = (bz1 - bz0 + 1) / k
checks = dict(length_from_game=L, model_length=ML, length_side=round(len_side, 3), length_top=round(len_top, 3),
              length_disagreement_percent=round(abs(len_side - len_top) / L * 100, 2),
              model_vs_game_percent=round(abs(ML - L) / L * 100, 2),
              beam_top=round(beam, 3), beam_bow=round(beam_bow, 3), beam_disagreement_percent=round(abs(beam - beam_bow) / L * 100, 2),
              height_side=round(height, 3), height_bow=round(height_bow, 3),
              height_disagreement_percent=round(abs(height - height_bow) / L * 100, 2),
              widest_at_station_percent=round(beam_st, 1))
# hull-only ratios (the proportion check, fittings excluded)
hull_h = [m for m in M['masses'] if m['obj'] == CODE + '_hull' or m['name'].startswith('Hull')][0]
hull_beam = hull_h['y'][1] - hull_h['y'][0]
checks['hull_beam'] = round(hull_beam, 2); checks['hull_depth'] = round(hull_h['z'][1] - hull_h['z'][0], 2)
checks['L_to_B_hull'] = round(L / hull_beam, 2); checks['L_to_H_hull'] = round(L / checks['hull_depth'], 2)
checks['PASS'] = bool(checks['length_disagreement_percent'] <= 2 and checks['model_vs_game_percent'] <= 2
                      and checks['beam_disagreement_percent'] <= 2 and checks['height_disagreement_percent'] <= 2)
fit = os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '_camera.json')
if os.path.exists(fit):
    fj = json.load(open(fit)); checks['outline_iou_percent'] = round(fj.get('iou', 0) * 100, 1)
    checks['mass_outline_iou_percent'] = round(fj.get('body_iou', 0) * 100, 1)
    checks['concept_camera'] = {kk: fj[kk] for kk in ('az', 'el', 'roll', 'dist', 'mm', 'sx', 'sy') if kk in fj}


F = M['features']
GUNS = [f for f in F if f['kind'] in ('gun', 'launcher')]


def aimtxt(f):
    if f.get('aim') is None:
        return '-'
    yaw, pitch = f['aim']
    if f['kind'] == 'engine':
        return 'exhaust aft'
    if f['kind'] == 'claw':
        return 'hook forward and down'
    side = 'port' if yaw > 2 else ('starboard' if yaw < -2 else '')
    s = 'forward' if abs(yaw) <= 2 else '%d deg off the bow to %s' % (abs(round(yaw)), side)
    if abs(pitch) >= 3:
        s += ', %+d elev' % round(pitch)
    return s


def side_of(y):
    return 'C' if abs(y) < 0.3 else ('P' if y > 0 else 'S')


# ---------------- annotate the orthographic views ----------------
def ann(view, im, alpha, hide_far=None, belly_only=False):
    dr = ImageDraw.Draw(im)
    for f in F:
        p = f['pos']
        if view == 'top' and f['kind'] in ('claw', 'bay') :
            continue
        if view == 'underside' and f['kind'] not in ('claw', 'bay', 'intake', 'engine', 'fitting') and p[2] > -0.5:
            continue
        u, v = proj(view, p)
        far = hide_far is not None and hide_far(p)
        col = DIM if far else ACC
        tip = f.get('muzzle', [None])[0] if f.get('muzzle') else (f.get('tip') or f.get('exit') or f.get('end'))
        if tip is not None and view in ('side', 'top', 'underside'):
            tu, tv = proj(view, tip)
            if far:
                dashed(dr, (u, v), (tu, tv), DIM, 2, 6)
        txt = f['id']
        r = 7
        if far:
            dr.ellipse((u - r, v - r, u + r, v + r), outline=DIM, width=2)
        else:
            dr.ellipse((u - r, v - r, u + r, v + r), outline=ACC, width=3)
        label(dr, (u + 9 * SC, v - 26 * SC), txt, f_s, fill=col, box=not far)
    return dr


W_S, H_S = side.size
# side view: stations, dimensions, scale bar
dr = ann('side', side, a_side, hide_far=lambda p: p[1] < -0.5)
for i in range(11):
    x = XT - ML * i / 10; u, _ = proj('side', (x, 0, 0))
    dr.line((u, H_S - 88 * SC, u, H_S - 76 * SC), fill=DIM, width=2); label(dr, (u - 14 * SC, H_S - 74 * SC), '%d%%' % (i * 10), f_s, DIM, box=False)
y0 = sz0 - 30
dr.line((sx0, y0, sx1, y0), fill=CYAN, width=2)
for xx in (sx0, sx1):
    dr.line((xx, y0 - 10, xx, y0 + 10), fill=CYAN, width=2)
label(dr, ((sx0 + sx1) / 2 - 150, y0 - 34), 'length %.2f units (game %.1f)' % (len_side, L), f_m, CYAN)
dr.line((sx1 + 30, sz0, sx1 + 30, sz1), fill=CYAN, width=2)
label(dr, (sx1 - 330 * SC, sz1 - 40 * SC), 'height %.2f (claw tip to turret); hull %.2f' % (height, checks['hull_depth']), f_s, CYAN)


def scalebar(dr, x, y):
    for i in range(5):
        dr.rectangle((x + i * k, y, x + (i + 1) * k, y + 12), fill=INK if i % 2 == 0 else (90, 90, 90))
    dr.rectangle((x, y, x + 5 * k, y + 12), outline=INK, width=1)
    label(dr, (x, y + 16), '0', f_s, INK, box=False); label(dr, (x + 5 * k - 30, y + 16), '5 units', f_s, INK, box=False)


import importlib.util as _ilu
_sp = _ilu.spec_from_file_location('ship', os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '.py'))
_sm = _ilu.module_from_spec(_sp)
try:
    import types; sys.modules.setdefault('bpy', types.ModuleType('bpy')); _sp.loader.exec_module(_sm)
    deck_x = max(r[0] for r in _sm.HULL)
except Exception as ex:
    print('no hull table', ex); deck_x = None
if deck_x is not None:
    ov = XT - deck_x
    checks['prow_overhang'] = round(ov, 2)
    u0, _ = proj('side', (XT, 0, 0)); u1, _ = proj('side', (deck_x, 0, 0)); yv = sz0 + 20 * SC
    dr.line((u0, yv, u1, yv), fill=ACC, width=3)
    for uu in (u0, u1):
        dr.line((uu, yv - 10, uu, yv + 10), fill=ACC, width=3)
    label(dr, (u0, yv + 12 * SC), 'prow overhang %.2f (forward-most point to the forward end of the deck edge)' % ov, f_s, ACC)
scalebar(dr, 30 * SC, H_S - 44 * SC)
label(dr, (14 * SC, 14 * SC), 'TRUE SIDE (port beam, bow left, level)', f_m)
label(dr, (14 * SC, 50 * SC), 'grey rings: far-side fittings', f_s, DIM)

# top view
dr = ann('top', top, a_top)
W_T, H_T = top.size
for i in range(11):
    x = XT - ML * i / 10; _, v = proj('top', (x, 0, 0))
    dr.line((8, v, 30 * SC, v), fill=DIM, width=2); label(dr, (34 * SC, v - 12 * SC), '%d%%' % (i * 10), f_s, DIM, box=False)
dr.line((wr[1], wr[0], wr[2], wr[0]), fill=CYAN, width=2)
label(dr, (wr[1], wr[0] + 6), 'beam %.2f over barrels at %.0f%%; hull %.2f' % (beam, beam_st, hull_beam), f_s, CYAN)
dr.line((W_T - 40, ty0, W_T - 40, ty1), fill=CYAN, width=2)
label(dr, (W_T - 330 * SC, ty1 - 40 * SC), 'length %.2f' % len_top, f_m, CYAN)
scalebar(dr, 110 * SC, H_T - 44 * SC)
label(dr, (14, 14), 'TRUE TOP (bow up, port left)', f_m)
label(dr, (14, 48 * SC), 'belly items (claws, bay) not shown: see underside', f_s, DIM)

# underside
dr = ann('underside', und, a_und)
scalebar(dr, 30 * SC, H_T - 44 * SC)
label(dr, (14, 14), 'UNDERSIDE (from below)', f_m)
label(dr, (14, 48 * SC), 'bow up, port on the right', f_s, DIM)

# bow and stern
dr = ImageDraw.Draw(bow)
label(dr, (14, 14), 'BOW-ON (port right)', f_m)
label(dr, (14, 52 * SC), 'beam %.2f  height %.2f' % (beam_bow, height_bow), f_s, CYAN)
dr = ImageDraw.Draw(stern)
label(dr, (14, 14), 'ENGINE END (port left)', f_m)
for f in F:
    if f['kind'] == 'engine':
        u, v = proj('stern', f['exit']); label(dr, (u - 12, v - 12), f['id'], f_s, ACC)
for f in F:
    if f['kind'] in ('intake', 'dish', 'claw'):
        u, v = proj('bow', f['pos']); label(ImageDraw.Draw(bow), (u - 12, v - 12), f['id'], f_s, ACC)

# cutaway with inside labels
dr = ImageDraw.Draw(cut)
INS = M['inside']
SPN = {}
for r in INS:
    if r['kind'] == 'space' and r['y'][0] < 0.05:
        u0, v0 = proj('cutaway', (r['x'][1], 0, r['z'][1])); u1, v1 = proj('cutaway', (r['x'][0], 0, r['z'][0]))
        SPN[r['name']] = len(SPN) + 1
        label(dr, ((u0 + u1) / 2 - 10 * SC, (v0 + v1) / 2 - 12 * SC), str(SPN[r['name']]), f_m, INK)
    if r['kind'] == 'break':
        if r.get('path'):
            pts = [proj('cutaway', (x_, 0, z_)) for x_, z_ in r['path']]
            for a_, b_ in zip(pts, pts[1:]):
                dashed(dr, a_, b_, RED, int(5 * SC / 2) + 2, 10)
            lx, ly = pts[0] if r.get('orient') != 'long' else pts[len(pts) // 2]
            label(dr, (lx + 6, ly - 40 * SC), r['name'] + (' (long)' if r.get('orient') == 'long' else ''), f_m, RED)
        else:
            u, _ = proj('cutaway', (r['x'], 0, 0))
            dashed(dr, (u, 40 * SC), (u, cut.size[1] - 90 * SC), RED, 4, 14)
            label(dr, (u + 6, 44 * SC), r['name'], f_m, RED)
    if r['kind'] == 'bulkhead':
        u, _ = proj('cutaway', (r['x'], 0, 0))
        label(dr, (u - 12, cut.size[1] - 86 * SC), r['name'], f_s, DIM, box=False)
    if r['kind'] == 'deck':
        _, v = proj('cutaway', (0, 0, r['z']))
        label(dr, (6, v - 12 * SC), r['name'] + ' deck', f_s, DIM, box=False)
for p in M['points']:
    if p['kind'] in ('breach', 'core'):
        u, v = proj('cutaway', p['pos'])
        rr = 9
        dr.polygon([(u, v - rr), (u + rr, v), (u, v + rr), (u - rr, v)], outline=RED if p['kind'] == 'breach' else ACC, width=3)
        label(dr, (u + 10, v + 4), p['name'].replace('hp_breach_', 'b').replace('hp_', ''), f_s, RED if p['kind'] == 'breach' else ACC, box=False)
label(dr, (14, 8), 'INSIDE: side section on the centreline (port half removed)', f_s)
scalebar(dr, 30 * SC, cut.size[1] - 44 * SC)

# beauty and blockout three-quarter
beauty = Image.open(os.path.join(REPO, M['beauty'])).convert('RGB')
tq, _ = flat('threequarter')

for nm, im in (('side', side), ('top', top), ('underside', und), ('bow', bow), ('stern', stern), ('cutaway', cut), ('threequarter', tq)):
    im.save(os.path.join(OUT, nm + '.png'))

json.dump(checks, open(os.path.join(OUT, 'checks.json'), 'w'), indent=1)
print(json.dumps(checks))
# ---------------- manifest (R214): every part, its route, and the break pieces ----------------
ARCS_ = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0)}
SHT = M.get('sheet') or dict(version=3, round='round 3', date='2026-11-11', blend='opus532\\r3b')
KITN = M.get('kit', 'hullbreakers')
man = dict(code=CODE, sheet_version=SHT.get('version', 3), routes_note='kit = the %s parts kit (tools/blender/kits/%s/parts.py, the same builders the build uses); hand-built = modelled for this hull; generated = from a reviewed part-library entry' % (KITN.capitalize(), KITN),
           turret_marking='R219: a turret is an empty <id>_turret at the ring centre (local +Z = mount normal) with custom properties turret=1, slot, weapon, arc_lo, arc_hi, arc_deg (bearings from the bow, + to port, core.js inArc), rest_yaw, rest_pitch; its turning meshes <id>_turn_<material> are its children; the ring <id>_mount_<material> stays on the hull. Casemates are single fixed parts (turret=0, gun_fixed=1).',
           parts=[], masses=[], break_pieces=[])
KITK = ('gun', 'launcher', 'engine', 'dish', 'intake', 'claw', 'chain', 'thruster', 'hatch', 'hatchbox', 'vent', 'lamp', 'antenna', 'pipe', 'bay', 'slit',
        'core', 'strut', 'corewin')
for f in F:
    row = dict(id=f['id'], kind=f['kind'], what=f['what'], count=f['count'], route='kit' if f['kind'] in KITK else 'hand-built',
               source=f['src'], inventory=f.get('inv', []))
    if f['kind'] == 'gun':
        tur = 'casemate' not in f['what'] and not f.get('fixed')
        row['turret'] = tur
        if tur:
            lo_, hi_ = ARCS_.get(f.get('slot') or 'T', (-180.0, 180.0))
            row.update(pivot_object=f['id'] + '_turret', arc_lo=lo_, arc_hi=hi_)
    man['parts'].append(row)
for m in M['masses']:
    man['masses'].append(dict(name=m['name'], route='hand-built'))
br = [r for r in M['inside'] if r['kind'] == 'break']
tr = sorted([r for r in br if r.get('orient') != 'long'], key=lambda r: -r['x'])
lg = [r for r in br if r.get('orient') == 'long']
edges = [XT] + [r['x'] for r in tr] + [XT - ML]
names = ['bow piece'] + ['midships piece %d' % i for i in range(1, len(tr))] + ['stern piece']
for i in range(len(edges) - 1):
    a_, b_ = edges[i], edges[i + 1]
    split = [r['name'] for r in lg if min(q[0] for q in r['path']) < a_ and max(q[0] for q in r['path']) > b_]
    nm_ = names[i] if i < len(names) else 'piece %d' % i
    if split:
        for half in ('upper', 'lower'):
            man['break_pieces'].append(dict(name='%s, %s half' % (nm_, half), stations='%.1f to %.1f percent' % (station(a_), station(b_)),
                                            bounded_by=[r['name'] for r in tr if r['x'] in (a_, b_)] + split, full_interior=True))
    else:
        man['break_pieces'].append(dict(name=nm_, stations='%.1f to %.1f percent' % (station(a_), station(b_)),
                                        bounded_by=[r['name'] for r in tr if r['x'] in (a_, b_)], full_interior=True))
man['insides'] = 'full interiors throughout the hull, hidden until a piece breaks (R215); every break piece carries its share'
json.dump(man, open(os.path.join(OUT, 'manifest.json'), 'w'), indent=1)

# ---------------- feature table ----------------
def r2(v):
    return '%.2f' % v


lines = []
lines.append('# %s: %s, build sheet\n' % (CODE, M['name']))
lines.append('%s | class %s | version %s (%s), %s | blockout: `C:\\Users\\rcbai\\Downloads\\voidsworn_test\\%s\\%s\\%s_blockout.blend`\n' % (
    M['faction'], M['cls'], SHT.get('version', 3), SHT.get('round', 'round 3'), SHT.get('date', '2026-11-11'), SHT.get('blend', 'opus532\\r3b'), CODE, CODE))
lines.append('**Length %.1f world units** (%s). Frame: +X bow, +Y port, +Z up; station %% from the prow tip; offset + port / - starboard; '
             'height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.\n' % (L, M['game']))
lines.append('## Measured off the views\n')
lines.append('| Check | Value |\n|---|---|')
for kk in ('model_length', 'length_side', 'length_top', 'length_disagreement_percent', 'beam_top', 'beam_bow', 'beam_disagreement_percent',
           'height_side', 'height_bow', 'height_disagreement_percent', 'widest_at_station_percent', 'hull_beam', 'hull_depth', 'L_to_B_hull', 'L_to_H_hull',
           'prow_overhang', 'outline_iou_percent', 'mass_outline_iou_percent', 'PASS'):
    if kk in checks:
        lines.append('| %s | %s |' % (kk.replace('_', ' '), checks[kk]))
lines.append('\n## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)\n')
lines.append('| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |\n|---|---|---:|---:|---:|---:|---|---|---|---|')
for f in F:
    cnt = '%d barrel%s' % (f['count'], 's' if f['count'] > 1 else '') if f['kind'] == 'gun' else ('%d tubes' % f['count'] if f['kind'] == 'launcher' else str(f['count']))
    slot = ('%s %s' % (f.get('slot', ''), f.get('weapon', ''))).strip() or '-'
    pts = aimtxt(f)
    if f['kind'] == 'chain':
        pts = 'to station %.1f%%, offset %s' % (station(f['end'][0]), r2(f['end'][1]))
    lines.append('| %s | %s | %s | %.1f | %s | %s | %s | %s | %s | %s |' % (
        f['id'], f['what'], cnt, f['station'], r2(f['pos'][1]), r2(f['pos'][2]), pts, slot, f['src'], f.get('note', '')))
ng = sum(f['count'] for f in F if f['kind'] == 'gun'); nm_ = sum(1 for f in F if f['kind'] == 'gun')
lines.append('\nTotals: %d gun mounts with %d barrels; %d launcher tubes; %d engines; %d intakes; %d dishes; %d claws; %d chains.' % (
    nm_, ng, sum(f['count'] for f in F if f['kind'] == 'launcher'), sum(1 for f in F if f['kind'] == 'engine'),
    sum(1 for f in F if f['kind'] == 'intake'), sum(1 for f in F if f['kind'] == 'dish'), sum(1 for f in F if f['kind'] == 'claw'),
    sum(1 for f in F if f['kind'] == 'chain')))
lines.append('No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).\n')
lines.append('## Colour zones (break stations from the side view; finish from the beauty)\n')
lines.append('| Zone | From % | To % | Where | Note |\n|---|---:|---:|---|---|')
for r in INS:
    if r['kind'] == 'colour':
        lines.append('| %s | %.1f | %.1f | %s | %s |' % (r['name'], max(0, station(r['x'][0])), min(100, station(r['x'][1])), r['where'], r.get('note', '')))
lines.append('\n## Major masses\n')
lines.append('| Mass | Station % | Offset range | Height range | Colour | Note |\n|---|---|---|---|---|---|')
for m in M['masses']:
    lines.append('| %s | %.1f to %.1f | %s to %s | %s to %s | %s | %s |' % (m['name'], m['st'][0], m['st'][1], r2(m['y'][0]), r2(m['y'][1]),
                                                                  r2(m['z'][0]), r2(m['z'][1]), m['role'], m.get('note', '')))
lines.append('\n## INSIDE (R98, R209): what each break reveals\n')
lines.append('Deck levels (height): ' + '; '.join('%s deck %.2f (%.0f%% to %.0f%%)' % (r['name'], r['z'], station(r['x'][1]), station(r['x'][0])) for r in INS if r['kind'] == 'deck') + '.\n')
lines.append('Bulkhead and frame stations: ' + ', '.join('%s %.1f%%' % (r['name'], station(r['x'])) for r in INS if r['kind'] == 'bulkhead') + '.\n')
lines.append('| Space | Station % | Offset range | Height range | Note |\n|---|---|---|---|---|')
for r in INS:
    if r['kind'] == 'space':
        lines.append('| %s (%s) | %.1f to %.1f | %s to %s | %s to %s | %s |' % (r['name'].replace('_', ' '), r['mat'], station(r['x'][1]), station(r['x'][0]),
                                                                    r2(r['y'][0]), r2(r['y'][1]), r2(r['z'][0]), r2(r['z'][1]), r.get('note', '')))
lines.append('\n| Armour zone | Thickness (units) | Note |\n|---|---:|---|')
for r in INS:
    if r['kind'] == 'armour':
        lines.append('| %s | %.2f | %s |' % (r['name'], r['t'], r.get('note', '')))
lines.append('\n| Break line | Station % | What it opens |\n|---|---|---|')
for r in INS:
    if r['kind'] == 'break':
        if r.get('orient') == 'long':
            xs = [q[0] for q in r['path']]
            st_ = '%.1f to %.1f (along)' % (station(max(xs)), station(min(xs)))
        else:
            xs = [q[0] for q in (r.get('path') or [(r['x'], 0)])]
            st_ = '%.1f (seam wanders %.1f to %.1f)' % (station(r['x']), station(max(xs)), station(min(xs)))
        lines.append('| %s | %s | %s |' % (r['name'], st_, r.get('note', '')))
    if r['kind'] == 'note':
        lines.append('\n%s\n' % r['note'])
lines.append('\n## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)\n')
lines.append('| Point | Station % | Offset | Height | Side | Section | Note |\n|---|---:|---:|---:|---|---|---|')
for p in M['points']:
    lines.append('| %s | %.1f | %s | %s | %s | %s | %s |' % (p['name'], p['station'], r2(p['pos'][1]), r2(p['pos'][2]), p.get('side', ''), p.get('section', ''), p.get('note', '')))
fj_ = os.path.join(RD, CODE + '_fit.json')
if os.path.exists(fj_):
    FJ = json.load(open(fj_))
    lines.append('\n## Fit check (RULEBOOK 5.15, R217 to R219)\n')
    lines.append('Clashes left: %s. Tested: %s. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); '
                 'picture: [fit_view.jpg](fit_view.jpg).' % (', '.join('%s %d' % kv for kv in FJ['counts'].items()),
                                                            ', '.join('%s %s' % (v, k_.replace('_', ' ')) for k_, v in FJ['tested'].items())))
    lines.append('\n## Parts inventory (R218)\n')
    lines.append('Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); '
                 'the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).')
lines.append('\n## Changed from the picture (R207)\n')
for w, why in M['changes']:
    lines.append('- **%s.** %s.' % (w, why))
lines.append('\n## Designed here, not shown in the picture\n')
for t in M['tbd']:
    lines.append('- %s.' % t)
for f in F:
    if f['src'] != 'picture':
        lines.append('- %s (%s): %s.' % (f['id'], f['what'], f.get('note', '')))
open(os.path.join(OUT, 'feature_table.md'), 'w').write('\n'.join(lines) + '\n')

# ---------------- the sheet ----------------
PAD = int(40 * SC)
col_l = W_T * 2 + PAD
SW = max(col_l + W_S + 3 * PAD, int(2800 * SC))
head = int(300 * SC)
# right column: side, cutaway, bow+stern
right_h = H_S + PAD + cut.size[1] + PAD + max(bow.size[1], stern.size[1])
body_h = max(H_T, right_h)
# table block under everything
tab_rows = [f for f in F]
tab_h = 60 + LH * (len(tab_rows) + 3)
ch_h = 50 + LH * (len(M['changes']) + 2)
SH = head + body_h + PAD + max(tab_h, ch_h) + int(2400 * SC) + int(SW * 0.4)
# R221 (ships.md 2c): the weapon row, each weapon type the ship carries beside its rules, its lore line and its design line,
# from the close-ups build.py renders (weapon_<id>.png) and the kit's WEAPONS table (in the model json)
import textwrap
WORDER = ['gauss', 'flak', 'gsentry', 'doom']   # main guns first, the fixed weapon last
WEAP = sorted([w for w in M.get('weapons', []) if os.path.exists(os.path.join(RD, w['image']))], key=lambda w: (WORDER.index(w['id']) if w['id'] in WORDER else 9, w['id']))
WR_W = (SW - PAD * (len(WEAP) + 1)) // max(1, len(WEAP)) if WEAP else 0
WR_IH = int(WR_W * 0.7)
WR_WRAP = max(40, int(WR_W / (11.5 * SC)))


def weapon_text(w):
    out = [('%s  (data.js %s; %s)' % (w.get('name', w['id']), w['id'], ', '.join(w.get('mounts', []))), f_m, INK)]
    for lab, key, col in (('Rules', 'rules', DIM), ('Lore', 'lore', ACC), ('Built as', 'design', INK)):
        for i, ln in enumerate(textwrap.wrap('%s: %s' % (lab, w.get(key, '')), WR_WRAP)):
            out.append((ln, f_s, col))
    return out


WR_H = (int(60 * SC) + WR_IH + int(20 * SC) + max(len(weapon_text(w)) for w in WEAP) * int(28 * SC) + int(40 * SC) + PAD) if WEAP else 0
SH += WR_H
sheet = Image.new('RGB', (SW, SH), (44, 44, 46))
dr = ImageDraw.Draw(sheet)
dr.text((PAD, 30), '%s  |  %s' % (CODE, M['name']), font=f_xl, fill=INK)
dr.text((PAD, int(110 * SC)), '%s  |  class %s  |  length %.1f world units (%s)' % (M['faction'], M['cls'], L, 'hull_table.gd CLS_LEN'), font=f_m, fill=INK)
dr.text((PAD, int(150 * SC)), ('Build sheet v%s (%s, R217 to R219), %s. Every view' % (SHT.get('version', 3), SHT.get('round', 'round 3'), SHT.get('date', '2026-11-11'))) + ': an orthographic render of ONE Blender blockout, one scale (%d px per unit). Side %.2f / top %.2f long (%.2f%% apart).' % (k, len_side, len_top, checks['length_disagreement_percent']), font=f_m, fill=DIM)
dr.text((PAD, int(190 * SC)), 'Orange rings: feature-table IDs. Grey rings, dashed: far side. Station % from the prow tip. Counts in the table outrank the pictures.', font=f_m, fill=DIM)
# FIRST: the accepted beauty beside the blockout at the camera fitted to it (R213)
bcam = Image.open(os.path.join(RD, 'beauty_cam.png')).convert('RGBA'); bgc = Image.new('RGBA', bcam.size, GREY + (255,)); bgc.alpha_composite(bcam)
bcam = bgc.convert('RGB')
BW = (SW - 3 * PAD) // 2; BH = int(BW * beauty.height / beauty.width)
dr.text((PAD, head - int(10 * SC)), 'ACCEPTED BEAUTY (identity: finish, colour, character)', font=f_m, fill=INK)
dr.text((2 * PAD + BW, head - int(10 * SC)), 'THE BLOCKOUT at the camera fitted to the beauty (same model as every view below)', font=f_m, fill=INK)
sheet.paste(beauty.resize((BW, BH)), (PAD, head + int(30 * SC)))
sheet.paste(bcam.resize((BW, BH)), (2 * PAD + BW, head + int(30 * SC)))
head = head + int(30 * SC) + BH + PAD
if WEAP:
    dr.text((PAD, head), 'WEAPONS: each weapon built from what it is (R221; lore bible 7, factions.md, data.js), shown alone at the same angle',
            font=f_l, fill=INK)
    for i, w in enumerate(WEAP):
        x0 = PAD + i * (WR_W + PAD)
        im = Image.open(os.path.join(RD, w['image'])).convert('RGBA')
        bg_ = Image.new('RGBA', im.size, GREY + (255,)); bg_.alpha_composite(im)
        sheet.paste(bg_.convert('RGB').resize((WR_W, WR_IH)), (x0, head + int(60 * SC)))
        ty = head + int(60 * SC) + WR_IH + int(20 * SC)
        for ln, fn_, col in weapon_text(w):
            dr.text((x0, ty), ln, font=fn_, fill=col); ty += int(28 * SC) if fn_ is f_s else int(34 * SC)
    head += WR_H
y = head
sheet.paste(top, (PAD, y)); sheet.paste(und, (PAD + W_T + PAD // 2, y))
xr = col_l + PAD
sheet.paste(side, (xr, y))
sheet.paste(cut, (xr, y + H_S + PAD))
yb = y + H_S + PAD + cut.size[1] + PAD
sheet.paste(bow, (xr, yb)); sheet.paste(stern, (xr + bow.width + PAD, yb))
# identity: the accepted beauty and the blockout's own three-quarter, in the space under the plan views
iy = y + H_T + PAD; iw = col_l - PAD
room = max(body_h - H_T - PAD, int(500 * SC))
bh = min(room // 2 - int(40 * SC), int(iw * beauty.height / beauty.width)); bw = int(beauty.width * bh / beauty.height)
tq_h = bh; tq_w = int(tq.width * tq_h / tq.height)
dr.text((PAD, iy), 'blockout three-quarter (45 deg to port of the bow, 30 up), same model as every view', font=f_m, fill=INK)
tq_h = min(room - int(60 * SC), int(iw * tq.height / tq.width)); tq_w = int(tq.width * tq_h / tq.height)
sheet.paste(tq.resize((tq_w, tq_h)), (PAD, iy + int(40 * SC)))
body_h = max(body_h, H_T + PAD + tq_h + int(60 * SC))
# text block: feature table (compact) and changes
y2 = head + body_h + PAD
dr.text((PAD, y2), 'FEATURE TABLE (full table with offsets and heights: feature_table.md)', font=f_l, fill=INK)
yy = y2 + int(50 * SC)
cols = [(c_, int(w_ * SC)) for c_, w_ in [('ID', 70), ('fitting', 420), ('count', 90), ('stn %', 100), ('offset', 110), ('height', 110), ('points', 440), ('slot', 170), ('source', 120)]]
x = PAD
for nm_c, w in cols:
    dr.text((x, yy), nm_c, font=f_s, fill=ACC); x += w
yy += LH
for f in F:
    cnt = str(f['count'])
    vals = [f['id'], f['what'][:38], cnt, '%.1f' % f['station'], r2(f['pos'][1]), r2(f['pos'][2]), aimtxt(f)[:38] if f['kind'] != 'chain' else 'lashing',
            ('%s %s' % (f.get('slot', ''), f.get('weapon', ''))).strip(), f['src']]
    x = PAD
    for (nm_c, w), v in zip(cols, vals):
        dr.text((x, yy), v, font=f_s, fill=INK if f['src'] == 'picture' else CYAN); x += w
    yy += LH
xc = PAD + sum(w for _, w in cols) + PAD
dr.text((xc, y2), 'CHANGED FROM THE PICTURE (R207)', font=f_l, fill=INK)
yy = y2 + int(50 * SC)
import textwrap
for w_, why in M['changes']:
    for i, ln in enumerate(textwrap.wrap('- %s: %s' % (w_, why), 95)):
        dr.text((xc + (0 if i == 0 else 20), yy), ln, font=f_s, fill=INK); yy += int(28 * SC)
yy += 20
dr.text((xc, yy), 'INSIDE: armour and break lines', font=f_l, fill=INK); yy += int(50 * SC)
for r in INS:
    if r['kind'] == 'armour':
        dr.text((xc, yy), '- armour %s: %.2f %s' % (r['name'], r['t'], r.get('note', '')), font=f_s, fill=INK); yy += int(28 * SC)
for r in INS:
    if r['kind'] == 'break':
        where = 'along the belt' if r.get('orient') == 'long' else 'at %.1f%%' % station(r['x'])
        for i, ln in enumerate(textwrap.wrap('- %s %s: %s' % (r['name'], where, r.get('note', '')), 95)):
            dr.text((xc + (0 if i == 0 else 20), yy), ln, font=f_s, fill=RED); yy += int(28 * SC)
for r in INS:
    if r['kind'] == 'note':
        for i, ln in enumerate(textwrap.wrap(r['note'], 95)):
            dr.text((xc + (0 if i == 0 else 20), yy), ln, font=f_s, fill=CYAN); yy += int(28 * SC)
for nm_s, n_s in SPN.items():
    r = [q for q in INS if q['kind'] == 'space' and q['name'] == nm_s][0]
    dr.text((xc, yy), '%d  %s: %s' % (n_s, nm_s.replace('_', ' '), r.get('note', '')), font=f_s, fill=INK); yy += int(28 * SC)
nb = sum(1 for p in M['points'] if p['kind'] == 'breach')
dr.text((xc, yy + 10), '- %d breach anchors (red diamonds), core (orange diamond); rcs, boarding and bay points in feature_table.md' % nb, font=f_s, fill=INK)
dr.text((xc, yy + 50), 'Cyan rows: designed here, not shown in the picture.', font=f_s, fill=CYAN)
sheet = sheet.crop((0, 0, SW, min(SH, max(yy + 120, y2 + 60 + LH * (len(F) + 3)))))
pv = sheet.resize((int(sheet.width * 720 / sheet.height), 720), Image.LANCZOS)  # the preview is the main sheet, before the extras
pv.save(os.path.join(OUT, 'preview.jpg'), quality=88)
extra = [Image.open(os.path.join(OUT, n_)).convert('RGB') for n_ in ('fit_view.jpg', 'cells.jpg') if os.path.exists(os.path.join(OUT, n_))]
if extra:
    ex_h = sum(int(e.height * min(1.0, (sheet.width - 2 * PAD) / e.width)) + PAD for e in extra)
    s2 = Image.new('RGB', (sheet.width, sheet.height + ex_h), (44, 44, 46)); s2.paste(sheet, (0, 0)); yy2 = sheet.height
    for e in extra:
        k_ = min(1.0, (sheet.width - 2 * PAD) / e.width)
        e = e.resize((int(e.width * k_), int(e.height * k_))); s2.paste(e, (PAD, yy2)); yy2 += e.height + PAD
    sheet = s2
sheet.save(os.path.join(OUT, 'sheet.jpg'), quality=90)
print('sheet', sheet.size, 'preview', pv.size)
