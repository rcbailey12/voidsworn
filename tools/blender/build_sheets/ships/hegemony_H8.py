# hegemony_H8: the Cordon destroyer, the Hegemony Navy's ion escort (godot/rules/data/tables.json h_interdictor, "Cordon
# destroyer", class Destroyer, 9.5 world units). Issue 1412. Shape of record: Muse run 3 (issue 1146, PR 1707):
# contrib/muse/design/class_family_hegemony_2026_11/cordon_sheet.webp and cordon_beauty.webp, copied to
# docs/ship_pipeline/build_sheets/hegemony_H8/concept_*.jpg; designs.md "CORDON" is the table. Ryan took the Cordon Nov 22 2026.
# Rules: ion F (1 shot), turbo T (the Plasma lance, 2 shots); ability ionpulse; no hangar.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): the concept is a base.
# Family pattern: the Dominion (hegemony_H10.py, its ion accelerator shared), the Picket (hegemony_H7.py): pale grey module
# plate, the faceted section round a vertical flank band with the blue line, module bands with a deep seam, the flush panel grid.
# Read off the cordon sheet (top view on the right, BOW AT THE TOP; port side view lower left, BOW ON THE LEFT; 850 px = 9.5
# units in the top view): the anvil. A deep ion block with slab sides at the full beam, its bow corners chamfered in plan; a hard
# step where the beam comes in 0.65 a side and the deck drops in the same face; a narrower aft body to a flat transom. Both
# views draw the step near half length (the table says 35 percent); this sheet puts it at 48 percent (see the changes).
# +X bow, +Y port, +Z up. Bow face x = +4.75, transom x = -4.75; the flank bands straddle z 0.
import math
from ships.hegemony_H10 import ion_trench

CODE = 'hegemony_H8'
NAME = 'Cordon destroyer (Hegemony Navy escort)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js h_interdictor (cls 'Destroyer', 'Cordon destroyer'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5; game folder H8_23 (AI_HULLS hegemony|Destroyer)"
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_H8/concept_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_H8/concept_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(1140, 105, 1510, 1040), largest=True, flip=False, rot=90), side=dict(box=(55, 795, 1060, 995), largest=True, flip=False))
CROPS = [('bow (the ion block and the trench)', (170, 420, 960, 1010)), ('midships (the lance turret, the step, the fin)', (700, 300, 1400, 950)),
         ('stern (the aft body, the transom and the nozzle pods)', (1250, 230, 1920, 760))]
SHEET = dict(version=1, round='first sheet', date='2026-11-22', blend='opus1412',
             blend_where='rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H8 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

XF, XS = 4.75, -4.75            # the bow face and the stern transom
XB = 3.8                        # the trench's back wall: the block's loft ends here, the bow frame runs on to the face
STEP = 0.2                      # the step: the ion block's aft face, the aft body starts here
TRENCH = dict(w=1.1, h=0.6, zc=-0.05)
BANDS_B = (2.75,)               # module band on the ion block
BANDS_A = (STEP - 0.12, -2.3)   # the step's band on the aft body, and the second bulkhead ring
TURRET = 1.15                   # the lance turret on the block's aft deck
FIN = (-0.75, 0.28, 1.2)        # the sensor fin on the aft body: x, height, length
SHELL = 0.12
C1, C2 = 0.1, 0.12

# (x, half-beam, deck z, belly z) keys and the section's band and edge offsets for each mass
BLOCK = dict(keys=[(4.75, 1.25, 0.70, -0.62), (4.35, 1.45, 0.74, -0.68), (3.7, 1.6, 0.75, -0.70), (STEP, 1.6, 0.75, -0.70)], kt=0.18, kb=-0.32, ddw=0.3, dbw=0.25)
AFT = dict(keys=[(STEP, 0.95, 0.40, -0.62), (XS, 0.95, 0.40, -0.62)], kt=0.10, kb=-0.24, ddw=0.22, dbw=0.18)


def key_at(m, x):
    s = m['keys']
    if x >= s[0][0]:
        return list(s[0])
    if x <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0]) if a[0] != b[0] else 0.0
            return [a[i] + (b[i] - a[i]) * t for i in range(4)]


def mass_at(x):
    return BLOCK if x > STEP else AFT


def st_at(x, m=None):
    m = m or mass_at(x)
    _, hw, zt, zb = key_at(m, x)
    dw = hw - m['ddw']; bw = hw - m['dbw']
    return [x, hw, zt, zb, m['kt'], m['kb'], dw, bw, dw * 0.45, dw * 0.7, 0.0]


HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in [st_at(k[0], BLOCK) for k in BLOCK['keys']] + [st_at(k[0] - 1e-3, AFT) for k in AFT['keys']]]


def half_ring(x, inset=0.0, m=None):
    _, hw, zt, zb, kt, kb, dw, bw, y1, y1b, sd = st_at(x, m)
    hw -= inset; zt -= inset; zb += inset; dw -= inset * 0.5; bw -= inset * 0.5; y1 -= inset * 0.5; y1b -= inset * 0.5
    kt_ = min(kt, zt - C1 - 0.02); kb_ = max(kb, zb + C2 + 0.02)
    return [(0.0, zt), (y1, zt), (y1b, zt), (dw, zt), (dw + C1, zt - C1), (hw, kt_), (hw, kb_), (bw + C2, zb + C2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0, m=None):
    h = half_ring(x, inset, m)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


def hw_at(x, z, inset=0.0, m=None):
    h = half_ring(x, inset, m)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h, h[1:]):
        if min(z0, z1) - 1e-6 <= z <= max(z0, z1) + 1e-6:
            if abs(z1 - z0) < 1e-6:
                best = max(best, y0, y1)
            else:
                best = max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


def deck_z(x):
    return half_ring(x)[0][1]


def belly_z(x):
    return st_at(x)[3]


def facet(x, i, side, frac=0.5):
    """a point on the port (side +1) or starboard edge i of the half section at x, and its outward normal"""
    from mathutils import Vector
    h = half_ring(x)
    (ya, za), (yb, zb) = h[i], h[i + 1]
    p = Vector((x, side * (ya + (yb - ya) * frac), za + (zb - za) * frac))
    n = Vector((0, side * (zb - za), -(yb - ya)))
    if n.length < 1e-6:
        n = Vector((0, side, 0))
    n.normalize()
    if (n.y * side) < 0 and abs(n.z) < 0.9:
        n = -n
    return p, n


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


def dedupe(loop, eps=1e-4):
    out = []
    for p in loop:
        if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > eps:
            out.append(p)
    if len(out) > 1 and math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1]) < eps:
        out.pop()
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

    # ---------------- the ion block: one loft from the trench's back wall to the step ----------------
    xs = sorted({k[0] for k in BLOCK['keys'] if STEP <= k[0] <= XB} | {XB, STEP} | {x / 4 for x in range(1, 16)}, reverse=True)
    xs = [x for x in xs if STEP <= x <= XB]
    blk = K.loft_rings(CODE + '_block', [ring(x, m=BLOCK) for x in xs], 'hgrey')
    md = blk.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the ion block', blk, 'pale grey module plate',
           note='the deep forward block: slab sides at the full beam, a flat deck, chamfered deck edges, upper facets, the tall flank band in two tiers, lower facets, a flat belly; its aft face is the step')
    K.mark('ion_block', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('step', 'hull', ['facet', 'step', 'chamfer'])
    grid = [XB - 0.06 - 0.36 * i for i in range(12)]
    grid = [x for x in grid if x >= STEP + 0.06 and not any(abs(x - b) < 0.16 for b in BANDS_B)] + [STEP + 0.06]
    plate_jobs.append(('block_deck', [ring(x, m=BLOCK) for x in grid], dict(faces=[0, 1, 2, 15, 16, 17], inv='deck_panels')))
    plate_jobs.append(('block_flank', [ring(x, m=BLOCK) for x in grid], dict(faces=[4, 13, 6, 11], inv='flank_panels')))
    plate_jobs.append(('block_belly', [ring(x, m=BLOCK) for x in grid], dict(faces=[8, 9], inv='belly_panels')))

    # ---------------- the aft body: one narrower loft from the step to the transom ----------------
    xa = [STEP] + [STEP - 0.25 * i for i in range(1, 40) if STEP - 0.25 * i > XS] + [XS]
    aft = K.loft_rings(CODE + '_aft', [ring(x, m=AFT) for x in xa], 'hgrey')
    md = aft.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the aft body', aft, 'pale grey module plate', note='one narrower hull, sides parallel to a flat transom, the same faceted section with one flank band')
    K.mark('aft_body', 'hull', ['facet', 'step', 'chamfer'])
    grid = [STEP - 0.3 - 0.36 * i for i in range(14)]
    grid = [x for x in grid if x >= XS + 0.06 and not any(abs(x - b) < 0.16 for b in BANDS_A)] + [XS + 0.06]
    plate_jobs.append(('aft_deck', [ring(x, m=AFT) for x in grid], dict(faces=[0, 1, 2, 15, 16, 17], inv='deck_panels')))
    plate_jobs.append(('aft_flank', [ring(x, m=AFT) for x in grid], dict(faces=[4, 13, 6, 11], inv='flank_panels')))
    plate_jobs.append(('aft_belly', [ring(x, m=AFT) for x in grid], dict(faces=[8, 9], inv='belly_panels')))
    # the step face: a trim frame round the aft body where it leaves the block, armour plates on the face either side
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.box('H8_stepplate_%s' % sn, STEP - 0.03, STEP + 0.004, side * 1.02 if side > 0 else -1.42, 1.42 if side > 0 else -1.02, -0.5, 0.55, 'hpanel', ch=0.015, grp='hull')

    # ---------------- the bow: a blunt armoured face round the ion trench (R183 (1)) ----------------
    tw, th, tz = TRENCH['w'] / 2, TRENCH['h'] / 2, TRENCH['zc']

    def rect_match(loop):
        out = []
        for (y, z) in loop:
            dy, dz = y, z - tz
            k = min(tw / abs(dy) if abs(dy) > 1e-9 else 1e9, th / abs(dz) if abs(dz) > 1e-9 else 1e9)
            out.append((dy * k, tz + dz * k))
        return out
    xs_b = [XB, 4.2, 4.5, XF]
    loops = [[(y, z) for (_, y, z) in ring(x, m=BLOCK)] for x in xs_b]
    inner = rect_match(loops[-1])
    n = len(inner)
    V, F = [], []
    for x, lp in zip(xs_b, loops):
        V += [(x, y, z) for (y, z) in lp]
    for x in xs_b:
        V += [(x, y, z) for (y, z) in inner]
    m = len(xs_b)
    for k in range(m - 1):
        for i in range(n):
            j = (i + 1) % n
            F.append((k * n + i, k * n + j, (k + 1) * n + j, (k + 1) * n + i))
            F.append(((m + k) * n + j, (m + k) * n + i, (m + k + 1) * n + i, (m + k + 1) * n + j))
    for i in range(n):
        j = (i + 1) % n
        F.append(((m - 1) * n + i, (m - 1) * n + j, (2 * m - 1) * n + j, (2 * m - 1) * n + i))
        F.append((j, i, m * n + i, m * n + j))
    bowf = K._obj(CODE + '_bowframe', V, F, 'hgrey', grp='hull')
    # open the accelerator's roof within the bow module (R287 run 2, as the Dominion and the Iron Mandate): the lens reads from above
    cutter = K.box('ion_roof_cutter', XB + 0.15, XF - 0.08, -tw + 0.06, tw - 0.06, tz + th - 0.02, 1.2, 'hgrey', grp='hull')
    cut = bowf.modifiers.new('ion roof window', 'BOOLEAN')
    cut.operation = 'DIFFERENCE'; cut.solver = 'EXACT'; cut.object = cutter
    bpy.context.view_layer.objects.active = bowf
    bpy.ops.object.modifier_apply(modifier=cut.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    K.mass('Bow face round the ion trench', bowf, 'pale grey module plate', note='the blunt bow face (never a ship\'s stem): the block\'s facets run to it, the trench recessed in its middle')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    for k, (y0, y1, z0, z1) in enumerate(((-tw - 0.1, tw + 0.1, tz + th + 0.04, tz + th + 0.13), (-tw - 0.1, tw + 0.1, tz - th - 0.2, tz - th - 0.04),
                                          (tw + 0.04, tw + 0.2, tz - th + 0.02, tz + th - 0.02), (-tw - 0.2, -tw - 0.04, tz - th + 0.02, tz + th - 0.02))):
        K.box('H8_bowplate_%d' % k, XF - 0.02, XF + 0.05, y0, y1, z0, z1, 'hpanel', ch=0.015, grp='hull')
    K.box('H8_bowtrim_t', XF, XF + 0.06, -tw - 0.035, tw + 0.035, tz + th, tz + th + 0.035, 'htrim', grp='hull')
    K.box('H8_bowtrim_b', XF, XF + 0.06, -tw - 0.035, tw + 0.035, tz - th - 0.035, tz - th, 'htrim', grp='hull')
    for s_ in (1, -1):
        K.box('H8_bowtrim_%s' % ('p' if s_ > 0 else 's'), XF, XF + 0.06, tw if s_ > 0 else -tw - 0.035, tw + 0.035 if s_ > 0 else -tw, tz - th, tz + th, 'htrim', grp='hull')
    ion_trench(K, (XB, 0.0, tz), XF - XB, TRENCH['w'], TRENCH['h'], coils=3, r=0.3, open_roof=True)

    # ---------------- the module bands ----------------
    def band(x, loop, tag):
        loop = dedupe(loop)
        for k, (a, b) in enumerate(((x + 0.11, x + 0.03), (x - 0.03, x - 0.11))):
            tube(K, 'H8_band_%s_%d' % (tag, k), b, a, offset_loop(loop, 0.05), offset_loop(loop, -0.02), 'htrim')
        tube(K, 'H8_bandseam_%s' % tag, x - 0.035, x + 0.035, offset_loop(loop, 0.018), offset_loop(loop, -0.02), 'hgrey2')
    for i, x in enumerate(BANDS_B):
        band(x, [(y, z) for (_, y, z) in ring(x, m=BLOCK)], 'b%d' % i)
    for i, x in enumerate(BANDS_A):
        band(x, [(y, z) for (_, y, z) in ring(x, m=AFT)], 'a%d' % i)
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line: two rows on the block's tall band, one on the aft body's ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        cuts = sorted([XF - 0.3] + [b + d for b in BANDS_B for d in (0.2, -0.2)] + [STEP + 0.15], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa_, xb_ = cuts[k], cuts[k + 1]
            for r_, z_ in enumerate((0.1, -0.24)):
                pts = []
                for j in range(9):
                    x = xa_ + (xb_ - xa_) * j / 8
                    h = half_ring(x, m=BLOCK)
                    pts.append((x, side * (h[5][0] + 0.003), z_))
                K.strip('H8_blue_b%s%d%d' % (sn, k, r_), pts, w=0.055, t=0.02, normals=[(0, side, 0)] * len(pts), m='hblue', grp='hull')
        cuts = sorted([BANDS_A[0] - 0.2, BANDS_A[1] + 0.2, BANDS_A[1] - 0.2, XS + 0.25], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            yo = side * (AFT['keys'][0][1] + 0.003)
            K.strip('H8_blue_a%s%d' % (sn, k), [(cuts[k], yo, -0.07), (cuts[k + 1], yo, -0.07)], w=0.055, t=0.02, normals=[(0, side, 0)] * 2, m='hblue', grp='hull')
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- the Plasma lance: one low turret on the block's aft deck ----------------
    K.gun('T1', (TURRET, 0.0, deck_z(TURRET)), 0.0, 0.0, barrels=2, cal=0.1, blen=1.0, size=0.95, slot='T', weapon='turbo', inv='lance',
          note='the Plasma lance (turbo T, 2 shots over 2 barrels, one each volley): one low turret on the centreline, on the ion block\'s aft deck over the step')

    # ---------------- the sensor fin: one, low, on the aft body just aft of the step ----------------
    fx, fh, fl = FIN
    K.organ('A1', HP.antenna(fh, L=fl, t=0.22), (fx, 0.0, deck_z(fx)), (0, 0, 1), fwd=(1, 0, 0), inv='sensor_fin',
            what='sensor fin, %.2f tall, %.1f long' % (fh, fl), kind='antenna',
            note='the one low sensor fin, on the aft body below the lance\'s firing plane (designs.md: aft of the step so it clears the arc; R240)')

    # ---------------- the drives: two rectangular nozzle pods on the transom ----------------
    for k, side in enumerate((1, -1)):
        K.engine('E%d' % (k + 1), (XS - 0.4, side * 0.45, -0.1), 0.3, 0.6, bell=1.0, body_r=0.36, kw=dict(w=0.68, h=0.56),
                 inv='engines', note='%s nozzle pod: a rectangular nozzle, blue-white throat, on the transom' % ('port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'engine, rectangular nozzle 0.68 x 0.56'
    h0 = half_ring(XS, m=AFT)
    K.box('H8_transomframe', XS - 0.03, XS + 0.005, -h0[3][0] + 0.06, h0[3][0] - 0.06, h0[8][1] + 0.08, h0[0][1] - 0.05, 'hgrey2', grp='hull')

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for j, z in enumerate((0.42, -0.42)):
            K.thruster('Q1%s%d' % (sn, j), (XF + 0.005, side * 0.88, z), (1, 0, 0), inv='thrusters', r=0.11,
                       note='retro thruster on the bow face corner (lore 3.4: backing off is cheap)')
            K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        p, nrm = facet(3.3, 4, side)
        K.thruster('Q2' + sn, tuple(p + nrm * 0.004), tuple(nrm), inv='thrusters', r=0.14, note='bow attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        p, nrm = facet(-3.95, 4, side)
        K.thruster('Q3' + sn, tuple(p + nrm * 0.004), tuple(nrm), inv='thrusters', r=0.13, note='stern attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        p, nrm = facet(-3.0, 4, side, 0.5)
        K._surface_part('D1' + sn, HP.bay(0.2, 0.55), tuple(p + nrm * 0.02), tuple(nrm), (1, 0, 0), 'drone_doors', 'flush drone doors 0.55 x 0.2', 'bay', 'picture',
                        'the faction\'s small drone bay: flush armoured doors on the aft body\'s upper facet (designs.md); no hangar in the rules, so no craft fly', aperture=0.8)
        for i, x in enumerate((3.55, 3.15, 2.2, 1.75, 1.3, 0.85)):
            h = half_ring(x)
            K.slit('W%d%s' % (i + 1, sn), (x, side * (h[5][0] + 0.01), -0.07), (0, side, 0), 0.28, 0.06, inv='windows', note='blue-white window of the block\'s crew decks, between the blue lines')
        K.vent('V1' + sn, (3.3, side * 0.45, deck_z(3.3) + 0.004), (0, 0, 1), 0.18, 0.55, slats=6, inv='vents', note='heat louvre over the ion capacitors')
        K.vent('V2' + sn, (2.05, side * 0.55, deck_z(2.05) + 0.004), (0, 0, 1), 0.18, 0.4, slats=6, inv='vents', note='heat louvre over the reactor')
        K.vent('V3' + sn, (-1.55, side * 0.42, deck_z(-1.55) + 0.004), (0, 0, 1), 0.16, 0.5, slats=5, inv='vents', note='heat louvre over the crew decks')
        K.vent('V4' + sn, (-3.25, side * 0.42, deck_z(-3.25) + 0.004), (0, 0, 1), 0.16, 0.5, slats=5, inv='vents', note='heat louvre over the engine room')
        K.vent('V5' + sn, (-4.05, side * 0.42, deck_z(-4.05) + 0.004), (0, 0, 1), 0.16, 0.4, slats=4, inv='vents', note='heat louvre over the drive feeds')
        for xb_ in BANDS_B:
            for d in (0.3, -0.3):
                K.organ('LB%s%s' % (sn, 'f' if d > 0 else 'a'), HP.latch(n=4, pitch=0.18, w=0.12), (xb_ + d, side * 0.95, deck_z(xb_ + d) + 0.004), (0, 0, 1), fwd=(1, 0, 0),
                        inv='latches', what='module latch row (4 clamps)', kind='latch', note='locks the two block modules together across the band')
        for d in (0.3, -0.3):
            K.organ('LA%s%s' % (sn, 'f' if d > 0 else 'a'), HP.latch(n=3, pitch=0.16, w=0.1), (BANDS_A[1] + d, side * 0.45, deck_z(BANDS_A[1] + d) + 0.004), (0, 0, 1), fwd=(1, 0, 0),
                    inv='latches', what='module latch row (3 clamps)', kind='latch', note='locks two aft body modules together across the band')
        for i, x in enumerate((1.7, -3.5)):
            p, nrm = facet(x, 6, side)
            K.hatch('H5%d%s' % (i, sn), tuple(p + nrm * 0.004), tuple(nrm), 0.36, 0.16, inv='hatches', note='flank hatch on the lower facet: stores to the lower deck')
    K.hatch('H1', (3.3, 0.0, deck_z(3.3) + 0.004), (0, 0, 1), 0.36, 0.3, inv='hatches', note='deck hatch over the ion capacitor room')
    K.hatch('H2', (-3.0, 0.0, deck_z(-3.0) + 0.004), (0, 0, 1), 0.34, 0.26, inv='hatches', note='deck hatch to the aft crew decks')
    K.hatch('H3', (-3.75, 0.0, deck_z(-3.75) + 0.004), (0, 0, 1), 0.34, 0.26, inv='hatches', note='deck hatch to the engine room')
    K.hatch('H4', (2.0, 0.0, belly_z(2.0) - 0.06), (0, 0, -1), 0.5, 0.34, inv='hatches', note='belly hatch on the armour step: the reactor\'s service hatch')
    K.hatch('H6', (-1.5, 0.0, belly_z(-1.5) - 0.004), (0, 0, -1), 0.4, 0.3, inv='hatches', note='aft belly hatch: stores')

    # ---------------- the belly: an armour step under the ion block ----------------
    belly = []
    for x, k in ((4.2, 0.0), (3.95, 1.0), (0.8, 1.0), (0.5, 0.0)):
        zb = belly_z(x); bw = st_at(x, BLOCK)[7] - 0.4
        belly.append([(x, bw, zb + 0.01), (x, bw - 0.06 * k, zb - 0.06 * k), (x, -bw + 0.06 * k, zb - 0.06 * k), (x, -bw, zb + 0.01)])
    K.mass('Belly armour step', K.loft_rings('H8_belly', belly, 'hgrey2'), 'recessed grey', note='a second armour layer under the ion block (a worked belly, R185 (5))')
    plate_jobs.append(('belly_step', belly, dict(faces=[1], inv='belly_panels', closed=False)))

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim (paint stage)', XF, XS, 'whole hull')
    K.colour('implant-blue light strips (the blue line), blue-white nozzles and windows', XF, XS, 'the flank bands, the stern')
    K.colour('no rust, no warm light, no asymmetry', XF, XS, 'factions.md Never')

    # ---------------- INSIDE: white corridors, blue emergency light, racks of identical equipment ----------------
    IN = SHELL + 0.06

    def slab(name, z, x0, x1, kind_name, m, n=4):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            w = min(hw_at(x, z - 0.04, IN, m), hw_at(x, z + 0.04, IN, m)) - 0.02
            rs.append([(x, w, z - 0.04), (x, w, z + 0.04), (x, -w, z + 0.04), (x, -w, z - 0.04)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))

    def frame_at(name, x, m):
        ho = dedupe(half_ring(x, IN, m)); hi = dedupe(half_ring(x, IN + 0.1, m))
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        V, F = [], []
        nn = min(len(fo), len(fi))
        for k in range(nn):
            a_, b_ = k, (k + 1) % nn
            q = [fo[a_], fo[b_], fi[b_], fi[a_]]
            if math.hypot(fo[b_][0] - fo[a_][0], fo[b_][1] - fo[a_][1]) < 1e-4:
                continue
            o = len(V)
            V += [(x + 0.05, y_, z_) for (y_, z_) in q] + [(x - 0.05, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def room(name, kind, x0, x1, z0, z1, m, ymax=None, y0=None, note=''):
        w = min(hw_at(x, z, IN, m) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.05
        if ymax is not None:
            w = min(w, ymax)
        if y0 is None:
            K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)
        else:
            for side in (1, -1):
                ya, yb = (y0, w) if side > 0 else (-w, -y0)
                K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    G = 0.15
    # the bow compartment (the trench's back wall to the block band): the ion capacitors
    slab('bow_main', 0.12, XB - 0.1, BANDS_B[0] + G, 'main', BLOCK)
    frame_at('F1', 3.3, BLOCK)
    room('ion_capacitors', 'machinery', XB - 0.1, BANDS_B[0] + G, -0.5, 0.06, BLOCK, ymax=0.9, note='the ion cannon\'s capacitor banks and field drivers behind the trench')
    room('fwd_corridor', 'hcorr', XB - 0.1, BANDS_B[0] + G, 0.18, 0.5, BLOCK, note='white corridors of the forward crew deck')
    # the block's aft compartment (the band to the step): the command deck, the lance magazine, the reactor
    slab('mid_main', 0.12, BANDS_B[0] - G, STEP + 0.1, 'main', BLOCK)
    frame_at('F2', 2.0, BLOCK); frame_at('F3', 0.6, BLOCK)
    room('command', 'bridge', BANDS_B[0] - G, 1.95, 0.18, 0.52, BLOCK, ymax=0.9, note='the command deck: the Registry link room')
    room('lance_room', 'magazine', 1.85, 0.45, 0.18, 0.5, BLOCK, ymax=0.75, note='the lance\'s capacitor room under the turret')
    room('reactor', 'core', 2.5, 0.35, -0.55, 0.06, BLOCK, ymax=0.85, note='the reactor (hp_core): its power runs forward to the trench and up to the lance')
    for k in range(3):
        x0 = 2.5 - k * 0.7
        room('rack_%d' % k, 'hrack', x0, x0 - 0.5, -0.5, 0.04, BLOCK, y0=0.95, note='racks of identical equipment beside the reactor (factions.md "Inside")')
    room('emerg_mid', 'hemerg', BANDS_B[0] - G, STEP + 0.1, 0.5, 0.53, BLOCK, ymax=0.08, note='the blue emergency light strip along the corridor ceiling')
    # the aft body's forward compartment (the step band to the second ring): crew decks and stores
    slab('aft_main', -0.1, BANDS_A[0] - G, BANDS_A[1] + G, 'main', AFT)
    frame_at('F4', -1.2, AFT)
    room('aft_crew', 'hcorr', BANDS_A[0] - G, BANDS_A[1] + G, -0.05, 0.2, AFT, note='crew decks and corridors in the aft body, white, numbered')
    room('aft_stores', 'machinery', BANDS_A[0] - G, BANDS_A[1] + G, -0.42, -0.15, AFT, note='coolant and fuel plant under the crew deck')
    # the stern compartment: the engine room
    frame_at('F5', -3.5, AFT)
    room('engine_room', 'engroom', BANDS_A[1] - G, XS + 0.25, -0.42, 0.2, AFT, note='the engine room: the feeds to the two nozzle pods')
    K.armour('deck and facets', 0.12, 'machined plate in modules, flush panels over it')
    K.armour('bow face', 0.3, 'the blunt bow round the trench, the thickest plate')
    K.armour('step face', 0.2, 'the block\'s aft face')
    K.armour('belly and armour step', 0.15, '')
    R = 2.0
    K.break_line('B-1', STEP, 'the ion block tears from the aft body at the step, the trench, the reactor and the lance with it',
                 path=[(STEP, R), (STEP, 1.1), (STEP - 0.08, 0.5), (STEP + 0.06, 0.0), (STEP - 0.07, -0.5), (STEP, -1.1), (STEP, -R)])
    K.break_line('B-2', BANDS_A[1], 'the stern module falls away at the second bulkhead ring, the nozzles and the engine room with it',
                 path=[(BANDS_A[1], R), (BANDS_A[1], 1.1), (BANDS_A[1] - 0.08, 0.45), (BANDS_A[1] + 0.07, 0.0), (BANDS_A[1] - 0.06, -0.45), (BANDS_A[1], -1.1), (BANDS_A[1], -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: the ion capacitors, white corridors with blue emergency light, the command deck, the lance room, the reactor and racks of identical equipment, the aft crew decks, the engine room. The Hegemony breaks in modules at the bulkhead rings (factions.md).'))
    K.point('core', 'hp_core', (1.4, 0, -0.25))
    for i, (x, sec, side, m) in enumerate(((BANDS_B[0], 'prow', 1, BLOCK), (BANDS_A[0], 'mid', -1, AFT), (BANDS_A[1], 'eng', 1, AFT))):
        h = half_ring(x, m=m)
        K.point('breach', 'hp_breach_%d' % i, (x, side * (h[5][0] + 0.07), (h[5][1] + h[6][1]) / 2 + 0.15), side='port' if side > 0 else 'stbd', section=sec, note='on a module joint')
    for i, side in enumerate((1, -1)):
        K.point('rcs', 'hp_rcs_%d' % i, (XF + 0.12, side * 0.88, 0.42), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_%d' % i, (-1.2, side * (AFT['keys'][0][1] + 0.06), 0.0), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if XB + 0.1 < pc.x < XF and abs(pc.y) < tw + 0.05 and pc.z > 0.0:
            return True   # the trench's roof window
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.36, keep=keep, closed=spec.get('closed', True), unit=0.75)
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('H8_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='H8_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('The step sits at 48 percent (x 0.2), where both views draw it, not at the table\'s 35 percent; the ion block is 4.55 long, the aft body 4.95',
             'the sheet\'s top and side views and the beauty all put the step near half length (the anvil Ryan saw); designs.md says the step reads as tabled, a slip in the table\'s number')
    K.change('The lance turret sits on the ion block\'s aft deck at 38 percent, just ahead of the step (the top view\'s and the three-quarter view\'s place), and the sensor fin on the lower aft body just aft of the step',
             'R240: the fin stays below the turret\'s firing plane, so no gun aims through a sensor (designs.md: the fin aft of the step so it clears the arc); the table\'s turret at 48 percent would sit on the aft body behind the fin')
    K.change('The ion trench is the Dominion\'s accelerator at 1.1 by 0.6: three stepped capacitor rings, a broad blue lens block at the back, an inner glow and a muzzle lip, its roof opened within the bow module',
             'designs.md: three stepped capacitor rings, a blue lens, an inset lip; R287 and R289: the same accelerator on every Navy trench, the roof window so the lens reads at the whole-ship camera')
    K.change('Two nozzle pods on the transom; the top view\'s third and fourth pods and the side view\'s ventral fin are not built',
             'designs.md: two pods govern, the extra pods and the ventral fin are picture slips; rule 4.1: no keel fin')
    K.change('The block\'s tall flank band carries two blue lines with the crew deck windows between them (the concept\'s two rows); the aft body carries one',
             'the side view and the beauty draw two rows on the block; factions.md: a line of blue light')
    K.change('Flush drone doors on the aft body\'s upper facets, one a side, are kept with no craft: the rules give the Cordon no hangar',
             'designs.md: flush flank doors only, the faction\'s small drone bays; nothing launches from them in the game')
    K.change('Four retro thrusters on the bow face corners (the concept\'s four small blocks), attitude thrusters on the facets, louvres, hatches, module latch rows and a belly armour step added',
             'a ship in space needs thrusters and access (lore 3.4); every part has a job (R221); a worked belly (R185 (5))')
    K.change('Even panel grid of two module sizes, bulkhead rings as raised bands with a deep seam: one on the block, one round the aft body at the step, one at 74 percent',
             'paint direction hegemony.md; designs.md break lines (the step carries the forward break)')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 1412) ----------
    K.fix('Nozzle pods E1 and E2: their inner walls inside the aft body, then inside the transom frame', 'the exits moved to 0.4 aft of the transom; the housings still sit in the stern block')
    K.fix('Windows W1 inside the bow frame, where the block tapers in plan', 'the forward windows moved aft to 3.55 and 3.15, where the sides run parallel')
    K.fix('Deck louvres V1, V2 and V3 against the module latch rows', 'the block\'s latch rows out to 0.95 off the axis, V2 forward to 2.05 and shortened, V3 forward to 1.55 aft of middle')
    K.fix('Aft latch row LA against the deck hatch H2', 'H2 aft to 3.0')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled')


INV_NOTES = {}
