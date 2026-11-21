# hegemony_O3: the Relay beacon, the Hegemony Navy-built objective relay the game places on relay maps (godot/render/hull_table.gd
# AI_HULLS "obj|beacon" = O3_11). Issue 1413. Shape of record: contrib/muse/design/class_family_hegemony_2026_11/ (relay_sheet.webp,
# relay_beauty.webp; designs.md "RELAY BEACON" governs where a picture differs; Ryan took the Navy five Nov 20 2026, R369, PR 1168).
# Not a data.js ship: tools/recipe/gamedata.py names it obj_beacon (class beacon: no weapons, no engines, no breach anchors;
# tools/blender/kits/shared/hardpoints.py required_points). Designer of record: the Opus builder, the Board the final designer
# (R205, R207, R233, R236): the concept is a base.
# Family pattern: the Convoy (hegemony_O2.py): pale grey module plate, the module bands with a deep seam, the flush panel grid,
# implant-blue light strips, machined clamps.
# Read off the relay sheet (top view upper left, drawn LENS DOWN, so the sheet tools turn it a quarter; side view upper right,
# lens on the left; front view below) and the beauty (the lens toward the viewer): one boxy relay module with an oversized
# recessed blue lens in its forward face, two rails either side running along the module (four rails, two heights), a cradle
# clamping the rails to the module's middle, one low sensor fin aft on the module's top. The top view's module is 2.2 wide and
# 3.35 long, the rails 7.6 long (210 px = 2.2 units); the side view draws a longer module (picture slip, the top view governs).
# +X the lens (forward), +Y port, +Z up. The rail ends are x +-3.75; the module x -1.55 to +0.95, the lens face to +1.5.
import math

CODE = 'hegemony_O3'
NAME = 'Relay beacon (Hegemony Navy objective)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'beacon'
LENGTH = 7.5
GAME = "data.js obj_beacon (no data.js ship: tools/recipe/gamedata.py OBJECTIVES, the relay objective); length 7.5 rail end to rail end: designs.md's proposal, locked by the Board Nov 20 2026 (the Godot game never places or breaks the beacon, so no game table carries it)"
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_O3/concept_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_O3/concept_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(250, 15, 690, 765), largest=True, flip=False, rot=-90), side=dict(box=(830, 230, 1870, 530), largest=True, flip=False))
CROPS = [('the lens (the forward face, the stepped rings)', (560, 280, 1160, 980)), ('the cradle (the rail clamps, the module side)', (800, 300, 1500, 950)),
         ('the module top (the sensor fin, the panels)', (900, 100, 1500, 700))]
SHEET = dict(version=1, round='first sheet', date='2026-11-20', blend='opus1413',
             blend_where='rendered in the issue 1413 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_O3 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

# ---------------------------------------------------------------------------------------------------- the module section
# a square module with chamfered edges (the octagon of the front view): half-width and half-height H, chamfer legs CH
H, CH = 1.1, 0.25
XF, XA = 0.95, -1.55           # the module's front (the lens face's back) and its rear
LD = 0.55                      # the lens face block's depth (its front at XF + LD)
BANDS = (0.45, -0.5)           # module bands (the relay-ring module joints)
RY, RZ, RW, RT = 1.9, 0.42, 0.3, 0.3   # the rails: centre y and z, width (y) and height (z)
RX = 3.75                      # the rails' ends
HULL = [(x, H, H, -H, H, 0.0, 0.0) for x in (XF + LD, XF, 0.0, XA + 0.08, XA)]
SHELL = 0.08


def oct_yz(inset=0.0, h=H, ch=CH):
    """the module section as (y, z), clockwise from the top port corner (port is +y): edges 1, 3, 5, 7 are the flat port side,
    belly, starboard side and top"""
    a = h - inset; c = ch * (a / h) if h else ch
    return [(a - c, a), (a, a - c), (a, -a + c), (a - c, -a), (-a + c, -a), (-a, -a + c), (-a, a - c), (-a + c, a)]


def ring(x, inset=0.0):
    return [(x, y, z) for (y, z) in oct_yz(inset)]


def ring_fine(x, inset=0.0, k=4):
    """the section with each flat face cut into k: the hull loft's faces stay near square, not long slivers (the game's
    death cut splits a sliver only so far, then sends it whole to one piece, so its liner stood past the torn plating)"""
    o = oct_yz(inset); out = []
    for i in range(len(o)):
        a, b = o[i], o[(i + 1) % len(o)]
        n = k if i % 2 == 1 else 2
        out += [(a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n) for j in range(n)]
    return [(x, y, z) for (y, z) in out]


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
    K.hull_sections = list(HULL)
    K.hull_rounded = False
    plate_jobs = []

    # ---------------- the relay module: one chamfered box, its rear edge stepped in ----------------
    xs = [XF] + [x / 4 for x in range(3, -6, -1)] + [XA + 0.08, XA]
    rings = [ring_fine(x, 0.07 if x == XA else 0.0) for x in xs]
    hull = K.loft_rings(CODE + '_hull', rings, 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Relay module', hull, 'pale grey module plate',
           note='the relay module: a square section with chamfered edges, the relay core inside, the lens in its forward face')
    K.mark('module', 'hull', ['facet', 'step', 'chamfer'])
    grid = [XF - 0.05 - 0.4 * i for i in range(7)]
    grid = [x for x in grid if x >= XA + 0.1 and not any(abs(x - b) < 0.14 for b in BANDS)] + [XA + 0.1]
    plate_jobs.append(('module', [ring(x) for x in grid], dict(faces=[1, 3, 5, 7], inv='module_panels')))

    # ---------------- the lens: ONE oversized recessed blue lens in the forward face ----------------
    K.organ('L1', HP.relay_lens(H, 0.86, LD, ch=CH), (XF, 0.0, 0.0), (1, 0, 0), fwd=(0, 0, 1), inv='lens',
            what='relay lens, 1.72 across, in a %.2f deep face block' % LD, kind='relay_lens',
            note='the relay lens: stepped machined rings down to a blue lens, a thin blue ring at the mouth that pulses in time with the fleet; no muzzle lip, no trench (designs.md)')

    # ---------------- the module bands (the relay-ring module joints) ----------------
    loop = oct_yz()
    for i, x in enumerate(BANDS):
        for k, (a, b) in enumerate(((x + 0.11, x + 0.03), (x - 0.03, x - 0.11))):
            tube(K, 'O3_band_%d_%d' % (i, k), b, a, offset_loop(loop, 0.05), offset_loop(loop, -0.02), 'htrim')
        tube(K, 'O3_bandseam_%d' % i, x - 0.03, x + 0.03, offset_loop(loop, 0.018), offset_loop(loop, -0.02), 'hgrey2')
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the rails: four, two either side, running along the module ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for lev, z in (('u', RZ), ('l', -RZ)):
            y0, y1 = side * RY - RW / 2, side * RY + RW / 2
            K.mass('Rail, %s %s' % ('port' if side > 0 else 'starboard', 'upper' if lev == 'u' else 'lower'),
                   K.box('O3_rail_%s%s' % (sn, lev), -RX + 0.12, RX - 0.12, y0, y1, z - RT / 2, z + RT / 2, 'hgrey', ch=0.04, grp='hull'), 'pale grey module plate',
                   note='a cradle rail: a chamfered beam with flush panels, end caps and blue light strips')
            for e in (1, -1):   # machined end caps
                K.box('O3_railcap_%s%s%d' % (sn, lev, e > 0), (RX - 0.14) if e > 0 else -RX, RX if e > 0 else -(RX - 0.14),
                      y0 - 0.025, y1 + 0.025, z - RT / 2 - 0.025, z + RT / 2 + 0.025, 'hgrey2', ch=0.03, grp='hull')
                K.box('O3_railcapband_%s%s%d' % (sn, lev, e > 0), (RX - 0.2) if e > 0 else -(RX - 0.14), (RX - 0.14) if e > 0 else -(RX - 0.2),
                      y0 - 0.012, y1 + 0.012, z - RT / 2 - 0.012, z + RT / 2 + 0.012, 'htrim', grp='hull')
            # flush panels along the rail's outer face and its top (two module sizes), the joints dark
            yo = side * (RY + RW / 2)
            for k, (xa, xb) in enumerate(((3.45, 2.2), (2.1, 1.25), (-1.25, -2.1), (-2.2, -3.45))):
                K.box('O3_railpanel_%s%s%d' % (sn, lev, k), xb, xa, min(yo, yo + side * 0.012), max(yo, yo + side * 0.012), z - RT * 0.32, z + RT * 0.32, 'hpanel', grp='hull')
                K.box('O3_railtop_%s%s%d' % (sn, lev, k), xb, xa, side * RY - RW * 0.32, side * RY + RW * 0.32, z + RT / 2, z + RT / 2 + 0.01, 'hpanel', grp='hull')
            # the blue line: short implant-blue strips on the outer face, broken at the panels
            for k, x in enumerate((2.9, 1.6, -1.6, -2.9)):
                K.strip('O3_blue_%s%s%d' % (sn, lev, k), [(x + 0.14, yo + side * 0.012, z), (x - 0.14, yo + side * 0.012, z)], w=0.04, t=0.014,
                        normals=[(0, side, 0)] * 2, m='hblue', grp='hull')
    K.mark('rails', 'rail', ['facet', 'step', 'strip'])
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- the cradle: a saddle on each side of the module's middle, an arm and a clamp round each rail ----------------
    cx0, cx1 = -0.3, 0.2
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        y_in, y_out = side * (H - 0.02), side * (H + 0.16)
        K.mass('Cradle, %s' % ('port' if side > 0 else 'starboard'),
               K.box('O3_saddle_%s' % sn, cx0, cx1, min(y_in, y_out), max(y_in, y_out), -0.72, 0.72, 'hgrey2', ch=0.04, grp='hull'), 'recessed grey',
               note='the cradle saddle on the module side, its arms and clamps round the two rails')
        for lev, z in (('u', RZ), ('l', -RZ)):
            ya, yb = side * (H + 0.14), side * (RY - RW / 2 + 0.02)
            K.box('O3_arm_%s%s' % (sn, lev), cx0 + 0.08, cx1 - 0.08, min(ya, yb), max(ya, yb), z - 0.11, z + 0.11, 'hgrey', ch=0.03, grp='hull')
            ya, yb = side * (RY - RW / 2 - 0.07), side * (RY + RW / 2 + 0.07)
            K.box('O3_clamp_%s%s' % (sn, lev), cx0, cx1, min(ya, yb), max(ya, yb), z - RT / 2 - 0.07, z + RT / 2 + 0.07, 'hgrey2', ch=0.04, grp='hull')
            K.box('O3_clampband_%s%s' % (sn, lev), cx0 + 0.16, cx1 - 0.16, min(ya, yb) - 0.015, max(ya, yb) + 0.015, z - RT / 2 - 0.085, z + RT / 2 + 0.085, 'htrim', grp='hull')
    K.mark('cradle', 'rail', ['facet', 'step', 'strip'])
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for lev, z in (('u', RZ), ('l', -RZ)):
            K.organ('K%s%s' % (sn, lev), HP.latch(n=2, pitch=0.2, w=0.1), (-0.05, side * (RY + RW / 2 + 0.07), z), (0, side, 0), fwd=(0, 0, 1), inv='cradle_latches',
                    what='cradle latch pair', kind='latch', note='the latch that locks the cradle clamp round the rail')

    # ---------------- four mooring collars on the rails ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for lev, z, x in (('u', RZ, 3.0), ('l', -RZ, -3.0)):
            y0, y1 = side * RY - RW / 2 - 0.04, side * RY + RW / 2 + 0.04
            K.box('O3_collar_%s%s' % (sn, lev), x - 0.16, x + 0.16, y0, y1, z - RT / 2 - 0.04, z + RT / 2 + 0.04, 'htrim', ch=0.02, grp='hull')
            K.organ('M%s%s' % (sn, lev), HP.latch(n=2, pitch=0.16, w=0.09), (x, side * (RY + RW / 2 + 0.04), z), (0, side, 0), fwd=(1, 0, 0), inv='mooring',
                    what='mooring collar latch', kind='latch', note='a mooring collar on the rail: tugs and tenders make fast here')
    K.mark('mooring_collars', 'band', ['band', 'seam', 'strip'])

    # ---------------- the sensor fin: one, low, aft on the module's top ----------------
    K.organ('A1', HP.antenna(0.42, L=0.7, t=0.18), (-1.03, 0.0, H), (0, 0, 1), fwd=(1, 0, 0), inv='sensor_fin',
            what='sensor fin, 0.42 tall, 0.7 long', kind='antenna', note='the one low sensor fin: the relay\'s own fleet link and station keeping sensors')

    # ---------------- station-keeping thruster pads on the module's chamfered edges (no propulsion row) ----------------
    for i, x in enumerate((0.72, -1.05)):
        for sy in (1, -1):
            for sz in (1, -1):
                c = H - CH / 2
                nm = 'Q%d%s%s' % (i + 1, 'p' if sy > 0 else 's', 'u' if sz > 0 else 'l')
                K.thruster(nm, (x, sy * c, sz * c), (0, sy, sz), inv='thrusters', r=0.1,
                           note='station-keeping thruster pad: the relay holds its place, it does not fly')
                K.features[-1]['what'] = 'station-keeping thruster, two rectangular nozzles'

    # ---------------- fittings ----------------
    K.hatch('H1', (-0.05, 0.0, H), (0, 0, 1), 0.36, 0.3, inv='hatches', note='deck hatch: the maintenance crew\'s way into the relay core')
    K.hatch('H2', (-0.05, 0.0, -H), (0, 0, -1), 0.36, 0.3, inv='hatches', note='belly hatch: stores and the core\'s spares')
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.vent('V1' + sn, (-1.05, side * 0.62, H), (0, 0, 1), 0.3, 0.5, slats=4, inv='vents', note='heat louvre over the relay core\'s cooling plant')
        K.vent('V2' + sn, (0.72, side * 0.55, H), (0, 0, 1), 0.24, 0.42, slats=4, inv='vents', note='heat louvre behind the lens: the emitter\'s cooling')
        # round 2 (Ryan, Nov 21: "make sure the level of detail is on both so they don't look like clay"): the big flat module
        # faces get the working fittings a Registry hull carries, in the even Navy order (paired, clear of the bands)
        K.vent('V3' + sn, (-1.05, side * 0.62, -H), (0, 0, -1), 0.3, 0.5, slats=4, inv='vents', note='belly heat louvre: the cooling plant\'s lower intake')
        K.hatch('H3' + sn, (0.72, side * 0.55, -H), (0, 0, -1), 0.24, 0.2, inv='hatches', note='belly access plate under the emitter')
        K.hatch('H4' + sn, (0.15, side * 0.6, H), (0, 0, 1), 0.2, 0.16, inv='hatches', note='small deck access plate over the relay core')
        for i, x in enumerate((0.72, -1.05)):
            K.hatch('H5%d%s' % (i, sn), (x, side * (H + 0.004), 0.0), (0, side, 0), 0.26, 0.16, inv='hatches', up=(0, 0, 1),
                    note='side access plate on the module face, between the rails')

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim (paint stage)', XF + LD, -RX, 'whole relay')
    K.colour('implant-blue lens and light strips, the pulsing ring at the lens mouth', XF + LD, -RX, 'the lens, the rails')
    K.colour('no rust, no warm light, no asymmetry, no weapons, no propulsion row', XF + LD, -RX, 'factions.md Never; designs.md: no prow, no drive')

    # ---------------- INSIDE: the relay core, racks of identical equipment, a white maintenance corridor ----------------
    IN = SHELL + 0.05

    def frame_at(name, x):
        fo = oct_yz(IN); fi = oct_yz(IN + 0.08)
        V, F = [], []
        nn = len(fo)
        for k in range(nn):
            a_, b_ = k, (k + 1) % nn
            q = [fo[a_], fo[b_], fi[b_], fi[a_]]
            o = len(V)
            V += [(x + 0.04, y_, z_) for (y_, z_) in q] + [(x - 0.04, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def slab(name, z, x0, x1, kind_name):
        w = H - IN - 0.05
        K.box('in_deck_' + name, min(x0, x1), max(x0, x1), -w, w, z - 0.03, z + 0.03, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))
    W = H - IN - 0.1
    # three compartments between the module bands; nothing inside crosses a band, so each piece keeps its own insides
    G = 0.08
    comps = (('fwd', BANDS[0] + G, 0.85), ('mid', BANDS[1] + G, BANDS[0] - G), ('aft', XA + 0.15, BANDS[1] - G))
    for nm_, x0, x1 in comps:
        slab(nm_, -0.35, x1, x0, 'main')
        K.room('corr_' + nm_, 'hcorr', x0, x1, 0.65, W, -0.3, 0.42, note='the white maintenance corridor, numbered posts')
        K.room('emerg_' + nm_, 'hemerg', x0, x1, 0.65, W, 0.42, 0.47, note='blue emergency light along the corridor')
        K.room('stores_' + nm_, 'hold', x0, x1, -0.7, 0.7, -0.85, -0.42, note='spares and the power cells under the main deck')
    frame_at('F2', -0.03); frame_at('F3', -1.05)   # no frame in the short lens module: the cut's bite would reach it
    K.room('emitter', 'core', BANDS[0] + G, 0.85, -0.6, 0.6, -0.3, 0.6, note='the lens emitter and its focusing coils, behind the lens (hp_core)')
    K.room('relay_core', 'machinery', BANDS[1] + G, BANDS[0] - G, -0.6, 0.6, -0.3, 0.6, note='the relay core: racks of identical signal equipment, blue status light')
    K.room('cooling', 'hold', XA + 0.15, BANDS[1] - G, -0.6, 0.6, -0.3, 0.6, note='the cooling plant under the louvres')
    K.armour('module plate', 0.1, 'machined plate in modules, flush panels over it')
    K.armour('lens face', 0.2, 'the face block round the lens')
    # seams: at the relay-ring module joints (designs.md), never a straight cut (R186); the rails part with them
    R = 1.4
    K.break_line('B-1', BANDS[0], 'the lens module tears off at the forward joint, the lens with it',
                 path=[(BANDS[0], R), (BANDS[0], 1.15), (BANDS[0] + 0.05, 0.4), (BANDS[0] - 0.05, -0.4), (BANDS[0], -1.15), (BANDS[0], -R)])
    K.break_line('B-2', BANDS[1], 'the aft module falls away at the rear joint, the fin and the cooling plant with it',
                 path=[(BANDS[1], R), (BANDS[1], 1.15), (BANDS[1] - 0.05, 0.4), (BANDS[1] + 0.05, -0.4), (BANDS[1], -1.15), (BANDS[1], -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors (R215), hidden until a piece breaks: the lens emitter, the relay core\'s racks of identical equipment, a white maintenance corridor with blue emergency light, the cooling plant, the stores. It breaks into modules at the relay-ring joints (designs.md); the rails part with the modules.'))
    K.point('core', 'hp_core', (0.68, 0.0, 0.1))

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if abs(pc.y) > H - 0.05 and cx0 - 0.05 < pc.x < cx1 + 0.05:
            return True   # the cradle saddles
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.4, keep=keep, closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('O3_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='O3_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('The rails run along the module, two either side at two heights, in every view', 'designs.md: the front view\'s sideways rails are a picture slip; the top view, the side view and the beauty run them along the module')
    K.change('Length 7.5 to the rail ends, the cradle 4.1 across the rails, the module 2.2 square',
             'designs.md proposes a 7.5 footprint and a 4.8 cradle span; the top view draws the rails 4.1 apart (followed); the Board locked 7.5')
    K.change('The cradle is one saddle per side at the module\'s middle, an arm and a latched clamp round each rail', 'the top and side views clamp the rails at the middle; a clamp needs a latch (R221)')
    K.change('Four mooring collars, one per rail, the upper pair forward and the lower pair aft', 'designs.md: four mooring collars on the rails; mirrored port and starboard (factions.md: no asymmetry)')
    K.change('Eight station-keeping thruster pads on the module\'s chamfered edges, two stations', 'designs.md: pads on the module\'s sides only, no propulsion row; on the chamfers they fire clear of the rails')
    K.change('Module bands at the relay-ring joints (x +0.45 and -0.5) carry the break lines; the cradle joints are not a separate seam',
             'designs.md: it breaks into modules, not a spine; the rails part with the module pieces')
    K.change('A deck hatch, a belly hatch and four heat louvres added; the side view\'s longer module not followed', 'a maintained relay needs access and cooling (R221); the top view governs the module\'s length')
    K.open_item('The lens ring\'s pulse in time with the fleet is a game effect, not modelled')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled')


INV_NOTES = {}
