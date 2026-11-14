# corsair_A19: Hullbreaker gutship, the Mauler (Ashfall Hullbreakers destroyer, class Destroyer, 9.5 world units; issue 633).
# Accepted picture: contrib/muse/design/class_family_corsair_2026_11/corsair_A19_beauty.jpg (v6, accepted by Ryan Nov 12 2026,
# PR 625) and corsair_A19_sheet.jpg; designs.md is the design of record for the fittings. data.js c_reaver: torp F, scatter S,
# ability reload. Ryan's ruling for the round: "the two mismatched casemates sit IN the bow face", whatever the beauty's
# foredeck housings suggest; and on v4 and v5, no big gun on the prow ("added a giant front gun again?").
# Measured off the whole concept first (R229): a long flat slab (hull length to beam about 5, length to height about 8.5), its
# defining shape the arrow-head wedge prow: a broad flat bow plate that tapers to a blunt point over the first third (the
# concept sheet: 0.4 across at the tip, 1.3 just behind it, 2.1 by a third of the length) over a sloped chin, a raised spine
# of blocks along the middle, a lower side block widening one flank amidships, a raised stern block with the engines, grabber
# arms under the bow and under the forefoot.
# The Board is the final designer (R233): the build keeps that mass and the wedge (round 2: the Board found round 1's bow
# blunt and square from above), the two casemates in the narrow bow face under the plate's point, and makes the destroyer
# lopsided: its whole scatter battery on the STARBOARD side (data.js scatter S) and the port flank widened by the side block
# with a big pale trophy plate. It is never a small A16 (the barge's wide body and pods) or a small A17 (the cruiser's boxy
# head with two ears).
# +X bow, +Y port, +Z up. Long tube muzzle about x = +4.83, engine exits about x = -4.66. Flat belly z = -0.5, stern block top 0.66.
CODE = 'corsair_A19'
NAME = 'Hullbreaker gutship (the Mauler)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME = "data.js c_reaver (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5"
BEAUTY = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A19_beauty.jpg'
CONCEPT_SHEET = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A19_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(150, 30, 1800, 500), largest=True, flip=False), side=dict(box=(170, 480, 1820, 840), largest=True, flip=False))
CROPS = [('bow (foredeck plate, the two casemates in the face, grabbers)', (120, 380, 1100, 1060)), ('midships (spine, starboard battery)', (560, 160, 1500, 760)),
         ('stern (stern block and engines)', (1000, 60, 1920, 620))]
SHEET = dict(version=1, round='first sheet (issue 633)', date='2026-11-12', blend='opus633\\corsair_A19',
             before='First full layout', before_note='The first complete A19 layout, built with the Hullbreaker kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): see the fit report\'s fix column.')

import math, random

# (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer): the blunt bow face (the two casemates sit
# in it), the sloped chin, the long body, the taper into the stern block
# Issue 668 (R239, Ryan Nov 13: "a18 and a19 are much slimmer than concept. It's not a huge deal but it'd add some variety"):
# the slab is broadened toward the beauty's beam, every half-beam out by WIDEN (0.3) from 2.55 aft, less toward the face so the
# wedge prow keeps its point: hull 2.36 across (was 1.76), hull length to beam 4.0 (was 5.4); the spade, side block, stern
# block and every flank fitting move out with it.
WIDEN = 0.3
HULL = [
    (4.05, 0.62, 0.62, -0.26, 0.26, 0.1, 0.09),
    (3.55, 0.82, 0.82, -0.4, 0.29, 0.12, 0.12),
    (2.55, 0.8 + WIDEN, 0.8 + WIDEN, -0.5, 0.31, 0.14, 0.15),
    (1.5, 0.88 + WIDEN, 0.88 + WIDEN, -0.5, 0.32, 0.14, 0.15),
    (-3.1, 0.86 + WIDEN, 0.86 + WIDEN, -0.5, 0.34, 0.14, 0.15),
    (-3.6, 0.79 + WIDEN, 0.79 + WIDEN, -0.46, 0.32, 0.13, 0.14),
]
PL = dict(keep3d=True, courses=True, size=(0.2, 0.46), thick=(0.025, 0.06), step=0.03, gap=0.02, over=0.2, skip=0.04, stack=0.2, rivets_share=0.25, rivet_r=0.026, mats={'soot': 3, 'iron': 4, 'pale': 2, 'rust': 3, 'soot2': 2, 'violet': 1, 'steel': 2})
# the spine, bow to stern: stacked blocks (name, x fore, x aft, half-beam, top, front slope, y offset), gaps between them
SPINE = [
    ('M1 fore spine block', 1.7, 0.55, 0.64, 0.58, 0.2, 0.02),
    ('M2 battery block', 0.42, -0.98, 0.67, 0.62, 0.1, -0.03),
    ('M3 aft spine block', -1.08, -2.95, 0.64, 0.6, 0.1, 0.0),
]
CASEMATES = [('S1', 1.15, 2, 0.065, 0.62, 0.6, -50), ('S2', -0.45, 1, 0.1, 0.72, 0.72, -45), ('S3', -2.0, 2, 0.055, 0.55, 0.55, -55)]   # (id, x, barrels, cal, blen, size, yaw)
THR = [(2.75, -0.24, 1), (2.75, -0.24, -1), (-3.55, -0.24, 1), (-3.55, -0.24, -1)]
LAMPS = [(3.3, 1, -0.3), (1.9, 1, -0.32), (-1.95, 1, -0.38)]   # port; the starboard lamps sit on the brick faces (BRICKS)
BRICKS = [(2.35, 1.6, 0.12), (0.55, 0.12, 0.04), (-1.02, -1.5, 0.15), (-2.45, -2.95, 0.07)]   # starboard bricks (x fore, x aft, top)
ENG = (('E1', 0.0, 0.08, 0.34, 'centre bell, the largest'), ('E2', 0.62, 0.42, 0.22, 'port upper bell'), ('E3', -0.64, -0.36, 0.24, 'starboard lower bell'))
SB_TOP = 0.66      # the stern block's roof


def face_launcher(K, fid, pos, tubes, r, reach, depth, variant, inv, note):
    """a rocket casemate set IN the bow face (Hullbreaker kit bow_launcher, issue 633): the part placed with +X out of the face,
    registered as a data.js launcher (torp F) with its firing lane, backblast and launch exits, as K.launcher does for a rack"""
    from mathutils import Vector
    import kit as _k
    HP = _k.HP
    p = Vector(pos)
    part = HP.bow_launcher(tubes, r, reach, depth=depth, variant=variant)
    part = K.emit(fid, part, HP.frame(p, (1, 0, 0), (0, 0, 1)), inv)
    ex = [dict(pos=tuple(e['pos'][1]), axis=tuple(e['axis'][1]), r=e['radius']) for e in part.fit['exits']]
    dv = Vector((1, 0, 0)); cv = sum((Vector(e['pos']) for e in ex), Vector()) / len(ex)
    uv = Vector((0, 1, 0)); wv = Vector((0, 0, 1))
    hu = max(abs((Vector(e['pos']) - cv).dot(uv)) + e['r'] for e in ex) + 0.1
    hw = max(abs((Vector(e['pos']) - cv).dot(wv)) + e['r'] for e in ex) + 0.1
    lane = dict(apex=tuple(cv), dir=tuple(dv), u=tuple(uv), w=tuple(wv), hu=hu, hw=hw, half=4.0, length=K.length * 0.8, what='firing lane')
    blast = dict(apex=tuple(cv - dv * (depth + reach)), dir=tuple(-dv), u=tuple(uv), w=tuple(wv), hu=hu, hw=hw, half=15.0,
                 length=max(2.5 * (depth + reach), 0.15 * K.length), what='backblast')
    K.fitdata.append(dict(id=fid, kind='launcher', slot='F', lanes=[lane, blast],
                          apertures=[dict(pos=e['pos'], dir=e['axis'], r=e['r'], length=K.length * 0.8, cone=4.0, what='launch tube') for e in ex]))
    K.features.append(dict(id=fid, kind='launcher', what='rocket casemate in the bow face, %s' % ('one long tube' if tubes == 1 else '%d short fat tubes' % tubes),
                           count=tubes, pos=tuple(p), aim=(0.0, 0.0), slot='F', weapon='torp', src='picture', note=note, inv=[inv]))


def build(K):
    import kit as _k
    from mathutils import Vector
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Base hull (blunt bow, chin, long body)', K.hull(HULL, 'soot', shell=0.1, plates=dict(PL, seed=19, inv=['hull_plates', 'belly_plates'])),
           'soot and patched plate', note='the blunt bow face over a sloped chin, then the long low body')
    K.mark('hull_form', 'hull', ['bevel', 'step', 'overhang'])
    K.mass('Lower hull band', K.loft('A19_lowband', [(3.0, 1.06, 1.06, -0.54, -0.3, 0.0, 0.07), (-3.4, 0.84 + WIDEN, 0.84 + WIDEN, -0.54, -0.3, 0.0, 0.07)], 'soot2',
                                     plates=dict(PL, seed=20, faces=[3, 4, 5, 6, 7, 0], inv='belly_plates')), 'dark soot', note='the belly steps in under the flank')
    # the foredeck plate: the picture's broad flat spade over the bow, its tip a blunt wedge from above, overhanging the flanks
    K.mass('Foredeck plate (the spade)', K.loft('A19_spade', [(4.62, 0.2, 0.2, 0.2, 0.31, 0.03, 0.02), (4.15, 0.72, 0.72, 0.21, 0.38, 0.05, 0.03),
                                                             (3.2, 1.05, 1.05, 0.23, 0.42, 0.07, 0.03), (2.2, 1.3, 1.3, 0.25, 0.44, 0.07, 0.03),
                                                             (1.6, 1.34, 1.34, 0.26, 0.45, 0.07, 0.03), (1.15, 1.34, 1.34, 0.26, 0.45, 0.07, 0.03),
                                                             (0.9, 1.24, 1.24, 0.26, 0.42, 0.06, 0.03)],
                                                'iron', plates=dict(PL, seed=21, faces=[0, 1, 2], inv='spade_plates', size=(0.16, 0.36))),
           'bare iron and trophy plate', note='the broad flat bow plate, an arrow-head wedge from above: a blunt point that widens over the first third (the picture\'s spade)')
    K.mark('spade', 'tier', ['face', 'roof', 'opening'])
    for (nm, x0, x1, hw, top, slope, yo) in SPINE:
        base = 0.3 if x0 < 0.9 else 0.4
        secs = [(x0, hw - 0.12, hw - 0.12, base, top - slope * 0.7, 0.05, 0.03, yo),
                (x0 - slope * 0.8, hw, hw, base, top, 0.09, 0.03, yo),
                (x1 + 0.08, hw, hw, base, top, 0.09, 0.03, yo),
                (x1, hw - 0.06, hw - 0.06, base, top - 0.06, 0.07, 0.03, yo)]
        K.mass(nm, K.loft('A19_' + nm.split()[0], secs, 'soot', plates=dict(PL, seed=sum(map(ord, nm)) % 997, faces=[0, 1, 2, 3, 7], size=(0.13, 0.3))),
               'soot with dried-blood patches', note='stacked spine block, top %.2f' % top)
    K.mark('spine', 'tier', ['face', 'roof', 'opening'])
    # the port side block: the picture's lower block widening the port flank amidships, carrying the big trophy plate
    K.mass('Port side block', K.loft('A19_sideblock', [(0.85, 1.34, -0.98, -0.46, 0.0, 0.07, 0.07), (0.6, 1.42, -0.98, -0.5, 0.1, 0.09, 0.09),
                                                       (-2.55, 1.42, -0.98, -0.5, 0.1, 0.09, 0.09), (-2.85, 1.32, -0.98, -0.44, 0.02, 0.07, 0.07)],
                                       'soot2', plates=dict(PL, seed=24, faces=[0, 6, 7], inv='side_block_plates')),
           'dark soot', note='widens the port flank amidships (the picture\'s side block)')
    K.mark('side_block', 'tier', ['face', 'roof', 'opening'])
    # starboard: armour bricks between the casemates
    for i, (x0, x1, top) in enumerate(BRICKS):
        hw = abs(sy((x0 + x1) / 2, -1))
        ob = K.loft('A19_brick_%d' % i, [(x0, -(hw - 0.2), hw + 0.1, -0.42, top, 0.05, 0.05), (x1, -(hw - 0.2), hw + 0.1, -0.42, top, 0.05, 0.05)],
                    ('soot', 'iron', 'soot2', 'iron')[i], plates=dict(PL, seed=330 + i, faces=[2, 3, 4], size=(0.16, 0.36)))
        K.mass('Starboard brick %d' % (i + 1), ob, 'patched plate', note='armour brick between the casemates')
    K.mark('bricks', 'tier', ['face', 'roof', 'opening'])
    K.mass('Stern block', K.loft('A19_sternblock', [(-2.98, 1.2, 1.2, -0.5, SB_TOP - 0.06, 0.13, 0.13), (-3.15, 1.24, 1.24, -0.52, SB_TOP, 0.15, 0.14),
                                                    (-3.95, 1.24, 1.24, -0.52, SB_TOP, 0.15, 0.14), (-4.08, 1.16, 1.16, -0.46, SB_TOP - 0.08, 0.13, 0.12)],
                                    'soot', plates=dict(PL, seed=26, inv='stern_plates', size=(0.16, 0.36))), 'soot, rust', note='the raised stern block that carries the engines')
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])
    # small fittings on the plated masses
    # the big pale trophy plate: three torn Hegemony sheets bolted edge to edge, not one smooth face (round 2)
    for k, (x, w, h, a) in enumerate(((0.05, 0.75, 0.46, 0.03), (-0.73, 0.62, 0.5, -0.05), (-1.43, 0.66, 0.42, 0.06))):
        K.patch('TP1%s' % 'abc'[k], (x, 1.431, -0.2 + 0.02 * (k - 1)), (0, 1, 0), w, h, ang=a, lift=0.04, t=0.05, m='pale', inv='trophy')
    K.patch('TP2', (3.0, -0.45, 0.435), (0, 0, 1), 0.7, 0.48, ang=0.2, lift=0.03, t=0.04, m='violet', inv='trophy')
    K.patch('TP3', (2.1, 0.55, 0.445), (0, 0, 1), 0.6, 0.42, ang=-0.15, lift=0.03, t=0.04, m='rust', inv='trophy')
    K.patch('RC1', (0.12, -0.25, 0.625), (0, 0, 1), 0.6, 0.4, ang=0.06, lift=0.02, t=0.03, m='blood', inv='trophy')
    K.hatchbox('HB1', (-0.55, 0.3, 0.62), 0.3, 0.36, 0.11, inv='spine_boxes', note='ready-use locker for the scatter crews on the battery block')
    K.hatchbox('HB2', (-2.55, 0.28, 0.6), 0.3, 0.34, 0.1, inv='spine_boxes', note='framed box on the aft spine block')
    K.hatch('HS1', (-2.35, 1.421, -0.18), (0, 1, 0), 0.34, 0.2, up=(0, 0, -1), inv='hatches', note='crew hatch in the port side block')
    K.hatch('HS2', (-3.88, 1.241, 0.12), (0, 1, 0), 0.26, 0.22, up=(0, 0, -1), inv='hatches', note='engine room hatch on the stern block, port')
    K.slit('SL1', (1.62, 0.3, 0.53), (0.58, 0.0, 0.81), 0.2, 0.055, inv='spine', note='slit in the fore spine block\'s slope')
    for side in (1, -1):
        K.vent('VS%s' % ('p' if side > 0 else 's'), (-3.3, 1.241 * side, 0.32), (0, side, 0), 0.4, 0.26, slats=4, inv='vents', note='engine room louvre')
    K.antenna('AN1', (-3.45, 0.5, SB_TOP), 0.85, whips=3, inv='antenna', note='comms array on the stern block: the pack\'s gun ship hears the Sniffer\'s calls')

    # the plates go on now, before the machines claim their mounts (issue 633: the kit's default keep-outs strip a small hull)
    for (x, z, side) in THR:
        K.keepouts.append((Vector((x, sy(x, side) if x > -3.0 else 1.24 * side, z)), 0.24))
    for (x, side, z) in LAMPS:
        K.keepouts.append((Vector((x, 1.42 if -2.55 < x < 0.6 else sy(x, side), z)), 0.13))
    for (x0, x1, top) in BRICKS:
        K.keepouts.append((Vector(((x0 + x1) / 2, -abs(sy((x0 + x1) / 2, -1)) - 0.1, -0.2)), 0.13))
    for (fid, x, *_r) in CASEMATES:
        K.keepouts.append((Vector((x, sy(x, -1), -0.1)), 0.32))
    K.keepouts.append((Vector((3.0, 0.55, 0.43)), 0.22))           # the dishes' bases
    K.keepouts.append((Vector((-3.45, -0.55, SB_TOP)), 0.2))
    for x, z in ((1.12, 0.58), (-1.85, 0.6)):
        K.keepouts.append((Vector((x, -0.05, z)), 0.48))
    K.finish()

    # ---------------- the bow face: the two mismatched rocket casemates IN it (data.js torp F; Ryan's ruling) ----------------
    face_launcher(K, 'R1', (4.06, 0.32, 0.0), 1, 0.09, 0.52, 0.24, 0, 'bow_launchers',
                  'port casemate: one long rocket tube on a brace (the long-barrelled one)')
    face_launcher(K, 'R2', (4.06, -0.3, -0.01), 3, 0.074, 0.13, 0.24, 1, 'bow_launchers',
                  'starboard casemate: three short fat tubes banded together (the short and fat one)')
    K.tube('I1', (3.98, 0.0, -0.58), 0.11, 0.4, grille=True, bands=2, inv='scoop', what='wake-sniffer scoop with a grille',
           note='chin scoop under the face (designs.md)')
    # ---------------- grabbers: a pair under the chin, a pair under the forefoot ----------------
    for side, fa, fb in ((1, 'J1', 'J3'), (-1, 'J2', 'J4')):
        s_ = 'port' if side > 0 else 'starboard'
        K.claw_arm(fa, (3.4, 0.42 * side, -0.72), [(3.85, 0.48 * side, -0.86), (4.15, 0.52 * side, -0.8)], w=0.28, hook=-1.0, fork=0.32,
                   inv='grabbers', housing=(3.1, 3.62, 0.42 * side - 0.18, 0.42 * side + 0.18, -0.8, -0.4),
                   note='%s chin grabber: pins a hull against the bow casemates' % s_)
        K.claw_arm(fb, (1.1, 0.48 * side, -0.86), [(1.5, 0.54 * side, -1.0), (1.76, 0.57 * side, -0.95)], w=0.28, hook=1.0, fork=0.32,
                   inv='grabbers', housing=(0.8, 1.32, 0.48 * side - 0.18, 0.48 * side + 0.18, -0.94, -0.46),
                   note='%s forefoot grabber: the second bite, under the body' % s_)
    K.pipe('PH1', [(3.1, 0.0, -0.56), (2.3, 0.0, -0.58), (1.55, 0.0, -0.6)], r=0.035, inv='belly_pipes', note='hydraulic feed between the two grabber pairs')
    # ---------------- the dishes: large on the port bow shoulder, small on the starboard side of the stern block ----------------
    K.dish('D1', (3.0, 0.55, 0.427), 0.28, yaw=30, pitch=22, post=1.3, inv='dishes', note='the larger listening dish on the foredeck plate to port')
    K.dish('D2', (-3.45, -0.3, SB_TOP), 0.22, yaw=-55, pitch=18, post=1.25, inv='dishes', note='the small dish on the stern block, starboard')
    # ---------------- the scatter battery: data.js scatter S, all on the starboard side ----------------
    for (fid, x, nb, cal, blen, size, yaw) in CASEMATES:
        K.gun(fid, (x, sy(x, -1) - 0.02, -0.1), yaw, 0, barrels=nb, cal=cal, blen=blen, size=size, normal=(0, -1, 0), slot='S', weapon='scatter',
              inv='casemates', variant=int(x < 0), note='starboard flank casemate, %s' % ({1: 'one fat barrel', 2: 'twin barrels'}[nb]))
    K.gun('S4', (1.12, -0.05, 0.58), -35, 4, barrels=2, cal=0.062, blen=0.72, size=0.62, slot='S', weapon='scatter', inv='deck_turrets',
          note='fore spine turret, superfiring over the casemates to starboard')
    K.gun('S5', (-1.85, -0.05, 0.6), -40, 4, barrels=2, cal=0.06, blen=0.7, size=0.6, slot='S', weapon='scatter', inv='deck_turrets', variant=1,
          note='aft spine turret')
    # ---------------- engines: three bells in the stern block, the centre the largest ----------------
    for (fid, y, z, r, nm) in ENG:
        K.engine(fid, (-4.66, y, z), r, 0.6, bell=1.1, rings=3 if r > 0.3 else 2, body_r=r * 1.1, nose='flat', inv='engines', src='picture', note=nm)
    for i, (x, z, side) in enumerate(THR):
        K.thruster('Q%d' % (i + 1), (x, sy(x, side) if x > -3.0 else 1.24 * side, z), (0, side, 0), r=0.17, inv='thrusters', note='bow' if x > 0 else 'stern')
    for i, (x, side, z) in enumerate(LAMPS):
        y = 1.42 if -2.55 < x < 0.6 else max(sy(x - 0.05, side), sy(x + 0.05, side), key=abs)
        K.lamp('L%d' % i, (x, y + 0.01, z), (0, 1, 0), inv='lamps')
    for i, (x0, x1, top) in enumerate(BRICKS):
        K.lamp('L%d' % (i + 3), ((x0 + x1) / 2, -abs(sy((x0 + x1) / 2, -1)) - 0.1 - 0.005, -0.22), (0, -1, 0), inv='lamps')

    # ---- colour zones ----
    K.colour('soot and weathered plate', 4.85, -4.7, 'whole hull')
    K.colour('bare iron foredeck plate', 4.3, 0.9, 'the spade')
    K.colour('pale Hegemony trophy plate', 0.35, -2.25, 'port side block')
    K.colour('violet Eclipse plate', 3.35, 2.65, 'foredeck, starboard')
    K.colour('dried-blood red patch', 0.42, -0.18, 'battery block roof')

    # ---------- INSIDE: two decks (designs.md) ----------
    K.deck('lower', -0.24, -2.95, 3.45, inset=0.22, t=0.06)
    K.deck_box('upper', 0.16, -2.9, 1.55, 0.4, t=0.05)
    for i, x in enumerate((3.55, 2.05, 0.2, -1.35, -2.65)):
        K.bulkhead('F%d' % i, x, inset=0.14, t=0.06)
    K.room('rocket_magazine', 'magazine', 3.15, 3.85, -0.5, 0.5, -0.2, 0.18, note='the casemates\' rockets, behind the bow face')
    K.room('kennel_deck', 'crew', 2.45, 3.4, -0.55, 0.55, -0.42, -0.28, note='boarding gangs under the bow, behind the chin grabbers')
    K.room('gun_gallery', 'crew', -2.6, 1.55, -1.0, -0.74, -0.2, 0.12, note='the scatter crews\' gallery along the starboard casemates')
    K.room('shell_magazine', 'magazine', -1.2, 0.0, -0.3, 0.3, 0.2, 0.46, note='scatter shells in the battery block')
    K.room('crew_decks', 'crew', -2.6, -1.45, -0.3, 0.46, 0.2, 0.44, note='bunks and galley in the aft spine block')
    K.room('core', 'core', -1.25, 0.1, -0.35, 0.6, -0.42, -0.28, note='reactor core (hp_core)')
    K.room('loot_hold', 'hold', -2.65, -1.45, -0.6, 0.6, -0.42, -0.28, note='the loot hold aft (designs.md)')
    K.room('grabber_rams', 'machinery', 0.35, 1.9, -0.62, 0.62, -0.42, -0.28, note='rams and winches for both grabber pairs')
    K.room('engine_room', 'engroom', -3.85, -3.25, -1.0, 1.0, -0.4, 0.44, note='engine room in the stern block')
    K.armour('bow (forward of 3.2)', 0.16, 'the face and the foredeck plate: the casemates fire from under it')
    K.armour('starboard flank', 0.12, 'bricks between the casemates')
    K.armour('port side block', 0.1, 'and the trophy plate')
    K.armour('spine', 0.08, '')
    K.armour('stern block', 0.1, '')
    # R226 (RULEBOOK 5.17): each seam kinks round the machines near it: B-1 runs between the forefoot grabbers (with the body)
    # and the bow's thrusters and dish; B-2 between the aft turret S5 and casemate S3 (body) and the stern block's machines
    K.break_line('B-1', 2.42, 'the bow block weld: the bow tears away whole with its casemates, the foredeck plate\'s front, the dish and the chin grabbers (designs.md)',
                 path=[(2.44, 1.6), (2.37, 0.8), (2.5, 0.3), (2.36, -0.1), (2.48, -0.5), (2.36, -0.9), (2.42, -1.6)])
    K.break_line('B-2', -2.95, 'the stern block weld: the stern block and its engines tear away, opening the engine room and the loot hold',
                 path=[(-2.9, 1.6), (-3.02, 0.85), (-2.88, 0.35), (-3.04, -0.05), (-2.9, -0.45), (-3.05, -0.85), (-2.92, -1.6)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors through the hull (R215), hidden until a piece breaks. Patch plates tear first, then the bow block and the stern block part at their welds, ragged (R186).'))
    K.point('core', 'hp_core', (-0.6, 0.1, -0.36))
    for i, (x, y, z, sec, side) in enumerate([(2.0, sy(2.0, 1) + 0.01, 0.0, 'prow', 'port'), (0.25, sy(0.25, -1) - 0.01, -0.25, 'mid', 'stbd'), (-1.15, 1.44, -0.12, 'mid', 'port'),
                                              (-3.3, -1.26, 0.0, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (2.75, sy(2.75, 1), -0.24), side='port')
    K.point('rcs', 'hp_rcs_1', (2.75, sy(2.75, -1), -0.24), side='stbd')
    K.point('board', 'hp_board_0', (0.0, 1.43, -0.3), side='port')
    K.point('board', 'hp_board_1', (-1.75, sy(-1.75, -1), -0.36), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207, R233) ----------
    K.change('The two mismatched casemates sit IN the bow face: port, one long rocket tube on a brace; starboard, three short fat tubes banded together',
             'Ryan, Nov 12 (the round\'s ruling): "the two mismatched casemates sit IN the bow face", whatever the beauty\'s foredeck housings suggest. data.js c_reaver\'s '
             'only forward weapon is torp F, so both are rocket casemates (the Hullbreaker rattle rockets); the long tube stays short of a prow gun (RULEBOOK 4.4, Ryan on v5 "added a giant front gun again?")')
    K.change('Broader slab (issue 668, R239): every half-beam out by 0.3 from 2.55 aft (less toward the face), the foredeck plate, side block, stern block, spine blocks and every flank fitting with it; hull 2.36 across (was 1.76), hull length to beam 4.0 (was 5.4)',
             'Ryan, Nov 13 2026: "a18 and a19 are much slimmer than concept. It\'s not a huge deal but it\'d add some variety." The beauty reads a broad flat slab; the build moves toward it so the family varies in width, not only length. The wedge prow keeps its blunt point and the casemates their narrow face')
    K.change('The bow is an arrow-head from above: the broad flat bow plate runs from a blunt point 0.4 across to the full beam over the first third, overhanging a narrow bow face (1.24 across, 0.52 tall) that holds the two casemates; the hull\'s flanks widen back behind it',
             'the Board on round 1 (Nov 13, R233): the build had a blunt square bow; the picture\'s defining shape is the wedge prow (the concept sheet: 0.4 across at the tip, 1.3 just behind it, 2.1 by a third of the length). The face stays blunt and narrow, not a thin edge: the casemates need a face to sit in (designs.md)')
    K.change('Every face is plated in courses at the hull\'s plate size (0.2 to 0.46), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses',
             'the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit\'s courses plating (kit.py, opt-in, issue 633)')

    K.change('The whole scatter battery on the starboard side: three flank casemates of mixed calibre and two spine turrets resting to starboard',
             'data.js c_reaver: scatter S (one starboard battery); the picture\'s pods on both flanks and its foredeck guns have no other slot (R221)')
    K.change('No rocket racks on the middle deck', 'designs.md\'s two racks would be a second forward launcher; data.js gives one torp slot and the bow casemates fire it')
    K.change('Port flank: the side block carries one big pale Hegemony trophy plate, in three torn sheets bolted edge to edge', 'designs.md (the trophy plate widening the port outline amidships) on the picture\'s side block')
    K.change('Two grabber pairs: one under the chin, one under the forefoot', 'the picture\'s claws at the chin and further aft; designs.md\'s four arms; split so the jaw is not a copy of A17\'s')
    K.change('Three engine bells, the centre the largest, staggered in the stern block', 'designs.md; the picture\'s four become three, lopsided (port small and high, starboard lower)')
    K.change('Two dishes: the large one standing on the foredeck plate to port, a small one on the stern block to starboard', 'designs.md; the picture shows one on the foredeck')
    K.fix('SENSOR: S5 aiming through the small dish D2 at its aft bearings', 'R240 (Ryan, Nov 13: guns right behind or facing dishes and antennae): D2 moved inboard on the stern block (y -0.55 to -0.3), out of the arc of S5')
    K.change('Four attitude thrusters', 'a ship in space needs them to turn')
    K.change('Insides: two decks, the gun crews\' gallery along the starboard casemates, a kennel deck under the bow, the loot hold aft', 'designs.md; R209, R215')
    K.open_item('Belly detail between the grabber pairs and the stern block is designed here; the picture shows little of the underside')
