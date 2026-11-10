# Issue 209 round 4: tune armA4's shape numbers on the silhouette score (overlap with the concept's outline at the concept's fitted
# camera). Coordinate descent over a short list of design numbers, each held to a range that keeps the design (flat deck, sharp
# edge, slab sides, belly tuck, stepped superstructure); every other number stays as armA4 sets it. Runs in the cloud sandbox with
# the bpy module (no GPU), about 6 s per try.
# usage: python3.11 tune4.py -- CONCEPT.png CAM.json OUT.json [ROUNDS] [RES]
import os, sys, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import numpy as np
import bpy
import armA4 as A4
import silhouette4 as S

a = sys.argv[sys.argv.index('--') + 1:]
CONCEPT, CAM, OUT = a[0], a[1], a[2]; ROUNDS = int(a[3]) if len(a) > 3 else 2; RES = int(a[4]) if len(a) > 4 else 512
cam = json.load(open(CAM))['camera']; CM = S.concept_mask(CONCEPT, RES)

# name: (step, lo, hi). gl_top, t1_z, ... move a block's top; W etc. are the hull's plan and section.
SPACE = dict(W=(.008, .100, .145), xn=(.008, .480, .530), nose_w=(.010, .015, .070), pw=(.4, 1.6, 4.0), zd=(.008, -.010, .045),
             zd_nose=(.010, -.040, .045), zc=(.010, -.130, -.080), zb=(.010, -.195, -.140), zb_nose=(.012, -.170, -.100),
             over_c=(.008, .0, .040), over_b=(.015, .020, .100), wb=(.008, .070, .110), gl_top=(.008, .050, .085), gl_w=(.008, .070, .110),
             t1_z=(.008, .060, .095), t2_z=(.008, .075, .110), hump_z=(.010, .070, .110), ab_z=(.008, .050, .090), ab_w=(.008, .070, .100),
             st_z=(.010, .060, .100), st_w=(.008, .080, .110), aft_zb=(.010, -.100, -.060), rail_zb=(.010, -.120, -.080),
             cargo_lo=(.010, -.110, -.060))

def get(k):
    if k == 'gl_top': return A4.P['gl_z'][2]
    if k == 'cargo_lo': return A4.P['cargo_z'][0]
    return A4.P[k]

def put(k, v):
    if k == 'gl_top': z = A4.P['gl_z']; A4.P['gl_z'] = (z[0], v - .004, v)
    elif k == 'cargo_lo': A4.P['cargo_z'] = (v, A4.P['cargo_z'][1])
    else: A4.P[k] = v

def tris():
    dg = bpy.context.evaluated_depsgraph_get(); out = []
    for o in bpy.context.scene.objects:
        if o.type != 'MESH' or o.hide_render or o.get('role') == 'interior': continue
        me = o.data; me.calc_loop_triangles()
        v = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', v); v = v.reshape(-1, 3)
        t = np.empty(len(me.loop_triangles) * 3, np.int32); me.loop_triangles.foreach_get('vertices', t); t = t.reshape(-1, 3)
        M = np.array(o.matrix_world, np.float32); v = v @ M[:3, :3].T + M[:3, 3]; out.append(v[t])
    return np.concatenate(out, 0).astype(np.float64)

def score():
    A4.build_geometry(); return S.iou(S.raster(tris(), cam, RES), CM)

log = []; t0 = time.time(); best = score(); log.append(dict(start=best)); print('[tune] start', round(best, 4), flush=True)
steps = {k: v[0] for k, v in SPACE.items()}
for rnd in range(ROUNDS):
    for k, (st, lo, hi) in SPACE.items():
        v0 = get(k); improved = False
        for d in (+1, -1):
            v = min(hi, max(lo, v0 + d * steps[k]))
            if abs(v - v0) < 1e-9: continue
            put(k, v); s = score()
            if s > best + 2e-4:
                best = s; improved = True; v0 = v
                put(k, v); v2 = min(hi, max(lo, v + d * steps[k])); put(k, v2); s2 = score()   # one more step the same way
                if s2 > best + 2e-4: best = s2; v0 = v2
                put(k, v0); break
            put(k, v0)
        log.append(dict(round=rnd, key=k, value=round(get(k), 4), score=round(best, 4), improved=improved))
        print('[tune]', rnd, k, round(get(k), 4), round(best, 4), 'better' if improved else '', flush=True)
    steps = {k: v / 2 for k, v in steps.items()}
res = dict(score=round(best, 4), res=RES, seconds=round(time.time() - t0), P={k: (list(v) if isinstance(v, tuple) else v) for k, v in A4.P.items()}, log=log)
json.dump(res, open(OUT, 'w'), indent=1); print('[tune] done', round(best, 4), flush=True)
