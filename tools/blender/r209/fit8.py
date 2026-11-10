# Issue 209 round 8, step 1: fit the bow third's hull sections to the concept outline at the concept camera (Board brief, Nov 10:
# "the bow SHAPE, by a different method than round 7's detail pass"). Round 7 added detail to the bow and its outline got worse; this
# fits the shape itself.
# How: Ab7 is built once (armA7.build_geometry, the real build). Every object is tagged by what it follows:
#   regen   rebuilt each try from the numbers: the core hull loft (A5.HK with the bow knots swapped in), the hood and the deck lip
#   guns    the twin bow guns: moved with the guns' own offset (dx, dz)
#   cas     the casemates: moved sideways with the slab side's half-width change at their station
#   fin     the ventral fins and pods: moved up or down with the belly at x 0.35
#   rack    the forward drum rack on the hood: moved with the hood top
#   drop    small bow fittings and the bow plates (thin, laid on the hull): left out of the fast proxy (the full build has them)
#   static  everything else (aft of the bow, unchanged)
# The score is outline_thirds.py's, with the thirds labelled once from Ab7: the bow third overlap, the whole ship, and the bow's
# inner edges within 6 px (flat-shaded model edges to the concept's luminance edges). Coordinate descent over grouped numbers,
# each held to a range that keeps the design (flat deck, sharp deck edge, slab side, flat belly: no raked stem, no keel).
# The proxy is only a guide: every result is rebuilt in full (sil_dump.py build armA8) and scored by outline_thirds.py.
# usage: python3.11 fit8.py OUT_DIR [evals]      (bpy 4.5 module; writes OUT_DIR/fit8.json and the best numbers)
import os, sys, json, time, math, re
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import numpy as np
import bpy
from PIL import Image
from scipy import ndimage
import armA7 as A7
import armA5 as A5
import silhouette4 as S4
import outline_thirds as OT

REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
CONCEPT = os.path.join(REPO, 'docs/ship_pipeline/concepts/C15s_23.webp')
CAM = os.path.join(REPO, 'docs/shots/ship_pipeline/route209/round4/concept_camera.json')
BOW0 = [list(k) for k in A7.BOW]; HOOD0 = dict(A7.HOOD)
KI = {k: i + 1 for i, k in enumerate(A5.KEYS)}

# The bow is described by smooth curves, not knot by knot (a free knot fit made the deck dip and the side waist in), and the knots
# are then sampled from the curves. name -> (start, step, lo, hi). x runs to the bow; the section numbers are armA5's.
#   deck   zt: level at zt_mid aft of x_fall, then falls to zt_nose at the stem along a power curve (p_fall)
#   plan   Ws: full width Ws_mid aft of x_round, then a superellipse (exponent e_plan) to Ws_tip at the stem x_nose: a rounded D
#   slab   the slab side runs from just under the deck edge down to zs2 (mid to nose, linear)
#   tuck   Wt = ft * Ws at zt2; belly corner Wb = fb * Wt at zb (mid and nose values, linear along the rounding)
SPEC = dict(
    zt_mid=(-.006, .003, -.030, .015), zt_nose=(-.040, .004, -.100, .000), x_fall=(.380, .010, .300, .460), p_fall=(1.6, .25, 0.6, 3.5),
    Ws_mid=(.123, .003, .100, .135), x_round=(.390, .010, .320, .450), e_plan=(2.0, .25, 1.4, 4.0), Ws_tip=(.040, .006, .015, .080),
    x_nose=(.497, .004, .485, .510),
    zs2_mid=(-.108, .004, -.125, -.102), zs2_nose=(-.096, .004, -.125, -.060),
    ft_mid=(.69, .03, .45, .95), ft_nose=(.62, .03, .40, .95), zt2_mid=(-.142, .004, -.165, -.115), zt2_nose=(-.114, .004, -.160, -.085),
    fb_mid=(.47, .04, .45, .80), fb_nose=(.55, .04, .45, .85), zb_mid=(-.180, .004, -.195, -.160), zb_nose=(-.126, .006, -.180, -.110),
    h_face=(0, .006, -.03, .04), h_lip=(0, .006, -.03, .04), h_zface=(0, .004, -.015, .03), h_zlip=(0, .004, -.015, .03),
    h_ztop=(0, .004, -.015, .02), h_wface=(0, .004, -.02, .02), h_wback=(0, .004, -.03, .01),
    g_dx=(0, .006, -.04, .08), g_dz=(0, .004, -.02, .03),
    fin_dx=(0, .006, -.04, .04), fin_dz=(0, .004, -.03, .03),
    cas_dx=(0, .004, -.03, .03), cas_dz=(0, .003, -.02, .02),
)
# try 2 (round 8): the base can be the fitted build itself (R209_FITBASE=armA8), with its plates and fittings kept in the proxy, and
# the descent limited to some numbers (R209_FITKEYS=cas_dx,cas_dz)
BASE = os.environ.get('R209_FITBASE', 'armA7')
KEYS_ONLY = [k for k in os.environ.get('R209_FITKEYS', '').split(',') if k]
# try 2: the concept's near deck edge as a named line (traced by eye, docs/shots/ship_pipeline/route209/round8/concept_bow_trace.json).
# The automatic edge score misses it (the flat shade of deck and side is too close), so the outline fit could drop the deck edge
# well below the concept's while the outline still matched. DECK_W px of penalty per px of mean distance (0 = try 1).
TRACE = json.load(open(os.path.join(REPO, 'docs/shots/ship_pipeline/route209/round8/concept_bow_trace.json')))
DECK_W = float(os.environ.get('R209_DECKW', '0'))


def deck_edge_px(p, cam):
    """mean distance (px at 1024) from the model's near deck edge (the deck lip, y = Ws + 0.003, z = deck) to the traced line"""
    K = bow_from(p); xs = np.linspace(.22, K[-1][0] - .002, 40)
    zt = np.interp(xs, [k[0] for k in K], [k[1] for k in K]); ws = np.interp(xs, [k[0] for k in K], [k[3] for k in K]) + .003
    uv = S4.project(np.stack([xs, ws, zt + .0014], 1), cam); L = np.array(TRACE['deck_edge_port'], float)
    a, b = L[:-1], L[1:]; d = b - a
    t = np.clip(((uv[:, None, :] - a[None]) * d[None]).sum(-1) / (d * d).sum(-1)[None], 0, 1)
    q = a[None] + t[..., None] * d[None]; dist = np.linalg.norm(uv[:, None, :] - q, axis=-1).min(1)
    inside = uv[:, 0] <= L[:, 0].max() + 4
    return float(dist[inside].mean()) if inside.any() else 0.0
XK = (.21, .26, .30, .34, .38, .41, .43, .45, .465, .48, .49, 1.0)    # 1.0 stands for the stem (x_nose)


def bow_from(p):
    """the bow knots (armA5.HK columns) sampled from the curves, from x 0.21 (the bow break line is at 0.178) to the stem"""
    xn = p['x_nose']; out = []
    for x in XK:
        x = xn if x == 1.0 else min(x, xn - .004)
        tf = max(0.0, (x - p['x_fall']) / (xn - p['x_fall'])); zt = p['zt_mid'] + (p['zt_nose'] - p['zt_mid']) * tf ** p['p_fall']
        tr = max(0.0, (x - p['x_round']) / (xn - p['x_round'])); e = p['e_plan']
        Ws = p['Ws_tip'] + (p['Ws_mid'] - p['Ws_tip']) * max(0.0, 1 - min(1.0, tr) ** e) ** (1 / e)
        lin = lambda a, b: p[a] + (p[b] - p[a]) * tr
        zs2 = lin('zs2_mid', 'zs2_nose'); Wt = Ws * lin('ft_mid', 'ft_nose'); zt2 = lin('zt2_mid', 'zt2_nose')
        Wb = Wt * lin('fb_mid', 'fb_nose'); zb = lin('zb_mid', 'zb_nose')
        out.append((round(x, 4), zt, Ws - .003, Ws, zt - .005, zs2, Wt, zt2, Wb, zb))
    return out


def hood_from(p):
    h = dict(HOOD0)
    h['x_face'] = HOOD0['x_face'] + p['h_face']; h['x_lip'] = max(h['x_face'] + .01, HOOD0['x_lip'] + p['h_lip'])
    h['z_face'] = HOOD0['z_face'] + p['h_zface']; h['z_lip'] = (HOOD0['z_lip'][0] + p['h_zlip'], HOOD0['z_lip'][1] + p['h_zlip'])
    h['z_top'] = HOOD0['z_top'] + p['h_ztop']; w0 = HOOD0['w_face'][0] + p['h_wface']; h['w_face'] = (w0, w0 - .006)
    wb = HOOD0['w_back'][0] + p.get('h_wback', 0); h['w_back'] = (wb, wb - .008)
    h['w_lip'] = min(HOOD0['w_lip'], w0 - .008)
    return h


def tris(objs):
    dg = bpy.context.evaluated_depsgraph_get(); out = []
    for o in objs:
        e = o.evaluated_get(dg); me = e.to_mesh(); me.calc_loop_triangles()
        v = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', v); v = v.reshape(-1, 3)
        t = np.empty(len(me.loop_triangles) * 3, np.int32); me.loop_triangles.foreach_get('vertices', t); t = t.reshape(-1, 3)
        M = np.array(o.matrix_world, np.float32); v = v @ M[:3, :3].T + M[:3, 3]
        out.append(v[t]); e.to_mesh_clear()
    return np.concatenate(out, 0) if out else np.zeros((0, 3, 3), np.float32)


def group(o):
    n = o.name
    if n in ('core', 'glacis', 'hoodlip', 'decklip'): return 'regen'
    if n.startswith('bow'): return 'guns'
    if n.startswith('cas'): return 'cas'
    if n.startswith(('vfin', 'vpod')): return 'fin'
    if n.startswith('rackF'): return 'rack'
    if re.match(r'(pl[USTdg][ps]|hslat|hhatch|dhatch|fhatch|grab|dvent|mkID|mkDisc)', n): return 'drop'
    return 'static'


class Proxy:
    def __init__(self):
        __import__(BASE).build_geometry()
        objs = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render and o.get('role') != 'interior']
        G = {}
        for o in objs: G.setdefault(group(o), []).append(o)
        self.T = {g: tris(v) for g, v in G.items() if g not in ('regen',)}
        if BASE != 'armA7': self.T['static'] = np.concatenate([self.T['static'], self.T.pop('drop')], 0)   # its own plates and fittings
        self.cas_side = np.sign(self.T['cas'].mean(1)[:, 1])
        self.cam = json.load(open(CAM))['camera']; self.C = S4.concept_mask(CONCEPT)
        cg = np.asarray(Image.open(CONCEPT).convert('L').resize((S4.N, S4.N), Image.LANCZOS))
        self.CE = OT.edges(cg, self.C); self.dC = ndimage.distance_transform_edt(~self.CE)
        T0 = self.full(dict((k, v[0]) for k, v in SPEC.items()))
        x = T0.mean(1)[:, 0]; lab = np.where(x > 1 / 6, 1, np.where(x < -1 / 6, 3, 2)).astype(np.uint8)
        Lm = OT.painter(T0, self.cam, lab); M = Lm > 0
        idx = ndimage.distance_transform_edt(~M, return_distances=False, return_indices=True); self.L = Lm[idx[0], idx[1]]

    def regen(self, p):
        for o in list(bpy.data.objects):
            if o.name in ('core', 'glacis', 'hoodlip', 'decklip'): bpy.data.objects.remove(o, do_unlink=True)
        A5.HK[:] = [k for k in A5.HK if k[0] < A7.BOW_X0] + bow_from(p)
        A7.HOOD.clear(); A7.HOOD.update(hood_from(p))
        o = A5.hull_obj(A5.loft('core', [A5.section(x) for x in A5.stations()], bevel=.0022), 'core')
        new = A7.hood_objs() + [A7.deck_lip(), o]
        return tris(new)

    def full(self, p):
        R = self.regen(p); T = self.T
        g = T['guns'].copy(); g[..., 0] += p['g_dx']; g[..., 2] += p['g_dz']
        k0 = A5.knot(.35)
        c = T['cas'].copy()
        for xs in (.232, .356):
            m = np.abs(c.mean(1)[:, 0] - xs) < .06
            # sideways shift: the slab side's half-width change at the casemate's station
            d = A5.knot(xs)['Ws'] - self.ws0[xs] if hasattr(self, 'ws0') else 0.0
            c[m, :, 1] += (self.cas_side[m] * d)[:, None]
        c[..., 0] += p.get('cas_dx', 0); c[..., 2] += p.get('cas_dz', 0)
        f = T['fin'].copy(); f[..., 2] += (k0['zb'] - self.zb0) if hasattr(self, 'zb0') else 0.0
        # armA5.P fin_dz deepens the fin (its tip goes down by fin_dz, its root stays on the belly); fin_dx moves it along the ship
        zr, zt_ = f[..., 2].max(), f[..., 2].min(); f[..., 2] -= p.get('fin_dz', 0) * (zr - f[..., 2]) / max(1e-6, zr - zt_)
        f[..., 0] += p.get('fin_dx', 0)
        r = T['rack'].copy(); r[..., 2] += p['h_ztop']
        if not hasattr(self, 'ws0'):
            self.ws0 = {xs: A5.knot(xs)['Ws'] for xs in (.232, .356)}; self.zb0 = k0['zb']
        return np.concatenate([R, g, c, f, r, T['static']], 0).astype(np.float64)

    def score(self, p, edges=True):
        T = self.full(p); M = S4.raster(T, self.cam); C = self.C; L = self.L
        out = {}
        for k, t in enumerate(OT.THIRDS, 1):
            R = L == k; out[t] = 100 * (C & M & R).sum() / max(1, ((C | M) & R).sum())
        out['whole'] = 100 * (C & M).sum() / (C | M).sum()
        out['deck_px'] = deck_edge_px(p, self.cam)
        if edges:
            sh = OT.painter(T, self.cam, OT.shade_values(T, self.cam)); Mp = sh > 0
            ME = OT.edges(sh, Mp & C) & (L == 1); out['edge'] = 100 * float((self.dC[ME] <= 6).mean()) if ME.any() else 0
        return out, T


def objective(s): return s['bow'] + .5 * s['whole'] + .12 * s.get('edge', 0) - DECK_W * s.get('deck_px', 0)


def descend(P, p, evals, log):
    best = P.score(p)[0]; f = objective(best); n = 0
    steps = {k: v[1] for k, v in SPEC.items()}
    for rnd in range(4):
        improved = False
        for k in (KEYS_ONLY or [k for k in SPEC if not k.startswith('cas_')]):
            for sgn in (1, -1):
                q = dict(p); q[k] = min(SPEC[k][3], max(SPEC[k][2], p[k] + sgn * steps[k]))
                if q[k] == p[k]: continue
                s = P.score(q)[0]; n += 1; g = objective(s)
                if g > f + 1e-3:
                    p, f, best = q, g, s; improved = True
                    log.append(dict(n=n, k=k, v=round(q[k], 4), **{a: round(b, 2) for a, b in s.items()}))
                    print('[fit8]', n, k, round(q[k], 4), {a: round(b, 2) for a, b in s.items()}, flush=True)
                    # keep going the same way while it helps
                    while True:
                        r = dict(p); r[k] = min(SPEC[k][3], max(SPEC[k][2], p[k] + sgn * steps[k]))
                        if r[k] == p[k]: break
                        s = P.score(r)[0]; n += 1; g = objective(s)
                        if g > f + 1e-3:
                            p, f, best = r, g, s
                            log.append(dict(n=n, k=k, v=round(r[k], 4), **{a: round(b, 2) for a, b in s.items()}))
                            print('[fit8]', n, k, round(r[k], 4), {a: round(b, 2) for a, b in s.items()}, flush=True)
                        else: break
                    break
            if n >= evals: break
        if n >= evals: break
        if not improved: steps = {k: v / 2 for k, v in steps.items()}
    return p, best


if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; evals = int(a[1]) if len(a) > 1 else 400; os.makedirs(out, exist_ok=True)
    start = json.loads(a[2]) if len(a) > 2 and a[2].startswith('{') else (json.load(open(a[2]))['params'] if len(a) > 2 else {})
    t0 = time.time(); P = Proxy(); p = {k: v[0] for k, v in SPEC.items()}; p.update(start)
    s0 = P.score(p)[0]; print('[fit8] start', {k: round(v, 2) for k, v in s0.items()}, round(time.time() - t0, 1), flush=True)
    log = []; p, s = descend(P, p, evals, log)
    json.dump(dict(start=s0, best=s, params=p, bow=bow_from(p), hood=hood_from(p), log=log, seconds=round(time.time() - t0, 1)),
              open(os.path.join(out, 'fit8.json'), 'w'), indent=1)
    print('[fit8] best', {k: round(v, 2) for k, v in s.items()}, flush=True)
    np.savez_compressed(os.path.join(out, 'proxy_best.npz'), tris=P.full(p).astype(np.float32))
    OT.run(CONCEPT, CAM, os.path.join(out, 'sil'), ['proxy=' + os.path.join(out, 'proxy_best.npz')])
