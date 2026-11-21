# hegemony_IM5: The Iron Mandate, the Hegemony Navy's super-dreadnought (data.js h_boss, class Super-dreadnought, 31.0 world
# units, the boss). Issue 768. Shape of record: contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg and IM5_top.jpg (Ryan,
# Nov 14 2026: "Im5 is my preference", R255; the mix of IM2 and IM3 he asked for, R254). data.js h_boss: hturbo P, hturbo S,
# turbo T, ion F, flak T; ability nova (no mount); no hangar. Designer of record: the Opus builder, the Board the final designer
# (R205, R207, R233, R236): IM5 is a base, not a trace. Every change from IM5 is listed by K.change below.
# Measured off IM5_top.jpg (bow down in the picture; its own "IM5 TOP" label hides the bow tip, so the bow is read from the
# three-quarter IM5.jpg): length to beam about 2.5, the widest beam at about 35 to 45 percent from the stern, the stern about
# 0.62 of the widest beam, the canyon parallel-sided, about 0.4 of the beam, bridges at about 21, 40 and 64 percent from the
# stern. IM5 has no side view: the heights are designed (the three-quarter shows a thick hull, ridges standing well above the
# canyon floor, low flush bridges).
# +X bow, +Y port, +Z up. Bow face x = +15.5, the hull's stern face -14.3, nozzle exits -15.5. The hull datum is z 0.
import math
from ships.hegemony_H10 import ion_trench

CODE = 'hegemony_IM5'
NAME = 'The Iron Mandate, super-dreadnought (Hegemony Navy flagship, the boss)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'Super-dreadnought'
LENGTH = 31.0
GAME = "data.js h_boss (cls 'Super-dreadnought', boss); length from godot/render/hull_table.gd CLS_LEN['Super-dreadnought'] = 31.0 (drawn x SHIP_K 1.6 = 49.6 on the board)"
BEAUTY = 'contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg'
KIT = 'hegemony'
# IM5's only true view is its top view; IM5_top.jpg turned so the bow is on the left (the sheet tools crop and flip only). IM5 has
# no side view: the sheet tools leave the concept's side cells and its length to height blank (issue 768).
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_IM5/concept_IM5_top_bow_left.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(2, 37, 718, 345), largest=True, flip=False))   # from row 37: the label's part above the ship left out
CROPS = [('bow (the bow deck, the fin, the canyon mouth and the ion trench)', (60, 380, 560, 700)),
         ('midships (the bridged canyon, the shoulder lances, the bridge turret)', (300, 120, 800, 470)),
         ('stern (the stern bridge, the nozzle row)', (560, 30, 1060, 330))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus768',
             blend_where='rendered in the issue 768 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_IM5 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit (issue 759) and its issue 768 additions, run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them. Beyond the fit check: the inside check sent back '
                    'four rooms set below the belly skin and frames F1 and F2 outside the skin at the tapering bow (frames inset 0.08 more); the '
                    'first battle-camera look sent back the shoulder swell (0.4 out over 0.15, a box sticking out of the flank), now 0.3 over '
                    'two long ramps; the first look beside IM5 sent back a small trench mouth (2.2 by 1.0, now 2.6 by 1.25) and a bare canyon '
                    '(coolant lines on the ledges and the engine room\'s control windows at the canyon\'s end added).')

# ---------------------------------------------------------------------------------------------------- the hull's section
# One broad wedge hull. Its section (port half; starboard mirrors it), from the centreline at the canyon floor outward: the canyon
# floor, the canyon's lower wall, a ledge, the upper wall, a chamfered lip, the ridge deck, (at the shoulders) the pit wall and the
# pit's terrace, the deck-edge chamfer, the upper facet out to the knuckle, the vertical flank band (the blue line), the lower
# facet, the chine chamfer, the flat belly. The canyon is cut deep between two raised armoured ridges; at the bow its floor rises
# to the bow deck (the fin stands on it, the ion trench is under it); at the stern it rises to the stern deck (the engine rooms).
SHELL = 0.25       # hull thickness (the solidify shell)
XF = 15.5          # the bow face
XB = 13.0          # the ion trench's back wall: the main loft ends here, the bow frame runs on to the bow face
XS = -14.3         # the hull's stern face; the nozzle pods stand aft of it to -15.5
XE = -15.5         # the nozzle exits
CAN0, CAN1 = -12.4, 10.5     # the canyon's aft and forward ends (the stern deck step and the bow deck step)
NF_CAN = 0.1       # the canyon floor
NF_BOW = 0.95      # the bow deck (the canyon's floor ahead of the canyon: low, so the fin stays under the bridge turret's fire, R240)
TRENCH = dict(w=2.6, h=1.25, zc=-0.3)
BRIDGES = [('bow', 4.4, 1.8), ('mid', -3.4, 2.6), ('stern', -9.0, 2.2)]     # (name, x centre, length): flush with the ridge decks
BR_TOP, BR_BOT = 1.8, 1.05
SEAMS = (10.2, 1.2, -6.4, -11.4)                  # transverse seams (module bands where the hull gives way)
BANDS = (10.2, 6.4, 1.2, -0.6, -6.4, -11.4)       # module bands (raised rings); the seams are four of them
PIT = (-5.55, -5.4, -4.95, -1.85, -1.4, -1.25)    # the shoulder pits' stations: no pit, ramp, full depth ... full depth, ramp, no pit
TURRET = (-3.4, 4.22)                             # the shoulder lance turrets' ring centre (x, |y|), on the pit floor


def lerp_tab(tab, x):
    if x <= tab[0][0]:
        return tab[0][1]
    if x >= tab[-1][0]:
        return tab[-1][1]
    for (x0, v0), (x1, v1) in zip(tab, tab[1:]):
        if x0 <= x <= x1:
            return v0 + (v1 - v0) * ((x - x0) / (x1 - x0) if x1 > x0 else 0.0)


HW = [(-14.3, 5.15), (-12.0, 5.6), (-6.5, 6.0), (-1.0, 6.0), (6.0, 5.05), (11.0, 3.9), (15.5, 2.6)]    # the knuckle's half-beam
ZT = [(-14.3, 1.8), (4.0, 1.8), (15.5, 1.4)]          # the ridge deck
ZB = [(-14.3, -1.9), (-12.0, -2.0), (6.0, -2.0), (15.5, -1.2)]   # the belly
KT = [(-14.3, 0.5), (6.0, 0.5), (15.5, 0.32)]         # the flank band's top
KB = [(-14.3, -1.0), (6.0, -1.0), (15.5, -0.72)]      # the flank band's bottom
SWELL = [(-7.4, 0.0), (PIT[1], 0.3), (PIT[4], 0.3), (0.6, 0.0)]   # the knuckle swells gently out over the pits (IM5: widest at the lances)


def nf_at(x):
    """the floor of the notch between the ridges: the stern deck, the canyon floor, the bow deck"""
    return lerp_tab([(CAN0 - 0.02, ZT[0][1] - 0.3), (CAN0, NF_CAN), (CAN1 - 0.02, NF_CAN), (CAN1, NF_BOW)], x)


def par(x):
    hw = lerp_tab(HW, x) + lerp_tab(SWELL, x)
    zt, zb, kt, kb = lerp_tab(ZT, x), lerp_tab(ZB, x), lerp_tab(KT, x), lerp_tab(KB, x)
    nf = nf_at(x)
    t = max(0.0, min(1.0, (x - CAN1) / (XF - CAN1)))      # the bow deck narrows toward the bow face
    cf, cl, cw = 1.55 - 0.4 * t, 1.80 - 0.45 * t, 1.90 - 0.45 * t
    dw = hw - 0.75
    sd = lerp_tab([(PIT[0], 0.0), (PIT[1], 0.42), (PIT[4], 0.42), (PIT[5], 0.0)], x) if PIT[0] <= x <= PIT[5] else 0.0
    yfree = (cw + dw) / 2
    y1 = lerp_tab([(PIT[0], yfree), (PIT[1], 3.7), (PIT[2], 2.8), (PIT[3], 2.8), (PIT[4], 3.7), (PIT[5], yfree)], x) if PIT[0] <= x <= PIT[5] else yfree
    return dict(hw=hw, zt=zt, zb=zb, kt=kt, kb=kb, nf=nf, cf=cf, cl=cl, cw=cw, dw=dw, bw=hw - 1.0, sd=sd, y1=y1)


def half_ring(x):
    """the port half of the section at x, from the notch floor's centre round to the belly's centre: [(y, z)] (15 points)"""
    p = par(x)
    zt, nf, sd = p['zt'], p['nf'], p['sd']
    zl = nf + 0.45 * (zt - nf)
    c, c2 = 0.14, 0.16
    zd = zt - sd
    kt = min(p['kt'], zd - c - 0.05)
    return [(0.0, nf), (p['cf'], nf), (p['cf'], zl), (p['cl'], zl), (p['cl'], zt - 0.1), (p['cw'], zt), (p['y1'], zt), (p['y1'] + 0.001, zd),
            (p['dw'], zd), (p['dw'] + c, zd - c), (p['hw'], kt), (p['hw'], p['kb']), (p['bw'] + c2, p['zb'] + c2), (p['bw'], p['zb']), (0.0, p['zb'])]


def loop(x):
    h = half_ring(x)
    return h + [(-y, z) for (y, z) in reversed(h[1:-1])]


def ring(x):
    return [(x, y, z) for (y, z) in loop(x)]


# Edge indices of a 28-point ring (edge j joins point j and j + 1); the starboard twin of port edge j is 27 - j.
E_FLOOR, E_WALL1, E_LEDGE, E_WALL2, E_LIP, E_DECK, E_PITWALL, E_TERRACE, E_EDGE, E_UPPER, E_BAND, E_LOWER, E_CHINE, E_BELLY = range(14)


def both(*edges):
    return sorted({e for j in edges for e in (j, 27 - j)})


def area(pts):
    return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))


def offset_poly(pts, d):
    """a closed (y, z) polygon moved out by d (in by -d) along each vertex's mitred normal; the outward side from the winding,
    so the canyon's walls move the right way (a centroid rule would push them into the canyon)"""
    n = len(pts)
    s = 1.0 if area(pts) > 0 else -1.0
    out = []
    for i in range(n):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
        ns = []
        for a, b in ((p0, p1), (p1, p2)):
            ey, ez = b[0] - a[0], b[1] - a[1]; L = math.hypot(ey, ez)
            ns.append((s * ez / L, -s * ey / L) if L > 1e-9 else None)
        ns = [q for q in ns if q] or [(0.0, 1.0)]
        my = sum(q[0] for q in ns); mz = sum(q[1] for q in ns); L = math.hypot(my, mz) or 1.0
        my, mz = my / L, mz / L
        cosh = max(0.4, my * ns[0][0] + mz * ns[0][1])
        out.append((p1[0] + my * d / cosh, p1[1] + mz * d / cosh))
    return out


def signed_dist(pts, q):
    """distance from q to the closed polygon pts, negative inside"""
    y, z = q
    inside = False
    best = 1e9
    for a, b in zip(pts, pts[1:] + pts[:1]):
        if (a[1] > z) != (b[1] > z):
            yc = a[0] + (z - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            if yc > y:
                inside = not inside
        ey, ez = b[0] - a[0], b[1] - a[1]; L2 = ey * ey + ez * ez
        t = 0.0 if L2 < 1e-12 else max(0.0, min(1.0, ((y - a[0]) * ey + (z - a[1]) * ez) / L2))
        best = min(best, math.hypot(y - a[0] - t * ey, z - a[1] - t * ez))
    return -best if inside else best


def inner(x, inset=SHELL):
    return offset_poly(loop(x), -inset)


def intervals(x, z, inset=SHELL):
    """the y spans inside the inner skin at height z: one span across the lower hull, one in each ridge above the canyon floor"""
    pts = inner(x, inset)
    ys = []
    for a, b in zip(pts, pts[1:] + pts[:1]):
        if (a[1] > z) != (b[1] > z):
            ys.append(a[0] + (z - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
    ys.sort()
    return [(ys[i], ys[i + 1]) for i in range(0, len(ys) - 1, 2)]


def bridge_box(name, inset=0.0):
    for nm, xc, L in BRIDGES:
        if nm == name:
            return (xc - L / 2 + inset, xc + L / 2 - inset, -1.9 + inset, 1.9 - inset, BR_BOT + inset, BR_TOP - inset)


def inside_ok(p, inset=SHELL):
    """how far the point p sits outside the inner skin of the mass that holds it (<= 0 inside): the hull (the canyon is outside
    it) or a bridge deck"""
    x, y, z = p
    best = 9.0
    if XS + inset <= x <= XB:
        best = signed_dist(inner(x, inset), (y, z))
    for nm, _, _ in BRIDGES:
        x0, x1, y0, y1, z0, z1 = bridge_box(nm, inset)
        if x0 <= x <= x1:
            best = min(best, max(y0 - y, y - y1, z0 - z, z - z1))
    return best


def slope(tab, x, d=0.05):
    return (lerp_tab(tab, x + d) - lerp_tab(tab, x - d)) / (2 * d)


def surf(x, j, t=0.5, side=1, d=0.02):
    """a point on edge j of the port half-ring at station x (t along the edge) and the hull's outward normal there, the taper
    along x included (a fitting set on a tapering face sits flat on it); side -1 mirrors to starboard"""
    from mathutils import Vector

    def pt(x_):
        h = half_ring(x_)
        a, b = h[j], h[j + 1]
        return Vector((x_, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    p = pt(x)
    tx = pt(x + d) - pt(x - d)
    h = half_ring(x)
    te = Vector((0, h[j + 1][0] - h[j][0], h[j + 1][1] - h[j][1]))
    nrm = te.cross(tx).normalized()
    out = Vector((0, -te.z, te.y))   # the half-ring runs clockwise in (y, z): outward is the edge turned a quarter to its left
    if nrm.dot(out) < 0:
        nrm = -nrm
    if side < 0:
        p = Vector((p.x, -p.y, p.z)); nrm = Vector((nrm.x, -nrm.y, nrm.z))
    return p, nrm


def deck_z(x, y):
    """the top surface at (x, y): the notch floor, the ridge deck or the pit floor"""
    h = half_ring(x)
    ay = abs(y)
    if ay <= h[1][0]:
        return h[0][1]
    if ay <= h[5][0]:
        return h[5][1]
    if ay <= h[6][0]:
        return h[6][1]
    return h[7][1]


def belly_z(x):
    return lerp_tab(ZB, x)


def loft_closed(K, name, rings, m):
    """a solid through section rings with each end capped by real triangles: the section is concave (the canyon), and an n-gon
    cap would be fanned across the canyon by the fit check's triangle tree"""
    from mathutils import Vector
    from mathutils.geometry import delaunay_2d_cdt, tessellate_polygon
    n = len(rings[0])
    V = [tuple(v) for r in rings for v in r]
    F = []
    for i in range(len(rings) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            F.append((a, b, b + n, a + n))
    for k, r in ((0, rings[0]), (len(rings) - 1, rings[-1])):
        if k == 0:
            tris = tessellate_polygon([[Vector((0.0, v[1], v[2])) for v in r]])
        else:
            # The stern rim has collinear deck edges. Keep each edge in the cap
            # without zero-area faces that turn the inner shell out past the stern.
            profile = [Vector((v[1], v[2])) for v in r]
            _, _, cap, original, _, _ = delaunay_2d_cdt(profile, [], [list(range(n))], 1, 1e-6)
            assert sorted(original) == [[i] for i in range(n)], 'stern cap must use the existing rim'
            tris = [tuple(original[q][0] for q in triangle) for triangle in cap]
        o = k * n
        for t in tris:
            t = tuple(o + q for q in t)
            # face the cap outward: the first ring is the bow end (+X), the last the stern end (-X)
            a_, b_, c_ = (Vector(V[q]) for q in t)
            nx = (b_ - a_).cross(c_ - a_).x
            if (nx < 0) == (k == 0):
                t = t[::-1]
            F.append(t)
    return K._obj(name, V, F, m)


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Hegemony colour zones live in the faction kit (tools/blender/kits/hegemony)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(x, lerp_tab(HW, x), lerp_tab(HW, x), lerp_tab(ZB, x), lerp_tab(ZT, x), 0.0, 0.0) for x in (XS, -6.5, -1.0, 6.0, 11.0, XF)]
    K.hull_rounded = False
    plate_jobs = []

    # ---------------- the hull: one loft from the stern face to the trench's back wall ----------------
    xs = {x / 4 for x in range(int(XS * 4), int(XB * 4) + 1)} | {XS, XB, CAN0 - 0.02, CAN0, CAN1 - 0.02, CAN1} | set(PIT) | {h[0] for h in HW}
    xs = sorted([x for x in xs if XS <= x <= XB], reverse=True)
    hull = loft_closed(K, CODE + '_hull', [ring(x) for x in xs], 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the broad wedge with its canyon', hull, 'pale grey module plate',
           note='one broad wedge hull: two raised armoured ridges and the canyon cut deep between them, its walls stepped by a ledge; a flat deck on each ridge, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a chine, a flat belly; the shoulder pits where the lances sit low')
    K.mark('hull', 'hull', ['facet', 'step', 'chamfer'])
    # panels on an even grid: rings at the module pitch (0.6) from the bow, so seams run straight and line up across every face
    grid = [XB - 0.1 - 0.6 * i for i in range(46)]
    grid = [x for x in grid if x >= XS + 0.05] + [XS + 0.05]
    grid = [x for x in grid if not (CAN0 - 0.08 < x < CAN0 + 0.06 or CAN1 - 0.08 < x < CAN1 + 0.06)]
    rg = [ring(x) for x in grid]
    plate_jobs.append(('deck', rg, dict(faces=both(E_DECK, E_TERRACE), inv='deck_panels')))
    plate_jobs.append(('canyon', rg, dict(faces=both(E_FLOOR, E_WALL1, E_LEDGE, E_WALL2), inv='canyon_panels')))
    plate_jobs.append(('flank', rg, dict(faces=both(E_UPPER, E_LOWER), inv='flank_panels')))
    plate_jobs.append(('belly', rg, dict(faces=both(E_BELLY), inv='belly_panels')))

    # ---------------- the bow: a blunt armoured face round the ion trench (R183 (1)) at the canyon's mouth ----------------
    tw, th, tz = TRENCH['w'] / 2, TRENCH['h'] / 2, TRENCH['zc']

    def rect_match(lp):
        """the trench mouth's rectangle, sampled where a ray from the mouth centre meets it, the ray's angle kept monotone round
        the loop (the notch would fold it back)"""
        out, prev = [], None
        for (y, z) in lp:
            a = math.atan2(z - tz, y)
            if prev is not None:
                while a > prev + 1e-9:
                    a -= 2 * math.pi
                while a < prev - 2 * math.pi:
                    a += 2 * math.pi
            prev = a
            dy, dz = math.cos(a), math.sin(a)
            k = min(tw / abs(dy) if abs(dy) > 1e-9 else 1e9, th / abs(dz) if abs(dz) > 1e-9 else 1e9)
            out.append((dy * k, tz + dz * k))
        for cy, cz in ((tw, tz + th), (tw, tz - th), (-tw, tz - th), (-tw, tz + th)):   # each corner taken by its nearest point
            i_ = min(range(len(out)), key=lambda q: math.hypot(out[q][0] - cy, out[q][1] - cz))
            out[i_] = (cy, cz)
        return out
    xs_b = [XB, 13.8, 14.6, XF]
    V, F = [], []
    loops = [loop(x) for x in xs_b]
    inn = rect_match(loop(XF))
    n = len(inn)
    for x, lp in zip(xs_b, loops):
        V += [(x, y, z) for (y, z) in lp]
    for x in xs_b:
        V += [(x, y, z) for (y, z) in inn]
    m = len(xs_b)
    for k in range(m - 1):
        for i in range(n):
            j = (i + 1) % n
            F.append((k * n + i, k * n + j, (k + 1) * n + j, (k + 1) * n + i))
            F.append(((m + k) * n + j, (m + k) * n + i, (m + k + 1) * n + i, (m + k + 1) * n + j))
    for i in range(n):
        j = (i + 1) % n
        F.append(((m - 1) * n + i, (m - 1) * n + j, (2 * m - 1) * n + j, (2 * m - 1) * n + i))   # the bow face
        F.append((j, i, m * n + i, m * n + j))                                                   # its back, on the hull's end
    bowf = K._obj(CODE + '_bowframe', V, F, 'hgrey', grp='hull')
    K.mass('Bow face round the ion trench', bowf, 'pale grey module plate',
           note='the blunt bow face (never a ship\'s stem): the ridge ends and the bow deck run to it, the trench recessed in its middle under the bow deck, at the canyon\'s mouth')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    for (y0, y1, z0, z1) in ((-tw - 0.12, tw + 0.12, tz + th + 0.04, tz + th + 0.32), (-tw - 0.12, tw + 0.12, tz - th - 0.32, tz - th - 0.04),
                             (tw + 0.04, tw + 0.5, tz - th + 0.02, tz + th - 0.02), (-tw - 0.5, -tw - 0.04, tz - th + 0.02, tz + th - 0.02)):
        K.box('IM5_bowplate_%d' % len(K.masses), XF - 0.02, XF + 0.06, y0, y1, z0, z1, 'hpanel', ch=0.02, grp='hull')
    K.box('IM5_bowtrim_t', XF, XF + 0.08, -tw - 0.04, tw + 0.04, tz + th, tz + th + 0.04, 'htrim', grp='hull')
    K.box('IM5_bowtrim_b', XF, XF + 0.08, -tw - 0.04, tw + 0.04, tz - th - 0.04, tz - th, 'htrim', grp='hull')
    for s_ in (1, -1):
        K.box('IM5_bowtrim_%s' % ('p' if s_ > 0 else 's'), XF, XF + 0.08, tw if s_ > 0 else -tw - 0.04, tw + 0.04 if s_ > 0 else -tw, tz - th, tz + th, 'htrim', grp='hull')
    ion_trench(K, (XB, 0.0, tz), XF - XB, TRENCH['w'], TRENCH['h'], coils=8, r=0.45)

    # ---------------- the stern face: a trim frame round the nozzle row ----------------
    K.box('IM5_sterntrim_t', XS - 0.05, XS + 0.02, -4.5, 4.5, 0.62, 0.7, 'htrim', grp='hull')
    K.box('IM5_sterntrim_b', XS - 0.05, XS + 0.02, -4.5, 4.5, -1.2, -1.12, 'htrim', grp='hull')
    # one flat row of six rectangular nozzle pods across the whole stern, on one datum (factions.md)
    for k, y in enumerate((3.75, 2.25, 0.75, -0.75, -2.25, -3.75)):
        K.engine('E%d' % (k + 1), (XE, y, -0.25), 0.62, XS - XE + 0.05, bell=1.0, body_r=0.75, kw=dict(w=1.1, h=1.45),
                 inv='engines', note='nozzle %d of the row (port to starboard): a rectangular nozzle pod, blue-white throat' % (k + 1))
        K.features[-1]['what'] = 'engine, rectangular nozzle 1.1 x 1.45'

    # ---------------- the three bridge decks across the canyon, flush with the ridge decks ----------------
    for nm, xc, L in BRIDGES:
        x0, x1 = xc - L / 2, xc + L / 2
        sec = [(x1, BR_TOP), (x0, BR_TOP), (x0, BR_TOP - 0.3), (x0 + 0.22, BR_BOT), (x1 - 0.22, BR_BOT), (x1, BR_TOP - 0.3)]
        rings_b = [[(x, y, z) for (x, z) in sec] for y in (1.9, -1.9)]
        ob = K.loft_rings('IM5_bridge_%s' % nm, rings_b, 'hgrey')
        K.mass('Bridge deck, %s' % nm, ob, 'pale grey module plate',
               note='a low armoured bridge deck spanning the canyon, its top flush with the ridge decks (never above them: no naval read), its underside chamfered, a crossing corridor inside')
        for sg in (1, -1):   # the trim band and the blue strip along each face of the bridge
            xf = x1 if sg > 0 else x0
            K.box('IM5_bridgetrim_%s%s' % (nm, 'f' if sg > 0 else 'a'), xf - 0.03 if sg > 0 else xf - 0.05, xf + 0.05 if sg > 0 else xf + 0.03,
                  -1.85, 1.85, BR_TOP - 0.2, BR_TOP - 0.12, 'htrim', grp='hull')
            K.strip('IM5_blue_br_%s%s' % (nm, 'f' if sg > 0 else 'a'), [(xf, 1.7, BR_TOP - 0.42), (xf, -1.7, BR_TOP - 0.42)], w=0.06, t=0.025,
                    normals=[(sg, 0, 0)] * 2, m='hblue', grp='hull')
        for k, yy in enumerate((1.0, -1.0)):   # two girders under each bridge (the deck's structure)
            K.box('IM5_bridgegirder_%s%d' % (nm, k), x0 + 0.35, x1 - 0.35, yy - 0.12, yy + 0.12, BR_BOT - 0.14, BR_BOT + 0.02, 'hgrey2', grp='hull')
        # flush top panels on the bridge in the hull's grid (0.6 along, 0.45 across)
        nx = max(1, int(round(L / 0.6))); ny = 8
        tops = {'hgrey': ([], []), 'hpanel': ([], [])}
        for i in range(nx):
            for j in range(ny):
                xa = x0 + 0.1 + (L - 0.2) * i / nx + 0.03; xb_ = x0 + 0.1 + (L - 0.2) * (i + 1) / nx - 0.03
                ya = -1.8 + 3.6 * j / ny + 0.03; yb = -1.8 + 3.6 * (j + 1) / ny - 0.03
                pc = Vector(((xa + xb_) / 2, (ya + yb) / 2, BR_TOP))
                if any((pc - c).length < r + 0.15 for c, r in K.keepouts):
                    continue
                mk = 'hpanel' if (i % 3 == 1 and min(j, ny - 1 - j) % 2 == 0) else 'hgrey'
                Vq, Fq = HP.panel_slab([(xa, ya, BR_TOP), (xb_, ya, BR_TOP), (xb_, yb, BR_TOP), (xa, yb, BR_TOP)], (0, 0, 1), 0.03 if mk == 'hgrey' else 0.022)
                bv, bf = tops[mk]; o = len(bv); bv.extend(Vq); bf.extend(tuple(q + o for q in f) for f in Fq)
        for mk, (Vq, Fq) in tops.items():
            if Vq:
                K._obj('IM5_bridge_%s_panels_%s' % (nm, mk), Vq, Fq, mk, grp='hull')
    K.mark('bridges', 'tier', ['face', 'roof', 'opening'])

    # ---------------- module bands: the joints where the hull gives way (factions.md "How it breaks") ----------------
    for i, x in enumerate(BANDS):
        lp = loop(x)
        for k, (a, b) in enumerate(((x + 0.13, x + 0.03), (x - 0.03, x - 0.13))):
            V_, F_ = [], []
            o_, i_ = offset_poly(lp, 0.07), offset_poly(lp, -0.03)
            nn = len(lp)
            V_ = [(b, y, z) for (y, z) in o_] + [(a, y, z) for (y, z) in o_] + [(b, y, z) for (y, z) in i_] + [(a, y, z) for (y, z) in i_]
            for q in range(nn):
                r_ = (q + 1) % nn
                F_ += [(q, r_, nn + r_, nn + q), (2 * nn + r_, 2 * nn + q, 3 * nn + q, 3 * nn + r_), (r_, q, 2 * nn + q, 2 * nn + r_), (nn + q, nn + r_, 3 * nn + r_, 3 * nn + q)]
            K._obj('IM5_band_%d_%d' % (i, k), V_, F_, 'htrim', grp='hull')
        o_, i_ = offset_poly(lp, 0.025), offset_poly(lp, -0.03)
        nn = len(lp)
        V_ = [(x - 0.04, y, z) for (y, z) in o_] + [(x + 0.04, y, z) for (y, z) in o_] + [(x - 0.04, y, z) for (y, z) in i_] + [(x + 0.04, y, z) for (y, z) in i_]
        F_ = []
        for q in range(nn):
            r_ = (q + 1) % nn
            F_ += [(q, r_, nn + r_, nn + q), (2 * nn + r_, 2 * nn + q, 3 * nn + q, 3 * nn + r_), (r_, q, 2 * nn + q, 2 * nn + r_), (nn + q, nn + r_, 3 * nn + r_, 3 * nn + q)]
        K._obj('IM5_bandseam_%d' % i, V_, F_, 'hgrey2', grp='hull')
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line: implant-blue strips along both flank bands, broken at the module bands ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        cuts = sorted([XB - 0.15] + [b + d for b in BANDS for d in (0.2, -0.2)] + [XS + 0.1], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa, xb_ = cuts[k], cuts[k + 1]
            pts = []
            nseg = max(2, int((xa - xb_) / 0.5))
            for j in range(nseg + 1):
                x = xa + (xb_ - xa) * j / nseg
                h = half_ring(x)
                pts.append((x, side * (h[10][0] + 0.003), (h[10][1] + h[11][1]) / 2))
            K.strip('IM5_blue_%s%d' % (sn, k), pts, w=0.08, t=0.025, normals=[(0, side, 0)] * len(pts), m='hblue', grp='hull')
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- weapons ----------------
    tx, ty = TURRET
    for side in (1, -1):
        sn = 'P' if side > 0 else 'S'
        zf = deck_z(tx, side * ty)
        K.keepouts.append((Vector((tx, side * ty, zf)), 1.5))
        K.gun('H%s' % sn, (tx, side * ty, zf), 60 * side, 0.0, barrels=2, cal=0.13, blen=1.35, size=1.15, slot=sn, weapon='hturbo', inv='lances',
              note='%s shoulder lance turret: the heavy plasma lance (hturbo %s, 3 shots), a low wide mount sunk in the shoulder pit, two short thick barrels' % (
                  'port' if side > 0 else 'starboard', sn))
    # the pits' inner walls get a trim lip
    for side in (1, -1):
        y_ = 2.8
        K.box('IM5_pitlip_%s' % ('p' if side > 0 else 's'), PIT[2], PIT[3], y_ - 0.05 if side > 0 else -y_ - 0.03, y_ + 0.03 if side > 0 else -y_ + 0.05,
              1.8 - 0.42, 1.8 + 0.025, 'htrim', grp='hull')
    xm = [b for b in BRIDGES if b[0] == 'mid'][0][1]
    K.keepouts.append((Vector((xm, 0, BR_TOP)), 1.3))
    K.gun('T1', (xm, 0.0, BR_TOP), 0.0, 0.0, barrels=2, cal=0.1, blen=1.0, size=0.95, slot='T', weapon='turbo', inv='bridge_lance',
          note='the plasma lance on the midships bridge (turbo T, 2 shots): the same low lance mount at a smaller size, turning all round over the ridge decks')
    xsb = [b for b in BRIDGES if b[0] == 'stern'][0][1]
    K.keepouts.append((Vector((xsb, 0, BR_TOP)), 0.8))
    K.gun('F1', (xsb, 0.0, BR_TOP), 0.0, 10.0, barrels=2, cal=0.065, blen=0.48, size=0.85, slot='T', weapon='flak', inv='pickets',
          note='the picket lasers on the stern bridge (flak T, 3 shots over 2 emitters, both fire every volley): point defence over the stern quarter')

    # ---------------- the sensor fin (one low fin, never a tower), on the bow deck ----------------
    K.antenna('A1', (12.15, 0.0, NF_BOW), 0.5, whips=0, inv='sensor_fin',
              note='the one low sensor fin on the bow deck ahead of the canyon: sensor windows and a lens strip; low enough that the bridge lance fires over it (R240)')
    K.features[-1]['what'] = 'sensor fin, 0.5 tall, 2.4 long'

    # ---------------- the canyon machinery: real plant with a job (issue 768) ----------------
    def organ(fid, part, x, what, kind, note, inv):
        K.organ(fid, part, (x, 0.0, NF_CAN), (0, 0, 1), fwd=(1, 0, 0), inv=inv, what=what, kind=kind, note=note)
    organ('CB1', HP.capbank(4, 2.2, 1.2, 0.55), 8.3, 'capacitor bank (4 cells)', 'capbank', 'the ion cannon\'s charge banks: four identical cells, a bus bar to the trench', 'capbanks')
    organ('CB2', HP.capbank(3, 1.5, 1.2, 0.55), 2.45, 'capacitor bank (3 cells)', 'capbank', 'the ion cannon\'s second charge bank, on the main power trunks', 'capbanks')
    organ('HX1', HP.exchanger(1.4, 1.2, 0.6, 9), -1.75, 'heat exchanger', 'exchanger', 'the reactor\'s coolant exchanger: its heat leaves the hull in the open canyon', 'exchangers')
    organ('HX2', HP.exchanger(1.4, 1.2, 0.6, 9), -5.3, 'heat exchanger', 'exchanger', 'the reactor\'s second coolant exchanger', 'exchangers')
    organ('HX3', HP.exchanger(1.4, 1.2, 0.6, 9), -7.5, 'heat exchanger', 'exchanger', 'the drives\' coolant exchanger, over the engine feeds', 'exchangers')
    organ('HX4', HP.exchanger(1.2, 1.2, 0.6, 7), -10.4, 'heat exchanger', 'exchanger', 'the drives\' second coolant exchanger, under the stern bridge\'s aft edge', 'exchangers')
    ends = [CAN1 - 0.3] + sorted(BANDS, reverse=True) + [CAN0 + 0.05]
    k = 0
    for a, b in zip(ends, ends[1:]):
        xa, xb_ = (a - 0.3 if a in BANDS else a), (b + 0.3 if b in BANDS else b + 0.25)
        if xa - xb_ < 0.6:
            continue
        for side in (1, -1):
            K.pipe('PT%d%s' % (k, 'p' if side > 0 else 's'), [(xa, side * 1.05, NF_CAN + 0.28), (xb_, side * 1.05, NF_CAN + 0.28)], r=0.16, inv='trunks',
                   note='armoured power trunk: the reactor\'s power forward to the ion cannon and aft to the drives, coupled at each module band')
            K.features[-1]['what'] = 'power trunk, %.1f long' % (xa - xb_)
        k += 1

    # coolant lines along the canyon's ledges: the exchangers' loops out to the ridges' plant rooms, one length per stretch between
    # the module bands and the bridges (they stop short of both, coupled with flanges)
    stops = sorted([(b - 0.3, b + 0.3) for b in BANDS] + [(xc - L / 2 - 0.2, xc + L / 2 + 0.2) for _, xc, L in BRIDGES])
    runs, x_ = [], CAN0 + 0.3
    for a, b in stops:
        if a > x_ + 0.6:
            runs.append((x_, a))
        x_ = max(x_, b)
    if CAN1 - 0.3 > x_ + 0.6:
        runs.append((x_, CAN1 - 0.3))
    for k, (a, b) in enumerate(runs):
        for side in (1, -1):
            def zl(x):
                return NF_CAN + 0.45 * (lerp_tab(ZT, x) - NF_CAN) + 0.17
            K.pipe('CL%d%s' % (k, 'p' if side > 0 else 's'), [(b, side * 1.64, zl(b)), (a, side * 1.64, zl(a))], r=0.07, inv='coolant_lines',
                   note='coolant line on the canyon ledge: the exchangers\' loop out to the ridges\' plant rooms')
            K.features[-1]['what'] = 'coolant line, %.1f long' % (b - a)
    # the engine room's control windows on the stern deck's fore face, overlooking the canyon (IM5's blue-lit canyon end)
    for k, y in enumerate((1.05, 0.35, -0.35, -1.05)):
        K.slit('WC%d' % (k + 1), (CAN0 - 0.01 + 0.012, y, 0.95), (1, 0, 0), 0.5, 0.2, inv='windows', note='a control window of the engine room, overlooking the canyon')

    # ---------------- the belly: an armour step under the hull ----------------
    belly = []
    for x, kk in ((13.0, 0.0), (12.4, 1.0), (6.0, 1.0), (-6.5, 1.0), (-12.0, 1.0), (-13.4, 1.0), (-13.9, 0.0)):
        zb = belly_z(x); bw = par(x)['bw'] - 0.7
        belly.append([(x, bw, zb + 0.02), (x, bw - 0.12 * kk, zb - 0.12 * kk), (x, -bw + 0.12 * kk, zb - 0.12 * kk), (x, -bw, zb + 0.02)])
    K.mass('Belly armour step', K.loft_rings('IM5_belly', belly, 'hgrey2'), 'recessed grey', note='a second armour layer under the hull (a worked belly)')
    plate_jobs.append(('belly_step', belly, dict(faces=[1], inv='belly_panels', closed=False)))

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.thruster('Q1' + sn, (XF, side * 2.05, -0.35), (1, 0, 0), inv='thrusters', r=0.3, note='retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap)')
        K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        for q, x in (('Q2', 11.6), ('Q3', -12.9)):
            h = half_ring(x)
            p = Vector((x, side * (h[9][0] + h[10][0]) / 2, (h[9][1] + h[10][1]) / 2))
            nrm = Vector((0, side * (h[9][1] - h[10][1]), h[10][0] - h[9][0])).normalized()
            K.thruster(q + sn, tuple(p), tuple(nrm), inv='thrusters', r=0.28, note='%s attitude thruster on the upper facet' % ('bow' if x > 0 else 'stern'))
            K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        for i, x in enumerate((8.9, 8.1, 7.3, 4.0, 3.2, -2.0, -2.8, -7.6, -8.4, -9.2)):
            p, nrm = surf(x, E_BAND, 0.25, side)
            K.slit('W%d%s' % (i + 1, sn), tuple(p + nrm * 0.01), tuple(nrm), 0.45, 0.1, inv='windows',
                   note='blue-white window of the ridge\'s crew decks')
        # deck louvres on the ridge decks, along the length, centred in their modules
        for i, x in enumerate((8.3, 3.0, -8.9)):
            K.vent('V%d%s' % (i + 1, sn), (x, side * 3.3, deck_z(x, 3.3)), (-slope(ZT, x), 0, 1), 0.34, 1.4, slats=7, inv='vents',
                   note='heat louvre on the ridge deck over the %s' % ('crew decks' if x > -5 else 'drive coolant plant'))
        K.vent('V4' + sn, (-13.3, side * 2.6, deck_z(-13.3, 2.6)), (0, 0, 1), 0.34, 1.1, slats=6, inv='vents', note='heat louvre over the engine room')
        for i, x in enumerate((7.6, -8.0)):
            p, nrm = surf(x, E_LOWER, 0.5, side)
            K.hatch('H7%d%s' % (i, sn), tuple(p + nrm * 0.004), tuple(nrm), 0.6, 0.42, inv='hatches', note='flank hatch on the lower facet: stores to the lower deck')
        for i, xb_ in enumerate(BANDS):
            for d in (0.32, -0.32):
                x = xb_ + d
                if PIT[0] - 0.3 < x < PIT[5] + 0.3:
                    continue
                pp = par(x); yl = (pp['cw'] + pp['dw']) / 2
                K.organ('L%d%s%s' % (i, sn, 'f' if d > 0 else 'a'), HP.latch(), (x, side * yl, deck_z(x, yl)), (-slope(ZT, x), 0, 1), fwd=(1, 0, 0), inv='latches',
                        what='module latch row (4 clamps)', kind='latch', note='locks two hull modules together across the band')
    K.hatch('H1', (5.55, 2.6, deck_z(5.55, 2.6)), (0, 0, 1), 0.6, 0.45, inv='hatches', note='deck hatch over the port ridge\'s forward crew deck')
    K.hatch('H2', (5.55, -2.6, deck_z(5.55, -2.6)), (0, 0, 1), 0.6, 0.45, inv='hatches', note='deck hatch over the starboard ridge\'s forward crew deck')
    K.hatch('H3', (4.0, 0.0, belly_z(4.0) - 0.12), (0, 0, -1), 0.8, 0.5, inv='hatches', note='belly hatch on the armour step: stores')
    K.hatch('H4', (-3.4, 0.0, belly_z(-3.4) - 0.12), (0, 0, -1), 0.8, 0.5, inv='hatches', note='belly hatch on the armour step: the reactor\'s service hatch')
    K.hatch('H5', (-9.0, 0.0, belly_z(-9.0) - 0.12), (0, 0, -1), 0.8, 0.5, inv='hatches', note='belly hatch on the armour step: the engine room\'s stores')
    K.hatchbox('HB1', (-13.3, 0.0, deck_z(-13.3, 0)), 0.9, 1.0, 0.26, inv='lift_heads', note='the stern lift head: stores up to the engine room')

    # ---------------- colour zones ----------------
    K.colour('steel blue-grey module plate, steel-blue trim (paint stage)', XF, XE, 'whole hull')
    K.colour('implant-blue light strips (the blue line, the bridge faces), blue-white nozzles and windows', XF, XE, 'the flank bands, the bridges, the stern')
    K.colour('no rust, no warm light, no asymmetry', XF, XE, 'factions.md Never')

    # ---------------- INSIDE: white corridors, blue emergency light, racks of identical equipment ----------------
    IN = SHELL + 0.06

    def spans(x0, x1, z):
        """the y spans inside the skin at height z, over the whole of x0..x1 (the narrowest at the three stations)"""
        sp = [intervals(x, z, IN) for x in (x0, (x0 + x1) / 2, x1)]
        k_ = min(len(s) for s in sp)
        out = []
        for i in range(k_):
            out.append((max(s[i][0] for s in sp), min(s[i][1] for s in sp)))
        return out

    def slab(name, z, x0, x1, kind_name):
        for i, (ya, yb) in enumerate(spans(x0, x1, z - 0.05)):
            sp2 = spans(x0, x1, z + 0.05)
            if i < len(sp2):
                ya, yb = max(ya, sp2[i][0]), min(yb, sp2[i][1])
            if yb - ya < 0.3:
                continue
            rs = [[(x, yb - 0.02, z - 0.04), (x, yb - 0.02, z + 0.04), (x, ya + 0.02, z + 0.04), (x, ya + 0.02, z - 0.04)] for x in (x0, x1)]
            K.loft_rings('in_deck_%s_%d' % (name, i), rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))

    def frame_at(name, x):
        """a frame ring inside the skin at station x, round the U of the section (the canyon stays open), split into plates"""
        fo = inner(x, IN + 0.08); fi = inner(x, IN + 0.2)   # 0.08 more: the frame is 0.12 thick along a tapering hull
        V, F = [], []
        nn = len(fo)
        for k_ in range(nn):
            a_, b_ = k_, (k_ + 1) % nn
            if math.hypot(fo[b_][0] - fo[a_][0], fo[b_][1] - fo[a_][1]) < 1e-4:
                continue
            q = [fo[a_], fo[b_], fi[b_], fi[a_]]
            o = len(V)
            V += [(x + 0.06, y_, z_) for (y_, z_) in q] + [(x - 0.06, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def room(name, kind, x0, x1, z0, z1, which='all', ymin=None, ymax=None, note=''):
        """a room in the lower hull ('low', across), or one in each ridge ('ridge', port and starboard), clear of the skin"""
        sp = [s for s in (spans(x0, x1, z0) if spans(x0, x1, z0) else [])]
        sp1 = spans(x0, x1, z1)
        if which == 'low':
            ya, yb = max(sp[0][0], sp1[0][0]) + 0.05, min(sp[0][1], sp1[0][1]) - 0.05
            if ymax is not None:
                ya, yb = max(ya, -ymax), min(yb, ymax)
            assert yb - ya > 0.3 and ya < 0 < yb, 'room %s is not across the lower hull (%.2f to %.2f)' % (name, ya, yb)
            K.room(name, kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
            return
        for side in (1, -1):
            cand = [s for s in sp if (s[0] + s[1]) * side > 0.5]
            cand1 = [s for s in sp1 if (s[0] + s[1]) * side > 0.5]
            if not cand or not cand1:
                continue
            ya, yb = max(cand[0][0], cand1[0][0]) + 0.05, min(cand[0][1], cand1[0][1]) - 0.05
            if ymin is not None:
                ya, yb = (max(ya, ymin), yb) if side > 0 else (ya, min(yb, -ymin))
            assert yb - ya > 0.3, 'room %s has no width (%.2f to %.2f)' % (name, ya, yb)
            K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)

    # compartments by the transverse seams (B-1 at 10.2, B-2 at 1.2, B-3 at -6.4, B-4 at -11.4): every inside stays in one
    # the bow compartment (13.0 to 10.2): under the bow deck, behind the trench
    slab('bow_lower', -0.55, 12.7, 10.5, 'lower')
    frame_at('F1', 12.2); frame_at('F2', 11.0)
    room('ion_capacitors', 'machinery', 12.75, 10.5, -0.75, 0.6, which='low', ymax=1.3, note='the ion cannon\'s field drivers behind the trench')
    room('bow_corridor', 'hcorr', 12.6, 10.5, 0.75, 1.05, which='ridge', note='white corridors at the ridges\' bow ends')
    # the forward compartment (10.2 to 1.2): crew decks in the ridges, racks and the command deck in the lower hull
    slab('fwd_main', 0.7, 9.9, 1.5, 'main')
    slab('fwd_lower', -0.95, 9.9, 1.5, 'lower')
    for i, x in enumerate((9.0, 7.6, 6.4, 5.0, 3.6, 2.2)):
        frame_at('F%d' % (i + 3), x)
    room('fwd_crew', 'hcorr', 9.8, 6.6, 0.8, 1.2, which='ridge', note='white corridors and crew berths of the ridges, numbered posts')
    room('fwd_crew2', 'hcorr', 6.2, 1.6, 0.8, 1.3, which='ridge', note='white corridors and crew berths of the ridges')
    room('command', 'bridge', 6.2, 3.8, -0.85, -0.3, which='low', ymax=2.2, note='the command deck: the Registry link room, under the bow bridge')
    for k_ in range(6):
        x0 = 9.7 - k_ * 0.5
        room('rack_%d' % k_, 'hrack', x0, x0 - 0.36, -0.85, -0.25, which='low', ymax=2.6, note='racks of identical equipment on the lower deck (factions.md "Inside")')
    room('ion_feed', 'machinery', 3.4, 1.6, -0.85, -0.3, which='low', ymax=2.4, note='the ion cannon\'s feed switching, under the second capacitor bank')
    room('fwd_stores', 'hold', 7.6, 1.6, -1.55, -1.1, which='low', ymax=3.0, note='stores and the retro thrusters\' feeds')
    room('emerg_fwd', 'hemerg', 9.6, 1.8, 1.15, 1.2, which='ridge', note='the blue emergency light strip along the corridor ceilings')
    # the midships compartment (1.2 to -6.4): the reactor, the lance rooms, the bridge lance's feed
    slab('mid_main', 0.7, 0.9, -6.1, 'main')
    slab('mid_lower', -0.95, 0.9, -6.1, 'lower')
    for i, x in enumerate((0.3, -1.0, -2.4, -3.4, -4.4, -5.8)):
        frame_at('F%d' % (i + 9), x)
    room('reactor', 'core', -1.1, -5.7, -1.6, -0.3, which='low', ymax=1.6, note='the reactor (hp_core): its power rides the trunks forward to the trench and aft to the drives')
    room('lance_rooms', 'magazine', -2.0, -4.8, 0.3, 0.95, which='ridge', ymin=2.9, note='the lance capacitor rooms under the shoulder pits')
    room('mid_crew', 'hcorr', 0.9, -1.2, 0.8, 1.3, which='ridge', note='white corridors of the ridges, midships')
    room('mid_racks', 'hrack', 0.9, -0.9, -0.85, -0.25, which='low', ymax=2.6, note='racks of identical equipment')
    room('turbo_feed', 'magazine', -5.0, -5.9, -0.85, -0.25, which='low', ymax=2.0, note='the bridge lance\'s capacitor feed, up through the midships bridge')
    room('emerg_mid', 'hemerg', 0.8, -1.15, 1.25, 1.3, which='ridge', note='the blue emergency light strip')
    # the aft compartment (-6.4 to -11.4): the drive coolant plant, the picket store, crew decks
    slab('aft_main', 0.7, -6.7, -11.1, 'main')
    slab('aft_lower', -0.95, -6.7, -11.1, 'lower')
    for i, x in enumerate((-7.2, -8.6, -10.0, -10.9)):
        frame_at('F%d' % (i + 15), x)
    room('aft_crew', 'hcorr', -6.7, -11.0, 0.8, 1.3, which='ridge', note='white corridors and crew decks')
    room('drive_plant', 'machinery', -6.7, -11.0, -1.6, -0.3, which='low', ymax=2.8, note='the drives\' coolant and fuel plant')
    room('picket_store', 'magazine', -8.3, -9.7, 0.15, 0.6, which='ridge', ymin=2.4, note='the picket lasers\' power cells, fed across the stern bridge')
    room('emerg_aft', 'hemerg', -6.8, -11.0, 1.25, 1.3, which='ridge', note='the blue emergency light strip')
    # the stern compartment (-11.4 to -14.3): the engine room
    slab('stern_lower', -0.95, -11.7, -14.0, 'lower')
    frame_at('F19', -12.6); frame_at('F20', -13.6)
    room('engine_room', 'engroom', -12.65, -14.0, -1.55, 1.05, which='low', ymax=4.0, note='the engine room under the stern deck: the feeds to the six nozzles')
    room('engine_room_fwd', 'engroom', -11.75, -12.5, -1.55, -0.3, which='low', ymax=3.6, note='the engine room\'s forward bay under the canyon floor')
    # the bridges' crossing corridors
    for nm, xc, L in BRIDGES:
        K.room('bridge_corr_%s' % nm, 'hcorr', xc - L / 2 + 0.4, xc + L / 2 - 0.4, -1.5, 1.5, BR_BOT + 0.33, BR_TOP - 0.33,
               note='the crossing corridor inside the %s bridge deck, from ridge to ridge' % nm)
    K.armour('ridge decks and facets', 0.25, 'machined plate in modules, flush panels over it')
    K.armour('canyon walls and floor', 0.25, 'the canyon floor carries the plant; its walls shield it')
    K.armour('shoulder pits', 0.35, 'the lance turrets\' pits')
    K.armour('bow face', 0.45, 'the blunt bow round the trench, the thickest plate')
    K.armour('bridge decks', 0.25, '')
    K.armour('belly and armour step', 0.3, '')
    # seams: in modules, at the bulkhead rings between them, like a spine coming apart (factions.md "How it breaks"); every path runs
    # on straight past both flanks and kinks between them (never a straight cut, R186); no machine on a seam (R226)
    R = 8.0
    K.break_line('B-1', 10.2, 'the bow module tears off at the first module band: the trench, the fin and the field drivers with it',
                 path=[(10.2, R), (10.2, 4.2), (10.32, 2.6), (10.08, 1.0), (10.3, -0.6), (10.1, -2.2), (10.2, -4.2), (10.2, -R)])
    K.break_line('B-2', 1.2, 'the forward module parts from midships at the second band, the canyon floor torn across between the second bank and the exchanger',
                 path=[(1.2, R), (1.2, 5.8), (1.32, 4.0), (1.08, 2.2), (1.3, 0.4), (1.1, -1.6), (1.28, -3.6), (1.2, -5.8), (1.2, -R)])
    K.break_line('B-3', -6.4, 'midships parts from the aft module behind the shoulder pits, the reactor\'s bite ragged',
                 path=[(-6.4, R), (-6.4, 6.0), (-6.28, 4.4), (-6.52, 2.6), (-6.3, 0.8), (-6.5, -1.0), (-6.3, -2.8), (-6.5, -4.4), (-6.4, -6.0), (-6.4, -R)])
    K.break_line('B-4', -11.4, 'the stern module and the nozzle row fall away at the last band',
                 path=[(-11.4, R), (-11.4, 5.6), (-11.3, 3.8), (-11.5, 2.0), (-11.32, 0.2), (-11.5, -1.6), (-11.3, -3.6), (-11.4, -5.6), (-11.4, -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: white corridors, blue emergency light, racks of identical equipment, the command deck, the lance rooms, the reactor, the drive plant, the engine room, the bridges\' crossing corridors. The canyon is open space, never filled. The Hegemony breaks in modules at the bulkhead rings (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).'))
    K.point('core', 'hp_core', (-3.4, 0, -1.0))
    # eight breach anchors on the module joints (Super-dreadnought base 8, Hegemony +0; HARDPOINTS.md), in the export's order:
    # prow P, prow S, prow P, mid S, mid P, mid S, eng P, eng S (tools/blender/kits/shared/hardpoints.py breach_layout)
    for i, (x, sec, side) in enumerate(((10.2, 'prow', 1), (10.2, 'prow', -1), (6.4, 'prow', 1), (1.2, 'mid', -1), (1.2, 'mid', 1), (-0.6, 'mid', -1),
                                        (-6.4, 'eng', 1), (-11.4, 'eng', -1))):
        h = half_ring(x); y, z = h[10][0], (h[10][1] + h[11][1]) / 2 + 0.25
        K.point('breach', 'hp_breach_%d' % i, (x, side * (y + 0.08), z), side='port' if side > 0 else 'stbd', section=sec, note='on a module joint')
    for i, side in enumerate((1, -1)):
        K.point('rcs', 'hp_rcs_%d' % i, (XF + 0.1, side * 2.05, -0.35), side='port' if side > 0 else 'stbd')
        h = half_ring(-12.9)
        K.point('rcs', 'hp_rcs_%d' % (i + 2), (-12.9, side * (h[10][0] + 0.2), h[10][1] + 0.3), side='port' if side > 0 else 'stbd')
        h = half_ring(-2.4)
        K.point('board', 'hp_board_%d' % i, (-2.4, side * (h[10][0] + 0.05), (h[10][1] + h[11][1]) / 2), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        for b in BANDS:
            if abs(pc.x - b) < 0.2 + hd * 0.3:
                return True
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.45, keep=keep, closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('IM5_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='IM5_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('IM5\'s rounded bow in the top view is sharpened into a straight-flanked wedge running to a blunt, nearly upright bow face (2.6 deep at the ridge ends), its corners chamfered',
             'design notes 758 ("IM5\'s bow reads rounder in the top view than the wedge the faction wants; the sheet sharpens it"); factions.md: a wedge with a blunt bow face; rule 4.1: no stem or keel line')
    K.change('The hull is 31.0 long, 12.0 across the knuckles (12.6 over the pit swells), 3.8 deep: length to beam 2.46 over the swells, 2.58 off them (IM5\'s top view about 2.5); the stern 10.3 across, wider than IM5\'s top view (about 0.62 of the beam) so the six nozzles fit in one row',
             'data.js h_boss class Super-dreadnought, CLS_LEN 31.0; factions.md asks about 3 : 1 for the line ships, and the boss keeps IM5\'s broader read (one broad wedge, R255); IM5 has no side view, so the depth is designed (the three-quarter shows a thick hull)')
    K.change('The canyon is 3.1 across its floor and 3.8 across its lips (about 0.3 of the beam, narrower than IM5\'s top view at about 0.4), 1.7 deep, its walls stepped by a ledge halfway down',
             'design notes 758 (DeepSeek, adopted: the canyon kept narrow so the ridges never read as separate hulls); R244: no flat walls; the depth keeps the canyon floor in view from the battle camera (34 degrees above the board)')
    K.change('The canyon runs from the bow deck (10.5) to the stern deck (-12.4); ahead of it a low bow deck (0.45 to 0.6 below the ridge tops) carries the sensor fin, the ion trench is recessed in the bow face under it',
             'design notes 758: the fin on the bow deck ahead of the canyon mouth, the trench at the canyon\'s mouth; R240: the bow deck sits low so the bridge lance fires over the fin (the fin\'s top 0.55 under the lance\'s pivot, 0.4 with the check\'s calibre pad)')
    K.change('The bow trench carries a large blue emitter lens, eight nested octagonal accelerator rings, lit emitter buses and an inset muzzle lip',
             'Ryan R289: the wide plain opening read as a carrier bay. It uses the Dominion correction (R287) inside IM5\'s existing mouth, without changing the concept outline, insides or single ion F slot')
    K.change('Three low bridge decks (bow 4.4, midships -3.4, stern -9.0) flush with the ridge decks, their undersides chamfered, two girders under each, a crossing corridor inside, a trim band and a blue strip on each face',
             'IM5 and its notes (bridges at about 64, 40 and 21 percent from the stern, flush with the ridge tops: never above the hull line, no naval read); R244: shaped, not boxes')
    K.change('The heavy plasma lances (hturbo P and S) are low twin turrets sunk in shoulder pits on the ridges\' outer shoulders at -3.4, abreast of the midships bridge, each turning through its own broadside arc (30 to 150 degrees off the bow)',
             'design notes 758: shoulder mounts, not the flank mounts the top view renders; R185 (4): guns low, sunk in and real; data.js hturbo P and S, 3 shots each; IM5 shows two thick barrels a mount (its notes say three): two, as the picture shows, both fire every volley (weapon_match SPLIT)')
    K.change('The plasma lance (turbo T) on the midships bridge is the heavy lance\'s mount at a smaller size (0.95 against 1.15), twin barrels, turning all round',
             'data.js turbo T, 2 shots; factions.md: the same parts repeated at different sizes; IM5 shows a twin turret on that bridge')
    K.change('The flak cluster (flak T) on the stern bridge is one twin picket laser turret, elevating to 60',
             'data.js flak T, 3 shots over 2 emitters (both fire every volley); IM5 shows a twin mount on the stern bridge; one mount, as the notes say')
    K.change('One flat row of six rectangular nozzle pods across the whole stern face on one datum, not only between the ridge roots',
             'IM5\'s three-quarter shows the plumes across the whole stern (its notes say between the ridge roots); factions.md: a flat row of rectangular blue-white nozzles; the boss needs the thrust of the whole stern')
    K.change('The canyon floor\'s machinery is real plant with a job: two capacitor banks for the ion cannon forward, four heat exchangers for the reactor and the drives aft, two armoured power trunks along the floor, each coupled with flanges short of every module band',
             'the issue: machinery on the canyon floor is real machinery with a job (R221); IM5 shows pipes and blocks there; R226: the banks and exchangers are machines and sit whole in one module, the trunks stop at the bands')
    K.change('Coolant lines on both canyon ledges (the exchangers\' loops out to the ridges\' plant rooms), one length per stretch between the bands and the bridges, and four blue-white control windows of the engine room on the stern deck\'s fore face, looking up the canyon',
             'IM5 shows pipe runs along the canyon walls and a blue-lit block at the canyon\'s aft end: here the windows of the engine room that watches the plant; every part has a job (R221); the lines stop short of the bands and bridges (R226)')
    K.change('Even panel grid of two module sizes on the decks, the canyon floor and walls, the facets, the belly and the bridges; module bands as raised rings with a deep double seam round the whole section, canyon included; module latch rows on the ridge decks at the bands',
             'paint direction hegemony.md (approved Nov 14): the even grid, two module sizes, the module band as structure; R243 ("Hegemony also pretty rigid and clean"); every part has a job (R221): the latches lock the modules')
    K.change('The flanks are faceted round a vertical flank band (upper and lower facets, chamfers, a chine) carrying the blue line, broken only at the module bands',
             'R244, binding on every sheet ship; factions.md: "a pale wedge with a line of blue light"; the strips are the running lights (paint direction 5)')
    K.change('Retro thrusters on the bow face, attitude thrusters on the facets, blue-white window slits, louvres, flush hatches, a stern lift head and a belly armour step added; no hangar, no drone bay, no mount for nova',
             'a ship in space needs thrusters and access (lore 3.4, 3.3); IM5 shows no underside; data.js h_boss has no hangar and its ability nova has no mount (the issue); every part has a job (R221)')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 768) ----------
    K.fix('The sensor fin A1 and the trench coils I1 reported inside the hull: the hull\'s end caps were one n-gon across a concave section (the canyon), which the fit check\'s triangle tree fans across the canyon; the trench mouth\'s corners were cut off by the ray sampling',
          'the end caps triangulated for real (loft_closed); each mouth corner taken by its nearest ring point')
    K.fix('Windows W1 to W3, louvre V1 and flank hatch H70 inside the hull where it tapers toward the bow',
          'every fitting set flat on its face with the taper included (surf: the face\'s own normal along x and across)')
    K.fix('Heat exchanger HX1\'s port into the module band at -0.6; HX2 to HX4 within 0.1 of a seam band',
          'HX1 aft to -1.75; HX2 to -5.3, HX3 to -7.5, HX4 to -10.4, each 0.15 or more clear of its band')
    K.fix('The power trunks\' collars and flanges into the canyon floor panels', 'the trunks raised to 0.28 over the floor; their saddles run down into the floor')
    K.fix('Belly hatch H3 inside the belly armour step where the belly rises at 8.0', 'moved to the flat belly at 4.0')
    K.fix('Latch rows L0 at the bow band past the deck edge (no mount on the hull)', 'every latch row set at the middle of the ridge deck at its band')
    K.fix('Latch rows L1 into deck hatches H1 and H2', 'the deck hatches moved to 5.55, between the band and the bow bridge')
    K.fix('The coolant lines\' collars into the canyon wall and ledge panels', 'the lines set 1.64 off the axis and 0.17 over the ledge')
    K.open_item('IM5 has no side or underside view: the heights, the belly and the underside are designed here')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack, a later job), not modelled')


INV_NOTES = {}
