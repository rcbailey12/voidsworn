# A2 max-detail ships: the blob-sweep rebuild of thin AI sticks (antenna fingers, pinnacles). The AI melts thin spikes into soft wavy
# fingers; CLAUDE.md says those get rebuilt by hand. Here: find thin upright fingers in the hull mesh (connected pieces above a level whose
# height is several times their width), cut them off above the level where they leave the body, and hand back what to build in their
# place: a mount plate over the cut and a crisp spire (antenna mast or gothic pinnacle) at the same spot and height.
import numpy as np
import hullio


def _components(p, idx, w, sel_tri):
    t = idx[sel_tri]
    if not len(t): return []
    W = w.max() + 1; parent = np.arange(W)
    def find(a):
        while parent[a] != a: parent[a] = parent[parent[a]]; a = parent[a]
        return a
    for a, b, c in w[t]:
        ra, rb, rc = find(a), find(b), find(c); parent[rb] = ra; parent[find(rc)] = ra
    roots = np.array([find(x) for x in w[t[:, 0]]]); out = []
    for r in np.unique(roots): out.append(np.nonzero(sel_tri)[0][roots == r])
    return out


def find_fingers(p, idx, zcut, box=None, min_ratio=2.0, min_h=.012, max_w=.03):
    """fingers above zcut (Blender frame, z up): returns list of dict(tris, c (x, y), r, z0, z1). box = (x0, x1, y0, y1) limits the search."""
    w = hullio.weld_ids(p); P = p[idx]; cen = P.mean(1)
    sel = np.all(P[:, :, 2] > zcut, 1)
    if box is not None: sel &= (cen[:, 0] > box[0]) & (cen[:, 0] < box[1]) & (cen[:, 1] > box[2]) & (cen[:, 1] < box[3])
    out = []
    for tris in _components(p, idx, w, sel):
        q = P[tris].reshape(-1, 3); z1 = q[:, 2].max(); h = z1 - zcut
        low = q[q[:, 2] < zcut + max(h * .25, .004)]
        if not len(low): continue
        c = low[:, :2].mean(0); r = np.percentile(np.linalg.norm(low[:, :2] - c, axis=1), 80)
        wid = max(np.ptp(q[:, 0]), np.ptp(q[:, 1]))
        if h >= min_h and h / max(wid, 1e-6) >= min_ratio and wid <= max_w:
            out.append(dict(tris=tris, c=c, r=float(np.clip(r, .0025, .012)), z0=float(zcut), z1=float(z1)))
    return out


def symmetrize(fingers, tol=.005):
    """matched pairs: twins across y = 0 get the same size and mirrored position (twins first, so a close pair is not merged); unpaired
    fingers near the centreline sit exactly on it"""
    paired = set()
    for i, f in enumerate(fingers):
        if i in paired or abs(f['c'][1]) < .0015: continue
        for j, g in enumerate(fingers):
            if j == i or j in paired: continue
            if abs(g['c'][0] - f['c'][0]) < .005 and abs(g['c'][1] + f['c'][1]) < .005 and g['c'][1] * f['c'][1] < 0:
                x = (f['c'][0] + g['c'][0]) / 2; y = (abs(f['c'][1]) + abs(g['c'][1])) / 2; r = (f['r'] + g['r']) / 2; z1 = (f['z1'] + g['z1']) / 2
                for k in (f, g): k['c'] = np.array([x, np.sign(k['c'][1]) * y]); k['r'] = r; k['z1'] = z1
                paired |= {i, j}; break
    for i, f in enumerate(fingers):
        if i not in paired and abs(f['c'][1]) < max(tol, f['r'] * 1.2, .008): f['c'] = np.array([f['c'][0], 0.0])  # a lone finger near the middle goes on it
    return fingers


def cut(p, idx, fingers):
    """remove the finger triangles; returns the new index array"""
    if not fingers: return idx
    dead = np.concatenate([f['tris'] for f in fingers]).astype(np.int64); keep = np.ones(len(idx), bool); keep[dead] = False; return idx[keep]


def scan(p, idx, zmin, box=None, exclude_x=None, levels=40):
    """fingers found from the top down (so a cluster gives each of its fingers), then each cluster is cut at the lowest level where it is
    still thin, and its fingers all rise from that cut, on one shared mount plate. exclude_x: |x| beyond which the hull's own bow and stern
    structures are left alone. Returns the fingers (with 'group' ids, group cut height z0 and the group's plate size)."""
    zs = np.linspace(zmin, p[:, 2].max(), levels); leaves = []; claimed = np.zeros(len(idx), bool)
    for z in zs[::-1]:
        for f in find_fingers(p, idx, z, box):
            if exclude_x is not None and abs(f['c'][0]) > exclude_x: continue
            if claimed[f['tris']].mean() > .3: continue
            claimed[f['tris']] = True
            if any(np.linalg.norm(f['c'] - g['c']) < max(.0045, (f['r'] + g['r']) * .8) for g in leaves): continue  # the same finger, seen lower down
            leaves.append(f)
    groups = []  # (tris set as bool mask, z0)
    for f in leaves:
        best = None
        for z in zs:
            if z >= f['z0']: break
            for g in find_fingers(p, idx, z, box, min_ratio=1.2, max_w=.045):
                m = np.zeros(len(idx), bool); m[g['tris']] = True
                if m[f['tris']].mean() > .5: best = (m, z); break
            if best: break
        mask, z0 = best if best else (np.isin(np.arange(len(idx)), f['tris']), f['z0'])
        for G in groups:
            if (G['mask'] & mask).any(): G['mask'] |= mask; G['z0'] = min(G['z0'], z0); G['leaves'].append(f); break
        else: groups.append(dict(mask=mask, z0=z0, leaves=[f]))
    out = []
    for k, G in enumerate(groups):
        tris = np.nonzero(G['mask'])[0]; P = p[idx[tris]].reshape(-1, 3); low = P[P[:, 2] < G['z0'] + .006]
        lo = low[:, :2].min(0) if len(low) else P[:, :2].min(0); hi = low[:, :2].max(0) if len(low) else P[:, :2].max(0)
        for j, f in enumerate(G['leaves']):
            f.update(group=k, z0=float(G['z0']), plate_lo=lo - .002, plate_hi=hi + .002, tris=tris if j == 0 else np.zeros(0, np.int64)); out.append(f)
    return symmetrize(out, .0045)
