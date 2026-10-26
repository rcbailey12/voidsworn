# A4 cuts: take out the AI parts that get rebuilt by hand (blob sweep defaults: guns, towers, masts, tanks, engine crowns, thin sticks)
# before the hull is refined and dressed. Works on the raw arrays (Blender working frame: x bow, y port, z up). No Blender needed.
#   box cut:     every triangle whose centre lies in the box goes (set the box floor a hair below the deck the part grew from, so the
#                hole's rim sits on the deck and the cover block closes it flush)
#   finger scan: thin protrusions past a level along a direction (up, down, aft, fore, port, stbd), the spires.py test turned to face
#                that way (height several times the width)
#   islands:     loose pieces smaller than a share of the hull's area (AI debris floating beside the hull)
# Each cut reports the rim of the hole it leaves (lo and hi corner of the boundary vertices), for kit.cover().
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', 'a2detail'),):
    if p not in sys.path: sys.path.insert(0, p)
import hullio, spires

DIRS = {'up': lambda p: p, 'down': lambda p: np.stack([p[:, 0], -p[:, 1], -p[:, 2]], 1), 'aft': lambda p: np.stack([p[:, 2], p[:, 1], -p[:, 0]], 1),
        'fore': lambda p: np.stack([-p[:, 2], p[:, 1], p[:, 0]], 1), 'port': lambda p: np.stack([p[:, 0], -p[:, 2], p[:, 1]], 1),
        'stbd': lambda p: np.stack([p[:, 0], p[:, 2], -p[:, 1]], 1)}


def _rim(p, idx, w, cut_mask):
    keep = ~cut_mask
    if not cut_mask.any(): return None
    kv = np.zeros(w.max() + 1, bool); kv[w[idx[keep]].ravel()] = True
    vs = idx[cut_mask].ravel(); rim = vs[kv[w[vs]]]
    pts = p[rim] if len(rim) else p[vs]
    return pts.min(0).tolist(), pts.max(0).tolist(), int(len(rim))


def islands(p, idx, w, min_share):
    """mask of triangles in connected pieces whose area is below min_share of the total"""
    W = w.max() + 1; parent = np.arange(W)
    def find(a):
        r = a
        while parent[r] != r: r = parent[r]
        while parent[a] != r: parent[a], a = r, parent[a]
        return r
    for a, b, c in w[idx]:
        ra, rb, rc = find(a), find(b), find(c)
        if rb != ra: parent[rb] = ra
        rc = find(c)
        if rc != ra: parent[rc] = ra
    roots = np.array([find(x) for x in w[idx[:, 0]]])
    P = p[idx]; ar = np.linalg.norm(np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]), axis=1) / 2
    u, inv = np.unique(roots, return_inverse=True); tot = np.bincount(inv, ar)
    return tot[inv] < min_share * ar.sum()


def needle_r(nd, x):
    """the needle cut's radius at x: a number, or a list of (x, r) points interpolated"""
    r = nd['r']
    if isinstance(r, (int, float)): return np.full(len(x), float(r))
    xs, rs = zip(*r); return np.interp(x, xs, rs)


def in_needle(nd, v, e=0.):
    """is point v (x, y, z) inside the needle cut's kept spindle (grown by e)?"""
    y0, z0 = nd.get('axis', (0, 0)); x0, x1 = nd.get('x', (-9, 9))
    if not (x0 - e < v[0] < x1 + e): return False
    return np.hypot(v[1] - y0, (v[2] - z0) * nd.get('zs', 1.0)) < needle_r(nd, np.array([v[0]]))[0] + e


def apply(p, idx, cuts, keep_islands=False, island_share=.002):
    """cuts: list of dict(name, box=(x0, x1, y0, y1, z0, z1)) or dict(name, dir='up', level=z, max_w=.03, min_ratio=2, box=(...) optional,
    mirror=True also cuts the box mirrored across y). Returns (idx_kept, rims {name: (lo, hi, nrim)}, report lines)."""
    w = hullio.weld_ids(p); cen = p[idx].mean(1); cut_all = np.zeros(len(idx), bool); rims = {}; rep = []
    for c in cuts:
        m = np.zeros(len(idx), bool)
        boxes = []
        if 'box' in c and 'dir' not in c:
            boxes = [c['box']]
            if c.get('mirror'): x0, x1, y0, y1, z0, z1 = c['box']; boxes.append((x0, x1, -y1, -y0, z0, z1))
            for k, (x0, x1, y0, y1, z0, z1) in enumerate(boxes):
                mk = (cen[:, 0] > x0) & (cen[:, 0] < x1) & (cen[:, 1] > y0) & (cen[:, 1] < y1) & (cen[:, 2] > z0) & (cen[:, 2] < z1) & ~cut_all
                nm = c['name'] + ('m' if k else '')
                if mk.any(): rims[nm] = _rim(p, idx, w, mk)
                m |= mk
                rep.append(f'cut {nm}: {int(mk.sum())} triangles')
        elif 'needle' in c:  # Ithar: keep only the spindle (centres within r of the axis line y=y0, z=z0 over x0..x1); the AI sails go
            nd = c['needle']; y0, z0 = nd.get('axis', (0, 0)); x0, x1 = nd.get('x', (-9, 9)); rr = needle_r(nd, cen[:, 0])
            d = np.hypot(cen[:, 1] - y0, (cen[:, 2] - z0) * nd.get('zs', 1.0))
            m = (d > rr) & (cen[:, 0] > x0) & (cen[:, 0] < x1) & ~cut_all
            if 'outside_x' in nd: m |= ((cen[:, 0] < x0) | (cen[:, 0] > x1)) & ~cut_all  # everything past the spindle's ends too
            if m.any(): rims[c['name']] = _rim(p, idx, w, m)
            rep.append(f'cut {c["name"]} (outside the needle): {int(m.sum())} triangles')
        elif 'dir' in c:
            q = DIRS[c['dir']](p); sel_box = c.get('box')
            fs = spires.find_fingers(q, idx, c['level'], None, min_ratio=c.get('min_ratio', 2.0), min_h=c.get('min_h', .010), max_w=c.get('max_w', .03))
            for f in fs:
                t = f['tris']
                if sel_box is not None:
                    x0, x1, y0, y1, z0, z1 = sel_box; cc = cen[t].mean(0)
                    if not (x0 < cc[0] < x1 and y0 < cc[1] < y1 and z0 < cc[2] < z1): continue
                m[t] = True
            m &= ~cut_all
            if m.any(): rims[c['name']] = _rim(p, idx, w, m)
            rep.append(f'cut {c["name"]} (thin, {c["dir"]} past {c["level"]}): {int(m.sum())} triangles in {len(fs)} pieces')
        cut_all |= m
    if not keep_islands:
        isl = islands(p, idx[~cut_all], w, island_share)
        if isl.any():
            ii = np.nonzero(~cut_all)[0][isl]; cut_all[ii] = True; rep.append(f'removed {len(ii)} triangles of loose AI debris')
    return idx[~cut_all], rims, rep
