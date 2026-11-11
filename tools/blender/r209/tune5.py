# Issue 209 round 5: tune armA5's traced hull on the concept outline, held to B0's proportions.
# The score is the overlap (intersection over union) with the concept's outline at the concept's fitted camera (silhouette4.py, the
# round 4 scorer, unchanged) plus a small prior: the overlap with B0's own outline seen from the side, from above and from ahead
# (orthographic), so the shape the concept camera cannot see stays B0's. Coordinate descent over grouped numbers: per region (aft
# hull, midship, bow) a deck lift, a belly drop and a width change of the traced knots, the bow's rake and the superstructure, side
# block, tower, mast and pylon numbers, each held to a range that keeps the design. Writes tune5_P.json (read by armA5 on import).
# Runs in the cloud sandbox with the bpy module (no GPU), about 5 s per try.
# usage: python3.11 tune5.py -- CONCEPT.png CAM.json B0.npz OUT.json [ROUNDS] [RES] [PRIOR] [INIT.json]   (INIT: carry on from a run)
import os, sys, json, time, copy
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
os.environ['R209_NO_TUNED'] = '1'
import numpy as np
import bpy
from PIL import Image, ImageDraw
import armA5 as A5
import silhouette4 as S

a = sys.argv[sys.argv.index('--') + 1:]
CONCEPT, CAM, B0, OUT = a[:4]; ROUNDS = int(a[4]) if len(a) > 4 else 2; RES = int(a[5]) if len(a) > 5 else 512
PRIOR = float(a[6]) if len(a) > 6 else .25
INIT = a[7] if len(a) > 7 else None
cam = json.load(open(CAM))['camera']; CM = S.concept_mask(CONCEPT, RES)
BASE_HK = [list(k) for k in A5.HK]; BASE_P = copy.deepcopy(A5.P)

N2 = 256
def ortho(T, view):
    u, v = {'side': (0, 2), 'top': (0, 1), 'front': (1, 2)}[view]; s = N2 / 1.1
    im = Image.new('L', (N2, N2), 0); d = ImageDraw.Draw(im)
    U = N2 / 2 + T[:, :, u] * s; V = N2 / 2 - T[:, :, v] * s
    for t in np.stack([U, V], -1).reshape(-1, 6).tolist(): d.polygon(t, fill=255)
    return np.asarray(im) > 0
TB0 = np.load(B0)['tris'].astype(np.float64)
B0M = {v: ortho(TB0, v) for v in ('side', 'top', 'front')}

# grouped numbers: name -> (step, lo, hi); value 0 (or 1 for scales) is the traced shape
REG = dict(aft=lambda x: x < -.12, mid=lambda x: -.12 <= x < .20, bow=lambda x: x >= .20)
G = dict(aft_dz=(.006, -.03, .02), aft_db=(.008, -.06, .02), aft_dw=(.006, -.025, .02), stern_x=(.006, -.02, .03),
         mid_dz=(.006, -.02, .03), mid_db=(.008, -.03, .02), mid_dw=(.006, -.025, .02),
         bow_dz=(.006, -.045, .02), bow_db=(.008, -.04, .03), bow_dw=(.006, -.035, .02),
         rake=(.012, 0.0, .07), nose_x=(.006, -.025, .012), shoulder=(.006, -.015, .02))
PK = dict(gl_top=(.006, -.03, .015), gl_wt=(.006, -.016, .016), t1_z=(.006, .046, .090), t2_z=(.006, .056, .105), hump_z=(.006, .040, .090),
          ab_z=(.006, .026, .070), bg_dz=(.006, -.03, .01), bg_x=(.010, -.04, .03), fd_r=(.002, .010, .022), ab_w=(.006, .050, .080), ab_end=(.010, -.470, -.400), st_z=(.008, .040, .075), st_w=(.006, .050, .080),
          sp_out=(.006, .165, .200), sp_lo=(.008, -.120, -.070), md_out=(.006, .160, .195), cg_out=(.006, .150, .195), cg_lo=(.008, -.120, -.070),
          fin_dx=(.012, -.09, .07), fin_dz=(.010, -.02, .06), fin_fwd=(.012, -.02, .08))   # tower and mast: fixed to the concept (armA5.TOWER, MAST), not tuned
V = {k: 0.0 for k in G}; V.update({k: None for k in PK})
SPACE_KEYS = set(G) | set(PK)
if INIT:
    for k, v in json.load(open(INIT))['V'].items():
        if k in V and k in SPACE_KEYS: V[k] = v

def getp(k):
    p = A5.P
    if k == 'gl_top': return V['gl_top'] if V['gl_top'] is not None else 0.0
    if k == 'gl_wt': return V['gl_wt'] if V['gl_wt'] is not None else 0.0
    if k == 'ab_end': return p['ab_x'][1]
    if k == 'sp_lo': return p['sp_z'][0]
    if k == 'cg_lo': return p['cg_z'][0]
    return p[k]

def apply():
    """V -> A5.HK and A5.P"""
    hk = []
    n = len(BASE_HK)
    for i, k in enumerate(BASE_HK):
        x, zt, Wd, Ws, zs1, zs2, Wt, zt2, Wb, zb = k
        r = 'aft' if REG['aft'](x) else ('mid' if REG['mid'](x) else 'bow')
        dz, db, dw = V[f'{r}_dz'], V[f'{r}_db'], V[f'{r}_dw']
        zt += dz; zs1 += dz; zs2 += db * .5; zt2 += db; zb += db
        Wd, Ws, Wt, Wb = Wd + dw, Ws + dw, Wt + dw, Wb + dw * .6
        if r == 'bow':
            zs1 += V['shoulder']
            j = n - 1 - i                      # 0 at the nose knot
            if j < 4:
                f = (1.0, .6, .3, .1)[j]; zb += V['rake'] * f; zt2 += V['rake'] * f * .8; zs2 += V['rake'] * f * .4
                if j < 3: x += V['nose_x'] * (1.0, .7, .4)[j]
        if r == 'aft' and i < 2: x -= V['stern_x'] * (1.0, .5)[i]
        hk.append((x, zt, Wd, Ws, zs1, zs2, Wt, zt2, Wb, zb))
    A5.HK[:] = hk
    A5.P['st_x'] = (BASE_P['st_x'][0] - V['stern_x'] * .5, BASE_P['st_x'][1] - V['stern_x'])
    p = A5.P; b = BASE_P
    for k in PK:
        v = V[k]
        if v is None: continue
        if k == 'gl_top': p['gl_z'] = tuple(z + v for z in b['gl_z'])
        elif k == 'gl_wt': p['gl_wt'] = b['gl_wt'] + v; p['gl_wb'] = b['gl_wb'] + v
        elif k == 'ab_end': p['ab_x'] = (b['ab_x'][0], v)
        elif k == 'sp_lo': p['sp_z'] = (v, b['sp_z'][1])
        elif k == 'cg_lo': p['cg_z'] = (v, b['cg_z'][1])
        else: p[k] = v

def tris():
    out = []
    for o in bpy.context.scene.objects:
        if o.type != 'MESH' or o.hide_render or o.get('role') == 'interior': continue
        me = o.data; me.calc_loop_triangles()
        v = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', v); v = v.reshape(-1, 3)
        t = np.empty(len(me.loop_triangles) * 3, np.int32); me.loop_triangles.foreach_get('vertices', t); t = t.reshape(-1, 3)
        M = np.array(o.matrix_world, np.float32); v = v @ M[:3, :3].T + M[:3, 3]; out.append(v[t])
    return np.concatenate(out, 0).astype(np.float64)

def score(detail=False):
    apply(); A5.build_geometry(); T = tris()
    c = S.iou(S.raster(T, cam, RES), CM); pr = {k: S.iou(ortho(T, k), B0M[k]) for k in B0M}
    s = c + PRIOR * float(np.mean(list(pr.values())))
    return (s, c, pr) if detail else s

def get(k): return V[k] if k in G else (getp(k) if V[k] is None else V[k])
def put(k, v): V[k] = v

log = []; t0 = time.time(); best, c0, pr0 = score(True); log.append(dict(start=round(best, 4), concept=round(c0, 4), prior={k: round(v, 4) for k, v in pr0.items()}))
print('[tune5] start', round(best, 4), 'concept', round(c0, 4), {k: round(v, 3) for k, v in pr0.items()}, flush=True)
SPACE = dict(G); SPACE.update(PK); steps = {k: v[0] for k, v in SPACE.items()}
for rnd in range(ROUNDS):
    for k, (st, lo, hi) in SPACE.items():
        v0 = get(k); improved = False
        for d in (+1, -1):
            v = min(hi, max(lo, v0 + d * steps[k]))
            if abs(v - v0) < 1e-9: continue
            put(k, v); s = score()
            if s > best + 2e-4:
                best = s; improved = True; v0 = v
                while True:      # keep stepping the same way while it helps
                    v2 = min(hi, max(lo, v0 + d * steps[k]))
                    if abs(v2 - v0) < 1e-9: break
                    put(k, v2); s2 = score()
                    if s2 > best + 2e-4: best = s2; v0 = v2
                    else: break
                put(k, v0); break
            put(k, v0)
        log.append(dict(round=rnd, key=k, value=round(get(k), 4), score=round(best, 4), improved=improved))
        print('[tune5]', rnd, k, round(get(k), 4), round(best, 4), 'better' if improved else '', round(time.time() - t0), flush=True)
    steps = {k: v / 2 for k, v in steps.items()}
s, c, pr = score(True)
res = dict(score=round(s, 4), concept=round(c, 4), prior={k: round(v, 4) for k, v in pr.items()}, res=RES, prior_weight=PRIOR,
           seconds=round(time.time() - t0), V={k: (None if v is None else round(v, 5)) for k, v in V.items()},
           HK=[[round(q, 5) for q in k] for k in A5.HK], P={k: (list(v) if isinstance(v, tuple) else v) for k, v in A5.P.items()}, log=log)
json.dump(res, open(OUT, 'w'), indent=1); print('[tune5] done', round(s, 4), 'concept', round(c, 4), flush=True)
