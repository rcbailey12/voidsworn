# Issue 756 audits of a painted S8 job (sandbox, not standing checks): sunward.md section 6's builder checks.
#   emissive   nothing on the intact ship over the game's 0.8 glow threshold, no blue over green (the stack's emissive_audit:
#              the baked map's brightest pixel times its strength, and every flat light's colour times strength)
#   frost      the frost marking coverage against the 6 percent cap, per visible face: the share of the ship's pixels in the
#              flat views (paint_top, paint_side, paint_side_s) that are frost-white paint (bright, near neutral or cool; the
#              ember and the frost lamps excluded by hue and by the lamps' own small count)
#   lift       the hull's hue before and after the battle lift (the game multiplies the albedo by the lift; a plain multiply
#              swings no hue, measured on the baked hull albedo's plate pixels)
#   median     the hull median at the battle camera against the iron pair's band (sunward.md 6: one main colour)
# usage: python audits.py JOB_DIR PREVIEW_DIR OUT_JSON     (python with numpy and Pillow; the stack is imported for its numbers)
import os, sys, json, importlib.util, types
import numpy as np
from PIL import Image

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
JOB, PV, OUT = sys.argv[1:4]
sys.modules.setdefault('bpy', types.ModuleType('bpy'))
sp = importlib.util.spec_from_file_location('sunward_stack', os.path.join(REPO, 'tools/blender/kits/voidsworn/stack.py'))
S = importlib.util.module_from_spec(sp); sp.loader.exec_module(S)
res = dict(emissive=S.emissive_audit(JOB, 'S8'))


def srgb_to_lin(a):
    a = a / 255.0; return np.where(a <= .04045, a / 12.92, ((a + .055) / 1.055) ** 2.4)


frost = {}
for v in ('paint_top', 'paint_side', 'paint_side_s'):
    p = os.path.join(PV, v + '.png')
    if not os.path.exists(p): continue
    a = np.asarray(Image.open(p).convert('RGB')).astype(np.float64)
    ship = a.max(2) > 10
    L = a.mean(2); sat = (a.max(2) - a.min(2)) / np.maximum(a.max(2), 1)
    fr = ship & (L > 150) & (sat < .18) & (a[..., 2] >= a[..., 0] - 4)
    frost[v] = dict(ship_px=int(ship.sum()), frost_px=int(fr.sum()), share=round(float(fr.sum() / max(ship.sum(), 1)), 4))
res['frost'] = dict(cap=S.FROST_CAP, views=frost, pass_=all(f['share'] <= S.FROST_CAP for f in frost.values()) and any(f['frost_px'] for f in frost.values()))
alb = np.asarray(Image.open(os.path.join(JOB, 'S8_hull_albedo.png')).convert('RGB')).astype(np.float64)
lin = srgb_to_lin(alb); m = lin.max(2) > .003


def hue(c):
    r, g, b = c; mx, mn = max(c), min(c)
    if mx - mn < 1e-9: return 0.0
    if mx == r: h = ((g - b) / (mx - mn)) % 6
    elif mx == g: h = (b - r) / (mx - mn) + 2
    else: h = (r - g) / (mx - mn) + 4
    return round(60 * h, 2)


med = np.median(lin[m], 0); lifted = med * S.LIFT
res['lift'] = dict(lift=S.LIFT, hue_before=hue(med), hue_after=hue(np.minimum(lifted, 1)), median_albedo_lin=[round(float(x), 5) for x in med])
bp = os.path.join(PV, 'paint_battle.png')
if os.path.exists(bp):
    a = np.asarray(Image.open(bp).convert('RGB')).astype(np.float64); ship = a.max(2) > 10
    hot = (a[..., 0] > a[..., 2] * 1.6) & (a[..., 0] > 90)       # the ember light, not the iron
    md = np.median(a[ship & ~hot], 0)
    lo, hi = S.CONCEPT['iron']
    res['median'] = dict(battle_median_srgb=[int(x) for x in md], iron_band=[lo, hi],
                         inside_band=bool(all(l - 6 <= x <= h + 6 for x, l, h in zip(md, lo, hi))), ember_share=round(float(hot[ship].mean()), 4))
json.dump(res, open(OUT, 'w'), indent=1, default=lambda o: bool(o) if isinstance(o, np.bool_) else float(o))
print(json.dumps(res, indent=1, default=lambda o: bool(o) if isinstance(o, np.bool_) else float(o)))
