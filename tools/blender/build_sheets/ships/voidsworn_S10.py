# voidsworn_S10: the Vigil-class cruiser of the Sunward Crusade (data.js penitent, class Cruiser, 14.5 world units). Issue 1157.
# Replaces the old A4 hull V16_37. Shape of record: the accepted concept contrib/muse/design/class_family_sunward_2026_11/
# (vigil_beauty.webp, vigil_sheet.webp; Ryan accepted it Nov 19 2026 14:26 UTC with smaller spires, R331). designs.md's Vigil
# table outranks the pictures (it lists their slips); S8 Daybreak (voidsworn_S8.py) is the family pattern, never copied literally.
# data.js penitent: battery P, battery S, lance F; ability focus; no hangar, no turrets.
# The one thing that outranks the numbers (the Board's brief): at the battle camera it reads as S8's family (black forged iron
# blade, ember spires) and carries the prow lance as ONE emitter set into the bow point, never a big glowing disc, and four
# battery ports a side.
# Spires (R331, Ryan: "can we scale down the giant radiator/orange towers on each ship a bit too?"): about 70 percent of the
# table's heights (tallest 1.2 for the table's 1.7), the same count (5), spaced ember fin slats (the radiator glow='slats' of issue 1158).
# +X bow, +Y port, +Z up. The lance's muzzle face (the point) x = +7.25, the engine exits x = -7.25. Deck line BALL_Z = 0.0.
import math

CODE = 'voidsworn_S10'
NAME = 'Vigil-class cruiser (Sunward Crusade)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js penitent (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5"
BEAUTY = 'contrib/muse/design/class_family_sunward_2026_11/vigil_beauty.webp'
KIT = 'voidsworn'
CONCEPT_SHEET = 'contrib/muse/design/class_family_sunward_2026_11/vigil_sheet.webp'
# the true views on the Vigil sheet (x0, y0, x1, y1): the top view above (bow LEFT), the side view lower left (bow LEFT)
CONCEPT_VIEWS = dict(top=dict(box=(40, 180, 1900, 600), largest=True, flip=False), side=dict(box=(10, 750, 1330, 1090), largest=True, flip=False))
CROPS = [('bow (the lance point)', (0, 760, 700, 1300)), ('midships (the gun deck)', (500, 300, 1400, 860)), ('stern (spires and engines)', (1000, 0, 1920, 760))]
SHEET = dict(version=1, round='first sheet', date='2026-11-19', blend='opus1157',
             blend_where='built in the issue 1157 cloud copy (bpy 5.3, Cycles CPU); `build.py voidsworn_S10 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout from the designs.md table, built with the Sunward kit and run through the fit check.',
             during='The fit check findings are in the table above, in the order the check made them.')

# ---------------------------------------------------------------------------------------------------- the hull section
# The family's blade section (S8): a crowned deck, a deck-edge chamfer, a big upper facet out to the knuckle, the vertical
# broadside band (kt to kb), a lower facet in, a chine chamfer, a flat worked belly (R244: angled facets, never a flat wall).
# (x, hw: half-beam at the knuckle, zt: deck, zb: belly, kt, kb: the broadside band's top and bottom, dw: deck half-width share)
# Widest 2.9 over the hull (3.0 over the gun deck lips) at 68 percent (x -2.6), the stern third, as designs.md asks.
ST = [
    (6.3, 0.42, 0.28, -0.34, 0.0, -0.05, 0.3),
    (5.9, 0.6, 0.39, -0.5, 0.06, -0.1, 0.4),
    (5.2, 0.82, 0.5, -0.64, 0.12, -0.16, 0.48),
    (4.2, 1.08, 0.63, -0.82, 0.19, -0.23, 0.52),
    (3.2, 1.24, 0.7, -0.93, 0.24, -0.27, 0.56),
    (2.3, 1.31, 0.73, -0.98, 0.27, -0.29, 0.58),
    (0.8, 1.35, 0.74, -1.0, 0.28, -0.3, 0.6),
    (-0.8, 1.39, 0.74, -1.0, 0.28, -0.3, 0.6),
    (-2.0, 1.44, 0.75, -1.01, 0.29, -0.31, 0.6),
    (-2.9, 1.45, 0.75, -1.01, 0.29, -0.31, 0.6),
    (-4.0, 1.41, 0.74, -1.0, 0.28, -0.3, 0.6),
    (-5.0, 1.33, 0.71, -0.95, 0.27, -0.29, 0.6),
    (-5.8, 1.23, 0.66, -0.88, 0.25, -0.27, 0.58),
    (-6.45, 1.15, 0.61, -0.81, 0.23, -0.25, 0.58),
]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
CROWN = 0.05       # the deck's crown at the centreline
BWF = 0.58         # the belly's half-width share of hw
SHELL = 0.16       # hull thickness (the solidify shell)
GUN_X = (1.74, 0.435, -0.87, -2.175)   # the four battery ports a side, stations 38 / 47 / 56 / 65 percent (battery: 4 shots)
BALL_Z = 0.0       # the broadside deck line
GUN_S = round(1.2 * LENGTH / 27.0, 3)   # S8's heavy broadside mount scaled to this hull (Ryan, Nov 20: "size it appropriately for the ship size"): 14.5 / 27, then "sliiiiiightly bigger" (x1.2)
PL = dict(size=(0.3, 0.56), thick=(0.02, 0.045))
TIP = 7.25


def st_at(x):
    s = sorted(ST, key=lambda r: -r[0])
    if x >= s[0][0]:
        return list(s[0])
    if x <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def half_ring(x, inset=0.0):
    """the port half of the section at x, deck centre to belly centre: [(y, z)], inset inward by about `inset`"""
    _, hw, zt, zb, kt, kb, dwf = st_at(x)
    hw -= inset; zt -= inset; zb += inset
    dw = max(0.02, hw * dwf - inset * 0.4); bw = max(0.02, hw * BWF - inset * 0.4)
    c = min(0.08, hw * 0.06); c2 = min(0.07, hw * 0.05)
    kt_ = min(kt, zt - 2 * c - 0.01); kb_ = max(kb, zb + 2 * c2 + 0.01)
    return [(0.0, zt + CROWN * min(1.0, hw)), (dw, zt), (dw + c, zt - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


# The B-3 liner relief, the same method as the S8 Daybreak's (voidsworn_S8.py shell_ring and relieve_liner, issue 1059): the
# shell's inner liner is left out from a strip of each lower flank facet down across the belly, over the whole B-1 to B-2 compartment, so when the
# belly peels away no liner is left standing outside its own piece's torn plating (the death seam check). The plating stays
# whole; only the inside lining has the gap.
B3_RELIEF = (0.2, 0.95)   # the strip along each lower flank facet, as fractions from the lower knuckle toward the belly edge
B3_SPAN = (-6.05, 2.95)   # the compartment the peel weakens (B-2 to B-1); within 0.5 of either joint the whole ring is relieved


def shell_ring(x):
    """ring(x) with two extra points on each lower flank facet, the edges of the liner relief strip"""
    half = half_ring(x)
    a, b = half[4:6]
    half[5:5] = [tuple(u + (v - u) * t for u, v in zip(a, b)) for t in B3_RELIEF]
    return [(x, y, z) for y, z in half + [(-y, z) for y, z in reversed(half[1:-1])]]


def relieve_liner(hull, shell, stations):
    """leave the liner out along the relief strip (exterior plating untouched), as S8 does"""
    import bpy
    strip = hull.vertex_groups.new(name='B3_relief')
    liner = hull.vertex_groups.new(name='inner_shell')
    shell.shell_vertex_group = liner.name
    ring_size = len(hull.data.vertices) // len(stations)
    port = range(5, 10)        # from the strip's top edge down the lower facet and across the belly to its centre line
    flanks = sorted({*port, *(ring_size - j for j in port)})
    lo, hi = B3_SPAN
    vs = []
    for i, x in enumerate(stations):
        if lo - 0.25 <= x <= lo + 0.5 or hi - 0.5 <= x <= hi + 0.25:
            vs.extend(i * ring_size + j for j in range(ring_size))
        elif lo < x < hi:
            vs.extend(i * ring_size + j for j in flanks)
    strip.add(vs, 1.0, 'REPLACE')
    tree = bpy.data.node_groups.new('S10 B-3 liner clearance', 'GeometryNodeTree')
    for direction in ('INPUT', 'OUTPUT'):
        tree.interface.new_socket(name='Geometry', in_out=direction, socket_type='NodeSocketGeometry')
    source = tree.nodes.new('NodeGroupInput'); output = tree.nodes.new('NodeGroupOutput')
    remove = tree.nodes.new('GeometryNodeDeleteGeometry'); remove.domain = 'FACE'
    both = tree.nodes.new('ShaderNodeMath'); both.operation = 'MULTIPLY'
    for i, group in enumerate((strip, liner)):
        w = tree.nodes.new('GeometryNodeInputNamedAttribute'); w.data_type = 'FLOAT'; w.inputs['Name'].default_value = group.name
        tree.links.new(w.outputs['Attribute'], both.inputs[i])
    full = tree.nodes.new('ShaderNodeMath'); full.operation = 'GREATER_THAN'; full.inputs[1].default_value = 0.99
    tree.links.new(both.outputs[0], full.inputs[0])
    tree.links.new(full.outputs[0], remove.inputs['Selection'])
    tree.links.new(source.outputs['Geometry'], remove.inputs['Geometry'])
    tree.links.new(remove.outputs['Geometry'], output.inputs['Geometry'])
    hull.modifiers.new('B-3 liner relief', 'NODES').node_group = tree


def hw_at(x, z, inset=0.0):
    """the section's half-width at height z (port side), inset by `inset`: 0 when z is outside"""
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
    _, hw, zt, zb, kt, kb, dwf = st_at(x)
    dw = hw * dwf
    return zt + CROWN * min(1.0, hw) * max(0.0, 1 - abs(y) / dw)


def facet_pt(x, side, f):
    """a point on the upper facet at share f from the deck-edge chamfer (0) to the knuckle (1), and its outward normal"""
    from mathutils import Vector
    h = half_ring(x)
    (y0, z0), (y1, z1) = h[2], h[3]
    p = Vector((x, side * (y0 + (y1 - y0) * f), z0 + (z1 - z0) * f))
    n = Vector((0, side * (z0 - z1), (y1 - y0))).normalized()
    return p, n


def lower_pt(x, side, f):
    """a point on the lower facet at share f from the knuckle (0) to the chine (1), and its outward normal"""
    from mathutils import Vector
    h = half_ring(x)
    (y0, z0), (y1, z1) = h[4], h[5]
    p = Vector((x, side * (y0 + (y1 - y0) * f), z0 + (z1 - z0) * f))
    n = Vector((0, side * (z0 - z1), -(y0 - y1))).normalized()
    if n.z > 0:
        n = Vector((0, n.y, -n.z))
    return p, n


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit (tools/blender/kits/voidsworn)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    xs = sorted({r[0] for r in ST} | {x / 4 for x in range(-25, 26)}, reverse=True)
    xbow = [x for x in xs if x >= 3.2]; xaft = [x for x in xs if x <= 3.2]
    rings = [ring(x) for x in xs]
    hull = K.loft_rings(CODE + '_hull', [shell_ring(x) for x in xs], 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    relieve_liner(hull, md, xs)
    K.mass('Hull: the blade', hull, 'black iron plate',
           note='a long faceted blade: crowned deck, big upper facets, the broadside band, lower facets, a flat worked belly; widest (2.9) at the stern third')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    rb = [ring(x) for x in xbow]; ra = [ring(x) for x in xaft]
    plate_jobs = [('hull', rings, dict(PL, faces=[0, 13], mats={'siron': 3, 'siron2': 2}, seed=11, inv='deck_plates')),
                  ('hull_fb', rb, dict(PL, faces=[2, 11], tri=True, mats={'siron': 4, 'siron2': 2}, seed=12, inv='flank_plates', size=(0.32, 0.6))),
                  ('hull_f', ra, dict(PL, faces=[2, 11], mats={'siron': 4, 'siron2': 2}, seed=16, inv='flank_plates')),
                  ('hull_b', rings, dict(PL, faces=[3, 10], mats={'siron2': 3, 'siron': 2}, seed=13, inv='flank_plates', size=(0.24, 0.45))),
                  ('hull_l', rings, dict(PL, faces=[4, 9], mats={'siron': 3, 'siron2': 2}, seed=14, inv='flank_plates')),
                  ('hull_v', rings, dict(PL, faces=[6, 7], mats={'siron2': 3, 'siron': 2}, seed=15, inv='belly_plates'))]

    # ---------------- the bow: the spearhead runs into the Oath lance's muzzle collar (one emitter in the point) ----------------
    LZ = -0.02   # the point's height (mid height: a blade, never a stem)
    K.spinal('L1', (5.75, 0.0, LZ), TIP - 5.75, r=0.3, point=(0.5, 0.47, 0.72), depth=0.26, slot='F', weapon='lance', inv='lance',
             note='the Oath lance (lance F, 1 shot): one emitter set in the spearhead\'s point: a heavy forged collar, a dark bore about 0.45 across (a third of the concept\'s opening), an ember lens set shallow in it')
    K.features[-1].update(what='oath lance, one emitter in the point (fixed)', route='hand-built')
    # the dorsal ridge (the Board, rev 2: the concept's strongest line): a raised, plated armoured spine from the lance housing to
    # the spire block, so the top view reads as a blade with a keel. Its forward run to station 30 percent is the lance's power
    # trunk (designs.md); aft of it the ridge carries the reactor's feeds on to the spine block.
    RX = (6.2, 6.0, 5.4, 4.5, 3.6, 2.6, 1.4, 0.4, -0.3, -0.5)

    def ridge_hw(x):
        return 0.12 + 0.16 * min(1.0, (6.2 - x) / 3.0)

    tr = []
    for x in RX:
        z0 = deck_z(x, 0.0) - 0.03
        k = 0.0 if x in (RX[0], RX[-1]) else 1.0
        hgt = (0.08 + 0.12 * min(1.0, (6.2 - x) / 2.5)) * min(1.0, (x + 0.5) / 1.2 + 0.4)   # it steps down before the command slits
        w = ridge_hw(x)
        tr.append([(x, w + 0.06, z0), (x, w + 0.06, z0 + (0.4 + 0.2 * k) * hgt), (x, w * 0.6, z0 + hgt * (0.3 + 0.7 * k) + 0.02),
                   (x, -w * 0.6, z0 + hgt * (0.3 + 0.7 * k) + 0.02), (x, -w - 0.06, z0 + (0.4 + 0.2 * k) * hgt), (x, -w - 0.06, z0)])
    K.mass('Dorsal ridge (the lance power trunk forward)', K.loft_rings('S10_trunk', tr, 'siron2'), 'darker iron',
           note='a raised armoured spine from the lance to the spire block; forward of station 30 percent it is the lance\'s power trunk (designs.md)')
    plate_jobs.append(('ridge', tr, dict(PL, faces=[1, 2, 3], mats={'siron': 2, 'siron2': 2}, seed=27, inv='trunk_plates', size=(0.18, 0.4), closed=False)))
    for i, x in enumerate([5.7 - j * 0.62 for j in range(11)]):
        if x < -0.3:
            break
        hz = deck_z(x, 0.0) - 0.03
        hgt = (0.08 + 0.12 * min(1.0, (6.2 - x) / 2.5)) * min(1.0, (x + 0.5) / 1.2 + 0.4)
        w = ridge_hw(x) + 0.07
        K.rib('S10_trunkband_%d' % i, [(x, w, hz + 0.01), (x, w * 0.62, hz + hgt + 0.035), (x, -w * 0.62, hz + hgt + 0.035), (x, -w, hz + 0.01)], w=0.05, t=0.03, m='sworn')
    K.mark('trunk', 'spine', ['block', 'step', 'slit'])
    # the paired cheek housings: the lance's capacitor banks on the upper facets either side of the ridge (the faction's "one
    # heavy pair at the bow" in form, designs.md chair ruling)
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        rs = []
        x0, x1 = 5.4, 3.3
        for x in [x0 + (x1 - x0) * i / 6 for i in range(7)]:
            a, n = facet_pt(x, side, 0.12); b, _ = facet_pt(x, side, 0.62)
            taper = min(1.0, (x0 - x) / 0.7) * min(1.0, (x - x1) / 0.35 + 0.4)
            o = 0.13 * max(0.2, taper)
            rs.append([tuple(a - n * 0.02), tuple(a + n * o), tuple(b + n * o * 0.7), tuple(b - n * 0.02)] if side > 0 else
                      [tuple(b - n * 0.02), tuple(b + n * o * 0.7), tuple(a + n * o), tuple(a - n * 0.02)])
        ob = K.loft_rings('S10_cheek_%s' % nm[0], rs, 'siron2')
        K.mass('Lance capacitor housing, %s' % nm, ob, 'darker iron', note='an armoured capacitor bank on the upper facet, one of the paired cheek housings')
        plate_jobs.append(('cheek%s' % nm[0], rs, dict(PL, faces=[1], tri=True, mats={'siron': 2, 'siron2': 1}, seed=20 + (side > 0) * 5,
                                                         inv='bow_plates', size=(0.22, 0.45), closed=False)))
        for k in range(3):
            x = 5.0 - k * 0.55
            p, n = facet_pt(x, side, 0.37)
            K.vent('C%d%s' % (k + 1, nm[0]), tuple(p + n * 0.13 * min(1.0, (5.4 - x) / 0.7)), tuple(n), 0.34, 0.16, slats=4, inv='cheek_vents',
                   note='a capacitor bank\'s heat louvre on the cheek housing')
    K.mark('spearhead', 'hull', ['facet', 'step', 'chamfer'])

    # ---------------- the broadside band: the gun deck lips and four Sear battery ports a side ----------------
    XL0, XL1 = 2.55, -2.95
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        for lip, zz in (('upper', 0), ('lower', 1)):
            rs = []
            xl = [XL0, XL0 - 0.25] + [XL0 - 0.25 - (XL0 - 0.25 - XL1 - 0.25) * i / 8 for i in range(1, 9)] + [XL1]
            for i, x in enumerate(xl):
                _, hw, zt, zb, kt, kb, dwf = st_at(x)
                out = 0.0 if i in (0, len(xl) - 1) else 0.12
                if zz == 0:
                    pts = [(hw - 0.04, kt + 0.09), (hw + out, kt + 0.01), (hw + out, kt - 0.05), (hw - 0.04, kt - 0.05)]
                else:
                    pts = [(hw - 0.04, kb + 0.05), (hw + out, kb + 0.05), (hw + out, kb - 0.02), (hw - 0.04, kb - 0.09)]
                rs.append([(x, side * y, z) for (y, z) in (pts if side > 0 else pts[::-1])])
            ob = K.loft_rings('S10_lip_%s_%s' % (lip, nm[0]), rs, 'siron2')
            K.mass('Gun deck %s lip, %s' % (lip, nm), ob, 'darker iron', note='the armoured shelf over (under) the battery ports; its ends are angled')
    K.mark('gun_deck', 'belt', ['band', 'plate'])
    for side in (1, -1):
        sn = 'P' if side > 0 else 'S'
        for i, x in enumerate(GUN_X):
            hw = st_at(x)[1]
            K.gun('%s%d' % (sn, i + 1), (x, side * (hw - 0.04), BALL_Z), 90 * side, 0.0, barrels=1, cal=0.115 * GUN_S, blen=0.72 * GUN_S, size=GUN_S, mount='casemate',
                  normal=(0, side, 0), slot=sn, weapon='battery', inv='broadside',
                  note='%s battery port %d of 4 (Sear battery, battery %s)' % ('port' if side > 0 else 'starboard', i + 1, sn))

    # ---------------- the spine block and the spire line (5 spires, R331: about 70 percent of the table's heights) ----------------
    SPX = (-1.35, -5.95)
    sp = []
    for x in (SPX[0], SPX[0] - 0.03, -2.2, -3.6, -5.0, SPX[1] + 0.25, SPX[1]):
        z0 = deck_z(x, 0.0) - 0.05
        k = 0.0 if x == SPX[1] else 1.0   # a vertical forward face for the command slits
        hwb = 0.4 * (0.85 + 0.15 * k)
        sp.append([(x, hwb, z0), (x, hwb, z0 + 0.13 + 0.12 * k), (x, hwb - 0.06, z0 + 0.21 + 0.13 * k), (x, -hwb + 0.06, z0 + 0.21 + 0.13 * k),
                   (x, -hwb, z0 + 0.13 + 0.12 * k), (x, -hwb, z0)])
    spine = K.loft_rings('S10_spine', sp, 'siron2')
    SPZ = deck_z(-3.6, 0.0) - 0.05 + 0.34   # the spine block's top: the spire roots stand on it
    K.mass('Spine block (the spire line\'s base)', spine, 'darker iron',
           note='a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-4)')
    plate_jobs.append(('spine', sp, dict(PL, faces=[0, 2, 4], mats={'siron': 2, 'siron2': 2}, seed=31, inv='spine_plates', size=(0.2, 0.42))))
    # the command deck: ember slits in the spine block's stepped forward face (station 60 percent in the table; the face is at 59)
    for i, y in enumerate((-0.22, 0.0, 0.22)):
        K.slit('W%d' % (i + 1), (SPX[0] + 0.004, y, deck_z(SPX[0], 0.0) - 0.05 + 0.19), (1, 0, 0), 0.1, 0.04, inv='bridge_slits',
               note='command deck window, ember-lit, in the spine block\'s face')
    K.mark('spine', 'spine', ['block', 'step', 'slit'])
    # five radiator spires at stations 66 / 71 / 76 / 81 / 86 percent (rev 2: one tight row), tallest (1.2) in the middle, each its own profile;
    # lit fin slats spaced wider and reaching less far, about half the old lit area (R331; the same radiator glow='slats' as S8's issue 1158)
    SPIRES = [(-2.33, 0.8, 0), (-3.05, 1.02, 3), (-3.77, 1.2, 2), (-4.49, 1.0, 1), (-5.21, 0.78, 0)]   # rev 2: one tight row (the Board)
    PROF = ('blade', 'stepped', 'twin', 'raked')
    SC = 0.6   # the kit's radiator scale= (issue 1156): built at flagship detail, shrunk by SC, the same call as Warden's spires
    for i, (x, h, prof) in enumerate(SPIRES):
        L = 0.62
        part = HP.radiator(h, L, profile=prof, spread=SC * (0.2 + 0.42 * (h / SC) / 2.6), seed=i, scale=SC, glow='slats')   # S8's R331 spires (issue 1158)
        K.organ('R%d' % (i + 1), part, (x, 0.0, SPZ), (0, 0, 1), fwd=(1, 0, 0), inv='spires', what='radiator spire, %.2f tall, profile %s' % (h, PROF[prof]),
                kind='radiator', note='sheds the reactor\'s heat: spaced ember fin slats between iron posts (R331)')
        K.mass('Radiator spire R%d (%s, %.2f tall)' % (i + 1, PROF[prof], h), bpy.data.objects['R%d_body_embar' % (i + 1)], 'ember fin slats on iron',
               note='one of the five spires of the spire line')

    # ---------------- the stern: two ember bells, 1.2 across, offsets 0.8 ----------------
    # the drum's buried front stops 0.04 aft of B-2 (-6.05): stage 4's audit fails any part crossing a break line (Nov 19 PC run)
    for side in (1, -1):
        K.engine('E%d' % (1 if side > 0 else 2), (-7.2, side * 0.8, -0.12), 0.6, 0.42, bell=1.0, body_r=0.52, rings=3,
                 inv='engines', note='%s main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug' % ('port' if side > 0 else 'starboard'))

    # ---------------- the belly: an armour step ----------------
    belly = []
    for x, kk in ((4.0, 0.0), (3.4, 1.0), (2.3, 1.0), (0.8, 1.0), (-0.8, 1.0), (-2.0, 1.0), (-2.9, 1.0), (-4.0, 1.0), (-5.0, 1.0), (-5.4, 0.0)):
        _, hw, zt, zb, kt, kb, dwf = st_at(x)
        bw = hw * BWF - 0.15
        belly.append([(x, bw, zb + 0.01), (x, bw - 0.07 * kk, zb - 0.08 * kk), (x, -bw + 0.07 * kk, zb - 0.08 * kk), (x, -bw, zb + 0.01)])
    K.mass('Belly armour step', K.loft_rings('S10_belly', belly, 'siron2'), 'darker iron', note='a second forged layer under the gun deck and the reactor')
    plate_jobs.append(('belly', belly, dict(PL, faces=[1], mats={'siron2': 2, 'siron': 2}, seed=41, inv='belly_plates', closed=False)))

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p, n = lower_pt(5.6, side, 0.45)
        K.thruster('Q1' + sn, tuple(p), tuple(n), r=0.2, inv='thrusters', note='bow attitude thruster on the lower facet')
        p, n = facet_pt(-5.2, side, 0.6)
        K.thruster('Q2' + sn, tuple(p), tuple(n), r=0.2, inv='thrusters', note='stern attitude thruster on the upper facet')
        for i, x in enumerate((-3.0, -3.8, -4.6)):
            p, n = facet_pt(x, side, 0.5)
            K.vent('V%d%s' % (i + 1, sn), tuple(p), tuple(n), 0.5, 0.22, slats=5, inv='vents', note='reactor heat louvre over the reactor room')
        for i, x in enumerate(((GUN_X[0] + GUN_X[1]) / 2, (GUN_X[2] + GUN_X[3]) / 2)):
            hw = st_at(x)[1]
            K.slit('G%d%s' % (i + 1, sn), (x, side * (hw + 0.004), BALL_Z), (0, side, 0), 0.14, 0.045, inv='gallery_slits',
                   note='a gun gallery\'s ember slit between two ports')
        for i, x in enumerate((5.0, 4.1, 3.3, -1.9, -3.4, -4.2, -5.7)):
            p, n = lower_pt(x, side, 0.1) if x > 3 else facet_pt(x, side, 0.06)
            K.lamp('L%d%s' % (i + 1, sn), tuple(p + n * 0.006), tuple(n), inv='lamps', note='frost-white running point on the blade\'s edge')
    for i, (x, y) in enumerate(((2.55, 0.62), (2.55, -0.62), (-0.9, 0.66), (-0.9, -0.66))):
        K.hatch('H%d' % (i + 1), (x, y, deck_z(x, y) + 0.04), (0, -0.05 * (1 if y > 0 else -1), 1), 0.26, round_=True, inv='hatches', note='deck hatch')
    for i, (x, y) in enumerate(((1.5, 0.36), (1.5, -0.36), (-3.4, 0.36), (-3.4, -0.36))):
        K.hatch('H%d' % (i + 5), (x, y, st_at(x)[3] - 0.08 - 0.02), (0, 0, -1), 0.28, round_=True, inv='hatches', note='belly hatch on the armour step')
    K.hatchbox('HB1', (-0.2, 0.6, deck_z(-0.2, 0.6)), 0.34, 0.46, 0.16, inv='lift_heads', note='the hoist head over the gun deck: shells up from the shell rooms')

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white markings (paint stage)', TIP, -TIP, 'whole hull')
    K.colour('ember glow (radiator slats, engine throats, window slits, the lance lens)', TIP, -TIP, 'the spires, the bells, the slits, the lens')
    K.colour('frost-white running points', TIP, -TIP, 'the blade\'s edges')
    K.colour('no rust anywhere, no blue light', TIP, -TIP, 'factions.md Never')

    # ---------------- INSIDE: iron decks, the gun crews' galleries, frames, the reactor, the lance's capacitor room ----------------
    IN = SHELL + 0.04
    B1, B2 = 2.95, -6.05     # the transverse seams (the spearhead's root, the engine section)
    PEEL = -0.75             # B-3's level: the belly plating peels away under the gun deck

    def deck_slab(name, z, x0, x1, inset=0.02, n=6):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = hw_at(x, z, IN) - inset
            rs.append([(x, hw, z - 0.025), (x, hw, z + 0.025), (x, -hw, z + 0.025), (x, -hw, z - 0.025)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=name, z=z, x=(x1, x0)))

    def frame_at(name, x, zr=None, record=True):
        """a frame ring inside the skin at station x; zr: the heights it keeps, so a frame never straddles a peel plane"""
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.08)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        n = len(fo); pts = []
        for kk in range(n):
            a_, b_ = kk, (kk + 1) % n
            for j in range(6):
                t0 = j / 6
                pts.append(((fo[a_][0] + (fo[b_][0] - fo[a_][0]) * t0, fo[a_][1] + (fo[b_][1] - fo[a_][1]) * t0),
                            (fi[a_][0] + (fi[b_][0] - fi[a_][0]) * t0, fi[a_][1] + (fi[b_][1] - fi[a_][1]) * t0)))
        bands = zr or [(-99.0, 99.0)]
        V, F = [], []
        m = len(pts)
        for kk in range(m):
            (oa, ia), (ob, ib) = pts[kk], pts[(kk + 1) % m]
            zs_ = [oa[1], ob[1], ia[1], ib[1]]
            if not any(all(lo_ <= z_ <= hi_ for z_ in zs_) for lo_, hi_ in bands):
                continue
            q = [oa, ob, ib, ia]
            o = len(V)
            V += [(x + 0.04, y_, z_) for (y_, z_) in q] + [(x - 0.04, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        if F:
            K._obj('in_bh_' + name, V, F, 'frame', inside=True)
            if record:
                K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.03
        if ymax is not None:
            w = min(w, ymax)
        K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)

    def side_room(name, kind, x0, x1, z0, z1, y_in, note=''):
        for side in (1, -1):
            w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.03
            ya, yb = (y_in, w) if side > 0 else (-w, -y_in)
            K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    # decks: the bow deck (the lance's capacitor room over it), the gun deck and the upper deck between the seams, clear of both
    deck_slab('bow', -0.1, 5.5, 3.1)
    deck_slab('upper', 0.36, 2.8, -5.9); deck_slab('gun', -0.36, 2.8, -3.3, inset=0.12)
    deck_slab('main_aft', -0.36, -3.5, -5.9)
    for i, x in enumerate((5.4, 4.5, 3.6, 3.15, 2.75, 1.1, -0.2, -1.5, -2.8, -3.6, -4.4, -5.2, -5.85)):
        if B2 < x < B1:   # the whole B-1 to B-2 compartment the peel weakens: the frames stop well above it
            frame_at('F%d_upper' % i, x, zr=[(PEEL + 0.35, 99.0)])
        else:
            frame_at('F%d' % i, x)
    room('lance_capacitors', 'machinery', 5.4, 3.2, -0.04, 0.42, note='the Oath lance\'s capacitor room: the trunk\'s charge banks behind the emitter')
    room('bow_stores', 'hold', 5.2, 3.2, -0.6, -0.15, note='bow stores and the bow thrusters\' feeds')
    side_room('gun_gallery', 'gallery', 2.6, -3.1, -0.31, 0.3, 0.78, note='the gun crews\' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5)')
    for suffix, y0, y1 in (('p', 0.5, 0.74), ('s', -0.74, -0.5)):
        K.room('shell_rooms_' + suffix, 'magazine', -3.0, 2.5, y0, y1, -0.3, 0.05, note='the battery shell room inboard of the gun gallery')
    room('fire_plot', 'bridge', 1.0, -0.5, -0.31, 0.3, ymax=0.45, note='the broadside plotting room (no AI: plotted by hand)')
    room('crew_mid', 'crew', -0.7, -3.1, -0.31, 0.3, ymax=0.45, note='crew berths between the galleries')
    room('upper_rooms', 'crew', 2.6, -1.2, 0.4, 0.62, note='the gunners\' mess and the chalk wall where the names go up before launch')
    room('command', 'bridge', -1.4, -2.2, 0.4, 0.62, note='the command deck under the spine block\'s slits')
    room('plenum', 'machinery', -2.3, -5.7, 0.4, 0.62, note='the heat plenum feeding the spire line')
    room('reactor', 'core', -3.6, -5.2, -0.4, 0.3, ymax=0.75, note='the reactor: its heat goes up through the plenum into the spires (hp_core)')
    side_room('coolant', 'machinery', -3.6, -5.2, -0.4, 0.28, 0.82, note='coolant pumps either side of the reactor')
    room('engine_room', 'engroom', -5.35, -5.9, -0.4, 0.3, note='the engine room and the two drives\' feeds')
    K.armour('upper facets and deck', 0.16, 'forged plate over the galleries')
    K.armour('broadside band and lips', 0.2, 'the gun deck face, the heaviest belt')
    K.armour('spearhead', 0.22, 'solid forged layers toward the point round the lance')
    K.armour('belly and armour step', 0.16, '')
    K.armour('spine block', 0.14, 'it snaps off with the spires')
    # seams (factions.md "How it breaks": along the gun decks, the hull splits lengthwise between deck rows; the spire line snaps
    # off as one piece; R226: no machine on a seam; a long seam stays inside one transverse compartment)
    reach = 2 * max(r[1] for r in ST)
    K.break_line('B-1', B1, 'the spearhead tears from the gun deck at its root, the lance and its capacitor room going with it',
                 path=[(B1, reach), (B1, 0.8), (3.1, 0.3), (2.85, -0.2), (3.02, -0.7), (B1, -reach)])
    K.break_line('B-2', B2, 'the engine section tears from the reactor section, behind the spire line',
                 path=[(B2, reach), (-6.0, 0.9), (-6.12, 0.3), (-6.02, -0.3), (-6.1, -0.9), (B2, -reach)])
    K.break_line('B-3', 0.0, 'under the gun deck: the belly plating peels away below the galleries and their shell rooms',
                 path=[(2.6, PEEL), (1.0, PEEL + 0.02), (-0.8, PEEL - 0.02), (-2.2, PEEL + 0.01), (-3.3, PEEL)], kind='long')
    K.break_line('B-4', -3.6, 'the spire line snaps off as one piece, the spine block tearing along its root',
                 path=[(-1.4, SPZ - 0.2), (-2.8, SPZ - 0.21), (-4.4, SPZ - 0.2), (-5.9, SPZ - 0.21)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit gun galleries, frames, the reactor, the lance\'s capacitor room. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly (R186).'))
    K.point('core', 'hp_core', (-4.4, 0, -0.25))
    # four breach anchors (Cruiser base 4, Sunward +0), in the contract's layout for 4 (hardpoints.breach_layout: prow port,
    # mid starboard, mid port, eng starboard), each on open plating. Stage 7 (export7.py authored) needs each one 0.03 ship
    # lengths (0.43) clear of every part within 0.04 lengths of where it is placed, and 0.05 lengths (0.72) from the anchors
    # before it measured in x and height only; the spots are the clearest of a scan of both sides (Nov 20, after the PC runs
    # found 4.6 closed on the starboard side and then no mid anchor)
    for i, (x, z, sec, side) in enumerate(((5.0, BALL_Z, 'prow', 1), (0.2, BALL_Z - 0.45, 'mid', -1), (1.0, BALL_Z + 0.15, 'mid', 1),
                                           (-3.5, BALL_Z - 0.3, 'eng', -1))):
        K.point('breach', 'hp_breach_%d' % i, (x, side * hw_at(x, z), z), side='port' if side > 0 else 'stbd', section=sec, note='on open side plating')
    for i, side in enumerate((1, -1)):
        p, n = lower_pt(5.6, side, 0.45)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(p), side='port' if side > 0 else 'stbd')
        p, n = facet_pt(-5.2, side, 0.6)
        K.point('rcs', 'hp_rcs_%d' % (i + 2), tuple(p), side='port' if side > 0 else 'stbd')
        hw = st_at(-3.0)[1]
        K.point('board', 'hp_board_%d' % i, (-3.0, side * hw, BALL_Z), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3
    # ---------- the forged plating, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), closed=spec.get('closed', True), unit=0.6)
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('S10_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('S10_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='S10_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('The bow is one spearhead point carrying the Oath lance in a heavy forged round collar (about a third of the concept\'s opening): one emitter in the point, a dark bore, a small ember lens deep inside',
             'designs.md: "the beauty\'s spearhead reads as a shallow fork around the emitter (build one point, emitter in its face)"; the Board\'s brief: one emitter set into the bow point, never a big glowing disc')
    K.change('Four battery ports a side in one row at 38 / 47 / 56 / 65 percent, not the pictures\' two rows of three',
             'data.js battery fires 4 shots a volley, one port per shot (designs.md table, the family battery pattern on S8; R241 SPLIT rule); the ports are big with heavy proud collars and ember gallery slits between them (Board rev 1 note)')
    K.change('Five spires, not seven, about 70 percent of the table\'s heights (tallest 1.2 over the spine block, against 1.7), set close in one tight row at 66 to 86 percent, ember in the slats (the shared radiator from issue 1158), so the spire is not a whole lit tower',
             'designs.md table (5 spires); Ryan, Nov 19 2026 (R331): "can we scale down the giant radiator/orange towers on each ship a bit too?"; the ember shows in the slats, not as a whole lit tower')
    K.change('The paired cheek housings on the upper facets either side of the lance trunk are the lance\'s capacitor banks',
             'designs.md chair ruling: the faction\'s "one heavy pair at the bow" is met in form by the emitter and its paired cheek housings')
    K.change('The two engines are bells on short riveted drums (1.2 across, offsets 0.8), glowing ember, no flame plume',
             'designs.md table; in game the bells glow ember and the game draws the plume (ships.md 0.2 (5))')
    K.change('No deck turrets: the crowned deck stays clean except the power trunk, one hoist head and four hatches',
             'data.js penitent has no turret slot (designs.md: "the crowned deck stays clean"; R241: no decorative weapons)')
    K.change('The hull is widest at the stern third (2.9, 3.0 over the gun deck lips, at 68 percent); with the battery ports, their proud collars and short barrels the outline reaches 4.15 at the guns (the barrels kept short so the ports read as deep round openings, as the concept draws them)',
             'designs.md: beam 3.0 at about 68 percent; factions.md: widest at the stern third')
    K.change('A raised plated dorsal ridge runs from the lance back to the spine block, tapering low before the command slits',
             'the concept\'s strongest line (the Board\'s rev 1 note); it is the lance\'s power trunk, and it ends low so the bridge slits keep their view')
    K.change('Attitude thrusters, deck and belly hatches, a hoist head, heat louvres, ember slits, frost running points and a belly armour step added',
             'a ship in space needs thrusters and access; the reactor needs louvres; the pictures show no underside; every part has a job (R221)')
    K.change('Transverse breaks at the spearhead root (30 percent) and behind the spire line (B-2); the gun deck peel and the spire line peel sit in the one compartment between',
             'factions.md "How it breaks" (lengthwise between deck rows, the spire line as one piece); the build contract keeps every long seam inside one transverse compartment, and the spire line overlaps the gun deck stations on this hull')
    K.change('B-3 peels the belly plating below the gun deck, the liner is relieved along that seam and at both joints, frames between the breaks stop above it, and the keel deck and ballast tanks are gone',
             'the first peel sat on the sloped lower hull and tore through the liner and the rooms behind it, so the death check found 411 inside faces on the outer hull; the S8 liner relief and a clear belly bring that to 0')
    K.change('The battery ports are S8\'s heavy broadside mount (forged surround, ball mantlet, a real barrel) scaled to the hull (14.5 / 27, then 1.2 times on Ryan\'s "slightly bigger")',
             'Ryan, Nov 20 2026: the concept\'s open tube ports read as torpedo tubes in game; he picked S8\'s gun mounts "sized appropriately for the ship size", which also ties the Vigil to S8\'s family')
    K.open_item('The belly is designed here; the concept shows no underside')
    K.open_item('Frost-white markings and the half-sun crest are paint (the Sunward stack), not modelled')


INV_NOTES = {}
