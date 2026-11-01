#!/usr/bin/env python3
"""F4 asteroid library: real rock shapes as small glTF files the game imports (godot/world/rocks/*.glb).

Shapes follow real small bodies rather than lumpy potatoes:
  fragment  S-type shards (Itokawa's halves, Eros): an elongated body broken by several flat fracture planes
  rubble    C-type rubble piles (Bennu, Ryugu): rounded, some with an equatorial ridge (spinning top), strewn with boulders
  binary    contact binaries (Itokawa, Arrokoth, comet 67P): two lobes joined by a neck
  slab      flat broken plates
  shard     ice shards: long prisms with sharp cuts
plus crystal clusters (hexagonal prisms with pointed tips) for crystal fields.

Each body is a radial surface on a fine icosphere (10,242 points): an ellipsoid (or two lobes), large-scale warping,
fracture planes (smooth-min cuts), ridges, a power-law crater population with bowls and raised rims, boulders, and fine
grit. Vertex colour carries what the shader needs: R open-sky (cavity AO), G crater floor, B fresh fracture face,
A a broad patch value. Run: python3 rockgen.py OUT_DIR [--preview sheet.png]
"""
import sys, os, json, struct, math
import numpy as np
from scipy import sparse

SUB = 5


def icosphere(sub):
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    v = [np.array(x, float) / np.linalg.norm(x) for x in v]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
         (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    for _ in range(sub):
        mid = {}
        nf = []

        def m(a, b):
            k = (min(a, b), max(a, b))
            if k not in mid:
                p = v[a] + v[b]
                v.append(p / np.linalg.norm(p))
                mid[k] = len(v) - 1
            return mid[k]
        for a, b, c in f:
            ab, bc, ca = m(a, b), m(b, c), m(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    return np.array(v), np.array(f, np.int64)


# ---------------------------------------------------------------- noise (vectorised gradient noise)
class Noise:
    def __init__(self, seed):
        r = np.random.default_rng(seed)
        self.perm = np.concatenate([r.permutation(256)] * 2)
        g = r.normal(size=(256, 3))
        self.grad = g / np.linalg.norm(g, axis=1, keepdims=True)

    def n(self, p):
        p = np.asarray(p, float)
        i = np.floor(p).astype(np.int64)
        f = p - i
        u = f * f * f * (f * (f * 6 - 15) + 10)
        i &= 255
        P = self.perm
        out = 0.0
        res = np.zeros(p.shape[:-1])
        for dx in (0, 1):
            for dy in (0, 1):
                for dz in (0, 1):
                    h = P[P[P[i[..., 0] + dx] + i[..., 1] + dy] + i[..., 2] + dz]
                    g = self.grad[h]
                    d = f - np.array([dx, dy, dz])
                    w = (u[..., 0] if dx else 1 - u[..., 0]) * (u[..., 1] if dy else 1 - u[..., 1]) * (u[..., 2] if dz else 1 - u[..., 2])
                    res += w * np.sum(g * d, axis=-1)
        return res  # about -0.7..0.7

    def fbm(self, p, oct=5, lac=2.03, gain=0.5):
        s, a, tot = 0.0, 1.0, 0.0
        q = np.asarray(p, float)
        for k in range(oct):
            s = s + a * self.n(q + k * 17.31)
            tot += a
            a *= gain
            q = q * lac
        return s / tot

    def ridged(self, p, oct=4):
        s, a, tot = 0.0, 1.0, 0.0
        q = np.asarray(p, float)
        for k in range(oct):
            v = 1 - np.abs(self.n(q + k * 7.7) * 1.6)
            s = s + a * v * v
            tot += a
            a *= 0.5
            q = q * 2.1
        return s / tot


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


def ray_ellipsoid(d, c, ax):
    """far intersection distance from the origin along unit d with the ellipsoid centre c, semi-axes ax (axis aligned)"""
    o = -c / ax
    dd = d / ax
    A = np.sum(dd * dd, -1)
    B = 2 * np.sum(dd * o, -1)
    C = np.sum(o * o) - 1
    disc = B * B - 4 * A * C
    t = (-B + np.sqrt(np.maximum(disc, 0))) / (2 * A)
    return np.where(disc > 0, t, 0.0)


def rand_dir(r, n=None):
    v = r.normal(size=(3,) if n is None else (n, 3))
    return v / np.linalg.norm(v, axis=-1, keepdims=True)


def adjacency(F, n):
    rows = np.concatenate([F[:, 0], F[:, 1], F[:, 2], F[:, 1], F[:, 2], F[:, 0]])
    cols = np.concatenate([F[:, 1], F[:, 2], F[:, 0], F[:, 0], F[:, 1], F[:, 2]])
    A = sparse.coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(n, n)).tocsr()
    A.data[:] = 1.0
    deg = np.asarray(A.sum(1)).ravel()
    return sparse.diags(1.0 / deg) @ A


def smooth(W, x, it):
    for _ in range(it):
        x = 0.5 * x + 0.5 * (W @ x)
    return x


def body(seed, family, D, F, W):
    r = np.random.default_rng(seed)
    nz = Noise(seed * 7 + 1)
    # direction warp: no body is a clean ellipsoid
    wv = np.stack([nz.fbm(D * 1.1 + o, 3) for o in (0.0, 31.7, 63.1)], -1)
    Dw = D + wv * (0.22 if family in ("rubble",) else 0.3)
    Dw /= np.linalg.norm(Dw, axis=1, keepdims=True)
    if family == "binary":
        a1 = np.array([r.uniform(.55, .7), r.uniform(.42, .55), r.uniform(.4, .5)])
        a2 = a1 * r.uniform(0.7, 0.9)
        off = r.uniform(0.26, 0.34)
        c1 = np.array([-off * 0.55, 0, 0])
        c2 = np.array([off, r.uniform(-.08, .08), r.uniform(-.08, .08)])
        R1 = ray_ellipsoid(Dw, c1, a1)
        R2 = ray_ellipsoid(Dw, c2, a2)
        R = -smin(-R1, -R2, 0.22)
        cuts = r.integers(1, 4)
    else:
        ax = {"fragment": ([1, 1], [.55, .8], [.4, .62]), "rubble": ([1, 1], [.8, .95], [.7, .88]), "slab": ([1, 1], [.6, .8], [.24, .36]),
              "shard": ([1, 1], [.34, .5], [.3, .42])}[family]
        a = np.array([r.uniform(*ax[0]), r.uniform(*ax[1]), r.uniform(*ax[2])])
        R = 1.0 / np.sqrt(np.sum((Dw / a) ** 2, 1))
        cuts = {"fragment": r.integers(4, 8), "rubble": r.integers(0, 2), "slab": r.integers(3, 6), "shard": r.integers(5, 9)}[family]
    R = R * (1 + (0.16 if family != "rubble" else 0.1) * nz.fbm(D * 1.6 + 5.0, 4))
    pre = R.copy()
    # fracture planes: flat broken faces with slightly rounded edges
    for k in range(int(cuts)):
        n = rand_dir(r)
        if family == "shard":   # cut mostly along the long axis: prismatic
            n[0] *= 0.35
            n /= np.linalg.norm(n)
        ext = np.max(R * (D @ n))
        h = ext * r.uniform(0.62, 0.86)
        dn = D @ n
        t = np.where(dn > 1e-3, h / np.maximum(dn, 1e-3), 1e9)
        R = smin(R, t, 0.025 if family in ("shard", "fragment") else 0.05)
    facet = np.clip((pre - R) / 0.04, 0, 1)
    # equatorial ridge (spinning-top rubble piles)
    if family == "rubble":
        # spinning top (Bennu, Ryugu): flattened poles and a sharp equatorial ridge, or a plainer oblate pile
        top = r.random() < 0.65
        R = R * (1 - (0.2 if top else 0.1) * np.abs(D[:, 1]) ** 1.5) * (1 + (0.12 if top else 0.04) * np.exp(-(D[:, 1] / 0.2) ** 2))
    # ridges and grooves
    R = R * (1 + 0.035 * (nz.ridged(D * 3.2 + 2.0) - 0.55))
    # craters: a power-law population; older ones softer
    crater = np.zeros(len(D))
    ncr = {"fragment": 34, "rubble": 12, "binary": 28, "slab": 20, "shard": 8}[family]
    for k in range(ncr):
        c = rand_dir(r)
        rho = min(0.6, 0.06 * (1 - r.random()) ** (-1 / 1.6))
        depth = rho * r.uniform(0.2, 0.34)
        age = r.random()
        ang = np.arccos(np.clip(D @ c, -1, 1))
        u = ang / rho
        bowl = np.where(u < 1, 1 - u * u, 0.0)
        rim = np.exp(-((u - 1) / (0.22 + 0.2 * age)) ** 2) * 0.28 * (1 - 0.6 * age)
        R = R * (1 + depth * (-bowl * (1 - 0.5 * age) + rim))
        crater = np.maximum(crater, bowl * (1 - 0.4 * age))
    # boulders on rubble piles and some others
    nb = {"fragment": 18, "rubble": 90, "binary": 30, "slab": 10, "shard": 0}[family]
    for k in range(nb):
        c = rand_dir(r)
        rho = 0.03 + 0.07 * r.random() ** 2
        ang = np.arccos(np.clip(D @ c, -1, 1))
        R = R * (1 + rho * 0.5 * np.exp(-(ang / rho) ** 2 * 2.0))
    # grit
    R = R * (1 + 0.012 * nz.fbm(D * 13 + 9.0, 3))
    P = D * R[:, None]
    # centre on the volume-ish centroid, scale so the longest half-extent is 1
    P -= (P.max(0) + P.min(0)) * 0.5
    P /= np.abs(P).max()
    # vertex normals (area weighted)
    fn = np.cross(P[F[:, 1]] - P[F[:, 0]], P[F[:, 2]] - P[F[:, 0]])
    N = np.zeros_like(P)
    for j in range(3):
        np.add.at(N, F[:, j], fn)
    N /= np.linalg.norm(N, axis=1, keepdims=True) + 1e-12
    # cavity AO: how far a point sits below its smoothed neighbourhood, at two scales
    rr = np.linalg.norm(P, axis=1)
    s1 = smooth(W, rr, 6)
    s2 = smooth(W, rr, 40)
    cav = np.clip(1 - 9 * np.maximum(s1 - rr, 0) - 3.5 * np.maximum(s2 - rr, 0), 0.15, 1)
    patch = 0.5 + 0.9 * nz.fbm(D * 1.4 + 40.0, 3)
    col = np.stack([cav, np.clip(crater, 0, 1), facet, np.clip(patch, 0, 1)], 1)
    return P.astype(np.float32), N.astype(np.float32), col


def crystal_cluster(seed):
    r = np.random.default_rng(seed)
    verts, norms, cols, idx = [], [], [], []

    def add_tri(a, b, c, ca, cb, cc):
        n = np.cross(b - a, c - a)
        n /= np.linalg.norm(n) + 1e-12
        base = len(verts)
        for p, q in ((a, ca), (b, cb), (c, cc)):
            verts.append(p)
            norms.append(n)
            cols.append(q)
        idx.extend([base, base + 1, base + 2])
    nc = r.integers(6, 12)
    for k in range(nc):
        axis = rand_dir(r)
        axis[1] = abs(axis[1]) * 1.5 + 0.4
        axis /= np.linalg.norm(axis)
        L = r.uniform(0.45, 1.0) * (1.0 if k else 1.25)
        w = L * r.uniform(0.09, 0.16)
        tipl = w * r.uniform(1.3, 2.2)
        u = np.cross(axis, [0.31, 0.12, 0.94])
        u /= np.linalg.norm(u)
        v = np.cross(axis, u)
        base = axis * r.uniform(-0.05, 0.05) - axis * 0.15
        ring0 = [base + w * (math.cos(a) * u + math.sin(a) * v) for a in np.linspace(0, 2 * math.pi, 7)[:-1]]
        ring1 = [p + axis * L for p in ring0]
        tip = base + axis * (L + tipl)
        for j in range(6):
            a0, a1, b0, b1 = ring0[j], ring0[(j + 1) % 6], ring1[j], ring1[(j + 1) % 6]
            c0 = (1, 0, 0, 1)
            c1 = (1, 0.75, 0, 1)
            ct = (1, 1, 0, 1)
            add_tri(a0, a1, b1, c0, c0, c1)
            add_tri(a0, b1, b0, c0, c1, c1)
            add_tri(b0, b1, tip, c1, c1, ct)
    P = np.array(verts, np.float32)
    P -= np.array([(P[:, 0].max() + P[:, 0].min()) / 2, P[:, 1].min(), (P[:, 2].max() + P[:, 2].min()) / 2], np.float32)
    P /= np.abs(P).max()
    return P, np.array(norms, np.float32), np.array(cols, float), np.array(idx, np.int64).reshape(-1, 3)


# ---------------------------------------------------------------- glTF writer (positions, normals, COLOR_0, indices)
def write_glb(path, P, N, C, F, name):
    F = np.asarray(F)
    big = P.shape[0] > 65535
    ib = F.astype(np.uint32 if big else np.uint16).tobytes()
    pb = P.astype(np.float32).tobytes()
    nb = N.astype(np.float32).tobytes()
    cb = np.clip(np.round(np.asarray(C) * 255), 0, 255).astype(np.uint8).tobytes()

    def pad(b):
        return b + b"\0" * ((4 - len(b) % 4) % 4)
    chunks = [pad(ib), pad(pb), pad(nb), pad(cb)]
    offs = np.cumsum([0] + [len(c) for c in chunks]).tolist()
    blob = b"".join(chunks)
    views = [{"buffer": 0, "byteOffset": offs[0], "byteLength": len(ib), "target": 34963},
             {"buffer": 0, "byteOffset": offs[1], "byteLength": len(pb), "target": 34962},
             {"buffer": 0, "byteOffset": offs[2], "byteLength": len(nb), "target": 34962},
             {"buffer": 0, "byteOffset": offs[3], "byteLength": len(cb), "target": 34962}]
    acc = [{"bufferView": 0, "componentType": 5125 if big else 5123, "count": int(F.size), "type": "SCALAR"},
           {"bufferView": 1, "componentType": 5126, "count": len(P), "type": "VEC3", "min": P.min(0).tolist(), "max": P.max(0).tolist()},
           {"bufferView": 2, "componentType": 5126, "count": len(P), "type": "VEC3"},
           {"bufferView": 3, "componentType": 5121, "normalized": True, "count": len(P), "type": "VEC4"}]
    g = {"asset": {"version": "2.0", "generator": "voidsworn F4 rockgen"}, "scene": 0, "scenes": [{"nodes": [0]}],
         "nodes": [{"mesh": 0, "name": name}], "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 1, "NORMAL": 2, "COLOR_0": 3}, "indices": 0}]}],
         "buffers": [{"byteLength": len(blob)}], "bufferViews": views, "accessors": acc}
    js = json.dumps(g, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(blob), 0x004E4942) + blob)


# the library: name, family, seed; and which rock kinds draw on which families (world.gd reads rocks.json)
LIB = [("frag_%02d" % i, "fragment", 100 + i) for i in range(6)] + [("rubble_%02d" % i, "rubble", 200 + i) for i in range(5)] + \
      [("binary_%02d" % i, "binary", 300 + i) for i in range(4)] + [("slab_%02d" % i, "slab", 400 + i) for i in range(3)] + \
      [("shard_%02d" % i, "shard", 500 + i) for i in range(4)]
KINDS = {"stone": ["fragment", "binary", "slab", "rubble"], "iron": ["fragment", "slab", "binary"], "carbon": ["rubble", "binary", "fragment"],
         "ice": ["shard", "fragment", "binary"], "crystal": ["fragment", "slab", "shard"]}


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    D, F = icosphere(SUB)
    W = adjacency(F, len(D))
    # the low-detail sphere's points are the first points of the fine one (subdivision only appends), so a far copy of
    # each rock is the same shape sampled on 642 points
    D3, F3 = icosphere(3)
    n3 = len(D3)
    assert np.allclose(D[:n3], D3)
    man = {"rocks": [], "crystals": [], "kinds": KINDS}
    shapes = []
    for name, fam, seed in LIB:
        P, N, C = body(seed, fam, D, F, W)
        # glTF faces counter-clockwise seen from outside: the icosphere's are clockwise
        write_glb(os.path.join(out, name + ".glb"), P, N, C, F[:, [0, 2, 1]], name)
        Pl = P[:n3]
        fl = np.cross(Pl[F3[:, 1]] - Pl[F3[:, 0]], Pl[F3[:, 2]] - Pl[F3[:, 0]])
        Nl = np.zeros_like(Pl)
        for j in range(3):
            np.add.at(Nl, F3[:, j], fl)
        Nl /= np.linalg.norm(Nl, axis=1, keepdims=True) + 1e-12
        write_glb(os.path.join(out, name + "_lo.glb"), Pl, Nl.astype(np.float32), C[:n3], F3[:, [0, 2, 1]], name + "_lo")
        ext = (P.max(0) - P.min(0)).tolist()
        man["rocks"].append({"name": name, "family": fam, "ext": [round(x, 3) for x in ext]})
        shapes.append((P, F, C))
        print(name, fam, "ext", np.round(ext, 2))
    for i in range(3):
        P, N, C, Fc = crystal_cluster(900 + i)
        write_glb(os.path.join(out, "crystal_%02d.glb" % i), P, N, C, Fc, "crystal_%02d" % i)
        man["crystals"].append("crystal_%02d" % i)
    with open(os.path.join(out, "rocks.json"), "w") as f:
        json.dump(man, f, indent=1)
    if "--preview" in sys.argv:
        preview(shapes, sys.argv[sys.argv.index("--preview") + 1])


def preview(shapes, path, S=300):
    from PIL import Image
    L = np.array([0.45, 0.7, 0.55])
    L /= np.linalg.norm(L)
    tiles = []
    for P, F, C in shapes:
        a, b = 0.6, 0.5
        Ry = np.array([[math.cos(a), 0, math.sin(a)], [0, 1, 0], [-math.sin(a), 0, math.cos(a)]])
        Rx = np.array([[1, 0, 0], [0, math.cos(b), -math.sin(b)], [0, math.sin(b), math.cos(b)]])
        V = P @ Ry.T @ Rx.T
        xy = (V[:, :2] * 0.46 + 0.5) * S
        img = np.zeros((S, S, 3))
        zb = np.full((S, S), -1e9)
        fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
        fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-12
        for t, n in zip(F, fn):
            if n[2] < 0:
                continue
            Pt = xy[t]
            x0, y0 = np.floor(Pt.min(0)).astype(int)
            x1, y1 = np.ceil(Pt.max(0)).astype(int)
            x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, S - 1), min(y1, S - 1)
            if x1 < x0 or y1 < y0:
                continue
            X, Y = np.meshgrid(np.arange(x0, x1 + 1) + .5, np.arange(y0, y1 + 1) + .5)
            d = (Pt[1, 1] - Pt[2, 1]) * (Pt[0, 0] - Pt[2, 0]) + (Pt[2, 0] - Pt[1, 0]) * (Pt[0, 1] - Pt[2, 1])
            if abs(d) < 1e-9:
                continue
            w0 = ((Pt[1, 1] - Pt[2, 1]) * (X - Pt[2, 0]) + (Pt[2, 0] - Pt[1, 0]) * (Y - Pt[2, 1])) / d
            w1 = ((Pt[2, 1] - Pt[0, 1]) * (X - Pt[2, 0]) + (Pt[0, 0] - Pt[2, 0]) * (Y - Pt[2, 1])) / d
            w2 = 1 - w0 - w1
            ins = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
            zz = w0 * V[t[0], 2] + w1 * V[t[1], 2] + w2 * V[t[2], 2]
            sub = zb[y0:y1 + 1, x0:x1 + 1]
            upd = ins & (zz > sub)
            sub[upd] = zz[upd]
            c = C[t].mean(0)
            sh = (0.06 + 0.94 * max(0, n @ (Rx @ Ry @ L))) * (0.35 + 0.65 * c[0])
            col = np.array([0.55, 0.5, 0.45]) * (1 - 0.4 * c[1]) * (1 + 0.35 * c[2])
            img[y0:y1 + 1, x0:x1 + 1][upd] = col * sh
        tiles.append(np.flipud(img))
    cols = 6
    rows = (len(tiles) + cols - 1) // cols
    sheet = np.zeros((rows * S, cols * S, 3))
    for k, t in enumerate(tiles):
        sheet[(k // cols) * S:(k // cols + 1) * S, (k % cols) * S:(k % cols + 1) * S] = t
    Image.fromarray((np.clip(sheet, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8)).save(path)


if __name__ == "__main__":
    main()
