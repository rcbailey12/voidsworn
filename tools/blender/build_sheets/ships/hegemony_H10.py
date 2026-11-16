# hegemony_H10: the Dominion-class dreadnought, the Hegemony Navy's line flagship (data.js h_dominion, class Battleship, 21.0
# world units). Issue 759. Shape of record: contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg and _beauty.jpg
# (H10 picked and settled, R198; style not reached: "semi realistic but not quite", so this sheet dresses it in the realistic
# detailed style, R197, R204 (3)). data.js h_dominion: hturbo P, hturbo S, ion F, flak T; ability launch, hangar 1.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): H10 is a base, not a trace.
# Measured off the H10 sheet's true views (top view above, side view below, BOW ON THE RIGHT in both; 1636 px = 21 units): the
# wedge the forward half, 4.9 wide at the bow face, 7.0 at a quarter, 7.9 across the shoulder turret bays at 38 to 46 percent;
# the twin rails the aft half, 6.6 across both, a gap about 1.2 between them; the bow face 1.4 deep, the wedge 3.0 at 30
# percent, the rails 2.8. Length to beam 2.66, length to height 7.0 (factions.md: a heavy thick wedge, about 3 : 1, R183 (3)).
# Ruled answers that bind this sheet (pack.md section 9, R232): flush armoured drone doors on the Dominion; Ryan judges the sheet
# beside corsair_A.jpg (R198 (3)). Every change from H10 is listed by K.change below.
# +X bow, +Y port, +Z up. Bow face x = +10.5, nozzle exits x = -10.5. The hull datum is z 0.
import math

CODE = 'hegemony_H10'
NAME = 'Dominion-class dreadnought (Hegemony Navy line flagship)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'Battleship'
LENGTH = 21.0
GAME = "data.js h_dominion (cls 'Battleship'); length from godot/render/hull_table.gd CLS_LEN['Battleship'] = 21.0 (drawn x SHIP_K 1.6 = 33.6 on the board)"
BEAUTY = 'contrib/muse/design/concept_round7_2026_11/hegemony_H10_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg'
# the true views on the H10 sheet (x0, y0, x1, y1), bow on the right in both
CONCEPT_VIEWS = dict(top=dict(box=(125, 92, 1790, 740), largest=True, flip=True), side=dict(box=(125, 838, 1790, 1166), largest=True, flip=True))
CROPS = [('bow (the blunt wedge and the ion trench)', (1150, 200, 1910, 900)), ('midships (the shoulder turrets, the sensor fin)', (700, 150, 1450, 900)),
         ('stern (the twin rails, the drone bay, the nozzles)', (0, 30, 900, 720))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus759',
             blend_where='rendered in the issue 759 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_H10 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the new Hegemony kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them. Beyond the fit check, the sheet\'s own looks sent back: the first '
                    'lance turrets (size 0.9, barrels 0.92) read small beside H10\'s big shoulder turrets and their barrels hid behind the glacis, so they grew '
                    'to 1.1 with 1.25 barrels in a wider, longer pit; the first sensor fin (0.62 tall, 1.8 long) read as a sail from the beam, so it came '
                    'down to 0.42 and ran out to 2.4; the first panel grid (0.8 by 0.62) left the hull at a seventh of the guns\' triangle density, so it '
                    'went to 0.6 by 0.45.')

# ---------------------------------------------------------------------------------------------------- the wedge's section
# The wedge's section (port half; the starboard half mirrors it): a flat deck, a deck-edge chamfer, an upper facet sloping out to
# the knuckle, the vertical flank band (the blue line runs along it), a lower facet sloping in, a chine chamfer, a flat worked
# belly. At the shoulders the deck steps down into a terrace (the turret pit): the lance turrets sit low in it, sunk into the
# shoulder armour (R185 (4)), and the knuckle swells out over it (H10's octagonal turret bays).
# (x, hw: knuckle half-beam, zt: deck, zb: belly, kt, kb: the flank band's top and bottom, dw: deck edge, bw: belly half-width,
#  y1, y1b: the terrace wall's top and foot (on the deck where there is no terrace), sd: the terrace's depth)
ST = [
    (10.5, 2.35, 0.62, -0.98, 0.25, -0.40, 1.95, 1.70, 0.98, 1.46, 0.0),
    (9.7, 2.56, 0.70, -1.15, 0.27, -0.46, 2.10, 1.85, 1.05, 1.58, 0.0),
    (8.4, 2.82, 0.80, -1.37, 0.30, -0.53, 2.30, 2.05, 1.15, 1.72, 0.0),
    (6.7, 3.14, 0.90, -1.60, 0.33, -0.60, 2.55, 2.25, 1.28, 1.91, 0.0),
    (5.0, 3.42, 0.98, -1.80, 0.35, -0.66, 2.75, 2.42, 1.38, 2.06, 0.0),
    (4.45, 3.50, 1.02, -1.87, 0.36, -0.68, 2.80, 2.46, 1.40, 2.10, 0.0),
    (4.3, 3.64, 1.02, -1.87, 0.36, -0.68, 3.25, 2.46, 2.10, 2.105, 0.34),
    (3.85, 3.95, 1.02, -1.88, 0.36, -0.68, 3.62, 2.46, 1.45, 1.455, 0.34),
    (0.55, 3.95, 1.02, -1.88, 0.36, -0.68, 3.62, 2.46, 1.45, 1.455, 0.34),
    (0.10, 3.64, 1.02, -1.88, 0.36, -0.68, 3.25, 2.46, 2.10, 2.105, 0.34),
    (-0.05, 3.50, 1.02, -1.88, 0.36, -0.68, 2.80, 2.46, 1.40, 2.10, 0.0),
    (-0.40, 3.50, 1.02, -1.88, 0.36, -0.68, 2.80, 2.46, 1.40, 2.10, 0.0),
]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]   # the sheet kit's loft format, for the sheet tools
SHELL = 0.25       # hull thickness (the solidify shell)
XB = 9.3           # the trench's back wall: the wedge loft ends here, the bow frame runs on to the bow face at 10.5
XA = -0.40         # the wedge's aft face; the rails run aft from just behind it
TRENCH = dict(w=1.3, h=0.7, zc=-0.175)
# the twin rails: centre 1.95 off the axis, 2.66 wide, the deck 1.0, the belly -1.72; nozzle pods aft of the rails' end at -9.2
RY, RHW, RZT, RZB, RX0, RX1 = 1.95, 1.33, 1.0, -1.72, -0.35, -9.2
BAY = dict(x0=-0.35, x1=-4.6, hw=0.78, z0=-1.5, z1=0.5)
BANDS_W = (7.0, 4.75, -0.2)                     # module bands on the wedge
BANDS_R = (-3.0, -5.6, -8.2)                   # module bands on the rails
TURRET = (2.2, 2.9)                            # the shoulder lance turrets' ring centre (x, |y|), on the terrace floor


def st_at(x):
    s = sorted(ST, key=lambda r: -r[0])
    if x >= s[0][0]:
        return list(s[0])
    if x <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0]) if a[0] != b[0] else 0.0
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def half_ring(x, inset=0.0):
    """the port half of the wedge's section at x, deck centre to belly centre: [(y, z)], inset inward by about `inset`"""
    _, hw, zt, zb, kt, kb, dw, bw, y1, y1b, sd = st_at(x)
    hw -= inset; zt -= inset; zb += inset; dw -= inset * 0.5; bw -= inset * 0.5
    c = 0.12; c2 = 0.14
    y1 = min(y1, dw - 0.05); y1b = min(max(y1b, y1 + 0.001), dw - 0.02)
    zd = zt - sd
    kt_ = min(kt, zd - c - 0.02); kb_ = max(kb, zb + c2 + 0.02)
    return [(0.0, zt), (y1, zt), (y1b, zd), (dw, zd), (dw + c, zd - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


def hw_at(x, z, inset=0.0):
    """the wedge's half-width at height z (port side), inset by `inset` (the inside of the skin): 0 when z is outside"""
    h = half_ring(x, inset)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h, h[1:]):
        if min(z0, z1) - 1e-6 <= z <= max(z0, z1) + 1e-6:
            if abs(z1 - z0) < 1e-6:
                best = max(best, y0, y1)
            else:
                best = max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


def deck_z(x, y):
    """the wedge's top surface at (x, y): the deck, or the terrace floor"""
    h = half_ring(x)
    ay = abs(y)
    if ay <= h[1][0]:
        return h[0][1]
    if ay <= h[3][0]:
        return h[2][1]
    return h[3][1]


def belly_z(x):
    return st_at(x)[3]


def rail_half(side, inset=0.0):
    """the port (side +1) or starboard rail's section: a chamfered block with a recessed band round its flanks at mid height
    (the two module tiers of H10's rails; the blue line runs in the outer recess). [(y, z)] all round."""
    yc = side * RY; a = RHW - inset; zt = RZT - inset; zb = RZB + inset
    r = 0.07
    pts = [(-a + 0.1, zt), (a - 0.3, zt), (a, zt - 0.3), (a, -0.02), (a - r, -0.08), (a - r, -0.26), (a, -0.32), (a, zb + 0.22), (a - 0.22, zb),
           (-a + 0.12, zb), (-a, zb + 0.12), (-a, -0.32), (-a + r, -0.26), (-a + r, -0.08), (-a, -0.02), (-a, zt - 0.1)]
    return [(yc + side * u, z) for (u, z) in pts]


def rail_ring(x, side, inset=0.0):
    return [(x, y, z) for (y, z) in rail_half(side, inset)]


def offset_loop(pts, d):
    """a closed (y, z) loop moved out by d along each vertex's bisector (the loop's own outward side, by its centroid)"""
    n = len(pts)
    cy = sum(p[0] for p in pts) / n; cz = sum(p[1] for p in pts) / n
    out = []
    for i in range(n):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
        nrm = []
        for (a, b) in ((p0, p1), (p1, p2)):
            ey, ez = b[0] - a[0], b[1] - a[1]; L = math.hypot(ey, ez) or 1.0
            ny, nz = ez / L, -ey / L
            if (ny * (p1[0] - cy) + nz * (p1[1] - cz)) < 0:
                ny, nz = -ny, -nz
            nrm.append((ny, nz))
        my, mz = nrm[0][0] + nrm[1][0], nrm[0][1] + nrm[1][1]; L = math.hypot(my, mz) or 1.0
        my, mz = my / L, mz / L
        cosh = max(0.35, my * nrm[0][0] + mz * nrm[0][1])
        out.append((p1[0] + my * d / cosh, p1[1] + mz * d / cosh))
    return out


def tube(K, name, x0, x1, outer, inner, m, grp='hull', inside=False):
    """a closed annular solid from x0 to x1 between two (y, z) loops of the same count (outer round inner): a module band, the
    bow frame round the trench"""
    n = len(outer)
    V = [(x0, y, z) for (y, z) in outer] + [(x1, y, z) for (y, z) in outer] + [(x0, y, z) for (y, z) in inner] + [(x1, y, z) for (y, z) in inner]
    F = []
    for i in range(n):
        j = (i + 1) % n
        F.append((i, j, n + j, n + i))                         # outer wall
        F.append((2 * n + j, 2 * n + i, 3 * n + i, 3 * n + j))  # inner wall
        F.append((j, i, 2 * n + i, 2 * n + j))                 # the x0 face
        F.append((n + i, n + j, 3 * n + j, 3 * n + i))         # the x1 face
    return K._obj(name, V, F, m, grp=grp, inside=inside)


def inside_ok(p, inset=SHELL):
    """how far the point p sits outside the inner skin of the mass that holds it (<= 0 inside): the wedge, a rail or the bay block"""
    x, y, z = p
    if x >= XA - 0.02 and x <= XB:
        h = half_ring(x, inset)
        hw = hw_at(x, z, inset)
        return max(abs(y) - hw if hw > 0 else 0.05, z - h[0][1], h[-1][1] - z)
    best = 9.0
    if BAY['x1'] + inset <= x <= BAY['x0'] and abs(y) <= BAY['hw']:
        best = min(best, max(abs(y) - (BAY['hw'] - inset), z - (BAY['z1'] - inset), (BAY['z0'] + inset) - z))
    if RX1 + inset <= x <= RX0:
        side = 1 if y > 0 else -1
        best = min(best, max(abs(abs(y) - RY) - (RHW - inset), z - (RZT - inset), (RZB + inset) - z))
    return best


def ion_trench(K, root, depth, w, h, coils=6, r=0.35):
    """Issue 870: dress the kit's trench as a field accelerator, inside its existing opening.

    Both Hegemony sheets use this design. The kit still supplies the liners, feed conduits,
    muzzle and firing lane; the larger lens ends at that same registered muzzle.
    """
    import kit
    from mathutils import Vector
    HP = kit.HP
    part = HP.spinal(depth, r, w=w, h=h, coils=coils)
    part.comps = [c for c in part.comps if not c['name'].startswith(('coil', 'emitter', 'lens'))]
    hw, hh = w / 2, h / 2
    ex = depth * 0.24

    def frame(x0, x1, outer, inner):
        # Closed chamfered ring with an actual hole, including its front and rear annuli.
        loops = [HP.octa(*outer, min(outer) * 0.35), HP.octa(*inner, min(inner) * (2 - math.sqrt(2)))]
        verts = [(x, y, z) for x in (x0, x1) for loop in loops for y, z in loop]
        faces = []
        for i in range(8):
            j = (i + 1) % 8
            faces += [(i, j, 16 + j, 16 + i), (8 + j, 8 + i, 24 + i, 24 + j),
                      (j, i, 8 + i, 8 + j), (16 + i, 16 + j, 24 + j, 24 + i)]
        return verts, faces

    # The block fills the rear of the trench. Its broad blue lens replaces the tiny disc.
    part.add('emitter', 'mount', 'hmetal', HP.block(-0.02, ex + 0.035, hw * 0.82, hh * 0.82, hh * 0.22))
    part.add('emitter_bezel', 'body', 'htrim', frame(ex + 0.035, ex + 0.065,
             (hw * 0.77, hh * 0.77), (hw * 0.59, hh * 0.59)))
    part.add('lens', 'body', 'hblue', HP.block(ex + 0.04, ex + 0.1, hw * 0.58, hh * 0.58, hh * 0.2))
    # The emitter's recessed skirt casts blue onto the accelerator. All new light belongs
    # to the emitter, using existing stack zones; the metal coils and muzzle stay unlit.
    part.add('emitter_glow', 'body', 'hlining', frame(ex + 0.02, ex + 0.045,
             (hw * 0.91, hh * 0.88), (hw * 0.79, hh * 0.79)))
    for side in (-1, 1):
        part.add('emitter_bus%d' % (side > 0), 'body', 'hlining',
                 HP.block(ex + 0.08, depth - 0.06, hw * 0.035, hh * 0.12,
                          hh * 0.04, yo=side * hw * 0.90))
    # Nested octagonal capacitor bands get larger toward the mouth, with dark gaps between.
    # A raised floor and chamfered corners remove the flat loading-deck read.
    for i in range(coils):
        t = i / max(1, coils - 1)
        x = (ex + 0.16) * (1 - t) + (depth - 0.10) * t
        outer = (hw - 0.065, hh - 0.065)
        inner = (hw * (0.63 + 0.11 * t), hh * (0.62 + 0.08 * t))
        part.add('coil%d' % i, 'body', 'hmetal', frame(x - 0.025, x + 0.025, outer, inner))
        # Recessed emitter field contacts between the dark metal bands, not deck lamps.
        part.add('emitter_field%d' % i, 'body', 'hlining', frame(x - 0.04, x - 0.026,
                 (inner[0] + hw * 0.035, inner[1] + hh * 0.035), inner))
    part.add('muzzle_lip', 'body', 'htrim', frame(depth - 0.055, depth - 0.005,
             (hw - 0.055, hh - 0.055), (hw * 0.76, hh * 0.72)))

    part = K.emit('I1', part, HP.frame(Vector(root), (1, 0, 0), (0, 0, 1)), 'ion_trench', keep=False)
    fd = part.fit
    for ob in K.coll.objects:
        if ob.get('grp') == 'I1' and ob.get('role') != 'mount':
            ob['gun_fixed'] = 1
            ob['turret'] = 0
    # Keep the kit's single forward slot, muzzle and mouth-origin firing lane (K.spinal).
    lane = dict(apex=tuple(fd['lane_from'][1]), dir=(1.0, 0.0, 0.0), u=(0.0, 1.0, 0.0), w=(0.0, 0.0, 1.0),
                hu=fd['radius'], hw=fd['radius'], half=4.0, length=K.length * 0.8, what='firing lane')
    K.fitdata.append(dict(id='I1', kind='gun', slot='F', pivot=tuple(fd['pivot'][1]), up=(0, 0, 1), mount='spinal',
                         ring=tuple(root), rest_yaw=0.0, reach=fd['reach'], band=(-10, 0, 10, 20),
                         muzzles=[tuple(m[1]) for m in fd['muzzles']], cal=r, hous_r=fd['radius'], rest_pitch=0.0,
                         lanes=[lane], aim=tuple(fd['aim'][1]), bore=fd['bore']))
    K.features.append(dict(id='I1', kind='gun', what='ion cannon, stepped accelerator and blue emitter (fixed)', count=1,
                           pos=tuple(root), aim=(0.0, 0.0), slot='F', weapon='ion', src='designed',
                           note='R287, R289: broad blue emitter lens at the back, nested capacitor rings, inner glow and a framed muzzle lip, all inside the bow face',
                           muzzle=[tuple(m[1]) for m in fd['muzzles']], normal=(1, 0, 0), fixed=True, inv=['ion_trench']))


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Hegemony colour zones live in the faction kit (tools/blender/kits/hegemony)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    plate_jobs = []

    # ---------------- the wedge: one loft from its aft face to the trench's back wall ----------------
    xs = sorted({r[0] for r in ST if XA <= r[0] <= XB} | {XB} | {x / 4 for x in range(-1, 38)}, reverse=True)
    xs = [x for x in xs if XA <= x <= XB]
    hull = K.loft_rings(CODE + '_wedge', [ring(x) for x in xs], 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the wedge', hull, 'pale grey module plate',
           note='the heavy thick wedge: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a flat worked belly; the shoulder terraces where the lance turrets sit low')
    K.mark('wedge', 'hull', ['facet', 'step', 'chamfer'])
    # panels on an even grid: rings laid at the module pitch (0.6) from the bow, so seams run straight and line up across faces
    grid = [XB - 0.1 - 0.6 * i for i in range(17)]
    grid = [x for x in grid if x >= XA + 0.05] + [XA + 0.05]
    plate_jobs.append(('wedge_deck', [ring(x) for x in grid], dict(faces=[0, 17, 2, 15], inv='deck_panels')))
    plate_jobs.append(('wedge_flank', [ring(x) for x in grid], dict(faces=[4, 13, 6, 11], inv='flank_panels')))
    plate_jobs.append(('wedge_belly', [ring(x) for x in grid], dict(faces=[8, 9], inv='belly_panels')))

    # ---------------- the bow: a blunt armoured face round the ion trench (R183 (1)) ----------------
    tw, th, tz = TRENCH['w'] / 2, TRENCH['h'] / 2, TRENCH['zc']

    def rect_match(loop):
        """the trench mouth's rectangle, sampled where the ray from the mouth centre to each loop vertex meets it"""
        out = []
        for (y, z) in loop:
            dy, dz = y, z - tz
            k = min(tw / abs(dy) if abs(dy) > 1e-9 else 1e9, th / abs(dz) if abs(dz) > 1e-9 else 1e9)
            out.append((dy * k, tz + dz * k))
        return out
    bow_outer = [(y, z) for (_, y, z) in ring(10.5)]
    xs_b = [XB, 9.7, 10.1, 10.5]
    V, F = [], []
    loops = [[(y, z) for (_, y, z) in ring(x)] for x in xs_b]
    inner = rect_match(bow_outer)
    n = len(inner)
    for k, (x, lp) in enumerate(zip(xs_b, loops)):
        V += [(x, y, z) for (y, z) in lp]
    for k, x in enumerate(xs_b):
        V += [(x, y, z) for (y, z) in inner]
    m = len(xs_b)
    for k in range(m - 1):
        for i in range(n):
            j = (i + 1) % n
            F.append((k * n + i, k * n + j, (k + 1) * n + j, (k + 1) * n + i))
            F.append(((m + k) * n + j, (m + k) * n + i, (m + k + 1) * n + i, (m + k + 1) * n + j))
    for i in range(n):
        j = (i + 1) % n
        F.append(((m - 1) * n + i, (m - 1) * n + j, (2 * m - 1) * n + j, (2 * m - 1) * n + i))   # the bow face
        F.append((j, i, m * n + i, m * n + j))                                                   # its back, on the wedge's end
    bowf = K._obj(CODE + '_bowframe', V, F, 'hgrey', grp='hull')
    K.mass('Bow face round the ion trench', bowf, 'pale grey module plate', note='the blunt bow face (never a ship\'s stem): the wedge\'s facets run to it, the trench recessed in its middle')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    # the bow face's armour: machined plates round the trench mouth, a trim frame on the mouth
    for (y0, y1, z0, z1) in ((-tw - 0.12, tw + 0.12, tz + th + 0.04, tz + th + 0.3), (-tw - 0.12, tw + 0.12, tz - th - 0.3, tz - th - 0.04),
                             (tw + 0.04, tw + 0.55, tz - th + 0.02, tz + th - 0.02), (-tw - 0.55, -tw - 0.04, tz - th + 0.02, tz + th - 0.02)):
        K.box('H10_bowplate_%d' % len(K.masses), 10.48, 10.56, y0, y1, z0, z1, 'hpanel', ch=0.02, grp='hull')
    K.box('H10_bowtrim_t', 10.5, 10.58, -tw - 0.04, tw + 0.04, tz + th, tz + th + 0.04, 'htrim', grp='hull')
    K.box('H10_bowtrim_b', 10.5, 10.58, -tw - 0.04, tw + 0.04, tz - th - 0.04, tz - th, 'htrim', grp='hull')
    for s_ in (1, -1):
        K.box('H10_bowtrim_%s' % ('p' if s_ > 0 else 's'), 10.5, 10.58, s_ * tw if s_ > 0 else -tw - 0.04, tw + 0.04 if s_ > 0 else -tw, tz - th, tz + th, 'htrim', grp='hull')
    ion_trench(K, (XB, 0.0, tz), 10.5 - XB, TRENCH['w'], TRENCH['h'])

    # ---------------- the twin rails, the drone bay block between them ----------------
    xr = [RX0] + [RX0 - 0.25 * i for i in range(1, 40) if RX0 - 0.25 * i > RX1] + [RX1]
    rails = {}
    for side in (1, -1):
        nm = 'port' if side > 0 else 'starboard'
        ob = K.loft_rings(CODE + '_rail_%s' % nm[0], [rail_ring(x, side) for x in xr], 'hgrey')
        md = ob.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
        rails[side] = ob
        K.mass('Rail, %s' % nm, ob, 'pale grey module plate', note='one of the twin rails: a chamfered block in two module tiers (a recessed band at mid height), the drives at its end')
        gr = [RX0 - 0.05 - 0.6 * i for i in range(16) if RX0 - 0.05 - 0.6 * i > RX1 + 0.05] + [RX1 + 0.05]
        plate_jobs.append(('rail_%s' % nm[0], [rail_ring(x, side) for x in gr], dict(faces=[0, 2, 6, 8, 10, 14], inv='rail_panels')))
    K.mark('rails', 'rail', ['facet', 'step', 'strip'])
    bx = [BAY['x0'], BAY['x0'] - 0.3, BAY['x1'] + 0.3, BAY['x1']]
    hb = BAY['hw']
    bb = [[(x, hb, BAY['z0']), (x, hb, BAY['z1']), (x, -hb, BAY['z1']), (x, -hb, BAY['z0'])] for x in bx]
    ob = K.loft_rings(CODE + '_baytrough', bb, 'hgrey2')
    md = ob.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Drone bay block between the rails', ob, 'recessed grey', note='the hangar between the rails (H10\'s bay): its roof a trough below the rail decks, the flush armoured doors in it')
    K.mark('bay_block', 'tier', ['face', 'roof', 'opening'])
    K._surface_part('B1', HP.bay(1.0, 3.2), (-2.45, 0.0, BAY['z1']), (0, 0, 1), (1, 0, 0), 'bay', 'flush armoured drone doors 3.2 x 1.0', 'bay', 'picture',
                    'data.js hangar 1: the drone bay\'s flush armoured doors, a seam line only on the intact ship (R232); the drones launch up out of the trough', aperture=2.0)
    # the nozzle pods: four rectangular nozzles in one flat row across the stern, two to a rail (factions.md)
    for side in (1, -1):
        for k, dy in enumerate((0.71, -0.71)):
            eid = 'E%d' % (1 + k + (0 if side > 0 else 2))
            K.engine(eid, (-10.5, side * RY + dy, -0.36), 0.62, 1.3, bell=1.0, body_r=0.75, kw=dict(w=1.1, h=1.45),
                     inv='engines', note='%s rail, %s nozzle: a rectangular nozzle pod, blue-white throat' % ('port' if side > 0 else 'starboard', ('outer' if dy * side > 0 else 'inner')))
            K.features[-1]['what'] = 'engine, rectangular nozzle 1.1 x 1.45'
    # the rails' aft face between the pods: a trim frame
    for side in (1, -1):
        K.box('H10_railcap_%s' % ('p' if side > 0 else 's'), RX1 - 0.04, RX1 + 0.02, side * RY - RHW + 0.15, side * RY + RHW - 0.15, RZB + 0.15, RZT - 0.15, 'hgrey2', grp='hull')

    # ---------------- module bands: the joints where the hull gives way (factions.md "How it breaks") ----------------
    def band(x, loop, tag):
        for k, (a, b) in enumerate(((x + 0.13, x + 0.03), (x - 0.03, x - 0.13))):
            tube(K, 'H10_band_%s_%d' % (tag, k), b, a, offset_loop(loop, 0.07), offset_loop(loop, -0.03), 'htrim')
        tube(K, 'H10_bandseam_%s' % tag, x - 0.04, x + 0.04, offset_loop(loop, 0.025), offset_loop(loop, -0.03), 'hgrey2')
    for i, x in enumerate(BANDS_W):
        band(x, [(y, z) for (_, y, z) in ring(x)], 'w%d' % i)
    for i, x in enumerate(BANDS_R):
        for side in (1, -1):
            band(x, rail_half(side), 'r%d%s' % (i, 'p' if side > 0 else 's'))
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line: implant-blue strips along the flank band and the rails' recess ----------------
    def blue_run(tag, pts, nrm):
        if len(pts) > 1:
            K.strip('H10_blue_%s' % tag, pts, w=0.07, t=0.025, normals=[nrm(p) for p in pts], m='hblue', grp='hull')
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        cuts = sorted([XB - 0.15] + [b + d for b in BANDS_W for d in (0.2, -0.2)] + [XA + 0.08], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa, xb_ = cuts[k], cuts[k + 1]
            pts = []
            for j in range(13):
                x = xa + (xb_ - xa) * j / 12
                h = half_ring(x)
                pts.append((x, side * (h[5][0] + 0.003), (h[5][1] + h[6][1]) / 2))
            blue_run('w%s%d' % (sn, k), pts, lambda p: (0, side, 0))
        cuts = sorted([RX0 - 0.1] + [b + d for b in BANDS_R for d in (0.2, -0.2)] + [RX1 + 0.1], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa, xb_ = cuts[k], cuts[k + 1]
            yo = side * (RY + RHW - 0.07 + 0.003)
            blue_run('r%s%d' % (sn, k), [(xa, yo, -0.17), (xb_, yo, -0.17)], lambda p: (0, side, 0))
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- the shoulder lance turrets, sunk in the terraces ----------------
    tx, ty = TURRET
    for side in (1, -1):
        sn = 'P' if side > 0 else 'S'
        zf = deck_z(tx, side * ty)
        K.keepouts.append((Vector((tx, side * ty, zf)), 1.45))   # no panel under the turret's sweep
        K.gun('H%s' % sn, (tx, side * ty, zf), 55 * side, 0.0, barrels=2, cal=0.12, blen=1.25, size=1.1, slot=sn, weapon='hturbo', inv='lances',
              note='%s shoulder lance turret: the heavy plasma lance (hturbo %s, 3 shots), a low wide mount sunk in the shoulder terrace, two short thick barrels' % (
                  'port' if side > 0 else 'starboard', sn))
    # the terrace's inner wall gets a trim lip (the pit's edge)
    for side in (1, -1):
        h0 = half_ring(2.2)
        K.box('H10_pitlip_%s' % ('p' if side > 0 else 's'), 0.65, 3.75, side * h0[1][0] - 0.05 if side > 0 else -h0[1][0] - 0.03,
              h0[1][0] + 0.03 if side > 0 else -h0[1][0] + 0.05, h0[2][1], h0[0][1] + 0.025, 'htrim', grp='hull')

    # ---------------- the sensor fin (one low fin, never a tower) ----------------
    K.antenna('A1', (1.6, 0.0, deck_z(1.6, 0.0)), 0.42, whips=0, inv='sensor_fin',
              note='the one low sensor fin on the centreline: sensor windows and a lens strip; the command deck is under it')
    K.features[-1]['what'] = 'sensor fin, 0.4 tall, 2.4 long'

    # ---------------- the picket lasers: two twin turrets on the belly ----------------
    for side in (1, -1):
        x, y = 4.3, side * 1.35
        K.gun('F%d' % (1 if side > 0 else 2), (x, y, belly_z(x) - 0.1), 40 * side, 10, barrels=2, cal=0.055, blen=0.42, size=0.62, normal=(0, 0, -1), slot='T', weapon='flak',
              inv='pickets', note='%s picket laser turret on the belly (flak T: the pair is the one slot, 3 shots over 4 emitters, both fire every volley)' % ('port' if side > 0 else 'starboard'))

    # ---------------- the belly: an armour step under the wedge ----------------
    belly = []
    for x, k in ((8.6, 0.0), (8.2, 1.0), (6.7, 1.0), (5.0, 1.0), (4.15, 1.0), (3.55, 1.0), (0.85, 1.0), (0.25, 1.0), (-0.2, 0.0)):
        zb = belly_z(x); bw = st_at(x)[7] - 0.55
        belly.append([(x, bw, zb + 0.02), (x, bw - 0.1 * k, zb - 0.1 * k), (x, -bw + 0.1 * k, zb - 0.1 * k), (x, -bw, zb + 0.02)])
    K.mass('Belly armour step', K.loft_rings('H10_belly', belly, 'hgrey2'), 'recessed grey', note='a second armour layer under the wedge (a worked belly, R185 (5))')
    plate_jobs.append(('belly_step', belly, dict(faces=[1], inv='belly_panels', closed=False)))

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.thruster('Q1' + sn, (10.5, side * 1.55, -0.25), (1, 0, 0), inv='thrusters', r=0.3,
                   note='retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap)')
        K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        h = half_ring(8.0)
        p = Vector((8.0, side * (h[4][0] + h[5][0]) / 2, (h[4][1] + h[5][1]) / 2)); nrm = Vector((0, side * (h[4][1] - h[5][1]), h[5][0] - h[4][0])).normalized()
        K.thruster('Q2' + sn, tuple(p), tuple(nrm), inv='thrusters', r=0.26, note='bow attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        K.thruster('Q3' + sn, (-7.75, side * (RY + RHW), 0.42), (0, side, 0), inv='thrusters', r=0.26, note='stern attitude thruster on the rail\'s outer flank')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        for i, x in enumerate((8.9, 8.2, 7.5)):
            h = half_ring(x)
            K.slit('W%d%s' % (i + 1, sn), (x, side * (h[5][0] + 0.035), h[5][1] - 0.13), (0, side, 0), 0.4, 0.09, inv='windows',
                   note='blue-white window of the forward crew decks')
        for i, x in enumerate((-1.6, -4.3)):
            K.slit('W%d%s' % (i + 4, sn), (x, side * (RY + RHW + 0.004), -0.55), (0, side, 0), 0.5, 0.09, inv='windows', note='blue-white window of the rails\' crew decks')
        for i, x in enumerate((-1.7, -4.3, -6.9)):
            K.vent('V%d%s' % (i + 1, sn), (x, side * RY, RZT), (0, 0, 1), 0.34, 1.2, slats=7, inv='vents',
                   note='heat louvre on the rail deck over the %s' % ('crew decks' if x > -5 else 'engine room'))
        for i, x in enumerate((-1.7, -4.3, -6.6)):
            K.vent('V%d%s' % (i + 6, sn), (x, side * (RY + RHW + 0.004), 0.55), (0, side, 0), 1.5, 0.2, slats=3, inv='vents',
                   note='heat louvre on the rail\'s upper tier (H10\'s long flank slots)')
        for i, x in enumerate((-2.5, -5.1, -7.7)):
            K.hatch('H6%d%s' % (i, sn), (x, side * (RY + RHW + 0.004), -0.85), (0, side, 0), 0.5, 0.36, inv='hatches', up=(0, 0, 1),
                    note='rail flank hatch on the lower tier: access to the plant rooms')
        for i, x in enumerate((3.2, 1.2)):
            h = half_ring(x)
            p = Vector((x, side * (h[6][0] + h[7][0]) / 2, (h[6][1] + h[7][1]) / 2)); nrm = Vector((0, side * (h[6][1] - h[7][1]), h[7][0] - h[6][0])).normalized()
            if nrm.z > 0:
                nrm = Vector((0, nrm.y, -nrm.z))
            K.hatch('H7%d%s' % (i, sn), tuple(p + nrm * 0.004), tuple(nrm), 0.55, 0.4, inv='hatches', note='flank hatch on the lower facet: stores to the lower deck')
        K.vent('V4' + sn, (5.9, side * 0.85, deck_z(5.9, 0) + 0.01), (0.047, 0, 1), 0.3, 1.2, slats=7, inv='vents', note='heat louvre over the lance capacitor rooms')
        K.vent('V5' + sn, (1.0, side * 0.8, deck_z(1.0, 0.8)), (0, 0, 1), 0.3, 0.9, slats=5, inv='vents', note='heat louvre over the reactor')
        for i, xb_ in enumerate(BANDS_W[:2]):
            for d in (0.32, -0.32):
                K.organ('LW%d%s%s' % (i, sn, 'f' if d > 0 else 'a'), HP.latch(), (xb_ + d, side * 1.2, deck_z(xb_ + d, 1.2)), (0, 0, 1), fwd=(1, 0, 0), inv='latches',
                        what='module latch row (4 clamps)', kind='latch', note='locks the two wedge modules together across the band')
        for i, xb_ in enumerate(BANDS_R):
            for d in (0.32, -0.32):
                K.organ('LR%d%s%s' % (i, sn, 'f' if d > 0 else 'a'), HP.latch(), (xb_ + d, side * RY, RZT), (0, 0, 1), fwd=(1, 0, 0), inv='latches',
                        what='module latch row (4 clamps)', kind='latch', note='locks two rail modules together across the band')
    K.hatch('H1', (8.0, 0.0, deck_z(8.0, 0)), (0, 0, 1), 0.7, 0.45, inv='hatches', note='deck hatch over the forward crew deck')
    K.hatch('H2', (3.6, 0.0, deck_z(3.6, 0)), (0, 0, 1), 0.6, 0.5, inv='hatches', note='deck hatch to the command deck')
    K.hatch('H3', (2.9, 0.0, belly_z(2.9) - 0.1), (0, 0, -1), 0.8, 0.5, inv='hatches', note='belly hatch on the armour step: stores')
    K.hatch('H4', (1.1, 0.0, belly_z(1.1) - 0.1), (0, 0, -1), 0.8, 0.5, inv='hatches', note='belly hatch on the armour step: the reactor\'s service hatch')
    for side in (1, -1):
        K.hatch('H5' + ('p' if side > 0 else 's'), (-4.3, side * RY, RZB), (0, 0, -1), 0.7, 0.45, inv='hatches', note='rail belly hatch: the engine room\'s stores')
    K.hatchbox('HB1', (6.1, 0.0, deck_z(6.1, 0)), 0.9, 1.1, 0.26, inv='lift_heads', note='the bow lift head: stores up to the forward decks')

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim (paint stage)', 10.5, -10.5, 'whole hull')
    K.colour('implant-blue light strips (the blue line), blue-white nozzles and windows', 10.5, -10.5, 'the flank bands, the rails, the stern')
    K.colour('no rust, no warm light, no asymmetry', 10.5, -10.5, 'factions.md Never')

    # ---------------- INSIDE: white corridors, blue emergency light, racks of identical equipment ----------------
    IN = SHELL + 0.06

    def slab(name, z, x0, x1, kind_name, wfn, n=4):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = wfn(x, z) - 0.02
            rs.append([(x, hw, z - 0.04), (x, hw, z + 0.04), (x, -hw, z + 0.04), (x, -hw, z - 0.04)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))

    def wedge_w(x, z):
        return min(hw_at(x, z - 0.05, IN), hw_at(x, z + 0.05, IN))

    def frame_at(name, x, zr=None):
        """a frame ring inside the wedge's skin at station x (the hull's own section, inset), split into short plates"""
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.12)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        V, F = [], []
        nn = len(fo)
        for k in range(nn):
            a_, b_ = k, (k + 1) % nn
            q = [fo[a_], fo[b_], fi[b_], fi[a_]]
            if math.hypot(fo[b_][0] - fo[a_][0], fo[b_][1] - fo[a_][1]) < 1e-4:
                continue
            o = len(V)
            V += [(x + 0.06, y_, z_) for (y_, z_) in q] + [(x - 0.06, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def rail_frame(name, x, side):
        ho = rail_half(side, IN); hi = rail_half(side, IN + 0.12)
        V, F = [], []
        nn = len(ho)
        for k in range(nn):
            q = [ho[k], ho[(k + 1) % nn], hi[(k + 1) % nn], hi[k]]
            o = len(V)
            V += [(x + 0.06, y_, z_) for (y_, z_) in q] + [(x - 0.06, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, y0=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.05
        if ymax is not None:
            w = min(w, ymax)
        if y0 is None:
            K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)
        else:
            for side in (1, -1):
                ya, yb = (y0, w) if side > 0 else (-w, -y0)
                K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)

    def rail_room(name, kind, x0, x1, z0, z1, note=''):
        a = RHW - IN - 0.05
        for side in (1, -1):
            K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), side * RY - a, side * RY + a, z0, z1, note=note)
    # compartments by the transverse seams (B-1 at 7.0, B-2 at -0.55, B-3 at -5.6): every inside stays in one (ships.md 2c)
    # the bow compartment (10.5 to 7.0)
    slab('bow_main', 0.12, 9.05, 7.3, 'main', wedge_w)
    slab('bow_lower', -0.72, 8.7, 7.3, 'lower', wedge_w)
    frame_at('F1', 8.6); frame_at('F2', 7.75)
    room('ion_capacitors', 'machinery', 9.0, 7.35, -0.64, 0.04, ymax=1.3, note='the ion cannon\'s capacitor banks and field drivers behind the trench')
    room('fwd_corridor', 'hcorr', 9.0, 7.35, 0.2, 0.45, note='white corridors of the forward crew deck')
    room('bow_stores', 'hold', 8.6, 7.35, -1.05, -0.8, ymax=1.2, note='bow stores and the retro thrusters\' feeds')
    # the mid compartment (7.0 to -0.55): the main deck, the lower deck, the command deck, the lance rooms, the reactor
    slab('mid_main', 0.12, 6.7, -0.3, 'main', wedge_w)
    slab('mid_lower', -0.95, 6.7, -0.3, 'lower', wedge_w)
    for i, x in enumerate((6.3, 5.0, 3.6, 2.4, 1.2, -0.22)):
        frame_at('F%d' % (i + 3), x)
    room('crew_corridor', 'hcorr', 6.65, 4.0, 0.2, 0.6, note='white corridors and crew berths of the main deck, numbered posts')
    room('command', 'bridge', 3.3, 0.5, 0.2, 0.62, ymax=1.2, note='the command deck under the sensor fin: the Registry link room')
    room('lance_rooms', 'magazine', 3.7, 0.7, -0.85, 0.04, y0=1.35, note='the lance capacitor rooms under the shoulder turrets')
    room('reactor', 'core', 3.3, 0.3, -1.5, 0.04, ymax=1.15, note='the reactor (hp_core): its power runs forward to the trench and out to the lances')
    for k in range(5):
        x0 = 6.55 - k * 0.48
        room('rack_%d' % k, 'hrack', x0, x0 - 0.36, -0.87, -0.12, y0=0.4, note='racks of identical equipment on the lower deck (factions.md "Inside")')
    room('picket_store', 'magazine', 4.9, 3.75, -1.55, -1.03, ymax=1.8, note='the picket lasers\' power cells over the belly turrets')
    room('emerg_mid', 'hemerg', 6.6, 0.4, 0.56, 0.6, ymax=0.08, note='the blue emergency light strip along the corridor ceiling')
    # the aft compartment (-0.55 to -5.6): the drone hangar, the rails' crew decks and stores
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        a = RHW - IN - 0.03
        rs = [[(x, side * RY + a, -0.39), (x, side * RY + a, -0.31), (x, side * RY - a, -0.31), (x, side * RY - a, -0.39)] for x in (-0.8, -5.35)]
        K.loft_rings('in_deck_rail_fwd_' + sn, rs, 'deck', inside=True)
        rs = [[(x, side * RY + a, -0.39), (x, side * RY + a, -0.31), (x, side * RY - a, -0.31), (x, side * RY - a, -0.39)] for x in (-5.85, -8.9)]
        K.loft_rings('in_deck_rail_aft_' + sn, rs, 'deck', inside=True)
        for i, x in enumerate((-1.4, -2.6, -3.8, -4.9, -6.4, -7.6, -8.7)):
            rail_frame('R%d_%s' % (i + 1, sn), x, side)
    K.inside.append(dict(kind='deck', name='rail', z=-0.35, x=(-0.8, -8.9)))
    rs = [[(x, BAY['hw'] - IN - 0.02, -1.12), (x, BAY['hw'] - IN - 0.02, -1.04), (x, -BAY['hw'] + IN + 0.02, -1.04), (x, -BAY['hw'] + IN + 0.02, -1.12)] for x in (-0.85, -4.3)]
    K.loft_rings('in_deck_hangar', rs, 'deck', inside=True)
    K.inside.append(dict(kind='deck', name='hangar', z=-1.08, x=(-0.85, -4.3)))
    K.room('hangar', 'hangar', -4.3, -0.85, -0.4, 0.4, -1.0, 0.15, note='the drone hangar: drone racks either side, the doors overhead (data.js hangar 1)')
    rail_room('rail_crew', 'hcorr', -0.85, -5.3, -0.25, 0.55, note='crew decks and corridors in the rails, white, numbered')
    rail_room('rail_stores', 'machinery', -0.85, -5.3, -1.35, -0.47, note='coolant and fuel plant under the rails\' crew decks')
    # the stern compartment (-5.6 to -10.5): the engine rooms
    rail_room('engine_room', 'engroom', -5.9, -8.88, -1.35, 0.55, note='the engine rooms: the feeds to the two nozzles of each rail')
    rail_room('emerg_rail', 'hemerg', -0.85, -5.3, 0.5, 0.54, note='blue emergency light along the rails\' corridors')
    K.armour('deck and facets', 0.25, 'machined plate in modules, flush panels over it')
    K.armour('shoulder terraces', 0.35, 'the lance turrets\' pits')
    K.armour('bow face', 0.45, 'the blunt bow round the trench, the thickest plate')
    K.armour('rails', 0.25, '')
    K.armour('belly and armour step', 0.3, '')
    # seams: in modules, at the bulkhead rings between them, like a spine coming apart (factions.md "How it breaks"); every path runs
    # on straight past both flanks and kinks between them (never a straight cut, R186); no machine on a seam (R226)
    R = 5.0
    K.break_line('B-1', 7.0, 'the bow module tears off at the first module band, the trench and the capacitor rooms with it',
                 path=[(7.0, R), (7.0, 2.4), (7.12, 1.1), (6.86, 0.0), (7.1, -1.2), (7.0, -2.4), (7.0, -R)])
    K.break_line('B-2', -0.55, 'the wedge tears from the rails at the junction ring, the drone bay roof torn across',
                 path=[(-0.55, R), (-0.55, 3.4), (-0.48, 2.0), (-0.66, 0.6), (-0.45, -0.5), (-0.62, -1.9), (-0.55, -3.4), (-0.55, -R)])
    K.break_line('B-3', -5.6, 'the rails part at their middle module band: the stern modules and the nozzles fall away',
                 path=[(-5.6, R), (-5.6, 3.4), (-5.5, 2.4), (-5.7, 1.5), (-5.55, 0.0), (-5.68, -1.5), (-5.52, -2.4), (-5.6, -3.4), (-5.6, -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: white corridors, blue emergency light, racks of identical equipment, the command deck, the lance rooms, the reactor, the drone hangar, the engine rooms. The Hegemony breaks in modules at the bulkhead rings (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).'))
    K.point('core', 'hp_core', (1.8, 0, -0.7))
    # six breach anchors on the module joints (Battleship base 6, Hegemony +0; HARDPOINTS.md), port and starboard alternating
    for i, (x, sec, side) in enumerate(((7.0, 'prow', 1), (4.75, 'prow', -1), (-0.2, 'mid', 1), (-3.0, 'mid', -1), (-5.6, 'eng', 1), (-8.2, 'eng', -1))):
        if x > XA:
            h = half_ring(x); y, z = h[5][0], (h[5][1] + h[6][1]) / 2 + 0.2
        else:
            y, z = RY + RHW, 0.35
        K.point('breach', 'hp_breach_%d' % i, (x, side * (y + 0.08), z), side='port' if side > 0 else 'stbd', section=sec, note='on a module joint')
    for i, side in enumerate((1, -1)):
        K.point('rcs', 'hp_rcs_%d' % i, (10.6, side * 1.55, -0.25), side='port' if side > 0 else 'stbd')
        K.point('rcs', 'hp_rcs_%d' % (i + 2), (-7.75, side * (RY + RHW + 0.2), 0.42), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_%d' % i, (-2.2, side * (RY + RHW + 0.05), 0.2), side='port' if side > 0 else 'stbd')
    K.point('bay', 'hp_bay_0', (-2.45, 0.0, BAY['z1'] + 0.08), note='the drone bay doors: drones launch up', dir=(0, 0, 1))

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if abs(pc.y) < BAY['hw'] + 0.02 and BAY['x1'] - 0.05 < pc.x < BAY['x0'] + 0.05 and pc.z < BAY['z1'] + 0.05:
            return True   # the rails' inner faces inside the bay block
        if pc.x > XA - 0.1 and RX0 + 0.1 > pc.x and abs(pc.y) < 3.4:
            pass
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.45, keep=keep, closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('H10_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='H10_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('H10\'s two tall box turrets with long thin twin barrels become low wide lance mounts sunk in shoulder terraces: a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, two short thick containment barrels with coil rings and vented shrouds',
             'Ryan, R185 (4): "The hegemony guns look weird and almost cartoonish"; factions.md: low armoured mounts sunk into the shoulder armour, short thick barrels, never tall round turrets with long thin barrels. The turret top stands 0.1 over the deck; the barrels sit at deck level')
    K.change('One shoulder turret a side, each one data.js slot: the port turret is hturbo P, the starboard hturbo S; each turns through its own broadside arc (30 to 150 degrees off the bow)',
             'data.js h_dominion carries hturbo P and hturbo S (3 shots each); two barrels a turret fire on every volley (weapon_match SPLIT). H10\'s turret count and places are kept')
    K.change('H10\'s glowing bow panel becomes a recessed ion accelerator: a broad blue lens block at the back, stepped octagonal capacitor rings, an emitter glow skirt and a thick inner muzzle lip',
             'Ryan R287: the opening read as a carrier bay; R289: the same correction on IM5. All details stay inside the existing bow opening; data.js ion F (1 shot), its muzzle, hull outline and insides stay unchanged')
    K.change('H10\'s small twin-tube fitting on the centreline is removed; the picket lasers (flak T) are two small twin turrets on the belly',
             'R241: no decorative or extra guns (the little twin tubes read as a gun with no data.js slot); the picket lasers on the belly keep the deck clear for the sensor fin (R240: no gun behind or aiming through a sensor) and cover the underside, where craft come from below')
    K.change('H10\'s oval sensor panel becomes the one low sensor fin on the centreline between the turrets (0.4 tall, 2.4 long, its leading edge raked)',
             'factions.md: "One low sensor fin, not a tower"; a taller first fin read as a submarine\'s sail from the beam (factions.md: H7 to H10 read as yachts or submarines); R240: no gun sits behind it or fires through it (the turrets fire outboard, the pickets below)')
    K.change('H10\'s open hangar recess between the rails becomes flush armoured drone doors in a trough between the rails (a seam line only), with blue guide lamps',
             'R232 (pack.md question 2): flush armoured drone doors on the Dominion; data.js hangar 1; the drones launch up out of the trough')
    K.change('H10\'s two raised boxes at the ends of the bay opening are left out; the flush doors run the trough\'s length instead',
             'the doors fill the trough between the junction seam B-2 and the rails\' first band (a box at the bay\'s forward end would sit across B-2), and H10 gives the boxes no job (R221: every part has a job)')
    K.change('H10\'s nozzles (two stacked pairs a rail in the side view, a pair across in the top view) become one flat row of four rectangular nozzle pods, two a rail, each a thick-lipped mouth with a blue-white throat and guide vanes',
             'factions.md: "a flat row of rectangular blue-white nozzles"; H10\'s views disagree with each other on the count; a round opening has depth (R244)')
    K.change('Even panel grid of two module sizes, module bands as raised rings with a deep double seam, flush fasteners (no rivets), H10\'s rows of four blocks kept as module latch rows at the bands',
             'paint direction hegemony.md (approved Nov 14): the even grid, two module sizes, the module band as structure; R243 ("Hegemony also pretty rigid and clean"); every part has a job (R221): the latches lock the modules')
    K.change('The wedge\'s flanks are faceted round a vertical flank band (upper and lower facets, chamfers, a chine) and the rails carry a recessed mid band, so no flank is a flat wall',
             'R244 ("the sides of the carrier are just flat walls"), binding on every sheet ship; H10\'s rails show the two tiers')
    K.change('The blue line runs along both flank bands and the rails\' recess, broken only at the module bands',
             'factions.md: "a pale wedge with a line of blue light"; the strips are the running lights (paint direction 5)')
    K.change('The bow face is blunt and nearly upright (1.6 deep at the face), its corners chamfered; the belly rises toward it but never to a stem',
             'R183 (1) and factions.md: a blunt bow face; rule 4.1: no ship\'s prow or keel line')
    K.change('Retro thrusters on the bow face, attitude thrusters on the facets and rails, blue-white window slits, louvres, flush hatches, a lift head, a belly armour step added',
             'a ship in space needs thrusters and access (lore 3.4: retro thrusters make backing off cheap; 3.3: blue-white windows); H10 shows no underside; every part has a job (R221)')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 759) ----------
    K.fix('HP and HS turning pieces inside the wedge and their bustles turning into the deck panels and the pit lip (the first pit ran 1.95 to 3.6 off the axis)',
          'the shoulder terrace widened inboard to 1.45 and lengthened (0.55 to 3.85 at full depth); no panel under the turret\'s sweep (a keep-out of 1.45)')
    K.fix('Window panes W1 to W3 inside the flank band, which tapers in plan', 'the windows set 0.035 proud of the band')
    K.fix('Nozzle pods E1 against E2 and E3 against E4', 'the pods 1.42 apart across each rail (they overhang the rail by 0.07 a side, as H10\'s pods do)')
    K.fix('Picket turrets F1 and F2 inside the belly armour step, and turning into it', 'the pickets seated on the step\'s face, 0.1 below the belly')
    K.fix('Belly hatch H3 half inside the rising belly at 6.0', 'moved to the flat belly at 2.9')
    K.fix('Reactor louvres V5 inside the pit lip, then V4 into the lift head HB1 and into the latch rows LW0 and LW1', 'V5 beside the sensor fin; the deck louvres turned to run along the length, V4 shortened to 1.2 and tilted to the deck\'s slope')
    K.fix('Flank hatches H70 and H71 inside the lower facet (their normal pointed in), first on the tapering facets forward', 'the normal turned out; the hatches moved to 3.2 and 1.2, where the facet runs straight')
    K.fix('Rail windows W4 and W5 against the rail louvres; stern thrusters Q3 against louvre V8', 'the windows to the lower tier, Q3 aft to 7.75, V8 forward to 6.6')
    K.fix('Rail louvres V2 against the latch rows at the 3.0 band', 'the rail louvres centred in their modules (1.7, 4.3, 6.6 aft)')
    K.fix('The nozzles failed the export\'s open-bell test (check_export.py, simulated here): the rim covered 0, then 8, of 12 sectors', 'points laid along the mouth\'s straight edges, the mouth made 1.1 by 1.45; all four pass, 12 of 12 sectors, a throat, a clear exhaust')
    K.fix('Lift head HB1 across seam B-1 (structure, allowed, but avoidable)', 'moved aft to 6.1')
    K.fix('Inside frames F5 and F8 outside the inner skin on the terrace ramps; the rails\' aft decks past the end cap', 'frames moved to full-terrace or plain stations; the decks end at 8.9 aft')
    K.open_item('The belly is designed here; H10 shows no underside')
    K.open_item('Stencil marks ("HD-14", "SECTION") and the steel-blue trim tone are paint (the Hegemony stack, a later job), not modelled')


INV_NOTES = {}
