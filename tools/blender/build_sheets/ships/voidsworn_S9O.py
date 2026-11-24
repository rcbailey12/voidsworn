# voidsworn_S9O: the Warden-class frigate of the Sunward Crusade (data.js warden, class Frigate, 6.5 world units), the Opus leg
# of blind builder pair 2 (issue 1889). A rebuild of the accepted Warden from its concept alone: the shape of record is the
# accepted concept docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg and concept_sheet.jpg (R331), and the
# "Warden, frigate" table in contrib/muse/design/class_family_sunward_2026_11/designs.md outranks both pictures (its "Picture
# slips": one flak pair, three spires). Blind: built without opening the voidsworn_S9 sheet, its inventory, recipe json or
# history, or the Astra leg. Family pattern read from S8 and S10 (the Vigil) only.
# data.js warden: autocannon F (3 shots), flak T (3 shots); ability evasive (no visible feature: the read is the narrow hull).
# Method (the brief, ships.md section 0 item 1 and R443): the midships and drive modules are FlatSoleLoft modules ending at their
# authored breaks (loft_module); the spearhead is its own module whose rings keep the loft's ten-point section and close it to a
# point at mid height; cooler cassettes and removable belly covers come from the shared hull methods; the flank trim race and the
# bow's worked-iron spike are broken_stripe runs, broken at the boarding doors and the casemate. The plating is the Sunward kit's
# own forged rows (forged_plates), never the Navy's plate_region. Added fittings take hull-tone iron and sit on hull structure.
# +X bow, +Y port, +Z up. The spearhead's point x = +3.25, the bell exits x = -3.25.
import math

CODE = 'voidsworn_S9O'
NAME = 'Warden-class frigate (Sunward Crusade), Opus blind rebuild'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js warden (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5"
BEAUTY = 'docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/voidsworn_S9/concept_sheet.jpg'
# the true views on the Warden sheet (x0, y0, x1, y1): the top view above, the side view lower left, bow LEFT in both
CONCEPT_VIEWS = dict(top=dict(box=(200, 320, 1650, 610), largest=True, flip=False), side=dict(box=(30, 810, 1260, 1060), largest=True, flip=False))
CROPS = [('bow (the spearhead and the repeater casemate)', (100, 500, 700, 900)), ('midships (the trunk and the flak pair)', (300, 380, 750, 760)),
         ('stern (the spire line and the bells)', (600, 250, 1000, 600))]
SHEET = dict(version=1, round='blind rebuild, first sheet', date='2026-11-24', blend='opus1889',
             blend_where='built in the issue 1889 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py voidsworn_S9O <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout from the designs.md table and the two concept pictures, built with the Sunward kit and the shared hull methods.',
             during='The fit check findings are in the table above, in the order the check made them.')

TIP = 3.25
STERN = -2.92          # the transom; the bells stand out behind it to x -3.25
SOLE = -0.27           # the flat worked belly
FLANK = (-0.08, 0.06)  # the vertical broadside band's bottom and top (the loft's fixed flank datums)
CHINE_H = 0.08         # the chine above the sole
WIDTHS = (0.62, 0.84, 0.6)   # deck, chine and sole half-widths as shares of the half beam
PZ = -0.02             # the spearhead's point: mid height, a blade, never a stem
SHELL = 0.06           # hull thickness (the modules' inward shell)
B1, B2 = 1.3, -2.5     # the transverse breaks: the spearhead root (30 percent) and the drive section
PEEL = -0.14           # B-3: the lengthwise break along the lower band facet
# The loft's stations aft to bow: (x, half beam, deck z). Widest 1.5 at 72 percent (x -1.43), as designs.md asks; the flanks
# run nearly parallel from the shoulders aft, as the concept's top view draws them.
STATIONS = ((STERN, 0.6, 0.19), (-2.6, 0.66, 0.2), (-2.0, 0.73, 0.2), (-1.43, 0.75, 0.2), (-0.7, 0.72, 0.2), (0.2, 0.67, 0.2), (B1, 0.58, 0.2))
# the spearhead's half beam forward of B-1 (the loft's last station carries on into it)
BOW_BEAM = ((B1, 0.58), (1.8, 0.48), (2.3, 0.36), (2.8, 0.21), (3.1, 0.09), (TIP, 0.006))
CAS_X = TIP - 0.14 * LENGTH          # the repeater casemate at station 14 percent (2.34)
FLAK_X = TIP - 0.60 * LENGTH         # the flak pair at station 60 percent (-0.65)
SPINE_X = (TIP - 0.58 * LENGTH, -2.42)   # the spine block: its face (the command slits) at 58 percent, its end before B-2
SPIRES = [(TIP - 0.68 * LENGTH, 0.5, 3), (TIP - 0.76 * LENGTH, 0.64, 2), (TIP - 0.84 * LENGTH, 0.54, 0)]   # 68 / 76 / 84 percent
DOORS = ((-1.25, -0.97),)            # the boarding doors in each flank's band (hp_board)
PL = dict(size=(0.15, 0.27), thick=(0.012, 0.024))
SPINE_TOP = 0.2 - 0.03 + 0.19   # the spine block's top over the flat deck: the spire roots stand on it
UNIT = 0.3                           # the kit's plating scale hook for a hull under half the Vigil's length


def _lerp(a, b, t):
    return a + (b - a) * t


def _beam_bow(x):
    for (x0, b0), (x1, b1) in zip(BOW_BEAM, BOW_BEAM[1:]):
        if x0 <= x <= x1:
            return _lerp(b0, b1, (x - x0) / (x1 - x0))
    return BOW_BEAM[-1][1]


def _profile():
    import sys, os
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.normpath(os.path.join(here, '..', '..', '..', 'recipe')))
    sys.path.insert(0, os.path.normpath(os.path.join(here, '..', '..', 'kits', 'shared')))
    from hull_details import FlatSoleLoft
    return FlatSoleLoft(STATIONS, sole=SOLE, flank=FLANK, chine_height=CHINE_H, widths=WIDTHS)


def section(x):
    """(half beam, deck, upper, lower, chine, sole, deck share) at x: the loft's datums aft of B-1, closing to the point forward"""
    if x <= B1:
        for a, b in zip(STATIONS, STATIONS[1:]):
            if a[0] <= x <= b[0]:
                t = (x - a[0]) / (b[0] - a[0])
                beam, deck = _lerp(a[1], b[1], t), _lerp(a[2], b[2], t)
                break
        else:
            beam, deck = (STATIONS[0][1], STATIONS[0][2]) if x < STERN else (STATIONS[-1][1], STATIONS[-1][2])
        return beam, deck, FLANK[1], FLANK[0], SOLE + CHINE_H, SOLE, WIDTHS[0]
    t = min(0.985, (x - B1) / (TIP - B1))
    deck = _lerp(STATIONS[-1][2], PZ + 0.006, t ** 1.6)
    up = _lerp(FLANK[1], PZ + 0.003, t ** 1.2)
    lo = _lerp(FLANK[0], PZ - 0.002, t ** 1.2)
    ch = _lerp(SOLE + CHINE_H, PZ - 0.004, t ** 1.05)
    so = _lerp(SOLE, PZ - 0.006, t ** 0.95)
    return _beam_bow(x), deck, up, lo, ch, so, WIDTHS[0] - 0.42 * t   # the deck narrows to a ridge: a diamond section at the point


def ring(x, inset=0.0):
    """the loft's ten-point ring (clockwise from the bow, from the starboard deck edge), inset inward by about `inset`"""
    beam, deck, up, lo, ch, so, dw = section(x)
    b = max(0.004, beam - inset)
    d, c, s = b * dw, b * WIDTHS[1], b * WIDTHS[2]
    deck -= inset; so += inset
    up = min(up, deck - 0.01); ch = max(ch, so + 0.005); lo = max(min(lo, up - 0.01), ch + 0.005)
    return [(x, y, z) for y, z in ((-d, deck), (d, deck), (b, up), (b, lo), (c, ch), (s, so), (-s, so), (-c, ch), (-b, lo), (-b, up))]


def half_ring(x, inset=0.0):
    """the port half from the deck centre to the belly centre: [(y, z)]"""
    r = ring(x, inset)
    return [(0.0, r[1][2])] + [(p[1], p[2]) for p in r[1:6]] + [(0.0, r[5][2])]


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


def deck_z(x):
    return section(x)[1]


def face_pt(x, side, j, f):
    """a point at share f along ring edge j (port numbering: 1 shoulder, 2 band, 3 lower facet, 4 chine; 5 the sole) and its
    outward normal; side -1 mirrors it to starboard"""
    from mathutils import Vector
    r = ring(x)
    a, b = Vector(r[j][1:]), Vector(r[j + 1][1:])
    p = a.lerp(b, f)
    e = b - a
    n = Vector((-e.y, e.x)).normalized()     # the ring runs deck, band, sole on the port side: the outward normal is (-dz, dy)
    return Vector((x, side * p.x, p.y)), Vector((0.0, side * n.x, n.y))


def build(K):
    import bpy
    import kit as _k
    import os, sys
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit
        _k.MATS.setdefault(k_, v_)
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.normpath(os.path.join(here, '..', '..', '..', 'recipe')))
    from hull_methods import loft_module, slatted_cassette, belly_cover, mount_service_part, broken_stripe
    profile = _profile()
    for st in STATIONS:     # the spearhead rings keep the loft's section exactly at the joint
        assert all(abs(u - v) < 1e-9 for p, q in zip(profile.ring(st[0]), ring(st[0])) for u, v in zip(p, q)), st
    K.hull_sections = [(x, section(x)[0], section(x)[0], section(x)[5], section(x)[1], 0.0, 0.0) for x in [STERN] + [s[0] for s in STATIONS[1:]] + [b[0] for b in BOW_BEAM[1:]]]
    K.hull_rounded = False

    # ---------------- the hull: three modules, each ending at its authored break ----------------
    mods = {}
    mods['drive'] = loft_module(K, 'S9O_hull_drive', profile, 'siron', thickness=SHELL, start=STERN, end=B2)
    mods['mid'] = loft_module(K, 'S9O_hull_mid', profile, 'siron', thickness=SHELL, start=B2, end=B1)
    xbow = [B1 + (TIP - B1) * (i / 12) ** 0.9 for i in range(13)]
    bow = K.loft_rings('S9O_hull_bow', [ring(x) for x in xbow], 'siron')
    md = bow.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    mods['bow'] = bow
    relieve_liner(mods['mid'], [r[0][0] for r in profile.rings(B2, B1)])
    K.mass('Hull: the spearhead (bow module)', bow, 'black iron plate', note='the knife\'s point: the loft\'s section closing to one point at mid height, diamond at the tip; the casemate sits on its root')
    K.mass('Hull: midships module (FlatSoleLoft)', mods['mid'], 'black iron plate', note='the blade from the spearhead root to the drive break: crowned shoulders, the vertical band, the lower facets, a flat worked sole; widest 1.5 at 72 percent')
    K.mass('Hull: drive module (FlatSoleLoft)', mods['drive'], 'black iron plate', note='the drive section aft of B-2, the bells deep-set in its transom')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('spearhead', 'hull', ['facet', 'step', 'chamfer'])

    xs_body = sorted({STERN, B2, B1} | {round(x / 4, 3) for x in range(-11, 6)} | {s[0] for s in STATIONS}, reverse=True)
    xs_body = [x for x in xs_body if STERN <= x <= B1]
    body = [ring(x) for x in xs_body]
    bowr = [ring(x) for x in [B1 + (TIP - 0.12 - B1) * i / 7 for i in range(8)]]
    plate_jobs = [('deck', body, dict(PL, faces=[0], mats={'siron': 3, 'siron2': 2}, seed=11, inv='deck_plates')),
                  ('shoulder', body, dict(PL, faces=[1, 9], mats={'siron': 4, 'siron2': 2}, seed=12, inv='flank_plates')),
                  ('band', body, dict(PL, faces=[2, 8], mats={'siron2': 3, 'siron': 2}, seed=13, inv='flank_plates', size=(0.12, 0.22))),
                  ('lower', body, dict(PL, faces=[3, 7], mats={'siron': 3, 'siron2': 2}, seed=14, inv='flank_plates')),
                  ('belly', body, dict(PL, faces=[4, 5, 6], mats={'siron2': 3, 'siron': 2}, seed=15, inv='belly_plates')),
                  ('bow', bowr, dict(PL, faces=[1, 2, 3, 7, 8, 9], tri=True, mats={'siron': 4, 'siron2': 2}, seed=16, inv='bow_plates', size=(0.14, 0.3))),
                  ('bowbelly', bowr, dict(PL, faces=[4, 5, 6], mats={'siron2': 3, 'siron': 2}, seed=17, inv='belly_plates'))]

    # ---------------- the bow: the Sear repeater in its forged casemate at the spearhead root ----------------
    # its seat: a forged plinth that levels the narrow ridge under the casemate (the concept's casemate sits on a flat)
    seat_top = deck_z(CAS_X - 0.3) + 0.012
    sr = []
    for x in [CAS_X + 0.36, CAS_X + 0.3] + [CAS_X + 0.3 - 0.75 * i / 5 for i in range(1, 6)] + [CAS_X - 0.5]:
        hb = min(0.2, ring(x)[2][1] * 0.82)
        top = seat_top if CAS_X - 0.45 <= x <= CAS_X + 0.3 else deck_z(x) + 0.004
        sr.append([(x, hb + 0.03, deck_z(x) - 0.06), (x, hb, top), (x, -hb, top), (x, -hb - 0.03, deck_z(x) - 0.06)])
    seat = K.loft_rings('S9O_casemate_seat', sr, 'siron2')
    K.mass('Casemate seat', seat, 'darker iron', note='a forged plinth over the spearhead root: the repeater casemate stands on it')
    GS = 0.5
    _casemate(K, HP, Vector((CAS_X, 0.0, seat_top)), GS)

    # the worked-iron spike along the spearhead's ridge (the concept's bright blade line), broken round the casemate
    def ridge(x):
        return (x, 0.0, deck_z(x) + 0.002), (0.0, 0.0, 1.0)
    sx = [TIP - 0.3 - (TIP - 0.3 - (B1 + 0.08)) * i / 14 for i in range(15)][::-1]
    broken_stripe(K, 'S9O_spike', sx, [(CAS_X - 0.5, CAS_X + 0.36)], ridge, clearance=0.03,
                  race=(0.07, 0.012, 'siron2'), stripe=(0.026, 0.008, 'sworn'))
    K.built.append(dict(id='S9O_spike', kind='belt', type='belt', inv=['spike'], shaped=True, detailed=True, subs=['band', 'plate']))

    # ---------------- the trunk: the raised feed trunk from behind the casemate to the spine block's face ----------------
    TX = (B1 - 0.12, SPINE_X[0] + 0.1)
    tr = []
    for i, x in enumerate([TX[0] - (TX[0] - TX[1]) * k / 8 for k in range(9)]):
        k = 0.0 if i in (0, 8) else 1.0
        z0 = deck_z(x) - 0.01
        tr.append([(x, 0.075, z0), (x, 0.075, z0 + 0.03 + 0.02 * k), (x, 0.045, z0 + 0.045 + 0.03 * k),
                   (x, -0.045, z0 + 0.045 + 0.03 * k), (x, -0.075, z0 + 0.03 + 0.02 * k), (x, -0.075, z0)])
    K.mass('Feed trunk', K.loft_rings('S9O_trunk', tr, 'siron2'), 'darker iron',
           note='the raised trunk along the centreline: the reactor\'s power and the shell feed run forward under it to the bow magazine')
    for i in range(8):
        x = TX[0] - 0.12 - i * (TX[0] - TX[1] - 0.24) / 7
        z0 = deck_z(x) - 0.005
        pts = [Vector(q) for q in ((x, 0.085, z0), (x, 0.055, z0 + 0.082), (x, -0.055, z0 + 0.082), (x, -0.085, z0))]
        V, F = [], []
        for a_, b_ in zip(pts, pts[1:]):   # Kit.rib's flat bars, without its capital-ship keep-outs (0.45 each) that bared the deck
            vv, ff = HP.rod(a_, b_, 0.0125, 4)
            o = len(V); V += vv; F += [tuple(q + o for q in f) for f in ff]
        K._obj('S9O_trunkband_%d' % i, V, F, 'siron', grp='hull')
    K.mark('trunk', 'spine', ['block', 'step', 'slit'])

    # ---------------- the flak strakes and the spark flak pair at station 60 percent ----------------
    STK = (0.25, -1.35)
    for side, nm in ((1, 'p'), (-1, 's')):
        rs = []
        xl = [STK[0] - (STK[0] - STK[1]) * k / 8 for k in range(9)]
        for i, x in enumerate(xl):
            r = ring(x)
            d, dz = r[1][1], r[1][2]
            b, uz = r[2][1], r[2][2]
            out = 0.0 if i in (0, 8) else 0.05
            mid_y, mid_z = d + (b - d) * 0.35, dz + (uz - dz) * 0.35
            pts = [(d - 0.02, dz + 0.004), (b + out, dz + 0.004), (b + out, dz - 0.03), (mid_y, mid_z - 0.02)]
            rs.append([(x, side * y, z) for y, z in (pts if side > 0 else pts[::-1])])
        K.mass('Flak strake, %s' % ('port' if side > 0 else 'starboard'), K.loft_rings('S9O_strake_' + nm, rs, 'siron2'), 'darker iron',
               note='a forged shelf along the deck edge that carries the flak tub; its ends are angled')
        plate_jobs.append(('strake' + nm, rs, dict(PL, faces=[0] if side > 0 else [2], mats={'siron': 2, 'siron2': 1}, seed=40 + (side > 0), inv='strake_plates', size=(0.1, 0.24), closed=False)))
    K.mark('strakes', 'belt', ['band', 'plate'])
    for side in (1, -1):
        r = ring(FLAK_X)
        y = side * (r[1][1] + (r[2][1] + 0.05 - r[1][1]) * 0.55)
        K.gun('F%d' % (1 if side > 0 else 2), (FLAK_X, y, deck_z(FLAK_X) + 0.004), 25 * side, 12, barrels=2, cal=0.022, blen=0.2, size=0.32,
              slot='T', weapon='flak', inv='flak',
              note='%s spark flak twin on its strake; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley)' % ('port' if side > 0 else 'starboard'))

    # ---------------- the spine block, the command slits and the spire line (3 spires, R331 scale) ----------------
    sp = []
    for x in (SPINE_X[0], SPINE_X[0] - 0.02, -0.9, -1.4, -1.9, SPINE_X[1] + 0.12, SPINE_X[1]):
        z0 = deck_z(x) - 0.03
        k = 0.0 if x == SPINE_X[1] else 1.0
        hb = 0.2 * (0.85 + 0.15 * k)
        sp.append([(x, hb, z0), (x, hb, z0 + 0.08 + 0.06 * k), (x, hb - 0.03, z0 + 0.13 + 0.06 * k), (x, -hb + 0.03, z0 + 0.13 + 0.06 * k),
                   (x, -hb, z0 + 0.08 + 0.06 * k), (x, -hb, z0)])
    K.mass('Spine block (the spire line\'s base)', K.loft_rings('S9O_spine', sp, 'siron2'), 'darker iron',
           note='a forged block along the centreline aft; the spires stand on it and it snaps off with them (B-4)')
    plate_jobs.append(('spine', sp, dict(PL, faces=[0, 2, 4], mats={'siron': 2, 'siron2': 2}, seed=31, inv='spine_plates', size=(0.09, 0.2))))
    SPZ = SPINE_TOP
    for i, y in enumerate((-0.115, 0.115)):
        K._surface_part('W%d' % (i + 1), HP.slit(0.07, 0.024, depth=0.04, fr=0.02), (SPINE_X[0] + 0.003, y, deck_z(SPINE_X[0]) - 0.03 + 0.105), (1, 0, 0), (0, 0, 1),
                        'bridge_slits', 'vision slit', 'slit', 'picture', aperture=0.5,
               note='command deck window, ember-lit, in the spine block\'s face (station 58 percent)')
    K.mark('spine', 'spine', ['block', 'step', 'slit'])
    PROF = ('blade', 'stepped', 'twin', 'raked')
    SC = 0.27
    for i, (x, h, prof) in enumerate(SPIRES):
        part = HP.radiator(h, 0.28, profile=prof, spread=SC * (0.2 + 0.42 * (h / SC) / 2.6), seed=i, scale=SC, glow='slats')
        K.organ('R%d' % (i + 1), part, (x, 0.0, SPZ), (0, 0, 1), fwd=(1, 0, 0), inv='spires', what='radiator spire, %.2f tall, profile %s' % (h, PROF[prof]),
                kind='radiator', note='sheds the reactor\'s heat: ember in the slats between iron fin ribs (R331)')
        K.mass('Radiator spire R%d (%s, %.2f tall)' % (i + 1, PROF[prof], h), bpy.data.objects['R%d_body_embar' % (i + 1)], 'ember slats on iron',
               note='one of the three spires of the spire line')

    # the reactor's cooler cassettes on the aft deck either side of the spine block (shared hull method: slatted_cassette)
    for i, side in enumerate((1, -1)):
        for j, x in enumerate((-1.0, -1.42, -1.84, -2.26)):
            cas = slatted_cassette(length=0.26, width=0.13, depth=0.035, rim=0.02, seat=0.012, slats=4, slat_width=0.022,
                                   materials=('ember', 'siron2', 'siron'))
            mount_service_part(K, 'K%d%s' % (j + 1, 'p' if side > 0 else 's'), cas, kind='vent', pos=(x, side * 0.3, deck_z(x)), normal=(0, 0, 1),
                               inv='coolers', note='reactor cooler cassette: dark iron slats over an ember-lit recess, seated on the deck beside the spine block')

    # ---------------- the stern: two ember bells, 0.55 across, offsets 0.4 ----------------
    for side in (1, -1):
        _engine(K, HP, 'E%d' % (1 if side > 0 else 2), (-3.25, side * 0.4, -0.04), 0.275, 0.3, 0.2, 0.45, note='%s main engine: a riveted drum deep-set in the transom, a deep bell, ember lining and plug' % ('port' if side > 0 else 'starboard'))

    # ---------------- the flank: the frost race (broken at the boarding doors), gallery slits, louvres ----------------
    RZ = 0.022
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'

        def band_pt(x, side=side):
            return (x, side * (ring(x)[2][1] + 0.002), RZ), (0.0, float(side), 0.0)
        rx = [B1 - 0.05 - (B1 - 0.05 - (B2 + 0.06)) * i / 20 for i in range(21)][::-1]
        broken_stripe(K, 'S9O_race_' + sn, rx, DOORS, band_pt, clearance=0.04, race=(0.045, 0.026, 'siron2'), stripe=(0.014, 0.006, 'sworn'))
        for d0, d1 in DOORS:
            x = (d0 + d1) / 2
            K.hatch('D1' + sn, (x, side * (ring(x)[2][1] + 0.012), -0.01), (0, side, 0), 0.17, 0.1, inv='doors', up=(0, 0, 1),
                    note='the boarding door in the band (hp_board); the trim race breaks round it')
        for i, x in enumerate((0.95, 0.55, 0.15, -0.25, -1.55, -1.87)):
            K._surface_part('G%d%s' % (i + 1, sn), HP.slit(0.09, 0.02, depth=0.04, fr=0.018), (x, side * (ring(x)[2][1] + 0.002), -0.045), (0, side, 0), (0, 0, 1),
                            'gallery_slits', 'vision slit', 'slit', 'picture', aperture=0.5,
                   note='an ember slit in the band: the crew galleries behind it')
        for i, x in enumerate((-1.7, -2.04)):
            p, n = face_pt(x, side, 1, 0.5)
            K._surface_part('V%d%s' % (i + 1, sn), HP.vent(0.2, 0.09, 4, depth=0.04, fr=0.022), tuple(p), tuple(n), (1, 0, 0), 'vents', 'louvre panel', 'vent', 'designed', aperture=0.4, note='reactor heat louvre on the aft shoulder')
    K.built.append(dict(id='S9O_race', kind='belt', type='belt', inv=['race'], shaped=True, detailed=True, subs=['band', 'plate']))

    # ---------------- the belly: the service trunk under removable covers (shared hull method: belly_cover) ----------------
    for i, (a, b) in enumerate(((0.95, 0.35), (0.25, -0.35), (-0.45, -1.05), (-1.15, -1.75), (-1.85, -2.38))):
        cov = belly_cover(length=a - b, width=0.2, depth=0.028, rim=0.018, seat=0.012, gap=0.005, materials=('siron2', 'siron'))
        mount_service_part(K, 'C%d' % (i + 1), cov, kind='cover', pos=((a + b) / 2, 0.0, SOLE), normal=(0, 0, -1),
                           inv='belly_covers', note='removable service cover over the belly trunk (each lid its own mesh)')

    # ---------------- fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p, n = face_pt(2.45, side, 3, 0.5)
        K.thruster('Q1' + sn, tuple(p), tuple(n), r=0.07, inv='thrusters', note='bow attitude thruster on the lower facet')
        p, n = face_pt(-2.3, side, 1, 0.5)
        K.thruster('Q2' + sn, tuple(p), tuple(n), r=0.07, inv='thrusters', note='stern attitude thruster on the aft shoulder')
        for i, x in enumerate((2.98, 1.65, 1.0, 0.5, -1.45)):
            p, n = face_pt(x, side, 1, 0.92)
            K._surface_part('L%d%s' % (i + 1, sn), HP.lamp(0.032), tuple(p + n * 0.002), tuple(n), (1, 0, 0), 'lamps', 'running light', 'lamp', 'designed', note='frost-white running point on the blade\'s shoulder edge')
    for i, (x, y) in enumerate(((1.0, 0.24), (1.0, -0.24), (-0.25, 0.3), (-0.25, -0.3))):
        K.hatch('H%d' % (i + 1), (x, y, deck_z(x) + 0.003), (0, 0, 1), 0.13, round_=True, inv='hatches', note='deck hatch')
    K.hatchbox('HB1', (0.55, -0.26, deck_z(0.55)), 0.13, 0.2, 0.07, inv='lift_heads',
               note='the shell hoist head over the bow magazine\'s feed')

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white markings (paint stage)', TIP, -TIP, 'whole hull')
    K.colour('ember glow (radiator slats, engine throats, window slits, cooler recesses)', TIP, -TIP, 'the spires, the bells, the slits, the cassettes')
    K.colour('frost-white running points', TIP, -TIP, 'the blade\'s shoulder edges')
    K.colour('no rust anywhere, no blue light', TIP, -TIP, 'factions.md Never')

    # ---------------- INSIDE ----------------
    _insides(K)

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3

    # ---------- the forged plating, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if abs(pc.y) < 0.12 and pc.z > 0.12 and TX[1] - 0.02 < pc.x < TX[0] + 0.02:
            return True        # the trunk's footing
        if abs(pc.y) < 0.05 and pc.x > B1 and pc.z > PZ:
            return True        # the spike along the ridge
        return any((pc - c).length < r + hd * 0.6 for c, r in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), closed=spec.get('closed', True), unit=UNIT, rr=0.026 * UNIT)
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('S9O_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('S9O_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='S9O_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))

    _changes(K)


def _casemate(K, HP, pos, s):
    """the Sear repeater's casemate on the deck. Kit.gun picks its casemate branch by a flank normal; the repeater is a deck
    casemate (parts.py _sear_repeater: origin on the deck, +Z up, fixed forward), so this places it the way that branch does
    (the same part, frame, fit row and feature row) with the deck's up as its normal."""
    import math
    from mathutils import Vector
    import kit as _k
    p = Vector(pos); nrm = Vector((0.0, 0.0, 1.0))
    cal, blen = 0.03 * s / 0.5, 0.44 * s / 0.5
    part = HP.gun(3, cal, blen, s, 'casemate', pitch=0.0, variant=0, weapon='autocannon')
    part = K.emit('A1', part, HP.frame(p, Vector((1, 0, 0)), nrm), 'repeater')
    fd = part.fit
    K.fitdata.append(dict(id='A1', kind='gun', slot='F', pivot=tuple(fd['trunnion'][1]), up=tuple(nrm), mount='casemate', ring=tuple(p), rest_yaw=0.0,
                          reach=fd['reach'], band=(-10, 0, 10, 20), muzzles=[tuple(m[1]) for m in fd['muzzles']], cal=cal * 1.55, hous_r=fd['radius'],
                          rest_pitch=0.0, aim=tuple(fd['aim'][1]), bore=cal / 2))
    K.features.append(dict(id='A1', kind='gun', what='sear repeater, triple casemate', count=3, pos=tuple(p), aim=(0.0, 0.0), slot='F',
                           weapon='autocannon', src='picture', muzzle=[tuple(m[1]) for m in fd['muzzles']], normal=tuple(nrm), inv=['repeater'],
                           note='the Sear repeater (autocannon F, 3 shots): a three-barrel rotary cluster in a forged casemate at station 14 percent; all three barrels fire each volley'))


def _engine(K, HP, fid, pos, r, length, body_r, S, note=''):
    """Kit.engine at frigate size: the kit's bell carries flagship-sized lips, bands, studs and struts in world units, so it is
    built at 1/S and shrunk by S (the radiator's scale= idea, issue 1156), then placed and recorded as Kit.engine does"""
    from mathutils import Vector, Matrix
    p = Vector(pos)
    part = HP.engine_bell(r / S, length / S, bell_len=r * 1.1 / S, body_r=body_r / S, rings=3, nose='dome').transform(Matrix.Scale(S, 4))
    part.fit['radius'] *= S; part.fit['body_r'] *= S   # transform moves points, not the plain sizes
    part = K.emit(fid, part, HP.frame(p, (1, 0, 0), (0, 0, 1)), 'engines')
    rad = part.fit['radius']
    K.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=tuple(p), dir=(-1, 0, 0), r0=rad, half=12.0, length=max(2.5 * 2 * rad, 0.22 * K.length))]))
    K.features.append(dict(id=fid, kind='engine', what=getattr(HP, 'ENGINE_WHAT', 'engine, bell %.1f across') % (2 * rad), count=1, pos=tuple(p),
                           aim=(180.0, 0.0), src='picture', note=note, exit=tuple(p), radius=rad, inv=['engines']))


def relieve_liner(hull, stations):
    """S8's and S10's B-3 method on the midships module: the shell's inner liner is left out across the lower band facet, the chine
    and the sole over the peel's compartment, so when the belly peels away no liner stands outside its piece's torn plating.
    The plating stays whole; only the inside lining has the gap."""
    import bpy
    shell = hull.modifiers['shell']
    strip = hull.vertex_groups.new(name='B3_relief')
    liner = hull.vertex_groups.new(name='inner_shell')
    shell.shell_vertex_group = liner.name
    n = 10
    vs = []
    for i, x in enumerate(stations):
        if x <= B2 + 0.3 or x >= B1 - 0.3:
            vs.extend(i * n + j for j in range(n))
        else:
            vs.extend(i * n + j for j in range(3, 9))
    strip.add(vs, 1.0, 'REPLACE')
    tree = bpy.data.node_groups.new('S9O B-3 liner clearance', 'GeometryNodeTree')
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


def _insides(K):
    IN = SHELL + 0.03

    def deck_slab(name, z, x0, x1, inset=0.015, n=6):
        rs = []
        for x in [x0 + (x1 - x0) * i / n for i in range(n + 1)]:
            hw = hw_at(x, z, IN) - inset
            rs.append([(x, hw, z - 0.012), (x, hw, z + 0.012), (x, -hw, z + 0.012), (x, -hw, z - 0.012)])
        K.loft_rings('in_deck_' + name, rs, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=name, z=z, x=(x1, x0)))

    def frame_at(name, x, zr=None):
        ho = half_ring(x, IN); hi = half_ring(x, IN + 0.035)
        fo = ho + [(-y, z) for (y, z) in reversed(ho[1:-1])]
        fi = hi + [(-y, z) for (y, z) in reversed(hi[1:-1])]
        n = len(fo); pts = []
        for kk in range(n):
            a_, b_ = kk, (kk + 1) % n
            for j in range(4):
                t0 = j / 4
                pts.append(((fo[a_][0] + (fo[b_][0] - fo[a_][0]) * t0, fo[a_][1] + (fo[b_][1] - fo[a_][1]) * t0),
                            (fi[a_][0] + (fi[b_][0] - fi[a_][0]) * t0, fi[a_][1] + (fi[b_][1] - fi[a_][1]) * t0)))
        bands = zr or [(-99.0, 99.0)]
        V, F = [], []
        m = len(pts)
        for kk in range(m):
            (oa, ia), (ob, ib) = pts[kk], pts[(kk + 1) % m]
            if (abs(oa[0] - ob[0]) < 1e-9 and abs(oa[1] - ob[1]) < 1e-9):
                continue
            if not any(all(lo_ <= z_ <= hi_ for z_ in (oa[1], ob[1], ia[1], ib[1])) for lo_, hi_ in bands):
                continue
            q = [oa, ob, ib, ia]
            o = len(V)
            V += [(x + 0.018, y_, z_) for (y_, z_) in q] + [(x - 0.018, y_, z_) for (y_, z_) in q]
            F += [(o, o + 1, o + 2, o + 3), (o + 7, o + 6, o + 5, o + 4), (o, o + 4, o + 5, o + 1), (o + 1, o + 5, o + 6, o + 2), (o + 2, o + 6, o + 7, o + 3), (o + 3, o + 7, o + 4, o)]
        if F:
            K._obj('in_bh_' + name, V, F, 'frame', inside=True)
            K.inside.append(dict(kind='bulkhead', name=name.split('_')[0], x=x))

    def room(name, kind, x0, x1, z0, z1, ymax=None, note=''):
        w = min(hw_at(x, z, IN) for x in (x0, x1, (x0 + x1) / 2) for z in (z0, z1)) - 0.015
        if ymax is not None:
            w = min(w, ymax)
        K.room(name, kind, min(x0, x1), max(x0, x1), -w, w, z0, z1, note=note)

    deck_slab('bow', -0.06, 2.55, 1.42)
    deck_slab('main', 0.02, 1.18, B2 + 0.12)
    deck_slab('aft', 0.02, B2 - 0.1, STERN + 0.12)
    for i, x in enumerate((2.6, 2.2, 1.75, 1.0, 0.4, -0.2, -0.8, -1.4, -2.0, -2.75)):
        if B2 < x < B1:
            frame_at('F%d_upper' % i, x, zr=[(PEEL + 0.1, 99.0)])
        else:
            frame_at('F%d' % i, x)
    room('repeater_magazine', 'magazine', 2.55, 1.5, -0.04, 0.11, note='the Sear repeater\'s magazine and feed under the casemate (it goes with the spearhead, B-1)')
    room('bow_stores', 'hold', 2.3, 1.5, -0.19, -0.08, note='bow stores and the bow thrusters\' feeds')
    room('crew_fwd', 'crew', 1.15, 0.1, 0.04, 0.15, note='the crew berths and the chalk wall where the names go up before launch')
    room('galleries', 'gallery', 1.15, -0.3, -0.07, 0.0, note='the crew galleries behind the band\'s ember slits')
    room('command', 'bridge', -0.45, -1.0, 0.04, 0.15, ymax=0.3, note='the command deck under the spine block\'s slits (no AI: plotted by hand)')
    room('flak_magazine', 'magazine', -0.4, -1.0, -0.07, 0.0, note='the spark flak magazine between the tubs')
    room('reactor', 'core', -1.3, -2.25, -0.07, 0.15, ymax=0.4, note='the reactor: its heat rises through the spine block into the spires (hp_core)')
    room('engine_room', 'engroom', -2.62, -2.85, -0.12, 0.12, note='the engine room and the two drives\' feeds')
    K.armour('shoulders and deck', SHELL, 'forged plate over the galleries')
    K.armour('band', SHELL, 'the trim race and the boarding doors')
    K.armour('spearhead', SHELL, 'forged layers toward the point round the casemate seat')
    K.armour('spine block', 0.05, 'it snaps off with the spires')
    reach = 2 * max(s[1] for s in STATIONS)
    K.break_line('B-1', B1, 'the spearhead tears from the hull at its root, the casemate and its magazine going with it',
                 path=[(B1, reach), (B1, 0.4), (1.34, 0.15), (1.26, -0.1), (1.33, -0.35), (B1, -reach)])
    K.break_line('B-2', B2, 'the drive section tears from the reactor section, behind the spire line',
                 path=[(B2, reach), (-2.47, 0.4), (-2.53, 0.12), (-2.48, -0.15), (-2.54, -0.4), (B2, -reach)])
    K.break_line('B-3', 0.0, 'lengthwise along the band: the belly tears away below the galleries',
                 path=[(1.15, PEEL), (0.4, PEEL + 0.01), (-0.5, PEEL - 0.01), (-1.4, PEEL + 0.008), (-2.3, PEEL)], kind='long')
    K.break_line('B-4', -1.6, 'the spire line snaps off as one piece, the spine block tearing along its root',
                 path=[(SPINE_X[0] - 0.02, SPINE_TOP - 0.1), (-1.1, SPINE_TOP - 0.11), (-1.8, SPINE_TOP - 0.1), (SPINE_X[1] + 0.02, SPINE_TOP - 0.11)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors (R215), hidden until a piece breaks: iron decks, ember-lit galleries, frames, the repeater magazine, the reactor. Sunward breaks lengthwise along the band and the spire line snaps off as one piece (factions.md).'))
    K.point('core', 'hp_core', (-1.8, 0, -0.02))
    # two breach anchors (Frigate base 2, Sunward +0): prow port, eng starboard, on open plating
    for i, (x, z, sec, side) in enumerate(((1.9, -0.1, 'prow', 1), (-2.3, -0.12, 'eng', -1))):
        K.point('breach', 'hp_breach_%d' % i, (x, side * hw_at(x, z), z), side='port' if side > 0 else 'stbd', section=sec, note='on open lower plating')
    for i, side in enumerate((1, -1)):
        p, n = face_pt(2.45, side, 3, 0.5)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(p), side='port' if side > 0 else 'stbd')
        x = sum(DOORS[0]) / 2
        K.point('board', 'hp_board_%d' % i, (x, side * ring(x)[2][1], -0.01), side='port' if side > 0 else 'stbd')


def _changes(K):
    K.change('The bow is one spearhead point at mid height, diamond in section at the tip, closing from the loft\'s own ten-point section',
             'family law (designs.md "Never change": one point at mid height, diamond section); the loft keeps one section language from point to transom')
    K.change('The Sear repeater sits in a forged casemate on a raised seat at station 14 percent, three barrels in one rotary cluster, all firing each volley',
             'designs.md table (autocannon F, 3 shots, station 14 percent); the concept draws the casemate further aft (about 25 percent) and the table wins; the seat levels the narrow ridge so the casemate sits on structure, not on the facets')
    K.change('One spark flak pair on forged strakes at the deck edges at station 60 percent, not the beauty\'s four small tubs',
             'designs.md "Picture slips": the table\'s one flak pair governs; 3 shots over the pair\'s 4 barrels, both fire every volley (weapon_match SPLIT, S8\'s convention)')
    K.change('Three radiator spires at 68 / 76 / 84 percent on the spine block, tallest 0.64 in the middle, not the beauty\'s four',
             'designs.md "Picture slips" (3 spires); heights about 70 percent of the table\'s 0.9 as the family\'s spires were scaled (R331: "scale down the giant radiator/orange towers on each ship")')
    K.change('The hull is widest 1.5 at 72 percent and about 0.47 deep, wider than the concept\'s top view draws it',
             'designs.md table (6.5 / 1.5, widest at 72 percent) outranks the picture, which reads nearer 1.1 wide')
    K.change('The worked-iron spike on the spearhead\'s ridge and the flank trim race are shared broken_stripe runs, broken round the casemate and the boarding doors; hull-tone iron race, worked-iron inlay',
             'the concept\'s bright blade line on the bow and the R443 stripe method; the Picket v2 lesson: added fittings in hull tones, sitting on hull structure')
    K.change('The cooler cassettes either side of the spine block and the removable belly covers are the shared hull methods (slatted_cassette, belly_cover)',
             'the concept\'s grilles round the spire base and the brief\'s 1888 methods; the concept shows no underside, so the belly trunk is designed here')
    K.change('Two bells 0.55 across at offsets 0.4 on riveted drums, glowing ember, no flame plume',
             'designs.md table; in game the bells glow ember and the game draws the plume (ships.md 0.2 (5))')
    K.change('The breaks: the spearhead root (B-1, 30 percent), the drive section (B-2), a lengthwise tear along the lower band facet (B-3) and the spire line as one piece (B-4)',
             'designs.md "Breaks: lengthwise along the band; spire line snaps as one piece"; the transverse breaks keep each long seam inside one compartment')
    K.change('Attitude thrusters, deck hatches, a hoist head, boarding doors, ember gallery slits, aft louvres and frost running points added',
             'a ship in space needs thrusters, access and boarding points; every part has a job (R221)')
    K.open_item('The belly is designed here; the concept shows no underside')
    K.open_item('Frost-white markings and the half-sun crest are paint (the Sunward stack), not modelled')


INV_NOTES = {}
