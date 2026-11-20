# voidsworn_S9: the Warden-class frigate, the Sunward Crusade's knife (data.js warden, class Frigate, 6.5 world units). Issue 1156.
# Shape of record: the accepted concept contrib/muse/design/class_family_sunward_2026_11/ (warden_sheet.webp, warden_beauty.webp;
# designs.md "Warden" governs where a picture differs; Ryan accepted it Nov 19 2026 14:26 UTC with smaller spires, R331).
# data.js warden: autocannon F (3 shots), flak T (3 shots); ability evasive; no hangar, no broadside.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): the concept is a base, not a trace.
# Family pattern: the S8 Daybreak sheet (voidsworn_S8.py): the same blade section, the same kit, the same spire language, scaled
# to a frigate with its own counts (designs.md "Never copy from S8 literally").
# Measured off the Warden sheet's true views (top view above, side view below left, bow on the LEFT in both; 1330 px = 6.5 units):
# the hull about 1.2 wide over the stern third, the flak tubs at its deck edges, the spearhead the forward 40 percent.
# +X bow, +Y port, +Z up. Bow tip x = +3.25, engine exits x = -3.25. The broadside band's middle z = 0.01.
import math

CODE = 'voidsworn_S9'
NAME = 'Warden-class frigate (Sunward Crusade)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js warden (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5 (drawn x SHIP_K 1.6 = 10.4 on the board)"
BEAUTY = 'docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/voidsworn_S9/concept_sheet.jpg'
# the true views on the Warden sheet (x0, y0, x1, y1), bow on the LEFT in both (the build's side view is bow left too)
CONCEPT_VIEWS = dict(top=dict(box=(195, 310, 1660, 620), largest=True, flip=False), side=dict(box=(25, 800, 1300, 1070), largest=True, flip=False))
CROPS = [('bow (the spearhead and the repeater casemate)', (0, 280, 700, 780)), ('midships (the trunk and the flak pair)', (330, 120, 830, 620)),
         ('stern (the spire line and the bells)', (560, 180, 1024, 560))]
SHEET = dict(version=1, round='first sheet', date='2026-11-19', blend='opus1156',
             blend_where='rendered in the issue 1156 cloud copy (Blender 5.3 as the bpy module, Cycles CPU); `build.py voidsworn_S9 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Sunward kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

# ---------------------------------------------------------------------------------------------------- the hull section
# S8's blade section at frigate size (port half; the starboard half mirrors it): a crowned deck, a deck-edge chamfer, a big upper
# facet sloping out and down to the knuckle, the vertical broadside band (kt to kb: plated and louvred, no ports: the Warden has
# no broadside slot), a lower facet sloping in, a chine chamfer, a flat worked belly. The bow keeps the facets to its point (a
# forged spearhead, diamond in section, its tip at mid height: never a ship's stem, factions.md).
# (x, hw: half-beam at the knuckle, zt: deck, zb: belly, kt, kb: the band's top and bottom, dw: deck half-width share)
ST = [
    (3.25, 0.012, 0.005, -0.04, -0.012, -0.025, 0.4),
    (3.0, 0.1, 0.05, -0.12, 0.0, -0.05, 0.42),
    (2.6, 0.24, 0.12, -0.22, 0.03, -0.07, 0.46),
    (2.1, 0.37, 0.19, -0.3, 0.07, -0.085, 0.5),
    (1.5, 0.49, 0.25, -0.36, 0.1, -0.09, 0.55),
    (0.9, 0.56, 0.28, -0.39, 0.11, -0.095, 0.58),
    (0.2, 0.6, 0.3, -0.4, 0.12, -0.095, 0.6),
    (-0.6, 0.64, 0.3, -0.4, 0.12, -0.095, 0.6),
    (-1.4, 0.68, 0.3, -0.41, 0.125, -0.1, 0.6),
    (-2.1, 0.67, 0.3, -0.4, 0.12, -0.1, 0.6),
    (-2.6, 0.64, 0.285, -0.38, 0.115, -0.095, 0.6),
    (-2.92, 0.6, 0.26, -0.34, 0.1, -0.09, 0.58),
]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
CROWN = 0.03       # the deck's crown at the centreline
BWF = 0.58         # the belly's half-width share of hw
SHELL = 0.06       # hull thickness (the solidify shell)
BAND_Z = 0.01      # the broadside band's middle
PL = dict(size=(0.17, 0.3), thick=(0.009, 0.018))
UNIT = 0.4         # the kit plating's fixed sizes (smallest face, gaps, sink), scaled for a frigate (forged_plates unit)
RR = 0.011         # rivet head size on this hull's plates
GUN_X = 2.34       # the Sear repeater casemate, station 14 percent
FLAK_X = -0.65     # the spark flak pair, station 60 percent
TY = 0.44          # the flak tubs' offset: the deck edges
SPINE_X = (-0.45, -2.6)   # the spine block: its forward face (the command slits) to its aft end
TRANS = [(-0.9, 9.0), (-0.9, 0.24), (-0.4, 0.22), (-0.4, -0.22), (-0.9, -0.24), (-0.9, -9.0)]   # B-1's plan path


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
    dw = max(0.006, hw * dwf - inset * 0.4); bw = max(0.006, hw * BWF - inset * 0.4)
    c = min(0.04, hw * 0.06); c2 = min(0.035, hw * 0.05)
    kt_ = min(kt, zt - 2 * c - 0.003); kb_ = max(kb, zb + 2 * c2 + 0.003)
    return [(0.0, zt + CROWN * min(1.0, hw / 0.66)), (dw, zt), (dw + c, zt - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


def ring(x, inset=0.0):
    h = half_ring(x, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(x, y, z) for (y, z) in full]


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
    return zt + CROWN * min(1.0, hw / 0.66) * max(0.0, 1 - abs(y) / dw)


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


def band_pt(x, side, z=None):
    from mathutils import Vector
    _, hw, zt, zb, kt, kb, dwf = st_at(x)
    return Vector((x, side * hw, BAND_Z if z is None else z)), Vector((0, side, 0))


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit (tools/blender/kits/voidsworn)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    xs = sorted({r[0] for r in ST} | {x / 8 for x in range(-23, 26)}, reverse=True)
    hull = K.loft_rings(CODE + '_hull', [ring(x) for x in xs], 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the blade', hull, 'black iron plate',
           note='a narrow faceted blade: crowned deck, big upper facets, the plated band, lower facets, a flat worked belly; widest (1.36) at the stern third')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    # the plating rings: one every quarter unit (a plate course), so the plates run at the hull's own plate size
    px = sorted({r[0] for r in ST if r[0] < 3.2} | {x / 4 for x in range(-11, 13)}, reverse=True)
    rings = [ring(x) for x in px]
    rb = [ring(x) for x in px if x >= 1.4]; ra = [ring(x) for x in px if x <= 1.5]
    plate_jobs = [('hull', rings, dict(PL, faces=[0, 13], mats={'siron': 3, 'siron2': 2}, seed=11, inv='deck_plates')),
                  ('hull_fb', rb, dict(PL, faces=[2, 11], tri=True, mats={'siron': 4, 'siron2': 2}, seed=12, inv='flank_plates', size=(0.17, 0.32))),
                  ('hull_f', ra, dict(PL, faces=[2, 11], mats={'siron': 4, 'siron2': 2}, seed=16, inv='flank_plates')),
                  ('hull_b', rings, dict(PL, faces=[3, 10], mats={'siron2': 3, 'siron': 2}, seed=13, inv='flank_plates', size=(0.12, 0.26))),
                  ('hull_l', rings, dict(PL, faces=[4, 9], mats={'siron': 3, 'siron2': 2}, seed=14, inv='flank_plates')),
                  ('hull_v', rings, dict(PL, faces=[6, 7], mats={'siron2': 3, 'siron': 2}, seed=15, inv='belly_plates'))]

    # ---------------- the bow: a forged spearhead with a raised centre ridge and one layer of cheek plates ----------------
    ridge = []
    for x in (3.08, 2.9, 2.75, 2.62):
        f = (3.08 - x) / 0.46
        w = 0.025 + 0.05 * f; hgt = 0.015 + 0.025 * f; z = deck_z(x, 0.0) - 0.006
        ridge.append([(x, w, z), (x, w * 0.55, z + hgt), (x, -w * 0.55, z + hgt), (x, -w, z)])
    K.mass('Bow ridge', K.loft_rings('S9_bow_ridge', ridge, 'siron2'), 'darker iron',
           note='the spearhead\'s raised centre ridge (a forged fuller) from the point back to the casemate\'s glacis')
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        # the cheek plates: one forged layer along the upper facet, stepping back toward the casemate (the blade's bevel)
        x0, x1, f0, f1, out = 2.95, 1.55, 0.18, 0.7, 0.022
        rs = []
        for x in [x0 + (x1 - x0) * i / 6 for i in range(7)]:
            a, n = facet_pt(x, side, f0); b, _ = facet_pt(x, side, f1)
            taper = min(1.0, (x0 - x) / 0.35) * min(1.0, (x - x1) / 0.2 + 0.35)
            o = out * max(0.15, taper)
            rs.append([tuple(a - n * 0.006), tuple(a + n * o), tuple(b + n * o), tuple(b - n * 0.006)] if side > 0 else
                      [tuple(b - n * 0.006), tuple(b + n * o), tuple(a + n * o), tuple(a - n * 0.006)])
        ob = K.loft_rings('S9_cheek_%s' % nm[0], rs, 'siron')
        plate_jobs.append(('cheek%s' % nm[0], rs, dict(PL, faces=[1], tri=True, mats={'siron': 2, 'siron2': 1}, seed=20 + (side > 0) * 5,
                                                       inv='bow_plates', size=(0.1, 0.24), closed=False)))
        K.mass('Bow cheek plates, %s' % nm, ob, 'black iron', note='a forged layer along the upper facet, the spearhead\'s bevel')
    K.mark('spearhead', 'hull', ['facet', 'step', 'chamfer'])

    # ---------------- the bow gun: the Sear repeater in its forged casemate at the spearhead's root ----------------
    gz = deck_z(GUN_X, 0.0) - 0.005
    gpos = Vector((GUN_X, 0.0, gz))
    part = HP.gun(3, 0.019, 0.4, 0.38, 'casemate', pitch=0.0, weapon='autocannon')   # Ryan, Nov 20: smaller, less boxy, the barrels out front as on the concept
    part = K.emit('A1', part, HP.frame(gpos, (1, 0, 0), (0, 0, 1)), 'bow_gun')
    for ob in K.coll.objects:
        if ob.get('grp') == 'A1' and ob.get('role') != 'mount':
            ob['gun_fixed'] = 1
            ob['turret'] = 0
    fd = part.fit
    K.fitdata.append(dict(id='A1', kind='gun', slot='F', pivot=tuple(fd['trunnion'][1]), up=(0, 0, 1), mount='casemate', ring=tuple(gpos), rest_yaw=0.0,
                          reach=fd['reach'], band=(-10, 0, 10, 20), muzzles=[tuple(m[1]) for m in fd['muzzles']], cal=0.019 * 1.55,
                          hous_r=fd['radius'], rest_pitch=0.0, aim=tuple(fd['aim'][1]), bore=0.0095))
    K.features.append(dict(id='A1', kind='gun', what='sear repeater, three-barrel rotary casemate (fixed forward)', count=3, pos=tuple(gpos), aim=(0.0, 0.0),
                           slot='F', weapon='autocannon', src='picture', note='the frigate\'s bow gun (autocannon F, 3 shots: all three barrels fire every volley); the frigate turns to bring it to bear',
                           muzzle=[tuple(m[1]) for m in fd['muzzles']], normal=(0, 0, 1), inv=['bow_gun']))
    K.mark('casemate', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the broadside band: plated and louvred (no ports: the Warden has no broadside slot) ----------------
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        for lip, zz in (('upper', 0), ('lower', 1)):
            rs = []
            xl = [1.5, 1.38] + [1.38 - (1.38 + 2.2) * i / 8 for i in range(1, 9)] + [-2.32]
            for i, x in enumerate(xl):
                _, hw, zt, zb, kt, kb, dwf = st_at(x)
                out = 0.0 if i in (0, len(xl) - 1) else 0.045
                if zz == 0:
                    pts = [(hw - 0.015, kt + 0.03), (hw + out, kt + 0.005), (hw + out, kt - 0.02), (hw - 0.015, kt - 0.02)]
                else:
                    pts = [(hw - 0.015, kb + 0.02), (hw + out, kb + 0.02), (hw + out, kb - 0.006), (hw - 0.015, kb - 0.03)]
                rs.append([(x, side * y, z) for (y, z) in (pts if side > 0 else pts[::-1])])
            ob = K.loft_rings('S9_lip_%s_%s' % (lip, nm[0]), rs, 'siron2')
            K.mass('Band %s lip, %s' % (lip, nm), ob, 'darker iron', note='the armoured shelf over (under) the plated band; its ends are angled')
        for i, x in enumerate((1.05, 0.35, -0.35, -1.85)):
            p, n = band_pt(x, side)
            K._surface_part('U%d%s' % (i + 1, nm[0]), HP.vent(0.15, 0.06, 3, depth=0.025, fr=0.012), tuple(p + n * 0.042), tuple(n), (0, 0, 1), 'band_louvres',
                            'band louvre 0.15 x 0.06', 'vent', 'picture', 'a heat louvre in the plated band (the gallery spaces behind it breathe out here)', aperture=0.4)
    K.mark('gun_deck', 'belt', ['band', 'plate'])

    # ---------------- deck: the spark flak pair on low tubs at the deck edges ----------------
    def drum(name, x, y, r, z0, z1, n=8):
        rs = []
        for k, (zz, rr) in enumerate(((z0 - 0.04, r), (z1 - 0.016, r), (z1, r - 0.016))):
            rs.append([(x + rr * math.cos(2 * math.pi * i / n + math.pi / n), y + rr * math.sin(2 * math.pi * i / n + math.pi / n), zz) for i in range(n)])
        V = [v for r_ in rs for v in r_]
        F = []
        for j in range(len(rs) - 1):
            for i in range(n):
                a, b = j * n + i, j * n + (i + 1) % n
                F.append((a, b, b + n, a + n))
        F.append(tuple(range(n))[::-1]); o = (len(rs) - 1) * n; F.append(tuple(range(o, o + n)))
        ob = K._obj(name, V, F, 'siron2', grp='hull')
        K.keepouts.append((Vector((x, y, z1)), r + 0.03))
        return ob
    zF = {}
    for side in (1, -1):
        sn = 'port' if side > 0 else 'starboard'
        z0 = deck_z(FLAK_X, side * TY); zF[side] = z0 + 0.035
        K.mass('Flak tub, %s' % sn, drum('S9_ftub_%s' % sn[0], FLAK_X, side * TY, 0.15, z0 - 0.16, zF[side]), 'darker iron',
               note='an octagonal forged tub at the deck edge, its skirt running down onto the upper facet')
    K.mark('barbettes', 'tier', ['face', 'roof', 'opening'])
    for side in (1, -1):
        K.gun('F%d' % (1 if side > 0 else 2), (FLAK_X, side * TY, zF[side]), 30 * side, 12, barrels=2, cal=0.03, blen=0.24, size=0.32, slot='T', weapon='flak',
              inv='flak', note='%s spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley)' % ('port' if side > 0 else 'starboard'))

    # ---------------- the spine block and the spire line ----------------
    sp = []
    for x in (SPINE_X[0], SPINE_X[0] - 0.08, -0.8, -1.6, -2.3, SPINE_X[1] + 0.08, SPINE_X[1]):
        z0 = deck_z(x, 0.0) - 0.02
        k = 0.0 if x in SPINE_X else 1.0
        hwb = 0.17 * (0.85 + 0.15 * k)
        sp.append([(x, hwb, z0), (x, hwb, z0 + 0.06 + 0.05 * k), (x, hwb - 0.03, z0 + 0.1 + 0.05 * k), (x, -hwb + 0.03, z0 + 0.1 + 0.05 * k),
                   (x, -hwb, z0 + 0.06 + 0.05 * k), (x, -hwb, z0)])
    spine = K.loft_rings('S9_spine', sp, 'siron2')
    SPZ = deck_z(-1.6, 0.0) - 0.02 + 0.15   # the spine block's top: the spire roots stand on it
    K.mass('Spine block (the spire line\'s base)', spine, 'darker iron',
           note='a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-3)')
    plate_jobs.append(('spine', sp, dict(PL, faces=[0, 2, 4], mats={'siron': 2, 'siron2': 2}, seed=31, inv='spine_plates', size=(0.09, 0.22))))
    # the bridge: armoured ember slits in the spine block's forward face (the command deck below looks out through them)
    for i, y in enumerate((-0.075, 0.0, 0.075)):
        K._surface_part('W%d' % (i + 1), HP.slit(0.05, 0.022, depth=0.025, fr=0.012), (SPINE_X[0] + 0.002, y, deck_z(SPINE_X[0], 0.0) - 0.02 + 0.075), (1, 0, 0),
                        (0, 0, 1), 'bridge_slits', 'vision slit 0.05 x 0.02', 'slit', 'picture', 'command deck window, ember-lit, in the spine block\'s face', aperture=0.5)
    K.mark('spine', 'spine', ['block', 'step', 'slit'])
    # three radiator spires (designs.md: stations 68, 76, 84 percent; R331: about 70 percent of the table's 0.9, so the tallest 0.65),
    # the middle one tallest, each its own profile, the ember in lit fin slats with iron between them (glow='slats', as S8's R331
    # rebuild, issue 1158: the fins stand at least 0.26 apart at flagship size, so the iron core shows between every pair)
    SC = 0.42
    SPIRES = [(-1.17, 0.47, 0.22, 3), (-1.69, 0.65, 0.24, 1), (-2.21, 0.52, 0.22, 0)]
    for i, (x, h, L, prof) in enumerate(SPIRES):
        part = HP.radiator(h, L, profile=prof, spread=SC * (0.2 + 0.42 * (h / SC) / 2.6), seed=i, scale=SC, glow='slats')
        K.organ('R%d' % (i + 1), part, (x, 0.0, SPZ), (0, 0, 1), fwd=(1, 0, 0), inv='spires', what='radiator spire, %.2f tall, profile %s' % (h, ('blade', 'stepped', 'twin', 'raked')[prof]),
                kind='radiator', note='sheds the reactor\'s heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair')
        K.mass('Radiator spire R%d (%s, %.2f tall)' % (i + 1, ('blade', 'stepped', 'twin', 'raked')[prof], h), bpy.data.objects['R%d_body_embar' % (i + 1)], 'ember fin slats on iron',
               note='one of the three spires of the spire line')

    # ---------------- the stern: two ember bells on riveted drums ----------------
    # the kit's engine has flagship rivet and band sizes (they read as gear teeth on a 0.55 bell), so each engine is built at
    # 1 / ES and shrunk by ES, then placed as K.engine places one (its exhaust cone for the fit check, its feature row)
    ES = 0.45
    for side in (1, -1):
        fid = 'E%d' % (1 if side > 0 else 2)
        p = Vector((-3.2376, side * 0.4, -0.05))
        part = HP.engine_bell(0.275 / ES, 0.62 / ES, bell_len=0.275 * 1.1 / ES, body_r=0.25 / ES, rings=3, nose='dome')
        part.transform(Matrix.Scale(ES, 4))
        for k_ in ('radius', 'body_r'):   # Part.transform moves points and turns directions; sizes are scaled here
            part.fit[k_] = part.fit[k_] * ES
        part = K.emit(fid, part, HP.frame(p, (1, 0, 0), (0, 0, 1)), 'engines')
        rad = part.fit['radius']
        K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=tuple(p), dir=(-1, 0, 0), r0=rad, half=12.0, length=max(2.5 * 2 * rad, 0.22 * K.length))]))
        K.features.append(dict(id=fid, kind='engine', what=(getattr(HP, 'ENGINE_WHAT', 'engine, bell %.1f across') % (2 * rad)), count=1, pos=tuple(p), aim=(180.0, 0.0),
                               src='picture', note='%s main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug' % ('port' if side > 0 else 'starboard'),
                               exit=tuple(p), radius=rad, inv=['engines']))

    # ---------------- the belly: an armour step ----------------
    belly = []
    for x, k in ((1.9, 0.0), (1.7, 1.0), (1.2, 1.0), (0.4, 1.0), (-0.4, 1.0), (-1.2, 1.0), (-2.0, 1.0), (-2.2, 0.0)):
        _, hw, zt, zb, kt, kb, dwf = st_at(x)
        bw = hw * BWF - 0.07
        belly.append([(x, bw, zb + 0.006), (x, bw - 0.035 * k, zb - 0.035 * k), (x, -bw + 0.035 * k, zb - 0.035 * k), (x, -bw, zb + 0.006)])
    K.mass('Belly armour step', K.loft_rings('S9_belly', belly, 'siron2'), 'darker iron', note='a second forged layer under the magazines and the reactor')
    plate_jobs.append(('belly', belly, dict(PL, faces=[1], mats={'siron2': 2, 'siron': 2}, seed=41, inv='belly_plates', closed=False)))

    # ---------------- the dorsal power trunk: from the reactor forward along the centreline to the casemate ----------------
    tr = []
    for x in (1.95, 1.9, 1.0, 0.0, -0.15, -0.2):
        z0 = deck_z(x, 0.0) - 0.008; k = 0.0 if x in (1.95, -0.2) else 1.0
        tr.append([(x, 0.05, z0), (x, 0.05, z0 + 0.016 + 0.014 * k), (x, 0.033, z0 + 0.026 + 0.02 * k), (x, -0.033, z0 + 0.026 + 0.02 * k), (x, -0.05, z0 + 0.016 + 0.014 * k), (x, -0.05, z0)])
    K.mass('Dorsal power trunk', K.loft_rings('S9_trunk', tr, 'siron2'), 'darker iron', note='armoured conduits from the reactor to the repeater (the concept\'s long centre rail)')
    for i in range(8):
        x = 1.75 - i * 0.28
        n0 = len(K.keepouts)
        K.rib('S9_trunkband_%d' % i, [(x, 0.053, deck_z(x, 0) - 0.004), (x, 0.0, deck_z(x, 0) + 0.046), (x, -0.053, deck_z(x, 0) - 0.004)], w=0.018, t=0.012, m='sworn')
        # the kit's rib keeps plates 0.45 clear, a capital hull's size: on this frigate that cleared the whole deck round the
        # trunk, so the band's own keep-outs shrink to about its width (kept in the sheet so the shared kit.py is unchanged)
        K.keepouts[n0:] = [(c, 0.03) for c, _ in K.keepouts[n0:]]
    K.mark('trunk', 'spine', ['block', 'step', 'slit'])

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p, n = facet_pt(1.75, side, 0.55)
        K.thruster('Q1' + sn, tuple(p), tuple(n), r=0.075, inv='thrusters', note='bow attitude thruster on the upper facet')
        p, n = facet_pt(-2.2, side, 0.6)
        K.thruster('Q2' + sn, tuple(p), tuple(n), r=0.075, inv='thrusters', note='stern attitude thruster on the upper facet')
        for i, x in enumerate((-1.35, -1.8)):
            p, n = facet_pt(x, side, 0.5)
            K._surface_part('V%d%s' % (i + 1, sn), HP.vent(0.24, 0.1, 4, depth=0.03, fr=0.016), tuple(p), tuple(n), (0, 0, 1), 'vents',
                            'louvre panel 0.24 x 0.10', 'vent', 'designed', 'reactor heat louvre over the reactor room', aperture=0.4)
        for i, x in enumerate((2.3, 1.3)):
            p, n = lower_pt(x, side, 0.15)
            K._surface_part('L%d%s' % (i + 1, sn), HP.lamp(0.026), tuple(p + n * 0.003), tuple(n), (0, 0, 1), 'lamps', 'running light', 'lamp', 'designed',
                            'frost-white running point on the knuckle line', aperture=0.35)
        for i, x in enumerate((0.05, -1.05, -2.25)):
            p, n = facet_pt(x, side, 0.08)
            K._surface_part('L%d%s' % (i + 3, sn), HP.lamp(0.026), tuple(p + n * 0.003), tuple(n), (0, 0, 1), 'lamps', 'running light', 'lamp', 'designed',
                            'frost-white running point on the deck edge', aperture=0.35)
    def small_hatch(w):
        # the kit's hatch has flagship rim heights: built at w / 0.4 and shrunk to frigate size, so it keeps its proportions
        return HP.hatch(w / 0.4, w / 0.4).transform(Matrix.Scale(0.4, 4))
    for i, (x, y) in enumerate(((1.25, 0.16), (1.25, -0.16))):
        K._surface_part('H%d' % (i + 1), small_hatch(0.1), (x, y, deck_z(x, y) + 0.016), (0, 0, 1), (1, 0, 0), 'hatches', 'round hatch 0.1', 'hatch', 'designed',
                        'deck hatch over the crew deck', aperture=0.6)
    for i, (x, y) in enumerate(((0.5, 0.15), (0.5, -0.15))):
        K._surface_part('H%d' % (i + 3), small_hatch(0.11), (x, y, st_at(x)[3] - 0.035 - 0.006), (0, 0, -1), (1, 0, 0), 'hatches', 'round hatch 0.11', 'hatch', 'designed',
                        'belly hatch on the armour step', aperture=0.6)

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white markings (paint stage)', 3.25, -3.25, 'whole hull')
    K.colour('ember glow (spire slats, engine throats, window slits, the repeater\'s lenses)', 2.6, -3.25, 'the spires, the bells, the slits')
    K.colour('frost-white running points', 2.3, -2.4, 'the knuckle forward, the deck edges aft')
    K.colour('no rust anywhere, no blue light', 3.25, -3.25, 'factions.md Never')

    # ---------------- INSIDE: iron decks, frames, the repeater's magazine, the crew deck, the reactor, the engine room ----------------
    IN = SHELL + 0.015

    def deck_slab(name, z, x0, x1, inset=0.008, n=6):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = hw_at(x, z, IN) - inset
            rs.append([(x, hw, z - 0.012), (x, hw, z + 0.012), (x, -hw, z + 0.012), (x, -hw, z - 0.012)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name={'main_aft': 'main', 'lower_aft': 'lower', 'main_bow': 'main'}.get(name, name), z=z, x=(x1, x0)))

    def frame_at(name, x, zr=None, record=True):
        """a frame ring inside the skin at station x; zr: the heights it keeps (a list of (lo, hi)), so a frame never straddles a
        peel plane (ships.md 2c: a peel through frames leaves their halves outside the torn hull)"""
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.035)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        n = len(fo); pts = []
        for k in range(n):
            a_, b_ = k, (k + 1) % n
            for j in range(6):
                t0 = j / 6
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
            V += [(x + 0.018, y_, z_) for (y_, z_) in q] + [(x - 0.018, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        if not V:
            return   # nothing of this frame lies in the kept bands (the bow below the peel)
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        if record:
            K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.012
        if ymax is not None:
            w = min(w, ymax)
        K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)

    def side_room(name, kind, x0, x1, z0, z1, y_in, note=''):
        for side in (1, -1):
            w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.012
            ya, yb = (y_in, w) if side > 0 else (-w, -y_in)
            K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    # Between B-1 and B-4 the lower hull peels away along the band (B-2, z -0.12): the decks and rooms keep clear of -0.17 to -0.07.
    # Forward of B-4 the spearhead snaps off whole, so its frames are full rings; no deck, room or frame crosses B-4 (x 1.64).
    deck_slab('main_bow', 0.0, 2.45, 1.74); deck_slab('main', 0.0, 1.54, -0.3); deck_slab('lower', -0.2, 1.54, -0.3)
    deck_slab('main_aft', 0.0, -1.0, -2.85); deck_slab('lower_aft', -0.22, -0.95, -2.85)
    for i, x in enumerate((2.6, 2.2, 1.48, 1.2, 0.7, 0.2, -0.25, -1.0, -1.45, -1.95, -2.45, -2.85)):
        if -0.4 < x < 1.64:   # between B-1 and B-4 the lower hull peels away (B-2): the frame keeps clear of the peel band
            frame_at('F%d_upper' % i, x, zr=[(-0.065, 99.0)]); frame_at('F%d_lower' % i, x, zr=[(-99.0, -0.175)], record=False)
        else:
            frame_at('F%d' % i, x)
    room('repeater_magazine', 'magazine', 2.4, 2.0, 0.025, 0.075, note='the Sear repeater\'s magazine and feed, under the casemate')
    room('bow_stores', 'hold', 2.0, 1.75, -0.25, -0.18, note='bow stores and the bow thrusters\' feeds')
    room('crew_deck', 'crew', 1.54, 0.55, 0.025, 0.16, note='the crew deck: berths and the mess, the chalk wall where the names go up before launch')
    room('fire_plot', 'bridge', 0.45, -0.25, 0.025, 0.2, ymax=0.26, note='the plotting room (no AI: plotted by hand)')
    side_room('flak_magazine', 'magazine', 0.1, -0.3, 0.025, 0.2, 0.3, note='the spark flak magazines, under the tubs')
    room('ballast_fwd', 'machinery', 1.4, -0.3, -0.29, -0.19, note='trim tanks and pumps under the crew deck')
    room('command', 'bridge', -0.95, -1.05, 0.025, 0.2, ymax=0.3, note='the command deck under the spine block\'s slits')
    room('reactor', 'core', -1.1, -2.2, -0.33, 0.2, ymax=0.32, note='the reactor: its heat goes up through the spine block into the spires (hp_core)')
    side_room('coolant', 'machinery', -1.1, -2.2, -0.2, 0.2, 0.36, note='coolant pumps and heat exchangers either side of the reactor')
    room('engine_room', 'engroom', -2.3, -2.75, -0.27, 0.19, note='the engine room and the two drives\' feeds')
    K.armour('upper facets and deck', 0.06, 'forged plate over the crew deck and the magazines')
    K.armour('band and lips', 0.07, 'the plated band, the hull\'s belt')
    K.armour('spearhead', 0.08, 'solid forged layers toward the point')
    K.armour('belly and armour step', 0.06, '')
    K.armour('spine block', 0.05, 'it snaps off with the spires')
    # seams (factions.md "How it breaks": along the gun decks, the hull splits lengthwise between deck rows; the spire line snaps
    # off as one piece; R226: no machine on a seam; ships.md 2c: a peel is one level plane per compartment)
    K.break_line('B-1', -0.4, 'the bow and gun section tears from the reactor section: aft of the flak tubs at the flanks, ahead of the spine block on the centreline',
                 path=TRANS)
    K.break_line('B-2', 0.0, 'along the band: the lower hull peels away under the crew deck, the magazines and the stores',
                 path=[(1.55, -0.12), (1.0, -0.121), (0.4, -0.118), (-0.35, -0.12)], kind='long')
    K.break_line('B-4', 1.64, 'the spearhead snaps off whole at the casemate\'s back, so the peel along the band (B-2) stays aft of it, '
                 'where the band is tall enough for its torn edge', path=[(1.64, 9.0), (1.64, -9.0)])
    K.break_line('B-3', -1.6, 'the spire line snaps off as one piece, the spine block tearing along its root',
                 path=[(-0.45, SPZ - 0.09), (-1.2, SPZ - 0.092), (-2.0, SPZ - 0.09), (-2.58, SPZ - 0.091)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit crew spaces, frames, the repeater magazine, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).'))
    K.point('core', 'hp_core', (-1.65, 0, -0.08))
    # Two breach anchors (Frigate base 2, Sunward +0): the contract for two is one in the prow and one in the engine section
    # (hardpoints.sections_for), one each side. Each sits on the hull side at least 0.03 of the length from every part (check_export):
    # the prow one at the band's forward end between the L2 lamp and the Q1 thruster, the engine one low on the band aft of V1.
    for i, (x, side, z, sec) in enumerate(((1.52, 1, BAND_Z, 'prow'), (-1.55, -1, -0.06, 'eng'))):
        K.point('breach', 'hp_breach_%d' % i, (x, side * hw_at(x, z), z), side='port' if side > 0 else 'stbd', section=sec,
                note='on the hull side by the broadside band, clear of the louvres, lamps and thrusters')
    for i, side in enumerate((1, -1)):
        p, n = facet_pt(1.75, side, 0.55)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(p), side='port' if side > 0 else 'stbd')
        p, n = facet_pt(-2.2, side, 0.6)
        K.point('rcs', 'hp_rcs_%d' % (i + 2), tuple(p), side='port' if side > 0 else 'stbd')
        hw = st_at(-0.95)[1]
        K.point('board', 'hp_board_%d' % i, (-0.95, side * hw, BAND_Z), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):   # worked metal, as the sheet kit renders its own metal rows
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3
    # ---------- the forged plating, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), closed=spec.get('closed', True), rr=RR, unit=UNIT)
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('S9_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('S9_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='S9_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Three radiator spires, not the beauty\'s four, at 0.47, 0.65 and 0.52 over the spine block (tallest in the middle)',
             'designs.md\'s table (3 spires, tallest 0.9) outranks the picture; Ryan, Nov 19 2026 (R331): "can we scale down the giant radiator/orange towers on each ship a bit too?", so about 70 percent of the table\'s heights')
    K.change('The spires\' fins stand further apart, so the ember shows as lit slats with dark iron between them, not as a whole lit tower', 'R331: the ember shows in the slats, not as a whole lit tower (factions.md Sunward silhouette line)')
    K.change('One flak pair (two twin tubs at the deck edges, station 60 percent), not the beauty\'s four tubs', 'designs.md\'s table and data.js warden carry one flak slot (3 shots); four tubs would be silent or extra mounts (R241)')
    K.change('Round 3 (Ryan, Nov 20, on the in-game pictures: "fix ember glow and the boxy gun"): the casemate is about a quarter smaller (size 0.38, was 0.5) with a steeper glacis and narrower roof, and the three barrels reach further out of it',
             'the concept\'s bow gun is a compact sloped house with its barrels well out front; ours read as a big box on the spearhead. The spires\' heat core now glows under iron ribs (the shared radiator glow=\'slats\', so S8, Vigil and every Sunward build get it)')
    K.change('The bow gun is a fixed casemate (the Sear repeater: three barrels round a spindle in a forged housing with a sloped glacis), not a turning turret with a cupola',
             'data.js autocannon is arc F; a fixed forward mount matches the game, and the frigate turns to bring it to bear (R241); the concept\'s cupola read as a second gun, so the sight is a slit in the glacis')
    K.change('The broadside band is plated and louvred, with no ports and no lit gallery slits', 'designs.md: no broadside slot in data, so no ports (R241: no decorative guns)')
    K.change('The command deck looks out through three ember slits in the spine block\'s forward face at station 61 percent (the table\'s 58)',
             'the spine block (and with it the spire line) must sit wholly aft of B-1, which runs ahead of it on the centreline and behind the flak tubs at the flanks')
    K.change('Two ember bells 0.55 across at plus and minus 0.4 on riveted drums, the stern widened to 1.2 to carry them', 'designs.md\'s table; the stern face must hold both drums (factions.md: two to four bells, deep-set)')
    K.change('The beam is 1.36 at the knuckle (1.47 over the band lips), not the table\'s 1.5', 'the concept\'s own top view measures about 1.2 over the hull; the lips and louvres bring the envelope near the table, the hull stays a narrow knife')
    K.change('Attitude thrusters, deck and belly hatches, heat louvres, frost running points, a belly armour step added', 'a ship in space needs thrusters and access; the reactor needs louvres; the concept shows no underside; every part has a job (R221)')
    K.change('A second transverse break, B-4 at x 1.64: the spearhead snaps off whole, and the band peel (B-2) runs only between B-1 and B-4', 'the death seam check (stage 7 run, Nov 19): the peel plane tilts and waves across the beam, and in the shallow bow its torn edge reached the knuckle, leaving 154 inside triangles (the hull liner and the bow stores) outside their piece; the bow piece has no peel, so 0 remain')
    K.change('The concept\'s long centre rail is the dorsal power trunk, banded, from the casemate back to the spine block', 'the rail needs a job (R221): it feeds the repeater from the reactor')
    # ---------- the fit report's fix column: every finding the check made while this sheet was designed (issue 1156) ----------
    K.fix('Deck hatches H1 and H2: the seam ring inside the crowned deck', 'hatches lifted 0.016 onto the crown')
    K.fix('Engine drums E1 and E2 against the stern thrusters Q2 and the aft running lights L5', 'the stern thrusters moved forward to 2.2 aft, the aft lights to 2.25 aft, the reactor louvres to 1.35 and 1.8 aft')
    K.fix('Command slit W2 covered by the dorsal trunk', 'the slits raised in the spine block\'s face and the trunk ended 0.25 short of the face')
    K.open_item('The belly is designed here; the concept shows no underside')
    K.open_item('Frost-white markings and the half-sun crest are paint (the Sunward stack, stage 5), not modelled')


INV_NOTES = {}
