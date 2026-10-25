# A2 max-detail ships: hand-style surface detail on the AI hulls, in the barge's manner (tools/blender/hs/detail_lib.py supplies the
# plate cutter, edge beads and rivets, oriented boxes and tubes; this file decides where things go on these hull shapes).
#
# Rules kept (CLAUDE.md): everything sits on the real hull surface (bent onto it by ray casts, a hair sunk so there is no light gap), on a
# visible mount where it is a fitting, in matched pairs mirrored across the hull's own symmetry plane (found from the mesh), no guns are
# added (so none can face backward), and nothing naval: no portholes in rows, no rails, masts, funnels, keels or anchors. The space
# vocabulary instead: armour plates with seams, sensor housings, recessed running lights, vents, conduit runs, equipment pods.
# Chorus is grown, not built: ridges, pores, veins and glowing sacs, no panels or pipes. Ithar: pearl with gold filigree inlay and jade
# lenses. Deathless: carved ossuary: rib bands, carved glyph panels, vertebra knobs, green slits.
#
# Every part is registered with PROPS[name] = dict(col=(r,g,b) linear, emit=0..1, rgh=roughness, met=metal); the build script writes
# these as attributes so the bake can read them.
import math, random
import numpy as np
import bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import hs_lib, detail_lib

PROPS = {}
_mark = [0]


def tag(col, emit=0.0, rgh=.5, met=.3):
    """props for every part made since the last tag() call"""
    for o in hs_lib.PARTS[_mark[0]:]:
        PROPS[o.name] = dict(col=tuple(col), emit=float(emit), rgh=float(rgh), met=float(met))
    _mark[0] = len(hs_lib.PARTS)


def srgb(h):
    c = [int(h[i:i + 2], 16) / 255. for i in (1, 3, 5)]
    return tuple(x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4 for x in c)


def mul(c, k): return tuple(min(1., x * k) for x in c)


# ---------------------------------------------------------------------------------------------------------------------------------------
class Hull:
    """the hull surface: BVH for ray casts, area-weighted surface samples with their baked AO and curvature (hulls_hi _m map), and the
    mirror plane the pairs are placed across"""
    def __init__(self, obj, mmap, plane_n, plane_c, seed=1):
        self.o = obj; me = obj.data
        bm = bmesh.new(); bm.from_mesh(me); bm.transform(obj.matrix_world); bmesh.ops.triangulate(bm, faces=bm.faces[:])
        self.T = BVHTree.FromBMesh(bm); bm.free()
        self.m = Vector(plane_n).normalized(); self.c = Vector(plane_c)
        me.calc_loop_triangles(); F = len(me.loop_triangles)
        tv = np.zeros(F * 3, np.int32); me.loop_triangles.foreach_get('vertices', tv); tv = tv.reshape(-1, 3)
        tl = np.zeros(F * 3, np.int32); me.loop_triangles.foreach_get('loops', tl); tl = tl.reshape(-1, 3)
        co = np.zeros(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', co); co = co.reshape(-1, 3)
        uv = np.zeros(len(me.loops) * 2, np.float32); me.uv_layers['atlas'].data.foreach_get('uv', uv); uv = uv.reshape(-1, 2)
        a, b, c = co[tv[:, 0]], co[tv[:, 1]], co[tv[:, 2]]; cr = np.cross(b - a, c - a); ar = np.linalg.norm(cr, axis=1) / 2
        r = np.random.default_rng(seed); N = 60000
        f = r.choice(F, N, p=ar / ar.sum()); u_, v_ = r.random(N), r.random(N); fl = u_ + v_ > 1; u_[fl], v_[fl] = 1 - u_[fl], 1 - v_[fl]
        self.sp = a[f] + (b[f] - a[f]) * u_[:, None] + (c[f] - a[f]) * v_[:, None]
        self.sn = cr[f] / np.maximum(np.linalg.norm(cr[f], axis=1, keepdims=True), 1e-12)
        su = uv[tl[f, 0]] + (uv[tl[f, 1]] - uv[tl[f, 0]]) * u_[:, None] + (uv[tl[f, 2]] - uv[tl[f, 0]]) * v_[:, None]
        H, W = mmap.shape[:2]; px = np.clip((su[:, 0] * W).astype(int), 0, W - 1); py = np.clip(((1 - su[:, 1]) * H).astype(int), 0, H - 1)
        self.ao = mmap[py, px, 0]; self.cv = mmap[py, px, 1] - .5
        self.lo = Vector(co.min(0).tolist()); self.hi = Vector(co.max(0).tolist()); self.L = (self.hi - self.lo).x
        self.placed = []  # (point, radius)

    def mirror_p(self, p): return p - 2 * (p - self.c).dot(self.m) * self.m
    def mirror_v(self, v): return v - 2 * v.dot(self.m) * self.m

    def nearest(self, p, maxd=.01):
        h = self.T.find_nearest(p, maxd)
        if h[0] is None: return None, None
        return Vector(h[0]), Vector(h[1]).normalized()

    def flat(self, p, n, t, b, w, h, cos=.8):
        """the ground under a w x h footprint is flat enough (each corner's surface normal close to n, and close to the plane)"""
        for cu, cv in ((1, 1), (1, -1), (-1, 1), (-1, -1), (0, 0)):
            o = p + t * cu * w / 2 + b * cv * h / 2
            q = self.T.ray_cast(o + n * .02, -n, .04)
            if q[0] is None: return False
            qn = Vector(q[1]).normalized(); qn = qn if qn.dot(n) > 0 else -qn
            if qn.dot(n) < cos: return False
        return True

    def free(self, p, r, k=1.0):
        return all((q - p).length > (r + rq) * k for q, rq in self.placed)

    def pairs(self, rng, count, accept, rad, k=1.0, tries=40, centre_ok=True):
        """yield up to count placements: (p, n, mirrored) where mirrored is (p2, n2) on the other side, or None for a centreline single.
        accept(i) filters by sample index (normal, AO, curvature, position)."""
        made = 0; N = len(self.sp); t = 0
        while made < count and t < count * tries:
            t += 1; i = int(rng.integers(N))
            if not accept(i): continue
            p = Vector(self.sp[i].tolist()); n = Vector(self.sn[i].tolist()); r = rad(rng) if callable(rad) else rad
            side = (p - self.c).dot(self.m)
            if abs(side) < r * .9:  # straddles the symmetry plane: one centred part
                if not centre_ok: continue
                p = p - side * self.m; q, qn = self.nearest(p, .02)
                if q is None or not self.free(q, r, k): continue
                qn = qn if qn.dot(n) > 0 else -qn; qn = (qn - qn.dot(self.m) * self.m).normalized()
                self.placed.append((q, r)); made += 1; yield q, qn, None, r; continue
            asym = getattr(self, 'asym', False)
            if side < 0 and not asym: continue  # pairs are seeded from one side only
            p2, n2 = self.nearest(self.mirror_p(p), getattr(self, 'snap', .006))
            ok = p2 is not None
            if ok:
                n2 = n2 if n2.dot(self.mirror_v(n)) > 0 else -n2; ok = n2.dot(self.mirror_v(n)) >= .85
            if not ok:
                if asym and self.free(p, r, k):  # organic hulls (Chorus) are not exactly symmetric: grow a single where the mirror misses
                    self.placed.append((p, r)); made += 1; yield p, n, None, r
                continue
            if side < 0: continue
            if not (self.free(p, r, k) and self.free(p2, r, k)): continue
            self.placed += [(p, r), (p2, r)]; made += 1; yield p, n, (p2, n2), r


def frame_for(n, along=Vector((1, 0, 0))):
    return detail_lib.frame(n, along)


def mirrored_frame(H, n2, t1):
    """frame on the mirror side whose t is the mirror of t1 (so a shape mirrors exactly: (u, v) maps to (u, -v))"""
    t = H.mirror_v(t1); t = (t - n2 * t.dot(n2)).normalized(); b = n2.cross(t); return t, b, n2


# ---------------------------------------------------------------------------------------------------------------------------------------
# building blocks (all placed in a local frame t, b, n at p; each side of a pair gets its own frame so the part follows its own surface)
def plate(H, S, name, p, n, t, b, pts, th, lift, col, props, dress=0, r=None, flip=False):
    if flip: pts = [(u, -v) for u, v in reversed(pts)]
    edge = detail_lib.conform_plate(S, name, p, n, t, b, pts, lift + th, th, seg=.013, keep=.6, clear=0)  # coarser bend grid than the barge: same look, half the triangles
    if edge is None: return False
    flatten(H, bpy.data.objects[name], n, lift + th)
    tag(col, **props)
    if dress and detail_lib.edge_dress(name + 'e', edge, n, dress, r or random.Random(1), p): tag(mul(col, .8), rgh=props.get('rgh', .5) * .9, met=min(1, props.get('met', .3) + .2))
    return True


def flatten(H, o, n, top, k=.7, slack=.0012):
    """AI hull surfaces are bumpy, so a plate bent exactly onto them reads pillowy. Pull the plate's top toward its own best-fit plane, but
    never below its seat on the hull and never more than `slack` above it (so it cannot lift off)."""
    me = o.data; V = np.array([v.co[:] for v in me.vertices])
    if len(V) < 4: return
    c = V.mean(0); u, s_, vt = np.linalg.svd(V - c); nf = vt[2] if np.dot(vt[2], n) > 0 else -vt[2]
    F = V - np.outer((V - c) @ nf, nf) * k
    for i, v in enumerate(F):
        h = H.T.ray_cast(Vector(v) + n * .02, -n, .05)
        if h[0] is None: F[i] = V[i]; continue
        d = (Vector(v) - Vector(h[0])).dot(n)
        if d < top: F[i] = v + nf * (top - d)
        elif d > top + slack: F[i] = v - nf * (d - top - slack)
    me.vertices.foreach_set('co', F.astype(np.float32).ravel()); me.update()


def housing(name, p, n, t, b, w, h, col, lens=None, lens_col=None, dome=False, props=None):
    """sensor housing or light: a mount plate, a raised body, optionally a lens (emissive) or a dome"""
    props = props or {}
    detail_lib.obox(name + 'm', p + n * .0003, t, b, n, (w * 1.35, h * 1.35, .0018), bevel=.0003); tag(mul(col, .7), **props)  # mount plate
    if dome:
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=8, radius=1.0)
        for v in bm.verts: v.co = Vector((v.co.x * w / 2, v.co.y * h / 2, max(v.co.z, -.15) * min(w, h) * .45))
        M = Matrix((t, b, n)).transposed().to_4x4(); bmesh.ops.transform(bm, matrix=M, verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=p + n * .0012)
        hs_lib._obj(name + 'd', bm, 0); tag(lens_col or col, emit=1.0 if lens else 0.0, rgh=.18, met=.1)
        return
    detail_lib.obox(name + 'b', p + n * .0022, t, b, n, (w, h, .0030), bevel=.0005); tag(col, **props)
    if lens:
        detail_lib.obox(name + 'l', p + n * .0036, t, b, n, (w * .55, h * .5, .0008), bevel=0); tag(lens_col, emit=1.0, rgh=.15, met=0)


def vent(name, p, n, t, b, w, h, col, dark):
    detail_lib.obox(name, p + n * .0006, t, b, n, (w, h, .0016), bevel=.0003); tag(col, rgh=.55, met=.5)
    k = max(2, int(w / .0035))
    for i in range(k): detail_lib.obox(f'{name}s{i}', p + n * .0015 + t * (-w / 2 + w / (k + 1) * (i + 1)), t, b, n, (.0012, h * .8, .0010), bevel=0)
    tag(dark, rgh=.7, met=.4)


def surface_walk(H, p, d, step, nstep, wobble=0., rng=None, plane=None):
    """points along the hull surface from p heading d; plane (normal) keeps the walk in a plane (ribs); stops where the surface turns away"""
    pts = [(p.copy(), None)]; cur = p.copy(); dd = d.copy(); q0, n0 = H.nearest(cur, .02)
    if q0 is None: return []
    pts = [(q0, n0)]; cur = q0; n = n0
    for _ in range(nstep):
        dd = (dd - n * dd.dot(n))
        if plane is not None: dd = dd - plane * dd.dot(plane)
        if dd.length < 1e-6: break
        dd.normalize()
        if wobble and rng is not None: dd = (dd + n.cross(dd) * rng.normal(0, wobble)).normalized()
        q, qn = H.nearest(cur + dd * step, step * 2)
        if q is None: break
        qn = qn if qn.dot(n) > 0 else -qn
        if qn.dot(n) < .55: break  # a sharp turn: stop rather than wrap over an edge
        pts.append((q, qn)); cur, n = q, qn
    return pts


def tube_path(name, pts, r0, r1, lift, seg=8):
    """one tapered tube mesh along surface points (veins, ridges, conduits)"""
    if len(pts) < 3: return None
    bm = bmesh.new(); rings = []; N = len(pts)
    for k, (q, n) in enumerate(pts):
        a = pts[min(k + 1, N - 1)][0] - pts[max(k - 1, 0)][0]
        if a.length < 1e-7: continue
        a.normalize(); s = n - a * n.dot(a)
        if s.length < 1e-6: continue
        s.normalize(); w = a.cross(s); r = r0 + (r1 - r0) * k / (N - 1); c = q + s * (lift + r * .35)
        rings.append([bm.verts.new(c + (s * math.cos(j * 2 * math.pi / seg) + w * math.sin(j * 2 * math.pi / seg)) * r * (1 if math.cos(j * 2 * math.pi / seg) > 0 else .55)) for j in range(seg)])
    if len(rings) < 3: bm.free(); return None
    for A, B in zip(rings, rings[1:]):
        for j in range(seg): bm.faces.new((A[j], A[(j + 1) % seg], B[(j + 1) % seg], B[j]))
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1]); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return hs_lib._obj(name, bm, 0)


def ribbon_path(name, pts, w, th, lift):
    """a flat strip laid on the surface (filigree, rib bands): width w across, thickness th above the surface"""
    if len(pts) < 2: return None
    bm = bmesh.new(); rows = []; N = len(pts)
    for k, (q, n) in enumerate(pts):
        a = pts[min(k + 1, N - 1)][0] - pts[max(k - 1, 0)][0]
        if a.length < 1e-7: continue
        a = (a - n * a.dot(n)).normalized(); s = n.cross(a); base = q + n * lift
        rows.append([bm.verts.new(base - s * w / 2 - n * .0006), bm.verts.new(base + s * w / 2 - n * .0006), bm.verts.new(base + s * w * .42 + n * th), bm.verts.new(base - s * w * .42 + n * th)])
    if len(rows) < 2: bm.free(); return None
    for A, B in zip(rows, rows[1:]):
        for j in range(4): bm.faces.new((A[j], A[(j + 1) % 4], B[(j + 1) % 4], B[j]))
    bm.faces.new(list(reversed(rows[0]))); bm.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return hs_lib._obj(name, bm, 0)


def torus(name, p, n, R, r, seg=10, ring=6):
    t, b, n = frame_for(n); bm = bmesh.new(); vs = []
    for i in range(seg):
        a = i * 2 * math.pi / seg; d = t * math.cos(a) + b * math.sin(a); row = []
        for j in range(ring):
            c = j * 2 * math.pi / ring; row.append(bm.verts.new(p + d * (R + r * math.cos(c)) + n * r * math.sin(c)))
        vs.append(row)
    for i in range(seg):
        for j in range(ring): bm.faces.new((vs[i][j], vs[(i + 1) % seg][j], vs[(i + 1) % seg][(j + 1) % ring], vs[i][(j + 1) % ring]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return hs_lib._obj(name, bm, 0)


def blister(name, p, n, rx, ry, hgt, seg=14, vseg=8):
    t, b, n = frame_for(n); bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=vseg, radius=1.0)
    for v in bm.verts: v.co = Vector((v.co.x * rx, v.co.y * ry, v.co.z * hgt if v.co.z > 0 else v.co.z * hgt * .3))
    M = Matrix((t, b, n)).transposed().to_4x4(); bmesh.ops.transform(bm, matrix=M, verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=p)
    return hs_lib._obj(name, bm, 0)


# ---------------------------------------------------------------------------------------------------------------------------------------
def side_rows(H, S, rows, step=.010):
    """conduit runs along the flanks for the long hulls (Voidsworn, Hegemony): ray casts across the symmetry plane at fixed heights,
    split where the hull turns away or a part is in the way. Returns runs of (point, normal) on the +m side and their mirror runs."""
    runs = []
    for zf in rows:
        z = H.lo.z + (H.hi.z - H.lo.z) * zf; run = []
        x = H.lo.x + .04
        while x < H.hi.x - .06:
            o = Vector((x, 0, z)) + H.m * 1.0; h = H.T.ray_cast(o, -H.m, 1.0)
            ok = False
            if h[0] is not None:
                q = Vector(h[0]); qn = Vector(h[1]).normalized(); qn = qn if qn.dot(H.m) > 0 else -qn
                if qn.dot(H.m) > .7 and H.free(q, .004, 1.0): ok = True; run.append((q, qn))
            if not ok:
                if len(run) > 5: runs.append(run)
                run = []
            x += step
        if len(run) > 5: runs.append(run)
    return runs


def dress_armour(H, S, fac, seed, P):
    """Voidsworn and Hegemony: armour panelling. P: palette dict(base, dark, trim, lens). Voidsworn: thick riveted and welded plates, heavy
    vents and conduit; Hegemony: thin crisp panels, few rivets, clean housings, more recessed lights."""
    rng = np.random.default_rng(seed); r = random.Random(seed); heg = fac == 'hegemony'
    base, dark, trim, lens = P['base'], P['dark'], P['trim'], P['lens']
    plate_props = dict(rgh=.46 if heg else .55, met=.16 if heg else .36)
    sizes = [(.45, (.030, .060), (.018, .034)), (.40, (.016, .030), (.010, .020)), (.15, (.010, .016), (.007, .012))]
    kinds = (('rect', .55), ('chamfer', .3), ('trap', .15)) if heg else (('rect', .4), ('chamfer', .4), ('trap', .2))
    open_ok = lambda i: H.ao[i] > .45 and abs(H.cv[i]) < .12  # open plating: not in a cavity, not on a ridge
    n_pl = 0
    # conduit runs along the flanks (Voidsworn heavier), with brackets and junction boxes; mirrored run by run
    nrun = 0
    for run in side_rows(H, S, (.38, .55) if not heg else (.45,)):
        for s_, rr in enumerate((run, None)):
            if rr is None:
                rr = []
                for q, qn in run:
                    q2, n2 = H.nearest(H.mirror_p(q), .006)
                    if q2 is None: break
                    rr.append((q2, n2 if n2.dot(H.mirror_v(qn)) > 0 else -n2))
                if len(rr) != len(run): continue
            pr = .0016 if heg else .0021
            tube_path(f'cond{nrun}{"ab"[s_]}', rr, pr, pr, pr * .6, seg=8); tag(mul(dark, 1.8), rgh=.45, met=.7)
            H.placed += [(q, .005) for q, _ in rr[::2]]
            for k in range(0, len(rr), 5):
                q, qn = rr[k]; t, b, n1 = frame_for(qn); detail_lib.obox(f'cbr{nrun}{"ab"[s_]}{k}', q + qn * .0016, t, b, n1, (.003, .0045, .0034), bevel=0)
            for q, qn in (rr[0], rr[-1]):
                t, b, n1 = frame_for(qn); detail_lib.obox(f'cjb{nrun}{"ab"[s_]}{id(q) % 997}', q + qn * .0025, t, b, n1, (.008, .007, .005), bevel=.0006)
            tag(mul(base, .8), rgh=.5, met=.5)
        nrun += 1
    # fittings on flat ground: vents, sensor housings, equipment pods, recessed running lights
    fit = 0
    def fittings(count, accept, kind):
        nonlocal fit
        for p, n, mir, rad in H.pairs(rng, count, accept, .010, k=1.1):
            t, b, n1 = frame_for(n); w, h = r.uniform(.010, .018), r.uniform(.007, .012)
            if not H.flat(p, n1, t, b, w * 1.4, h * 1.4): continue
            sides = [(p, n1, t, b)]
            if mir:
                t2, b2, n2 = mirrored_frame(H, mir[1], t)
                if not H.flat(mir[0], n2, t2, b2, w * 1.4, h * 1.4): continue
                sides.append((mir[0], n2, t2, b2))
            for s_, (q, nn, tt, bb) in enumerate(sides):
                nm = f'{kind}{fit}{"ab"[s_]}'
                if kind == 'vent': vent(nm, q, nn, tt, bb, w, h, mul(dark, 1.6), mul(dark, .5))
                elif kind == 'sensor': housing(nm, q, nn, tt, bb, w * .8, w * .8, mul(base, .9), lens=False, dome=True, lens_col=mul(dark, 1.3), props=plate_props)
                elif kind == 'pod': housing(nm, q, nn, tt, bb, w * 1.3, h, mul(base, .95), props=plate_props)
                elif kind == 'light': housing(nm, q, nn, tt, bb, w * .45, h * .45, mul(dark, 1.5), lens=True, lens_col=lens, props=plate_props)
            fit += 1
    side = lambda i: abs(Vector(H.sn[i].tolist()).dot(H.m)) > .6
    top = lambda i: H.sn[i][2] > .7
    below = lambda i: H.sn[i][2] < -.7
    fittings(26 if not heg else 16, lambda i: side(i) and open_ok(i), 'vent')
    fittings(12, lambda i: top(i) and open_ok(i), 'vent')
    fittings(10 if not heg else 14, lambda i: top(i) and H.ao[i] > .6, 'sensor')
    fittings(10, lambda i: below(i) and open_ok(i), 'pod')
    fittings(8 if not heg else 14, lambda i: side(i) and H.ao[i] > .5, 'light')
    for p, n, mir, rad in H.pairs(rng, 420 if not heg else 380, open_ok, lambda g: g.uniform(.012, .030), k=.9):
        u = r.uniform(0, 1); acc = 0
        for wgt, wr, hr in sizes:
            acc += wgt
            if u <= acc: break
        w, h = r.uniform(*wr), r.uniform(*hr); w, h = min(w, rad * 2.2), min(h, rad * 1.6)
        kw = r.uniform(0, 1); acc = 0
        for kind, kp in kinds:
            acc += kp
            if kw <= acc: break
        pts = detail_lib.outline(kind, w, h, r); th = (.0011 if heg else .0018) * r.uniform(.8, 1.25)
        col = mul(base, r.uniform(.86, 1.10) if heg else r.uniform(.80, 1.15))
        if r.random() < (.06 if heg else .10): col = mul(dark, 1.4)
        dress = (0 if heg else (r.choice((1, 1, 0, 2)) if w > .028 else r.choice((0, 1))))  # rivet rows only on the big Voidsworn plates (rivets are costly geometry)
        t, b, n1 = frame_for(n); rot = math.radians(r.uniform(-2, 2)); R = Matrix.Rotation(rot, 3, n1); t, b = R @ t, R @ b
        rs = r.random()
        if not plate(H, S, f'pl{n_pl}a', p, n1, t, b, pts, th, -.0004, col, plate_props, dress, random.Random(rs)): continue
        if mir:
            t2, b2, n2 = mirrored_frame(H, mir[1], t); plate(H, S, f'pl{n_pl}b', mir[0], n2, t2, b2, pts, th, -.0004, col, plate_props, dress, random.Random(rs), flip=True)
        n_pl += 1
    # running lights at the extremities, matched: widest point amidships (both sides), bow tip, stern top
    lights(H, rng, lens, mul(dark, 1.5), plate_props)
    print(f'dress {fac}: {n_pl} plate pairs, {fit} fitting pairs, {nrun} conduit runs')


def lights(H, rng, lens, body, props, n_pairs=3):
    """recessed running lights at hard points: the widest port and starboard points at a few stations (always a port/starboard pair,
    whatever the hull's mirror plane is)"""
    made = 0; Yv = Vector((0, 1, 0))
    for xf in np.linspace(.2, .8, n_pairs):
        x = H.lo.x + H.L * xf; got = []
        for sgn in (1, -1):
            best = None
            for zf in np.linspace(.3, .7, 9):
                z = H.lo.z + (H.hi.z - H.lo.z) * zf; h = H.T.ray_cast(Vector((x, sgn * 1.0, z)), -sgn * Yv, 2.0)
                if h[0] is None: continue
                q = Vector(h[0]); d = q.y * sgn
                if best is None or d > best[0]: best = (d, q, Vector(h[1]).normalized())
            if best is None: break
            qn = best[2] if best[2].y * sgn > 0 else -best[2]; got.append((best[1], qn))
        if len(got) != 2: continue
        (q, qn), (q2, n2) = got; t, b, n1 = frame_for(qn); housing(f'rl{made}a', q, n1, t, b, .006, .004, body, lens=True, lens_col=lens, props=props)
        t2 = Vector((t.x, -t.y, t.z)); t2 = (t2 - n2 * t2.dot(n2)).normalized(); b2 = n2.cross(t2)
        housing(f'rl{made}b', q2, n2, t2, b2, .006, .004, body, lens=True, lens_col=lens, props=props)
        made += 1
    return made


def dress_chorus(H, S, seed, P):
    """bio-organic: ridges (raised welts), veins (thin branching tubes, some glowing), pores (rimmed craters in clusters), glowing sacs.
    Mirrored across the body's symmetry plane, as a living thing is."""
    rng = np.random.default_rng(seed); flesh, dark, glow = P['base'], P['dark'], P['lens']
    n_r = n_v = n_p = n_s = 0
    body = lambda i: H.ao[i] > .5
    def walk_pair(p, n, mir, step, nstep, wob, rr):
        d0 = Vector(rng.normal(0, 1, 3).tolist()); d0 = (d0 - n * d0.dot(n)).normalized()
        st = int(rng.integers(1 << 30))
        a = surface_walk(H, p, d0, step, nstep, wob, np.random.default_rng(st))
        if mir is None: return [a]
        # the mirror walk is the mirror of the first one, re-snapped onto the other side's surface
        b = []
        for q, qn in a:
            q2, n2 = H.nearest(H.mirror_p(q), .008)
            if q2 is None: break
            b.append((q2, n2 if n2.dot(H.mirror_v(qn)) > 0 else -n2))
        return [a, b] if len(b) == len(a) else [a]
    for p, n, mir, rad in H.pairs(rng, 46, body, .03, k=.7):  # ridges: thick, low, short
        for s_, path in enumerate(walk_pair(p, n, mir, .007, int(rng.integers(7, 16)), .25, rng)):
            if tube_path(f'ridge{n_r}{"ab"[s_]}', path, .0055, .0020, -.0030, seg=10): tag(mul(flesh, 1.15), rgh=.45, met=.02)
        n_r += 1
    for p, n, mir, rad in H.pairs(rng, 90, body, .02, k=.4):  # veins: thin, long, wandering; a third carry bile light
        lit = rng.random() < .33
        for s_, path in enumerate(walk_pair(p, n, mir, .006, int(rng.integers(12, 30)), .45, rng)):
            if tube_path(f'vein{n_v}{"ab"[s_]}', path, .0019, .0006, -.0009, seg=6):
                tag(mul(glow, .5) if lit else mul(dark, 1.8), emit=.35 if lit else 0, rgh=.3, met=0)
        n_v += 1
    for p, n, mir, rad in H.pairs(rng, 44, lambda i: H.ao[i] > .45, .012, k=1.0):  # pore clusters
        k = int(rng.integers(3, 6))
        for s_, (q0, n0) in enumerate([(p, n)] + ([mir] if mir else [])):
            t, b, nn = frame_for(n0)
            rr_ = np.random.default_rng(n_p * 7 + 1)
            for j in range(k):
                o = q0 + t * rr_.uniform(-.010, .010) + b * rr_.uniform(-.010, .010) * (1 if s_ == 0 else -1)
                q, qn = H.nearest(o, .01)
                if q is None: continue
                qn = qn if qn.dot(n0) > 0 else -qn; R = rr_.uniform(.0018, .0038)
                torus(f'pore{n_p}{"ab"[s_]}{j}', q - qn * .0004, qn, R, R * .45, seg=8, ring=4)
                blister(f'porec{n_p}{"ab"[s_]}{j}', q - qn * .0012, qn, R * .9, R * .9, .0006, seg=8, vseg=5)
            tag(mul(flesh, .8), rgh=.4, met=0)
        n_p += 1
    for p, n, mir, rad in H.pairs(rng, 22, lambda i: H.ao[i] > .55 and H.cv[i] > -.02, lambda g: g.uniform(.008, .016), k=1.6):  # glowing sacs
        for s_, (q, qn) in enumerate([(p, n)] + ([mir] if mir else [])):
            torus(f'sacr{n_s}{"ab"[s_]}', q - qn * .0005, qn, rad * .95, rad * .28, seg=14, ring=6); tag(mul(flesh, .7), rgh=.45, met=0)
            blister(f'sac{n_s}{"ab"[s_]}', q - qn * .0008, qn, rad * .85, rad * .85, rad * .55); tag(glow, emit=1.0, rgh=.15, met=0)
        n_s += 1
    print(f'dress chorus: {n_r} ridge pairs, {n_v} vein pairs, {n_p} pore clusters, {n_s} sacs')


def dress_ithar(H, S, seed, P):
    """pearl ceramic with gold filigree inlay (flat raised ribbons, flowing curves), jade lenses, smooth inset seams (in the normal map)"""
    rng = np.random.default_rng(seed); pearl, gold, jade, dark = P['base'], P['trim'], P['lens'], P['dark']
    n_f = n_l = 0
    for p, n, mir, rad in H.pairs(rng, 110, lambda i: H.ao[i] > .55, .035, k=.55):
        d0 = Vector((1, 0, 0)); d0 = (d0 - n * d0.dot(n))
        if d0.length < .2: d0 = Vector(rng.normal(0, 1, 3).tolist()); d0 = d0 - n * d0.dot(n)
        d0.normalize(); d0 = (d0 + n.cross(d0) * rng.uniform(-.8, .8)).normalized()
        a = surface_walk(H, p, d0, .006, int(rng.integers(10, 26)), .18, np.random.default_rng(int(rng.integers(1 << 30))))
        paths = [a]
        if mir:
            b = []
            for q, qn in a:
                q2, n2 = H.nearest(H.mirror_p(q), .008)
                if q2 is None: break
                b.append((q2, n2 if n2.dot(H.mirror_v(qn)) > 0 else -n2))
            if len(b) == len(a): paths.append(b)
        for s_, pth in enumerate(paths):
            if ribbon_path(f'fil{n_f}{"ab"[s_]}', pth, .0026, .0007, -.0002): tag(gold, rgh=.28, met=.95)
        n_f += 1
    for p, n, mir, rad in H.pairs(rng, 16, lambda i: H.ao[i] > .6 and abs(H.cv[i]) < .06, .008, k=2.0):
        for s_, (q, qn) in enumerate([(p, n)] + ([mir] if mir else [])):
            t, b, nn = frame_for(qn)
            torus(f'lensr{n_l}{"ab"[s_]}', q - qn * .0003, qn, .0042, .0011, seg=14, ring=6); tag(gold, rgh=.28, met=.95)
            blister(f'lens{n_l}{"ab"[s_]}', q - qn * .0006, qn, .0036, .0036, .0022); tag(jade, emit=1.0, rgh=.1, met=0)
        n_l += 1
    lights(H, rng, jade, mul(gold, .8), dict(rgh=.3, met=.9), n_pairs=2)
    print(f'dress ithar: {n_f} filigree pairs, {n_l} lens pairs')


def dress_deathless(H, S, seed, P, ring_axis=None):
    """carved ossuary: rib bands in parallel sets (the ribcage), carved glyph panels (sunk, with a raised border), vertebra knobs, green
    slits between ribs"""
    rng = np.random.default_rng(seed); r = random.Random(seed); slate, bone, green, dark = P['base'], P['trim'], P['lens'], P['dark']
    ax = Vector(ring_axis or (0, 0, 1)).normalized()
    n_r = n_g = n_k = 0
    open_ok = lambda i: H.ao[i] > .5 and abs(H.cv[i]) < .1
    for p, n, mir, rad in H.pairs(rng, 34, open_ok, .035, k=.8):
        # rib plane: across the structure. Around the ring's axis the structure runs tangentially, so ribs lie in the plane normal to that
        rad_v = (p - H.c) - ax * (p - H.c).dot(ax)
        tang = ax.cross(rad_v).normalized() if rad_v.length > .05 else Vector((1, 0, 0))
        sets = []
        for j in range(int(rng.integers(3, 6))):
            q = p + tang * (j - 2) * .011; q, qn = H.nearest(q, .02)
            if q is None: continue
            d = qn.cross(tang).normalized(); L = int(rng.integers(5, 10))
            a = surface_walk(H, q, d, .005, L, plane=tang); b = surface_walk(H, q, -d, .005, L, plane=tang)
            pth = list(reversed(b))[:-1] + a if len(a) > 1 and len(b) > 1 else a
            sets.append(pth)
        paths = [(pth, 'a') for pth in sets]
        if mir:
            for pth in sets:
                mm = []
                for q, qn in pth:
                    q2, n2 = H.nearest(H.mirror_p(q), .008)
                    if q2 is None: break
                    mm.append((q2, n2 if n2.dot(H.mirror_v(qn)) > 0 else -n2))
                if len(mm) == len(pth): paths.append((mm, 'b'))
        for k, (pth, s_) in enumerate(paths):
            if ribbon_path(f'rib{n_r}{s_}{k}', pth, .0055, .0024, -.0004): tag(bone, rgh=.62, met=.05)
        # a green slit between the first two ribs of the set
        if len(sets) >= 2 and len(sets[0]) > 3:
            mid = [((a_[0] + b_[0]) / 2, a_[1]) for a_, b_ in zip(sets[0], sets[1])][1:-1]
            if len(mid) > 2 and ribbon_path(f'slit{n_r}a', mid, .0018, .0003, -.0005): tag(green, emit=1.0, rgh=.2, met=0)
        n_r += 1
    for p, n, mir, rad in H.pairs(rng, 60, open_ok, lambda g: g.uniform(.014, .024), k=1.0):  # carved glyph panels
        t, b, n1 = frame_for(n); w, h = rad * 1.4, rad * .9
        pts = detail_lib.outline('chamfer', w, h, r); col = mul(slate, r.uniform(.6, .8))
        if not plate(H, S, f'gly{n_g}a', p, n1, t, b, pts, .0012, -.0009, col, dict(rgh=.7, met=.4), 0): continue
        borders = [(p, n1, t, b, False)]
        if mir:
            t2, b2, n2 = mirrored_frame(H, mir[1], t)
            if plate(H, S, f'gly{n_g}b', mir[0], n2, t2, b2, pts, .0012, -.0009, col, dict(rgh=.7, met=.4), 0): borders.append((mir[0], n2, t2, b2, True))
        for s_, (q, nn, tt, bb, fl) in enumerate(borders):  # carved glyph strokes: short raised bars in a fixed pattern per panel
            rr = random.Random(n_g * 31)
            for e in range(5):
                u = rr.uniform(-w * .35, w * .35); v = rr.uniform(-h * .3, h * .3) * (-1 if fl else 1); horiz = rr.random() < .5
                detail_lib.obox(f'glys{n_g}{s_}{e}', q + tt * u + bb * v + nn * .0004, tt, bb, nn, ((w * .3, .0012, .0010) if horiz else (.0012, h * .35, .0010)), bevel=0)
            tag(mul(bone, .7), rgh=.6, met=.05)
        n_g += 1
    for p, n, mir, rad in H.pairs(rng, 30, lambda i: H.ao[i] > .55, .009, k=1.4):  # vertebra knobs
        for s_, (q, qn) in enumerate([(p, n)] + ([mir] if mir else [])):
            t, b, nn = frame_for(qn)
            detail_lib.obox(f'knobm{n_k}{"ab"[s_]}', q + nn * .0004, t, b, nn, (.012, .009, .0016), bevel=.0004); tag(mul(slate, .8), rgh=.65, met=.45)
            blister(f'knob{n_k}{"ab"[s_]}', q + nn * .0008, qn, .0045, .0035, .0040); tag(bone, rgh=.6, met=.05)
        n_k += 1
    lights(H, rng, green, mul(dark, 1.5), dict(rgh=.5, met=.5), n_pairs=3)
    print(f'dress deathless: {n_r} rib sets, {n_g} glyph panels, {n_k} knobs')


def build_spires(fingers, style, col, dark, props):
    """the hand-built replacements for the AI's melted fingers (spires.py): a mount plate over the cut, then a crisp tapered spire.
    style 'gothic' (Voidsworn pinnacles: octagonal, banded, pointed, with a finial) or 'mast' (Hegemony antenna masts: slimmer taper,
    collars, a sensor bulb on top)"""
    n = 0; done = set()
    for f in fingers:
        x, y = float(f['c'][0]), float(f['c'][1]); z0, z1, r = f['z0'], f['z1'], f['r']; h = z1 - z0
        if f['group'] not in done:  # one mount plate per cluster, over the whole cut
            done.add(f['group']); lo, hi = f['plate_lo'], f['plate_hi']
            if abs(lo[1] + hi[1]) < .006: e = max(abs(lo[1]), abs(hi[1])); lo, hi = (lo[0], -e), (hi[0], e)  # centreline mounts stay symmetric
            hs_lib.box(f'spm{n}', ((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, z0 - .0025), (max(hi[0] - lo[0], .006), max(hi[1] - lo[1], .006), .006), bevel=.0006); tag(mul(col, .8), **props)
        if style == 'gothic':
            hs_lib.cyl(f'spi{n}', (x, y, z0 + h * .5), r, h, axis='Z', seg=8, r2=r * .12, bevel=0); tag(col, **props)
            for k, fz in enumerate((.18, .46)):
                hs_lib.cyl(f'spb{n}{k}', (x, y, z0 + h * fz), r * (1 - fz * .8) + .0012, .0025, axis='Z', seg=8, bevel=0)
            tag(mul(dark, 1.6), rgh=.45, met=.6)
            b = bmesh.new(); bmesh.ops.create_uvsphere(b, u_segments=8, v_segments=6, radius=max(.0012, r * .22)); bmesh.ops.translate(b, verts=b.verts, vec=(x, y, z1 - h * .02))
            hs_lib._obj(f'spf{n}', b, 0); tag(mul(dark, 1.6), rgh=.45, met=.6)
        else:
            hs_lib.cyl(f'spi{n}', (x, y, z0 + h * .5), r * .8, h, axis='Z', seg=10, r2=r * .32, bevel=0); tag(col, **props)
            for k, fz in enumerate((.25, .55, .8)):
                hs_lib.cyl(f'spb{n}{k}', (x, y, z0 + h * fz), r * .8 * (1 - fz * .6) + .0011, .0018, axis='Z', seg=10, bevel=0)
            tag(mul(dark, 1.3), rgh=.4, met=.6)
            b = bmesh.new(); bmesh.ops.create_uvsphere(b, u_segments=10, v_segments=6, radius=max(.0013, r * .36)); bmesh.ops.translate(b, verts=b.verts, vec=(x, y, z1))
            hs_lib._obj(f'spf{n}', b, 0); tag(mul(col, .95), rgh=.3, met=.3)
        n += 1
    print(f'spires rebuilt by hand: {n}')
    return n
