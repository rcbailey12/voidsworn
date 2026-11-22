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


def _pick(g, bay, palette, weights, seed):
    h = math.sin(g * 12.9898 + bay * 78.233 + seed * 3.7) * 43758.5453
    h = h - math.floor(h)
    total, acc = sum(weights), 0.0
    for colour, w in zip(palette, weights):
        acc += w / total
        if h <= acc:
            break
    return colour


import os as _os
# How the panel colours mix (Ryan Nov 20 7:48 PM CT, look test A/B/C, issue 1415: picked C): 'streaks' runs thin streaks of
# mixed amber, violet and green side by side down each gap between the ribbons, each its own colour and length, for every
# Glasswright hull. 'blocks' (one colour per leaf panel, R337 round 5) stays for comparison only; GW_MIX overrides it in a test.
MIX = _os.environ.get('GW_MIX', 'marble')


def _hash2(i, j, seed):
    h = math.sin(i * 127.1 + j * 311.7 + seed * 74.7) * 43758.5453
    return h - math.floor(h)


def _vnoise(u, v, seed, period_v=None):
    """smooth value noise; v wraps with period_v (whole cells round the hull) when given"""
    i0, j0 = math.floor(u), math.floor(v)
    fu, fv = u - i0, v - j0
    su, sv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    def h(i, j):
        if period_v:
            j = j % period_v
        return _hash2(i, j, seed)
    a = h(i0, j0) + (h(i0 + 1, j0) - h(i0, j0)) * su
    b = h(i0, j0 + 1) + (h(i0 + 1, j0 + 1) - h(i0, j0 + 1)) * su
    return a + (b - a) * sv


def marble_field(x, a, seed=0):
    """a flowing, marbled colour field over the hull: long veins along the ship that meander, split and run into each other
    (domain-warped value noise, stretched along x). Returns 0..1."""
    P = 20                                     # cells round the hull (whole, so the field wraps seamlessly)
    v = a / (2 * math.pi) * P
    u = x * 0.85
    wu = _vnoise(u * 0.7 + 3.1, v * 0.5, seed + 5, P) - 0.5
    wv = _vnoise(u * 0.9 + 7.7, v * 0.5 + 1.3, seed + 9, P) - 0.5
    uu, vv = u + 1.2 * wu, v + 2.6 * wv
    n = 0.62 * _vnoise(uu, vv, seed, P) + 0.38 * _vnoise(uu * 2.3, vv * 2.0 + 0.5, seed + 3, 2 * P)
    return n


_MARBLE_CUTS = {}


def _marble_cuts(weights, seed):
    """the field values that split it into the palette's shares (55/27/18): measured once on a sample"""
    key = (tuple(weights), seed)
    if key not in _MARBLE_CUTS:
        vals = sorted(marble_field(i * 0.173, j * 0.0911, seed) for i in range(140) for j in range(70))
        tot, acc, cuts = sum(weights), 0.0, []
        for w in weights[:-1]:
            acc += w / tot
            cuts.append(vals[int(acc * (len(vals) - 1))])
        _MARBLE_CUTS[key] = cuts
    return _MARBLE_CUTS[key]



def mosaic_tint(x, a, gaps, palette, weights, seed=0, tones=None, streak=False):
    """the colour and glow a core point carries. `gaps` gives (gap index, along-coordinate[, across 0..1]) for the point;
    each gap is cut into leaf-length bays and every bay picks one colour from the palette by weight, so panels read as
    leaves of one colour each, never salt and pepper.

    R337 round 5 (outside read: "flat blocks, not lit from behind"): a panel is lit from behind, so its glow is hottest in
    the middle and falls to dark at its lead border, along AND across; with `tones` (name -> (deep rgb, hot rgb)) the colour
    itself runs from the deep tone at the border to the hot tone in the middle, and near a bay end it runs into the next
    leaf's colour along the flow. Returns (rgb or palette name, glow).

    streak=True (issue 1415, Ryan Nov 20: the Prism and the W4b bomber read as "random circles of light"): on a wide body the
    ribbons no longer hide a bay's dark border, so the hot-middle fall-off shows as a lit disk. The streak style keeps only a
    thin dark rim (outer 15% along, 20% across), lights the pane evenly inside and adds a soft hot line down its long axis,
    so each pane reads as a streak of stained glass between the leading. Off by default: CD5 and the slim hulls keep R337."""
    r = gaps(x, a)
    g, along = r[0], r[1]
    across = r[2] if len(r) > 2 else 0.5
    if MIX == 'marble':
        # Ryan Nov 21: intermixed, the colours running together, never rectangle after rectangle of one colour
        n = marble_field(x, a, seed)
        cuts = _marble_cuts(weights, seed)
        ac = min(1.0, max(0.0, across))
        glow = 0.06 + 0.80 * min(1.0, min(ac, 1 - ac) / 0.18) ** 0.8 * (0.55 + 0.45 * _vnoise(x * 1.7, a * 9.0, seed + 21))
        if not tones:
            k = sum(1 for c in cuts if n > c)
            return palette[k], glow
        def tone(name):
            deep, hot = tones[name]
            return [d + (h - d) * glow ** 1.5 for d, h in zip(deep, hot)]
        cols = [tone(c) for c in palette]
        k = sum(1 for c in cuts if n > c)
        rgb = cols[k]
        bw = 0.035                              # the colours run into each other across a soft seam
        for i, c in enumerate(cuts):
            if abs(n - c) < bw:
                t = 0.5 + 0.5 * (n - c) / bw
                rgb = [p + (q - p) * t for p, q in zip(cols[i], cols[i + 1])]
                break
        return tuple(rgb), glow
    if MIX == 'streaks':
        # thin streaks of mixed colour side by side down each gap, each its own colour and length
        n = 4
        ac = min(0.999, max(0.0, across)) * n
        sub = int(ac)
        sa = along * 0.55 + 0.37 * sub
        bay = math.floor(sa)
        frac = sa - bay
        colour = _pick(g * 7 + sub, bay, palette, weights, seed + 11)
        fa = ac - sub
        rim_c = min(1.0, min(fa, 1 - fa) / 0.22)
        rim_a = min(1.0, min(frac, 1 - frac) / 0.08)
        glow = 0.06 + 0.78 * (rim_a * rim_c) ** 0.7 * (0.40 + 0.60 * math.sin(math.pi * fa) ** 1.5) * (0.6 + 0.4 * math.sin(math.pi * min(1.0, max(0.0, across))))
        if not tones:
            return colour, glow
        deep, hot = tones[colour]
        return tuple(d + (h - d) * glow ** 1.5 for d, h in zip(deep, hot)), glow
    bay = math.floor(along)
    frac = along - bay
    colour = _pick(g, bay, palette, weights, seed)
    # the ribbons hide the outer quarter of a gap each side, so the fall-off is steep across: dark at the visible border
    if streak:
        ac = min(1.0, max(0.0, across))
        rim_a = min(1.0, min(frac, 1 - frac) / 0.15)
        rim_c = min(1.0, min(ac, 1 - ac) / 0.20)
        rim = (rim_a * rim_c) ** 0.7
        line = math.exp(-((ac - 0.5) / 0.16) ** 2)
        glow = 0.06 + 0.94 * rim * (0.62 + 0.38 * line)
    else:
        glow = (max(0.0, math.sin(math.pi * frac)) ** 1.2) * (max(0.0, math.sin(math.pi * min(1.0, max(0.0, across)))) ** 3.0)
        glow = 0.06 + 0.94 * glow
    if not tones:
        return colour, glow
    def tone(name, k):
        deep, hot = tones[name]
        return [d + (h - d) * k for d, h in zip(deep, hot)]
    rgb = tone(colour, glow ** 1.5)
    # run into the neighbouring leaf along the flow over the last fifth of the bay
    edge = min(frac, 1 - frac)
    if edge < 0.2 and not streak:
        other = _pick(g, bay + (1 if frac > 0.5 else -1), palette, weights, seed)
        w = 0.5 * (1 - edge / 0.2) ** 2
        rgb = [c + (o - c) * w for c, o in zip(rgb, tone(other, glow ** 1.5))]
    return tuple(rgb), glow


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
