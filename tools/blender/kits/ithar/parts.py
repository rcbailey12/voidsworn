# The Glasswright (`ithar`) part kit: ribbons, mosaic panels and lenses (issue 1183, R337; R333: shared, so every Glasswright
# sheet ship gets the same look when it is rebuilt).
#
# The look (Ryan, Nov 18 2026: "glass like, so almost reflective"; Nov 19 R337: restart from the approved CD5 concept):
#   - the hull is long sweeping RIBBONS, like flame or folded silk, overlapping and twisting stern to bow; opaque, pearly white
#     to champagne, highly reflective, with fine silver lines along their edges;
#   - the gaps between ribbons are MOSAIC panels: leaf-shaped fields of small faceted cells in amber, violet and green that glow
#     from within, like stained glass. They are the main colour of the ship;
#   - NOTHING is see-through on an intact hull. The mosaic is an opaque core skin under the ribbons; the interior lives in the
#     inside collection for the death and break-up only.
#
# Pure geometry: mathutils only, no bpy. Every builder returns (verts, faces) plus per-vertex attributes the sheet writes onto
# the mesh (the paint stack in stack.py reads them). The ship file supplies its own core surface: core(x, a, lift) returns the
# world point at station x, section angle a (0 = port beam, pi/2 = top), pushed `lift` along the outward normal.
import math
from mathutils import Vector

TAU = 2 * math.pi


def outward(core, x, a, lift, eps=1e-3):
    """core point pushed `lift` along its outward normal (finite differences, so any core shape works)"""
    p = Vector(core(x, a))
    if not lift:
        return p
    du = Vector(core(x + eps, a)) - Vector(core(x - eps, a))
    dv = Vector(core(x, a + eps)) - Vector(core(x, a - eps))
    n = du.cross(dv)
    if n.length < 1e-9:
        n = Vector((0, math.cos(a), math.sin(a)))
    n.normalize()
    radial = Vector((0, p.y, p.z))
    if radial.length > 1e-6 and n.dot(radial) < 0:
        n = -n
    return p + n * lift


class Ribbon:
    """One sweeping pearl ribbon laid over the core.

    x0, x1      stations where it starts (stern) and ends (bow)
    centre(x)   section angle of the ribbon's centre line (the twist and sweep)
    half(t)     half width in radians at t = 0..1 along the ribbon (leaf, flame or band profile)
    lift(t, v)  height above the core at t and across-coordinate v = -1..1 (curl a leaf edge up for a crest)
    """

    def __init__(self, x0, x1, centre, half, lift, name='ribbon', clamp=None):
        self.x0, self.x1, self.centre, self.half, self.lift, self.name = x0, x1, centre, half, lift, name
        self.clamp = clamp  # optional clamp(x, point, lift) -> lift, keeps clear of grown optics

    def point(self, core, t, v):
        x = self.x0 + (self.x1 - self.x0) * t
        a = self.centre(x) + v * self.half(t)
        h = self.lift(t, v)
        if self.clamp:
            h = self.clamp(x, core(x, a), h)
        return outward(core, x, a, h)

    def mesh(self, core, nu=160, nv=12):
        """open strip (the sheet solidifies it into a thick ribbon); attributes: along (0..1), across (-1..1)"""
        verts, along, across = [], [], []
        for i in range(nu + 1):
            t = i / nu
            for j in range(nv + 1):
                v = -1 + 2 * j / nv
                verts.append(self.point(core, t, v)); along.append(t); across.append(v)
        row = nv + 1
        faces = [(i * row + j, i * row + j + 1, (i + 1) * row + j + 1, (i + 1) * row + j)
                 for i in range(nu) for j in range(nv)]
        return verts, faces, dict(gw_along=along, gw_across=across)

    def edge(self, core, side, nu=160, raise_=0.012):
        """the polyline along one edge (side -1 or +1), a hair above the ribbon, for its silver line"""
        out = []
        for i in range(nu + 1):
            t = i / nu
            x = self.x0 + (self.x1 - self.x0) * t
            a = self.centre(x) + side * self.half(t)
            h = self.lift(t, side)
            if self.clamp:
                h = self.clamp(x, core(x, a), h)
            out.append(outward(core, x, a, h + raise_))
        return out

    def covers(self, x, a, pad=0.0):
        """True where this ribbon lies over station x, angle a (for placing mosaic panels in the gaps)"""
        if not (self.x0 <= x <= self.x1):
            return False
        t = (x - self.x0) / (self.x1 - self.x0)
        d = math.atan2(math.sin(a - self.centre(x)), math.cos(a - self.centre(x)))
        return abs(d) <= self.half(t) + pad


def leaf(p=0.7, floor=0.0, peak=0.5, tip=None):
    """a leaf or flame profile, widest at t = peak. `floor` keeps the start (stern) gathered rather than pointed; `tip` is
    the width kept at the end (default the same floor; 0 tapers a flame tongue to a point)"""
    end = floor if tip is None else tip
    def f(t):
        if t <= peak:
            s, lo = math.sin(0.5 * math.pi * t / peak), floor
        else:
            s, lo = math.sin(0.5 * math.pi * (1 - t) / (1 - peak)), end
        return lo + (1 - lo) * max(0.0, s) ** p
    return f


def mosaic_tint(x, a, gaps, palette, weights, seed=0):
    """which panel colour a core point carries. `gaps` gives (gap index, along-coordinate) for the point; each gap is cut into
    leaf-length bays and every bay picks one colour from the palette by weight, so panels read as leaves of one colour each,
    never salt and pepper. Returns (rgb, glow) where glow falls to the panel's lead border."""
    g, along = gaps(x, a)
    bay = math.floor(along)
    frac = along - bay
    h = math.sin(g * 12.9898 + bay * 78.233 + seed * 3.7) * 43758.5453
    h = h - math.floor(h)
    total = sum(weights)
    acc = 0.0
    for colour, w in zip(palette, weights):
        acc += w / total
        if h <= acc:
            break
    # Brighter in the middle of each leaf, dimmer at the ends where two leaves meet (stained-glass leading).
    glow = 0.35 + 0.65 * math.sin(math.pi * frac) ** 0.6
    return colour, glow


def cut_lens(centre, axis, radius, depth, sides=12, ry=None, rz=None):
    """a rose-cut faceted lens: a girdle ring, a staggered crown ring and an apex, flat triangular facets (shade it flat).
    `axis` is the outward direction (unit vector along x, y or z of the world, sign included); ry, rz stretch an oval lens."""
    c = Vector(centre); ax = Vector(axis).normalized()
    u = ax.orthogonal().normalized(); w = ax.cross(u).normalized()
    ry = ry or radius; rz = rz or radius
    def ring(scale, d, phase):
        return [c + ax * d + u * (ry * scale * math.cos(phase + TAU * i / sides)) + w * (rz * scale * math.sin(phase + TAU * i / sides))
                for i in range(sides)]
    girdle = ring(1.0, 0.0, 0.0)
    crown = ring(0.62, depth * 0.62, math.pi / sides)
    apex = c + ax * depth
    verts = girdle + crown + [apex]
    n = sides
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + i))            # girdle facet
        faces.append((j, n + j, n + i))        # star facet between crown points
        faces.append((n + i, n + j, 2 * n))    # top facet to the apex
    faces.append(tuple(range(n))[::-1])        # the back, closed
    return verts, faces
