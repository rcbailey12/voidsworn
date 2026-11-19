# voidsworn_S8: the Daybreak-class dreadnought, the Sunward Crusade flagship (data.js ascendant, class Dreadnought, 27.0 world
# units). Issue 738. Shape of record: contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg and _beauty.jpg (S8
# settled in direction, R185; style not reached, R206 (2): this sheet dresses it in the realistic detailed style, R197).
# data.js ascendant: hbattery P, hbattery S, turret T, flak T; ability nova; no hangar, no lance.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): S8 is a base, not a trace.
# Measured off the S8 sheet's true views (top view above, side view below, bow on the RIGHT in both; 1450 px = 27 units): the hull
# body about 4.4 wide from a quarter to two thirds of the length, the radiator bank 5.3 wide at the stern quarter, the guns
# reaching about 5.4 across amidships; the body about 2.2 deep, the radiator bank's top 4.0 over the belly; the fork and its
# blades the forward 28 percent. Hull length to beam 6.1, length to height 12.3 (median over the middle 60 percent).
# Ruled changes that bind this sheet (pack.md section 9, R232): the fork is replaced, the bow designed for this class; no lance
# recess (the Daybreak carries no lance); the spires vary in profile. Every change from S8 is listed by K.change below.
# +X bow, +Y port, +Z up. Bow tip x = +13.5, engine exits x = -13.5. The broadside deck line (the casemate balls) z = 0.08.
import math

CODE = 'voidsworn_S8'
NAME = 'Daybreak-class dreadnought (Sunward Crusade flagship)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Dreadnought'
LENGTH = 27.0
GAME = "data.js ascendant (cls 'Dreadnought'); length from godot/render/hull_table.gd CLS_LEN['Dreadnought'] = 27.0 (drawn x SHIP_K 1.6 = 43.2 on the board)"
BEAUTY = 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg'
# the true views on the S8 sheet (x0, y0, x1, y1), bow on the right in both
CONCEPT_VIEWS = dict(top=dict(box=(15, 150, 1485, 500), largest=True, flip=True), side=dict(box=(15, 590, 1485, 850), largest=True, flip=True))
CROPS = [('bow (the spearhead)', (1050, 80, 1536, 560)), ('midships (gun deck and turrets)', (550, 100, 1150, 600)), ('stern (spires and engines)', (0, 180, 700, 760))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus738',
             blend_where='rendered in the issue 738 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_S8 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the new Sunward kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them. Beyond the fit check, the sheet\'s own looks sent back: the first hull (3.2 deep, '
                    'the Sear pair on tall drums) read as a boat with battleship turrets, so the hull came down to 2.75 deep and the turrets went to S8\'s low grid; '
                    'the first spires (fin panels leaning out) read as organ pipes from the beam and shards from above, so they became fin stacks that glow; the '
                    'gun jackets\' close fins read as springs, so each carries three cooling rings.')

# ---------------------------------------------------------------------------------------------------- the hull section
# The blade's section (port half; the starboard half mirrors it): a crowned deck, a deck-edge chamfer, a big upper facet sloping
# out and down to the knuckle, the vertical broadside band (the gun deck face, kt to kb), a lower facet sloping in, a chine
# chamfer, a flat worked belly. So the flanks are angled facets, never a flat wall (R244), and the bow keeps the same facets
# down to its point (a forged spearhead, diamond in section, its tip at mid height: never a ship's stem, factions.md).
# (x, hw: half-beam at the knuckle, zt: deck, zb: belly, kt, kb: the broadside band's top and bottom, dw: deck half-width share)
ST = [
    (13.5, 0.03, 0.02, -0.07, -0.01, -0.04, 0.4),
    (12.6, 0.4, 0.21, -0.38, 0.04, -0.11, 0.42),
    (11.2, 0.9, 0.46, -0.72, 0.11, -0.18, 0.46),
    (9.5, 1.42, 0.75, -1.04, 0.21, -0.24, 0.5),
    (7.6, 1.85, 0.98, -1.3, 0.31, -0.28, 0.55),
    (5.8, 2.1, 1.14, -1.48, 0.39, -0.31, 0.58),
    (4.8, 2.18, 1.2, -1.55, 0.42, -0.32, 0.6),
    (2.0, 2.2, 1.2, -1.56, 0.42, -0.32, 0.6),
    (-1.0, 2.26, 1.2, -1.56, 0.42, -0.32, 0.6),
    (-2.8, 2.38, 1.2, -1.56, 0.43, -0.33, 0.6),
    (-4.6, 2.56, 1.22, -1.58, 0.45, -0.34, 0.6),
    (-6.6, 2.66, 1.22, -1.58, 0.45, -0.34, 0.6),
    (-8.6, 2.6, 1.2, -1.56, 0.44, -0.34, 0.6),
    (-10.2, 2.44, 1.14, -1.48, 0.42, -0.32, 0.6),
    (-11.6, 2.3, 1.05, -1.36, 0.38, -0.3, 0.58),
]
# the same stations in the sheet kit's loft format (x, half-beam port, half-beam starboard, belly, deck, -, -), for the sheet tools
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
CROWN = 0.07       # the deck's crown at the centreline
BWF = 0.58         # the belly's half-width share of hw
SHELL = 0.28       # hull thickness (the solidify shell)
B3_RELIEF = (0.10, 0.80)  # the bounds of the relief strip along each lower flank facet
GUN_X = (3.55, 2.2, 0.85, -0.5, -1.85)   # the five broadside ports a side (hbattery fires 5 shots a volley)
BALL_Z = 0.05      # the broadside deck line
PL = dict(size=(0.48, 0.92), thick=(0.03, 0.07))


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
    c = min(0.12, hw * 0.06); c2 = min(0.1, hw * 0.05)
    kt_ = min(kt, zt - 2 * c - 0.01); kb_ = max(kb, zb + 2 * c2 + 0.01)
    return [(0.0, zt + CROWN * min(1.0, hw)), (dw, zt), (dw + c, zt - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


def shell_ring(x):
    """Add two straight-edge stations for the liner relief on each lower flank."""
    half = half_ring(x)
    a, b = half[4:6]
    half[5:5] = [tuple(u + (v - u) * t for u, v in zip(a, b)) for t in B3_RELIEF]
    return [(x, y, z) for y, z in half + [(-y, z) for y, z in reversed(half[1:-1])]]


def relieve_liner(hull, shell, stations):
    """Keep the exterior plating continuous and leave a break between the two liner runs."""
    import bpy

    strip = hull.vertex_groups.new(name='B3_relief')
    liner = hull.vertex_groups.new(name='inner_shell')
    shell.shell_vertex_group = liner.name
    ring_size = len(hull.data.vertices) // len(stations)
    port = range(3, 5 + len(B3_RELIEF))
    flanks = [*port, *(ring_size - j for j in port)]
    relief_vertices = []
    for i, x in enumerate(stations):
        # The longitudinal tear reaches the transverse joint on either flank.
        if 4.5 <= x <= 5.5 or -3.6 <= x <= -2.5:
            relief_vertices.extend(i * ring_size + j for j in range(ring_size))
        elif -2.5 < x < 4.5:
            relief_vertices.extend(i * ring_size + j for j in flanks)
    strip.add(relief_vertices, 1.0, 'REPLACE')

    tree = bpy.data.node_groups.new('S8 B-3 liner clearance', 'GeometryNodeTree')
    for direction in ('INPUT', 'OUTPUT'):
        tree.interface.new_socket(name='Geometry', in_out=direction, socket_type='NodeSocketGeometry')
    source = tree.nodes.new('NodeGroupInput')
    output = tree.nodes.new('NodeGroupOutput')
    remove = tree.nodes.new('GeometryNodeDeleteGeometry')
    remove.domain = 'FACE'
    both = tree.nodes.new('ShaderNodeMath')
    both.operation = 'MULTIPLY'
    for i, group in enumerate((strip, liner)):
        weight = tree.nodes.new('GeometryNodeInputNamedAttribute')
        weight.data_type = 'FLOAT'
        weight.inputs['Name'].default_value = group.name
        tree.links.new(weight.outputs['Attribute'], both.inputs[i])
    full_face = tree.nodes.new('ShaderNodeMath')
    full_face.operation = 'GREATER_THAN'
    full_face.inputs[1].default_value = 0.99
    tree.links.new(both.outputs[0], full_face.inputs[0])
    tree.links.new(full_face.outputs[0], remove.inputs['Selection'])
    tree.links.new(source.outputs['Geometry'], remove.inputs['Geometry'])
    tree.links.new(remove.outputs['Geometry'], output.inputs['Geometry'])
    hull.modifiers.new('B-3 liner relief', 'NODES').node_group = tree


def hw_at(x, z, inset=0.0):
    """the section's half-width at height z (port side), inset by `inset` (the inside of the skin): 0 when z is outside"""
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
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit (tools/blender/kits/voidsworn)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]   # an octagon stand-in for kit helpers that read it
    K.hull_rounded = False
    xs = sorted({r[0] for r in ST} | {x / 2 for x in range(-23, 27)}, reverse=True)
    xbow = [x for x in xs if x >= 4.8]; xaft = [x for x in xs if x <= 4.8]
    rings = [ring(x) for x in xs]
    hull = K.loft_rings(CODE + '_hull', [shell_ring(x) for x in xs], 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    relieve_liner(hull, md, xs)
    K.mass('Hull: the blade', hull, 'black iron plate',
           note='a long faceted blade: crowned deck, big upper facets, the broadside band, lower facets, a flat worked belly; widest (5.3) at the stern third')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    rb = [ring(x) for x in xbow]; ra = [ring(x) for x in xaft]
    plate_jobs = [('hull', rings, dict(PL, faces=[0, 13], mats={'siron': 3, 'siron2': 2}, seed=11, inv='deck_plates')),
                  ('hull_fb', rb, dict(PL, faces=[2, 11], tri=True, mats={'siron': 4, 'siron2': 2}, seed=12, inv='flank_plates', size=(0.5, 1.0))),
                  ('hull_f', ra, dict(PL, faces=[2, 11], mats={'siron': 4, 'siron2': 2}, seed=16, inv='flank_plates')),
                  ('hull_b', rings, dict(PL, faces=[3, 10], mats={'siron2': 3, 'siron': 2}, seed=13, inv='flank_plates', size=(0.36, 0.7))),
                  ('hull_l', rings, dict(PL, faces=[4, 9], mats={'siron': 3, 'siron2': 2}, seed=14, inv='flank_plates')),
                  ('hull_v', rings, dict(PL, faces=[6, 7], mats={'siron2': 3, 'siron': 2}, seed=15, inv='belly_plates'))]

    # ---------------- the bow: a forged spearhead with a raised centre ridge and layered cheek plates ----------------
    ridge = []
    for x in (12.9, 12.0, 10.5, 9.0, 7.8, 6.9, 6.45):
        f = (12.9 - x) / 7.7
        w = 0.1 + 0.32 * f; hgt = 0.06 + 0.16 * f; z = deck_z(x, 0.0) - 0.02
        ridge.append([(x, w, z), (x, w * 0.55, z + hgt), (x, -w * 0.55, z + hgt), (x, -w, z)])
    K.mass('Bow ridge', K.loft_rings('S8_bow_ridge', ridge, 'siron2'), 'darker iron',
           note='the spearhead\'s raised centre ridge (a forged fuller), tapering to the point; stiffens the long bow')
    ridge2 = []
    for x in (11.6, 10.5, 9.0, 7.8, 6.9):
        f = (11.6 - x) / 4.7
        w = 0.06 + 0.12 * f; hgt = 0.05 + 0.05 * f; z = deck_z(x, 0.0) - 0.02 + 0.06 + 0.16 * (12.9 - x) / 7.7
        ridge2.append([(x, w, z), (x, w * 0.6, z + hgt), (x, -w * 0.6, z + hgt), (x, -w, z)])
    K.loft_rings('S8_bow_ridge_step', ridge2, 'sworn')
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        # the cheek plates: two forged layers along the upper facet, stepping back toward the gun deck (the blade's bevels)
        for layer, (x0, x1, f0, f1, out) in enumerate(((11.8, 5.4, 0.15, 0.72, 0.09), (10.2, 6.0, 0.25, 0.6, 0.17))):
            rs = []
            for x in [x0 + (x1 - x0) * i / 6 for i in range(7)]:
                a, n = facet_pt(x, side, f0); b, _ = facet_pt(x, side, f1)
                taper = min(1.0, (x0 - x) / 1.2) * min(1.0, (x - x1) / 0.6 + 0.35)
                o = out * max(0.15, taper)
                rs.append([tuple(a - n * 0.02), tuple(a + n * o), tuple(b + n * o), tuple(b - n * 0.02)] if side > 0 else
                          [tuple(b - n * 0.02), tuple(b + n * o), tuple(a + n * o), tuple(a - n * 0.02)])
            ob = K.loft_rings('S8_cheek%d_%s' % (layer, nm[0]), rs, 'siron' if layer == 0 else 'siron2')
            plate_jobs.append(('cheek%d%s' % (layer, nm[0]), rs, dict(PL, faces=[1], tri=True, mats={'siron': 2, 'siron2': 1}, seed=20 + layer + (side > 0) * 5,
                                                                    inv='bow_plates', size=(0.3, 0.7), closed=False)))
            if layer == 0:
                K.mass('Bow cheek plates, %s' % nm, ob, 'black iron', note='two forged layers along the upper facet, the spearhead\'s bevels')
    K.mark('spearhead', 'hull', ['facet', 'step', 'chamfer'])

    # ---------------- the broadside band: the gun deck lips (recess walls) and the five ports a side ----------------
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        for lip, zz in (('upper', 0), ('lower', 1)):
            rs = []
            xl = [4.45, 4.15] + [4.15 - (4.15 + 2.45) * i / 8 for i in range(1, 9)] + [-2.75]
            for i, x in enumerate(xl):
                _, hw, zt, zb, kt, kb, dwf = st_at(x)
                out = 0.0 if i in (0, len(xl) - 1) else 0.24
                if zz == 0:
                    pts = [(hw - 0.06, kt + 0.14), (hw + out, kt + 0.02), (hw + out, kt - 0.08), (hw - 0.06, kt - 0.08)]
                else:
                    pts = [(hw - 0.06, kb + 0.08), (hw + out, kb + 0.08), (hw + out, kb - 0.03), (hw - 0.06, kb - 0.14)]
                rs.append([(x, side * y, z) for (y, z) in (pts if side > 0 else pts[::-1])])
            ob = K.loft_rings('S8_lip_%s_%s' % (lip, nm[0]), rs, 'siron2')
            K.mass('Gun deck %s lip, %s' % (lip, nm), ob, 'darker iron', note='the armoured shelf over (under) the broadside ports; its ends are angled')
    K.mark('gun_deck', 'belt', ['band', 'plate'])
    for side in (1, -1):
        sn = 'P' if side > 0 else 'S'
        for i, x in enumerate(GUN_X):
            hw = st_at(x)[1]
            K.gun('%s%d' % (sn, i + 1), (x, side * hw, BALL_Z), 90 * side, 0.0, barrels=1, cal=0.115, blen=0.72, size=1.0, mount='casemate',
                  normal=(0, side, 0), slot=sn, weapon='hbattery', inv='broadside',
                  note='%s broadside port %d of 5 (heavy sear broadside, hbattery %s)' % ('port' if side > 0 else 'starboard', i + 1, sn))

    # ---------------- deck: the Sear turret barbettes (superfiring pair on the centreline), the flak tubs ----------------
    def drum(name, x, y, r, z0, z1, n=16):
        rs = []
        for k, (zz, rr) in enumerate(((z0 - 0.15, r), (z1 - 0.06, r), (z1, r - 0.06))):
            rs.append([(x + rr * math.cos(2 * math.pi * i / n + math.pi / n), y + rr * math.sin(2 * math.pi * i / n + math.pi / n), zz) for i in range(n)])
        # loft_rings lofts along its ring list: a stack of horizontal rings lofts straight up
        V = [v for r_ in rs for v in r_]
        F = []
        for j in range(len(rs) - 1):
            for i in range(n):
                a, b = j * n + i, j * n + (i + 1) % n
                F.append((a, b, b + n, a + n))
        F.append(tuple(range(n))[::-1]); o = (len(rs) - 1) * n; F.append(tuple(range(o, o + n)))
        ob = K._obj(name, V, F, 'siron2', grp='hull')
        K.keepouts.append((Vector((x, y, z1)), r + 0.1))
        return ob
    # S8's four low deck turrets in a grid of two pairs (no tall barbettes: R185 (5), no battleship turrets): the Sear pair forward on
    # low forged tubs at the deck edges, the spark flak pair aft on lower tubs; each pair side by side is one data.js slot
    TY = 1.42
    zS, zF = {}, {}
    for side in (1, -1):
        sn = 'port' if side > 0 else 'starboard'
        z0 = deck_z(3.4, side * TY); zS[side] = z0 + 0.24
        K.mass('Sear turret tub, %s' % sn, drum('S8_stub_%s' % sn[0], 3.4, side * TY, 0.66, z0 - 0.62, zS[side]), 'darker iron',
               note='a low forged tub at the deck edge, its skirt running down onto the upper facet')
        z0 = deck_z(0.6, side * TY); zF[side] = z0 + 0.1
        K.mass('Flak tub, %s' % sn, drum('S8_ftub_%s' % sn[0], 0.6, side * TY, 0.5, z0 - 0.62, zF[side], n=8), 'darker iron',
               note='an octagonal forged tub at the deck edge, lower than the Sear tubs')
    for x, y, r, z1 in [(3.4, s_ * TY, 0.66, zS[s_]) for s_ in (1, -1)]:
        for k in range(10):
            a = 2 * math.pi * (k + 0.5) / 10
            if (y > 0 and math.sin(a) < -0.5) or (y < 0 and math.sin(a) > 0.5):
                continue
            K.rib('S8_tubrib_%s_%d' % ('p' if y > 0 else 's', k), [(x + (r + 0.005) * math.cos(a), y + (r + 0.005) * math.sin(a), z1 - 0.5),
                                                                   (x + (r + 0.005) * math.cos(a), y + (r + 0.005) * math.sin(a), z1 - 0.08)], w=0.07, t=0.05, m='sworn')
    K.mark('barbettes', 'tier', ['face', 'roof', 'opening'])
    for side in (1, -1):
        K.gun('T%d' % (1 if side > 0 else 2), (3.4, side * TY, zS[side]), 0, 5, barrels=1, cal=0.125, blen=0.66, size=1.12, slot='T', weapon='turret', inv='sear_turrets',
              note='%s Sear turret: one heavy focusing emitter, on a low tub; the pair is the one Sear turret slot (2 shots: one each, every volley)' % ('port' if side > 0 else 'starboard'))
        K.gun('F%d' % (1 if side > 0 else 2), (0.6, side * TY, zF[side]), 30 * side, 12, barrels=2, cal=0.075, blen=0.6, size=0.8, slot='T', weapon='flak',
              inv='flak', note='%s spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley)' % ('port' if side > 0 else 'starboard'))

    # ---------------- the spine block and the spire line ----------------
    SPX = (-3.0, -9.3)
    sp = []
    for x in (SPX[0], SPX[0] - 0.35, -4.0, -6.0, -8.2, SPX[1] + 0.4, SPX[1]):
        z0 = deck_z(x, 0.0) - 0.08
        k = 0.0 if x in SPX else 1.0
        hwb = 0.62 * (0.85 + 0.15 * k)
        sp.append([(x, hwb, z0), (x, hwb, z0 + 0.22 + 0.2 * k), (x, hwb - 0.1, z0 + 0.35 + 0.22 * k), (x, -hwb + 0.1, z0 + 0.35 + 0.22 * k),
                   (x, -hwb, z0 + 0.22 + 0.2 * k), (x, -hwb, z0)])
    spine = K.loft_rings('S8_spine', sp, 'siron2')
    SPZ = deck_z(-6.0, 0.0) - 0.08 + 0.35 + 0.22   # the spine block's top: the spire roots stand on it
    K.mass('Spine block (the spire line\'s base)', spine, 'darker iron',
           note='a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-4)')
    plate_jobs.append(('spine', sp, dict(PL, faces=[0, 2, 4], mats={'siron': 2, 'siron2': 2}, seed=31, inv='spine_plates', size=(0.3, 0.7))))
    for x in (-3.4, -9.0):
        K.keepouts.append((Vector((x, 0, SPZ)), 0.5))
    # the bridge: armoured ember slits in the spine block's stepped forward face (the command deck below looks out through them)
    for i, y in enumerate((-0.27, 0.0, 0.27)):
        K.slit('W%d' % (i + 1), (SPX[0] + 0.005, y, deck_z(SPX[0], 0.0) - 0.08 + 0.19), (1, 0, 0), 0.17, 0.06, inv='bridge_slits',
               note='command deck window, ember-lit, in the spine block\'s face')
    K.mark('spine', 'spine', ['block', 'step', 'slit'])
    # seven radiator spires: heights rise to the tallest at the row's middle (amidships of the line), each profile its own.
    # R331 (Ryan, Nov 19 2026): every spire at 70 percent of the first build's height (SPIRE_SCALE), the same stations, lengths
    # and profiles, and the ember in the fin slats (glow='slats': three to five glowing fins at least 0.26 apart, was 0.17, with
    # the dark iron core between them, the fins reaching 60 percent as far out), never a whole lit tower, so the stripes read
    # from the battle camera's 34 degrees and from above (about half the old towers' lit area at both cameras)
    SPIRE_SCALE = 0.7
    SPIRES = [(-3.75, 1.6, 0.7, 0), (-4.6, 2.0, 0.72, 3), (-5.45, 2.35, 0.72, 1), (-6.3, 2.6, 0.74, 2), (-7.15, 2.35, 0.72, 1),
              (-8.0, 2.0, 0.72, 3), (-8.85, 1.55, 0.62, 0)]
    SPIRES = [(x, round(h * SPIRE_SCALE, 3), L, prof) for (x, h, L, prof) in SPIRES]
    for i, (x, h, L, prof) in enumerate(SPIRES):
        part = HP.radiator(h, L, profile=prof, spread=0.2 + 0.42 * h / 2.6, seed=i, glow='slats')
        K.organ('R%d' % (i + 1), part, (x, 0.0, SPZ), (0, 0, 1), fwd=(1, 0, 0), inv='spires', what='radiator spire, %.1f tall, profile %s' % (h, ('blade', 'stepped', 'twin', 'raked')[prof]),
                kind='radiator', note='sheds the reactor\'s heat: a few glowing radiator fins standing apart between iron posts, the dark iron core between them')
        K.mass('Radiator spire R%d (%s, %.1f tall)' % (i + 1, ('blade', 'stepped', 'twin', 'raked')[prof], h), bpy.data.objects['R%d_body_embar' % (i + 1)], 'ember fin slats on iron',
               note='one of the seven spires of the spire line')

    # ---------------- the stern: the stern hood over the drums, two big ember bells ----------------
    for side in (1, -1):
        K.engine('E%d' % (1 if side > 0 else 2), (-13.45, side * 1.15, -0.17), 1.05, 2.3, bell=1.0, body_r=0.95, rings=4,
                 inv='engines', note='%s main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug' % ('port' if side > 0 else 'starboard'))

    # ---------------- the belly: an armour step and its fittings ----------------
    belly = []
    for x, k in ((6.4, 0.0), (5.6, 1.0), (4.8, 1.0), (2.0, 1.0), (-1.0, 1.0), (-2.8, 1.0), (-4.6, 1.0), (-6.6, 1.0), (-8.6, 1.0), (-9.0, 1.0), (-9.8, 0.0)):
        _, hw, zt, zb, kt, kb, dwf = st_at(x)
        bw = hw * BWF - 0.25
        belly.append([(x, bw, zb + 0.02), (x, bw - 0.12 * k, zb - 0.13 * k), (x, -bw + 0.12 * k, zb - 0.13 * k), (x, -bw, zb + 0.02)])
    K.mass('Belly armour step', K.loft_rings('S8_belly', belly, 'siron2'), 'darker iron', note='a second forged layer under the gun deck and the reactor')
    plate_jobs.append(('belly', belly, dict(PL, faces=[1], mats={'siron2': 2, 'siron': 2}, seed=41, inv='belly_plates', closed=False)))

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p, n = facet_pt(9.6, side, 0.5)
        K.thruster('Q1' + sn, tuple(p), tuple(n), inv='thrusters', note='bow attitude thruster on the upper facet')
        p, n = facet_pt(-10.6, side, 0.6)
        K.thruster('Q2' + sn, tuple(p), tuple(n), inv='thrusters', note='stern attitude thruster on the upper facet')
        for i, x in enumerate((-4.4, -6.2, -8.0)):
            p, n = facet_pt(x, side, 0.45)
            K.vent('V%d%s' % (i + 1, sn), tuple(p), tuple(n), 0.9, 0.38, slats=5, inv='vents', note='reactor heat louvre over the reactor room')
        for i, x in enumerate(((GUN_X[1] + GUN_X[2]) / 2, (GUN_X[3] + GUN_X[4]) / 2)):
            # in two of the four gaps between the ports (the other two carry breach anchors): the galleries' vision slits
            hw = st_at(x)[1]
            K.slit('G%d%s' % (i + 1, sn), (x, side * (hw + 0.005), BALL_Z), (0, side, 0), 0.22, 0.07, inv='gallery_slits',
                   note='a gun gallery\'s ember slit between two ports')
        for i, x in enumerate((11.0, 8.4, 6.2, -3.4, -5.3, -7.1, -9.4)):
            # on the blade's edge: the knuckle line along the spearhead, the deck edge aft
            p, n = lower_pt(x, side, 0.1) if x > 5 else facet_pt(x, side, 0.06)
            K.lamp('L%d%s' % (i + 1, sn), tuple(p + n * 0.01), tuple(n), inv='lamps', note='frost-white running point on the deck edge')
    for i, (x, y) in enumerate(((6.6, 0.75), (6.6, -0.75), (-1.9, 1.3), (-1.9, -1.3))):
        K.hatch('H%d' % (i + 1), (x, y, deck_z(x, y) + 0.06), (0, -0.07 * (1 if y > 0 else -1), 1), 0.42, round_=True, inv='hatches', note='deck hatch')
    for i, (x, y) in enumerate(((3.0, 0.6), (3.0, -0.6), (-6.0, 0.6), (-6.0, -0.6))):
        K.hatch('H%d' % (i + 5), (x, y, st_at(x)[3] - 0.13 - 0.03), (0, 0, -1), 0.46, round_=True, inv='hatches', note='belly hatch on the armour step')
    K.hatchbox('HB1', (5.9, 0.0, deck_z(5.9, 0.0)), 0.6, 0.75, 0.3, inv='lift_heads', note='the bow lift head: stores up to the forward decks')
    # the dorsal power trunk: from the reactor section forward along the centreline to the bow lift head (S8's long centre strip)
    tr = []
    for x in (5.45, 5.3, 2.0, -1.0, -2.0, -2.15):
        z0 = deck_z(x, 0.0) - 0.03; k = 0.0 if x in (5.45, -2.15) else 1.0
        tr.append([(x, 0.2, z0), (x, 0.2, z0 + 0.06 + 0.06 * k), (x, 0.13, z0 + 0.1 + 0.08 * k), (x, -0.13, z0 + 0.1 + 0.08 * k), (x, -0.2, z0 + 0.06 + 0.06 * k), (x, -0.2, z0)])
    K.mass('Dorsal power trunk', K.loft_rings('S8_trunk', tr, 'siron2'), 'darker iron', note='armoured conduits from the reactor to the turrets and the bow (S8\'s centre strip)')
    for i in range(12):
        x = 5.0 - i * 0.58
        if abs(x - (-1.55)) < 0.45:
            continue
        K.rib('S8_trunkband_%d' % i, [(x, 0.21, deck_z(x, 0) - 0.02), (x, 0.0, deck_z(x, 0) + 0.17), (x, -0.21, deck_z(x, 0) - 0.02)], w=0.06, t=0.04, m='sworn')
    K.mark('trunk', 'spine', ['block', 'step', 'slit'])
    K.hatchbox('HB2', (-1.55, 0.0, deck_z(-1.55, 0.0)), 0.6, 0.6, 0.28, inv='lift_heads', note='the hoist head behind T2: power cells up to the Sear turrets')

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white markings (paint stage)', 13.5, -13.5, 'whole hull')
    K.colour('ember glow (radiator bars, engine throats, window slits)', -3.0, -13.5, 'the spires, the bells, the slits')
    K.colour('frost-white running points', 13.5, -13.5, 'the deck edges')
    K.colour('no rust anywhere, no blue light', 13.5, -13.5, 'factions.md Never')

    # ---------------- INSIDE: iron decks, the gun crews' galleries, frames, the reactor, machinery ----------------
    IN = SHELL + 0.06

    def deck_slab(name, z, x0, x1, inset=0.02, n=6):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = hw_at(x, z, IN) - inset
            rs.append([(x, hw, z - 0.04), (x, hw, z + 0.04), (x, -hw, z + 0.04), (x, -hw, z - 0.04)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name={'upper_aft': 'upper', 'main_aft': 'gun'}.get(name, name), z=z, x=(x1, x0)))

    def frame_at(name, x, zr=None, record=True):
        """a frame ring inside the skin at station x; zr: the heights it keeps (a list of (lo, hi)), so a frame never straddles a
        peel plane (ships.md 2c: a peel through frames leaves their halves outside the torn hull)"""
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.12)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        n = len(fo); pts = []
        for k in range(n):
            a_, b_ = k, (k + 1) % n
            for j in range(6):
                t0, t1 = j / 6, (j + 1) / 6
                pts.append(((fo[a_][0] + (fo[b_][0] - fo[a_][0]) * t0, fo[a_][1] + (fo[b_][1] - fo[a_][1]) * t0),
                            (fi[a_][0] + (fi[b_][0] - fi[a_][0]) * t0, fi[a_][1] + (fi[b_][1] - fi[a_][1]) * t0)))
        bands = zr or [(-99.0, 99.0)]
        V, F = [], []
        m = len(pts)
        for k in range(m):
            (oa, ia), (ob, ib) = pts[k], pts[(k + 1) % m]
            zs_ = [oa[1], ob[1], ia[1], ib[1]]
            if not any(all(lo_ <= z_ <= hi_ for z_ in zs_) for lo_, hi_ in bands):
                continue
            q = [oa, ob, ib, ia]
            o = len(V)
            V += [(x + 0.06, y_, z_) for (y_, z_) in q] + [(x - 0.06, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        if record:
            K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, note=''):
        # the widest room that stays inside the skin over its whole length and height
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.04
        if ymax is not None:
            w = min(w, ymax)
        K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)

    def side_room(name, kind, x0, x1, z0, z1, y_in, note=''):
        for side in (1, -1):
            w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.04
            ya, yb = (y_in, w) if side > 0 else (-w, -y_in)
            K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    # The gun deck floor and upper deck sit above peel B-3, between the bow and aft decks.
    deck_slab('bow', -0.12, 10.6, 5.65)
    deck_slab('upper', 0.58, 4.85, -2.65); deck_slab('gun', -0.12, 4.10, -2.65, inset=0.22)
    deck_slab('upper_aft', 0.58, -2.85, -11.3); deck_slab('main_aft', -0.45, -3.55, -11.3)
    for i, x in enumerate((11.2, 9.4, 7.6, 5.75, 4.75, 2.85, 1.5, 0.15, -1.2, -2.6, -3.55, -4.0, -5.8, -7.6, -9.4, -11.3)):
        # The adjacent frames sit clear of the transverse crossings. The gun deck frames stop short of the B-3 peel.
        if -2.75 < x < 5.0:
            frame_at('F%d_upper' % i, x, zr=[(-0.17, 99.0)]); frame_at('F%d_lower' % i, x, zr=[(-99.0, -1.06)], record=False)
        else:
            frame_at('F%d' % i, x)
    room('fire_control', 'machinery', 9.2, 7.9, -0.08, 0.45, note='the forward fire-control room: the broadside directors (no AI: plotted by hand)')
    room('bow_stores', 'hold', 9.6, 7.9, -0.6, -0.16, note='bow stores and the bow thrusters\' feeds')
    room('crew_fwd', 'crew', 7.5, 5.4, -0.08, 0.74, note='crew decks: the dawn watch berths')
    room('ballast_fwd', 'machinery', 7.5, 5.4, -0.95, -0.16, note='bow trim tanks and pumps')
    side_room('gun_gallery', 'gallery', 4.6, -2.45, -0.26, 0.53, 1.30, note='the gun crews\' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5)')
    # B-3 clearance: the inboard strip of each gallery carries its shell room and hoist drive above the peel.
    for suffix, y0, y1 in (('p', 0.94, 1.27), ('s', -1.27, -0.94)):
        K.room('shell_rooms_' + suffix, 'magazine', -2.4, 4.4, y0, y1, 0.04, 0.43, note='the broadside shell room in the gun gallery')
        K.room('shell_hoist_' + suffix, 'machinery', -2.4, 4.4, y0, y1, -0.15, -0.02, note='the shell hoist drive below the gallery shell room')
    room('sear_cells', 'magazine', 4.3, 2.6, -0.26, 0.53, ymax=0.9, note='the Sear turrets\' power cells, hoisted to both tubs')
    room('fire_plot', 'bridge', 0.2, -1.4, -0.26, 0.53, ymax=0.9, note='the broadside plotting room (no AI: plotted by hand)')
    room('flak_magazine', 'magazine', 2.2, 0.5, -0.26, 0.53, ymax=0.9, note='the spark flak magazine, between the tubs')
    room('upper_fwd_rooms', 'crew', 4.6, -2.45, 0.63, 0.82, note='the gunners\' mess and the chalk wall where the names go up before launch')
    room('command', 'bridge', -3.15, -4.0, 0.63, 0.82, note='the command deck under the spine block\'s slits')
    room('reactor', 'core', -4.3, -7.6, -1.18, 0.52, ymax=1.3, note='the reactor: its heat goes up through the plenum into the spires (hp_core)')
    side_room('coolant', 'machinery', -4.3, -7.6, -0.85, 0.5, 1.38, note='coolant pumps and heat exchangers either side of the reactor')
    room('plenum', 'machinery', -4.15, -9.0, 0.63, 0.82, note='the heat plenum feeding the spire line')
    room('roll_hall', 'crew', -3.55, -4.15, -0.41, 0.52, note='the Roll: the crew hall under the command deck')
    room('engine_room', 'engroom', -7.8, -10.0, -1.15, 0.52, note='the engine room and the two drives\' feeds')
    K.armour('upper facets and deck', 0.3, 'forged plate over the galleries and the turret hoists')
    K.armour('broadside band and lips', 0.35, 'the gun deck face, the heaviest belt')
    K.armour('spearhead', 0.4, 'solid forged layers toward the point')
    K.armour('belly and armour step', 0.3, '')
    K.armour('spine block', 0.25, 'it snaps off with the spires')
    # seams (factions.md "How it breaks": along the gun decks, the hull splits lengthwise between deck rows; the spire line snaps
    # off as one piece; R226: no machine on a seam; ships.md 2c: a peel is one level plane per compartment)
    reach = 2 * max(r[1] for r in ST)
    K.break_line('B-1', 5.0, 'the spearhead tears from the gun deck at its root, opening the crew decks and the fire-control room',
                 path=[(5.0, reach), (5.0, 1.2), (5.2, 0.4), (4.85, -0.3), (5.05, -1.1), (5.0, -reach)])
    K.break_line('B-2', -2.75, 'the gun deck tears from the reactor section, between the last ports and the spine block',
                 path=[(-2.75, reach), (-2.7, 1.4), (-2.6, 0.6), (-2.78, -0.2), (-2.62, -1.0), (-2.72, -1.6), (-2.75, -reach)])
    K.break_line('B-3', 0.0, 'along the gun decks: the lower hull peels away under the galleries, their shell rooms and the turrets',
                 path=[(4.7, -0.72), (2.6, -0.7), (0.2, -0.74), (-1.4, -0.71), (-2.5, -0.72)], kind='long')
    K.break_line('B-4', -6.0, 'the spire line snaps off as one piece, the spine block tearing along its root',
                 path=[(-3.05, SPZ - 0.3), (-5.0, SPZ - 0.32), (-7.0, SPZ - 0.3), (-9.2, SPZ - 0.31)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit gun galleries, frames, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).'))
    K.point('core', 'hp_core', (-5.9, 0, -0.3))
    # Eight breach anchors (Dreadnought base 8, Sunward +0): prow 3, mid 3, engine 2.
    # The lower mid flank clears the casemates and gallery fittings for stage 7.
    for i, (x, sec, side) in enumerate(((9.4, 'prow', 1), (8.0, 'prow', -1), (6.6, 'prow', 1), ((GUN_X[0] + GUN_X[1]) / 2, 'mid', -1),
                                        ((GUN_X[2] + GUN_X[3]) / 2, 'mid', 1), (-2.5, 'mid', -1),
                                        (-6.0, 'eng', 1), (-9.0, 'eng', -1))):
        _, _, _, _, kt, kb, _ = st_at(x)
        z = {'prow': (kt + kb) / 2, 'mid': -1.14, 'eng': BALL_Z}[sec]
        note = 'on the lower flank, clear of broadside fittings' if sec == 'mid' else 'on the broadside deck line'
        K.point('breach', 'hp_breach_%d' % i, (x, side * hw_at(x, z), z), side='port' if side > 0 else 'stbd', section=sec, note=note)
    for i, side in enumerate((1, -1)):
        p, n = facet_pt(9.6, side, 0.5)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(p), side='port' if side > 0 else 'stbd')
        p, n = facet_pt(-10.6, side, 0.6)
        K.point('rcs', 'hp_rcs_%d' % (i + 2), tuple(p), side='port' if side > 0 else 'stbd')
        hw = st_at(-3.6)[1]
        K.point('board', 'hp_board_%d' % i, (-3.6, side * hw, BALL_Z), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):   # worked metal, as the sheet kit renders its own metal rows
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3
    # ---------- the forged plating, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('S8_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('S8_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='S8_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('The forked prow is replaced by a forged spearhead: one point at mid height, diamond in section, a raised centre ridge and two layers of cheek plates along its upper facets', 'Ryan, Nov 12 (R232, pack.md question 1): "It shouldn\'t be the same shape for everything"; the Daybreak carries no lance, so no lance recess; the point at mid height with matching upper and lower facets is a blade, never a ship\'s stem (factions.md Never)')
    K.change('Five broadside ports a side, not seven', 'data.js hbattery fires 5 shots a volley; seven single guns would leave two silent on every volley (R241, the SPLIT rule); five heavy single guns all fire every volley')
    K.change('S8\'s four low deck turrets kept in its grid of two pairs, each pair one data.js slot: the two Sear turrets forward with one heavy emitter each, the two spark flak twins aft, all on low tubs at the deck edges', 'data.js ascendant carries one turret slot (2 shots) and one flak slot (3 shots); four twin turrets would be extra weapons or silent barrels (R241). Two single-emitter Sear turrets fire one shot each every volley; two flak twins share 3 shots over 4 barrels and both fire every volley (weapon_match SPLIT). The emitters are short enough that a pair trained at each other never meets (the fit check\'s SWEEP)')
    K.change('S8\'s radiator bank (upright ember bars in two wide wedges either side of the spine, rising to the stern end) becomes one row of seven radiator spires on the centreline spine block, tallest at the middle of the row, each its own profile (blade, raked, stepped, twin), each a stack of flat radiator fins glowing ember between iron posts', 'factions.md: "a row of tall radiator spires along the spine, tallest amidships"; Ryan, Nov 12 (R232): "not exactly the same shape for every ship". Upright panels read as organ pipes from the beam and shards from above in the first render; flat fins read as radiators from the battle camera and from above. The ember glow and the line\'s place in the stern half are S8\'s')
    K.change('The spires stand aft of every turret and rise toward the middle of the row', 'so both turret pairs fire aft past and over the whole line (the fit check\'s ARC test); the spires are broad finned radiators, never masts, so nothing reads as a gun aimed through a mast (R240)')
    K.change('The hull is a little deeper (2.75 against S8\'s 2.2) and its flanks are angled facets round a vertical broadside band', 'the gun deck, upper deck and real insides need the depth (R215); R244: big flanks carry angled facets, never a flat wall')
    K.change('The shell rooms and hoist drives sit in the port and starboard gun galleries', 'clears the space below the B-3 peel inside the accepted hull (R254, issue 1059)')
    K.change('The decks, frames and Roll hall clear the ends of B-3, and the inner liner has relief along the tear', 'keeps these parts inside their own wreck plating where B-3 meets B-1 and B-2 (issue 1059)')
    K.change('The hull is widest at the stern third (5.3 over the reactor); with the broadside barrels the outline is still widest amidships (7.1 at 56 percent), as S8\'s is', 'factions.md: "widest at the stern third"; S8\'s body is 4.4 from end to end, its width carried by the radiator bank and the guns')
    K.change('The two engine bells are bigger (2.1 across) and their drums run 1.55 deep into the stern', 'factions.md: "big bells, ember orange, deep-set"; S8\'s two bells are its stern\'s identity and must read from the battle camera')
    K.change('Weapons built from the lore, not S8\'s generic barrels (R221)', 'the broadside guns are heavy short guns in deep round ports (R244: a round opening has depth); the Sear turrets are forged turrets with one heavy focusing emitter and radiator fins (las); the spark flak a squat drum with twin braked barrels and ammunition drums (tools/blender/kits/voidsworn/README.md)')
    K.change('Attitude thrusters, deck and belly hatches, lift heads, heat louvres, ember slits, frost running points, a belly armour step added', 'a ship in space needs thrusters and access; the spires\' reactor needs louvres; S8 shows no underside; every part has a job (R221)')
    K.change('The command deck looks out through ember slits in the spine block\'s forward face, not a box on the deck', 'S8\'s small lit block before the radiators read as a deck house (R185 (5): no deck house); the same ember windows now sit in the spine block itself')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 738) ----------
    K.fix('T1 barrels at bearings 150 and -150 reaching the flak housings, and T1 against T2 at 175 to 180 (the first layout: the Sear pair on the centreline on tall drums)',
          'the Sear pair moved to S8\'s grid: side by side on low tubs at the deck edges (1.42 off the axis), emitters short enough that the pair trained at each other never meets; the tall drums are gone (R185 (5): no battleship turrets)')
    K.fix('Gallery slits G1 and G2: the ember pane inside the hull face', 'the pane set proud of the frame\'s back (kit slit, glass from 0.006)')
    K.fix('Deck hatches H1 to H4: the seam ring inside the crowned deck', 'hatches lifted 0.06 onto the crown')
    K.fix('Lift head HB1 inside the bow ridge', 'the ridge ends at 6.45; HB1 sits ahead of the trunk at 5.9')
    K.fix('Heat louvres V2 against the running lights L5', 'the aft running lights moved between the louvres (5.3 and 7.1 aft)')
    K.fix('Command deck slits W1 to W3 covered by the spine block, then by HB2 and the power trunk', 'the slits sit in the spine block\'s vertical forward face; HB2 moved forward to 1.55 aft; the trunk ends at 2.15 aft')
    K.fix('Spire roots R1 and R2, R6 and R7 intersecting', 'the root sockets shortened to the spire\'s own length')
    K.fix('Bow running lights L2 inside the cheek plates', 'the bow lights moved down to the knuckle line, the blade\'s edge')
    K.fix('Belly hatches H5 and H6 not touching the armour step', 'the step lofted through every hull station, so its face follows the belly; the hatches seat on it')
    K.change('The spires stand at about S8\'s bank height: the tallest 1.8 over the spine block (2.3 over the deck) against S8\'s 1.8', 'Ryan, Nov 19 2026 (R331, issue 1158): "can we scale down the giant radiator/orange towers on each ship a bit too?"; the first build\'s 2.6 tallest read as giant orange towers. Every spire is 70 percent of its first height (1.6, 2.0, 2.35, 2.6, 2.35, 2.0, 1.55 became 1.12, 1.4, 1.65, 1.82, 1.65, 1.4, 1.09), same count, stations, lengths and profiles; the spire line still crowns the silhouette at the battle camera')
    K.change('The ember is in the fin slats, not a whole lit tower (R331, issue 1158)', 'The shared Sunward spire option radiator(..., glow=\'slats\'): three to five glowing fins at least 0.26 apart (was 0.17), reaching 60 percent as far out, over the dark iron core, about half the old towers\' lit area at the battle and concept cameras. Warden, Vigil and the later Sunward builds use the same option (R333)')
    K.change('Modelled plates: sleek triangles on the spearhead\'s facets and cheek plates, ordered rows of forged plates elsewhere', 'paint direction sunward.md (R243, "more triangle sleek panels") asks for triangles on the flat fields; modelled on the deck in the first render they read as rows of letters at a distance, so the deck keeps forged rows and the Sunward paint stack lays its triangles there')
    K.open_item('The belly is designed here; S8 shows no underside')
    K.open_item('Frost-white markings and the half-sun crest are paint (the Sunward stack, a later job), not modelled')


INV_NOTES = {}
