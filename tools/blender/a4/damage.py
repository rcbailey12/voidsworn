# A4 breach damage geometry (R39, Oct 26 2026: "right now it's just an orange shape with weird smoke, the actual underlying ship looks
# the same"). For every breach anchor of a built ship, real hull damage the effects helper (G4) swaps in at the breach stage:
#   skin_<n>         the patch of live hull that the hole replaces (a child mesh of the ship; hide it when the hole opens)
#   skin_<n>_heavy   the wider patch the heavy damage also tears away (it reaches through thin hull, so the silhouette loses a bite)
#   breach_<n>_hole  torn plates bent outward round a jagged hole (the ship's own paint on the outside, bare metal behind, a hot edge),
#                    and the guts behind it: a cavity with frame rings and stringers, deck layers, conduits (some torn and sparking),
#                    a dark interior with fire glow
#   breach_<n>_heavy the same at about twice the size and deeper, with more decks, more fire and more torn conduits
# Pure numpy on the exported arrays (CODE_ship.npz + CODE_meta.json): runs in the cloud or on the PC, no Blender, no rebake.
# Frame: glTF (+X bow, +Y up, -Z port), ship length about 1. Everything is built in the ship's own frame (node transforms identity).
import json, math, os
import numpy as np

UP = np.array([0., 1., 0.])
HOLE_R = {'S': .042, 'M': .036, 'L': .031, 'XL': .027}  # hole radius, ship lengths (the heavy damage is HEAVY_K times wider)
HEAVY_K = 2.1
RAM_LABEL = 9999  # the bow zone the ram crumples (skin_bow in the ship glb)
PLATE = .0016  # torn plate thickness, ship lengths
# faction interiors: (cavity wall, frames and decks, fire glow, torn-edge heat); Chorus guts are flesh and bone, not metal
INTERIOR = {
    'voidsworn': ((.035, .030, .028), (.13, .12, .11), (1.0, .42, .10), (1.0, .55, .22)),
    'hegemony': ((.050, .055, .062), (.30, .32, .35), (1.0, .50, .16), (1.0, .62, .30)),
    'corsair': ((.045, .028, .018), (.17, .10, .06), (1.0, .38, .08), (1.0, .50, .18)),
    'chorus': ((.10, .018, .022), (.55, .48, .38), (.55, 1.0, .25), (.85, .95, .30)),
    'ithar': ((.060, .075, .070), (.70, .72, .66), (.45, 1.0, .75), (.75, 1.0, .85)),
    'deathless': ((.030, .036, .032), (.16, .18, .17), (.35, 1.0, .30), (.60, 1.0, .50)),
}


# ------------------------------------------------------------------------------------------------------------------------------------
def unit(v):
    v = np.asarray(v, float); return v / max(np.linalg.norm(v), 1e-12)


def ray_hits(o, d, tp):
    """distances along ray o + t d to every triangle in tp (N, 3, 3) it crosses (Moller-Trumbore), t > 0"""
    e1 = tp[:, 1] - tp[:, 0]; e2 = tp[:, 2] - tp[:, 0]; pv = np.cross(d, e2); det = np.einsum('ij,ij->i', e1, pv)
    ok = np.abs(det) > 1e-12; inv = np.where(ok, 1 / np.where(ok, det, 1), 0); tv = o - tp[:, 0]
    u = np.einsum('ij,ij->i', tv, pv) * inv; qv = np.cross(tv, e1); v = (qv @ d) * inv; t = np.einsum('ij,ij->i', e2, qv) * inv
    m = ok & (u >= 0) & (v >= 0) & (u + v <= 1) & (t > 1e-6)
    return t[m]


def first_hit(o, d, tp):
    t = ray_hits(o, d, tp); return float(t.min()) if len(t) else None


class Mesh:
    """flat-shaded triangle soup per material (crisp, industrial; every triangle owns its corners)"""
    def __init__(self): self.P = {}; self.U = {}

    def tri(self, mat, a, b, c, uv=None):
        self.P.setdefault(mat, []).append((a, b, c))
        if uv is not None: self.U.setdefault(mat, []).append(uv)

    def quad(self, mat, a, b, c, d): self.tri(mat, a, b, c); self.tri(mat, a, c, d)

    def strip(self, mat, A, B, closed=True):
        """quads between two point rows A[i], B[i]"""
        n = len(A)
        for i in range(n if closed else n - 1):
            j = (i + 1) % n; self.quad(mat, A[i], A[j], B[j], B[i])

    def box(self, mat, c, ax, ay, az):
        """box centred at c with half axes ax, ay, az (vectors)"""
        cs = [c + sx * ax + sy * ay + sz * az for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)): self.quad(mat, *[cs[k] for k in f])

    def cyl(self, mat, a, b, r, seg=8, caps=True):
        d = unit(b - a); t = unit(np.cross(d, UP if abs(d @ UP) < .9 else np.array([1., 0, 0]))); s = np.cross(d, t)
        A = [a + r * (math.cos(2 * math.pi * k / seg) * t + math.sin(2 * math.pi * k / seg) * s) for k in range(seg)]; B = [q + (b - a) for q in A]
        self.strip(mat, A, B)
        if caps:
            for k in range(seg): self.tri(mat, a, A[(k + 1) % seg], A[k]); self.tri(mat, b, B[k], B[(k + 1) % seg])

    def blob(self, mat, c, r):
        """a small octahedron (fire glow spot, spark)"""
        v = [c + r * np.array(x) for x in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))]
        for a, b, cc in ((0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)): self.tri(mat, v[a], v[b], v[cc])

    def arrays(self):
        out = {}
        for mat, tris in self.P.items():
            T = np.array(tris, np.float64).reshape(-1, 3, 3)
            fn = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); good = np.linalg.norm(fn, axis=1) > 1e-14
            T = T[good]; fn = fn[good]; fn /= np.linalg.norm(fn, axis=1, keepdims=True)
            pos = T.reshape(-1, 3).astype(np.float32); nor = np.repeat(fn, 3, 0).astype(np.float32)
            d = dict(pos=pos, nor=nor, idx=np.arange(len(pos), dtype=np.uint32).reshape(-1, 3))
            if mat in self.U: d['uv'] = np.array(self.U[mat], np.float32).reshape(-1, 3, 2)[good].reshape(-1, 2)
            out[mat] = d
        return out


def double_sided_inward(M, mat, ring_rows, axis_c, closed=True):
    """cavity wall from rows of points (rim first); faces turned toward the axis line (the inside is what shows through the hole)"""
    for r in range(len(ring_rows) - 1):
        A, B = ring_rows[r], ring_rows[r + 1]; n = len(A)
        for i in range(n if closed else n - 1):
            j = (i + 1) % n; a, b, c, d = A[i], A[j], B[j], B[i]
            fn = np.cross(b - a, c - a); toward = axis_c - (a + c) / 2
            if fn @ toward < 0: M.quad(mat, a, d, c, b)
            else: M.quad(mat, a, b, c, d)


# ------------------------------------------------------------------------------------------------------------------------------------
class Ship:
    def __init__(self, npz, meta):
        m = dict(np.load(npz)); self.pos = m['pos'].astype(np.float64); self.idx = m['idx'].astype(np.int64); self.uv = m['uv']
        self.sail = m['sail'].astype(bool) if 'sail' in m else np.zeros(len(self.idx), bool)
        self.T = self.pos[self.idx]; self.C = self.T.mean(1)
        fn = np.cross(self.T[:, 1] - self.T[:, 0], self.T[:, 2] - self.T[:, 0]); self.A = np.linalg.norm(fn, axis=1) / 2
        self.FN = fn / np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
        self.meta = meta; self.fac = meta['faction']; self.band = meta.get('band') or 'M'
        self.label = np.zeros(len(self.idx), np.int32)  # 0 live hull; 2n+1 skin of hole n; 2n+2 extra skin of heavy n
        self.anchors = [h for h in meta['hardpoints'] if h['extras']['kind'] == 'breach']

    def near(self, p, R):
        """triangles (indices) whose centre is within R of p (solid hull only, no sails)"""
        return np.nonzero((np.linalg.norm(self.C - p, axis=1) < R) & ~self.sail)[0]


def jag_fn(rng, amp=1.0):
    ph = rng.uniform(0, 2 * math.pi, 4); k = rng.choice([3, 4, 5])
    return lambda th: 1 + amp * (.16 * np.sin(k * th + ph[0]) + .10 * np.sin((k + 2) * th + ph[1]) + .07 * np.sin(11 * th + ph[2]) + .05 * np.sin(17 * th + ph[3]))


def frame_at(h):
    n = unit(h['up']); t1 = unit(np.array(h['fwd']) - n * (np.array(h['fwd']) @ n)); t2 = np.cross(n, t1)
    return np.array(h['p'], float), n, t1, t2


def regions(S, rng):
    """label the skins: every hole first (they have priority), then the heavy rings"""
    r = HOLE_R.get(S.band, .034); info = []
    for k, h in enumerate(S.anchors):
        p, n, t1, t2 = frame_at(h); jag = jag_fn(rng)
        ii = S.near(p, r * 1.6); d = S.C[ii] - p; hh = d @ n; a = d @ t1; b = d @ t2; rho = np.hypot(a, b); th = np.arctan2(b, a)
        sel = ii[(rho < r * jag(th)) & (np.abs(hh) < r * .9) & (S.FN[ii] @ n > -.15) & (S.label[ii] == 0)]
        S.label[sel] = 2 * k + 1; info.append(dict(p=p, n=n, t1=t1, t2=t2, jag=jag, r=r))
    for k, inf in enumerate(info):
        R = r * HEAVY_K; jag2 = jag_fn(rng, 1.3); c = inf['p'] - inf['n'] * R * .30
        ii = S.near(c, R * 1.5); d = S.C[ii] - inf['p']; a = d @ inf['t1']; b = d @ inf['t2']; th = np.arctan2(b, a)
        sel = ii[(np.linalg.norm(S.C[ii] - c, axis=1) < R * jag2(th)) & (S.label[ii] == 0)]
        S.label[sel] = 2 * k + 2; inf.update(R=R, jag2=jag2, c=c)
    return info


# ------------------------------------------------------------------------------------------------------------------------------------
def petals(S, M, tris, inf, rad, jag, rng, bend=(.35, 1.1), K=7, gaps=2, r_in=.45):
    """the outer band of the removed skin, copied and bent outward about the hole's rim in K petals (some sectors missing), with a
    bare-metal back and a hot torn edge; the copied faces keep the ship's paint (same UVs and maps)"""
    if len(tris) == 0: return
    p, n, t1, t2 = inf['p'], inf['n'], inf['t1'], inf['t2']
    rot = rng.uniform(0, 2 * math.pi); gap = set(rng.choice(K, size=min(gaps, K - 1), replace=False).tolist()); phi = rng.uniform(*bend, K)
    sector = lambda th: (np.floor(((th + rot) % (2 * math.pi)) / (2 * math.pi) * K)).astype(int)
    d = S.C[tris] - p; th = np.arctan2(d @ t2, d @ t1); rho = np.hypot(d @ t1, d @ t2)
    keep = tris[(rho > rad * r_in * jag(th)) & ~np.isin(sector(th), list(gap))]
    if len(keep) == 0: return
    sec_t = sector(np.arctan2((S.C[keep] - p) @ t2, (S.C[keep] - p) @ t1))
    band = rad * (1 - r_in) * 1.1
    V0 = S.T[keep]; elen = np.linalg.norm(V0 - np.roll(V0, 1, axis=1), axis=2).max(1)
    small = elen < band * .6  # big flat triangles would bend into long spikes: they just go with the hole
    keep = keep[small]; sec_t = sec_t[small]
    if len(keep) == 0: return
    V = S.T[keep]; UVt = S.uv[S.idx[keep]]
    q = V - p; a = q @ t1; b = q @ t2; hh = q @ n; rh = np.hypot(a, b); tv = np.arctan2(b, a)
    hinge = rad * jag(tv); s = np.clip(hinge - rh, 0, band); ph = phi[sec_t][:, None] + .18 * np.sin(rh * 700 + tv * 5)  # a little crumple
    r2 = hinge - s * np.cos(ph); h2 = hh + s * np.sin(ph)
    dirs = np.stack([np.cos(tv), np.sin(tv)], -1)
    W = p + (r2 * dirs[..., 0])[..., None] * t1 + (r2 * dirs[..., 1])[..., None] * t2 + h2[..., None] * n
    # back side (bare metal) a plate's thickness under each bent face, and the torn edge between them
    fn = np.cross(W[:, 1] - W[:, 0], W[:, 2] - W[:, 0]); fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    Bk = W - fn[:, None, :] * PLATE
    for i in range(len(W)):
        M.tri('hull', W[i, 0], W[i, 1], W[i, 2], uv=UVt[i]); M.tri('interior', Bk[i, 0], Bk[i, 2], Bk[i, 1])
    # free edges (used by one kept triangle, away from the hinge) get the hot edge strip
    key = lambda x: tuple(np.round(x, 7))
    cnt = {}
    for i in range(len(V)):
        for e in ((0, 1), (1, 2), (2, 0)):
            k_ = tuple(sorted((key(V[i, e[0]]), key(V[i, e[1]])))); cnt[k_] = cnt.get(k_, 0) + 1
    for i in range(len(V)):
        for e in ((0, 1), (1, 2), (2, 0)):
            k_ = tuple(sorted((key(V[i, e[0]]), key(V[i, e[1]]))))
            if cnt[k_] == 1 and min(s[i, e[0]], s[i, e[1]]) > band * .12:
                M.quad('edge', W[i, e[0]], Bk[i, e[0]], Bk[i, e[1]], W[i, e[1]]); M.quad('edge', W[i, e[1]], Bk[i, e[1]], Bk[i, e[0]], W[i, e[0]])


def subdivide(V, UV, times):
    """split each triangle in four, `times` over (positions and UVs together), so a fine displacement (acid pits) has vertices to move"""
    for _ in range(times):
        m01, m12, m20 = (V[:, 0] + V[:, 1]) / 2, (V[:, 1] + V[:, 2]) / 2, (V[:, 2] + V[:, 0]) / 2
        u01, u12, u20 = (UV[:, 0] + UV[:, 1]) / 2, (UV[:, 1] + UV[:, 2]) / 2, (UV[:, 2] + UV[:, 0]) / 2
        V = np.concatenate([np.stack(t, 1) for t in ((V[:, 0], m01, m20), (m01, V[:, 1], m12), (m20, m12, V[:, 2]), (m01, m12, m20))])
        UV = np.concatenate([np.stack(t, 1) for t in ((UV[:, 0], u01, u20), (u01, UV[:, 1], u12), (u20, u12, UV[:, 2]), (u01, u12, u20))])
    return V, UV


def copy_skin(S, M, tris, xform, hot, sub=0):
    """copy ship triangles (keeping their paint), move them with xform(V) -> W (both (N, 3, 3)), give them a bare-metal back a plate's
    thickness under, and a hot edge strip on free edges where hot(Va, Vb) says so (Va, Vb: the edge's original end points). sub: split
    each triangle in four that many times first (no hot edges then)"""
    if len(tris) == 0: return
    V = S.T[tris]; UVt = S.uv[S.idx[tris]]
    if sub: V, UVt = subdivide(V, UVt, sub); hot = lambda a, b: False
    W = xform(V)
    fn = np.cross(W[:, 1] - W[:, 0], W[:, 2] - W[:, 0]); fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    Bk = W - fn[:, None, :] * PLATE
    for i in range(len(W)):
        M.tri('hull', W[i, 0], W[i, 1], W[i, 2], uv=UVt[i]); M.tri('interior', Bk[i, 0], Bk[i, 2], Bk[i, 1])
    key = lambda x: tuple(np.round(x, 7)); cnt = {}
    for i in range(len(V)):
        for e in ((0, 1), (1, 2), (2, 0)):
            k_ = tuple(sorted((key(V[i, e[0]]), key(V[i, e[1]])))); cnt[k_] = cnt.get(k_, 0) + 1
    for i in range(len(V)):
        for e in ((0, 1), (1, 2), (2, 0)):
            k_ = tuple(sorted((key(V[i, e[0]]), key(V[i, e[1]]))))
            if cnt[k_] == 1 and hot(V[i, e[0]], V[i, e[1]]):
                M.quad('edge', W[i, e[0]], Bk[i, e[0]], Bk[i, e[1]], W[i, e[1]]); M.quad('edge', W[i, e[1]], Bk[i, e[1]], Bk[i, e[0]], W[i, e[0]])


def local(inf, X):
    """anchor-local coordinates of points X (..., 3): rho (distance from the anchor axis), theta, height along the normal"""
    q = X - inf['p']; a = q @ inf['t1']; b = q @ inf['t2']; return np.hypot(a, b), np.arctan2(b, a), q @ inf['n']


def lip(M, S, inf, rad, tp, mat='edge', w=.14, seg=28):
    """a molten lip ring on the real hull round a clean hole (hides the triangle-jagged cut)"""
    rim = rim_points(S, inf, rad, lambda th: np.ones_like(th), tp, nrim=seg, inset=-.02)
    n = inf['n']; inner = [p_ + (inf['p'] - p_) * w - n * rad * .05 for p_ in rim]; outer = [p_ + (p_ - inf['p']) * w * .6 for p_ in rim]
    top = [p_ + n * rad * .06 for p_ in rim]
    M.strip(mat, outer, top); M.strip(mat, top, inner)


def hit_variants(S, inf, k, tp, rng):
    """per-weapon damage at one anchor (R43): lance burn-through, torpedo crater, plasma splash, gauss punch. Each returns
    (Mesh, the skin labels it replaces)"""
    out = {}; r, R = inf['r'], inf['R']; hole = np.nonzero(S.label == 2 * k + 1)[0]; both = np.nonzero((S.label == 2 * k + 1) | (S.label == 2 * k + 2))[0]
    # lance: a clean round bore with a molten lip and glowing walls; the rest of the patch stays as it was
    M = Mesh(); rl = r * .62
    rho, th, hh = local(inf, S.C[hole]); keep = hole[rho > rl * 1.02]
    copy_skin(S, M, keep, lambda V: V, lambda a, b: local(inf, a)[0] < rl * 1.25 and local(inf, b)[0] < rl * 1.25)
    lip(M, S, inf, rl, tp)
    T = first_hit(inf['p'] - inf['n'] * .002, -inf['n'], tp); D = min(T if T else rl * 2, rl * 2.2)
    bore = [rim_points(S, inf, rl, lambda t_: np.ones_like(t_), tp, nrim=24, inset=.0)]
    for f in (.25, .5, .8):
        bore.append([p_ - inf['n'] * D * f + (inf['p'] - inf['n'] * D * f - (p_ - inf['n'] * D * f)) * .12 * f for p_ in bore[0]])
    double_sided_inward(M, 'edge', bore[:2], inf['p'] - inf['n'] * D * .5); double_sided_inward(M, 'interior', bore[1:], inf['p'] - inf['n'] * D * .5)
    M.blob('glow', inf['p'] - inf['n'] * D * .85, rl * .35)
    out['lance'] = (M, [2 * k + 1])
    # torpedo: a blast crater over the wide patch, the plating dished inward, a ragged blown centre over the guts
    M = Mesh(); dep = R * .28; jag = jag_fn(rng, 1.4)
    rho, th, hh = local(inf, S.C[both]); keep = both[rho > R * .34 * jag(th)]
    def dish(V):
        rh, tv, h_ = local(inf, V); f = np.clip(1 - (rh / (R * .95)) ** 2, 0, 1) ** 1.3
        wob = 1 + .25 * np.sin(tv * 7 + rh * 400)
        return V - inf['n'] * (dep * f * wob)[..., None]
    copy_skin(S, M, keep, dish, lambda a, b: local(inf, a)[0] < R * .55 and local(inf, b)[0] < R * .55)
    cavity(S, M, inf, R * .42, jag, tp, rng, heavy=True)
    out['torp'] = (M, [2 * k + 1, 2 * k + 2])
    # plasma splash: no hole; the plating melted into a shallow dimple with a glowing pool and spatter round it
    M = Mesh(); dep = r * .16
    def melt(V):
        rh, tv, h_ = local(inf, V); f = np.clip(1 - (rh / r) ** 2, 0, 1); rip = .3 * np.sin(rh * 900) * f
        return V - inf['n'] * (dep * (f + rip))[..., None]
    copy_skin(S, M, hole, melt, lambda a, b: False, sub=2)
    pool = [inf['p'] - inf['n'] * dep * .8 + (math.cos(t_) * inf['t1'] + math.sin(t_) * inf['t2']) * r * .38 * (1 + .25 * math.sin(5 * t_ + 1)) + inf['n'] * .0006
            for t_ in np.linspace(0, 2 * math.pi, 19)[:-1]]
    cpool = inf['p'] - inf['n'] * dep * .9 + inf['n'] * .0008
    for j in range(len(pool)): M.tri('glow', cpool, pool[j], pool[(j + 1) % len(pool)])
    for g in range(9):
        t_ = rng.uniform(0, 2 * math.pi); rr = r * rng.uniform(.45, .95)
        q = inf['p'] + (math.cos(t_) * inf['t1'] + math.sin(t_) * inf['t2']) * rr; hq = first_hit(q + inf['n'] * r, -inf['n'], tp)
        if hq is not None: M.blob('edge', q + inf['n'] * (r - hq), r * rng.uniform(.03, .07))
    out['splash'] = (M, [2 * k + 1])
    # gauss: a small punched hole, the edge petals flicked outward, a short tunnel of guts
    M = Mesh(); rg = r * .45
    rho, th, hh = local(inf, S.C[hole]); outer = hole[rho > r * .8]
    copy_skin(S, M, outer, lambda V: V, lambda a, b: False)
    petals(S, M, hole[rho <= r * .8], inf, r * .8, lambda t_: np.ones_like(t_), rng, bend=(.25, .6), K=6, gaps=0, r_in=rg / (r * .8))
    cavity(S, M, inf, rg, lambda t_: np.ones_like(t_), tp, rng)
    out['gauss'] = (M, [2 * k + 1])
    # acid (Chorus bioplasma and spines, R43 "bio acid pitting and spines"): no clean hole; the plating eaten into a cluster of pits that
    # run together, the patch sagging, a glowing pool in each pit, and bone-like spines driven in at a slant
    M = Mesh(); pits = []
    for g in range(8):
        t_ = rng.uniform(0, 2 * math.pi); rr = r * rng.uniform(0, .7); pits.append((rr * math.cos(t_), rr * math.sin(t_), r * rng.uniform(.14, .30), r * rng.uniform(.07, .14)))
    def eat(V):
        q = V - inf['p']; a = q @ inf['t1']; b = q @ inf['t2']; rh = np.hypot(a, b); dz = .35 * r * .25 * np.clip(1 - (rh / r) ** 2, 0, 1)
        for (pa, pb, pr, pd) in pits: dz = dz + pd * np.exp(-((a - pa) ** 2 + (b - pb) ** 2) / (pr * pr))
        return V - inf['n'] * dz[..., None]
    copy_skin(S, M, hole, eat, lambda a, b: False, sub=2)
    for (pa, pb, pr, pd) in pits:
        q = inf['p'] + inf['t1'] * pa + inf['t2'] * pb; hq = first_hit(q + inf['n'] * r, -inf['n'], tp)
        if hq is not None: M.blob('glow', q + inf['n'] * (r - hq) - inf['n'] * pd * .75, pr * .32)
    for g in range(3):
        t_ = rng.uniform(0, 2 * math.pi); rr = r * rng.uniform(.1, .6); q = inf['p'] + (math.cos(t_) * inf['t1'] + math.sin(t_) * inf['t2']) * rr
        hq = first_hit(q + inf['n'] * r, -inf['n'], tp)
        if hq is None: continue
        base = q + inf['n'] * (r - hq) - inf['n'] * r * .08; tilt = unit(inf['n'] + (math.cos(t_ + 2) * inf['t1'] + math.sin(t_ + 2) * inf['t2']) * rng.uniform(.4, .9))
        L_ = r * rng.uniform(.6, 1.0); w_ = r * .055
        for s_, (f0, f1, wf) in enumerate(((0, .45, 1.0), (.45, .8, .62), (.8, 1.0, .3))):
            M.cyl('frame', base + tilt * L_ * f0, base + tilt * L_ * f1, w_ * wf, seg=7)
    out['acid'] = (M, [2 * k + 1])
    # boarding breach (Corsair claws, Chorus tendrils): a neat round cut, its plug pushed in and lying askew in the short tunnel behind,
    # the cut edge still glowing
    M = Mesh(); rb = r * .55
    rho, th, hh = local(inf, S.C[hole]); keep = hole[rho > rb * 1.02]; plug = hole[rho <= rb * 1.02]
    copy_skin(S, M, keep, lambda V: V, lambda a, b: local(inf, a)[0] < rb * 1.3 and local(inf, b)[0] < rb * 1.3)
    lip(M, S, inf, rb, tp, w=.07)
    T = first_hit(inf['p'] - inf['n'] * .002, -inf['n'], tp); D = min(T if T else rb * 2, rb * 1.8)
    tun = [rim_points(S, inf, rb, lambda t_: np.ones_like(t_), tp, nrim=24, inset=.0)]
    for f in (.3, .7, 1.0): tun.append([p_ - inf['n'] * D * f for p_ in tun[0]])
    double_sided_inward(M, 'edge', tun[:2], inf['p'] - inf['n'] * D * .5); double_sided_inward(M, 'interior', tun[1:], inf['p'] - inf['n'] * D * .5)
    def push(V):
        q = V - inf['p']; a = q @ inf['t1']; b = q @ inf['t2']; h_ = q @ inf['n']; ang = math.radians(28)
        a2 = a * math.cos(ang) - h_ * math.sin(ang); h2 = a * math.sin(ang) + h_ * math.cos(ang)
        return inf['p'] + a2[..., None] * inf['t1'] + b[..., None] * inf['t2'] + (h2 - D * .7)[..., None] * inf['n']
    copy_skin(S, M, plug, push, lambda a, b: True)
    M.blob('glow', inf['p'] - inf['n'] * D * .95, rb * .3)
    out['board'] = (M, [2 * k + 1])
    return out


def ram_bow(S, rng, length=.10):
    """the crumpled bow for a ram: the first `length` of the ship (by x) squashed back and folded, keeping its paint; returns (Mesh,
    triangle mask of the bow zone)"""
    x1 = S.pos[:, 0].max(); x0 = x1 - length; zone = (S.C[:, 0] > x0) & ~S.sail
    if not zone.any(): return None, zone
    ax = S.C[zone][:, 1:].mean(0)
    def crush(V):
        W = V.copy(); u = np.clip((V[..., 0] - x0) / length, 0, 1)
        W[..., 0] = x0 + (V[..., 0] - x0) * (1 - .45 * u)  # squashed back, most at the tip
        rad = V[..., 1:] - ax; fold = 1 + .35 * u * np.sin(u * 19 + np.arctan2(rad[..., 1], rad[..., 0]) * 3)
        W[..., 1:] = ax + rad * fold[..., None]
        return W
    M = Mesh(); copy_skin(S, M, np.nonzero(zone)[0], crush, lambda a, b: False)
    for g in range(6):
        c_ = S.C[zone][int(rng.integers(zone.sum()))]; M.blob('glow', crush(c_[None, None, :])[0, 0], length * .04)
    return M, zone


def rim_points(S, inf, rad, jag, tp, nrim=28, inset=.10):
    """the cavity's rim, on the real hull round the hole: one ray per angle down the anchor normal (pulled in where the ray misses the
    hull, so the cavity follows the silhouette), set a little inside the skin"""
    p, n, t1, t2 = inf['p'], inf['n'], inf['t1'], inf['t2']; pts = []
    for j in range(nrim):
        th = 2 * math.pi * j / nrim; dr = math.cos(th) * t1 + math.sin(th) * t2; rr = rad * float(jag(np.array([th]))[0]) * 1.03; hit = None
        for _ in range(7):
            o = p + n * rad * 1.2 + dr * rr; t = first_hit(o, -n, tp)
            if t is not None and t < rad * 3.5: hit = o - n * t; break
            rr *= .8
        pts.append((hit if hit is not None else p + dr * rr * .5) - n * rad * inset)
    return pts


def cavity(S, M, inf, rad, jag, tp, rng, heavy=False):
    """the guts behind the hole: wall, frame rings, stringers, decks, conduits, fire"""
    p, n, t1, t2 = inf['p'], inf['n'], inf['t1'], inf['t2']; fac = S.fac
    T = first_hit(p - n * .002, -n, tp); T = T if T is not None else rad * 2.5
    D = float(np.clip(min(T * (.85 if heavy else .72), rad * (1.7 if heavy else 1.45)), rad * .35, None))
    rim = rim_points(S, inf, rad, jag, tp); nr = len(rim); q = p - n * D
    dirs = [math.cos(2 * math.pi * j / nr) * t1 + math.sin(2 * math.pi * j / nr) * t2 for j in range(nr)]
    rows = [rim]
    for k in (1, 2, 3, 4):
        f = k / 4; bot = [q + dirs[j] * rad * .55 for j in range(nr)]
        rows.append([rim[j] * (1 - f) + bot[j] * f - n * 0 + dirs[j] * rad * .10 * math.sin(math.pi * f) for j in range(nr)])
    axis_c = p - n * D * .5
    double_sided_inward(M, 'interior', rows, axis_c)
    for j in range(nr): M.tri('interior', q, rows[-1][(j + 1) % nr], rows[-1][j]) if (np.cross(rows[-1][(j + 1) % nr] - q, rows[-1][j] - q) @ n) > 0 else M.tri('interior', q, rows[-1][j], rows[-1][(j + 1) % nr])
    # frame rings (flanges standing in from the wall) and stringers along it
    organic = fac == 'chorus'
    for k in (1, 2, 3):
        R0 = rows[k]; R1 = [R0[j] + (axis_c - R0[j]) * (.12 if not organic else .18) for j in range(nr)]
        sh = -n * rad * .025
        M.strip('frame', R0, R1); M.strip('frame', [x + sh for x in R1], [x + sh for x in R0]); M.strip('frame', R1, [x + sh for x in R1])
    for j in range(0, nr, 4 if not heavy else 3):
        for k in range(len(rows) - 1):
            a, b = rows[k][j], rows[k + 1][j]; inw = unit(axis_c - (a + b) / 2) * rad * .05
            M.box('frame', (a + b) / 2 + inw, (b - a) / 2, inw, unit(np.cross(b - a, inw)) * rad * .022)
    # decks: across the cavity, layered along the ship's up axis (side breach) or stacked down the hole (top or bottom breach)
    side = abs(n @ UP) < .6
    if side:
        th_ = unit(np.cross(UP, n)); levels = [-.38, .05, .45] if heavy else [-.30, .30]
        for e in levels:
            y = e * rad + rng.uniform(-.06, .06) * rad; w = math.sqrt(max(rad * rad - y * y, 0)) * .92; front = rad * rng.uniform(.10, .35)
            back = D * .92; nseg = 7; row_f, row_b = [], []
            for s_ in range(nseg + 1):
                u = -w + 2 * w * s_ / nseg; jagf = front + rad * .25 * rng.uniform(0, 1) * (1 if heavy else .6)
                row_f.append(p + UP * y + th_ * u - n * jagf); row_b.append(p + UP * y + th_ * u * .6 - n * back)
            dz = UP * rad * .035
            M.strip('frame', row_f, row_b, closed=False); M.strip('frame', [x - dz for x in row_b], [x - dz for x in row_f], closed=False)
            M.strip('frame', [x - dz for x in row_f], row_f, closed=False)
            for s_ in range(0, nseg + 1, 3):  # embers along the torn deck edge
                if rng.uniform() < .6: M.blob('glow', row_f[s_] - dz * .5, rad * rng.uniform(.02, .045))
            for s_ in range(0, nseg + 1, 2):  # deck beams under the plate
                M.box('frame', (row_f[s_] + row_b[s_]) / 2 - dz * 1.8, (row_b[s_] - row_f[s_]) / 2, dz * .8, th_ * rad * .03)
    else:
        for f in ((.35, .7) if not heavy else (.25, .5, .78)):
            ring = [rows[0][j] * (1 - f) + rows[-1][j] * f + dirs[j] * rad * .08 for j in range(nr)]
            inner = [p - n * D * f + dirs[j] * rad * (.25 + .30 * rng.uniform()) for j in range(nr)]
            dz = -n * rad * .03
            M.strip('frame', ring, inner); M.strip('frame', [x + dz for x in inner], [x + dz for x in ring]); M.strip('frame', inner, [x + dz for x in inner])
    # conduits across the cavity, some torn with a sparking end
    ax2 = unit(np.cross(UP, n)) if side else t1
    for c_ in range(3 if not heavy else 4):
        f = rng.uniform(.3, .85); off = rng.uniform(-.5, .5) * rad; cen = p - n * D * f + (UP if side else t2) * off
        half = rad * (.95 - .4 * f) * (1.1 if organic else 1.0); rr = rad * rng.uniform(.045, .085) * (1.6 if organic else 1.0)
        a, b = cen - ax2 * half, cen + ax2 * half
        if rng.uniform() < (.55 if heavy else .35):  # torn: ends in the cavity with a glowing stub
            cut = rng.uniform(.25, .6); b = a + (b - a) * cut; M.blob('glow', b, rr * 1.4)
        M.cyl('frame', a, b, rr, seg=8)
        for g in range(int(rng.integers(1, 3))):  # lit bands (or veins of light for Chorus)
            gp = a + (b - a) * rng.uniform(.15, .85); dd = unit(b - a) * rr * .6; M.cyl('glow', gp - dd, gp + dd, rr * 1.12, seg=8)
    # fire glow on the floor of the cavity and the decks
    for g in range(int(rng.integers(4, 7)) + (5 if heavy else 0)):
        f = rng.uniform(.55, .98); th = rng.uniform(0, 2 * math.pi); rr = rad * rng.uniform(.0, .45)
        cen = p - n * D * f + (math.cos(th) * t1 + math.sin(th) * t2) * rr
        M.blob('glow', cen, rad * rng.uniform(.03, .08))


# ------------------------------------------------------------------------------------------------------------------------------------
def build(npz, meta_path, seed=7):
    """returns dict(label (per ship triangle), parts {name: {mat: arrays}}, anchors [...])"""
    meta = json.load(open(meta_path)); S = Ship(npz, meta); rng = np.random.default_rng(seed + sum(map(ord, meta['code'])))
    info = regions(S, rng); parts = {}; tp_all = S.T[~S.sail]
    for k, inf in enumerate(info):
        near = np.linalg.norm(S.C[~S.sail] - inf['p'], axis=1) < inf['R'] * 5; tp = tp_all[near]
        # the hole
        M = Mesh(); hole = np.nonzero(S.label == 2 * k + 1)[0]
        petals(S, M, hole, inf, inf['r'], inf['jag'], rng)
        cavity(S, M, inf, inf['r'], inf['jag'], tp, rng)
        parts[f'breach_{k}_hole'] = M.arrays()
        # the heavy damage: bigger torn band, deeper guts
        M = Mesh(); both = np.nonzero((S.label == 2 * k + 1) | (S.label == 2 * k + 2))[0]
        petals(S, M, both, inf, inf['R'], inf['jag2'], rng, bend=(.5, 1.25), K=9, gaps=3, r_in=.62)
        cavity(S, M, inf, inf['R'] * .92, inf['jag2'], tp, rng, heavy=True)
        parts[f'breach_{k}_heavy'] = M.arrays()
    secs = []
    for inf in info:
        x = inf['p'][0]; secs.append('prow' if x > .17 else ('eng' if x < -.17 else 'mid'))
    # per-weapon variants (R43) on one anchor per section (keeps the file small); G4 picks the variant of the anchor in the hit section
    hits = {}
    for sec in ('prow', 'mid', 'eng'):
        ks = [k for k in range(len(info)) if secs[k] == sec]
        if not ks: continue
        k = ks[0]; inf = info[k]; tp = tp_all[np.linalg.norm(S.C[~S.sail] - inf['p'], axis=1) < inf['R'] * 5]
        for kind, (M, labs) in hit_variants(S, inf, k, tp, rng).items():
            parts[f'breach_{k}_{kind}'] = M.arrays(); hits[f'breach_{k}_{kind}'] = dict(breach=k, kind=kind, hides=[f'skin_{(l - 1) // 2}' + ('' if l % 2 else '_heavy') for l in labs])
    # the ram: a crumpled bow (its own skin in the ship glb)
    M, zone = ram_bow(S, rng)
    if M is not None:
        hide = sorted({int(l) for l in np.unique(S.label[zone]) if l > 0})
        S.label[zone & (S.label == 0)] = RAM_LABEL
        parts['ram_bow'] = M.arrays(); hits['ram_bow'] = dict(kind='ram', hides=['skin_bow'] + [f'skin_{(l - 1) // 2}' + ('' if l % 2 else '_heavy') for l in hide])
    return dict(label=S.label, parts=parts, anchors=[dict(i=k, p=inf['p'].round(5).tolist(), n=inf['n'].round(5).tolist(), section=secs[k],
                                                           r=round(inf['r'], 5), r_heavy=round(inf['R'], 5)) for k, inf in enumerate(info)],
                fac=S.fac, hits=hits)


def materials(G, fac):
    wall, frame, glow, edge = INTERIOR.get(fac, INTERIOR['voidsworn'])
    mk = lambda name, col, met, rgh, em=None, es=1.0: G.material(dict({'name': name, 'pbrMetallicRoughness': {'baseColorFactor': [*col, 1], 'metallicFactor': met, 'roughnessFactor': rgh}},
                                                                      **({'emissiveFactor': list(em), 'extensions': {'KHR_materials_emissive_strength': {'emissiveStrength': es}}} if em else {})))
    org = fac == 'chorus'
    return {'interior': mk('damage_interior', wall, 0 if org else .55, .55 if org else .75, em=tuple(c * .04 for c in glow), es=1.0),
            'frame': mk('damage_frame', frame, 0 if org else .7, .45 if org else .55),
            'glow': mk('damage_glow', glow, 0, .6, em=glow, es=1.0),     # G4 scales the glow itself against its flash and exposure rules
            'edge': mk('damage_edge', edge, .3, .5, em=edge, es=.5)}
