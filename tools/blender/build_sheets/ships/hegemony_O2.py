# hegemony_O2: the Convoy transport, the Hegemony Navy-built objective hauler the game flies as every intercept transport
# (godot/render/hull_table.gd AI_HULLS "obj|transport" = O2_37; battle.js intercept: any roster hull flagged transport, its
# weapons cleared). Issue 1413. Shape of record: contrib/muse/design/class_family_hegemony_2026_11/ (convoy_sheet.webp,
# convoy_beauty.webp; designs.md "CONVOY TRANSPORT" governs where a picture differs; Ryan took the Navy five Nov 20 2026 21:43
# UTC, R369, PR 1168).
# Not a data.js ship: tools/recipe/gamedata.py names it obj_transport (class transport, no weapons, R241: nothing that reads as a
# gun). Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): the concept is a base.
# Family pattern: the H10 Dominion sheet (hegemony_H10.py): the same faceted section round a vertical flank band with the blue
# line, the module bands, the even flush panel grid, the flat row of rectangular nozzles.
# Measured off the convoy sheet's true views (top view above, side view below, BOW ON THE LEFT in both; 1485 px = 11 units to the
# nozzle exits): a plain wedge bow to about 25 percent, the widest hull (3.6) over the cargo well's forward half, then about 3.1
# over the aft half; the four modules in a row in the well between the rails; the four nozzle pods in one flat row aft.
# +X bow, +Y port, +Z up. Bow face x = +5.5, nozzle exits x = -5.5. The hull datum is z 0.
import math

CODE = 'hegemony_O2'
NAME = 'Convoy transport (Hegemony Navy objective)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'transport'
LENGTH = 11.0
GAME = "data.js obj_transport (no data.js ship: tools/recipe/gamedata.py OBJECTIVES, the intercept transport); length from godot/render/hull_table.gd CLS_LEN['Transport'] = 11.0 (drawn x SHIP_K 1.6 = 17.6 on the board)"
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_O2/concept_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_O2/concept_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(125, 170, 1630, 695), largest=True, flip=False), side=dict(box=(40, 875, 1200, 1005), largest=True, flip=False))
CROPS = [('bow (the plain wedge, the bumper, the sensor fin)', (100, 300, 1000, 1000)), ('midships (the cargo modules in the well)', (500, 250, 1400, 950)),
         ('stern (the last modules, the nozzle row)', (1000, 150, 1920, 800))]
SHEET = dict(version=1, round='first sheet', date='2026-11-20', blend='opus1413',
             blend_where='rendered in the issue 1413 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_O2 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

# ---------------------------------------------------------------------------------------------------- the hull section
# H10's section at transport size (port half; the starboard half mirrors it): a flat deck, a deck-edge chamfer, an upper facet
# out to the knuckle, the vertical flank band (the blue line runs along it), a lower facet, a chine chamfer, a flat worked belly.
# Amidships the deck opens into the cargo well between the two rails (the rail decks either side): the four modules sit on its
# floor. (x, hw: knuckle half-beam, zt: deck, zb: belly, kt, kb: the band's top and bottom, dw: deck edge, bw: belly half-width,
#  yw: the well's half-width, wd: the well's depth below the deck, 0 where there is no well)
ST = [
    (5.5, 0.95, 0.30, -0.42, 0.10, -0.18, 0.78, 0.62, 0.30, 0.0),
    (4.6, 1.30, 0.45, -0.58, 0.14, -0.24, 1.10, 0.90, 0.30, 0.0),
    (3.5, 1.62, 0.58, -0.68, 0.17, -0.28, 1.40, 1.15, 0.30, 0.0),
    (2.75, 1.78, 0.62, -0.70, 0.18, -0.29, 1.56, 1.25, 0.30, 0.0),
    (2.36, 1.80, 0.62, -0.70, 0.18, -0.29, 1.58, 1.26, 0.30, 0.0),
    (2.3, 1.80, 0.62, -0.70, 0.18, -0.29, 1.58, 1.26, 1.0, 0.45),
    (-0.55, 1.80, 0.62, -0.70, 0.18, -0.29, 1.58, 1.26, 1.0, 0.45),
    (-0.85, 1.55, 0.62, -0.70, 0.18, -0.29, 1.36, 1.10, 1.0, 0.45),
    (-2.24, 1.55, 0.62, -0.70, 0.18, -0.29, 1.36, 1.10, 1.0, 0.45),
    (-2.3, 1.55, 0.62, -0.70, 0.18, -0.29, 1.36, 1.10, 0.30, 0.0),
    (-4.75, 1.55, 0.60, -0.68, 0.18, -0.29, 1.36, 1.10, 0.30, 0.0),
]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]   # the sheet kit's loft format, for the sheet tools
SHELL = 0.12
XF, XA = 5.5, -4.75
WELL = (2.3, -2.24)            # the cargo well's forward and aft walls
ZW = 0.62 - 0.45               # the well floor
BANDS = (2.42, 0.0, -2.42)     # module bands at 28, 50 and 72 percent (designs.md)
MODULES = (1.72, 0.62, -0.62, -1.72)   # the four cargo modules' centres: two either side of the middle band
ML, MW, MH = 0.86, 1.86, 1.0   # a module's length (along the ship), width (across) and height (from the well floor)


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
    """the port half of the section at x, deck centre (or well floor) to belly centre: [(y, z)], inset inward by about `inset`"""
    _, hw, zt, zb, kt, kb, dw, bw, yw, wd = st_at(x)
    hw -= inset; zt -= inset; zb += inset; dw -= inset * 0.5; bw -= inset * 0.5
    c = 0.09; c2 = 0.1
    yw = min(yw + inset * 0.5, dw - 0.06)
    zw = zt - wd
    kt_ = min(kt, zt - c - 0.02); kb_ = max(kb, zb + c2 + 0.02)
    return [(0.0, zw), (yw, zw), (yw + 0.002, zt), (dw, zt), (dw + c, zt - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


def hw_at(x, z, inset=0.0):
    """the section's half-width at height z (port side), inset by `inset`: 0 when z is outside (the outer skin only)"""
    h = half_ring(x, inset)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h[2:], h[3:]):
        if min(z0, z1) - 1e-6 <= z <= max(z0, z1) + 1e-6:
            if abs(z1 - z0) < 1e-6:
                best = max(best, y0, y1)
            else:
                best = max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


def deck_z(x, y):
    h = half_ring(x)
    return h[0][1] if abs(y) <= h[1][0] else h[3][1]


def belly_z(x):
    return st_at(x)[3]


def offset_loop(pts, d):
    """a closed (y, z) loop moved out by d along each vertex's bisector (H10's helper)"""
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


def tube(K, name, x0, x1, outer, inner, m, grp='hull'):
    n = len(outer)
    V = [(x0, y, z) for (y, z) in outer] + [(x1, y, z) for (y, z) in outer] + [(x0, y, z) for (y, z) in inner] + [(x1, y, z) for (y, z) in inner]
    F = []
    for i in range(n):
        j = (i + 1) % n
        F.append((i, j, n + j, n + i))
        F.append((2 * n + j, 2 * n + i, 3 * n + i, 3 * n + j))
        F.append((j, i, 2 * n + i, 2 * n + j))
        F.append((n + i, n + j, 3 * n + j, 3 * n + i))
    return K._obj(name, V, F, m, grp=grp)


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    plate_jobs = []

    # ---------------- the hull: one loft, the plain wedge forward, the cargo well amidships, the drive section aft ----------------
    xs = sorted({r[0] for r in ST} | {x / 4 for x in range(-18, 22)}, reverse=True)
    xs = [x for x in xs if XA <= x <= XF and not (2.3 < x < 2.36) and not (-2.3 < x < -2.24)]
    hull = K.loft_rings(CODE + '_hull', [ring(x) for x in xs], 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the wedge and the rails', hull, 'pale grey module plate',
           note='a plain wedge bow, the rails either side of the cargo well, the drive section aft: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a flat worked belly')
    K.mark('wedge', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('rails', 'rail', ['facet', 'step', 'strip'])
    grid = [XF - 0.15 - 0.5 * i for i in range(21)]
    grid = [x for x in grid if x >= XA + 0.05 and not (2.2 < x < 2.45) and not (-2.35 < x < -2.15)] + [XA + 0.05]
    plate_jobs.append(('deck', [ring(x) for x in grid], dict(faces=[0, 17, 2, 15], inv='deck_panels')))
    plate_jobs.append(('flank', [ring(x) for x in grid], dict(faces=[4, 13, 6, 11], inv='flank_panels')))
    plate_jobs.append(('belly', [ring(x) for x in grid], dict(faces=[8, 9], inv='belly_panels')))
    # the well's end walls: a trim lip on each
    for i, (x0, x1) in enumerate(((2.3, 2.38), (-2.32, -2.24))):
        K.box('O2_welllip_%d' % i, x0, x1, -1.0, 1.0, 0.6, 0.66, 'htrim', grp='hull')
    K.mark('cargo_well', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the bow: a solid armoured bumper plate with docking clamps (no trench, no gun, no terrace) ----------------
    hb = half_ring(XF)
    K.box('O2_bumper', XF - 0.02, XF + 0.1, -hb[5][0] + 0.12, hb[5][0] - 0.12, hb[6][1] + 0.02, hb[5][1] + 0.08, 'hgrey2', ch=0.03, grp='hull')
    K.box('O2_bumper_trim_t', XF + 0.06, XF + 0.12, -hb[5][0] + 0.15, hb[5][0] - 0.15, hb[5][1] + 0.03, hb[5][1] + 0.07, 'htrim', grp='hull')
    K.box('O2_bumper_trim_b', XF + 0.06, XF + 0.12, -hb[5][0] + 0.15, hb[5][0] - 0.15, hb[6][1] + 0.03, hb[6][1] + 0.07, 'htrim', grp='hull')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    for i, y in enumerate((0.3, -0.3)):
        K.organ('D%d' % (i + 1), HP.latch(n=3, pitch=0.16, w=0.11), (XF + 0.12, y, 0.0), (1, 0, 0), fwd=(0, 0, 1), inv='docking_clamps',
                what='docking clamp row (3 clamps)', kind='latch', note='a docking clamp on the bumper: the transport mates to a station or a tug here')

    # ---------------- the four cargo modules in the well ----------------
    for i, x in enumerate(MODULES):
        K.organ('C%d' % (i + 1), HP.container(ML, MW, MH), (x, 0.0, ZW + 0.012), (0, 0, 1), fwd=(1, 0, 0), inv='cargo',
                what='cargo module %.2f x %.2f x %.2f' % (ML, MW, MH), kind='container',
                note='one of four identical cargo modules locked in the well: a plain slab box, its lid, stiffener ribs, mooring clamps (designs.md); a loaded module is its own break piece')
    for i, x in enumerate(MODULES):
        for side in (1, -1):
            K.organ('LM%d%s' % (i + 1, 'p' if side > 0 else 's'), HP.latch(n=2, pitch=0.24, w=0.12), (x, side * 1.22, 0.62), (0, 0, 1), fwd=(1, 0, 0), inv='mooring',
                    what='mooring clamp pair', kind='latch', note='mooring clamps on the rail deck beside the module: they hold its lifting eyes')

    # ---------------- module bands at 28, 50 and 72 percent ----------------
    def band(x, loop, tag):
        for k, (a, b) in enumerate(((x + 0.11, x + 0.03), (x - 0.03, x - 0.11))):
            tube(K, 'O2_band_%s_%d' % (tag, k), b, a, offset_loop(loop, 0.05), offset_loop(loop, -0.02), 'htrim')
        tube(K, 'O2_bandseam_%s' % tag, x - 0.03, x + 0.03, offset_loop(loop, 0.018), offset_loop(loop, -0.02), 'hgrey2')
    for i, x in enumerate(BANDS):
        band(x, [(y, z) for (_, y, z) in ring(x)], 'b%d' % i)
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line along the flank band ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        cuts = sorted([XF - 0.25] + [b + d for b in BANDS for d in (0.16, -0.16)] + [XA + 0.15], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa, xb_ = cuts[k], cuts[k + 1]
            pts = []
            for j in range(9):
                x = xa + (xb_ - xa) * j / 8
                h = half_ring(x)
                pts.append((x, side * (h[5][0] + 0.003), (h[5][1] + h[6][1]) / 2))
            K.strip('O2_blue_%s%d' % (sn, k), pts, w=0.05, t=0.02, normals=[(0, side, 0)] * len(pts), m='hblue', grp='hull')
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- the sensor fin: one, low, ahead of the cargo row ----------------
    K.organ('A1', HP.antenna(0.3, L=1.3, t=0.22), (3.4, 0.0, deck_z(3.4, 0.0)), (0, 0, 1), fwd=(1, 0, 0), inv='sensor_fin',
            what='sensor fin, 0.3 tall, 1.3 long', kind='antenna', note='the one low sensor fin: the navigation and convoy link sensors; the bridge is under it')

    # ---------------- the drives: four rectangular nozzle pods in one flat row ----------------
    for k, y in enumerate((1.14, 0.38, -0.38, -1.14)):
        K.engine('E%d' % (k + 1), (-5.5, y, -0.16), 0.25, 0.78, bell=1.0, body_r=0.3, kw=dict(w=0.5, h=0.66),
                 inv='engines', note='nozzle pod %d of the flat row: a rectangular mouth, blue-white throat' % (k + 1))
        K.features[-1]['what'] = 'engine, rectangular nozzle 0.5 x 0.66'
    K.box('O2_sterncap', XA - 0.04, XA + 0.02, -1.42, 1.42, -0.55, 0.5, 'hgrey2', grp='hull')

    # ---------------- the belly: an armour step ----------------
    belly = []
    for x, k in ((4.2, 0.0), (3.9, 1.0), (2.6, 1.0), (0.4, 1.0), (-1.8, 1.0), (-3.9, 1.0), (-4.3, 0.0)):
        zb = belly_z(x); bw = st_at(x)[7] - 0.3
        belly.append([(x, bw, zb + 0.015), (x, bw - 0.06 * k, zb - 0.06 * k), (x, -bw + 0.06 * k, zb - 0.06 * k), (x, -bw, zb + 0.015)])
    K.mass('Belly armour step', K.loft_rings('O2_belly', belly, 'hgrey2'), 'recessed grey', note='a second plate under the holds')
    plate_jobs.append(('belly_step', belly, dict(faces=[1], inv='belly_panels', closed=False)))

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.thruster('Q1' + sn, (XF + 0.1, side * 0.72, 0.0), (1, 0, 0), inv='thrusters', r=0.13, note='retro thruster on the bow face: the transport brakes into a dock')
        K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        h = half_ring(-3.6)
        p = Vector((-3.6, side * (h[4][0] + h[5][0]) / 2, (h[4][1] + h[5][1]) / 2)); nrm = Vector((0, side * (h[4][1] - h[5][1]), h[5][0] - h[4][0])).normalized()
        K.thruster('Q2' + sn, tuple(p), tuple(nrm), inv='thrusters', r=0.14, note='stern attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        for i, x in enumerate((4.3, 3.95, 3.6)):
            h = half_ring(x)
            K.slit('W%d%s' % (i + 1, sn), (x, side * (h[5][0] + 0.05), h[5][1] - 0.06), (0, side, 0), 0.22, 0.06, inv='windows', note='blue-white window of the crew deck')
        for i, x in enumerate((1.8, 1.0, -1.2, -3.2)):
            K.hatch('H1%d%s' % (i, sn), (x, side * (st_at(x)[1] + 0.004), -0.2), (0, side, 0), 0.3, 0.13, inv='hatches', up=(0, 0, 1),
                    note='flank hatch on the band: stores and crew access to the holds')
        for i, x in enumerate((-2.9, -3.5, -4.1)):
            K.vent('V%d%s' % (i + 1, sn), (x, side * 0.7, deck_z(x, 0.7)), (0, 0, 1), 0.36, 0.5, slats=4, inv='vents', note='heat louvre over the reactor and the drives')
        for i, x in enumerate((1.17, -1.17)):
            K.vent('V%d%s' % (i + 4, sn), (x, side * 1.35, 0.62), (0, 0, 1), 0.2, 0.55, slats=5, inv='vents', note='hold louvre on the rail deck: the holds\' air plant')
    K.hatch('H1', (4.55, 0.0, deck_z(4.55, 0) + 0.012), (0, 0, 1), 0.4, 0.3, inv='hatches', note='deck hatch over the bridge')
    K.hatch('H2', (-3.4, 0.0, deck_z(-3.4, 0)), (0, 0, 1), 0.4, 0.3, inv='hatches', note='deck hatch over the engine room')
    K.hatch('H3', (0.0, 0.0, belly_z(0.0) - 0.06), (0, 0, -1), 0.5, 0.4, inv='hatches', note='belly hatch on the armour step: the lower hold')

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim (paint stage)', XF, -5.5, 'whole hull')
    K.colour('implant-blue light strips (the blue line), blue-white nozzles and windows', XF, -5.5, 'the flank bands, the stern')
    K.colour('no rust, no warm light, no asymmetry, no weapons', XF, -5.5, 'factions.md Never; designs.md: readable as defenseless')

    # ---------------- INSIDE: white corridors, blue emergency light, holds of identical racks ----------------
    IN = SHELL + 0.05

    def wid(x, z):
        return min(hw_at(x, z - 0.04, IN), hw_at(x, z + 0.04, IN))

    def slab(name, z, x0, x1, kind_name, n=4):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = wid(x, z) - 0.02
            rs.append([(x, hw, z - 0.03), (x, hw, z + 0.03), (x, -hw, z + 0.03), (x, -hw, z - 0.03)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))

    def frame_at(name, x):
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.08)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        V, F = [], []
        nn = len(fo)
        for k in range(nn):
            a_, b_ = k, (k + 1) % nn
            if math.hypot(fo[b_][0] - fo[a_][0], fo[b_][1] - fo[a_][1]) < 1e-4:
                continue
            q = [fo[a_], fo[b_], fi[b_], fi[a_]]
            o = len(V)
            V += [(x + 0.04, y_, z_) for (y_, z_) in q] + [(x - 0.04, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, y0=None, note=''):
        w = min(wid(x, z) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.05
        if ymax is not None:
            w = min(w, ymax)
        if y0 is None:
            K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)
        else:
            for side in (1, -1):
                ya, yb = (y0, w) if side > 0 else (-w, -y0)
                K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    # the bow compartment (5.5 to 2.42): the bridge, the crew deck, the bow stores
    slab('bow_main', 0.0, 4.6, 2.6, 'main')
    frame_at('F1', 4.3); frame_at('F2', 3.4); frame_at('F3', 2.6)
    room('bridge', 'bridge', 4.2, 2.65, 0.06, 0.4, ymax=0.8, note='the bridge under the sensor fin: the convoy link to its escorts')
    room('crew_deck', 'hcorr', 4.5, 2.65, 0.06, 0.4, y0=0.85, note='white corridors and crew berths, numbered posts')
    room('bow_stores', 'hold', 4.2, 2.65, -0.5, -0.06, note='bow stores and the retro thrusters\' feeds')
    # the cargo compartments (2.42 to 0.0, 0.0 to -2.42): the holds under the well floor
    for nm_, (x0, x1) in (('fwd', (2.2, 0.12)), ('aft', (-0.12, -2.2))):
        slab('hold_%s' % nm_, -0.32, x0, x1, 'hold')
        room('hold_%s' % nm_, 'hold', x0 - 0.05, x1 + 0.05, -0.27, 0.06, ymax=0.9, note='the lower hold: racks of identical sealed crates under the well floor')
        room('rail_corr_%s' % nm_, 'hcorr', x0 - 0.05, x1 + 0.05, 0.12, 0.42, y0=1.1, note='the rails\' corridors either side of the well, white, numbered')
        room('emerg_%s' % nm_, 'hemerg', x0 - 0.05, x1 + 0.05, 0.42, 0.45, y0=1.1, note='blue emergency light along the rails\' corridors')
    for i, x in enumerate((1.7, 0.6, -0.6, -1.7)):
        frame_at('F%d' % (i + 4), x)
    # the drive compartment (-2.42 to -4.75): the reactor and the engine room
    slab('aft_main', -0.1, -2.6, -4.55, 'main')
    for i, x in enumerate((-2.7, -3.5, -4.3)):
        frame_at('F%d' % (i + 8), x)
    room('reactor', 'core', -2.65, -3.6, -0.05, 0.42, ymax=0.8, note='the reactor (hp_core)')
    room('engine_room', 'engroom', -3.7, -4.5, -0.55, 0.42, note='the engine room and the four drives\' feeds')
    room('fuel', 'machinery', -2.65, -3.6, -0.55, -0.15, note='fuel and coolant plant under the reactor')
    K.armour('deck and facets', 0.12, 'machined plate in modules, flush panels over it')
    K.armour('bow face and bumper', 0.2, 'the solid bumper plate')
    K.armour('belly and armour step', 0.15, '')
    # seams: in modules at the bands (factions.md "How it breaks"), never a straight cut (R186); each module its own piece
    R = 3.0
    K.break_line('B-1', 2.42, 'the bow module tears off at the first band, the bridge with it',
                 path=[(2.42, R), (2.42, 1.4), (2.5, 0.6), (2.36, -0.2), (2.48, -1.0), (2.42, -1.4), (2.42, -R)])
    K.break_line('B-2', 0.0, 'the hull parts at the middle band between the module pairs, the well floor torn across',
                 path=[(0.0, R), (0.0, 1.4), (0.07, 0.5), (-0.07, -0.4), (0.05, -1.1), (0.0, -1.4), (0.0, -R)])
    K.break_line('B-3', -2.42, 'the drive section falls away at the last band, the nozzles with it',
                 path=[(-2.42, R), (-2.42, 1.4), (-2.34, 0.5), (-2.5, -0.3), (-2.36, -1.0), (-2.42, -1.4), (-2.42, -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors (R215), hidden until a piece breaks: white corridors, blue emergency light, the bridge, the holds of identical sealed crates, the reactor, the engine room. Each loaded cargo module breaks off as its own piece; the hull breaks in modules at the bands (factions.md).'))
    K.point('core', 'hp_core', (-3.1, 0, 0.15))
    # four breach anchors on the module joints (transport base 4, Hegemony +0; HARDPOINTS.md), port and starboard alternating
    for i, (x, sec, side) in enumerate(((2.42, 'prow', 1), (0.0, 'mid', -1), (0.0, 'mid', 1), (-2.42, 'eng', -1))):
        h = half_ring(x); y, z = h[5][0], (h[5][1] + h[6][1]) / 2 + 0.12
        K.point('breach', 'hp_breach_%d' % i, (x, side * (y + 0.06), z), side='port' if side > 0 else 'stbd', section=sec, note='on a module joint')
    for i, side in enumerate((1, -1)):
        K.point('rcs', 'hp_rcs_%d' % i, (XF + 0.25, side * 0.72, 0.0), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_%d' % i, (-1.2, side * (st_at(-1.2)[1] + 0.05), -0.12), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if WELL[1] - 0.05 < pc.x < WELL[0] + 0.05 and abs(pc.y) < 1.02 and pc.z < 0.55:
            return True   # the well floor and walls: the modules stand there
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.4, keep=keep, closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('O2_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='O2_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Four identical cargo modules in the well, two either side of the middle band (centres 15.6, 5.6, -5.6 and -15.6 percent off midships)',
             'designs.md: four modules govern (the beauty draws three); the module bands at 28, 50 and 72 percent never cross a module, so each loaded module breaks off whole')
    K.change('The module rings are raised trim bands with a deep seam at 28, 50 and 72 percent', 'designs.md break lines; factions.md: the Hegemony breaks in modules at the bulkhead rings')
    K.change('The sensor fin is one low fin at 19 percent, 0.3 tall, on the bow deck ahead of the well', 'designs.md: one low fin ahead of the cargo row; at 25 percent it would stand on the well\'s forward wall')
    K.change('The bow face is a solid bumper plate with two docking clamp rows and two retro thrusters; no trench, no gun, no terrace',
             'designs.md: readable as defenseless; the clamps mate it to a dock or a tug; data gives the transport no weapon (battle.js intercept clears its weapons)')
    K.change('Four rectangular nozzle pods in one flat row at the stern (0.5 by 0.66 mouths)', 'designs.md and factions.md: a flat row of rectangular blue-white nozzles')
    K.change('The well\'s floor holds the lower holds; the rails carry the corridors either side; the drive section aft is closed deck with reactor louvres',
             'every part has a job (R221); the concept shows the well running nearly to the stern, cut short here so the drive section is its own break piece (B-3)')
    K.change('Flank hatches, blue-white crew windows, hold louvres on the rail decks, mooring clamps beside each module, a belly armour step added',
             'a transport needs access, light and air (lore 3.3); the mooring clamps hold the modules; the concept shows no underside (R221)')
    K.open_item('The belly is designed here; the concept shows no underside')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled')


INV_NOTES = {}
