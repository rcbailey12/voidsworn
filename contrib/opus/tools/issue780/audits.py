# Issue 780 audits of a painted Hegemony job (sandbox, not standing checks): hegemony.md section 6's builder checks.
#   emissive   nothing on the intact ship over the game's 0.8 glow threshold, no warm emissive (the stack's emissive_audit: the
#              baked map's brightest pixel times its strength, and every flat light's colour times strength; red over blue fails)
#   cap        the value cap: the baked hull and parts albedo, times the light gain and the lift (the tone a face shows), against
#              #626d7d (no plate brighter): the share of painted pixels over it by more than 6 in any channel
#   lift       the hull's hue before and after the battle lift (a plain multiply swings no hue)
#   median     the hull median at the battle cameras (the long lens and cam170, the blue light and the background left out)
#              against the concept's hull median by the same method (R256: Sunward read darker than its concept)
#   symmetry   every decal placed on one side has its mirror on the other (y negated, within 0.002 ship lengths)
# usage: python audits.py JOB_DIR PREVIEW_DIR CELL CONCEPT_JPG OUT_JSON     (python with numpy and Pillow)
import os, sys, json, importlib.util, types
import numpy as np
from PIL import Image

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
JOB, PV, CELL, CONCEPT, OUT = sys.argv[1:6]
sys.modules.setdefault('bpy', types.ModuleType('bpy'))
sp = importlib.util.spec_from_file_location('hegemony_stack', os.path.join(REPO, 'tools/blender/kits/hegemony/stack.py'))
S = importlib.util.module_from_spec(sp); sp.loader.exec_module(S)
res = dict(emissive=S.emissive_audit(JOB, CELL))


def to_lin(a):
    a = a / 255.0; return np.where(a <= .04045, a / 12.92, ((a + .055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(c, 0, 1); return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055) * 255


cap = {}
for part in ('hull', 'parts'):
    a = np.asarray(Image.open(os.path.join(JOB, f'{CELL}_{part}_albedo.png')).convert('RGB')).astype(np.float64)
    lin = to_lin(a); m = lin.max(2) > .003
    show = to_srgb(lin[m] * S.LIGHT_GAIN * S.LIFT)
    over = (show > np.array(S.CAP) + 6).any(1)
    cap[part] = dict(px=int(m.sum()), median_show=[int(x) for x in np.median(show, 0)], p99_show=[int(x) for x in np.percentile(show, 99, 0)],
                     over_cap_share=round(float(over.mean()), 5))
res['cap'] = dict(cap=S.CAP, atlases=cap, pass_=all(v['over_cap_share'] < .005 for v in cap.values()))
alb = np.asarray(Image.open(os.path.join(JOB, f'{CELL}_hull_albedo.png')).convert('RGB')).astype(np.float64)
lin = to_lin(alb); m = lin.max(2) > .003


def hue(c):
    r, g, b = c; mx, mn = max(c), min(c)
    if mx - mn < 1e-9: return 0.0
    if mx == r: h = ((g - b) / (mx - mn)) % 6
    elif mx == g: h = (b - r) / (mx - mn) + 2
    else: h = (r - g) / (mx - mn) + 4
    return round(60 * h, 2)


med = np.median(lin[m], 0)
res['lift'] = dict(lift=S.LIFT, hue_before=hue(med), hue_after=hue(np.minimum(med * S.LIFT, 1)), median_albedo_lin=[round(float(x), 5) for x in med])


def hull_median(a, bg=None):
    bg = a[:8, :8].reshape(-1, 3).mean(0) if bg is None else bg
    ship = np.abs(a - bg).sum(2) > 24
    blue = (a[..., 2] > a[..., 0] * 1.6) & (a[..., 2] > 120)        # the blue light, not the hull
    return [int(x) for x in np.median(a[ship & ~blue], 0)], round(float(blue[ship].mean()), 4)


con = np.asarray(Image.open(CONCEPT).convert('RGB')).astype(np.float64)
cm, cb = hull_median(con)
res['median'] = dict(concept_hull_median=cm, concept_blue_share=cb)
for v in ('paint_battle', 'paint_cam170', 'paint_beauty'):
    p = os.path.join(PV, v + '.png')
    if os.path.exists(p):
        md, bs = hull_median(np.asarray(Image.open(p).convert('RGB')).astype(np.float64), bg=np.zeros(3))
        res['median'][v] = dict(hull_median=md, blue_share=bs, minus_concept=[x - y for x, y in zip(md, cm)])
J = json.load(open(os.path.join(JOB, f'{CELL}.json')))
dec = [d for d in J['paint']['decals'] if d.get('placed')]
pairs = []
for d in dec:
    x, y, z = d['pos']
    if abs(y) < .002: pairs.append(dict(rule=d['rule'], centreline=True)); continue
    mate = [e for e in dec if abs(e['pos'][0] - x) < .002 and abs(e['pos'][1] + y) < .002 and abs(e['pos'][2] - z) < .002]
    pairs.append(dict(rule=d['rule'], side=d['side'], mirrored=bool(mate)))
res['symmetry'] = dict(decals=pairs, unplaced=[d['rule'] + ' ' + d['side'] for d in J['paint']['decals'] if not d.get('placed')],
                       pass_=all(p.get('mirrored', True) for p in pairs))
json.dump(res, open(OUT, 'w'), indent=1, default=lambda o: bool(o) if isinstance(o, np.bool_) else float(o))
print(json.dumps(res, indent=1, default=lambda o: bool(o) if isinstance(o, np.bool_) else float(o)))
