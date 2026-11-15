# deathless_E14: the Eclipse flare, the glass cannon (class Destroyer, 9.5 world units). Issue 739 (first sheet), issue 782 (this
# redesign). Accepted picture: contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg and _sheet.jpg (Ryan,
# Nov 12 2026, issue 627: "The flare is what I was thinking of for the annulus", the round 1 Annulus direction).
# R256 (Ryan, Nov 15 2026 07:02, on the first sheet's flat ring): "it's changing the core structure which I don't love. Now the
# ring is horizontal instead of vertical, which changes the entire ship. Is there a way we can be clever here", then "Can we
# find a way to make it built around one larger gun and that's the center of the ring? Like a glass cannon basically". So the
# ring stands upright and faces forward as in the concept, the ship runs through its middle, and the ship is built round one
# big fixed gun whose muzzle is the glowing aperture at the ring's centre: the ring is that gun's focusing ring.
# data.js d_jackal after issue 784 (branch opus/issue-784, the rules half of R256): one null lance, nlance F, the gauss kind;
# ability phase, regen 2, reanimate; speed 3; no hangar. This branch merges 784's; main's data.js lists gauss T and gauss F until it merges.
# Designer of record: Opus (R205, R207); the Board is the final designer (R233, R236): the concept is a base.
# +X bow, +Y port, +Z up. Bow (the lance's muzzle lip) x = +4.75, engine exit x = -4.75. The ring stands in the Y-Z plane.
import math

CODE = 'deathless_E14'
NAME = 'Eclipse flare (the glass cannon)'
FACTION = 'Eclipse (deathless)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js d_jackal (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)"
BEAUTY = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg'
KIT = 'eclipse'
CONCEPT_SHEET = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare_sheet.jpg'
# the sheet's middle view draws the ring upright and edge-on from the beam, as built here, so its height now compares; its left
# view draws the ring face-on with the spar across it (a plan of a flat ring), kept as the plan crop for the length only
CONCEPT_VIEWS = dict(top=dict(box=(28, 255, 795, 1010), largest=False, flip=False), side=dict(box=(815, 255, 1115, 1010), largest=False, flip=False))
CROPS = [('bow (the ring, the lance\'s muzzle at its centre)', (60, 420, 1000, 1180)), ('midships (the core in its cage, the spar)', (100, 60, 1120, 1000)),
         ('stern (the spar, the dorsal housing and the engine ring)', (950, 220, 1800, 760))]
SHEET = dict(version=2, round='redesign, the upright ring and the glass cannon (issue 782, R256)', date='2026-11-15', blend='sandbox',
             before='First full layout of the redesign', tq_zoom=0.72,
             before_note='The first complete upright E14 layout, built with the Eclipse kit and run through the check before any fix.', during='')

XR = 3.4                                 # the ring's plane (its depth runs XR - D/2 to XR + D/2), on the ship's axis
D = 0.8                                  # the ring's depth along the ship: edge-on from the beam it is a band this wide
R_OUT, R_IN, R_HOOP = 3.0, 2.0, (1.8, 2.06)
NPLATE, GAP = 12, 5.0                    # twelve chunky plates, a clear even gap (degrees) between them (R266: never one smooth band)
LIP = 0.1                                # the plate's outer rim reaches forward LIP (a shallow dish facing the enemy)
CH = 0.1                                 # the chamfer on the rim's front and back edges, where the corona lines run
XC, RCORE = 2.0, 0.5                     # the core, just aft of the ring
XL, LL, RL = 3.3, 1.45, 0.55             # the null lance: root on the gun heart's face, length, housing radius
XS, XH = 2.86, 3.2                       # the spokes run from the focus collar on the gun heart (XS) out to the hoop (XH)
PANEL = (0.26, 0.4)                      # the even panel size (R243), as E13

# the spar and the stern block (the hull loft): (x, half-beam port, starboard, bottom, top, top chamfer, bottom chamfer), bow first
# R266 (Ryan: "the body being too thin with it just looking like a stick is a big one"): a chunky faceted body in steps, about
# the beauty's mass: 1.0 across behind the core, 1.12 from midships, the stern block 1.44
HULL = [
    (XC - 0.53, 0.22, 0.22, -0.2, 0.2, 0.06, 0.06),      # seated in the core's aft hub collar, clear of its gimbal
    (1.25, 0.4, 0.4, -0.38, 0.4, 0.15, 0.13),
    (1.05, 0.5, 0.5, -0.46, 0.5, 0.2, 0.17),             # the first step
    (-0.9, 0.5, 0.5, -0.46, 0.5, 0.2, 0.17),
    (-1.0, 0.56, 0.56, -0.5, 0.54, 0.21, 0.18),          # the second step
    (-2.25, 0.56, 0.56, -0.5, 0.54, 0.21, 0.18),
    (-2.4, 0.68, 0.68, -0.6, 0.66, 0.24, 0.2),           # the stern block
    (-3.5, 0.72, 0.72, -0.64, 0.7, 0.25, 0.21),
    (-3.62, 0.62, 0.62, -0.56, 0.6, 0.22, 0.18),
]
# the gun heart: the lance's breech casing, from the core's fore hub to the lance's seat inside the ring; regular octagons, so
# from ahead it reads round like the beauty's heart, never a box
DRUM = [
    (XL, 0.66, 0.66, -0.66, 0.66, 0.39, 0.39),
    (2.98, 0.94, 0.94, -0.94, 0.94, 0.55, 0.55),          # the forward shoulder carries the core windows (R266)
    (2.75, 0.94, 0.94, -0.94, 0.94, 0.55, 0.55),
    (2.62, 0.6, 0.6, -0.6, 0.6, 0.35, 0.35),
    (XC + 0.53, 0.22, 0.22, -0.2, 0.2, 0.06, 0.06),       # seated in the core's fore hub collar
]
COLLAR = [(XS + 0.07, 1.02, 1.02, -1.02, 1.02, 0.6, 0.6), (XS - 0.07, 1.02, 1.02, -1.02, 1.02, 0.6, 0.6)]


def dense(sections, step=0.4):
    import kit as _k
    out = []
    for a, b in zip(sections, sections[1:]):
        n = max(1, int(round((a[0] - b[0]) / step)))
        for i in range(n):
            out.append(tuple(_k.sec_at(sections, a[0] + (b[0] - a[0]) * i / n)))
    out.append(tuple(sections[-1]))
    return out


def rp(x, r, t_deg):
    """a point at station x, radius r, angle t (degrees from +Y, port, toward +Z, up) in the ring's plane"""
    t = math.radians(t_deg)
    return (x, r * math.cos(t), r * math.sin(t))


def x_front(r):
    """the plate's front face at radius r: it reaches forward LIP from the inner edge to the rim's chamfer (a shallow dish)"""
    return XR + D / 2 + LIP * max(0.0, min(1.0, (r - R_IN) / (R_OUT - CH - R_IN)))


def plate_rings(k, n=10):
    """plate k (centred at 30k degrees from port, toward up): section rings across its span, each six points round the
    plate's section in (radius, x): inner aft, outer aft, the rim (back chamfer, front chamfer), outer fore, inner fore.
    Faces: 0 the back, 1 the back chamfer, 2 the outer rim, 3 the front chamfer, 4 the front (the dish), 5 the inner edge."""
    c = 360.0 * k / NPLATE; h = 180.0 / NPLATE - GAP / 2
    xa, xf = XR - D / 2, XR + D / 2 + LIP
    sec = [(R_IN, xa), (R_OUT - CH, xa), (R_OUT, xa + CH), (R_OUT, xf - CH), (R_OUT - CH, xf), (R_IN, XR + D / 2)]
    rings = []
    for i in range(n + 1):
        t = c - h + 2 * h * i / n
        rings.append([rp(x, r, t) for (r, x) in sec])
    return rings, c, h


def build(K):
    import kit as _k
    from mathutils import Vector
    EP = _k.HP   # the Eclipse kit (KIT above): its even panels (R243)
    panel_jobs = []

    def rings_of(secs):
        return [[(s[0], y, z) for (y, z) in _k._octa(s[1], s[2], s[3], s[4], s[5], s[6])] for s in secs]

    # ---------------- the spar and the stern block (the hull), the gun heart ----------------
    hd = dense(HULL)
    hull = K.hull(hd, 'shade2', shell=0.08)
    K.mass('Hull: the spar and the stern block', hull, 'deep violet plate', note='a slim chamfered spar from the core aft to a faceted stern block')
    panel_jobs.append(('E14_spar', rings_of(hd), list(range(8)), 'spar_plates', ('shade2', 'violet')))
    K.mark('spar', 'hull', ['bevel', 'step', 'overhang'])
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])
    dd = dense(DRUM, 0.3)
    drum = K.loft('E14_drum', dd, 'violet')
    K.mass('Gun heart', drum, 'violet plate', note='the lance\'s faceted breech casing from the core forward through the ring\'s centre, the lance on its face')
    panel_jobs.append(('E14_drum', rings_of(dd), [0, 2, 4, 6], 'spar_plates', ('violet', 'shade2')))
    # the focus collar the spokes land on, just behind the ring
    col = K.loft('E14_focus_collar', COLLAR, 'mauve')
    K.mass('Focus collar', col, 'mauve band', note='the band round the gun heart just behind the ring where the four spokes land')
    # the core windows (R266: the core's glow seen from ahead): four armoured ports on the heart's forward shoulder, onto the
    # light the heart carries from the core to the lance
    for j, a in enumerate((0.0, 90.0, 180.0, 270.0)):
        n_ = (0.66, 0.75 * math.cos(math.radians(a)), 0.75 * math.sin(math.radians(a)))
        K.corewin('W%d' % (j + 1), rp(3.14, 0.8, a), n_, 0.12, inv='core_windows', note='core window on the gun heart\'s forward shoulder, lit from ahead')
    K.mark('gun_heart', 'tier', ['face', 'roof', 'opening'])
    # body collars at the steps, and the layered flank armour and keel (R266: a stepped, plated body, never a rod)
    for i, (x, hw, zb, zt) in enumerate(((1.0, 0.56, -0.52, 0.56), (-0.95, 0.62, -0.56, 0.6))):
        K.loft('E14_collar%d' % i, [(x + 0.07, hw, hw, zb, zt, 0.22, 0.19), (x - 0.07, hw, hw, zb, zt, 0.22, 0.19)], 'mauve')
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for j, (x0, x1, hw) in enumerate(((0.85, -0.8, 0.5), (-1.12, -2.12, 0.56))):
            K.loft('E14_flank%s%d' % (sn, j), [(x0, 0.05, 0.05, -0.26, 0.28, 0.04, 0.04, side * (hw + 0.02)), (x0 - 0.08, 0.06, 0.06, -0.3, 0.32, 0.05, 0.05, side * (hw + 0.03)),
                                               (x1 + 0.08, 0.06, 0.06, -0.3, 0.32, 0.05, 0.05, side * (hw + 0.03)), (x1, 0.05, 0.05, -0.26, 0.28, 0.04, 0.04, side * (hw + 0.02))], 'violet')
            K.loft('E14_flank%s%d_step' % (sn, j), [(x0 - 0.2, 0.04, 0.04, -0.14, 0.16, 0.03, 0.03, side * (hw + 0.09)), (x1 + 0.2, 0.04, 0.04, -0.14, 0.16, 0.03, 0.03, side * (hw + 0.09))], 'mauve')
    K.loft('E14_keel', [(0.8, 0.12, 0.12, -0.56, -0.4, 0.0, 0.05), (0.65, 0.26, 0.26, -0.6, -0.4, 0.0, 0.08), (-2.0, 0.28, 0.28, -0.64, -0.44, 0.0, 0.08),
                        (-2.2, 0.14, 0.14, -0.6, -0.44, 0.0, 0.05)], 'shade2')
    K.mark('flank_armour', 'hull', ['bevel', 'step', 'overhang'])

    # ---------------- the ring: twelve shade plates on one closed hoop, upright, facing the enemy (R233, R256) ----------------
    hoop = []
    m = 72
    for i in range(m + 1):
        t = 360.0 * i / m
        hoop.append([rp(XR - 0.26, R_HOOP[0], t), rp(XR - 0.26, R_HOOP[1], t), rp(XR + 0.26, R_HOOP[1], t), rp(XR + 0.26, R_HOOP[0], t)])
    K.mass('Hoop', K.loft_rings('E14_hoop', hoop, 'gunv', cap=False), 'violet gunmetal', note='one closed box-section ring under the plates\' inner edges')
    panel_jobs.append(('E14_hoop', hoop[::2], [2], 'ring_plates', ('mauve', 'gunv')))
    K.mark('hoop', 'belt', ['band', 'plate'])
    for k in range(NPLATE):
        rings, c, h = plate_rings(k)
        nm = 'E14_plate_%02d' % k
        ob = K.loft_rings(nm, rings, 'shade')
        if k % 3 == 0:
            K.mass('Ring plate at %d degrees' % c, ob, 'violet-black shade', note='a deep curved shade block, its front a shallow dish, its rim chamfered fore and aft')
        sub = rings[::3] + ([rings[-1]] if len(rings) % 3 != 1 else [])
        panel_jobs.append((nm, sub, [0, 2, 4], 'ring_plates', ('shade', 'shade2')))
        # the relief (R266: "ring too plain"): on the front face an inner and an outer armour block, each its own height, the
        # outer one stepped again, and a raised band round the rim; the same on every plate (ordered, R243)
        for j, (r0, r1, hgt, fr, mat) in enumerate(((R_IN + 0.1, R_IN + 0.42, 0.07, 0.7, 'shade2'), (R_IN + 0.5, R_OUT - CH - 0.08, 0.11, 0.8, 'shade2'),
                                                    (R_IN + 0.58, R_OUT - CH - 0.2, 0.17, 0.5, 'shade'))):
            blk = []
            for t in [c - h * fr + 2 * h * fr * i / 6 for i in range(7)]:
                blk.append([rp(x_front(r0) - 0.01, r0, t), rp(x_front(r1) - 0.01, r1, t), rp(x_front(r1) + hgt, r1 - 0.02, t), rp(x_front(r0) + hgt, r0 + 0.02, t)])
            K.loft_rings(nm + '_layer%d' % j, blk, mat)
        band = []
        for t in [c - h * 0.6 + 2 * h * 0.6 * i / 8 for i in range(9)]:
            band.append([rp(XR - 0.2, R_OUT - 0.01, t), rp(XR - 0.18, R_OUT + 0.05, t), rp(XR + 0.18, R_OUT + 0.05, t), rp(XR + 0.2, R_OUT - 0.01, t)])
        K.loft_rings(nm + '_band', band, 'shade2')
        # the corona lines (factions.md: the thin green-white ring at the rim): along the rim's front and back edges, so
        # edge-on the ring reads as a band between two bright lines, and down both sides of the plate's front face, so from
        # ahead every plate is outlined in light as the concept draws it
        ts = [c - h + 2 * h * i / 12 for i in range(1, 12)]
        for tag, xe in (('front', XR + D / 2 + LIP - CH - 0.045), ('back', XR - D / 2 + CH + 0.045)):
            pts = [rp(xe, R_OUT + 0.003, t) for t in ts]
            nrm = [(0.0, math.cos(math.radians(t)), math.sin(math.radians(t))) for t in ts]
            K.strip(nm + '_corona_' + tag, pts, w=0.06, t=0.02, normals=nrm)
        for tag, sg in (('side_a', -1), ('side_b', 1)):
            rs = [R_IN + 0.06 + (R_OUT - CH - 0.1 - R_IN - 0.06) * i / 6 for i in range(7)]
            pts = [rp(x_front(r) + 0.004, r, c + sg * (h - math.degrees(0.05 / r))) for r in rs]
            K.strip(nm + '_corona_' + tag, pts, w=0.04, t=0.016, normals=[(1.0, 0.0, 0.0)] * len(pts))
        K.built.append(dict(id='plate_%02d' % k, kind='shade', inv=['ring'], shaped=True, detailed=True, subs=['band', 'corona', 'layer', 'plate']))

    # ---------------- the spokes: the hoop carried to the gun heart's focus collar (R207) ----------------
    ra = math.sqrt(2) * (COLLAR[0][1] - COLLAR[0][5] / 2) - 0.03
    for i, th in enumerate((45.0, 135.0, 225.0, 315.0)):
        K.strut('S%d' % (i + 1), rp(XS, ra, th), rp(XH, R_HOOP[0] + 0.02, th), w=0.18, r=0.03, up=(1, 0, 0), src='designed', inv='spokes',
                note='truss spoke from the focus collar to the hoop, %s' % ('upper' if th < 180 else 'lower') + (' port' if th in (45.0, 315.0) else ' starboard'))

    # ---------------- the core and its broken cage, just aft of the ring ----------------
    K.core('C1', (XC, 0.0, 0.0), RCORE, inv='core', note='the trapped light core behind the ring\'s centre, the spar and the gun heart entering its hub collars')
    for j, a in enumerate((30.0, 90.0, 150.0, 210.0, 270.0, 330.0)):
        rings = []
        for i in range(9):
            t = math.radians(a - 19 + 38 * i / 8)
            c_, s_ = math.cos(t), math.sin(t)
            rings.append([(XC + xx, rr * c_, rr * s_) for xx, rr in ((0.52, 0.64), (0.52, 0.72), (-0.52, 0.72), (-0.52, 0.64))])
        rings = [[r[q] for r in rings] for q in range(4)]
        sec = [[rings[0][i], rings[1][i], rings[2][i], rings[3][i]] for i in range(9)]
        K.loft_rings('E14_cage_%d' % j, sec, 'shade')
        step = [[(p[0] * 0.7 + XC * 0.3, p[1] * (0.76 / 0.72) if q in (1, 2) else p[1], p[2] * (0.76 / 0.72) if q in (1, 2) else p[2]) for q, p in enumerate(s)] for s in sec[2:7]]
        K.loft_rings('E14_cage_%d_step' % j, step, 'shade2')
        for xx in (0.53, -0.53):
            web = []
            for i in (0, 4, 8):
                t = math.radians(a - 19 + 38 * i / 8); c_, s_ = math.cos(t), math.sin(t)
                web.append([(XC + xx + 0.02, 0.24 * c_, 0.24 * s_), (XC + xx + 0.02, 0.66 * c_, 0.66 * s_), (XC + xx - 0.02, 0.66 * c_, 0.66 * s_), (XC + xx - 0.02, 0.24 * c_, 0.24 * s_)])
            K.loft_rings('E14_cage_%d_web%s' % (j, 'f' if xx > 0 else 'a'), web, 'gunv')
        K.built.append(dict(id='cage_%d' % j, kind='feather', inv=['cage'], shaped=True, detailed=True, subs=['blade', 'step']))

    # ---------------- the weapon, by data.js slot: the null lance, the one big gun (issue 784's nlance F) ----------------
    K.spinal('L1', (XL, 0.0, 0.0), LL, r=RL, slot='F', weapon='nlance', inv='lance', kind='lance',
             note='the null lance (data.js nlance F, issue 784): one fixed spinal rail gun on the gun heart\'s face, firing forward through the ring\'s centre; its muzzle, a recessed aperture with a glowing lens and a green focus ring, is the ship\'s bow')

    # ---------------- the dorsal housing on the spar: the lance's capacitor bank ----------------
    cap = K.loft('E14_capbank', [(-0.25, 0.2, 0.2, 0.44, 0.62, 0.06, 0.0), (-0.45, 0.4, 0.4, 0.42, 0.76, 0.13, 0.03), (-2.0, 0.4, 0.4, 0.42, 0.76, 0.13, 0.03),
                                 (-2.2, 0.2, 0.2, 0.44, 0.62, 0.06, 0.0)], 'violet')
    K.mass('Capacitor housing', cap, 'violet plate', note='the stepped dorsal housing aft of the core that stores the lance\'s charge')
    for i, x in enumerate((-0.8, -1.25, -1.7)):
        K.loft('E14_capbank_rib%d' % i, [(x + 0.06, 0.43, 0.43, 0.4, 0.82, 0.14, 0.03), (x - 0.06, 0.43, 0.43, 0.4, 0.82, 0.14, 0.03)], 'mauve')
    K.mark('capbank', 'pylon', ['web', 'plate'])

    # ---------------- the engine ----------------
    K.engine('E1', (-4.75, 0.0, 0.0), 0.5, 0.56, bell=1.2, body_r=0.56, rings=3, nose='flat', inv='engine', src='picture', kw=dict(struts=12, seg=32, halo=1.1),
             note='the broad eclipse ring of pale light at the stern, larger than the mote\'s, and round it the free halo ring of pale light the concept draws at the end of the body (R266); no flame')

    # ---------------- fittings ----------------
    def chamfer_pt(secs, x, side, lower=True):
        s = _k.sec_at(secs, x)
        hw = s[1]; zb, zt, ct, cb = s[3], s[4], s[5], s[6]
        a, b = ((hw, zb + cb), (hw - cb, zb)) if lower else ((hw, zt - ct), (hw - ct, zt))
        n = Vector((0, abs(a[1] - b[1]), (-1 if lower else 1) * abs(b[0] - a[0]))).normalized()
        return (x, side * (a[0] + b[0]) / 2, (a[1] + b[1]) / 2), (0, side * n.y, n.z)
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p_, n_ = chamfer_pt(HULL, 0.55, side)
        K.thruster('Q1' + sn, p_, n_, r=0.14, inv='nose_thrusters', note='spar lower chamfer behind the core, firing down and out, clear of the ring')
        p_, n_ = chamfer_pt(HULL, -3.38, side)
        K.thruster('Q2' + sn, p_, n_, r=0.17, inv='stern_thrusters', note='stern block lower chamfer, firing down and out')
        for j, x in enumerate((-2.85, -3.3)):
            K.lamp('L%d%s' % (j, sn), (x, side * _k.sec_at(HULL, x)[1], 0.22), (0, side, 0), inv='lamps', note='corona strip light on the stern block flank', up=(1, 0, 0))
        K.vent('V1' + sn, (-2.9, side * _k.sec_at(HULL, -2.9)[1], -0.2), (0, side, 0), 0.32, 0.2, slats=4, inv='vents', note='heat slot panel low on the block flank')
        K.hatch('H1' + sn, (-2.95, side * 0.18, _k.sec_at(HULL, -2.95)[3] - 0.04), (0, 0, -1), 0.2, inv='hatches', note='belly hatch on the stern block')
    # the repair drones: four cradles on the hoop's front face between the spokes, each with its green work light
    for j, a in enumerate((0.0, 90.0, 180.0, 270.0)):
        tang = (0.0, -math.sin(math.radians(a)), math.cos(math.radians(a)))
        rad = (0.0, math.cos(math.radians(a)), math.sin(math.radians(a)))
        K._surface_part('D%d' % (j + 1), EP.hatchbox(0.12, 0.22, 0.1, 0), rp(XR + 0.26, 1.86, a), (1, 0, 0), tang, 'drone_docks',
                        'repair drone cradle 0.2 x 0.1', 'hatchbox', 'picture', 'repair drone cradle on the hoop\'s front face, under the plates\' inner edge')
        K.lamp('DL%d' % (j + 1), rp(XR + 0.26 + 0.1, 1.86, a), (1, 0, 0), inv='drone_lights', note='the drone\'s green work light', up=tang)
        K.allow_touch('D%d' % (j + 1), 'DL%d' % (j + 1), 'the drone\'s light sits on its cradle')
    # the light in the ring's open middle (R266, "glow inside the ring"): twelve small lights round the hoop's inner face, one
    # behind each plate, shining in across the middle, and a light strip round the inner face ahead of them
    for j in range(NPLATE):
        a = 360.0 * j / NPLATE
        K.lamp('HL%02d' % j, rp(XR, R_HOOP[0], a), (0.0, -math.cos(math.radians(a)), -math.sin(math.radians(a))), inv='hoop_lights', up=(1, 0, 0),
               note='a light on the hoop\'s inner face, shining into the ring\'s open middle')
    ring_pts = [rp(XR + 0.17, R_HOOP[0] - 0.003, 360.0 * i / 72) for i in range(73)]
    K.strip('E14_hoop_light', ring_pts, w=0.05, t=0.012, normals=[(0.0, -p[1] / R_HOOP[0], -p[2] / R_HOOP[0]) for p in ring_pts])

    # ---------------- the even panels, after every mount has claimed its keep-out ----------------
    for name, rings, faces, inv_id, mats in panel_jobs:
        EP.lay_panels(K, name, rings, faces, inv_id, size=PANEL, thick=0.024, gap=0.024, mats=mats, band=3)

    # ---------------- colour zones ----------------
    K.colour('violet-black shade plates, deep violet spar and gun heart (paint stage)', 4.75, -4.75, 'whole ship')
    K.colour('green-white corona line', XR + D / 2 + LIP, XR - D / 2, 'every ring plate\'s rim, front and back edges, and its layer\'s rim')
    K.colour('lance aperture: the glowing lens and the green focus ring', 4.75, 4.2, 'the lance\'s mouth at the ring\'s centre')
    K.colour('core light', XC + 0.55, XC - 0.55, 'the core in its cage')
    K.colour('drone lights, green', XR + 0.4, XR + 0.2, 'the four drone cradles on the hoop')

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
    for i, x in enumerate((3.15, 2.8)):
        s_ = _k.sec_at(DRUM, x)
        K.loft('in_bh_D%d' % i, [(x + 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06)),
                                 (x - 0.025, s_[1] - 0.12, s_[2] - 0.12, s_[3] + 0.12, s_[4] - 0.12, max(0, s_[5] - 0.06), max(0, s_[6] - 0.06))], 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='D%d' % i, x=x))
    K.room('capacitor_bank', 'machinery', 2.84, 3.12, -0.3, 0.3, -0.3, 0.05, note='the lance\'s breech capacitors, in the gun heart behind the ring')
    K.room('fwd_magazine', 'magazine', 2.84, 3.12, -0.24, 0.24, 0.1, 0.32, note='the lance\'s slug magazine, over the capacitors')
    K.room('conduits', 'machinery', -2.2, 1.0, -0.15, 0.15, -0.2, -0.07, note='power conduits from the core along the spar\'s keel to the capacitor housing')
    K.room('charge_store', 'machinery', -2.15, -0.45, -0.17, 0.17, 0.03, 0.19, note='the charge store under the dorsal capacitor housing')
    K.room('dark_decks', 'darkdeck', -0.35, 0.9, -0.17, 0.17, 0.03, 0.19, note='dark decks: the machine crew along the spar, unlit')
    K.room('archive_vault', 'archive', -3.0, -2.62, -0.3, 0.3, 0.06, 0.34, note='the archive vault in the stern block')
    K.room('repair_bay', 'machinery', -3.0, -2.62, -0.3, 0.3, -0.3, -0.02, note='the repair drones\' stores and the regeneration plant (data.js regen 2)')
    K.room('engine_room', 'engroom', -3.45, -3.05, -0.32, 0.32, -0.3, 0.34, note='the engine room and the drive\'s feed')
    K.inside.append(dict(kind='space', name='core', mat='ecore', x=(XC - 0.37, XC + 0.37), y=(-0.37, 0.37), z=(-0.37, 0.37),
                         note='the core of trapped light, in the open behind the ring\'s centre (hp_core)'))
    K.armour('ring plates (the shade)', 0.8, 'the thickest armour: deep blocks standing across the bow, facing the enemy')
    K.armour('gun heart', 0.14, '')
    K.armour('spar', 0.08, 'thin; the ring shades it from ahead (the glass cannon: data.js hull down, issue 784)')
    K.armour('stern block', 0.16, '')
    K.break_line('B-1', XC, 'the spar parts at the core: the cage bursts, the gun heart, the lance and the ring tear away forward (a ragged bite where the core goes)',
                 path=[(XC + 0.3, 0.95), (XC - 0.15, 0.6), (XC + 0.25, 0.25), (XC - 0.2, 0.0), (XC + 0.2, -0.3), (XC - 0.25, -0.6), (XC + 0.1, -0.95)])
    K.break_line('B-2', -2.42, 'the stern block tears from the spar, opening the archive vault and the engine room',
                 path=[(-2.36, 1.2), (-2.36, 0.5), (-2.5, 0.2), (-2.38, -0.15), (-2.5, -0.5), (-2.5, -1.2)])
    K.inside.append(dict(kind='note', name='insides', note='Eclipse breaks in layers (factions.md): the ring\'s plates peel away first as the hoop tears, then the bare spar parts at the core and the block tears away; full interiors throughout (R215), hidden until a piece breaks.'))
    K.point('core', 'hp_core', (XC, 0, 0))
    # three breach anchors (Destroyer base 3, Eclipse +0) on the shade's bands where it can (factions.md): the ring's port beam
    # plate and its starboard beam plate on their outer rims between the corona lines, and the stern block's roof
    K.point('breach', 'hp_breach_0', (XR + 0.05, R_OUT + 0.002, 0.0), side='port', section='prow', note='on the ring\'s port beam plate, its outer rim')
    K.point('breach', 'hp_breach_1', (XR - 0.05, -R_OUT - 0.002, 0.0), side='stbd', section='mid', note='on the ring\'s starboard beam plate, its outer rim')
    K.point('breach', 'hp_breach_2', (-3.1, 0.25, _k.sec_at(HULL, -3.1)[4] + 0.002), side='port', section='eng', note='on the stern block\'s roof (no shade plate reaches the engine third)')
    for i, side in enumerate((1, -1)):
        p_, n_ = chamfer_pt(HULL, 0.55, side)
        K.point('rcs', 'hp_rcs_%d' % i, p_, side='port' if side > 0 else 'stbd')
    for i, side in enumerate((1, -1)):
        K.point('board', 'hp_board_%d' % i, (-0.5, side * _k.sec_at(HULL, -0.5)[1], 0.0), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (the designer's calls, R207, R233, R236, R256) ----------
    K.change('The ring stands upright across the bow and faces forward, the ship running through its middle (R256)', 'Ryan, Nov 15: the first sheet\'s flat ring "changes the entire ship"; the concept\'s beauty and its middle and right views stand it upright. It is the shade held forward at the enemy (factions.md)')
    K.change('The ring is 0.8 deep along the ship, its front a shallow dish, its rim chamfered fore and aft with a corona line on each edge', 'from the beam the upright ring is exactly edge-on at any camera height, so its depth is the whole band the battle camera sees: 0.8 is about 10 px at the default battle camera, between two bright lines (the Board, issue 782)')
    K.change('One big fixed gun, the null lance, at the ring\'s centre; its muzzle, a recessed aperture with a glowing lens and a green focus ring, is the bow', 'Ryan, Nov 15: "built around one larger gun and that\'s the center of the ring ... like a glass cannon". data.js gives the flare one forward null lance (issue 784); designs.md\'s fixed forward housing with a recessed aperture and focus ring comes back')
    K.change('No second gun: the aft turret of the first sheet is gone; a stepped capacitor housing on the spar stores the lance\'s charge', 'issue 784 trades both null cannons for the one lance (the glass cannon); every visible gun is a data.js slot (R241)')
    K.change('The gun heart is the lance\'s breech casing, from the core forward through the ring\'s centre; four truss spokes carry the hoop to its focus collar', 'R207: the picture\'s plates float; the ring is the lance\'s focusing ring, so it hangs off the gun\'s own heart')
    K.change('The core sits just aft of the ring in its broken cage of six small shade plates, its light seen from the beam and the quarters; from ahead its glow shows through the four core windows on the gun heart\'s shoulder', 'designs.md: core and main gun together at the ring\'s heart; the beauty shows the core lit inside the heart behind the muzzle')
    K.change('The ring is 6.0 across, 0.63 of the length, standing in the forward fifth; the spar and stern block run 7.6 aft of it', 'the beauty draws a big forward ring with the spar running far aft; kept from the first sheet so the class stays the same size on the board')
    K.change('Twelve plates on one closed hoop (R233)', 'R233: one closed ring, never a small zenith; the upright ring cannot read as the zenith\'s split oval round a spine')
    K.change('The repair drones are docked on the hoop\'s front face, each cradle with a green work light', 'the picture shows drones hovering in the ring\'s gaps; a built ship carries them docked, and every part sits on the ship')
    K.change('The body is a chunky faceted beam in steps, 1.0 across behind the core and 1.12 from midships, the stern block 1.44, with layered flank armour, a keel and collars at the steps', 'R266, Ryan: "the body being too thin with it just looking like a stick is a big one"; the beauty draws a heavy plated body about a sixth as wide as it is long')
    K.change('A free halo ring of pale light, 2.2 across, stands round the engine at the far end of the body on four arms', 'R266, Ryan: "bow ring missing": the beauty\'s big glowing ring at the end of the body; it is the engine\'s eclipse ring of light, painted by the stack\'s engine rule')
    K.change('Each ring plate carries its own relief (an inner and an outer armour block, the outer stepped again, a raised rim band) and a corona line down both sides of its face; the gaps between plates are 5 degrees', 'R266, Ryan: "ring too plain": the concept\'s twelve chunky plates, each outlined in light, never one smooth band; the relief is the same on every plate (ordered, R243)')
    K.change('Twelve small lights round the hoop\'s inner face and a light strip ahead of them light the ring\'s open middle; four core windows on the gun heart\'s forward shoulder show the core\'s glow from ahead', 'R266, Ryan: "glow inside the ring": the beauty\'s lit middle; the lights are the faction\'s green-white (R204 conforms the beauty\'s teal to green), not blue-white')
    K.change('The lance\'s bore is 0.94 deep: a liner stepping in three stages, coil bands round each, two green focusing bands and a lit throat round the lens', 'R266, Ryan: "the inside of the lance/gun looks pretty plain"')
    K.change('Engines are eclipse rings, not flame', 'factions.md: "no flaming bells. An eclipse ring of pale light"')
    K.change('Panels dead even, aligned rows on every face, tone in ordered bands (R243)', 'Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels)')
    K.change('Thrusters, belly hatches, heat panels and corona strip lights added', 'a ship in space needs thrusters; the picture shows no underside')
    K.change('The forward thrusters sit under the body behind the core, not at the nose', 'a thruster on the gun heart fires into the ring\'s lower plates')
    K.change('The third breach anchor sits on the stern block\'s roof', 'the class table needs one in the engine third; no shade plate reaches it')
    K.open_item('The underside of the gun heart and the block is designed here; the picture shows no underside')
    K.open_item('The ring reaches 3.05 below the ship\'s axis (4.9 drawn): the game centres every hull on its box (godot/render/ship_view.gd _fit), so lifting the ship above the board is a game-side offset, not a model one (R266)')
    # ---------- the fit report's fix column: every finding on the first full layout ----------
    K.fix('H1p and H1s (belly hatches) inside the stern block, once the body grew (R266)', 'the hatches sit 0.04 under the block\'s new floor, read off its section')
    K.fix('L1 (the null lance) body inside E14_drum (the gun heart)', 'the housing starts 0.04 ahead of the gun heart\'s face; only the seat ring (the mount) sinks into it')
    K.fix('DL1 to DL4 (drone lights) inside the ring plates\' inner edges', 'the cradles moved in to radius 1.86 on the hoop\'s face and each light lies along the hoop, clear of the plates')
    K.fix('D1 to D4 (drone cradles) against DL1 to DL4 (their lights)', 'each light is mounted on its own cradle on purpose (an allowed touch, as a part on a part)')
