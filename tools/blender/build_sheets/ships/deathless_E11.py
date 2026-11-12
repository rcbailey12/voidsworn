# deathless_E11: The Unsetting, the Eclipse flagship (class Tomb-ark, 28.0 world units). Issue 532, Eclipse build sheets.
# Accepted picture: contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg and _sheet.jpg (R206).
# data.js d_boss: gauss T, gauss T, doom F, flak T; ability nova (the spinal shell); no hangar.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced.
# Measured off the 8c sheet's true views (the top view sets the scale, 1607 px = 28 units; the side view its own): the
# crescent 10.8 across, its back at 39 percent; horns at the prow; the body 4.6 to 4.9 wide behind the crescent, tapering to
# about 3.8 at the band collar (75 percent) and flaring again at the stern feathers; the body about 3.6 deep, the batteries
# raising it to 5.6 at the turrets; hull length to beam 5.7 and length to height 7.0 (median over the middle 60 percent).
# +X bow, +Y port, +Z up. Prow (horn tips) x = +14.0, engine exits x = -14.0. The projector's axis z = -0.45.
import math

CODE = 'deathless_E11'
NAME = 'The Unsetting (Eclipse flagship)'
FACTION = 'Eclipse (deathless)'
CLASS = 'Tomb-ark'
LENGTH = 28.0
GAME = "data.js d_boss (cls 'Tomb-ark'); length from godot/render/hull_table.gd CLS_LEN['Tomb-ark'] = 28.0 (drawn x SHIP_K 1.6 = 44.8 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg'
KIT = 'eclipse'
CONCEPT_SHEET = 'contrib/muse/design/concept_round8c_2026_11/deathless_E11_sheet.jpg'
# the true views on the 8c sheet (x0, y0, x1, y1), bow on the right; the escort is a separate shape and is left out
CONCEPT_VIEWS = dict(top=dict(box=(139, 23, 1747, 670), largest=True, flip=True), side=dict(box=(143, 704, 1824, 1079), largest=True, flip=True))
CROPS = [('bow (crescent and projector)', (900, 300, 1920, 1100)), ('midships (batteries)', (450, 60, 1250, 620)), ('stern (engines and feathers)', (0, 20, 760, 560))]
SHEET = dict(version=3, round='third sheet (R221 weapons, pass 2)', date='2026-11-12', blend='opus532e\\w\\w3',
             before='First full layout', before_note='The first complete E11 layout, built with the Eclipse kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): deck hatches and the core port sunk in the curved tier, the belt lights inside the belt, '
                    'heat panels covered by the stern feathers (moved forward of the band collar), the aft flak twin sweeping through deck hatches (moved to the deck edge), '
                    'and, after the crescent was raised over the nose, the fore twin\'s barrels striking the tier when trained aft (the tier now starts behind its sweep).' + ' ' + 'R221 weapon rebuild (this sheet): the new null cannons, shredders and corona arc emitter checked at zero on their first full run, with the new LANE test and the emitter\'s own firing lane.')

PEXP = (2.8, 2.3)   # the oval section: flatter over the deck, round in the flanks and belly
# (x, half-beam port, half-beam starboard, bottom, top, -, -): the body, nose first (the nose sits inside the crescent's root)
HULL = [
    (5.6, 1.3, 1.3, -1.3, 0.5, 0, 0),
    (4.7, 1.7, 1.7, -1.6, 0.85, 0, 0),
    (3.5, 2.15, 2.15, -1.9, 1.35, 0, 0),
    (2.0, 2.38, 2.38, -2.05, 1.95, 0, 0),
    (-2.0, 2.3, 2.3, -2.05, 1.95, 0, 0),
    (-5.6, 2.1, 2.1, -1.95, 1.85, 0, 0),
    (-7.0, 1.88, 1.88, -1.82, 1.72, 0, 0),
    (-8.4, 1.92, 1.92, -1.85, 1.76, 0, 0),
    (-9.8, 2.04, 2.04, -1.98, 1.9, 0, 0),
    (-11.2, 2.08, 2.08, -2.02, 1.95, 0, 0),
    (-12.3, 1.9, 1.9, -1.88, 1.8, 0, 0),
]
PL = dict(keep3d=True, size=(0.32, 0.75), thick=(0.03, 0.09), skip=0.07, stack=0.35, mats={'violet': 5, 'mauve': 4, 'shade2': 2, 'lilac': 1})

# the crescent: two ellipses in plan (d = distance aft of the prow, y to port), the outer through the horn tips and the back,
# the inner through the horn tips and the inner wall
CO, AO, BO = 5.168, 5.932, 5.4   # outer: centre d, semi-axis along the length, half-width (back at d 11.1, 39.6 percent)
CI, AI, BI = 2.983, 4.217, 3.75   # inner (its back, the inner wall, at d 7.2: the band is 3.9 deep at the root, as the plan; 1.65 wide at the sides, between the plan's 1.3 and the beauty's)
PHI_H = math.degrees(math.acos((0.0 - CO) / AO))   # the horn tip on the outer ellipse
PSI_H = math.degrees(math.acos((0.0 - CI) / AI))
Z0 = -0.2                        # the projector axis
ZC = 0.3                         # the crescent's root plane (it rides up over the body's nose, the concept's plan and profile)


def cres(phi_deg, u):
    """a point across the crescent at outer angle phi (0 = the back, + to port), u = 0 inner edge, 1 outer edge: (x, y)"""
    ph = math.radians(phi_deg); ps = math.radians(phi_deg * PSI_H / PHI_H)
    xo, yo = 14.0 - (CO + AO * math.cos(ph)), BO * math.sin(ph)
    xi, yi = 14.0 - (CI + AI * math.cos(ps)), BI * math.sin(ps)
    return xi + (xo - xi) * u, yi + (yo - yi) * u


def cz(phi_deg, u):
    """the lower blade's top and bottom at (phi, u): thick at the inner wall, knife-thin at the rim, drooping to the horns"""
    f = min(1.0, abs(phi_deg) / PHI_H)
    zc = ZC - 1.6 * f ** 1.3
    h_in = 0.16 + 1.0 * (1 - f) ** 0.8
    h_out = 0.08 + 0.55 * (1 - f) ** 1.5
    th = h_in * (1 - u) + h_out * u
    return zc - 0.4 * th, zc + 0.6 * th


def build(K):
    import kit as _k
    from mathutils import Vector

    def surf(x, side, z):
        return K.surf(x, side, z)

    hull = K.hull(HULL, 'violet', shell=0.22, plates=dict(PL, seed=11, inv=['body_plates']), rounded=True, pexp=PEXP)
    K.mass('Hull: the oval body', hull, 'Eclipse violet plate', note='widest behind the crescent, waisted at the band collar, flaring at the stern')
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])

    # ---------------- the crescent shade: a lower blade, an upper layer, a root layer; a corona line on every rim ----------------
    N = 72
    phis = [-PHI_H + 2 * PHI_H * i / N for i in range(N + 1)]
    US = (0.0, 0.33, 0.66, 1.0)
    rings = []
    for ph in phis:
        bot = []; top = []
        for u in US:
            x, y = cres(ph, u); zb, zt = cz(ph, u)
            bot.append((x, y, zb)); top.append((x, y, zt))
        rings.append(bot + top[::-1])
    K.mass('Crescent lower blade', K.loft_rings('E11_crescent_blade', rings, 'violet',
                                                plates=dict(PL, seed=21, faces=[0, 1, 2, 4, 5, 6, 7], size=(0.3, 0.65), stride=2, inv='crescent_plates')),
           'Eclipse violet and mauve plate', note='a broad brim: 1.2 thick at the inner wall, 0.6 at the back rim, thin at the horns; it falls 1.6 from the root to the horns')
    PHI_U, U_U = 122.0, 0.55
    up_rings = []
    for i in range(N + 1):
        ph = -PHI_U + 2 * PHI_U * i / N
        f = abs(ph) / PHI_U
        t = max(0.05, 0.25 * (1 - f ** 2) ** 0.5)
        bot = []; top = []
        for u in (0.0, U_U * 0.5, U_U):
            x, y = cres(ph, u); zb, zt = cz(ph, u)
            bot.append((x, y, zt - 0.02)); top.append((x, y, zt + t - (0.06 if u == U_U else 0.0)))
        up_rings.append(bot + top[::-1])
    K.mass('Crescent upper layer', K.loft_rings('E11_crescent_upper', up_rings, 'mauve',
                                                plates=dict(PL, seed=22, faces=[3, 4, 5], size=(0.3, 0.6), stride=2, inv='crescent_plates')),
           'mauve plate', note='stepped in from the rim, over the inner half of the blade, to 122 degrees either side')
    PHI_R, U_R = 64.0, 0.3
    r_rings = []
    for i in range(N // 2 + 1):
        ph = -PHI_R + 2 * PHI_R * i / (N // 2)
        f = abs(ph) / PHI_R
        t0 = 0.25 * (1 - (ph / PHI_U) ** 2) ** 0.5
        t = max(0.04, 0.2 * (1 - f ** 2) ** 0.5)
        bot = []; top = []
        for u in (0.0, U_R * 0.5, U_R):
            x, y = cres(ph, u); zb, zt = cz(ph, u)
            bot.append((x, y, zt + t0 - 0.02)); top.append((x, y, zt + t0 + t - (0.05 if u == U_R else 0.0)))
        r_rings.append(bot + top[::-1])
    K.mass('Crescent root layer', K.loft_rings('E11_crescent_root', r_rings, 'violet',
                                               plates=dict(PL, seed=23, faces=[3, 4, 5], size=(0.3, 0.55), stride=2, inv='crescent_plates')),
           'violet plate', note='the third, shortest layer over the root')
    # corona lines: the blade's rim, the upper layer's rim, the inner rim
    K.strip('E11_corona_rim', [(*cres(ph, 1.0), cz(ph, 1.0)[1] + 0.005) for ph in phis], w=0.034, t=0.025)
    K.strip('E11_corona_upper', [(*cres(ph, U_U), cz(ph, U_U)[1] + max(0.05, 0.25 * (1 - (ph / PHI_U) ** 2) ** 0.5) - 0.055)
                                 for ph in [-PHI_U + 2 * PHI_U * i / N for i in range(N + 1)]], w=0.032, t=0.022)
    inner = []
    for ph in [-PHI_U + 2 * PHI_U * i / N for i in range(N + 1)]:
        t0 = max(0.05, 0.25 * (1 - (ph / PHI_U) ** 2) ** 0.5)
        tr = max(0.04, 0.2 * (1 - (ph / PHI_R) ** 2) ** 0.5) if abs(ph) < PHI_R else 0.0
        x, y = cres(ph, 0.0)
        inner.append((x + 0.04, y, cz(ph, 0.0)[1] + t0 + tr + 0.005))
    K.strip('E11_corona_inner', inner, w=0.032, t=0.022)
    K.mark('crescent', 'shade', ['band', 'layer', 'corona', 'plate'])
    K.mark('crescent_plates', 'plate', ['slab', 'step', 'bevel', 'fastener'])

    # ---------------- the corona arc projector (doom F), out of the crescent's inner wall ----------------
    K.spinal('A1', (5.1, 0.0, Z0), 7.56, r=0.66, collar_r=1.02, collar_len=3.2, block_len=1.6, block_r=0.84, slot='F', weapon='doom',
             inv='projector', note='the corona arc emitter on the axis, through the crescent: a capacitor column ending in a crown of electrode horns round a black shade disc; the spinal shell (nova) fires from it')
    import bpy as _bpy
    for nm_, ob_, col_ in (('Projector breech collars', 'A1_mount_mauve', 'mauve and violet'), ('Projector shaft', 'A1_body_violet', 'violet and mauve'), ('Projector muzzle block', 'A1_body_mauve', 'mauve')):
        K.mass(nm_, _bpy.data.objects[ob_], col_, note='a part of the kit projector, counted as its own mass')

    # ---------------- the body: the neck brow, dorsal tiers, flank belt, skirt, band collar ----------------
    def tier(name, x0, x1, hw0, hw1, lift, seed):
        # a layered plate tier lying on the deck: a rounded section following the hull's top, sloped at both ends
        secs = []
        for x, k in ((x0, 0.0), (x0 - 0.7, 1.0), (x1 + 0.6, 1.0), (x1, 0.0)):
            zt_ = K.deck_z(x, 0.0); hw = hw0 + (hw1 - hw0) * (x0 - x) / (x0 - x1)
            secs.append((x, hw * (0.75 + 0.25 * k), hw * (0.75 + 0.25 * k), zt_ - 0.45, zt_ + lift * (0.25 + 0.75 * k), 0, 0))
        return K.loft(name, secs, 'mauve', rounded=True, pexp=(3.2, 2.0), plates=dict(PL, seed=seed, faces=list(range(0, 12)), size=(0.3, 0.6), inv='body_plates'))
    K.mass('Dorsal tier', tier('E11_tier1', -0.2, -5.5, 1.45, 1.25, 0.26, 31), 'mauve plate',
           note='the layered plate tier along the spine (the concept\'s raised plate rows), a quarter unit proud')
    def tier_z(x, y):
        # the dorsal tier's rounded top at (x, y): its section is (hw, deck - 0.45 .. deck + 0.26), deck exponent 3.2
        hw = 1.45 + (1.25 - 1.45) * (-0.2 - x) / 5.3; zt_ = K.deck_z(x, 0.0); zb_, zt2 = zt_ - 0.45, zt_ + 0.26
        return (zb_ + zt2) / 2 + (zt2 - zb_) / 2 * max(0.0, 1 - (abs(y) / hw) ** 3.2) ** (1 / 3.2)
    K.mass('Barbette, fore battery', K.loft('E11_barb1', [(3.1, 0.62, 0.62, 1.5, 2.12, 0, 0), (2.98, 0.7, 0.7, 1.5, 2.1, 0, 0), (1.82, 0.7, 0.7, 1.5, 2.1, 0, 0),
                                                          (1.7, 0.62, 0.62, 1.5, 2.12, 0, 0)], 'violet', rounded=True, pexp=(2.0, 2.0),
                                           plates=dict(PL, seed=35, faces=list(range(0, 12)), size=(0.25, 0.45))),
           'violet plate', note='a low round drum, slimmed to the turret\'s foot (R221 pass 2): the fore battery fires aft over the tier and the aft battery\'s muzzles')
    K.mass('Barbette, aft battery', K.loft('E11_barb2', [(-1.52, 0.64, 0.64, 1.9, 2.87, 0, 0), (-1.64, 0.72, 0.72, 1.9, 2.83, 0, 0), (-2.76, 0.72, 0.72, 1.9, 2.83, 0, 0),
                                                         (-2.88, 0.64, 0.64, 1.9, 2.87, 0, 0)], 'violet', rounded=True, pexp=(2.0, 2.0),
                                           plates=dict(PL, seed=34, faces=list(range(0, 12)), size=(0.25, 0.45))),
           'violet plate', note='a low round drum that superfires the aft battery over the fore one')
    K.mark('dorsal_tiers', 'tier', ['face', 'roof', 'opening'])
    K.mass('Flank belt', K.band('E11_belt', [2.8, 2.0, -2.0, -5.6, -6.7], -0.05, 0.4, 0.12, 'gunv',
                                plates=dict(PL, seed=41, size=(0.5, 1.1), thick=(0.07, 0.16), skip=0.12, stack=0.5, mats={'lilac': 4, 'mauve': 3, 'violet': 1}, inv='belts'), k=3),
           'grey-mauve armour boxes', note='a raised strake at mid height, both flanks')
    K.mass('Lower skirt', K.band('E11_skirt', [2.6, 2.0, -2.0, -5.6, -6.7], -1.6, -0.45, 0.07, 'violet',
                                 plates=dict(PL, seed=42, size=(0.28, 0.4), thick=(0.04, 0.1), stack=0.1, inv='skirt')),
           'deep violet tall plates', note='tall narrow plates hanging below the belt')
    K.mark('belts', 'belt', ['band', 'plate']); K.mark('skirt', 'belt', ['band', 'plate'])
    bc = [(x, h + 0.2, h + 0.2, zb - 0.2, zt + 0.2, 0, 0) for (x, h, zb, zt) in ((-6.95, 1.88, -1.82, 1.72), (-7.25, 1.89, -1.83, 1.73),
                                                                                 (-7.65, 1.9, -1.84, 1.74), (-7.95, 1.91, -1.84, 1.75))]
    K.mass('Band collar', K.loft('E11_band', bc, 'gunv', rounded=True, pexp=PEXP,
                                 plates=dict(PL, seed=43, size=(0.28, 0.32), thick=(0.06, 0.12), stack=0.0, skip=0.0, mats={'mauve': 3, 'lilac': 2, 'violet': 2}, inv='band_collar')),
           'violet gunmetal with segmented blocks', note='the heavy band ring at 77 percent')
    K.mark('band_collar', 'belt', ['band', 'plate'])

    # ---------------- the stern feathers: three rows of eight swept shade blades ----------------
    import kit as kk
    nf = 0
    for row, (x0, lift0, lift1, L) in enumerate(((-8.2, 0.02, 0.06, 2.0), (-9.4, 0.03, 0.08, 2.0), (-10.6, 0.04, 0.15, 2.3))):
        for k in range(12):
            a = math.radians(15 + 30 * k + (15 if row == 1 else 0))
            sec = []
            for j, f in enumerate((0.0, 0.35, 0.7, 1.0)):
                x = x0 - L * f
                s = kk.sec_at(HULL, x)
                ring = kk._round_sec(s[1], s[2], s[3], s[4], 0.0, 96, *PEXP)
                # the hull ring point nearest the angle a (from +Y toward +Z)
                zc = (s[3] + s[4]) / 2
                best = min(range(96), key=lambda i: abs(math.atan2(ring[i][1] - zc, ring[i][0]) - math.atan2(math.sin(a), math.cos(a))))
                p0 = Vector((x, ring[best][0], ring[best][1])); p1 = Vector((x, ring[(best + 1) % 96][0], ring[(best + 1) % 96][1]))
                tang = (p1 - p0).normalized(); nrm = Vector((0, p0.y, p0.z - zc)).normalized()
                w = 1.04 * (1 - f) + 0.34 * f; lift = lift0 + (lift1 - lift0) * f * f; th = 0.08 * (1 - 0.5 * f)
                c = p0 + nrm * lift
                sec.append([c - tang * w / 2, c + tang * w / 2, c + tang * w / 2 * 0.92 + nrm * th, c - tang * w / 2 * 0.92 + nrm * th])
            ob = K.loft_rings('E11_feather_%d_%d' % (row, k), sec, ['violet', 'mauve', 'shade2'][(row + k) % 3])
            # the thickness step: a narrower second plate on each blade's root half
            st = [[q + (sec[j][2] - sec[j][1]).normalized() * 0.0 for q in sec[j]] for j in range(2)]
            mid = [(sec[j][0] + sec[j][1]) / 2 for j in range(3)]
            nr = [(sec[j][3] - sec[j][0]).normalized() for j in range(3)]
            K.loft_rings('E11_feather_step_%d_%d' % (row, k), [[mid[j] + (sec[j][1] - sec[j][0]) * 0.22 * sg + nr[j] * (0.08 * (1 - 0.17 * j) + dz)
                                                                for sg, dz in ((-1, 0), (1, 0), (0.9, 0.05), (-0.9, 0.05))] for j in range(3)], 'shade2')
            K.built.append(dict(id='feather_%d_%d' % (row, k), kind='feather', inv=['feathers'], shaped=True, detailed=True, subs=['blade', 'step']))
            nf += 1
            if k in (0, 3, 6, 9):
                K.mass('Feather row %d, blade %d' % (row + 1, k + 1), ob, 'violet blade', note='swept shade blade, lifting aft')
        # a step plate along each row's root (the thickness step where the next row overlaps)

    # ---------------- batteries, by data.js slot ----------------
    K.gun('T1', (2.4, 0.0, 2.1), 0, 5, barrels=2, cal=0.13, blen=2.0, size=1.35, slot='T', weapon='gauss', inv='main_guns',
          note='fore null cannon: twin rail pairs through a crescent shade, on a low drum behind the crescent')
    K.gun('T2', (-2.2, 0.0, 2.85), 0, 3, barrels=2, cal=0.13, blen=2.0, size=1.35, slot='T', weapon='gauss', inv='main_guns', variant=1,
          note='aft null cannon, superfiring over T1; far enough aft that T1 fires aft over its muzzles')
    K.gun('F1', (-6.4, 0.0, K.deck_z(-6.4, 0.0)), 0, 12, barrels=2, cal=0.075, blen=1.1, size=0.85, slot='T', weapon='flak', inv='flak',
          note='null shredder: a fan of five needle rails, aft on the deck')
    K.gun('F2', (-1.0, 0.0, -2.05), 0, 10, barrels=2, cal=0.075, blen=1.1, size=0.85, normal=(0, 0, -1), slot='T', weapon='flak', inv='belly_flak',
          note='null shredder on the belly, covering below')

    # ---------------- deck and flank fittings ----------------
    K.corewin('CW1', (-3.75, 0.0, tier_z(-3.75, 0.0) - 0.01), (0, 0, 1), 0.34, inv='core_port', note='the core\'s light through a hex port in tier 1')
    K.hatchbox('HB1', (-4.6, 0.0, tier_z(-4.6, 0.0) - 0.02), 0.9, 0.5, 0.4, inv='shade_gen', note='raised deck housing (the shade generator) on tier 1')
    def deck_n(x, y):
        from mathutils import Vector as V_
        return tuple(V_((0, -(K.deck_z(x, y + 0.02) - K.deck_z(x, y - 0.02)) / 0.04, 1)).normalized())
    K.hatch('H1', (-6.1, 1.35, K.deck_z(-6.1, 1.35) + 0.04), deck_n(-6.1, 1.35), 0.32, inv='hatches', note='deck hatch aft, port')
    K.hatch('H2', (-6.1, -1.35, K.deck_z(-6.1, -1.35) + 0.04), deck_n(-6.1, -1.35), 0.32, inv='hatches', note='deck hatch aft, starboard')
    K.hatch('H3', (-3.2, 0.9, -1.97), (0, 0, -1), 0.4, inv='hatches', note='belly hatch, port')
    K.hatch('H4', (-3.2, -0.9, -1.97), (0, 0, -1), 0.4, inv='hatches', note='belly hatch, starboard')
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        K.thruster('Q1' + sn, (1.6, surf(1.6, side, 0.95), 0.95), K.surf_n(1.6, side, 0.95), inv='bow_thrusters', note='neck flank')
        for i, x in enumerate((2.6, 0.6, -1.4, -3.4)):
            z = 0.62
            K.lamp('L%d%s' % (i, sn), (x, surf(x, side, z), z), K.surf_n(x, side, z), inv='lamps', note='corona strip light over the belt', up=(1, 0, 0))
        K.vent('V1' + sn, (-6.0, max(surf(-5.6, side, 1.05), surf(-6.4, side, 1.05), key=abs) + 0.03 * side, 1.05), K.surf_n(-6.0, side, 1.05), 0.7, 0.32, slats=4,
               inv='vents', note='heat slot panel over the belt, ahead of the band collar')
        K.thruster('Q2' + sn, (-7.5, side * 2.1, 0.0), (0, side, 0), inv='stern_thrusters', note='on the band collar')

    # ---------------- engines: a diamond of four ----------------
    for i, (y, z, nm) in enumerate(((0.0, 1.2, 'upper'), (1.2, 0.0, 'port'), (-1.2, 0.0, 'starboard'), (0.0, -1.2, 'lower'))):
        K.engine('E%d' % (i + 1), (-14.0, y, z), 0.56, 1.25, bell=1.2, body_r=0.66, rings=3, nose='flat', inv='engines',
                 src='picture' if nm != 'starboard' else 'designed', note='%s engine of the diamond' % nm)

    # ---------------- colour zones ----------------
    K.colour('Eclipse violet and mauve plate, violet-black shade (paint stage)', 14.0, -14.0, 'whole hull')
    K.colour('green-white corona line', 14.0, 2.9, 'every crescent rim')
    K.colour('core light', -3.0, -3.5, 'the core port')
    K.colour('pale grey-green weathering (paint)', 9.0, 6.0, 'inner crescent face')

    # ---------- INSIDE: decks, frames, archive vaults, dark decks, the core (factions.md: inside, archive vaults, dark decks, the core's light) ----------
    def deck(name, z, x0, x1, inset=0.3):
        secs = []
        for x in (x0, (2 * x0 + x1) / 3, (x0 + 2 * x1) / 3, x1):
            hw = abs(surf(x, 1, z)) - inset
            secs.append((x, max(hw, 0.3), max(hw, 0.3), z - 0.04, z + 0.04, 0, 0))
        K.loft('in_deck_' + name, secs, 'darkdeck', inside=True)
        K.inside.append(dict(kind='deck', name=name, z=z, x=(x1, x0)))
    deck('lower', -0.95, 4.6, -12.0); deck('main', 0.3, 5.0, -12.0); deck('upper', 1.2, 3.0, -11.4)
    for i, x in enumerate((4.6, 2.2, -0.4, -3.0, -5.5, -7.5, -9.8, -12.0)):
        s = _k.sec_at(HULL, x)
        K.loft('in_bh_F%d' % i, [(x + 0.05, s[1] - 0.3, s[2] - 0.3, s[3] + 0.3, s[4] - 0.3, 0, 0), (x - 0.05, s[1] - 0.3, s[2] - 0.3, s[3] + 0.3, s[4] - 0.3, 0, 0)],
               'frame', inside=True, rounded=True, pexp=PEXP)
        K.inside.append(dict(kind='bulkhead', name='F%d' % i, x=x))
    K.room('capacitor_bank', 'magazine', 2.3, 4.5, -0.9, 0.9, -0.9, 0.2, note='corona arc capacitors behind the projector\'s breech')
    K.room('fore_magazine', 'magazine', 1.8, 3.4, -0.7, 0.7, 0.4, 1.15, note='under the fore battery')
    K.room('archive_vault_fore', 'archive', -0.3, 2.1, -1.5, 1.5, -0.9, 0.25, note='archive vaults: the Starwrights\' stored selves')
    K.room('aft_magazine', 'magazine', -2.2, -0.4, -0.7, 0.7, 0.4, 1.15, note='under the aft battery')
    K.room('dark_decks', 'darkdeck', -2.9, -0.5, -1.4, 1.4, 0.4, 1.15, note='dark decks: machine crew stations, unlit')
    K.room('core', 'ecore', -5.3, -3.1, -1.1, 1.1, -0.9, 1.15, note='the core of trapped light (hp_core); its port opens on the deck')
    K.room('archive_vault_aft', 'archive', -7.3, -5.6, -1.2, 1.2, -0.9, 0.25, note='archive vaults')
    K.room('shade_machinery', 'machinery', -7.3, -5.6, -1.0, 1.0, 0.4, 1.15, note='shade generators and the band collar\'s drives')
    K.room('flak_magazine', 'magazine', -1.8, -0.2, -0.7, 0.7, -1.5, -1.0, note='over the belly twin')
    K.room('engine_room', 'engroom', -11.9, -9.9, -1.4, 1.4, -0.9, 1.15, note='engine room and the four drives\' feeds')
    K.armour('crescent (shade layers)', 0.6, 'three layers, thickest at the inner wall; the rims knife-thin')
    K.armour('dorsal tiers and barbettes', 0.4, '')
    K.armour('flank belt', 0.3, 'over the vaults and magazines')
    K.armour('belly and skirt', 0.25, '')
    K.armour('stern feathers', 0.15, 'thinnest; they peel first')
    # issue 618 (R226): B-1 kinks aft round the projector's breech collars (A1 runs from 4.5), so the projector rides whole with the bow
    K.break_line('B-1', 5.2, 'the crescent root seam: the shade and the projector tear away from the neck, opening the capacitor bank',
                 path=[(5.5, 1.6), (4.3, 1.05), (4.1, 0.3), (4.35, -0.4), (4.15, -1.05), (5.4, -1.6)])
    K.break_line('B-2', -7.5, 'at the band collar: the stern (feathers and drives) tears away, opening the engine room and the aft vault',
                 path=[(-8.02, 2.5), (-8.02, 1.9), (-7.4, 1.1), (-7.95, 0.2), (-7.2, -0.7), (-8.02, -1.8), (-8.02, -2.5)])   # issue 618 (R226): aft of the collar thrusters Q2
    K.break_line('B-3', 0.0, 'the dorsal tiers peel off band by band along their base, taking the batteries, laying the dark decks bare',
                 path=[(1.3, 1.5), (-0.8, 1.35), (-2.6, 1.55), (-4.2, 1.35), (-5.4, 1.5)], kind='long')
    # issue 618: the game's longitudinal seam is one level plane over its compartment (RECIPE.md, format version 1); B-4 lies at 0.9,
    # over the projector's collars (top 0.74, R226) and through the crescent's root, where the upper and root layers sit on the blade
    K.break_line('B-4', 9.0, 'the crescent\'s upper layers peel from the lower blade at the root, band by band, over the projector',
                 path=[(5.8, 0.9), (7.5, 0.92), (9.5, 0.9), (11.0, 0.88), (12.5, 0.9)], kind='long')
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks. Eclipse breaks in layers (factions.md): shade plates peel band by band, then the body behind is bare; deaths blow it apart unevenly, a ragged bite where the core goes (R186).'))
    K.point('core', 'hp_core', (-4.2, 0, 0.1))
    # eight breach anchors on the shade bands (Tomb-ark base 8, Eclipse +0): prow 3, mid 3, engine 2, alternating sides
    for i, (x, y, z, sec, side) in enumerate([(8.5, 3.6, -0.3, 'prow', 'port'), (8.0, -3.9, -0.35, 'prow', 'stbd'), (11.0, 2.6, -1.0, 'prow', 'port'),
                                              (-0.9, -1.4, 2.0, 'mid', 'stbd'), (-3.8, 1.3, 1.98, 'mid', 'port'), (0.9, -2.4, 0.5, 'mid', 'stbd'),
                                              (-9.3, 1.9, 0.9, 'eng', 'port'), (-10.4, -1.9, -0.9, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec, note='on a shade band')
    K.point('rcs', 'hp_rcs_0', (1.6, surf(1.6, 1, 0.95), 0.95), side='port'); K.point('rcs', 'hp_rcs_1', (1.6, surf(1.6, -1, 0.95), 0.95), side='stbd')
    K.point('rcs', 'hp_rcs_2', (-7.5, 2.1, 0.0), side='port'); K.point('rcs', 'hp_rcs_3', (-7.5, -2.1, 0.0), side='stbd')
    # issue 618: the boarding origins the game contract needs (HARDPOINTS.md: one a side, mid hull): the flanks over the belt,
    # between the strip lights, where the reclaim swarms leave the dark decks
    K.point('board', 'hp_board_0', (-2.4, surf(-2.4, 1, 0.95), 0.95), side='port'); K.point('board', 'hp_board_1', (-2.4, surf(-2.4, -1, 0.95), 0.95), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('The engine cluster is a diamond of four', 'the side view and the beauty show three bells stacked, the plan shows two side by side; a diamond of four is the one layout that reads as all three pictures, and keeps the stern wide and flat')
    K.change('Engines are eclipse rings, not flame', 'factions.md: "no flaming bells. An eclipse ring of pale light": each bell has a black shade disc with a thin pale green-white ring inside its lip')
    K.change('Batteries by data.js slot', 'd_boss carries gauss T twice, doom F and flak T: the two big mounts are the null cannons (the aft one superfires on a barbette), the projector is the corona arc, the small aft mount and a belly mount are the null shredders')
    K.change('Weapons built from the lore, not the picture\'s generic turrets (R221)', 'Ryan: "their turrets look the same as hullbreakers"; the picture draws box turrets with round twin barrels. The null cannons are rail guns (slim round rail pairs with banded collars) firing through the slot of a thin arched crescent shade, the shredders fans of needle rails, all in the hull\'s curved, layered, banded language (pass 2: "super blocky"), the projector an arc emitter with a crown of electrode horns round the crest\'s black disc (tools/blender/kits/eclipse/README.md)')
    K.change('The green hexagon on the deck is the core port, not a gun', 'the faction\'s green is the trapped core seen through gaps; the flak slot is the small twin')
    K.change('The crescent is three stacked layers with a corona line on each rim', 'factions.md: broad layered plates, the green a thin line on every shade rim; the concept shows two stepped bands and a lip; the layers are also how it breaks (band by band)')
    K.change('Low round drums under both batteries, slimmed to the turret feet (R221 pass 2)', 'so the fore twin clears the tier when it trains aft and fires aft over the aft twin\'s muzzles, and the aft twin fires over the fore one (the fit check found both)')
    K.change('Belly twin, attitude thrusters, deck and belly hatches, corona strip lights, heat panels added', 'the belly needs cover and a ship in space needs thrusters; the picture shows no underside')
    K.open_item('The belly between the skirt and the belly twin is designed here; the picture does not show the underside')

    K.change('The crescent band is 1.65 wide at its sides', 'the plan of record (the 8c sheet\'s top view) gives 1.3, the beauty reads broader; the band sits between the two so the beauty\'s fat brim reads without losing the plan')
    # ---------- the fit report's fix column: every finding on the first full layout (/tmp before/deathless_E11_fit.json, kept in fit_report.md) ----------
    K.fix('F1 (aft flak twin) intersecting HB1 (the deck housing), and sweeping through it from bearing -30 to 30', 'the housing made shorter (0.5) and moved forward to 4.6 aft of amidships; the twin moved aft to 6.4, so its barrels clear the housing at every bearing')
    K.fix('T1 (fore twin) firing aft blocked by T2\'s plinth at bearings 175 and -175', 'T2 moved aft (to 57 percent) and T1 raised on a low round drum, so T1\'s highest line passes over T2\'s muzzles; both twins carry 2.0 barrels')
