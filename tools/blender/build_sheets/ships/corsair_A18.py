# corsair_A18: Hullbreaker raider, the Sniffer (Ashfall Hullbreakers frigate, class Frigate, 6.5 world units; issue 633).
# Accepted picture: contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg (v3, accepted by Ryan Nov 12 2026,
# PR 625) and corsair_A18_sheet.jpg; designs.md (the merged five-leg design) is the design of record for the fittings.
# data.js c_raider: autocannon T, ability overburn, speed 6, evasion 28 (the fastest, most evasive Hullbreaker).
# Measured off the whole concept first (R229): the sheet's true views give a chunky nose that tapers forward to a wide grilled
# face (about 0.85 across and 0.5 tall at the face), the body swelling behind it to about 1.7 at 40 percent of the length, a
# raised spine of stacked blocks from a third of the length to the engine block, a lower aft engine block, two engine drums
# on short pylons at the stern quarters and smaller bells between them, grabbers under the chin, a big flush disc on the nose.
# The Board is the final designer (R233): the build keeps that mass, and its outline from above is its own: a tapering nose
# that swells into the body (round 2: the Board found round 1 a long box with a dish at the front), one oversized listening
# dish nearly flush on the nose to starboard (designs.md, "a little brick with one big ear"), and lopsided engine drums (the
# port drum clearly larger). It is never a small A16 (the barge's wide body and gun rows) or a small A17 (the cruiser's
# boxy head with two ears).
# +X bow, +Y port, +Z up. Grabber tips about x = +3.3, engine exits about x = -3.2. Flat belly z = -0.57, spine top 0.69.
CODE = 'corsair_A18'
NAME = 'Hullbreaker raider (the Sniffer)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js c_raider (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5"
BEAUTY = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg'
CONCEPT_SHEET = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A18_sheet.jpg'
# the true views on the family sheet (x0, y0, x1, y1): top view on the first row, side view on the second, bow on the left
CONCEPT_VIEWS = dict(top=dict(box=(250, 30, 1650, 480), largest=True, flip=False), side=dict(box=(240, 490, 1750, 830), largest=True, flip=False))
CROPS = [('bow (wedge, face, chin, grabbers)', (60, 380, 1000, 1220)), ('midships (spine and flank)', (500, 120, 1400, 900)),
         ('stern (engine block and drums)', (1050, 40, 1920, 640))]
SHEET = dict(version=1, round='first sheet (issue 633)', date='2026-11-12', blend='opus633\\corsair_A18',
             before='First full layout', before_note='The first complete A18 layout, built with the Hullbreaker kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): see the fit report\'s fix column.')

import math, random

# (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer): the wedge bow over a cut-in chin, the
# body, the aft taper into the engine block. Issue 668 (R239, Ryan Nov 13: "a18 and a19 are much slimmer than concept. It's
# not a huge deal but it'd add some variety"): the body is broadened toward the beauty's beam, every half-beam out by WIDEN
# (0.18) from 1.5 aft, less toward the face so the grille nose keeps its taper: widest 2.04 (was 1.68), hull length to beam
# 3.2 (was 3.9).
WIDEN = 0.18
HULL = [
    (3.1, 0.48, 0.48, -0.28, 0.22, 0.13, 0.11),
    (2.5, 0.72, 0.72, -0.46, 0.36, 0.17, 0.15),
    (1.5, 0.78 + WIDEN, 0.78 + WIDEN, -0.55, 0.45, 0.18, 0.16),
    (0.4, 0.84 + WIDEN, 0.84 + WIDEN, -0.55, 0.46, 0.18, 0.16),
    (-1.3, 0.8 + WIDEN, 0.8 + WIDEN, -0.53, 0.45, 0.17, 0.15),
    (-2.25, 0.74 + WIDEN, 0.74 + WIDEN, -0.53, 0.45, 0.16, 0.15),
    (-2.78, 0.65 + WIDEN, 0.65 + WIDEN, -0.46, 0.4, 0.14, 0.14),
]
PL = dict(keep3d=True, courses=True, size=(0.16, 0.36), thick=(0.02, 0.05), step=0.025, gap=0.018, over=0.2, skip=0.04, stack=0.2, rivets_share=0.25, rivet_r=0.02, mats={'soot': 3, 'iron': 4, 'pale': 2, 'rust': 3, 'soot2': 2, 'violet': 1, 'steel': 2})
# the spine, bow to stern: stacked blocks (name, x fore, x aft, half-beam, top, front slope, y offset), with gaps between them
SPINE = [
    ('S1 fore spine block', 1.45, 0.78, 0.53, 0.6, 0.22, 0.0),
    ('S2 gun block', 0.72, 0.18, 0.51, 0.66, 0.1, 0.02),
    ('S3 mid spine block', 0.12, -0.36, 0.48, 0.61, 0.08, -0.03),
    ('S4 sensor block', -0.42, -1.0, 0.51, 0.69, 0.1, 0.02),
    ('S5 aft spine block', -1.06, -2.3, 0.53, 0.61, 0.08, 0.0),
]
THR = [(0.62, -0.36, 1), (0.62, -0.36, -1), (-1.3, -0.37, 1), (-1.3, -0.37, -1)]     # attitude thrusters (x, z, side)
LAMPS = [(2.2, 1), (-0.35, 1), (-1.65, 1), (-0.35, -1), (-1.65, -1)]                 # running lights low on the flanks (x, side)
ENG = ((1, 1.28, 0.3, -3.2, 'port drum, the larger'), (-1, -1.19, 0.245, -3.17, 'starboard drum'))


def small_antenna(K, fid, pos, h, whips, k, inv, note):
    """the kit's antenna array at k of its size: on the frigate the kit array's base block (sized for the barge) would carry
    half the hull's detail per square unit (R224; issue 618: detail scales with the part's size)"""
    from mathutils import Vector, Matrix
    import kit as _k
    p = Vector(pos)
    K.emit(fid, _k.HP.antenna(h / k, whips), _k.HP.frame(p, (1, 0, 0), (0, 0, 1)) @ Matrix.Scale(k, 4), inv)
    K.features.append(dict(id=fid, kind='antenna', what='antenna array, %.1f tall, %d whips (the kit array at %d percent)' % (h, whips, round(k * 100)), count=1,
                           pos=tuple(p), aim=None, src='picture', note=note, inv=[inv]))


def build(K):
    import kit as _k
    from mathutils import Vector
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Base hull (wedge bow, body, aft taper)', K.hull(HULL, 'soot', shell=0.08, plates=dict(PL, seed=18, inv=['hull_plates', 'belly_plates'])),
           'soot and patched plate', note='the sloped wedge bow over a cut-in chin, then the long body')
    K.mark('hull_form', 'hull', ['bevel', 'step', 'overhang'])
    K.mass('Lower hull band', K.loft('A18_lowband', [(1.85, 0.86, 0.86, -0.6, -0.4, 0.0, 0.08), (0.4, 0.76 + WIDEN, 0.76 + WIDEN, -0.6, -0.4, 0.0, 0.08), (-1.3, 0.72 + WIDEN, 0.72 + WIDEN, -0.6, -0.4, 0.0, 0.08),
                                                     (-2.55, 0.68 + WIDEN, 0.68 + WIDEN, -0.6, -0.4, 0.0, 0.08)], 'soot2',
                                     plates=dict(PL, seed=19, faces=[3, 4, 5, 6, 7, 0], inv='belly_plates')), 'dark soot', note='the belly steps in under the flank')
    # the engine pylons and the engine block (masses first, so the plates go on before any part claims its mount, R224)
    for side, y, r, ex, nm in ENG:
        K.mass('Engine pylon %s' % ('port' if side > 0 else 'starboard'),
               K.box('A18_pylon_%s' % ('p' if side > 0 else 's'), -2.75, -2.0, min(side * 0.55, side * (abs(y) - r * 0.6)), max(side * 0.55, side * (abs(y) - r * 0.6)),
                     -0.15, 0.12, 'iron', ch=0.04, plates=dict(PL, seed=40 + (side > 0), faces=[0, 1, 2, 7], size=(0.12, 0.26))),
               'iron', note='short pylon out to the engine drum')
    K.mark('pylons', 'pylon', ['web', 'plate'])
    K.mass('Engine block', K.box('A18_engblock', -2.9, -2.6, -0.72, 0.72, -0.42, 0.5, 'soot', ch=0.09, plates=dict(PL, seed=57, size=(0.12, 0.26))), 'soot, steel')
    K.mark('engine_block', 'pylon', ['web', 'plate'])
    # ---------------- the face and chin: a framed face with the wake-sniffer scoop, a brow plate over it ----------------
    K.box('A18_face_lip', 3.04, 3.15, -0.3, 0.3, -0.2, -0.15, 'steel', ch=0.015)
    K.box('A18_face_brow', 3.02, 3.15, -0.3, 0.3, 0.07, 0.12, 'steel', ch=0.015)
    for side in (1, -1):
        K.box('A18_face_cheek%d' % (side > 0), 3.02, 3.15, min(side * 0.28, side * 0.33), max(side * 0.28, side * 0.33), -0.2, 0.12, 'steel', ch=0.015)
    K.patch('FBR', (2.84, 0.0, 0.285), (0.23, 0, 0.97), 0.5, 0.3, ang=0.03, lift=0.02, t=0.03, m='pale', inv='face_plates')
    for side in (1, -1):
        K.patch('FC%s' % ('p' if side > 0 else 's'), (2.93, sy(2.93, side) + 0.005 * side, -0.04), (0.3, 0.95 * side, 0), 0.3, 0.3, ang=0.05 * side, lift=0.02, t=0.03,
                m='iron' if side > 0 else 'rust', inv='face_plates')
    K.mark('face_plates', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    # the wide intake grille that fills the face: three louvre panels side by side in one frame (a kit vent sized to the
    # frigate, so its detail per square unit stays at the hull's, issue 618's rule)
    for i, y in enumerate((0.188, 0.0, -0.188)):
        K.vent('I%d' % (i + 1), (3.11, y, -0.04), (1, 0, 0), 0.18, 0.21, slats=5, inv='scoop',
               note='%s panel of the wide intake grille that fills the bow face: the wake-sniffer scoop tastes the wake of ships ahead '
                    '(designs.md: the chin scoop, moved up into the face as the picture draws it)' % ('port', 'middle', 'starboard')[i])
    # ---------------- the dish mount: a low raised block on the nose, starboard, that carries the one big ear nearly flush ----------------
    K.mass('Dish mount (raised block on the nose, starboard)', K.loft('A18_sponson', [(2.45, 0.28, 0.28, 0.15, 0.6, 0.06, 0.0, -0.36),
                                                                                     (2.27, 0.32, 0.32, 0.15, 0.6, 0.07, 0.0, -0.37),
                                                                                     (1.62, 0.32, 0.32, 0.15, 0.62, 0.07, 0.0, -0.37),
                                                                                     (1.46, 0.28, 0.28, 0.15, 0.58, 0.06, 0.0, -0.36)],
                                                                     'iron', plates=dict(PL, seed=23, faces=[0, 1, 2, 3, 7], inv='sponson_plates', size=(0.12, 0.26))),
           'bare iron, patched', note='a low armoured block bolted on the nose to starboard, the dish set nearly flush on it (the picture\'s flush disc)')
    K.mark('sponson', 'tier', ['face', 'roof', 'opening'])
    K.slit('SL1', (2.452, -0.47, 0.52), (1, 0, 0), 0.2, 0.06, inv='sponson', note='vision slit in the dish mount\'s front: the dish operator\'s port')
    # ---------------- the spine: stacked blocks with gaps and undercut bases ----------------
    for (nm, x0, x1, hw, top, slope, yo) in SPINE:
        base = 0.36
        secs = [(x0, hw - 0.1, hw - 0.1, base, top - slope * 0.7, 0.05, 0.03, yo),
                (x0 - slope * 0.8, hw, hw, base, top, 0.09, 0.03, yo),
                (x1 + 0.06, hw, hw, base, top, 0.09, 0.03, yo),
                (x1, hw - 0.05, hw - 0.05, base, top - 0.05, 0.07, 0.03, yo)]
        K.mass(nm, K.loft('A18_' + nm.split()[0], secs, 'soot', plates=dict(PL, seed=sum(map(ord, nm)) % 997, faces=[0, 1, 2, 3, 7], size=(0.11, 0.24))),
               'soot with dried-blood patches', note='stacked spine block, top %.2f' % top)
    K.mark('spine', 'tier', ['face', 'roof', 'opening'])
    K.slit('SL2', (1.33, 0.22, 0.555), (0.62, 0.0, 0.79), 0.2, 0.065, inv='spine', note='slit in the fore spine block\'s slope, port (the dish fills the starboard view)')
    K.patch('RC1', (-1.62, 0.12, 0.61), (0, 0, 1), 0.55, 0.38, ang=0.06, lift=0.02, t=0.03, m='blood', inv='trophy')
    K.hatch('HS1', (-1.45, 0.53, 0.535), (0, 1, 0), 0.2, 0.1, up=(0, 0, -1), inv='spine_hatch', note='crew hatch on the aft spine block, port')
    K.hatchbox('HB1', (-0.62, 0.2, 0.69), 0.24, 0.28, 0.09, inv='spine_boxes', note='framed box on the sensor block')
    K.hatchbox('HB2', (-2.05, 0.0, 0.61), 0.28, 0.32, 0.1, inv='spine_boxes', note='ready-use locker on the aft spine block')
    small_antenna(K, 'AN1', (-1.33, -0.2, 0.61), 0.66, 3, 0.65, 'antenna', 'comms array on the aft spine block: calls the pack in on what the dish heard')
    K.vent('VT1', (-2.76, 0.0, 0.503), (0, 0, 1), 0.3, 0.2, slats=4, inv='vents', note='engine-room louvre on the engine block roof')

    # ---------------- the flanks: bolted armour bricks, unmatched; the port trophy plate ----------------
    rb = random.Random(1818)
    for side in (1, -1):
        xs = [(1.2, 0.35), (-0.95, -1.65)] if side > 0 else [(0.95, 0.2), (-0.15, -0.95), (-1.1, -1.65)]
        for i, (x0, x1) in enumerate(xs):
            out = rb.uniform(0.07, 0.11); zb = -0.23; ztop = rb.uniform(0.1, 0.21)
            hw = abs(sy((x0 + x1) / 2, side))
            a, b = (hw + out, -(hw - 0.2)) if side > 0 else (-(hw - 0.2), hw + out)
            ob = K.loft('A18_flank_%d%s' % (i, 'p' if side > 0 else 's'), [(x0, a, b, zb, ztop, 0.05, 0.05), (x1, a, b, zb, ztop, 0.05, 0.05)],
                        rb.choice(['soot', 'iron', 'soot2']), plates=dict(PL, seed=300 + i * 7 + (side > 0), faces=[6, 7, 0] if side > 0 else [2, 3, 4], size=(0.14, 0.32)))
            K.mass('Flank brick %d %s' % (i + 1, 'port' if side > 0 else 'starboard'), ob, 'patched plate', note='armour brick bolted on the flank')
    K.mark('flank_bricks', 'tier', ['face', 'roof', 'opening'])
    K.patch('TP1', (-0.3, sy(-0.3, 1) + 0.005, -0.02), (0, 1, 0), 1.0, 0.42, ang=0.04, lift=0.03, t=0.04, m='pale', inv='trophy')
    K.patch('TP2', (1.0, 0.65, 0.455), (0, 0, 1), 0.4, 0.32, ang=0.3, lift=0.03, t=0.03, m='violet', inv='trophy')

    # the plates go on now, over every mass, with the mounts of the flank fittings and the turret kept clear (on a frigate the
    # kit's default keep-outs, sized for the barge, would strip most of the hull: issue 633)
    for (x, z, side) in THR:
        K.keepouts.append((Vector((x, sy(x, side), z)), 0.2))
    for (x, side) in LAMPS:
        K.keepouts.append((Vector((x, sy(x, side), -0.36)), 0.12))
    K.keepouts.append((Vector((0.45, 0.02, 0.66)), 0.44))
    K.keepouts.append((Vector((1.98, -0.37, 0.62)), 0.34))        # the dish's base and post
    K.keepouts.append((Vector((2.55, -0.47, 0.45)), 0.2))           # the dish operator's slit
    for side in (1, -1):                                           # the grabber shoulders under the chin
        K.keepouts.append((Vector((2.15, 0.34 * side, -0.6)), 0.26))
    K.finish()

    # the one big ear, after the plates (a plate keep-out round its base would strip the small sponson bare)
    K.dish('D1', (1.98, -0.37, 0.62), 0.46, yaw=-15, pitch=84, post=0.16, inv='ear',
           note='the one oversized listening dish, 0.9 across (more than half the beam), set nearly flush on the raised dish mount, canted a little forward, on the starboard side of the nose')

    # ---------------- the grabbers: one pair of small arms under the chin ----------------
    for side, fi in ((1, 'J1'), (-1, 'J2')):
        K.claw_arm(fi, (2.2, 0.34 * side, -0.72), [(2.6, 0.41 * side, -0.82), (2.88, 0.45 * side, -0.76)], w=0.22, hook=-1.0 if side > 0 else 1.0, fork=0.32,
                   inv='grabbers', housing=(1.9, 2.37, 0.34 * side - 0.15, 0.34 * side + 0.15, -0.8, -0.46),
                   note='%s grabber arm under the chin: pins a fleeing hull long enough for the pack to catch up' % ('port' if side > 0 else 'starboard'))
    K.pipe('PH1', [(2.75, 0.0, -0.42), (2.35, 0.0, -0.53), (2.0, 0.0, -0.58)], r=0.03, inv='chin_pipes', note='the rams\' hydraulic feed')

    # ---------------- the one gun: data.js autocannon T, on the gun block of the spine ----------------
    K.gun('T1', (0.45, 0.02, 0.66), 0, 6, barrels=2, cal=0.052, blen=0.74, size=0.52, slot='T', weapon='autocannon', inv='autocannon',
          note='twin autocannon turret on the spine\'s gun block, all round (data.js c_raider\'s only weapon)')

    # ---------------- engines: the overburn drums on short pylons at the stern quarters (port larger, as the picture), a small centre bell ----------------
    for side, y, r, ex, nm in ENG:
        K.engine('E%d' % (1 if side > 0 else 2), (ex, y, 0.0), r, 1.0, bell=1.12, rings=3, body_r=r * 1.12, nose='flat', inv='engines',
                 src='picture', note='%s: the overburn engine' % nm)
    K.engine('E3', (-3.15, 0.0, -0.09), 0.17, 0.45, bell=1.1, rings=2, body_r=0.19, nose='flat', inv='engines', src='picture', note='small centre bell under the block')
    for i, (x, z, side) in enumerate(THR):
        K.thruster('Q%d' % (i + 1), (x, sy(x, side), z), (0, side, 0), r=0.13, inv='thrusters', note='bow' if x > 0 else 'stern')
    for (x, side) in LAMPS:
        i = {2.2: 0, -0.35: 1, -1.65: 2}[x]
        K.lamp('L%d%s' % (i, 'p' if side > 0 else 's'), (x, max(sy(x - 0.05, side), sy(x + 0.05, side), key=abs) + 0.01 * side, -0.36), (0, side, 0), inv='lamps')

    # ---- colour zones ----
    K.colour('soot and weathered plate', 3.3, -3.2, 'whole hull')
    K.colour('bare iron sponson', 2.42, 1.22, 'starboard bow shoulder')
    K.colour('pale Hegemony trophy plate', 0.2, -0.8, 'port flank')
    K.colour('violet Eclipse plate', 1.15, 0.85, 'port foredeck')
    K.colour('dried-blood red patch', -1.35, -1.9, 'aft spine roof')

    # ---------- INSIDE: one deck, as designs.md ----------
    K.deck('main', -0.16, -2.5, 2.25, inset=0.18, t=0.05)
    for i, x in enumerate((2.3, 1.38, -0.25, -1.55, -2.45)):
        K.bulkhead('F%d' % i, x, inset=0.12, t=0.05)
    K.room('sensor_room', 'bridge', 1.55, 2.3, -0.3, 0.3, -0.11, 0.21, note='the listening room under the dish: plotters and the dish feed')
    K.room('grabber_rams', 'machinery', 1.6, 2.2, -0.29, 0.29, -0.39, -0.22, note='rams and winches for the chin grabbers')
    K.room('kennel_nook', 'crew', 0.45, 0.95, -0.48, 0.48, -0.44, -0.22, note='boarding crew kennel')
    K.room('loot_hold', 'hold', -0.15, 0.3, -0.39, 0.39, -0.44, -0.22, note='a loot hold the size of a closet (designs.md)')
    K.room('ready_magazine', 'magazine', 0.3, 0.68, -0.25, 0.25, -0.11, 0.3, note='autocannon belts under the turret')
    K.room('crew_space', 'crew', -1.4, -0.4, -0.43, 0.43, -0.11, 0.3, note='crew bunks and galley, scavenged frames')
    K.room('core', 'core', -1.45, -0.5, -0.39, 0.39, -0.44, -0.22, note='reactor core (hp_core)')
    K.room('engine_room', 'engroom', -2.4, -1.65, -0.48, 0.48, -0.44, 0.26, note='engine room and the overburn feeds to the drums')
    K.armour('wedge bow (forward of 1.6)', 0.12, 'face plate and the sponson\'s front')
    K.armour('flank bricks', 0.08, 'bolted bricks over the flank')
    K.armour('spine', 0.06, '')
    K.armour('belly', 0.07, 'the flat belly, the band stepping in')
    K.armour('engine end', 0.05, 'thinnest: the raider trades armour for speed')
    # R226 (RULEBOOK 5.17): the seam behind the sensor head kinks round every machine: the dish D1 rides with the head, the
    # bow thrusters Q1 and Q2 and the autocannon T1 with the body
    K.break_line('B-1', 1.12, 'behind the sensor head: the head tears away as one ragged piece with the dish still on it (designs.md), '
                 'opening the listening room and the grabber rams',
                 path=[(1.18, 1.3), (1.05, 0.88), (1.16, 0.4), (1.0, -0.05), (1.14, -0.5), (1.04, -0.88), (1.15, -1.3)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors through the hull (R215), hidden until a piece breaks. Patch plates tear first; the hull parts at the weld behind the head, ragged (R186).'))
    K.point('core', 'hp_core', (-1.0, 0, -0.33))
    for i, (x, y, z, sec, side) in enumerate([(0.9, sy(0.9, 1), 0.08, 'prow', 'port'), (-0.65, sy(-0.65, -1), -0.05, 'mid', 'stbd'), (-2.05, sy(-2.05, 1), -0.45, 'eng', 'port')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (1.5, sy(1.5, 1), -0.12), side='port')
    K.point('rcs', 'hp_rcs_1', (1.5, sy(1.5, -1), -0.12), side='stbd')
    K.point('board', 'hp_board_0', (-0.2, sy(-0.2, 1), -0.29), side='port')
    K.point('board', 'hp_board_1', (-0.2, sy(-0.2, -1), -0.29), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207, R233) ----------
    K.change('One gun: a twin autocannon turret on the spine\'s gun block', 'data.js c_raider carries one weapon, autocannon T (R221: weapons from data.js); the picture\'s rows of flank guns, '
             'designs.md\'s two bow casemates and its rocket rack have no slot, so they are not built')
    K.change('Broader body (issue 668, R239): every half-beam out by 0.18 from 1.5 aft (less toward the face), the spine blocks, belly band, engine block and drum pylons with it; widest 2.04 across (was 1.68), hull length to beam 3.2 (was 3.9)',
             'Ryan, Nov 13 2026: "a18 and a19 are much slimmer than concept. It\'s not a huge deal but it\'d add some variety." The beauty reads broader than the sheet\'s top view; the build moves toward it so the family varies in width, not only length. The grille nose, the dish and the lopsided drums are kept')
    K.change('The nose is chunky and tapers forward to the face: 0.96 across and 0.5 tall at the face, widening and deepening over the first 40 percent to 2.0 across at midships, where the body is widest, then easing aft',
             'the Board on round 1 (Nov 13, R233): the build was a long box (1.46 wide almost bow to stern, a 0.4 tall face) with a dish at the front; the concept sheet draws the nose 1.0 across at the face and 1.6 to 1.7 by 40 percent of the length')
    K.change('The one big ear: an oversized listening dish (0.9 across, more than half the beam) set nearly flush on a low raised dish mount on the nose, to starboard',
             'the picture\'s flush disc on the starboard foredeck; designs.md\'s "a little brick with one big ear". Round 2 drops round 1\'s sponson that bulged the shoulder: the outline from above is the nose\'s own taper and swell (the Board)')
    K.change('Lopsided engines: two drums on short pylons at the stern quarters, the port drum clearly larger, and one small centre bell',
             'designs.md (two bells of uneven size) with the picture\'s outrigger drums, the larger on the side the picture draws it; the picture\'s three stacked centre bells become one, so the stern does not read as A16\'s pods')
    K.change('The bow face is a wide intake grille: three louvre panels in one steel frame, 0.56 across, at the end of the nose; the wake-sniffer scoop is that grille',
             'the picture\'s wide grilled face (the Board on round 1: "a chunky tapering nose that ends in a wide intake grille"); designs.md puts the scoop under the chin, and the chin carries the grabbers')
    K.change('One pair of small grabber arms under the chin, splayed a little', 'designs.md: one pair (A17 carries two pairs); the picture shows a pair of hooked claws there')
    K.change('The spine is five stacked blocks with gaps, the gun block and the sensor block the tallest', 'the picture\'s raised spine; stacked and bolted scrap brick (R196, R197), not one smooth deckhouse')
    K.change('Armour bricks bolted on the flanks, two to port and three to starboard; the port flank keeps a pale Hegemony trophy plate', 'the picture\'s patchwork flank; designs.md\'s trophy plate')
    K.change('The antenna array is the kit\'s at 65 percent of its size', 'R224: at full size its base block, sized for the barge, carried half the frigate\'s hull detail per square unit (issue 618: detail scales with the part\'s size)')
    K.change('Every face is plated in courses at the hull\'s plate size (0.16 to 0.36), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses',
             'the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit\'s courses plating (kit.py, opt-in, issue 633)')

    K.change('Four small attitude thrusters', 'a ship in space needs them to turn (the overburn raider turns hard)')
    K.change('Insides: one deck with the listening room, a kennel nook, a closet loot hold, the core and the engine room', 'designs.md; R209, R215')
    K.open_item('Belly detail between the grabber housings and the engine block is designed here; the picture does not show the underside')
