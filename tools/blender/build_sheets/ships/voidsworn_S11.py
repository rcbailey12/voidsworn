# voidsworn_S11: the Harrow-class destroyer, the Sunward Crusade's torpedo bow (data.js harrow, class Destroyer, 9.5 world
# units). Issue 1414. Shape of record: the round 2 concept contrib/muse/design/class_family_sunward_2026_11/ (harrow_sheet.webp,
# harrow_beauty.webp on PR 1163; designs.md "Harrow" governs where a picture differs; Ryan took round 2 Nov 20 2026 21:43 UTC,
# R369, built with 4 small spires at 0.85).
# data.js harrow: torp F (1 shot), turret T (2 shots); ability reload; no hangar, no broadside. Variant vs_harrow_t: torp F, torp F
# ("Twin prow torpedo tubes and no turret"): the same model, the twin tubes are drawn either way.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): the concept is a base, not a trace.
# Family pattern: the S9 Warden sheet (voidsworn_S9.py): the same blade section, the same kit, the same spire language, scaled to
# a destroyer with its own counts (designs.md "Never copy from S8 literally").
# Measured off the Harrow sheet's true views (top view above, side view below, bow on the LEFT in both; 1669 px = 9.5 units to the
# bell exits): a long leaf-shaped taper from the point, the twin tube cowls on the deck at about 22 percent, the widest hull (2.1) over the
# magazine section at 40 to 50 percent, then about 1.7 over the stern third; the hull about 0.7 deep.
# +X bow, +Y port, +Z up. Bow tip x = +4.75, engine exits x = -4.75. The broadside band's middle z = 0.0.
import math

CODE = 'voidsworn_S11'
NAME = 'Harrow-class destroyer (Sunward Crusade)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js harrow (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)"
BEAUTY = 'docs/ship_pipeline/build_sheets/voidsworn_S11/concept_beauty.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/voidsworn_S11/concept_sheet.jpg'
# the true views on the Harrow sheet (x0, y0, x1, y1), bow on the LEFT in both (the build's side view is bow left too)
CONCEPT_VIEWS = dict(top=dict(box=(80, 88, 1765, 474), largest=True, flip=False), side=dict(box=(60, 550, 1765, 818), largest=True, flip=False))
CROPS = [('bow (the spearhead and the twin torpedo tubes)', (40, 300, 900, 900)), ('midships (the magazine section and the turret pair)', (500, 150, 1300, 900)),
         ('stern (the spire line and the bells)', (1000, 150, 1920, 900))]
SHEET = dict(version=1, round='first sheet', date='2026-11-20', blend='opus1414',
             blend_where='rendered in the issue 1414 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py voidsworn_S11 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Sunward kit and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

# ---------------------------------------------------------------------------------------------------- the hull section
# S9's blade section at destroyer size (port half; the starboard half mirrors it): a crowned deck, a deck-edge chamfer, a big
# upper facet out and down to the knuckle, the vertical broadside band (plated and louvred, no ports: no broadside slot), a lower
# facet, a chine chamfer, a flat worked belly. The bow tapers in one long leaf curve to a forged point (diamond in section, its tip at mid
# height); the two torpedo tubes sit in raised armoured cowls on the deck either side of the centreline, looking forward.
# (x, hw: half-beam at the knuckle, zt: deck, zb: belly, kt, kb: the band's top and bottom, dw: deck half-width share)
ST = [
    (4.75, 0.014, 0.006, -0.05, -0.012, -0.03, 0.4),
    (4.3, 0.2, 0.07, -0.12, 0.02, -0.05, 0.42),
    (3.8, 0.37, 0.13, -0.2, 0.05, -0.07, 0.44),
    (3.2, 0.55, 0.19, -0.28, 0.08, -0.09, 0.45),
    (2.6, 0.72, 0.25, -0.35, 0.11, -0.11, 0.46),
    (2.0, 0.87, 0.3, -0.42, 0.13, -0.125, 0.5),
    (1.3, 0.98, 0.34, -0.46, 0.15, -0.14, 0.55),
    (0.4, 1.05, 0.36, -0.48, 0.15, -0.14, 0.58),
    (-0.4, 1.0, 0.36, -0.48, 0.15, -0.14, 0.58),
    (-1.2, 0.9, 0.36, -0.47, 0.15, -0.14, 0.58),
    (-2.0, 0.86, 0.355, -0.46, 0.145, -0.135, 0.58),
    (-3.2, 0.87, 0.35, -0.45, 0.14, -0.13, 0.58),
    (-4.0, 0.89, 0.34, -0.43, 0.135, -0.13, 0.58),
    (-4.25, 0.87, 0.32, -0.4, 0.125, -0.12, 0.56),
]
HULL = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
CROWN = 0.045      # the deck's crown at the centreline
BWF = 0.58         # the belly's half-width share of hw
SHELL = 0.08       # hull thickness (the solidify shell)
BAND_Z = 0.005     # the broadside band's middle
PL = dict(size=(0.24, 0.42), thick=(0.012, 0.024))
UNIT = 0.55        # the kit plating's fixed sizes (smallest face, gaps, sink), scaled for a destroyer (forged_plates unit)
RR = 0.015         # rivet head size on this hull's plates
TUBE_X = 2.62      # the torpedo tubes' mouths, at the front of their deck cowls (station 22 percent, as the round 2 top view)
TUBE_Y = 0.36      # the tubes' offset from the centreline (the round 2 top view: about 0.37)
TUBE_R = 0.15
TUBE_Z = 0.47      # the bores' centre height: the cowls stand on the deck, the bores clear of the falling bow ahead
TURRET_X = 0.38    # the sear turret pair, station 46 percent
TY = 0.62          # the turret tubs' offset: the deck edges
SPINE_X = (-1.05, -3.95)   # the spine block: its forward face (the command slits) to its aft end
B1_X = -0.75       # the transverse break between the gun section and the reactor section
TRANS = [(B1_X, 9.0), (B1_X, 0.4), (B1_X + 0.4, 0.35), (B1_X + 0.4, -0.35), (B1_X, -0.4), (B1_X, -9.0)]   # B-1's plan path


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
    c = min(0.05, hw * 0.06); c2 = min(0.045, hw * 0.05)
    kt_ = min(kt, zt - 2 * c - 0.003); kb_ = max(kb, zb + 2 * c2 + 0.003)
    return [(0.0, zt + CROWN * min(1.0, hw / 1.0)), (dw, zt), (dw + c, zt - c), (hw, kt_), (hw, kb_), (bw + c2, zb + c2), (bw, zb), (0.0, zb)]


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
    return zt + CROWN * min(1.0, hw / 1.0) * max(0.0, 1 - abs(y) / dw)


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


def torpedo_tubes(K, inv='tubes'):
    """the twin Cinder torpedo tubes in raised cowls on the deck, built as ONE launcher (data.js torp F, 1 shot: the salvo leaves
    either bore in turn, so the one mount fires every volley); registered with its firing lanes as K.launcher does"""
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    p = Vector((TUBE_X, 0.0, TUBE_Z))
    part = HP.torpedo_pair(TUBE_R, 0.95, 2 * TUBE_Y, s=0.6, cowl=True)
    part = K.emit('T1', part, HP.frame(p, (1, 0, 0), (0, 0, 1)), inv)
    for ob in K.coll.objects:
        if ob.get('grp') == 'T1' and ob.get('role') != 'mount':
            ob['gun_fixed'] = 1
            ob['turret'] = 0
    ex = [dict(pos=tuple(e['pos'][1]), axis=tuple(e['axis'][1]), r=e['radius']) for e in part.fit['exits']]
    dv = Vector((1, 0, 0)); uv = Vector((0, 1, 0)); wv = Vector((0, 0, 1))
    lanes = [dict(apex=e['pos'], dir=tuple(dv), u=tuple(uv), w=tuple(wv), hu=e['r'] + 0.04, hw=e['r'] + 0.04, half=3.0, length=K.length * 0.8, what='firing lane') for e in ex]
    K.fitdata.append(dict(id='T1', kind='launcher', slot='F', lanes=lanes,
                          apertures=[dict(pos=e['pos'], dir=e['axis'], r=e['r'], length=K.length * 0.8, cone=4.0, what='launch tube') for e in ex]))
    K.features.append(dict(id='T1', kind='launcher', what='twin Cinder torpedo tubes in deck cowls (one launcher, fixed forward)', count=2,
                           pos=tuple(p), aim=(0.0, 0.0), slot='F', weapon='torp', src='picture',
                           note='the destroyer\'s salvo (torp F, 1 shot: it leaves either tube in turn); the ship turns to aim it',
                           muzzle=[e['pos'] for e in ex], normal=(1, 0, 0), fixed=True, inv=[inv]))


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit (tools/blender/kits/voidsworn)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(r[0], r[1], r[1], r[3], r[2], 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    xs = sorted({r[0] for r in ST} | {x / 8 for x in range(-35, 38)}, reverse=True)
    xs = [x for x in xs if x >= -4.25]
    hull = K.loft_rings(CODE + '_hull', [ring(x) for x in xs], 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the blade', hull, 'black iron plate',
           note='a faceted blade: crowned deck, big upper facets, the plated band, lower facets, a flat worked belly; the bow one long leaf taper, widest (2.1) over the magazine section')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    # the plating rings: one every 0.3 (a plate course), so the plates run at the hull's own plate size
    px_f = [x for x in sorted({r[0] for r in ST if 3.0 <= r[0] < 4.6} | {3.0 + 0.3 * i for i in range(6)}, reverse=True)]
    px_a = [x for x in sorted({r[0] for r in ST if r[0] <= 3.0} | {3.0 - 0.3 * i for i in range(25) if 3.0 - 0.3 * i > -4.25}, reverse=True)]
    rf = [ring(x) for x in px_f]; ra = [ring(x) for x in px_a]
    plate_jobs = []
    for tag, rs, seed0 in (('bow', rf, 10), ('aft', ra, 20)):
        plate_jobs += [('%s_deck' % tag, rs, dict(PL, faces=[0, 13], mats={'siron': 3, 'siron2': 2}, seed=seed0 + 1, inv='deck_plates')),
                       ('%s_facet' % tag, rs, dict(PL, faces=[2, 11], tri=(tag == 'bow'), mats={'siron': 4, 'siron2': 2}, seed=seed0 + 2, inv='flank_plates')),
                       ('%s_band' % tag, rs, dict(PL, faces=[3, 10], mats={'siron2': 3, 'siron': 2}, seed=seed0 + 3, inv='flank_plates', size=(0.16, 0.36))),
                       ('%s_lower' % tag, rs, dict(PL, faces=[4, 9], mats={'siron': 3, 'siron2': 2}, seed=seed0 + 4, inv='flank_plates')),
                       ('%s_belly' % tag, rs, dict(PL, faces=[6, 7], mats={'siron2': 3, 'siron': 2}, seed=seed0 + 5, inv='belly_plates'))]

    # ---------------- the bow: a forged point with a raised centre ridge ----------------
    ridge = []
    for x in (4.5, 4.2, 3.8, 3.4, 3.0, 2.76):
        f = min(1.0, (4.5 - x) / 1.4)
        w = 0.03 + 0.06 * f; hgt = 0.02 + 0.03 * f; z = deck_z(x, 0.0) - 0.008
        ridge.append([(x, w, z), (x, w * 0.55, z + hgt), (x, -w * 0.55, z + hgt), (x, -w, z)])
    K.mass('Bow ridge', K.loft_rings('S11_bow_ridge', ridge, 'siron2'), 'darker iron',
           note='the spearhead\'s raised centre ridge (a forged fuller) from the point back to the power trunk\'s head')
    K.mark('spearhead', 'hull', ['facet', 'step', 'chamfer'])

    # ---------------- the twin torpedo tubes in their deck cowls ----------------
    torpedo_tubes(K)
    K.mark('tube_cowls', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the magazine section: ember heat-vent slits on the upper facets (the reload read) ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for i, x in enumerate((1.25,)):
            p, n = facet_pt(x, side, 0.4)
            K._surface_part('M%d%s' % (i + 1, sn), HP.vent(0.7, 0.3, 4, depth=0.04, fr=0.022), tuple(p + n * 0.03), tuple(n), (0, 0, 1), 'magazine_vents',
                            'heat-vent slit panel 0.7 x 0.3, four long lit slits', 'vent', 'picture', 'the torpedo magazine sheds its reload heat here (designs.md: ember heat-vent slits)', aperture=0.4)

    # ---------------- the broadside band: plated and louvred (no ports: the Harrow has no broadside slot) ----------------
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        for lip, zz in (('upper', 0), ('lower', 1)):
            rs = []
            xl = [2.8, 2.66] + [2.66 - (2.66 + 3.7) * i / 10 for i in range(1, 11)] + [-3.85]
            for i, x in enumerate(xl):
                _, hw, zt, zb, kt, kb, dwf = st_at(x)
                out = 0.0 if i in (0, len(xl) - 1) else 0.06
                if zz == 0:
                    pts = [(hw - 0.02, kt + 0.04), (hw + out, kt + 0.007), (hw + out, kt - 0.027), (hw - 0.02, kt - 0.027)]
                else:
                    pts = [(hw - 0.02, kb + 0.027), (hw + out, kb + 0.027), (hw + out, kb - 0.008), (hw - 0.02, kb - 0.04)]
                rs.append([(x, side * y, z) for (y, z) in (pts if side > 0 else pts[::-1])])
            ob = K.loft_rings('S11_lip_%s_%s' % (lip, nm[0]), rs, 'siron2')
            K.mass('Band %s lip, %s' % (lip, nm), ob, 'darker iron', note='the armoured shelf over (under) the plated band; its ends are angled')
        for i, x in enumerate((2.0, 1.1, -0.2, -1.6, -2.6)):
            p, n = band_pt(x, side)
            K._surface_part('U%d%s' % (i + 1, nm[0]), HP.vent(0.2, 0.08, 3, depth=0.03, fr=0.015), tuple(p + n * 0.056), tuple(n), (0, 0, 1), 'band_louvres',
                            'band louvre 0.2 x 0.08', 'vent', 'picture', 'a heat louvre in the plated band (the gallery spaces behind it breathe out here)', aperture=0.4)
    K.mark('gun_deck', 'belt', ['band', 'plate'])

    # ---------------- deck: the sear turret pair on low tubs at the deck edges ----------------
    def drum(name, x, y, r, z0, z1, n=10):
        rs = []
        for k, (zz, rr) in enumerate(((z0 - 0.05, r), (z1 - 0.02, r), (z1, r - 0.02))):
            rs.append([(x + rr * math.cos(2 * math.pi * i / n + math.pi / n), y + rr * math.sin(2 * math.pi * i / n + math.pi / n), zz) for i in range(n)])
        V = [v for r_ in rs for v in r_]
        F = []
        for j in range(len(rs) - 1):
            for i in range(n):
                a, b = j * n + i, j * n + (i + 1) % n
                F.append((a, b, b + n, a + n))
        F.append(tuple(range(n))[::-1]); o = (len(rs) - 1) * n; F.append(tuple(range(o, o + n)))
        ob = K._obj(name, V, F, 'siron2', grp='hull')
        K.keepouts.append((Vector((x, y, z1)), r + 0.04))
        return ob
    zT = {}
    for side in (1, -1):
        sn = 'port' if side > 0 else 'starboard'
        z0 = deck_z(TURRET_X, side * TY); zT[side] = z0 + 0.045
        K.mass('Turret tub, %s' % sn, drum('S11_ttub_%s' % sn[0], TURRET_X, side * TY, 0.22, z0 - 0.2, zT[side]), 'darker iron',
               note='an octagonal forged tub at the deck edge, its skirt running down onto the upper facet')
    K.mark('barbettes', 'tier', ['face', 'roof', 'opening'])
    for side in (1, -1):
        K.gun('G%d' % (1 if side > 0 else 2), (TURRET_X, side * TY, zT[side]), 35 * side, 4, barrels=1, cal=0.04, blen=0.3, size=0.4, slot='T', weapon='turret',
              inv='turrets', note='%s sear turret; the pair is the one turret slot (2 shots: one a mount, both fire every volley)' % ('port' if side > 0 else 'starboard'))

    # ---------------- the spine block and the spire line ----------------
    sp = []
    for x in (SPINE_X[0], SPINE_X[0] - 0.1, -1.6, -2.4, -3.2, SPINE_X[1] + 0.1, SPINE_X[1]):
        z0 = deck_z(x, 0.0) - 0.03
        k = 0.0 if x in SPINE_X else 1.0
        hwb = 0.24 * (0.85 + 0.15 * k)
        sp.append([(x, hwb, z0), (x, hwb, z0 + 0.08 + 0.07 * k), (x, hwb - 0.04, z0 + 0.14 + 0.07 * k), (x, -hwb + 0.04, z0 + 0.14 + 0.07 * k),
                   (x, -hwb, z0 + 0.08 + 0.07 * k), (x, -hwb, z0)])
    spine = K.loft_rings('S11_spine', sp, 'siron2')
    SPZ = deck_z(-2.4, 0.0) - 0.03 + 0.21   # the spine block's top: the spire roots stand on it
    K.mass('Spine block (the spire line\'s base)', spine, 'darker iron',
           note='a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-3)')
    plate_jobs.append(('spine', sp, dict(PL, faces=[0, 2, 4], mats={'siron': 2, 'siron2': 2}, seed=31, inv='spine_plates', size=(0.12, 0.3))))
    for i, y in enumerate((-0.1, 0.0, 0.1)):
        K._surface_part('W%d' % (i + 1), HP.slit(0.065, 0.028, depth=0.03, fr=0.014), (SPINE_X[0] + 0.002, y, deck_z(SPINE_X[0], 0.0) - 0.03 + 0.1), (1, 0, 0),
                        (0, 0, 1), 'bridge_slits', 'vision slit 0.065 x 0.028', 'slit', 'picture', 'command deck window, ember-lit, in the spine block\'s face', aperture=0.5)
    K.mark('spine', 'spine', ['block', 'step', 'slit'])
    # four radiator spires (designs.md: stations 66, 73, 80, 87 percent; the final table: tallest 0.85, R331 and the Board's Nov 19
    # correction), tallest second from the front, each its own profile, the ember in lit fin slats with iron between them (glow='slats')
    SC = 0.55
    SPIRES = [(-1.52, 0.66, 0.3, 3), (-2.19, 0.85, 0.32, 1), (-2.85, 0.76, 0.3, 0), (-3.52, 0.58, 0.28, 2)]
    for i, (x, h, L, prof) in enumerate(SPIRES):
        part = HP.radiator(h, L, profile=prof, spread=SC * (0.2 + 0.42 * (h / SC) / 2.6), seed=i, scale=SC, glow='slats')
        K.organ('R%d' % (i + 1), part, (x, 0.0, SPZ), (0, 0, 1), fwd=(1, 0, 0), inv='spires', what='radiator spire, %.2f tall, profile %s' % (h, ('blade', 'stepped', 'twin', 'raked')[prof]),
                kind='radiator', note='sheds the reactor\'s heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair')
        K.mass('Radiator spire R%d (%s, %.2f tall)' % (i + 1, ('blade', 'stepped', 'twin', 'raked')[prof], h), bpy.data.objects['R%d_body_embar' % (i + 1)], 'ember fin slats on iron',
               note='one of the four spires of the spire line')

    # ---------------- the stern: two ember bells on riveted drums ----------------
    ES = 0.62
    for side in (1, -1):
        fid = 'E%d' % (1 if side > 0 else 2)
        p = Vector((-4.72, side * 0.55, -0.05))
        part = HP.engine_bell(0.4 / ES, 0.55 / ES, bell_len=0.4 * 1.1 / ES, body_r=0.36 / ES, rings=3, nose='dome')
        part.transform(Matrix.Scale(ES, 4))
        for k_ in ('radius', 'body_r'):
            part.fit[k_] = part.fit[k_] * ES
        part = K.emit(fid, part, HP.frame(p, (1, 0, 0), (0, 0, 1)), 'engines')
        rad = part.fit['radius']
        K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=tuple(p), dir=(-1, 0, 0), r0=rad, half=12.0, length=max(2.5 * 2 * rad, 0.22 * K.length))]))
        K.features.append(dict(id=fid, kind='engine', what=(getattr(HP, 'ENGINE_WHAT', 'engine, bell %.1f across') % (2 * rad)), count=1, pos=tuple(p), aim=(180.0, 0.0),
                               src='picture', note='%s main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug' % ('port' if side > 0 else 'starboard'),
                               exit=tuple(p), radius=rad, inv=['engines']))

    # ---------------- the belly: an armour step ----------------
    belly = []
    for x, k in ((2.7, 0.0), (2.5, 1.0), (1.6, 1.0), (0.6, 1.0), (-0.6, 1.0), (-1.8, 1.0), (-3.0, 1.0), (-3.4, 0.0)):
        _, hw, zt, zb, kt, kb, dwf = st_at(x)
        bw = hw * BWF - 0.1
        belly.append([(x, bw, zb + 0.008), (x, bw - 0.05 * k, zb - 0.05 * k), (x, -bw + 0.05 * k, zb - 0.05 * k), (x, -bw, zb + 0.008)])
    K.mass('Belly armour step', K.loft_rings('S11_belly', belly, 'siron2'), 'darker iron', note='a second forged layer under the magazine and the reactor')
    plate_jobs.append(('belly', belly, dict(PL, faces=[1], mats={'siron2': 2, 'siron': 2}, seed=41, inv='belly_plates', closed=False)))

    # ---------------- the dorsal power trunk: the reactor's feed forward along the centreline to the turret deck ----------------
    tr = []
    for x in (2.75, 2.68, 1.8, 0.8, -0.85, -0.95):
        z0 = deck_z(x, 0.0) - 0.01; k = 0.0 if x in (2.75, -0.95) else 1.0
        tr.append([(x, 0.07, z0), (x, 0.07, z0 + 0.022 + 0.02 * k), (x, 0.046, z0 + 0.036 + 0.028 * k), (x, -0.046, z0 + 0.036 + 0.028 * k), (x, -0.07, z0 + 0.022 + 0.02 * k), (x, -0.07, z0)])
    K.mass('Dorsal power trunk', K.loft_rings('S11_trunk', tr, 'siron2'), 'darker iron', note='armoured conduits from the reactor forward over the magazine to the tube room (the concept\'s centre stripe)')
    for i in range(10):
        x = 2.5 - i * 0.36
        n0 = len(K.keepouts)
        K.rib('S11_trunkband_%d' % i, [(x, 0.074, deck_z(x, 0) - 0.005), (x, 0.0, deck_z(x, 0) + 0.066), (x, -0.074, deck_z(x, 0) - 0.005)], w=0.024, t=0.016, m='sworn')
        K.keepouts[n0:] = [(c, 0.04) for c, _ in K.keepouts[n0:]]
    K.mark('trunk', 'spine', ['block', 'step', 'slit'])

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p, n = lower_pt(2.2, side, 0.35)
        K.thruster('Q1' + sn, tuple(p), tuple(n), r=0.1, inv='thrusters', note='bow attitude thruster on the lower facet')
        p, n = facet_pt(-3.3, side, 0.75)
        K.thruster('Q2' + sn, tuple(p), tuple(n), r=0.1, inv='thrusters', note='stern attitude thruster on the upper facet')
        for i, x in enumerate((-1.9, -2.6)):
            p, n = facet_pt(x, side, 0.45)
            K._surface_part('V%d%s' % (i + 1, sn), HP.vent(0.32, 0.13, 4, depth=0.035, fr=0.02), tuple(p), tuple(n), (0, 0, 1), 'vents',
                            'louvre panel 0.32 x 0.13', 'vent', 'designed', 'reactor heat louvre over the reactor room', aperture=0.4)
        for i, x in enumerate((2.5, 1.5, 0.6)):
            p, n = lower_pt(x, side, 0.15)
            K._surface_part('L%d%s' % (i + 1, sn), HP.lamp(0.034), tuple(p + n * 0.004), tuple(n), (0, 0, 1), 'lamps', 'running light', 'lamp', 'designed',
                            'frost-white running point on the knuckle line', aperture=0.35)
        for i, x in enumerate((-0.4, -1.6, -3.1)):
            p, n = facet_pt(x, side, 0.08)
            K._surface_part('L%d%s' % (i + 4, sn), HP.lamp(0.034), tuple(p + n * 0.004), tuple(n), (0, 0, 1), 'lamps', 'running light', 'lamp', 'designed',
                            'frost-white running point on the deck edge', aperture=0.35)

    def small_hatch(w):
        return HP.hatch(w / 0.5, w / 0.5).transform(Matrix.Scale(0.5, 4))
    for i, (x, y) in enumerate(((0.95, 0.22), (0.95, -0.22), (-0.3, 0.22), (-0.3, -0.22))):
        K._surface_part('H%d' % (i + 1), small_hatch(0.13), (x, y, deck_z(x, y) + 0.02), (0, 0, 1), (1, 0, 0), 'hatches', 'round hatch 0.13', 'hatch', 'designed',
                        'deck hatch over the crew deck', aperture=0.6)
    for i, (x, y) in enumerate(((1.0, 0.22), (1.0, -0.22))):
        K._surface_part('H%d' % (i + 5), small_hatch(0.14), (x, y, st_at(x)[3] - 0.05 - 0.008), (0, 0, -1), (1, 0, 0), 'hatches', 'round hatch 0.14', 'hatch', 'designed',
                        'belly hatch on the armour step: torpedo stores come aboard here', aperture=0.6)

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white markings (paint stage)', 4.75, -4.75, 'whole hull')
    K.colour('ember glow (spire slats, engine throats, window slits, the turrets\' lenses, the torpedoes\' fuse bands)', 3.0, -4.75, 'the spires, the bells, the slits')
    K.colour('frost-white running points', 2.5, -3.1, 'the knuckle forward, the deck edges aft')
    K.colour('no rust anywhere, no blue light', 4.75, -4.75, 'factions.md Never')

    # ---------------- INSIDE: iron decks, frames, the tube room, the torpedo magazine, the crew deck, the reactor, the engine room ----------------
    IN = SHELL + 0.02

    def deck_slab(name, z, x0, x1, inset=0.01, n=6):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = hw_at(x, z, IN) - inset
            rs.append([(x, hw, z - 0.016), (x, hw, z + 0.016), (x, -hw, z + 0.016), (x, -hw, z - 0.016)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name={'main_aft': 'main', 'lower_aft': 'lower', 'main_bow': 'main'}.get(name, name), z=z, x=(x1, x0)))

    def frame_at(name, x, zr=None, record=True):
        """a frame ring inside the skin at station x; zr: the heights it keeps (a list of (lo, hi)), so a frame never straddles a
        peel plane (ships.md 2c)"""
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.045)
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
            V += [(x + 0.024, y_, z_) for (y_, z_) in q] + [(x - 0.024, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        if not V:
            return
        K._obj('in_bh_' + name, V, F, 'frame', inside=True)
        if record:
            K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, y0=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.015
        if ymax is not None:
            w = min(w, ymax)
        if y0 is None:
            K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)
        else:
            for side in (1, -1):
                ya, yb = (y0, w) if side > 0 else (-w, -y0)
                K.room('%s_%s' % (name, 'p' if side > 0 else 's'), kind, min(x0, x1), max(x0, x1), ya, yb, z0, z1, note=note)
    # Between B-1 and B-4 the lower hull peels away along the band (B-2, z -0.15): the decks and rooms keep clear of -0.21 to -0.09.
    # Forward of B-4 the spearhead snaps off whole, so its frames are full rings; no deck, room or frame crosses B-4 (x 3.15).
    deck_slab('main_bow', 0.0, 4.0, 3.25)
    deck_slab('main', 0.0, 2.85, -0.6); deck_slab('lower', -0.27, 2.75, -0.6)
    deck_slab('main_aft', 0.0, -0.9, -4.1); deck_slab('lower_aft', -0.27, -0.9, -4.1)
    for i, x in enumerate((4.0, 3.5, 2.8, 2.3, 1.7, 1.1, 0.5, -0.1, -0.6, -1.0, -1.7, -2.4, -3.1, -3.7, -4.12)):
        if B1_X + 0.1 < x < 3.15:
            frame_at('F%d_upper' % i, x, zr=[(-0.085, 99.0)]); frame_at('F%d_lower' % i, x, zr=[(-99.0, -0.215)], record=False)
        else:
            frame_at('F%d' % i, x)
    room('bow_stores', 'hold', 3.95, 3.3, -0.14, 0.12, note='bow stores and the bow ridge\'s sensor feeds')
    room('tube_room', 'magazine', 2.85, 2.2, 0.03, 0.27, note='the tube room: the loaders run the next pair of Cinder torpedoes into the tubes by hand')
    room('torpedo_magazine', 'magazine', 2.15, 0.95, 0.03, 0.27, note='the torpedo magazine: racks of armoured Cinder bodies on rails, the reload the vents breathe for')
    room('crew_deck', 'crew', 0.9, -0.55, 0.03, 0.28, ymax=0.5, note='the crew deck: berths and the mess, the chalk wall where the names go up before launch')
    room('turret_magazine', 'magazine', 0.75, 0.0, 0.03, 0.27, y0=0.55, note='the sear turrets\' charge rooms, under the tubs')
    room('ballast_fwd', 'machinery', 2.7, -0.55, -0.4, -0.29, note='trim tanks and pumps under the magazine and the crew deck')
    room('command', 'bridge', -1.0, -1.3, 0.03, 0.28, ymax=0.4, note='the command deck under the spine block\'s slits')
    room('reactor', 'core', -1.35, -2.9, -0.4, 0.28, ymax=0.42, note='the reactor: its heat goes up through the spine block into the spires (hp_core)')
    room('coolant', 'machinery', -1.35, -2.9, -0.25, 0.28, y0=0.46, note='coolant pumps and heat exchangers either side of the reactor')
    room('engine_room', 'engroom', -3.0, -4.05, -0.38, 0.27, note='the engine room and the two drives\' feeds')
    K.armour('upper facets and deck', 0.08, 'forged plate over the magazine and the crew deck')
    K.armour('band and lips', 0.09, 'the plated band, the hull\'s belt')
    K.armour('bow point and tube cowls', 0.1, 'solid forged layers toward the point; the tube cowls are the thickest plate')
    K.armour('belly and armour step', 0.08, '')
    K.armour('spine block', 0.07, 'it snaps off with the spires')
    # seams (factions.md "How it breaks": along the gun decks, the hull splits lengthwise between deck rows; the spire line snaps
    # off as one piece; designs.md: the bow tube block separates at the forward knuckle; R226: no machine on a seam)
    K.break_line('B-1', B1_X, 'the gun and magazine section tears from the reactor section, between the turret tubs and the spine block\'s face',
                 path=TRANS)
    K.break_line('B-2', 0.0, 'along the band: the lower hull peels away under the magazine and the crew deck',
                 path=[(3.05, -0.15), (2.0, -0.151), (0.9, -0.148), (B1_X + 0.05, -0.15)], kind='long')
    K.break_line('B-4', 3.15, 'the bow point snaps off whole just ahead of the tube cowls (designs.md: the bow tube block separates at the forward knuckle), '
                 'so the tubes stay with the magazine section', path=[(3.15, 9.0), (3.15, -9.0)])
    K.break_line('B-3', -2.4, 'the spire line snaps off as one piece, the spine block tearing along its root',
                 path=[(SPINE_X[0], SPZ - 0.13), (-1.9, SPZ - 0.132), (-3.0, SPZ - 0.13), (SPINE_X[1] + 0.05, SPZ - 0.131)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit crew spaces, frames, the tube room and the torpedo magazine, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).'))
    K.point('core', 'hp_core', (-2.1, 0, -0.1))
    # Three breach anchors (Destroyer base 3, Sunward +0): one in each of the prow, mid and engine sections, alternating sides, each on
    # the hull side by the broadside band, clear of the louvres, lamps and thrusters
    for i, (x, side, z, sec) in enumerate(((2.25, 1, BAND_Z + 0.06, 'prow'), (-1.05, -1, BAND_Z + 0.06, 'mid'), (-3.55, 1, BAND_Z + 0.06, 'eng'))):
        K.point('breach', 'hp_breach_%d' % i, (x, side * hw_at(x, z), z), side='port' if side > 0 else 'stbd', section=sec,
                note='on the hull side by the broadside band, clear of the louvres, lamps and thrusters')
    for i, side in enumerate((1, -1)):
        p, n = lower_pt(2.2, side, 0.35)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(p), side='port' if side > 0 else 'stbd')
        p, n = facet_pt(-3.3, side, 0.75)
        K.point('rcs', 'hp_rcs_%d' % (i + 2), tuple(p), side='port' if side > 0 else 'stbd')
        hw = st_at(-1.3)[1]
        K.point('board', 'hp_board_%d' % i, (-1.3, side * hw, BAND_Z), side='port' if side > 0 else 'stbd')

    for m_ in getattr(HP, 'METALLIC', ()):
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
                K._obj('S11_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('S11_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='S11_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Four radiator spires, not the round 2 pictures\' five, at 0.66, 0.85, 0.76 and 0.58 over the spine block (tallest second from the front)',
             'designs.md\'s table (4 spires) outranks the picture; the final spire table (Board, Nov 19 15:30 UTC, after R331) gives the Harrow tallest 0.85; Ryan took round 2 with 4 small spires (R369)')
    K.change('The spires\' fins stand apart, so the ember shows as lit slats with dark iron between them, not as a whole lit tower', 'R331: the ember shows in the slats (the shared radiator glow=\'slats\', as S8, S9 and S10)')
    K.change('The twin torpedo tubes sit in raised armoured cowls on the deck either side of the centreline (station 22 percent, 0.36 off the centreline), each a rounded teardrop fairing sweeping back into the deck, a broad riveted mouth ring, a forged collar, a deep bore and the next torpedo\'s nose seated inside; the bow is one long leaf taper with no step',
             'the round 2 pictures Ryan took (R369) draw the tubes in deck cowls on a smooth taper; designs.md\'s cheek-plate tubes at station 10 percent would sit where the point is too narrow for two bores, and the cowls keep the firing lanes clear over the falling bow (R241)')
    K.change('The widest hull (2.1) sits over the magazine section at 40 to 50 percent, then about 1.7 over the stern third',
             'the round 2 top view measures its widest at 46 percent; designs.md calls this the widened magazine section (20 to 45 percent); its line "widest at about 70 percent" is the family default the picture overrides')
    K.change('The magazine\'s ember heat-vent slits are one long panel of four lit slits on each upper facet between the tube cowls and the turret pair, as the round 2 pictures draw them', 'designs.md: the reload read; R221: they vent the magazine below')
    K.change('One sear turret pair (two single-emitter tubs at the deck edges, station 46 percent)', 'designs.md\'s table and data.js harrow carry one turret slot (2 shots: one a mount)')
    K.change('The broadside band is plated and louvred, with no ports', 'designs.md: no broadside slot in data, so no ports (R241: no decorative guns)')
    K.change('Two ember bells 0.8 across at plus and minus 0.55 on riveted drums; no flame plumes', 'designs.md\'s table; the game draws the plume (round 2 pictures draw none at rest)')
    K.change('The concept\'s centre stripe is the dorsal power trunk, banded, from the reactor forward over the magazine to the tube room', 'the stripe needs a job (R221): it feeds the turrets and the tube room from the reactor')
    K.change('Attitude thrusters, deck and belly hatches, reactor louvres, frost running points, a belly armour step added', 'a ship in space needs thrusters and access; the reactor needs louvres; the concept shows no underside; every part has a job (R221)')
    K.open_item('The belly is designed here; the concept shows no underside')
    K.open_item('Frost-white markings (one thin stripe and a small sigil, round 2) are paint (the Sunward stack, stage 5), not modelled')


INV_NOTES = {}
