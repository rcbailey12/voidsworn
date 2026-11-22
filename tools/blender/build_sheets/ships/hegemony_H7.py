# hegemony_H7: the Picket frigate, the Hegemony Navy's smallest escort (godot/rules/data/tables.json h_picket, "Directorate
# picket", class Frigate, 6.5 world units). Issue 1412. Shape of record: Muse run 3 (issue 1146, PR 1707):
# contrib/muse/design/class_family_hegemony_2026_11/picket_sheet.webp and picket_beauty.webp, copied to
# docs/ship_pipeline/build_sheets/hegemony_H7/concept_*.jpg; designs.md "PICKET" governs where a picture differs.
# Ryan, Nov 22 2026, on run 3: "Agree with picket changes", and the speedboat keel goes: flatten it into a space hull (issue
# 1412 brief). Rules: laser F (the Plasma cannon, 2 shots), flak T (Picket lasers, 3 shots); ability evasive; no hangar.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): the concept is a base.
# Family pattern: the Dominion (hegemony_H10.py) and the Convoy and Relay (O2, O3): pale grey module plate, the faceted section
# round a vertical flank band with the blue line, module bands with a deep seam, the flush panel grid, machined latches.
# Read off the picket sheet (top view on the right, BOW AT THE TOP; port side view lower left, BOW ON THE LEFT; 1110 px = 6.5
# units in the top view): the bow face about 0.43 of the widest beam in the top view (the table's 55 percent followed), the
# widest point a little aft of middle, a flat transom about 78 percent of the widest beam; the side view about 1.0 tall, a flat
# top line with one chamfer down to the stern. +X bow, +Y port, +Z up. Bow face x = +3.25, transom x = -3.25; the flank band
# straddles z 0.
import math

CODE = 'hegemony_H7'
NAME = 'Picket frigate (Hegemony Navy escort)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js h_picket (cls 'Frigate', 'Directorate picket'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5; game folder H7_23 (AI_HULLS hegemony|Frigate)"
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_H7/concept_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_H7/concept_sheet.jpg'
# the true views on the picket sheet (x0, y0, x1, y1): the top view drawn bow up (turned a quarter to bow left), the side view bow left
CONCEPT_VIEWS = dict(top=dict(box=(1290, 45, 1700, 1180), largest=True, flip=False, rot=90), side=dict(box=(80, 735, 1100, 950), largest=True, flip=False))
CROPS = [('bow (the blunt face and the casemate)', (380, 620, 1000, 950)), ('midships (the fin and the barbette)', (650, 380, 1300, 850)),
         ('stern (the chamfer, the transom and the nozzle pods)', (1100, 280, 1600, 700))]
SHEET = dict(version=1, round='first sheet', date='2026-11-22', blend='opus1412',
             blend_where='rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H7 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

XF, XS = 3.25, -3.25            # the bow face and the stern transom
XB = 2.63                       # the casemate's back wall: the dart's loft ends here, the bow frame runs on to the face
CAS = dict(w=0.78, h=0.3, zc=-0.05)
BANDS = (0.95, -1.3)            # the bulkhead rings at 35 and 70 percent (designs.md)
BARB = (-0.2, 0.12, 0.5)        # the flak barbette: x, its plinth's height, its plinth's radius
FIN = (1.65, 0.17, 1.0)         # the sensor fin: x, height, length
SHELL = 0.08
C1, C2 = 0.08, 0.09             # the deck-edge chamfer and the chine

# the plan and profile keys (x, half-beam at the flank band, deck z, belly z): straight flanks from the bow face out to the
# widest point at 58 percent, then in to the transom; the top line flat to 74 percent, then one chamfer down to the stern;
# the belly flat (Ryan: no keel), lifting a little to the bow face
KEYS = [(3.25, 0.605, 0.40, -0.40), (2.6, 0.690, 0.40, -0.47), (2.0, 0.769, 0.40, -0.50), (0.3, 0.992, 0.40, -0.50), (-0.52, 1.10, 0.40, -0.50),
        (-1.56, 1.009, 0.40, -0.50), (-2.4, 0.935, 0.30, -0.49), (-3.25, 0.86, 0.20, -0.48)]


def key_at(x):
    s = KEYS
    if x >= s[0][0]:
        return list(s[0])
    if x <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0]) if a[0] != b[0] else 0.0
            return [a[i] + (b[i] - a[i]) * t for i in range(4)]


def st_at(x):
    """H10's section fields at x: (x, hw, zt, zb, kt, kb, dw, bw, y1, y1b, sd); no terraces on the Picket"""
    _, hw, zt, zb = key_at(x)
    dw = hw - 0.2; bw = hw - 0.16
    return [x, hw, zt, zb, 0.10, -0.14, dw, bw, dw * 0.45, dw * 0.7, 0.0]


ST = [st_at(k[0]) for k in KEYS]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]


def half_ring(x, inset=0.0):
    """the port half of the dart's section at x, deck centre to belly centre: [(y, z)] (H10's section, without the terrace)"""
    _, hw, zt, zb, kt, kb, dw, bw, y1, y1b, sd = st_at(x)
    hw -= inset; zt -= inset; zb += inset; dw -= inset * 0.5; bw -= inset * 0.5; y1 -= inset * 0.5; y1b -= inset * 0.5
    kt_ = min(kt, zt - C1 - 0.02); kb_ = max(kb, zb + C2 + 0.02)
    return [(0.0, zt), (y1, zt), (y1b, zt), (dw, zt), (dw + C1, zt - C1), (hw, kt_), (hw, kb_), (bw + C2, zb + C2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


def hw_at(x, z, inset=0.0):
    h = half_ring(x, inset)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h, h[1:]):
        if min(z0, z1) - 1e-6 <= z <= max(z0, z1) + 1e-6:
            if abs(z1 - z0) < 1e-6:
                best = max(best, y0, y1)
            else:
                best = max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


def deck_z(x, y=0.0):
    return half_ring(x)[0][1]


def belly_z(x):
    return st_at(x)[3]


def facet(x, i, side, frac=0.5):
    """a point on the port (side +1) or starboard edge i of the half section at x (between points i and i+1), and its outward normal"""
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

    # ---------------- the dart: one loft from the casemate's back wall to the stern transom ----------------
    xs = sorted({k[0] for k in KEYS if XS <= k[0] <= XB} | {XB, XS} | {x / 5 for x in range(-16, 14)}, reverse=True)
    xs = [x for x in xs if XS <= x <= XB]
    hull = K.loft_rings(CODE + '_hull', [ring(x) for x in xs], 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the dart', hull, 'pale grey module plate',
           note='one solid dart: a flat deck, chamfered deck edges, upper facets out to the flank band with the blue line, short lower facets, a flat worked belly; the top line chamfered down to the stern')
    K.mark('dart', 'hull', ['facet', 'step', 'chamfer'])
    grid = [XB - 0.05 - 0.32 * i for i in range(20)]
    grid = [x for x in grid if x >= XS + 0.05 and not any(abs(x - b) < 0.14 for b in BANDS)] + [XS + 0.05]
    plate_jobs.append(('deck', [ring(x) for x in grid], dict(faces=[0, 1, 2, 15, 16, 17], inv='deck_panels')))
    plate_jobs.append(('flank', [ring(x) for x in grid], dict(faces=[4, 13, 6, 11], inv='flank_panels')))
    plate_jobs.append(('belly', [ring(x) for x in grid], dict(faces=[8, 9], inv='belly_panels')))

    # ---------------- the bow: a blunt armoured face round the casemate mouth (R183 (1)) ----------------
    tw, th, tz = CAS['w'] / 2, CAS['h'] / 2, CAS['zc']

    def rect_match(loop):
        out = []
        for (y, z) in loop:
            dy, dz = y, z - tz
            k = min(tw / abs(dy) if abs(dy) > 1e-9 else 1e9, th / abs(dz) if abs(dz) > 1e-9 else 1e9)
            out.append((dy * k, tz + dz * k))
        return out
    xs_b = [XB, 2.85, 3.05, XF]
    loops = [[(y, z) for (_, y, z) in ring(x)] for x in xs_b]
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
        F.append(((m - 1) * n + i, (m - 1) * n + j, (2 * m - 1) * n + j, (2 * m - 1) * n + i))   # the bow face
        F.append((j, i, m * n + i, m * n + j))                                                   # its back, on the dart's end
    bowf = K._obj(CODE + '_bowframe', V, F, 'hgrey', grp='hull')
    K.mass('Bow face round the casemate', bowf, 'pale grey module plate', note='the blunt bow face (never a ship\'s stem): the dart\'s facets run to it, the casemate recessed low in its middle')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    # armour plates on the face above and beside the casemate mouth
    for k, (y0, y1, z0, z1) in enumerate(((-tw - 0.05, tw + 0.05, tz + th + 0.07, tz + th + 0.13), (-tw - 0.05, tw + 0.05, tz - th - 0.18, tz - th - 0.07),
                                          (tw + 0.07, tw + 0.16, tz - th, tz + th), (-tw - 0.16, -tw - 0.07, tz - th, tz + th))):
        K.box('H7_bowplate_%d' % k, XF - 0.01, XF + 0.025, y0, y1, z0, z1, 'hpanel', ch=0.01, grp='hull')
    K.gun('L1', (XB, 0.0, tz), 0.0, 0.0, barrels=2, cal=0.075, slot='F', weapon='laser', inv='casemate', fixed=True,
          part=HP.casemate(XF - XB, w=CAS['w'], h=CAS['h'], cal=0.075, out=0.07),
          note='the Plasma cannon (laser F, 2 shots): a low casemate inside the bow face, two short thick barrels side by side that barely clear the face; one shot a barrel each volley')
    K.features[-1]['what'] = 'plasma cannon, twin casemate in the bow face (fixed)'

    # ---------------- the module bands: the bulkhead rings where the hull gives way ----------------
    for i, x in enumerate(BANDS):
        loop = dedupe([(y, z) for (_, y, z) in ring(x)])
        for k, (a, b) in enumerate(((x + 0.1, x + 0.025), (x - 0.025, x - 0.1))):
            tube(K, 'H7_band_%d_%d' % (i, k), b, a, offset_loop(loop, 0.04), offset_loop(loop, -0.02), 'htrim')
        tube(K, 'H7_bandseam_%d' % i, x - 0.03, x + 0.03, offset_loop(loop, 0.012), offset_loop(loop, -0.02), 'hgrey2')
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line along each flank band, broken at the bands ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        cuts = sorted([XF - 0.25] + [b + d for b in BANDS for d in (0.16, -0.16)] + [XS + 0.25], reverse=True)
        for k in range(0, len(cuts) - 1, 2):
            xa, xb_ = cuts[k], cuts[k + 1]
            pts = []
            for j in range(9):
                x = xa + (xb_ - xa) * j / 8
                h = half_ring(x)
                pts.append((x, side * (h[5][0] + 0.003), (h[5][1] + h[6][1]) / 2))
            K.strip('H7_blue_%s%d' % (sn, k), pts, w=0.045, t=0.016, normals=[(0, side, 0)] * len(pts), m='hblue', grp='hull')
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='blue_line')

    # ---------------- the flak barbette: a low faceted plinth, the picket turret on it ----------------
    bx, bh, br = BARB
    zd = deck_z(bx)
    oct_ = [(bx + br * math.cos(math.pi / 8 + k * math.pi / 4), br * math.sin(math.pi / 8 + k * math.pi / 4)) for k in range(8)]
    pv, pf = HP._poly_prism(oct_, zd - 0.05, zd + bh, inset=0.04)
    K.mass('Flak barbette plinth', K._obj('H7_barbette', pv, pf, 'hgrey2', grp='hull'), 'recessed grey', note='the low faceted barbette the Picket lasers turn on')
    pv, pf = HP._poly_prism([(bx + (x - bx) * 1.02, y * 1.02) for (x, y) in oct_], zd + bh * 0.45, zd + bh * 0.6)
    K._obj('H7_barbetteband', pv, pf, 'htrim', grp='hull')
    K.mark('barbette', 'tier', ['face', 'roof', 'opening'], fid='barbette_plinth')
    K.gun('F1', (bx, 0.0, zd + bh), 0.0, 10.0, barrels=3, cal=0.04, blen=0.28, size=0.8, slot='T', weapon='flak', inv='barbette',
          note='the Picket lasers (flak T, 3 shots over 3 emitters, one each volley) on the dorsal barbette; the plinth lifts the emitters over the low sensor fin (R240)')

    # ---------------- the sensor fin: one, low, forward of the barbette ----------------
    fx, fh, fl = FIN
    K.organ('A1', HP.antenna(fh, L=fl, t=0.16), (fx, 0.0, deck_z(fx)), (0, 0, 1), fwd=(1, 0, 0), inv='sensor_fin',
            what='sensor fin, %.2f tall, %.1f long' % (fh, fl), kind='antenna', note='the one low sensor fin: the Picket\'s search sensors, the command deck under it')

    # ---------------- the drives: two rectangular nozzle pods seated in the stern block ----------------
    for k, side in enumerate((1, -1)):
        K.engine('E%d' % (k + 1), (XS - 0.25, side * 0.4, -0.1), 0.2, 0.5, bell=1.0, body_r=0.24, kw=dict(w=0.46, h=0.36),
                 inv='engines', note='%s nozzle pod: a rectangular nozzle, blue-white throat, seated in the stern block' % ('port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'engine, rectangular nozzle 0.46 x 0.36'
    h0 = half_ring(XS)
    K.box('H7_transomframe', XS - 0.025, XS + 0.005, -h0[3][0] + 0.06, h0[3][0] - 0.06, h0[8][1] + 0.06, h0[0][1] - 0.04, 'hgrey2', grp='hull')

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.thruster('Q1' + sn, (XF + 0.005, side * 0.24, 0.25), (1, 0, 0), inv='thrusters', r=0.09,
                   note='retro thruster on the bow face (lore 3.4: backing off is cheap; the Picket\'s evasive burn)')
        K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        p, nrm = facet(2.35, 4, side)
        K.thruster('Q2' + sn, tuple(p + nrm * 0.004), tuple(nrm), inv='thrusters', r=0.1, note='bow attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        p, nrm = facet(-2.8, 4, side)
        K.thruster('Q3' + sn, tuple(p + nrm * 0.004), tuple(nrm), inv='thrusters', r=0.1, note='stern attitude thruster on the upper facet')
        K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        p, nrm = facet(-1.85, 4, side, 0.55)
        K._surface_part('D1' + sn, HP.bay(0.16, 0.4), tuple(p + nrm * 0.025), tuple(nrm), (1, 0, 0), 'drone_doors', 'flush drone doors 0.4 x 0.16', 'bay', 'picture',
                        'the faction\'s small drone bay: flush armoured doors on the upper facet (designs.md); no hangar in the rules, so no craft fly', aperture=0.6)
        for i, x in enumerate((-2.25, -2.5)):
            h = half_ring(x)
            K.slit('W%d%s' % (i + 1, sn), (x, side * (h[5][0] + 0.01), (h[5][1] + h[6][1]) / 2 + 0.06), (0, side, 0), 0.16, 0.05, inv='windows',
                   note='blue-white window of the aft crew deck, over the blue line')
        K.vent('V1' + sn, (2.05, side * 0.22, deck_z(2.25) + 0.004), (0, 0, 1), 0.14, 0.4, slats=5, inv='vents', note='heat louvre over the cannon\'s capacitors')
        K.vent('V2' + sn, (-2.05, side * 0.42, deck_z(-2.05) + 0.004), (-0.119, 0, 1), 0.16, 0.5, slats=5, inv='vents', note='heat louvre over the engine room')
        K.vent('V3' + sn, (-0.35, side * 0.5, belly_z(-0.35) - 0.05), (0, 0, -1), 0.16, 0.5, slats=5, inv='vents', note='belly heat louvre under the reactor')
        K.vent('V4' + sn, (1.7, side * 0.4, belly_z(1.7) - 0.05), (0, 0, -1), 0.14, 0.4, slats=4, inv='vents', note='belly heat louvre under the command deck')
        for i, xb_ in enumerate(BANDS):
            for d in (0.22, -0.22):
                K.organ('LW%d%s%s' % (i, sn, 'f' if d > 0 else 'a'), HP.latch(n=3, pitch=0.13, w=0.08), (xb_ + d, side * 0.42, deck_z(xb_ + d) + 0.004), (0, 0, 1),
                        fwd=(1, 0, 0), inv='latches', what='module latch row (3 clamps)', kind='latch', note='locks two hull modules together across the band')
        p, nrm = facet(0.4, 6, side)
        K.hatch('H5' + sn, tuple(p + nrm * 0.004), tuple(nrm), 0.3, 0.14, inv='hatches', note='flank hatch on the lower facet: stores to the lower deck')
    K.hatch('H1', (2.47, 0.0, deck_z(2.47) + 0.004), (0, 0, 1), 0.3, 0.24, inv='hatches', note='deck hatch over the cannon room')
    K.hatch('H2', (0.55, 0.0, deck_z(0.55) + 0.004), (0, 0, 1), 0.3, 0.24, inv='hatches', note='deck hatch to the main deck')
    K.hatch('H3', (-1.75, 0.0, deck_z(-1.75) + 0.004), (0, 0, 1), 0.3, 0.24, inv='hatches', note='deck hatch to the engine room')
    K.hatch('H4', (0.55, 0.0, belly_z(0.55) - 0.05), (0, 0, -1), 0.36, 0.26, inv='hatches', note='belly hatch on the armour step: stores and the reactor\'s spares')

    # ---------------- the belly: an armour step under the flat belly (Ryan: a flat worked belly, no keel) ----------------
    belly = []
    for x, k in ((2.3, 0.0), (2.1, 1.0), (1.0, 1.0), (-1.2, 1.0), (-2.5, 1.0), (-2.7, 0.0)):
        zb = belly_z(x); bw = st_at(x)[7] - 0.22
        belly.append([(x, bw, zb + 0.01), (x, bw - 0.04 * k, zb - 0.045 * k), (x, -bw + 0.04 * k, zb - 0.045 * k), (x, -bw, zb + 0.01)])
    K.mass('Belly armour step', K.loft_rings('H7_belly', belly, 'hgrey2'), 'recessed grey', note='a second armour layer on the flat belly (Ryan Nov 22: flatten the keel into a space hull)')
    K.mark('belly_step', 'hull', ['facet', 'step', 'chamfer'])
    plate_jobs.append(('belly_step', belly, dict(faces=[1], inv='belly_panels', closed=False)))

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim (paint stage)', XF, XS, 'whole hull')
    K.colour('implant-blue light strips (the blue line), blue-white nozzles and windows', XF, XS, 'the flank bands, the stern')
    K.colour('no rust, no warm light, no asymmetry', XF, XS, 'factions.md Never')

    # ---------------- INSIDE: white corridors, blue emergency light, racks of identical equipment ----------------
    IN = SHELL + 0.05

    def slab(name, z, x0, x1, kind_name, n=4):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            w = min(hw_at(x, z - 0.03, IN), hw_at(x, z + 0.03, IN)) - 0.02
            rs.append([(x, w, z - 0.03), (x, w, z + 0.03), (x, -w, z + 0.03), (x, -w, z - 0.03)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=kind_name, z=z, x=(x1, x0)))

    def frame_at(name, x):
        ho = dedupe(half_ring(x, IN)); hi = dedupe(half_ring(x, IN + 0.06))
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
            V += [(x + 0.03, y_, z_) for (y_, z_) in q] + [(x - 0.03, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=name, x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, y0=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.04
        if ymax is not None:
            w = min(w, ymax)
        if y0 is None:
            K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)
        else:
            for side in (1, -1):
                ya, yb = (y0, w) if side > 0 else (-w, -y0)
                K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    G = 0.12
    # the bow compartment (the casemate's back wall to B-1): the cannon room, the command deck under the fin
    slab('bow_main', -0.12, XB - 0.08, BANDS[0] + G, 'main')
    frame_at('F1', 2.0)
    room('cannon_room', 'machinery', XB - 0.08, 2.08, -0.38, -0.16, ymax=0.45, note='the plasma cannon\'s capacitor banks and feed behind the casemate')
    room('command', 'bridge', 1.92, BANDS[0] + G, -0.08, 0.28, ymax=0.5, note='the command deck under the sensor fin')
    room('bow_stores', 'hold', 1.92, BANDS[0] + G, -0.38, -0.16, ymax=0.55, note='bow stores and the retro thrusters\' feeds')
    # the mid compartment (B-1 to B-2): the crew deck, the reactor under the barbette, the racks
    slab('mid_main', -0.12, BANDS[0] - G, BANDS[1] + G, 'main')
    frame_at('F2', 0.3); frame_at('F3', -0.75)
    room('crew_corridor', 'hcorr', BANDS[0] - G, 0.38, -0.08, 0.3, note='white corridors and crew berths of the main deck, numbered posts')
    room('flak_room', 'magazine', 0.22, -0.68, -0.08, 0.28, ymax=0.4, note='the Picket lasers\' power cells under the barbette')
    room('reactor', 'core', 0.22, -0.82, -0.38, -0.16, ymax=0.5, note='the reactor (hp_core): its power runs forward to the cannon and up to the barbette')
    for k in range(3):
        x0 = 0.22 - k * 0.36
        room('rack_%d' % k, 'hrack', x0, x0 - 0.26, -0.06, 0.24, y0=0.48, note='racks of identical equipment beside the flak room (factions.md "Inside")')
    room('emerg_mid', 'hemerg', BANDS[0] - G, 0.38, 0.3, 0.33, ymax=0.06, note='the blue emergency light strip along the corridor ceiling')
    # the aft compartment (B-2 to the transom): the engine room
    slab('aft_main', -0.12, BANDS[1] - G, XS + 0.6, 'main')
    frame_at('F4', -2.2)
    room('engine_room', 'engroom', BANDS[1] - G, XS + 0.6, -0.38, -0.16, note='the engine room: the feeds to the two nozzle pods')
    room('aft_crew', 'hcorr', BANDS[1] - G, -2.1, -0.08, 0.2, note='the aft crew deck, white and numbered')
    K.armour('deck and facets', 0.08, 'machined plate in modules, flush panels over it')
    K.armour('bow face', 0.15, 'the blunt bow round the casemate, the thickest plate')
    K.armour('belly and armour step', 0.1, 'the flat worked belly')
    R = 1.4
    K.break_line('B-1', BANDS[0], 'the bow module tears off at the first bulkhead ring, the casemate and the command deck with it',
                 path=[(BANDS[0], R), (BANDS[0], 1.0), (BANDS[0] + 0.06, 0.45), (BANDS[0] - 0.06, 0.0), (BANDS[0] + 0.05, -0.45), (BANDS[0], -1.0), (BANDS[0], -R)])
    K.break_line('B-2', BANDS[1], 'the stern module falls away at the second bulkhead ring, the nozzles and the engine room with it',
                 path=[(BANDS[1], R), (BANDS[1], 1.05), (BANDS[1] - 0.06, 0.5), (BANDS[1] + 0.06, 0.0), (BANDS[1] - 0.05, -0.5), (BANDS[1], -1.05), (BANDS[1], -R)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: the cannon room, the command deck, white corridors with blue emergency light, racks of identical equipment, the reactor, the engine room. The Hegemony breaks in modules at the bulkhead rings (factions.md).'))
    K.point('core', 'hp_core', (-0.3, 0, -0.27))
    for i, (x, sec, side) in enumerate(((BANDS[0], 'prow', 1), (BANDS[1], 'eng', -1))):
        h = half_ring(x)
        K.point('breach', 'hp_breach_%d' % i, (x, side * (h[5][0] + 0.06), (h[5][1] + h[6][1]) / 2 + 0.12), side='port' if side > 0 else 'stbd', section=sec, note='on a module joint')
    for i, side in enumerate((1, -1)):
        K.point('rcs', 'hp_rcs_%d' % i, (XF + 0.1, side * 0.24, 0.25), side='port' if side > 0 else 'stbd')
        h = half_ring(-0.6)
        K.point('board', 'hp_board_%d' % i, (-0.6, side * (h[5][0] + 0.05), 0.0), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if abs(pc.x - bx) < br + 0.06 and abs(pc.y) < br + 0.06 and pc.z > deck_z(bx) - 0.05:
            return True   # the barbette plinth
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=0.3, keep=keep, closed=spec.get('closed', True), unit=0.6)
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('H7_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='H7_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('The concept\'s V keel (the speedboat underside in the side view) becomes a flat worked belly: short lower facets, a chine, a flat belly with an armour step, panels, hatches and louvres on it',
             'Ryan, Nov 22 2026, on run 3: flatten the speedboat keel into a space hull; rule 4.1: space ships, never sea ships')
    K.change('The bow casemate is a fixed twin plasma cannon in a lined recess low in the blunt face, its two barrels clearing the face by 0.07; the concept\'s two dark ports read as the mouth',
             'designs.md: two short thick barrels side by side, recessed so they barely protrude, never the ion trench; tables.json h_picket laser F, 2 shots, one a barrel')
    K.change('The flak barbette is a low eight-sided plinth (0.12 high) with the picket turret on it, three short emitters; the concept\'s smooth mound is not followed',
             'designs.md: three short emitters (the beauty\'s mound hides them, a picture slip); R240: the plinth lifts the emitters\' firing plane clear over the low sensor fin, so no gun aims through a sensor')
    K.change('The sensor fin sits at 25 percent (x 1.65), 0.17 tall and 1.0 long, ahead of the first bulkhead ring; the table put it at 40 percent, 1.2 long',
             'the top view draws the fin well forward of the barbette (about 28 percent); at 40 percent a 1.2 fin crosses the 35 percent bulkhead ring and crowds the barbette')
    K.change('The two nozzle pods sit side by side in the stern transom, their lips 0.25 proud; the sheet\'s top view pods on a crossbar are not followed',
             'designs.md: two rectangular pods in one flat row, seated flush in the single stern block (the forked look is a picture slip)')
    K.change('Flush drone doors on the upper facets aft, one a side, are kept with no craft: the rules give the Picket no hangar',
             'designs.md: flush flank doors only, the faction\'s small drone bays; nothing launches from them in the game')
    K.change('Retro thrusters on the bow face over the casemate (the concept\'s two small dark ports there), attitude thrusters on the facets, window slits aft, louvres, hatches and module latch rows added',
             'a ship in space needs thrusters and access (lore 3.4; ability evasive); every part has a job (R221)')
    K.change('Even panel grid of two module sizes, bulkhead rings as raised bands with a deep seam at 35 and 70 percent', 'paint direction hegemony.md; designs.md break lines; the concept\'s scattered greebles are not built one for one')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 1412) ----------
    K.fix('Nozzle pods E1 and E2: their inner walls inside the stern block (the exits 0.16 aft of the transom)', 'the exits moved to 0.25 aft of the transom; the housings still sit in the stern block')
    K.fix('Drone doors D1 inside the upper facet, which tapers in plan', 'the doors 0.4 long and set 0.025 proud of the facet')
    K.fix('Deck louvres V2 inside the stern chamfer; belly louvres V3 inside the belly armour step', 'V2 tilted to the chamfer\'s slope; V3 and V4 seated on the step\'s face')
    K.fix('Stern thrusters Q3 against the windows W2, then against the nozzle pods and firing into the hull at the transom', 'Q3 forward to 2.8 aft of middle, the windows to 2.25 and 2.5, the doors to 1.85')
    K.fix('Deck louvres V1 against the deck hatch H1', 'V1 aft to 2.05, H1 forward to 2.47')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled')


INV_NOTES = {}
