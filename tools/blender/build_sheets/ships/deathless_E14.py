# deathless_E14: the Eclipse flare, the annulus destroyer (class Destroyer, 9.5 world units). Issue 739, Eclipse build sheets.
# Accepted picture: contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg and _sheet.jpg (Ryan, Nov 12 2026,
# issue 627: "The flare is what I was thinking of for the annulus", the round 1 Annulus direction). data.js d_jackal: gauss T,
# gauss F; ability phase, regen 2, reanimate; speed 3; no hangar.
# Designer of record: Opus (R205, R207); the Board is the final designer (R233, R236): the concept is a base.
# R233 (Ryan, Nov 12: "I agree with your take"): the flare carries ONE CLOSED RING, so from above it never reads as a small
# zenith (E12, the split oval ring round its whole spine). The ring's plane is the study's pick
# (tools/blender/build_sheets/studies/e14_ring_study.py): flat in plan reads as one closed ring from above and from every battle
# camera bearing; upright (the sheet's middle view) reads as a bar from above and a line from the beam.
# Read off the whole concept (R229): the beauty draws the ring big and forward, the gun heart at its centre and the spar running
# far aft behind it to the engine; the sheet's plan draws the ring nearly the ship's length across; the line-up about 0.6 of it.
# The build takes the ring 0.63 of the length across, its bow plate the ship's bow, the spar's tail and stern block behind it.
# +X bow, +Y port, +Z up. Bow (the ring's bow plate) x = +4.75, engine exit x = -4.75.
import math

CODE = 'deathless_E14'
NAME = 'Eclipse flare (the annulus destroyer)'
FACTION = 'Eclipse (deathless)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js d_jackal (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)"
BEAUTY = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg'
KIT = 'eclipse'
CONCEPT_SHEET = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare_sheet.jpg'
# the sheet's plan (left, BOW ON THE LEFT); its "side" is the middle view, which draws the ring upright and edge-on (it does not
# agree with the plan or the beauty): its height ratio is not comparable, said on the sheet
CONCEPT_VIEWS = dict(top=dict(box=(28, 255, 795, 1010), largest=False, flip=False), side=dict(box=(815, 255, 1115, 1010), largest=False, flip=False))
CROPS = [('bow (the ring\'s bow plates, the gun heart and its gun)', (60, 420, 1000, 1180)), ('midships (the core in its cage, the side plates)', (100, 60, 1120, 1000)),
         ('stern (the spar, the aft gun and the engine ring)', (950, 220, 1800, 760))]
SHEET = dict(version=1, round='first sheet (issue 739)', date='2026-11-15', blend='sandbox', before='First full layout',
             before_note='The first complete E14 layout, built with the Eclipse kit and run through the check before any fix.', during='')

XC, ZR = 1.75, 0.0                      # the ring's centre on the spar (and the core) and its plane
R_OUT, R_IN, R_HOOP = 3.0, 2.0, (1.8, 2.06)
NPLATE, GAP = 12, 3.0                   # twelve plates, a narrow even gap (degrees) between them
TH = 0.3                                # plate thickness; the outer rim lifts LIP (a shallow dish)
LIP = 0.06
RCORE = 0.5
PANEL = (0.26, 0.4)                     # the even panel size (R243), as E13

# the aft spar and the stern block (the hull loft): (x, half-beam port, starboard, bottom, top, top chamfer, bottom chamfer), bow first
HULL = [
    (XC - 0.53, 0.22, 0.22, -0.2, 0.2, 0.06, 0.06),      # seated in the core's aft hub collar, clear of its gimbal
    (0.95, 0.34, 0.34, -0.29, 0.31, 0.11, 0.09),
    (-2.3, 0.36, 0.36, -0.3, 0.33, 0.12, 0.1),
    (-2.55, 0.5, 0.5, -0.45, 0.5, 0.16, 0.14),
    (-3.5, 0.55, 0.55, -0.5, 0.55, 0.18, 0.15),
    (-3.6, 0.5, 0.5, -0.45, 0.5, 0.16, 0.14),
]
# the gun heart: a faceted drum from the core's fore hub to the hoop at the bow
DRUM = [
    (3.86, 0.16, 0.16, -0.14, 0.16, 0.05, 0.05),
    (3.55, 0.3, 0.3, -0.24, 0.34, 0.1, 0.08),
    (3.35, 0.4, 0.4, -0.32, 0.46, 0.13, 0.11),
    (2.65, 0.4, 0.4, -0.32, 0.46, 0.13, 0.11),
    (2.45, 0.33, 0.33, -0.28, 0.38, 0.11, 0.09),
    (XC + 0.53, 0.22, 0.22, -0.2, 0.2, 0.06, 0.06),       # seated in the core's fore hub collar
]


def dense(sections, step=0.4):
    import kit as _k
    out = []
    for a, b in zip(sections, sections[1:]):
        n = max(1, int(round((a[0] - b[0]) / step)))
        for i in range(n):
            out.append(tuple(_k.sec_at(sections, a[0] + (b[0] - a[0]) * i / n)))
    out.append(tuple(sections[-1]))
    return out


def ring_xy(theta_deg, r):
    t = math.radians(theta_deg)
    return XC + r * math.cos(t), r * math.sin(t)


def plate_rings(k, n=10):
    """plate k (centred at 30k degrees from the bow, + to port): section rings across its span, each [inner bottom, outer
    bottom, outer top, inner top]; the outer rim lifts LIP so the plate is a shallow dish"""
    c = 360.0 * k / NPLATE; h = 180.0 / NPLATE - GAP / 2
    rings = []
    for i in range(n + 1):
        t = c - h + 2 * h * i / n
        (xi, yi), (xo, yo) = ring_xy(t, R_IN), ring_xy(t, R_OUT)
        rings.append([(xi, yi, ZR - TH / 2), (xo, yo, ZR - TH / 2 + LIP), (xo, yo, ZR + TH / 2 + LIP), (xi, yi, ZR + TH / 2)])
    return rings, c, h


def build(K):
    import kit as _k
    from mathutils import Vector
    EP = _k.HP   # the Eclipse kit (KIT above): its even panels (R243)
    panel_jobs = []

    def rings_of(secs):
        return [[(s[0], y, z) for (y, z) in _k._octa(s[1], s[2], s[3], s[4], s[5], s[6])] for s in secs]

    # ---------------- the aft spar and the stern block (the hull), the gun heart ----------------
    hd = dense(HULL)
    hull = K.hull(hd, 'shade2', shell=0.08)
    K.mass('Hull: the spar and the stern block', hull, 'deep violet plate', note='a slim chamfered spar from the core aft to a faceted stern block')
    panel_jobs.append(('E14_spar', rings_of(hd), list(range(8)), 'spar_plates', ('shade2', 'violet')))
    K.mark('spar', 'hull', ['bevel', 'step', 'overhang'])
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])
    dd = dense(DRUM, 0.3)
    drum = K.loft('E14_drum', dd, 'violet')
    K.mass('Gun heart', drum, 'violet plate', note='the faceted drum on the spar at the ring\'s centre, the forward gun on its roof')
    panel_jobs.append(('E14_drum', rings_of(dd), [0, 2, 3, 4, 5, 6, 7], 'spar_plates', ('violet', 'shade2')))
    K.loft('E14_drum_roof', [(3.25, 0.26, 0.26, 0.42, 0.52, 0.06, 0.0), (3.15, 0.3, 0.3, 0.42, 0.55, 0.08, 0.0), (2.85, 0.3, 0.3, 0.42, 0.55, 0.08, 0.0),
                             (2.75, 0.26, 0.26, 0.42, 0.52, 0.06, 0.0)], 'mauve')
    K.mark('gun_heart', 'tier', ['face', 'roof', 'opening'])
    # spar collars where the struts and the saddle meet it
    for i, x in enumerate((0.95, -0.9, -2.3)):
        K.loft('E14_collar%d' % i, [(x + 0.08, 0.4, 0.4, -0.34, 0.37, 0.13, 0.11), (x - 0.08, 0.4, 0.4, -0.34, 0.37, 0.13, 0.11)], 'mauve')

    # ---------------- the ring: twelve shade plates on one closed hoop (R233) ----------------
    # the hoop: one closed box section under the plates' inner edges, joined to the gun heart at the bow and the spar at the stern
    hoop = []
    m = 72
    for i in range(m + 1):
        t = 360.0 * i / m
        hoop.append([(*ring_xy(t, R_HOOP[0]), ZR - 0.12), (*ring_xy(t, R_HOOP[1]), ZR - 0.12), (*ring_xy(t, R_HOOP[1]), ZR + 0.12), (*ring_xy(t, R_HOOP[0]), ZR + 0.12)])
    K.mass('Hoop', K.loft_rings('E14_hoop', hoop, 'gunv', cap=False), 'violet gunmetal', note='one closed box-section ring under the plates\' inner edges')
    panel_jobs.append(('E14_hoop', hoop[::2], [2], 'ring_plates', ('mauve', 'gunv')))
    K.mark('hoop', 'belt', ['band', 'plate'])
    for k in range(NPLATE):
        rings, c, h = plate_rings(k)
        nm = 'E14_plate_%02d' % k
        ob = K.loft_rings(nm, rings, 'shade')
        if k % 3 == 0:
            K.mass('Ring plate at %d degrees' % c, ob, 'violet-black shade', note='a curved shade slab, its outer rim lifting into a shallow dish')
        panel_jobs.append((nm, rings[::3] + ([rings[-1]] if len(rings) % 3 != 1 else []), [2], 'ring_plates', ('shade', 'shade2')))
        # the stepped second layer: a narrower band on the plate's top, over the middle of its span
        lay = []
        for t in [c - h * 0.72 + 2 * h * 0.72 * i / 6 for i in range(7)]:
            r0, r1 = R_IN + 0.3, R_OUT - 0.22
            z0 = ZR + TH / 2 + LIP * (r0 - R_IN) / (R_OUT - R_IN); z1 = ZR + TH / 2 + LIP * (r1 - R_IN) / (R_OUT - R_IN)
            (x0, y0), (x1, y1) = ring_xy(t, r0), ring_xy(t, r1)
            lay.append([(x0, y0, z0 - 0.01), (x1, y1, z1 - 0.01), (x1, y1, z1 + 0.045), (x0, y0, z0 + 0.045)])
        K.loft_rings(nm + '_layer', lay, 'shade2')
        # the corona line along the plate's outer rim, and along its layer's outer rim
        K.strip(nm + '_corona', [(*ring_xy(t, R_OUT - 0.03), ZR + TH / 2 + LIP + 0.004) for t in [c - h + 2 * h * i / 10 for i in range(1, 10)]], w=0.03, t=0.018)
        K.strip(nm + '_corona_layer', [(r[2][0], r[2][1], r[2][2] + 0.003) for r in lay[1:-1]], w=0.022, t=0.014)
        K.built.append(dict(id='plate_%02d' % k, kind='shade', inv=['ring'], shaped=True, detailed=True, subs=['band', 'corona', 'layer', 'plate']))

    # ---------------- the spokes: the hoop carried to the gun heart at the beams (R207) ----------------
    for i, th in enumerate((65.0, 115.0, -65.0, -115.0)):
        side = 1 if th > 0 else -1
        fwd = math.cos(math.radians(th)) > 0
        xa = XC + (0.74 if fwd else -0.74)
        ya = side * abs(_k.sec_at(DRUM if fwd else HULL, xa)[1])
        bx, by = ring_xy(th, R_HOOP[0] + 0.02)
        K.strut('S%d' % (i + 1), (xa, ya - side * 0.02, ZR), (bx, by, ZR), w=0.18, r=0.03, up=(0, 0, 1), src='designed', inv='spokes',
                note='truss spoke from the %s to the hoop, %s' % ('gun heart' if fwd else 'spar', 'port' if side > 0 else 'starboard'))

    # ---------------- the core and its broken cage ----------------
    K.core('C1', (XC, 0.0, ZR), RCORE, inv='core', note='the trapped light core at the ring\'s centre, the spar entering its hub collars')
    for j, a in enumerate((30.0, 90.0, 150.0, 210.0, 270.0, 330.0)):
        rings = []
        for i in range(9):
            t = math.radians(a - 19 + 38 * i / 8)
            c_, s_ = math.cos(t), math.sin(t)
            rings.append([(XC + xx, rr * c_, ZR + rr * s_) for xx, rr in ((0.52, 0.64), (0.52, 0.72), (-0.52, 0.72), (-0.52, 0.64))])
        rings = [[r[q] for r in rings] for q in range(4)]   # sections along x: [fore inner, fore outer, aft outer, aft inner] rows
        sec = [[rings[0][i], rings[1][i], rings[2][i], rings[3][i]] for i in range(9)]
        K.loft_rings('E14_cage_%d' % j, sec, 'shade')
        # its thickness step and the webs that seat it on the hub collars
        step = [[(p[0] * 0.7 + XC * 0.3, p[1] * (0.76 / 0.72) if q in (1, 2) else p[1], p[2] * (0.76 / 0.72) if q in (1, 2) else p[2]) for q, p in enumerate(s)] for s in sec[2:7]]
        K.loft_rings('E14_cage_%d_step' % j, step, 'shade2')
        for xx in (0.53, -0.53):
            web = []
            for i in (0, 4, 8):
                t = math.radians(a - 19 + 38 * i / 8); c_, s_ = math.cos(t), math.sin(t)
                web.append([(XC + xx + 0.02, 0.24 * c_, 0.24 * s_), (XC + xx + 0.02, 0.66 * c_, 0.66 * s_), (XC + xx - 0.02, 0.66 * c_, 0.66 * s_), (XC + xx - 0.02, 0.24 * c_, 0.24 * s_)])
            K.loft_rings('E14_cage_%d_web%s' % (j, 'f' if xx > 0 else 'a'), web, 'gunv')
        K.built.append(dict(id='cage_%d' % j, kind='feather', inv=['cage'], shaped=True, detailed=True, subs=['blade', 'step']))

    # ---------------- weapons, by data.js slot ----------------
    K.gun('F1', (3.0, 0.0, 0.55), 0, 3, barrels=2, cal=0.055, blen=1.0, size=0.6, slot='F', weapon='gauss', inv='fwd_gun',
          note='the forward null cannon (gauss F) on the gun heart\'s roof, turning only through the data arc F (60 either side of the bow), firing over the ring\'s bow plates')
    sad = K.loft('E14_saddle', [(-1.35, 0.18, 0.18, 0.2, 0.38, 0.06, 0.0), (-1.55, 0.4, 0.4, 0.18, 0.47, 0.12, 0.03), (-2.15, 0.4, 0.4, 0.18, 0.47, 0.12, 0.03),
                                (-2.35, 0.18, 0.18, 0.2, 0.38, 0.06, 0.0)], 'violet')
    K.mass('Saddle, aft gun', sad, 'violet plate', note='the stepped saddle the aft gun stands on')
    K.mark('saddle', 'pylon', ['web', 'plate'])
    K.gun('T1', (-1.85, 0.0, 0.47), 0, 4, barrels=2, cal=0.055, blen=1.0, size=0.6, slot='T', weapon='gauss', inv='aft_gun',
          note='the aft null cannon (gauss T) on its saddle aft of the ring, firing over the ring and turning all round')

    # ---------------- the engine ----------------
    K.engine('E1', (-4.75, 0.0, 0.03), 0.45, 0.56, bell=1.2, body_r=0.47, rings=3, nose='flat', inv='engine', src='picture', kw=dict(struts=12, seg=32),
             note='the broad eclipse ring of pale light at the stern, larger than the mote\'s; no flame')

    # ---------------- fittings ----------------
    def chamfer_pt(secs, x, side, lower=True):
        s = _k.sec_at(secs, x)
        hw = s[1]; zb, zt, ct, cb = s[3], s[4], s[5], s[6]
        a, b = ((hw, zb + cb), (hw - cb, zb)) if lower else ((hw, zt - ct), (hw - ct, zt))
        n = Vector((0, abs(a[1] - b[1]), (-1 if lower else 1) * abs(b[0] - a[0]))).normalized()
        return (x, side * (a[0] + b[0]) / 2, (a[1] + b[1]) / 2), (0, side * n.y, n.z)
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p_, n_ = chamfer_pt(DRUM, 3.45, side)
        K.thruster('Q1' + sn, p_, n_, r=0.14, inv='nose_thrusters', note='gun heart lower chamfer, firing down and out under the ring')
        p_, n_ = chamfer_pt(HULL, -3.38, side)
        K.thruster('Q2' + sn, p_, n_, r=0.17, inv='stern_thrusters', note='stern block lower chamfer, firing down and out')
        for j, x in enumerate((-2.85, -3.3)):
            K.lamp('L%d%s' % (j, sn), (x, side * _k.sec_at(HULL, x)[1], 0.22), (0, side, 0), inv='lamps', note='corona strip light on the stern block flank', up=(1, 0, 0))
        K.vent('V1' + sn, (-2.9, side * _k.sec_at(HULL, -2.9)[1], -0.2), (0, side, 0), 0.32, 0.2, slats=4, inv='vents', note='heat slot panel low on the block flank')
        K.hatch('H1' + sn, (-2.95, side * 0.18, -0.5), (0, 0, -1), 0.2, inv='hatches', note='belly hatch on the stern block')
    for j, a in enumerate((45.0, 135.0, 225.0, 315.0)):
        x, y = ring_xy(a, (R_HOOP[0] + R_IN) / 2 - 0.02)
        K.hatchbox('D%d' % (j + 1), (x, y, ZR + 0.12), 0.14, 0.22, 0.1, yaw=a + 90, inv='drone_docks', note='repair drone cradle on the hoop, in the gap under the plates\' inner edge')
        K.lamp('DL%d' % (j + 1), (x, y, ZR + 0.12 + 0.1), (0, 0, 1), inv='drone_lights', note='the drone\'s green work light', up=(math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        K.allow_touch('D%d' % (j + 1), 'DL%d' % (j + 1), 'the drone\'s light sits on its cradle')

    # ---------------- the even panels, after every mount has claimed its keep-out ----------------
    for name, rings, faces, inv_id, mats in panel_jobs:
        EP.lay_panels(K, name, rings, faces, inv_id, size=PANEL, thick=0.024, gap=0.024, mats=mats, band=3)

    # ---------------- colour zones ----------------
    K.colour('violet-black shade plates, deep violet spar and gun heart (paint stage)', 4.75, -4.75, 'whole ship')
    K.colour('green-white corona line', 4.75, -1.25, 'every ring plate\'s outer rim and its layer\'s rim')
    K.colour('core light', 2.3, 1.2, 'the core in its cage')
    K.colour('drone lights, green', 4.0, -0.5, 'the four drone cradles on the hoop')

    # ---------- INSIDE ----------
    for nm_, z_, x0, x1 in (('block', 0.02, -2.6, -3.55), ('spar', -0.02, 1.0, -2.25)):
        secs = []
        for x in (x0, (x0 + x1) / 2, x1):
            s_ = _k.sec_at(HULL, x); hw = s_[1] - 0.13
            secs.append((x, hw, hw, z_ - 0.025, z_ + 0.025, 0, 0))
        K.loft('in_deck_' + nm_, secs, 'darkdeck', inside=True)
        K.inside.append(dict(kind='deck', name=nm_, z=z_, x=(x1, x0)))
    for i, x in enumerate((0.4, -1.0, -2.6, -3.0, -3.4)):
        s_ = _k.sec_at(HULL, x)
        K.loft('in_bh_F%d' % i, [(x + 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06)),
                                 (x - 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06))], 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='F%d' % i, x=x))
    for i, x in enumerate((3.3, 2.7)):
        s_ = _k.sec_at(DRUM, x)
        K.loft('in_bh_D%d' % i, [(x + 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06)),
                                 (x - 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06))], 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='D%d' % i, x=x))
    K.room('capacitor_bank', 'machinery', 2.72, 3.25, -0.22, 0.22, -0.18, 0.05, note='the forward gun\'s capacitor bank, in the gun heart')
    K.room('fwd_magazine', 'magazine', 2.72, 3.25, -0.18, 0.18, 0.1, 0.3, note='the forward gun\'s magazine, under it')
    K.room('conduits', 'machinery', -2.2, 1.0, -0.15, 0.15, -0.2, -0.07, note='power conduits from the core along the spar\'s keel')
    K.room('aft_magazine', 'magazine', -2.15, -1.55, -0.17, 0.17, 0.03, 0.19, note='the aft gun\'s magazine, under its saddle')
    K.room('dark_decks', 'darkdeck', -1.45, 0.3, -0.17, 0.17, 0.03, 0.19, note='dark decks: the machine crew along the spar, unlit')
    K.room('archive_vault', 'archive', -3.0, -2.62, -0.3, 0.3, 0.06, 0.34, note='the archive vault in the stern block')
    K.room('repair_bay', 'machinery', -3.0, -2.62, -0.3, 0.3, -0.3, -0.02, note='the repair drones\' stores and the regeneration plant (data.js regen 2)')
    K.room('engine_room', 'engroom', -3.45, -3.05, -0.32, 0.32, -0.3, 0.34, note='the engine room and the drive\'s feed')
    K.inside.append(dict(kind='space', name='core', mat='ecore', x=(XC - 0.37, XC + 0.37), y=(-0.37, 0.37), z=(ZR - 0.37, ZR + 0.37),
                         note='the core of trapped light, in the open at the ring\'s centre (hp_core)'))
    K.armour('ring plates (the shade)', 0.3, 'the thickest armour, flat round the heart')
    K.armour('gun heart', 0.14, '')
    K.armour('spar', 0.08, 'thin; the ring shades it from ahead')
    K.armour('stern block', 0.16, '')
    K.break_line('B-1', XC, 'the spar parts at the core: the cage bursts, the gun heart and the ring\'s fore half tear away, the hoop torn across (a ragged bite where the core goes)',
                 path=[(XC + 0.3, 3.4), (XC + 0.3, 2.3), (XC - 0.15, 1.5), (XC + 0.25, 0.6), (XC - 0.2, 0.0), (XC + 0.2, -0.7), (XC - 0.25, -1.6), (XC + 0.1, -2.4), (XC + 0.1, -3.4)])
    K.break_line('B-2', -2.42, 'the stern block tears from the spar, opening the archive vault and the engine room',
                 path=[(-2.36, 1.2), (-2.36, 0.5), (-2.5, 0.2), (-2.38, -0.15), (-2.5, -0.5), (-2.5, -1.2)])
    K.inside.append(dict(kind='note', name='insides', note='Eclipse breaks in layers (factions.md): the ring\'s plates peel away first as the hoop tears, then the bare spar parts at the core and the block tears away; full interiors throughout (R215), hidden until a piece breaks.'))
    K.point('core', 'hp_core', (XC, 0, ZR))
    # three breach anchors (Destroyer base 3, Eclipse +0): prow and mid on the ring's plates (the shade's bands), eng on the block
    def plate_top(th, r):
        x, y = ring_xy(th, r)
        return (x, y, ZR + TH / 2 + LIP * (r - R_IN) / (R_OUT - R_IN) + 0.002)
    K.point('breach', 'hp_breach_0', plate_top(20.0, 2.35), side='port', section='prow', note='on the ring\'s bow quarter plate')
    K.point('breach', 'hp_breach_1', plate_top(-90.0, 2.3), side='stbd', section='mid', note='on the ring\'s starboard beam plate')
    K.point('breach', 'hp_breach_2', (-3.1, 0.25, 0.552), side='port', section='eng', note='on the stern block\'s roof (no shade plate reaches the engine third)')
    for i, side in enumerate((1, -1)):
        p_, n_ = chamfer_pt(DRUM, 3.45, side)
        K.point('rcs', 'hp_rcs_%d' % i, p_, side='port' if side > 0 else 'stbd')
    for i, side in enumerate((1, -1)):
        K.point('board', 'hp_board_%d' % i, (-0.5, side * _k.sec_at(HULL, -0.5)[1], 0.0), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (the designer's calls, R207, R233, R236) ----------
    K.change('One closed ring, lying flat in plan round the gun heart (R233)', 'Ryan, Nov 12: "I agree with your take": from above the flare never reads as a small zenith (the split oval ring). The study (studies/e14_ring_study.py) found flat reads as one closed ring from above and from every battle camera bearing; the sheet\'s upright ring reads as a bar from above')
    K.change('The ring is 6.0 across, 0.63 of the length, its bow plate the ship\'s bow, the spar and stern block behind it', 'between the beauty (a big forward ring) and the line-up (about 0.6 of the length); the sheet\'s plan draws it nearly the ship\'s length, which would put the ring round the whole ship as on the zenith')
    K.change('Twelve plates on one closed hoop, joined to the gun heart at the bow and the spar at the stern, four truss spokes at the beams', 'R207: the picture\'s plates float in a broken circle; a built ring needs a structure, and the closed hoop is the ring R233 asks for')
    K.change('The forward gun is the null cannon on the gun heart\'s roof, turning only through the data arc F', 'data.js gauss F; the game shows gauss as the null cannon on a turret (tools/blender/build_sheets/weapon_match.py FITS), so a fixed recessed housing (designs.md) would fail the weapon match. It rests on the bow and turns 60 either side, as the game turns an F weapon')
    K.change('The aft gun is the null cannon on a stepped saddle aft of the ring (data.js gauss T)', 'designs.md and the beauty: a low housing on the spar\'s dorsal line aft of the ring; it fires over the ring\'s plates')
    K.change('The core is green-white, in a broken cage of six small curved shade plates', 'designs.md conforms the beauty\'s teal to green (R204); the cage plates leave gaps the light shows through')
    K.change('The repair drones are docked on the hoop, each cradle with a green work light', 'the picture shows drones hovering in the ring\'s gaps; a built ship carries them docked, and every part sits on the ship')
    K.change('The spar is a layered beam 0.72 across behind the core, collared where the spokes and the saddle meet it', 'the beauty draws a heavy spar body running aft to the engine; a rod as thin as the zenith\'s spine (E12) read too slight beside a ring this big')
    K.change('From above the flare is one closed ring with the gun heart at its centre and a tail behind it (the spar, the aft gun, the stern block and the engine)', 'family distinctness (R233): the zenith\'s split oval rings its whole spine and has no tail; the mote is a leaf of blades; the flagship a crescent')
    K.change('Engines are eclipse rings, not flame', 'factions.md: "no flaming bells. An eclipse ring of pale light"')
    K.change('Panels dead even, aligned rows on every face, tone in ordered bands (R243)', 'Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels)')
    K.change('Thrusters, belly hatches, heat panels and corona strip lights added', 'a ship in space needs thrusters; the picture shows no underside')
    K.change('The third breach anchor sits on the stern block\'s roof', 'the class table needs one in the engine third; no shade plate reaches it')
    K.open_item('The underside of the gun heart, the ring and the block is designed here; the picture shows no underside')
    # ---------- the fit report's fix column: every finding on the first full layout ----------
    K.fix('Q2s (stern thruster) against V1s (heat panel)', 'the stern thrusters moved aft to 3.38 and the heat panels forward to 2.9')
    K.fix('D1 to D4 (drone cradles) against DL1 to DL4 (their lights), and the lights with no mount on the hull', 'each light is mounted on its own cradle on purpose (an allowed touch, as a part on a part)')
