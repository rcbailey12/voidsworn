# Interior Kit V2 (issue 1743, R416 Layer 3; RULEBOOK 5.4). Runs inside Blender, from Kit.finish(), after the hull, the parts and
# every inside the sheet placed are built.
#
# Every sheet's insides (K.room, K.deck, K.bulkhead, K.organ_room, K.hoop, K.septum and a sheet's own in_deck_ / in_bh_ objects)
# stay what they were: the room's enclosure, the deck slab, the bulkhead plate. This pass adds the modeled interior around them,
# read from what the sheet built, so every sheet upgrades on its next build without a line changed:
#   rooms by kind     core/ecore reactor vessel with containment rings, cooling headers and core slits; engroom turbine drums,
#                     flanges, manifolds and stern feeds; magazine tube racks in retaining frames; hrack/machinery equipment rack
#                     rows and conduit risers; hangar gantry rails, roof truss ribs and wall ribs; every other kind (bridge, hcorr,
#                     crew, darkdeck, archive, hold, gallery) ribbed bays with consoles, archive stacks or crates along the walls;
#   decks             longitudinal and transverse under-deck girders and edge flanges, following the deck's own footprint;
#   bulkheads         a hull-hugging collar, two stanchions, a cross beam and a framed pass-through arch on both faces;
#   the Chorus        vascular ridges and sac lobes on organs, glands, guts and vats; knobbed bone cross-struts between hoops;
#                     fibrous ridges along each septum (no metal anywhere: factions.md, the Chorus Never list);
#   the Eclipse       trusses, never ribs (factions.md, the Eclipse Never list): its bays take truss braces and archive stacks.
# The Glasswrights' insides are modeled in their own kit (tools/blender/kits/ithar/hull.py insides(): prism nodes on the frames,
# collared lens rings on the light cores); this pass only gives them UVs.
#
# A piece furnishing a room is dropped whole unless it lies inside the room's own box (the sheet placed the room; what is inside
# it is hidden wherever the room is). Every other piece (girders under a deck, a bulkhead's frame, Chorus ridges, lobes and
# struts) is dropped whole when any of its points sits outside the hull or closer to the hull's skin than MARGIN (R99,
# surface_check.py: no room pixel seen from outside; issue 1291: a room reaching the skin shows through it). Long pieces are cut into short segments, so the game's death cut
# tears them with the plating (R226, fx/test/death_seam_check.gd; a long sliver face sends a liner to the wrong piece).
# Last, every inside object gets box-projected UVs at one texel density (TILE of the ship's length per tile), which the faction's
# shared interior trim maps (tools/blender/kits/shared/interior_trim.py) tile over at paint (stage 5), and each is marked
# interior_kit = 2 (the export records it; check_export.py holds a V2 export to its trim maps).
import math, os, random
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

VERSION = 2
TILE = 0.055          # one trim tile spans this fraction of the ship's length (21-unit H10: 1.16 units)
MARGIN = 0.006        # of the ship's length: the closest a point added outside a room may sit to the hull's skin
SEG = 0.03            # of the ship's length: the longest segment of a long piece (death seam tearing)
CHORUS_ORGANS = ('organ', 'gut', 'gland', 'brood', 'vat', 'ganglion')
THIN_KINDS = ('hemerg',)   # light strips the sheet builds as rooms: nothing to furnish


class Mesh:
    """verts and faces of one added object, with a smooth flag per face"""
    def __init__(self):
        self.V = []; self.F = []; self.S = []

    def add(self, V, F, smooth=False):
        o = len(self.V); self.V += [tuple(v) for v in V]; self.F += [tuple(i + o for i in f) for f in F]; self.S += [smooth] * len(F)

    def extend(self, other):
        o = len(self.V); self.V += other.V; self.F += [tuple(i + o for i in f) for f in other.F]; self.S += other.S


# ------------------------------------------------------------------------------------------------------------ primitives
def box(c, h, seg=None):
    """an axis box at centre c with half extents h, cut into segments along its longest axis (no face longer than seg)"""
    ax = max(range(3), key=lambda i: h[i]); n = 1 if not seg else max(1, int(math.ceil(2 * h[ax] / seg)))
    o1, o2 = [i for i in range(3) if i != ax]
    corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    V = []
    for k in range(n + 1):
        t = -1 + 2 * k / n
        for a, b in corners:
            p = [0, 0, 0]; p[ax] = c[ax] + t * h[ax]; p[o1] = c[o1] + a * h[o1]; p[o2] = c[o2] + b * h[o2]; V.append(p)
    F = []
    for k in range(n):
        for j in range(4):
            a, b = k * 4 + j, k * 4 + (j + 1) % 4
            F.append((a, b, b + 4, a + 4))
    F.append((3, 2, 1, 0)); F.append(tuple(n * 4 + j for j in range(4)))
    return V, F


def tube(p0, p1, r, n=8, seg=None, cap=True, r1=None):
    """a capped cylinder from p0 to p1 (r at p0, r1 at p1), cut into rings no farther apart than seg"""
    p0, p1 = Vector(p0), Vector(p1); d = p1 - p0; L = d.length
    if L < 1e-6:
        return [], []
    ax = d / L; u = ax.orthogonal().normalized(); w = ax.cross(u); r1 = r if r1 is None else r1
    m = 1 if not seg else max(1, int(math.ceil(L / seg)))
    V = []
    for k in range(m + 1):
        t = k / m; p = p0 + d * t; rr = r + (r1 - r) * t
        V += [p + (u * math.cos(2 * math.pi * i / n) + w * math.sin(2 * math.pi * i / n)) * rr for i in range(n)]
    F = [(k * n + i, k * n + (i + 1) % n, (k + 1) * n + (i + 1) % n, (k + 1) * n + i) for k in range(m) for i in range(n)]
    if cap:
        F.append(tuple(range(n))[::-1]); F.append(tuple(range(m * n, (m + 1) * n)))
    return V, F


def ring(c, axis, r, w, t, n=16):
    """a square-section ring (a containment ring, a flange, a lens collar): radius r to r + t, width w along axis"""
    c = Vector(c); ax = Vector(axis).normalized(); u = ax.orthogonal().normalized(); v = ax.cross(u)
    V = []
    for s in (-w / 2, w / 2):
        for rr in (r, r + t):
            V += [c + ax * s + (u * math.cos(2 * math.pi * i / n) + v * math.sin(2 * math.pi * i / n)) * rr for i in range(n)]
    F = []
    for i in range(n):
        j = (i + 1) % n
        F += [(n + i, n + j, 3 * n + j, 3 * n + i), (j, i, 2 * n + i, 2 * n + j), (i, j, n + j, n + i), (3 * n + i, 3 * n + j, 2 * n + j, 2 * n + i)]
    return V, F


def lump(c, radii, seed=0, nu=10, nv=6, amp=0.12):
    """a small lumpy ellipsoid (a sac lobe, a bone knob)"""
    rnd = random.Random(seed); ph = [rnd.uniform(0, 6.3) for _ in range(3)]
    V = [(c[0], c[1], c[2] - radii[2])]
    for j in range(1, nv):
        th = math.pi * j / nv - math.pi / 2
        for i in range(nu):
            a = 2 * math.pi * i / nu
            k = 1 + amp * math.sin(3 * a + ph[0]) * math.cos(2 * th + ph[1]) + amp * 0.5 * math.sin(5 * a + 2 * th + ph[2])
            V.append((c[0] + radii[0] * math.cos(th) * math.cos(a) * k, c[1] + radii[1] * math.cos(th) * math.sin(a) * k, c[2] + radii[2] * math.sin(th) * k))
    V.append((c[0], c[1], c[2] + radii[2]))
    F = [(0, 1 + (i + 1) % nu, 1 + i) for i in range(nu)]
    for j in range(nv - 2):
        for i in range(nu):
            a = 1 + j * nu + i; b = 1 + j * nu + (i + 1) % nu; F.append((a, b, b + nu, a + nu))
    top = len(V) - 1; o = 1 + (nv - 2) * nu
    F += [(o + i, o + (i + 1) % nu, top) for i in range(nu)]
    return V, F


def path_tube(pts, r, n=6):
    """a tube along a polyline (veins, ridges, fibres), capped"""
    pts = [Vector(p) for p in pts]
    V = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(0, i - 1)]).normalized()
        q = d.cross(Vector((0, 0, 1)))
        if q.length < 0.1:
            q = d.cross(Vector((0, 1, 0)))
        q.normalize(); w = d.cross(q).normalized()
        rr = r[i] if isinstance(r, (list, tuple)) else r
        V += [p + (q * math.cos(2 * math.pi * j / n) + w * math.sin(2 * math.pi * j / n)) * rr for j in range(n)]
    F = [(i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j) for i in range(len(pts) - 1) for j in range(n)]
    F += [tuple(range(n))[::-1], tuple(range((len(pts) - 1) * n, len(pts) * n))]
    return V, F


# ------------------------------------------------------------------------------------------------------------ the pass
class Dresser:
    def __init__(self, K, faction):
        self.K = K; self.fac = faction; self.L = K.length
        self.seg = SEG * K.length; self.margin = MARGIN * K.length
        self.kept = 0; self.dropped = 0; self.added = {}; self.why = {}; self.room_box = None
        # the Glasswrights (Ryan, Nov 23): crystal machinery, hexagonal where the others are round, and lit crystals in the
        # leaf colours (their gw_in_ glass zones) where the others have plain caps; rooms placed by kits/ithar/rooms.py
        self.glass = faction == 'ithar'
        self.nr = 6 if self.glass else 16
        self.crys = None
        if self.glass:
            _gw_zones()
        self.tree = self._outer_tree()

    def _outer_tree(self):
        """one BVH over everything that is not an inside (the hull with its shell, the plates, the parts), world space"""
        dg = bpy.context.evaluated_depsgraph_get(); V = []; F = []
        for ob in self.K.coll.all_objects:
            if ob.type != 'MESH' or ob.get('inside'):
                continue
            ev = ob.evaluated_get(dg); me = ev.to_mesh(); mw = ob.matrix_world; o = len(V)
            V += [mw @ v.co for v in me.vertices]; F += [tuple(i + o for i in p.vertices) for p in me.polygons]
            ev.to_mesh_clear()
        return BVHTree.FromPolygons(V, F) if F else None

    def inside_hull(self, p):
        """p sits inside the outer surfaces (a hit straight up, down, port and starboard) and at least MARGIN from them"""
        if self.tree is None:
            return True
        p = Vector(p)
        loc, _n, _i, d = self.tree.find_nearest(p)
        if loc is not None and d < self.margin:
            self.why['skin'] = self.why.get('skin', 0) + 1
            return False
        for dv in ((0, 0, 1), (0, 0, -1), (0, 1, 0), (0, -1, 0)):
            if self.tree.ray_cast(p, Vector(dv))[0] is None:
                self.why['open'] = self.why.get('open', 0) + 1
                return False
        return True

    def piece(self, out, VF, smooth=False):
        """add one piece to out when every point of it (and its middle) is inside the hull and off its skin; a piece built
        inside a room's own box (self.room_box) is held to that box instead: the sheet placed the room, so a piece within it is
        hidden wherever the room is (R99), and a room close under the skin keeps its furniture"""
        V, F = VF
        if not V:
            return False
        if self.room_box is not None:
            lo, hi = self.room_box; e = 1e-5
            if all(lo[i] - e <= v[i] <= hi[i] + e for v in V for i in range(3)):
                out.add(V, F, smooth); self.kept += 1; return True
            self.dropped += 1; self.why['room'] = self.why.get('room', 0) + 1
            return False
        test = list(V)
        if len(V) <= 64:
            c = Vector((sum(v[0] for v in V) / len(V), sum(v[1] for v in V) / len(V), sum(v[2] for v in V) / len(V)))
            test.append(c)
        if all(self.inside_hull(v) for v in test):
            out.add(V, F, smooth); self.kept += 1; return True
        self.dropped += 1
        return False

    def emit(self, src, out, mat):
        if not out.F:
            return None
        name = 'in_v2_%s_%s' % (src.name[3:] if src.name.startswith('in_') else src.name, mat)
        ob = self.K._obj(name, out.V, out.F, mat, inside=True)
        for p, s in zip(ob.data.polygons, out.S):
            p.use_smooth = s
        ob['grp'] = src.get('grp', 'hull'); ob['interior_kit'] = VERSION; ob['dress_of'] = src.name
        self.added[mat] = self.added.get(mat, 0) + len(out.F)
        return ob

    # ---------------------------------------------------------------------------------------------------- rooms
    def room(self, ob, kind):
        try:
            self._room(ob, kind)
        finally:
            self.room_box = None

    def _room(self, ob, kind):
        lo, hi = bounds(ob)
        self.room_box = (lo.copy(), hi.copy())
        dims = hi - lo
        if min(dims) < 0.012 * self.L or kind in THIN_KINDS:
            return
        m = 0.03 * min(dims)        # stay off the room's own walls
        lo = lo + Vector((m, m, m)); hi = hi - Vector((m, m, m))
        frame_mat = 'frame' if self.fac != 'chorus' else 'bonefr'
        mach = Mesh(); furn = Mesh(); glow = Mesh()
        self.crys = {c: Mesh() for c in ('amber', 'violet', 'green')} if self.glass else None
        try:
            self._furnish(ob, kind, lo, hi, frame_mat, mach, furn, glow)
        finally:
            if self.crys:
                for c, m in self.crys.items():
                    self.emit(ob, m, 'gw_in_' + c)
            self.crys = None

    def crystal(self, p, axis, r, h, k):
        """a lit Glasswright crystal (a hexagonal prism with a pointed tip) in the k-th leaf colour; nothing for the others"""
        if not self.crys:
            return
        p = Vector(p); e = Vector(axis).normalized()
        col = ('amber', 'violet', 'green')[k % 3]
        self.piece(self.crys[col], tube(p, p + e * (0.75 * h), r, 6, None, True), False)
        self.piece(self.crys[col], tube(p + e * (0.75 * h), p + e * h, r, 6, None, True, 0.15 * r), False)

    def _furnish(self, ob, kind, lo, hi, frame_mat, mach, furn, glow):
        if kind in ('core', 'ecore'):
            self.reactor(lo, hi, mach, glow)
            made = self.emit(ob, mach, 'machinery'); self.emit(ob, glow, kind)
            if made is not None and glow.F:
                # the core's light now shows through the vessel's slits (and the vessel when it breaks open); the room around it
                # stops glowing all over, which washed the whole compartment out to white in the cutaway
                ob.data.materials[0] = made.data.materials[0]
            return
        if kind == 'engroom':
            self.turbines(lo, hi, mach, furn)
        elif kind == 'magazine':
            self.racks_tubes(lo, hi, furn, mach)
        elif kind in ('hrack', 'machinery'):
            self.equipment(lo, hi, furn, mach)
        elif kind == 'hangar':
            self.hangar(lo, hi, mach)
        else:
            self.bay(lo, hi, kind, furn, mach)
        self.emit(ob, mach, frame_mat); self.emit(ob, furn, kind if kind != 'engroom' else 'machinery')

    def reactor(self, lo, hi, mach, glow):
        dims = hi - lo; c = (lo + hi) / 2
        ax = 0 if dims.x >= dims.z else 2
        o = [i for i in range(3) if i != ax]
        half = min(dims[o[0]], dims[o[1]]) / 2; r = 0.62 * half; Lh = dims[ax] / 2 * 0.9
        a = c.copy(); a[ax] -= Lh; b = c.copy(); b[ax] += Lh
        e = Vector((0, 0, 0)); e[ax] = 1
        ia = a + e * (0.12 * Lh); ib = b - e * (0.12 * Lh)
        self.piece(mach, tube(ia, ib, r, self.nr, self.seg), not self.glass)
        self.piece(mach, tube(a, ia, 0.6 * r, self.nr, None, True, r), not self.glass)    # domed ends (frustums)
        self.piece(mach, tube(ib, b, r, self.nr, None, True, 0.6 * r), not self.glass)
        nr = 4
        for k in range(nr):
            p = ia + (ib - ia) * ((k + 0.5) / nr)
            self.piece(mach, ring(p, e, r, 0.07 * Lh, 0.12 * r, 6 if self.glass else 20))
        u = Vector((0, 0, 0)); u[o[0]] = 1; v = Vector((0, 0, 0)); v[o[1]] = 1
        for k in range(4):                                                              # cooling headers
            ang = math.pi / 4 + k * math.pi / 2; off = (u * math.cos(ang) + v * math.sin(ang)) * (1.28 * r)
            self.piece(mach, tube(ia + off, ib + off, 0.08 * r, 8, self.seg), True)
        for k in range(nr - 1):                                                         # recessed core slits between the rings
            p0 = ia + (ib - ia) * ((k + 0.5) / nr) + e * (0.05 * Lh); p1 = ia + (ib - ia) * ((k + 1.5) / nr) - e * (0.05 * Lh)
            for j in range(4):
                ang = j * math.pi / 2; nrm = u * math.cos(ang) + v * math.sin(ang); tg = nrm.cross(e)
                cc = (p0 + p1) / 2 + nrm * (0.985 * r)
                V = [cc + e * s1 * ((p1 - p0).length / 2) + tg * s2 * 0.07 * r + nrm * s3 * 0.03 * r
                     for s1 in (-1, 1) for s2 in (-1, 1) for s3 in (-1, 1)]
                F = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
                self.piece(glow, (V, F))

    def turbines(self, lo, hi, mach, furn):
        dims = hi - lo; c = (lo + hi) / 2
        two = dims.y > 1.6 * dims.z
        ys = (c.y - dims.y / 4, c.y + dims.y / 4) if two else (c.y,)
        r = 0.42 * min(dims.z, dims.y / len(ys)) * 0.95
        x0 = lo.x + 0.08 * dims.x; x1 = hi.x - 0.18 * dims.x
        for y in ys:
            zc = lo.z + r * 1.05
            self.piece(mach, tube((x0, y, zc), (x1, y, zc), r, self.nr, self.seg), not self.glass)
            for k in range(5):
                x = x0 + (x1 - x0) * (k + 0.5) / 5
                self.piece(mach, ring((x, y, zc), (1, 0, 0), r, 0.04 * dims.x, 0.1 * r, 6 if self.glass else 18))
                if k % 2 == 0:      # Glasswright drive resonators: a lit crystal standing on every other collar
                    self.crystal((x, y, zc + 1.08 * r), (0, 0, 1), 0.18 * r, 0.5 * r, k // 2)
            for s in (-1, 1):                                                           # stern feed conduits to the aft wall
                self.piece(furn, tube((x0, y + s * 0.45 * r, zc), (lo.x, y + s * 0.45 * r, zc), 0.12 * r, 8), True)
        zt = hi.z - 0.08 * dims.z                                                       # the overhead manifold
        for s in (-1, 1):
            self.piece(furn, tube((lo.x, c.y + s * 0.3 * dims.y, zt), (hi.x, c.y + s * 0.3 * dims.y, zt), 0.04 * dims.z, 8, self.seg), True)
        for y in ys:
            for k in range(3):
                x = x0 + (x1 - x0) * (k + 0.5) / 3
                self.piece(furn, tube((x, y, lo.z + 2.05 * r), (x, y, zt), 0.035 * dims.z, 8), True)

    def racks_tubes(self, lo, hi, furn, mach):
        dims = hi - lo; c = (lo + hi) / 2
        r = max(0.01 * self.L, 0.1 * min(dims.y, dims.z))
        ny = max(1, min(8, int(dims.y / (2.6 * r)))); nz = max(1, min(4, int(dims.z / (2.6 * r))))
        r = min(r, dims.y / ny / 2.6, dims.z / nz / 2.6)
        x0 = lo.x + 0.06 * dims.x; x1 = hi.x - 0.06 * dims.x
        for i in range(ny):
            for j in range(nz):
                y = lo.y + dims.y * (i + 0.5) / ny; z = lo.z + dims.z * (j + 0.5) / nz
                self.piece(furn, tube((x0, y, z), (x1, y, z), r, 6 if self.glass else 10, self.seg), not self.glass)
                self.crystal((x1, y, z), (1, 0, 0), 0.6 * r, 0.06 * dims.x, i + j)    # the lens at each rack's fore end
        bar = 0.25 * r
        for k in range(3):                                                              # retaining frames
            x = x0 + (x1 - x0) * k / 2
            for (yc, zc, hy, hz) in ((c.y, lo.z + bar, dims.y / 2, bar), (c.y, hi.z - bar, dims.y / 2, bar),
                                     (lo.y + bar, c.z, bar, dims.z / 2), (hi.y - bar, c.z, bar, dims.z / 2)):
                self.piece(mach, box((x, yc, zc), (bar, hy, hz)))

    def equipment(self, lo, hi, furn, mach):
        dims = hi - lo; c = (lo + hi) / 2
        rnd = random.Random(int(abs(c.x * 1000 + c.y * 37)))
        junky = self.fac == 'hullbreakers'
        aisle = 0.3 * dims.y
        rows = [(lo.y, c.y - aisle / 2), (c.y + aisle / 2, hi.y)] if dims.y > 0.8 * dims.z else [(lo.y, hi.y)]
        n = max(2, min(10, int(dims.x / (0.5 * dims.z + 1e-6))))
        for (ya, yb) in rows:
            for k in range(n):
                xa = lo.x + dims.x * k / n; xb = lo.x + dims.x * (k + 1) / n; gap = 0.06 * (xb - xa)
                h = dims.z * (0.82 if not junky else rnd.uniform(0.45, 0.85))
                d = (yb - ya) * (0.92 if not junky else rnd.uniform(0.6, 0.92))
                yc = ya + d / 2 if ya > c.y - 1e-6 or len(rows) == 1 else yb - d / 2
                self.piece(furn, box(((xa + xb) / 2, yc, lo.z + h / 2), ((xb - xa) / 2 - gap, d / 2, h / 2)))
                # the rack's face: a recessed panel band and a vent block on top
                self.piece(furn, box(((xa + xb) / 2, yc, lo.z + h * 0.55), ((xb - xa) / 2 - 2 * gap, d / 2 + 0.02 * dims.y, 0.08 * h)))
                # Glasswright stored-light racks: a lit crystal cap on each rack
                self.crystal(((xa + xb) / 2, yc, lo.z + h), (0, 0, 1), min(0.2 * (xb - xa), 0.12 * d), 0.14 * dims.z, k)
            for k in range(n + 1):                                                      # conduit risers between racks
                x = lo.x + dims.x * k / n
                y = (ya + yb) / 2
                if lo.x + 0.03 * dims.x < x < hi.x - 0.03 * dims.x:
                    self.piece(mach, tube((x, y, lo.z), (x, y, hi.z), 0.025 * dims.z + 0.002 * self.L, 6), True)

    def hangar(self, lo, hi, mach):
        dims = hi - lo; c = (lo + hi) / 2
        b = 0.05 * min(dims.y, dims.z)
        for s in (-1, 1):                                                               # gantry rails
            self.piece(mach, box((c.x, c.y + s * 0.32 * dims.y, hi.z - b), (dims.x / 2, b, b), self.seg))
        n = max(3, int(dims.x / (0.6 * dims.z)))
        for k in range(n + 1):                                                          # roof truss ribs and wall ribs
            x = lo.x + b + (dims.x - 2 * b) * k / n
            self.piece(mach, box((x, c.y, hi.z - 2.6 * b), (b * 0.7, dims.y / 2, b * 0.7)))
            for s in (-1, 1):
                self.piece(mach, box((x, c.y + s * (dims.y / 2 - b * 0.7), c.z), (b * 0.7, b * 0.7, dims.z / 2)))
        self.piece(mach, box((c.x, c.y, hi.z - 1.6 * b), (b * 1.2, 0.36 * dims.y, b * 0.6)))   # the trolley across the rails

    def bay(self, lo, hi, kind, furn, mach):
        """ribbed bays (bridge, corridors, crew, dark decks, archives, holds, galleries): wall pilasters and an overhead rib every
        bay, then what the room holds along its walls. The Eclipse take truss braces, never ribs."""
        dims = hi - lo; c = (lo + hi) / 2
        rnd = random.Random(int(abs(c.x * 997 + c.y * 31 + c.z * 7)))
        p = 0.06 * min(dims.y, dims.z)
        n = max(2, int(dims.x / max(0.55 * dims.z, 0.6 * dims.y if dims.y < dims.z else 0.0, 1e-6)))
        n = min(n, 14)
        eclipse = self.fac == 'eclipse'
        for k in range(n + 1):
            x = lo.x + p + (dims.x - 2 * p) * k / n
            for s in (-1, 1):
                self.piece(mach, box((x, c.y + s * (dims.y / 2 - p / 2), c.z), (p / 2, p / 2, dims.z / 2)))
            if eclipse:
                # a truss: a flat chord overhead and two diagonals down to the walls
                self.piece(mach, box((x, c.y, hi.z - p / 2), (p / 2, dims.y / 2, p / 2)))
                for s in (-1, 1):
                    a = Vector((x, c.y, hi.z - p)); b2 = Vector((x, c.y + s * (dims.y / 2 - p), hi.z - 0.45 * dims.z))
                    self.piece(mach, tube(a, b2, p * 0.35, 4), False)
            else:
                self.piece(mach, box((x, c.y, hi.z - p / 2), (p / 2, dims.y / 2, p / 2)))
        if kind in ('bridge', 'crew', 'hcorr', 'darkdeck', 'gallery'):
            # consoles along both walls between the pilasters: a low desk and a sloped face
            for k in range(n):
                xa = lo.x + p + (dims.x - 2 * p) * k / n; xb = lo.x + p + (dims.x - 2 * p) * (k + 1) / n
                for s in (-1, 1):
                    if dims.y < 0.45 * dims.z and s > 0:
                        continue
                    dd = 0.18 * dims.y if dims.y > 0.45 * dims.z else 0.3 * dims.y
                    yc = c.y + s * (dims.y / 2 - p - dd / 2)
                    h = 0.32 * dims.z
                    self.piece(furn, box(((xa + xb) / 2, yc, lo.z + h / 2), ((xb - xa) / 2 - p, dd / 2, h / 2)))
                    self.piece(furn, box(((xa + xb) / 2, yc + s * dd * 0.2, lo.z + h + 0.08 * dims.z), ((xb - xa) / 2 - 1.5 * p, dd * 0.18, 0.08 * dims.z)))
                    # Glasswright consoles: a lit crystal set in each desk
                    self.crystal(((xa + xb) / 2, yc - s * dd * 0.15, lo.z + h), (0, 0, 1), 0.08 * dd + 0.2 * p, 0.12 * dims.z, k + (s > 0))
        elif kind == 'archive':
            # tall archive stacks in rows down the room, shelves across them
            rows = max(1, min(4, int(dims.y / (0.35 * dims.z))))
            for r_ in range(rows):
                y = lo.y + p + (dims.y - 2 * p) * (r_ + 0.5) / rows
                w = 0.32 * (dims.y - 2 * p) / rows
                self.piece(furn, box((c.x, y, lo.z + 0.42 * dims.z), (dims.x / 2 - 2 * p, w, 0.42 * dims.z), self.seg))
                for j in range(1, 4):
                    self.piece(mach, box((c.x, y, lo.z + 0.84 * dims.z * j / 4), (dims.x / 2 - 2 * p, w * 1.15, p * 0.35), self.seg))
        else:
            # holds and anything else: crates stacked against the walls (seeded, so a rebuild places the same)
            for k in range(n):
                xa = lo.x + p + (dims.x - 2 * p) * k / n; xb = lo.x + p + (dims.x - 2 * p) * (k + 1) / n
                for s in (-1, 1):
                    h = dims.z * rnd.uniform(0.25, 0.6); d = dims.y * rnd.uniform(0.15, 0.3)
                    yc = c.y + s * (dims.y / 2 - p - d / 2)
                    self.piece(furn, box(((xa + xb) / 2, yc, lo.z + h / 2), ((xb - xa) / 2 * rnd.uniform(0.6, 0.9), d / 2, h / 2)))

    # ---------------------------------------------------------------------------------------------------- decks
    def deck(self, ob):
        """girders under the deck along its own footprint (rays onto the deck object), and flanges along its edges"""
        lo, hi = bounds(ob)
        dims = hi - lo
        if dims.x < 0.03 * self.L or dims.y < 0.02 * self.L:
            return
        tree = obj_tree(ob)
        above = hi.z + 1.0; below = lo.z - 1.0
        def at(x, y):
            t = tree.ray_cast(Vector((x, y, above)), Vector((0, 0, -1)))
            if t[0] is None:
                return None
            b = tree.ray_cast(Vector((x, y, below)), Vector((0, 0, 1)))
            return (t[0].z, b[0].z if b[0] is not None else t[0].z)
        nx = max(6, int(dims.x / (0.012 * self.L)))
        xs = [lo.x + dims.x * (i + 0.5) / nx for i in range(nx)]
        thick = 0.0; nt = 0
        for x in xs[:: max(1, nx // 6)]:
            h = at(x, (lo.y + hi.y) / 2)
            if h:
                thick += h[0] - h[1]; nt += 1
        thick = max(thick / max(nt, 1), 0.004 * self.L)
        depth = 2.4 * thick; w = 0.9 * thick
        out = Mesh()
        # the edges at each station: scan across
        edges = []
        for x in xs:
            ys = [lo.y + dims.y * j / 40 for j in range(41)]
            hit = [y for y in ys if at(x, y)]
            edges.append((x, min(hit), max(hit)) if hit else (x, None, None))
        def run(yfun, tag):
            seg = []
            for (x, ya, yb) in edges:
                y = yfun(ya, yb) if ya is not None else None
                h = at(x, y) if y is not None else None
                if h and at(x, y - w) and at(x, y + w):
                    seg.append((x, y, h[1]))
                else:
                    self._beam(out, seg, w, depth); seg = []
            self._beam(out, seg, w, depth)
        cy = (lo.y + hi.y) / 2
        run(lambda a, b: cy, 'keel')
        run(lambda a, b: a + 0.33 * (b - a), 'stbd')
        run(lambda a, b: a + 0.67 * (b - a), 'port')
        run(lambda a, b: a + 3.5 * w, 'stbd edge')           # the edge flanges, held in from the edge (a flange at the very edge
        # tore past its piece's broken hull on A16's castle deck)
        run(lambda a, b: b - 3.5 * w, 'port edge')
        step = max(1, int(round(nx / max(2, dims.x / (0.05 * self.L)))))
        for i in range(step // 2, nx, step):                    # transverse beams
            x, ya, yb = edges[i]
            if ya is None or yb - ya < 6 * w:
                continue
            h = at(x, (ya + yb) / 2)
            if not h:
                continue
            self.piece(out, box((x, (ya + yb) / 2, h[1] - 0.7 * depth / 2), (w * 0.8, (yb - ya) / 2 - 2.2 * w, 0.7 * depth / 2), self.seg))
        self.emit(ob, out, 'frame')

    def _beam(self, out, seg, w, depth):
        """a girder under the deck through the stations of seg ((x, y, deck bottom z)), its top on the deck's bottom; an I section
        (a web and a bottom flange) in straight runs no longer than SEG, each following the deck between its ends"""
        if len(seg) < 2:
            return
        runs = [[seg[0]]]
        for st in seg[1:]:
            runs[-1].append(st)
            if abs(st[0] - runs[-1][0][0]) >= self.seg:
                runs.append([st])
        for r in runs:
            if len(r) < 2:
                continue
            (x0, y0, _), (x1, y1, _) = r[0], r[-1]
            xm = (x0 + x1) / 2; ym = sum(p[1] for p in r) / len(r); zt = min(p[2] for p in r); hx = abs(x1 - x0) / 2 + 1e-4
            self.piece(out, box((xm, ym, zt - depth / 2), (hx, w * 0.3, depth / 2)))
            self.piece(out, box((xm, ym, zt - depth + w * 0.2), (hx, w, w * 0.2)))

    # ---------------------------------------------------------------------------------------------------- bulkheads
    def bulkhead(self, ob):
        lo, hi = bounds(ob); dims = hi - lo
        if dims.x > 0.5 * min(dims.y, dims.z) or min(dims.y, dims.z) < 0.03 * self.L:
            return
        xc = (lo.x + hi.x) / 2; t = dims.x
        pts = [Vector((v.co.y, v.co.z)) for v in ob.data.vertices if (ob.matrix_world @ v.co).x >= xc - 1e-6]
        if len(pts) < 6:
            return
        cen = sum(pts, Vector((0, 0))) / len(pts)
        pts = sorted(pts, key=lambda p: math.atan2(p.y - cen.y, p.x - cen.x))
        if len(pts) > 20:      # the collar follows the plate's outline at 20 points (its triangle cost stays small)
            pts = [pts[int(i * len(pts) / 20)] for i in range(20)]
        hy = dims.y / 2; hz = dims.z / 2
        cw = 0.1 * min(dims.y, dims.z); tc = max(0.5 * t, 0.002 * self.L)
        inner = [cen + (p - cen) * max(0.0, 1 - cw / max((p - cen).length, 1e-6)) for p in pts]
        out = Mesh()
        n = len(pts)
        for side in (-1, 1):
            x0 = xc + side * t / 2; x1 = xc + side * (t / 2 + tc)
            V = [(x0, p.x, p.y) for p in pts] + [(x0, p.x, p.y) for p in inner] + [(x1, p.x, p.y) for p in pts] + [(x1, p.x, p.y) for p in inner]
            F = []
            for i in range(n):
                j = (i + 1) % n
                F += [(2 * n + i, 2 * n + j, 3 * n + j, 3 * n + i), (i, j, 2 * n + j, 2 * n + i), (n + i, 3 * n + i, 3 * n + j, n + j)]
            self.piece(out, (V, F))
            # two stanchions, a cross beam and the framed pass-through arch, proud of the plate
            xm = xc + side * (t / 2 + tc / 2)
            def zspan(y):
                zs = []
                for a, b in zip(inner, inner[1:] + inner[:1]):
                    if (a.x - y) * (b.x - y) <= 0 and abs(b.x - a.x) > 1e-9:
                        zs.append(a.y + (b.y - a.y) * (y - a.x) / (b.x - a.x))
                return (min(zs), max(zs)) if len(zs) >= 2 else None
            if min(dims.y, dims.z) < 0.06 * self.L:
                continue      # a small ring (a rail's bulkhead): the collar alone
            for s in (-1, 1):
                y = cen.x + s * 0.42 * hy; zz = zspan(y)
                if zz:
                    self.piece(out, box((xm, y, (zz[0] + zz[1]) / 2), (tc / 2, 0.35 * cw, (zz[1] - zz[0]) / 2 - 0.2 * cw)))
            zz = zspan(cen.x)
            if zz:
                zb = zz[0]; ah = 0.5 * (zz[1] - zz[0]); aw = 0.24 * hy
                self.piece(out, box((xm, cen.x, zb + 0.62 * (zz[1] - zz[0])), (tc / 2, 0.42 * hy, 0.3 * cw)))      # cross beam
                for s in (-1, 1):
                    self.piece(out, box((xm, cen.x + s * aw, zb + ah / 2), (tc / 2 * 1.3, 0.25 * cw, ah / 2)))    # arch posts
                self.piece(out, box((xm, cen.x, zb + ah), (tc / 2 * 1.3, aw + 0.25 * cw, 0.25 * cw)))              # lintel
        self.emit(ob, out, 'frame')

    # ---------------------------------------------------------------------------------------------------- the Chorus
    def organ(self, ob, kind):
        """vascular ridges over the organ's own surface (rays from its middle) and sac lobes swelling from it"""
        lo, hi = bounds(ob); c = (lo + hi) / 2; rad = (hi - lo) / 2
        if min(rad) < 0.01 * self.L:
            return
        tree = obj_tree(ob)
        def surf(d):
            h = tree.ray_cast(c, d.normalized())
            return h[0]
        rnd = random.Random(int(abs(c.x * 733 + c.y * 17 + c.z * 3)))
        veins = Mesh(); lobes = Mesh()
        rv = 0.05 * min(rad)
        for k in range(7):
            a0 = rnd.uniform(0, 2 * math.pi); tw = rnd.uniform(-1.2, 1.2)
            pts = []
            for j in range(13):
                th = -1.25 + 2.5 * j / 12; a = a0 + tw * th
                d = Vector((math.cos(th) * math.cos(a), math.cos(th) * math.sin(a), math.sin(th)))
                p = surf(d)
                if p is not None:
                    pts.append(p + d.normalized() * rv * 0.3)
            if len(pts) >= 4:
                rr = [rv * (0.6 + 0.4 * math.sin(math.pi * i / (len(pts) - 1))) for i in range(len(pts))]
                self.piece(veins, path_tube(pts, rr, 6), True)
        for k in range(5):
            d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.6, 0.6)))
            if d.length < 1e-3:
                continue
            p = surf(d)
            if p is None:
                continue
            rl = rnd.uniform(0.18, 0.3) * min(rad)
            self.piece(lobes, lump(p - d.normalized() * rl * 0.45, (rl, rl, rl * 0.85), seed=rnd.randint(0, 999)), True)
        self.emit(ob, veins, 'vein'); self.emit(ob, lobes, kind)

    def hoops(self, obs):
        """knobs on every bone hoop and knobbed cross-struts between neighbouring hoops (tendons of bone)"""
        rings = []
        for ob in obs:
            lo, hi = bounds(ob); x = (lo.x + hi.x) / 2
            P = [ob.matrix_world @ v.co for v in ob.data.vertices]
            cen = sum(P, Vector()) / len(P)
            rings.append((x, ob, P, cen))
        rings.sort(key=lambda r: r[0])
        for (x, ob, P, cen) in rings:
            knobs = Mesh()
            inner = sorted(P, key=lambda p: (p - Vector((p.x, cen.y, cen.z))).length)[: len(P) // 2]
            r0 = 0.6 * (max(P, key=lambda p: p.x).x - min(P, key=lambda p: p.x).x) + 0.002 * self.L
            for k in range(8):
                a = 2 * math.pi * k / 8
                d = Vector((0, math.cos(a), math.sin(a)))
                p = max(inner, key=lambda q: (q - cen).normalized().dot(d))
                self.piece(knobs, lump(p, (r0, r0 * 1.1, r0 * 1.1), seed=k + int(x * 10)), True)
            self.emit(ob, knobs, 'bonefr')
        for (xa, oa, Pa, ca), (xb, ob_, Pb, cb) in zip(rings, rings[1:]):
            if xb - xa > 0.2 * self.L:
                continue
            struts = Mesh()
            for a in (0.75, 2.4, 3.9, 5.5):
                d = Vector((0, math.cos(a), math.sin(a)))
                pa = max(Pa, key=lambda q: (q - ca).normalized().dot(d) - 0.2 * (q - ca).length / max((q - ca).length, 1e-6))
                pb = max(Pb, key=lambda q: (q - cb).normalized().dot(d) - 0.2 * (q - cb).length / max((q - cb).length, 1e-6))
                pa = ca + (pa - ca) * 0.9; pb = cb + (pb - cb) * 0.9
                r = 0.006 * self.L
                mid = (pa + pb) / 2
                pts = [pa + (pb - pa) * t for t in (0, 0.25, 0.5, 0.75, 1)]
                self.piece(struts, path_tube(pts, [r * 1.3, r, r * 0.85, r, r * 1.3], 6), True)
                self.piece(struts, lump(mid, (r * 1.8, r * 1.6, r * 1.6), seed=int(a * 10)), True)
            self.emit(oa, struts, 'bonefr')

    def septum(self, ob):
        """fibrous ridges along the membrane shelf's top and bottom"""
        lo, hi = bounds(ob); dims = hi - lo
        if dims.x < 0.03 * self.L:
            return
        tree = obj_tree(ob); out = Mesh(); r = 0.0035 * self.L
        nx = max(6, int(dims.x / (0.02 * self.L)))
        for j in range(1, 6):
            y = lo.y + dims.y * j / 6
            for sgn, z0 in ((-1, hi.z + 1), (1, lo.z - 1)):
                pts = []
                for i in range(nx + 1):
                    x = lo.x + dims.x * i / nx
                    h = tree.ray_cast(Vector((x, y + 0.03 * dims.y * math.sin(i * 1.3 + j), z0)), Vector((0, 0, sgn)))
                    if h[0] is None:
                        if len(pts) >= 3:
                            self.piece(out, path_tube(pts, r, 5), True)
                        pts = []
                        continue
                    pts.append(h[0] - Vector((0, 0, sgn)) * r * 0.4)
                if len(pts) >= 3:
                    self.piece(out, path_tube(pts, r, 5), True)
        self.emit(ob, out, 'tissue')


# ------------------------------------------------------------------------------------------------------------ helpers
def bounds(ob):
    P = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
    return Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))), Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))


def obj_tree(ob):
    dg = bpy.context.evaluated_depsgraph_get(); ev = ob.evaluated_get(dg); me = ev.to_mesh(); mw = ob.matrix_world
    t = BVHTree.FromPolygons([mw @ v.co for v in me.vertices], [tuple(p.vertices) for p in me.polygons])
    ev.to_mesh_clear()
    return t


def box_uv(ob, tile):
    """box projection at one texel density: each face takes the two world axes across its normal, tile units per repeat"""
    me = ob.data; mw = ob.matrix_world; n3 = mw.to_3x3()
    bm = bmesh.new(); bm.from_mesh(me)
    uv = bm.loops.layers.uv.get('UVMap') or bm.loops.layers.uv.new('UVMap')
    for f in bm.faces:
        nrm = (n3 @ f.normal); ax = max(range(3), key=lambda i: abs(nrm[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][ax]
        for lp in f.loops:
            p = mw @ lp.vert.co
            lp[uv].uv = (p[a] / tile, p[b] / tile)
    bm.to_mesh(me); bm.free()
    if me.uv_layers.get('UVMap'):
        me.uv_layers.active = me.uv_layers['UVMap']


def _gw_zones():
    """the Glasswright leaf glass zones the crystals take (gw_in_amber, _violet, _green), registered from kits/ithar/hull.py
    when the sheet has not (a strike craft sets up only the paint stack)"""
    import importlib.util, sys
    km = sys.modules.get('kit')
    if km is None or all(('gw_in_' + c) in km.MATS for c in ('amber', 'violet', 'green')):
        return
    sp = importlib.util.spec_from_file_location('ithar_hull_zones', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'kits', 'ithar', 'hull.py'))
    hm = importlib.util.module_from_spec(sp); sp.loader.exec_module(hm)
    for c in ('amber', 'violet', 'green'):
        rgb, em = hm.ZONES['gw_in_' + c][:2]
        km.MATS.setdefault('gw_in_' + c, (rgb, em))


def faction_of(K, kit_name):
    import bpy
    # the whole ship, not only its insides: a Glasswright strike craft builds its insides from the base kit's zones (GV2, GW4),
    # and was dressed as Hullbreaker machinery when only the insides were read
    mats = {s.material.name for ob in bpy.context.scene.objects for s in getattr(ob, 'material_slots', ()) if s.material}
    if any(m.startswith('gw_') for m in mats):
        return 'ithar'
    return kit_name


def dress(K, kit_name):
    """the pass: add the modeled interior, then UVs and the V2 mark on every inside. Returns a summary for the sheet's INSIDE."""
    fac = faction_of(K, kit_name)
    D = Dresser(K, fac)
    src = [ob for ob in list(K.cin.objects) if ob.type == 'MESH']
    hoops = []
    for ob in src:
        m = ob.data.materials[0].name if ob.data.materials else ''
        if m.startswith('gw_'):
            continue
        if ob.name.startswith('in_deck_'):
            if m == 'septum':
                D.septum(ob)
            else:
                D.deck(ob)
        elif ob.name.startswith('in_bh_'):
            if m == 'bonefr':
                hoops.append(ob)
            else:
                D.bulkhead(ob)
        elif m in CHORUS_ORGANS:
            D.organ(ob, m)
        elif m:
            D.room(ob, m)
    if hoops:
        D.hoops(hoops)
    tile = TILE * K.length
    for ob in K.cin.objects:
        if ob.type == 'MESH':
            box_uv(ob, tile); ob['interior_kit'] = VERSION
    summary = dict(version=VERSION, faction=fac, pieces=D.kept, dropped_outside=D.dropped, dropped_points=D.why, faces_by_material=D.added,
                   tile=round(tile, 3))
    print('[interior_kit] %s' % summary)
    return summary
