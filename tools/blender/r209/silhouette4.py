# Issue 209 round 4: the concept's outline against each cell's, at the concept's own camera (plain Python: numpy, scipy, PIL).
# Step 1, `fit`: the concept camera. B0 (the whole-hull generation made from the concept image, yaw fixed into the ship frame) is
#   projected through a pinhole camera (azimuth, elevation, roll, distance, focal length, image centre) and the camera is fitted so
#   B0's outline matches the concept's alpha outline best. Round 3's hero camera (render.py) is the start point. The fitted camera
#   is then fixed: every cell is scored through it with no per-cell fitting (all cells share the ship frame, length 1.0).
# Step 2, `score`: per cell, overlap percent (intersection over union of the two outlines), how much of the concept outline the cell
#   covers, how much of the cell lies outside it, and a red / green overlay (green both, red concept only = missing, yellow cell
#   only = extra). Outlines are filled triangles at the concept's own 1024 px.
# Step 3, `probe`: back-projects concept points (pixel lists in the camera json) onto planes, for the deck plan and cross-section.
# usage: python3 silhouette4.py fit CONCEPT.png B0.npz CAM.json
#        python3 silhouette4.py score CONCEPT.png CAM.json OUT_DIR name=cell.npz[,name=cell.npz...]
import sys, json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage, optimize

N = 1024

def concept_mask(path, n=N):
    a = np.asarray(Image.open(path).convert('RGBA'))[:, :, 3] > 128
    if n != a.shape[0]: a = np.asarray(Image.fromarray(a).resize((n, n), Image.NEAREST))
    return a

def cam_basis(p):
    az, el, roll = math.radians(p['az']), math.radians(p['el']), math.radians(p['roll'])
    d = np.array([math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)])
    pos = np.array(p.get('target', (0, 0, -.01))) + d * p['dist']
    f = -d; r = np.cross(f, (0, 0, 1)); r /= np.linalg.norm(r); u = np.cross(r, f)
    c, s = math.cos(roll), math.sin(roll); r, u = c * r + s * u, -s * r + c * u
    return pos, f, r, u

def project(P, p, n=N):
    """ship-frame points (..., 3) to concept pixels (..., 2) at an n px square image"""
    pos, f, r, u = cam_basis(p); q = P - pos; z = q @ f
    k = p['focal'] * n / N
    return np.stack([p['cx'] * n / N + k * (q @ r) / z, p['cy'] * n / N - k * (q @ u) / z], -1)

def raster(T, p, n=N):
    """filled outline of triangles T (M, 3, 3) at n px"""
    uv = project(T, p, n); im = Image.new('L', (n, n), 0); dr = ImageDraw.Draw(im)
    for t in uv.reshape(-1, 6).tolist(): dr.polygon(t, fill=255)
    return np.asarray(im) > 0

def samples(T, k=400000, seed=1):
    """area-weighted surface points plus every vertex, for the fast splat used while fitting"""
    rng = np.random.default_rng(seed); a = np.linalg.norm(np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]), axis=1)
    i = rng.choice(len(T), k, p=a / a.sum()); w = rng.random((k, 2)); m = w.sum(1) > 1; w[m] = 1 - w[m]
    P = T[i, 0] + w[:, :1] * (T[i, 1] - T[i, 0]) + w[:, 1:] * (T[i, 2] - T[i, 0])
    return np.concatenate([P, T.reshape(-1, 3)[::3]], 0)

def splat(P, p, n):
    uv = project(P, p, n); ij = np.floor(uv).astype(int); ok = (ij[:, 0] >= 0) & (ij[:, 0] < n) & (ij[:, 1] >= 0) & (ij[:, 1] < n)
    m = np.zeros((n, n), bool); m[ij[ok, 1], ij[ok, 0]] = True
    return ndimage.binary_fill_holes(ndimage.binary_closing(m, iterations=2))

def iou(a, b): return float((a & b).sum() / max(1, (a | b).sum()))

KEYS = ('az', 'el', 'roll', 'dist', 'focal', 'cx', 'cy')

def fit(concept, b0, out):
    T = np.load(b0)['tris'].astype(np.float64); P = samples(T)
    # start: round 3's hero camera (render.py: from (1.22, 1.62, 0.80) at (0, 0, -0.01)), framed to the concept by its bounding box
    p0 = dict(az=math.degrees(math.atan2(1.62, 1.22)), el=math.degrees(math.atan2(.81, math.hypot(1.22, 1.62))), roll=0.0,
              dist=math.sqrt(1.22 ** 2 + 1.62 ** 2 + .81 ** 2), focal=1000.0, cx=512.0, cy=512.0)
    C = concept_mask(concept); ys, xs = np.nonzero(C)
    uv = project(P, p0); s = (xs.max() - xs.min()) / (uv[:, 0].max() - uv[:, 0].min()); p0['focal'] *= s
    uv = project(P, p0); p0['cx'] += (xs.min() + xs.max()) / 2 - (uv[:, 0].min() + uv[:, 0].max()) / 2
    p0['cy'] += (ys.min() + ys.max()) / 2 - (uv[:, 1].min() + uv[:, 1].max()) / 2
    hero = dict(p0)
    best = (None, -1)
    for n in (128, 256, 512):
        Cn = concept_mask(concept, n)
        def loss(x):
            p = dict(zip(KEYS, x)); p['dist'] = max(.6, p['dist'])
            return -iou(splat(P, p, n), Cn)
        x0 = np.array([(best[0] or p0)[k] for k in KEYS])
        steps = np.array([6, 4, 3, .4, 60, 20, 20]) * (128 / n)
        sim = np.array([x0] + [x0 + np.eye(7)[i] * steps[i] for i in range(7)])
        r = optimize.minimize(loss, x0, method='Nelder-Mead', options=dict(initial_simplex=sim, maxiter=500, xatol=1e-3, fatol=1e-5))
        best = (dict(zip(KEYS, r.x.tolist())), -r.fun); print('[fit]', n, round(best[1], 4), {k: round(v, 3) for k, v in best[0].items()}, flush=True)
    p = best[0]; full = iou(raster(T, p), C); hero_iou = iou(raster(T, hero), C)
    json.dump(dict(camera=p, b0_iou=round(full, 4), hero_start=hero, b0_iou_at_hero_start=round(hero_iou, 4), image=N), open(out, 'w'), indent=1)
    print('[fit] B0 overlap at the fitted camera', round(full, 4), 'at round 3 hero camera framed', round(hero_iou, 4))

def overlay(C, M, concept_path):
    """green both, red concept only (missing), yellow cell only (extra), over a dim copy of the concept"""
    base = np.asarray(Image.open(concept_path).convert('RGB').resize((N, N))).astype(np.float32) * .25 + 12
    out = base.copy()
    out[C & M] = out[C & M] * .5 + np.array([40, 190, 70]) * .5
    out[C & ~M] = np.array([215, 45, 40]); out[M & ~C] = np.array([235, 200, 40])
    return Image.fromarray(out.clip(0, 255).astype(np.uint8))

def score(concept, camj, outdir, cells):
    import os
    p = json.load(open(camj))['camera']; C = concept_mask(concept); res = {}
    for spec in cells:
        name, path = spec.split('=', 1); T = np.load(path)['tris'].astype(np.float64); M = raster(T, p)
        inter = (C & M).sum()
        res[name] = dict(overlap=round(100 * iou(C, M), 1), concept_covered=round(100 * inter / C.sum(), 1),
                         cell_outside=round(100 * (M & ~C).sum() / max(1, M.sum()), 1), triangles=int(len(T)))
        overlay(C, M, concept).save(os.path.join(outdir, f'sil_{name}.png'))
        Image.fromarray((M * 255).astype(np.uint8)).save(os.path.join(outdir, f'mask_{name}.png'))
        print('[score]', name, res[name], flush=True)
    json.dump(res, open(os.path.join(outdir, 'silhouette_scores.json'), 'w'), indent=1)

def look(concept, camj, cell, out, alpha=.55, ruler=True):
    """the cell flat-shaded at the concept camera (painter's order), blended over the concept, with a ruler along the deck centreline
    (ticks every 0.05 of the ship's length, at z = 0.03) and a vertical ruler at the bow; for reading positions off the concept"""
    p = json.load(open(camj))['camera']; base = Image.open(concept).convert('RGBA'); bg = Image.new('RGBA', base.size, (40, 40, 46, 255))
    bg.alpha_composite(base); base = bg.convert('RGB')
    if cell:
        T = np.load(cell)['tris'].astype(np.float64); pos, f, r, u = cam_basis(p)
        n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
        c = T.mean(1); vd = c - pos; n[(n * vd).sum(1) > 0] *= -1
        L = np.array([.35, .55, .76]); L /= np.linalg.norm(L); sh = np.clip(.25 + .75 * np.abs(n @ L), 0, 1)
        z = (c - pos) @ f; o = np.argsort(-z); uv = project(T, p)
        im = Image.new('RGB', base.size, (40, 40, 46)); m = Image.new('L', base.size, 0); dr = ImageDraw.Draw(im); dm = ImageDraw.Draw(m)
        for i in o:
            g = int(60 + 180 * sh[i]); t = uv[i].ravel().tolist(); dr.polygon(t, fill=(g, g, int(g * 1.05))); dm.polygon(t, fill=255)
        base = Image.composite(Image.blend(base, im, alpha), base, m)
    if ruler:
        d = ImageDraw.Draw(base)
        for x in np.arange(-.5, .5001, .05):
            a, b = project(np.array([[x, -.03, .03], [x, .03, .03]]), p)
            d.line([tuple(a), tuple(b)], fill=(0, 255, 255), width=2); d.text((b[0] + 3, b[1] + 3), f'{x:+.2f}', fill=(0, 255, 255))
        P = project(np.array([[x, 0, .03] for x in (-.5, .5)]), p); d.line([tuple(P[0]), tuple(P[1])], fill=(0, 200, 200), width=1)
        for zz in np.arange(-.20, .2001, .05):
            a = project(np.array([[.5, .14, zz]]), p)[0]; d.line([(a[0] - 6, a[1]), (a[0], a[1])], fill=(255, 0, 255), width=2)
            d.text((a[0] - 44, a[1] - 6), f'{zz:+.2f}', fill=(255, 0, 255))
    base.save(out)

if __name__ == '__main__':
    if sys.argv[1] == 'look': look(sys.argv[2], sys.argv[3], sys.argv[4] if sys.argv[4] != '-' else None, sys.argv[5])
    if sys.argv[1] == 'fit': fit(*sys.argv[2:5])
    elif sys.argv[1] == 'score': score(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5].split(','))
