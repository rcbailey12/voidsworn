# A4 hand-faired hulls (feel pass, Nov 1 2026; Ryan approved the hand-faired rebuild of the Hegemony super-dreadnought, H4_11, R64).
# The AI hull stays lumpy however much it is smoothed (Oct 31 waviness fix: the wobble is in the shape itself), so the hull body is
# rebuilt by hand from numbers taken off the AI hull and the concept: a hard-chine loft (flat armoured deck, slab upper side, an armour
# belt, lower side sloping into a flat belly with chines), a plan view that runs parallel and then tapers to a square-cut armoured prow,
# a deck that chamfers down only near the bow (no sheer, no raked stem: space ship, not naval), a flat stern face for the engines, and
# raised superstructure tiers as their own lofts standing on the deck. Every flat face is a strip with its own vertices, so the chines
# stay crisp while each strip shades smoothly along the ship.
# Returns the dict frame.load gives (pos, nor, idx, uv, uv2, tex, flipped) so the rest of the A4 chain (kit, dress, bake, export) runs
# unchanged. Blender working frame: x bow, y port, z up, ship length 1 along x. No Blender needed (numpy only) except for the neutral maps.
import numpy as np
import ithar


def _smooth(a, k):
    if k < 2: return a
    w = np.exp(-np.linspace(-2.5, 2.5, k) ** 2); w /= w.sum()
    return np.convolve(np.pad(a, k // 2, mode='edge'), w, mode='valid')[:len(a)]


def _curve(xs, pts, smooth=0):
    """piecewise-linear through (x, v) control points, then a light Gaussian smooth (in samples)"""
    px, pv = zip(*pts); return _smooth(np.interp(xs, px, pv), smooth)


def _ring_hull(W, zb, D, s):
    """the hull section (y, z) points, closed, starting at the starboard deck edge and running over the deck to port first"""
    zd = zb + D; dk, bw = s.get('deck', .80), s.get('belly', .50)
    half = [(dk * W, zd), (.965 * W, zd - .07 * D), (W, zd - .36 * D), (.95 * W, zd - .42 * D), (.92 * W, zd - .58 * D), (bw * W, zb)]
    stb = [(-y, z) for y, z in reversed(half)]
    return [(-dk * W, zd)] + half + stb[:-1]


def _ring_tier(w, zb, h):
    """a superstructure tier: slab sides with a chamfered top edge, standing on z = zb"""
    t = zb + h
    return [(-w, zb), (w, zb), (w, t - .32 * h), (.84 * w, t), (-.84 * w, t), (-w, t - .32 * h)]


class Mesh:
    def __init__(self, step=.006): self.pos, self.nor, self.uv, self.idx = [], [], [], []; self.vrow = 0.0; self.step = step

    def add_loft(self, xs, rings):
        """rings: (N, M, 2) section points per x; strips between consecutive ring points, each with its own vertices; end caps"""
        R = np.asarray(rings, np.float64); N, M, _ = R.shape
        X = np.repeat(xs[:, None], M, 1); P = np.stack([X, R[..., 0], R[..., 1]], -1)            # (N, M, 3)
        cen = P.mean(1, keepdims=True)
        su = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(P.mean(1), axis=0), axis=1))])  # length along the ship
        for j in range(M):
            a, b = P[:, j], P[:, (j + 1) % M]
            if np.all(np.linalg.norm(a - b, axis=1) < 1e-7): continue
            seg = np.linalg.norm(b - a, axis=1); m = max(1, int(np.ceil(seg.max() / self.step)))  # columns across the strip (breach
            # patches, kit rays and the dress need vertices inside the faces, not only on the chines)
            base = len(self.pos); out = np.zeros(3)
            for i in range(N):
                for c in range(m + 1):
                    t = c / m; self.pos.append(a[i] * (1 - t) + b[i] * t); self.uv.append((su[i], self.vrow + seg[i] * t))
            self.vrow += seg.max() + .01
            mid = (a + b).mean(0) / 2; out = mid - cen.mean(0)[0]; out[0] = 0
            q0 = np.array(self.pos[base]); q1 = np.array(self.pos[base + 1]); q2 = np.array(self.pos[base + m + 2])
            flip = np.dot(np.cross(q1 - q0, q2 - q0), out) < 0
            fn_acc = np.zeros((N, m + 1, 3)); vid = lambda i, c: base + i * (m + 1) + c
            for i in range(N - 1):
                for c in range(m):
                    p0, p1, p2, p3 = vid(i, c), vid(i, c + 1), vid(i + 1, c + 1), vid(i + 1, c)
                    f1, f2 = ((p0, p1, p2), (p0, p2, p3)) if not flip else ((p2, p1, p0), (p3, p2, p0))
                    q = np.array([self.pos[k] for k in f1]); n = np.cross(q[1] - q[0], q[2] - q[0])
                    self.idx += [f1, f2]
                    for (ii, cc) in ((i, c), (i, c + 1), (i + 1, c), (i + 1, c + 1)): fn_acc[ii, cc] += n
            fn = fn_acc.sum(1, keepdims=True)  # smooth along the ship, flat across the strip
            fn = np.repeat(fn, m + 1, 1) / np.maximum(np.linalg.norm(fn, axis=2, keepdims=True), 1e-12)
            for i in range(N):
                for c in range(m + 1): self.nor.append(fn[i, c])
        for i, sgn in ((0, -1.0), (N - 1, 1.0)):  # end caps: a fan to the centre, flat normal along x
            base = len(self.pos); c = P[i].mean(0)
            self.pos.append(c); self.nor.append((sgn, 0, 0)); self.uv.append((c[1] + 1.0, c[2] + self.vrow + .2))
            for j in range(M):
                self.pos.append(P[i, j]); self.nor.append((sgn, 0, 0)); self.uv.append((P[i, j, 1] + 1.0, P[i, j, 2] + self.vrow + .2))
            for j in range(M):
                t = (base, base + 1 + j, base + 1 + (j + 1) % M)
                q = np.array([self.pos[k] for k in t]); n = np.cross(q[1] - q[0], q[2] - q[0])
                self.idx.append(t if n[0] * sgn > 0 else t[::-1])
            self.vrow += .5

    def arrays(self):
        pos = np.asarray(self.pos, np.float64); nor = np.asarray(self.nor, np.float64); uv = np.asarray(self.uv, np.float64)
        idx = np.asarray(self.idx, np.int64)
        # all islands into 0..1 keeping their true proportions (the bake re-packs them with the parts)
        uv -= uv.min(0); uv /= max(uv.max(), 1e-9); uv = uv * .98 + .01
        return pos, nor, idx, uv


def hull_frame(spec):
    """the sampled hull: xs, half-beam W(x), belly z, depth D(x) (deck z = belly + D)"""
    x0, x1 = spec['x']; N = spec.get('n', 220); xs = np.linspace(x0, x1, N)
    W = _curve(xs, spec['plan'], smooth=spec.get('plan_smooth', 9))
    zb = np.full(N, float(spec['zb']))
    D0 = float(spec['depth']); xd, tipd, pw = spec.get('deck_drop', (x1, 1.0, 2.5))
    s = np.clip((xs - xd) / max(x1 - xd, 1e-6), 0, 1); D = D0 * (1 - (1 - tipd) * s ** pw)
    return xs, W, zb, D


def loft(spec, tmp):
    """spec: x=(stern, prow cut), plan=[(x, half-beam)...], zb (belly z), depth, deck_drop=(x where the deck starts to chamfer down, depth at
    the prow as a share, power), tiers=[dict(x=(x0, x1), w (half-width), h, end (chamfer length), drop (how far the ends come down))],
    deck, belly (shares of the half-beam)"""
    M = Mesh(); xs, W, zb, D = hull_frame(spec)
    M.add_loft(xs, [_ring_hull(W[i], zb[i], D[i], spec) for i in range(len(xs))])
    zdeck = lambda x: float(np.interp(x, xs, zb + D))
    for t in spec.get('tiers', []):
        a, b = t['x']; n = t.get('n', 70); tx = np.linspace(a, b, n); e = t.get('end', .03)
        k = np.clip(np.minimum(tx - a, b - tx) / max(e, 1e-6), 0, 1); k = k * k * (3 - 2 * k)       # chamfered ends
        base = np.array([zdeck(x) for x in tx]) + t.get('base', 0.0) - .004                     # sunk a little into what it stands on
        h = t['h'] * (t.get('drop', .25) + (1 - t.get('drop', .25)) * k); w = t['w'] * (.82 + .18 * k)
        M.add_loft(tx, [_ring_tier(w[i], base[i], h[i]) for i in range(n)])
    pos, nor, idx, uv = M.arrays()
    return dict(pos=pos, nor=nor, idx=idx, uv=uv, uv2=uv, tex=ithar.neutral_maps(tmp), flipped=False)


def describe(spec):
    xs, W, zb, D = hull_frame(spec)
    for x in np.linspace(xs[0], xs[-1], 12):
        i = int(np.argmin(abs(xs - x))); print(f'x {xs[i]:+.3f} half-beam {W[i]:.3f} belly {zb[i]:+.3f} deck {zb[i] + D[i]:+.3f}')
