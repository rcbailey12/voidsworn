# corsair_A17 round 3: Hullbreaker wrecker, the Pack Hunter (Ashfall Hullbreakers cruiser, class Cruiser, 14.5 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg (R201), from round 1 Pack Hunter
# (concept_directions_2026_11/corsair_B.jpg, R197). data.js c_marauder: scatter P, scatter S, torp F, flak T (no hangar).
# Round 3b (the Board on round 3: the massing did not match: "short, tall and round, a lump"; RULEBOOK 5.7 structure first).
# Measured off the round 8 sheet's true side and top views: hull length to beam 2.75 and length to height 4.06 (median over
# the middle 60 percent), the head narrow (about 1.9) between its scoop drums, long flat prongs reaching about a sixth of the
# length ahead of the head, the body a base hull with flank blocks and six top blocks stepping up toward the stern with gaps
# and undercuts, a stacked engine cluster. Built to those numbers at the data.js length.
# +X bow, +Y port, +Z up. Prong hooks about x = +7.25, engine exits x = -7.25. Flat belly z = -1.6, tallest block 1.87.
CODE = 'corsair_A17'
NAME = 'Hullbreaker wrecker (the Pack Hunter)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg'

# (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer)
# the head: a chamfered face that overhangs the jaw mouth (the bottom rises from -1.65 at 3.6 to -0.7 at the face), the neck
# pinched behind it, then the lean body
# the base hull (flank tier): the narrow head (x 6.2 to 4.3) then the body; the jaw mouth is cut in under the head face
# round 4 (A17 build, issue 532): the face is a narrower panel framed by big angled planes, a deep bevel all round as in the
# beauty, not a flat end (Ryan R217: "the front is also just a flat block which does not match the concept")
HULL = [
    (6.25, 1.08, 1.08, -0.42, 1.02, 0.3, 0.16),
    (5.8, 1.65, 1.65, -0.7, 1.48, 0.42, 0.28),
    (4.35, 1.7, 1.7, -0.82, 1.52, 0.42, 0.3),
    (4.05, 2.15, 2.2, -1.6, 0.42, 0.42, 0.45),
    (0.0, 2.3, 2.35, -1.6, 0.45, 0.42, 0.45),
    (-4.6, 2.3, 2.35, -1.6, 0.45, 0.42, 0.45),
    (-5.45, 2.0, 2.05, -1.4, 0.4, 0.38, 0.38),
]
PL = dict(size=(0.3, 0.75), thick=(0.03, 0.1), skip=0.1, stack=0.45, mats={'soot': 5, 'iron': 5, 'pale': 2, 'rust': 2, 'soot2': 2})
# the top blocks, bow to stern: (name, x fore, x aft, half-beam at the top, half-beam at the base, top, front slope, y offset)
# they step up toward the stern (concept side view: 0.47, 1.2, 1.6, 1.73, 1.87), with gaps between them and undercut bases
TOP = [
    ('U1 neck block', 4.0, 2.5, 1.5, 1.4, 1.12, 0.25, 0.0),
    ('U2 fore block', 2.35, 0.85, 1.85, 1.7, 0.9, 0.35, 0.08),
    ('U3 ramp block', 0.75, -0.15, 1.8, 1.75, 1.2, 0.7, -0.05),
    ('U4 mid block', -0.28, -1.85, 2.03, 1.75, 1.3, 0.25, 0.1),
    ('U5 saddle block', -1.98, -3.05, 1.7, 1.65, 1.4, 0.2, -0.12),
    ('U6 aft block', -3.18, -5.55, 2.1, 1.85, 1.52, 0.3, 0.05),
]


def build(K):
    import kit as _k
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Base hull (head and flank tier)', K.hull(HULL, 'soot', shell=0.2, plates=dict(PL, seed=17, inv=['head_plates', 'belly_plates'])),
           'weathered grey and soot plate', note='narrow head over a cut-in jaw mouth, then the long low body')
    K.mass('Lower hull band', K.loft('A17_lowband', [(3.9, 2.0, 2.05, -1.64, -1.0, 0.0, 0.22), (-5.2, 2.0, 2.05, -1.64, -1.0, 0.0, 0.22)], 'soot2',
                                     plates=dict(PL, seed=18, faces=[3, 4, 5, 6, 7, 0], inv='belly_plates')), 'dark soot', note='the belly steps in under the flank tier')
    # ---------------- the head: brow, crown, face panels ----------------
    K.mass('Head brow (step 1)', K.loft('A17_brow', [(5.72, 1.2, 1.2, 1.4, 1.6, 0.16, 0), (5.45, 1.35, 1.35, 1.4, 1.75, 0.22, 0),
                                                     (4.45, 1.38, 1.38, 1.4, 1.8, 0.22, 0)], 'pale', plates=dict(PL, seed=27, faces=[0, 1, 2, 3], inv='head_plates')),
           'pale grey trophy plate', note='the first roof step, sloped at its front')
    K.mass('Head crown (step 2)', K.loft('A17_crown', [(5.35, 0.75, 0.75, 1.72, 1.88, 0.1, 0), (5.15, 0.82, 0.82, 1.72, 1.98, 0.12, 0),
                                                       (4.55, 0.82, 0.82, 1.72, 1.98, 0.12, 0)], 'soot'), 'soot', note='the second step')
    K.loft('A17_mouth_roof', [(6.05, 0.95, 0.95, -0.62, -0.46, 0.04, 0.04), (5.75, 1.35, 1.35, -0.74, -0.58, 0.04, 0.06),
                              (4.45, 1.35, 1.35, -0.84, -0.66, 0.04, 0.06)], 'dark')
    K.mark('head', 'hull', ['bevel', 'step', 'overhang'])
    for i, (y, w) in enumerate(((0.48, 0.8), (-0.48, 0.8))):
        K.patch('FP%d' % i, (6.26, y, 0.3), (1, 0, 0), w, 1.15, ang=0.03 * (1 if i else -1), lift=0.015, t=0.05, m='iron', inv='head_face')
    for i, y in enumerate((0.95, 0.0, -0.95)):
        K.box('A17_strap%d' % i, 6.2, 6.33, y - 0.05, y + 0.05, -0.32, 0.92, 'steel')
    # the bevel frame round the face: armour plates on the angled corner and brow planes, and a lower lip
    for side in (1, -1):
        K.patch('FB%s' % ('p' if side > 0 else 's'), (6.03, 1.36 * side, 0.32), (0.8, 0.6 * side, 0), 0.62, 1.05, ang=0.04 * side, lift=0.03,
                t=0.05, m='iron' if side > 0 else 'pale', inv='head_face')
    K.patch('FBT', (6.03, 0.0, 1.25), (0.72, 0, 0.69), 1.5, 0.45, ang=0.02, lift=0.03, t=0.05, m='pale', inv='head_face')
    K.box('A17_face_lip', 5.95, 6.3, -0.95, 0.95, -0.5, -0.36, 'steel', ch=0.04)
    K.mark('head_face', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    K.box('A17_rust_brow', 4.95, 5.3, 0.9, 1.3, 1.72, 1.8, 'rust')

    # ---------------- the body: flank blocks (both sides, junky and unmatched) and the stepped top blocks ----------------
    import random
    rb = random.Random(1717)
    nfl = 0
    for side in (1, -1):
        xs = [(3.35, 2.55), (2.35, 0.95), (0.75, -1.2), (-1.4, -2.95), (-3.15, -4.5)]
        for i, (x0, x1) in enumerate(xs):
            if side < 0 and i in (1, 2):
                x0, x1 = x0 - 0.2, x1 - 0.12
            out = 0.28 if i == 3 else rb.uniform(0.16, 0.3); zb = -0.72; zt = 0.3 if i == 3 else rb.uniform(0.15, 0.38)
            hw = abs(sy((x0 + x1) / 2, side))
            a, b = (hw + out, -(hw - 0.4)) if side > 0 else (-(hw - 0.4), hw + out)
            ob = K.loft('A17_flank_%d%s' % (i, 'p' if side > 0 else 's'), [(x0, a, b, zb, zt, 0.12, 0.1), (x1, a, b, zb, zt, 0.12, 0.1)],
                        rb.choice(['soot', 'iron', 'soot2']),
                        plates=dict(PL, seed=200 + i * 7 + (side > 0), faces=[6, 7, 0] if side > 0 else [2, 3, 4], size=(0.25, 0.6)))
            K.mass('Flank block %d %s' % (i + 1, 'port' if side > 0 else 'starboard'), ob, 'patched plate', note='armour block on the flank tier')
            nfl += 1
    K.mark('hump', 'tier', ['face', 'roof', 'opening'])
    for (nm, x0, x1, hwt, hwb, top, slope, yo) in TOP:
        base = 0.4
        secs = [(x0, hwt - 0.25, hwt - 0.25, base, top - slope * 0.6, 0.12, max(0.0, hwt - hwb), yo),
                (x0 - slope * 0.7, hwt, hwt, base, top, 0.18, max(0.0, hwt - hwb), yo),
                (x1 + 0.12, hwt, hwt, base, top, 0.18, max(0.0, hwt - hwb), yo),
                (x1, hwt - 0.12, hwt - 0.12, base, top - 0.12, 0.12, max(0.0, hwt - hwb), yo)]
        K.mass(nm, K.loft('A17_' + nm.split()[0], secs, 'soot', plates=dict(PL, seed=hash(nm) % 997, faces=[0, 1, 2, 3], size=(0.3, 0.7))),
               'soot with dried-blood patches', note='stepped top block, top %.2f, undercut base' % top)
    K.box('A17_red_crest', -3.6, -4.9, -1.1, 0.4, 1.5, 1.54, 'blood')
    for side in (1, -1):
        K.slit('SL%d' % (1 if side > 0 else 2), (0.47, 0.7 * side - 0.05, 1.02), (0.65, 0, 0.76), 0.55, 0.12, inv='hump', note='slit in the ramp block slope')
        K.hatch('HS%d' % (1 if side > 0 else 2), (-4.35, 2.15 if side > 0 else -2.05, 0.98), (0, side, 0), 0.4, 0.5, inv='stern_hatch',
                note='hatch on the aft block flank')
    K.mass('Engine block', K.box('A17_engblock', -6.0, -5.4, -2.0, 2.0, -1.35, 1.35, 'soot', ch=0.22, plates=dict(PL, seed=57, faces=[0, 1, 2, 3, 4, 5, 6, 7])), 'soot, steel')
    K.mark('engine_block', 'pylon', ['web', 'plate'])
    K.loft('A17_belt', [(x, _k.sec_at(HULL, x)[1] + 0.12, _k.sec_at(HULL, x)[2] + 0.12, -1.25, -1.02, 0.06, 0.06) for x in (3.8, 0.0, -2.5, -5.2)], 'iron')
    for i, x in enumerate((0.85, -1.3, -3.05)):
        for side in (1, -1):
            K.rib('RB%d%s' % (i, 'p' if side > 0 else 's'), [(x, sy(x, side) + 0.06 * side, -1.0), (x, sy(x, side) + 0.06 * side, 0.4)], w=0.18, inv='flank_ribs')
    rp = random.Random(1718)
    tops = {t[0].split()[0]: t for t in TOP}
    for i, (blk, x, z, side) in enumerate([('U2', 1.55, 0.66, 1), ('U4', -1.05, 0.88, 1), ('U6', -3.62, 0.85, 1), ('U2', 1.4, 0.68, -1),
                                           ('U4', -0.8, 0.85, -1), ('U6', -3.5, 0.82, -1)]):
        t = tops[blk]; yf = t[7] + side * t[3]
        K.patch('PT%d' % i, (x, yf + 0.03 * side, z), (0, side, 0), rp.uniform(0.45, 0.6), rp.uniform(0.3, 0.42), ang=rp.uniform(-0.3, 0.3),
                lift=rp.uniform(0.05, 0.1), m=rp.choice(['iron', 'pale', 'rust']), inv='patches')
    for i, side in enumerate((1, -1)):
        t = tops['U5']; yf = t[7] + side * t[3]
        K.patch('PT%d' % (6 + i), (-2.5, yf + 0.03 * side, 0.9), (0, side, 0), 0.5, 0.36, ang=0.25 * side, lift=0.1, m='rust', inv='patches')
    for side in (1, -1):
        for j, (x, w) in enumerate(((1.9, 0.8), (1.25, 0.55))):
            K.patch('RS%d%s' % (j, 'p' if side > 0 else 's'), (x, 1.4 * side, 0.91), (0, 0.0, 1.0), w, 0.3, ang=0.04 * side, lift=0.02, t=0.04, m='blood', inv='rust_plates')
    K.mark('rust_plates', 'plate', ['slab', 'step', 'bevel', 'rivet'])

    # ---------------- head fittings: scoop drums, ears, grabber arms, hoses ----------------
    for side, fi, r in ((1, 'I1', 0.42), (-1, 'I2', 0.38)):
        y = 1.88 * side
        K.box('A17_%s_saddle' % fi, 4.35, 6.0, min(y * 0.78, y), max(y * 0.78, y), -0.78, -0.42, 'steel', ch=0.06)
        K.tube(fi, (6.35, y, -0.42), r, 2.1, grille=True, bands=4, inv='scoops', what='scoop drum with a grille',
               note='%s scoop drum on the head flank%s' % ('port' if side > 0 else 'starboard', ', the larger' if side > 0 else ''))
        # the ears (the beauty): big dishes, about the head's height across, standing out from brackets at the head's upper corners
        # Board on PR 611 (R207, R229): measured on the whole beauty (not the bow crop), each ear is about three quarters of
        # the head's flank height across (1.6), set low on the head's shoulders, turned forward and outward
        K.mass('Ear bracket %s' % ('port' if side > 0 else 'starboard'),
               K.box('A17_ear_bracket_%d' % (1 if side > 0 else 2), 4.35, 5.15, min(side * 1.5, side * 2.75), max(side * 1.5, side * 2.75), 0.06, 0.3, 'iron', ch=0.06),
               'iron', note='bracket out from the head\'s shoulder')
        K.dish('D%d' % (1 if side > 0 else 2), (4.75, 2.4 * side, 0.3), 0.8, yaw=40 * side, pitch=8, post=1.1, inv='ears',
               note='%s ear, a listening dish on the head\'s shoulder, turned forward and outward' % ('port' if side > 0 else 'starboard'))
    # R229 (Ryan, Nov 12: "the front claws or grabbers are coming out differently ... more like 4 independent prongs"; the
    # bow crop had cut them off): four articulated grabber arms, a pair a side as in the whole beauty and the sheet's side
    # view: an upper arm and a lower arm from under the jaw, each two segments with a knuckle and rams, running forward and
    # down; their forked pincers close toward each other (the upper hooks down, the lower up) to pin a hull for boarding
    for side, fi, fo in ((1, 'J1', 'J3'), (-1, 'J2', 'J4')):
        s_ = 'port' if side > 0 else 'starboard'
        K.claw_arm(fi, (4.35, 0.55 * side, -1.45), [(5.45, 0.6 * side, -1.88), (6.3, 0.74 * side, -1.74)], w=0.54, hook=-1.0, fork=0.3,
                   inv='jaws', housing=(3.95, 4.5, 0.55 * side - 0.36, 0.55 * side + 0.36, -1.68, -1.2),
                   note='%s lower grabber arm: shoulder under the jaw, knuckle low and forward, pincer hooking up' % s_)
        K.claw_arm(fo, (4.6, 1.52 * side, -1.3), [(5.6, 1.58 * side, -1.56), (6.4, 1.38 * side, -1.56)], w=0.48, hook=1.0, fork=0.3,
                   inv='jaws', housing=(4.15, 4.8, 1.52 * side - 0.32, 1.52 * side + 0.32, -1.5, -1.08),
                   note='%s upper grabber arm: over and outboard of the lower, pincer hooking down' % s_)
    # the hoses feed the arms' rams from the jaw machinery, over the arm shoulders into the body's front face (R229)
    for i, y in enumerate((0.15, 0.0, -0.15)):
        K.pipe('PH%d' % i, [(6.0, y, -0.6), (5.1, y, -0.72), (4.55, y, -0.92), (3.95, y, -0.98)], r=0.045, inv='jaw_pipes')

    # chains cut (R221: Ryan, "there's no purpose"; every part has a job, ships.md 2c)

    # ---------------- weapons, by data.js slot ----------------
    K.mass('Rack plinth', K.box('A17_plinth', 0.95, 2.1, -0.72, 0.72, 0.8, 1.7, 'iron', ch=0.12), 'iron', note='lifts the rocket pod clear over the neck turrets')
    K.launcher('R1', (1.95, 0.0, 1.7), 2, 3, cell=0.33, depth=1.0, pitch=10, slot='F', weapon='torp', inv='brow_rack',
               note='rattle-rocket pod on the fore block, firing over the head')
    K.gun('T1', (-4.6, 0.0, 1.52), 0, 8, barrels=2, cal=0.09, blen=1.25, size=0.85, slot='T', weapon='flak', inv='crest_gun', note='aft block twin, all round')
    K.gun('T2', (-1.0, 0.0, -1.64), 0, 8, barrels=2, cal=0.08, blen=1.1, size=0.75, normal=(0, 0, -1), slot='T', weapon='flak', inv='belly_turret',
          note='belly twin, covers below')
    for side, sl in ((1, 'P'), (-1, 'S')):
        K.box('A17_barbette_%s1' % sl, 2.9, 3.6, min(side * 0.95, side * 1.65), max(side * 0.95, side * 1.65), 0.7, 1.78, 'iron', ch=0.1)
        K.gun('%s1' % sl, (3.25, side * 1.3, 1.78), side * 40, 2, barrels=2, cal=0.08, blen=1.1, size=0.75, slot=sl, weapon='scatter', inv='deck_guns',
              note='neck block twin turret on a low barbette')
        K.gun('%s2' % sl, (-1.4, side * 1.8 + 0.1, 1.3), side * 35, 3, barrels=2, cal=0.08, blen=1.15, size=0.75, slot=sl, weapon='scatter', inv='deck_guns',
              variant=1, note='mid block twin turret, superfiring')
        K.gun('%s3' % sl, (-2.2, sy(-2.2, side) + 0.28 * side, -0.25), side * 35, 0, barrels=2, cal=0.08, blen=1.05, size=0.75, normal=(0, side, 0),
              slot=sl, weapon='scatter', inv='flank_casemates', note='flank casemate on the flank tier')

    # ---------------- engines: two columns a side, the inner a main over a lower, the outer between them; exits level ----------------
    for side, base in ((1, 1), (-1, 4)):
        k = 1.0 if side > 0 else 0.92
        for j, (y, z, r, nm) in enumerate(((0.72, 0.55, 0.5, 'inner main'), (1.9, 0.0, 0.44, 'outer'), (0.72, -0.62, 0.4, 'inner lower'))):
            K.engine('E%d' % (base + j), (-7.25, side * y, z), r * k, 0.95, bell=1.1, rings=3 if j == 0 else 2, body_r=r * k * 1.08, nose='flat',
                     src='picture' if side > 0 or j == 0 else 'designed', inv='engines', note='%s %s, a squat drum' % ('port' if side > 0 else 'starboard', nm))
    for i, (x, y, z, n) in enumerate([(3.75, sy(3.75, 1), -0.05, (0, 1, 0)), (3.75, sy(3.75, -1), -0.05, (0, -1, 0)),
                                      (-4.95, sy(-4.95, 1), -0.3, (0, 1, 0)), (-4.95, sy(-4.95, -1), -0.3, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, inv='bow_thrusters' if x > 0 else 'stern_thrusters', note='bow' if x > 0 else 'stern')
    K.antenna('AN1', (-2.65, 0.55, 1.4), 1.3, whips=3, inv='antennas', note='antenna array on the saddle block, port')
    K.antenna('AN2', (-2.8, -0.6, 1.4), 1.0, whips=2, inv='antennas', note='antenna array on the saddle block, starboard (shorter)')
    for side in (1, -1):
        K.vent('VS%s' % ('p' if side > 0 else 's'), (-5.0, 2.15 if side > 0 else -2.05, 0.92), (0, side, 0), 0.5, 0.45, inv='stern_vents')
        for i, x in enumerate((3.3, 1.85, 0.2, -1.6, -3.4)):
            K.lamp('L%d%s' % (i, 'p' if side > 0 else 's'), (x, max(sy(x - 0.1, side), sy(x + 0.1, side), key=abs) + 0.02 * side, -0.88), (0, side, 0), inv='lamps')
        K.lamp('LH%s' % ('p' if side > 0 else 's'), (-3.4, 2.15 if side > 0 else -2.05, 1.18), (0, side, 0), inv='lamps')
    K.hatchbox('HB1', (4.95, 0.0, 1.98), 0.35, 0.3, 0.12, inv='head_hatchboxes', note='framed box on the crown')
    K.hatchbox('HB2', (5.55, 0.85, 1.76), 0.25, 0.25, 0.1, inv='head_hatchboxes', note='framed box on the brow, port')
    K.hatchbox('HB3', (5.55, -0.85, 1.76), 0.22, 0.22, 0.1, inv='head_hatchboxes', note='framed box on the brow, starboard')
    K.hatchbox('HB4', (0.35, 0.0, 1.2), 0.6, 0.55, 0.18, inv='hump_hatchboxes', note='framed box on the ramp block')
    K.hatchbox('HB5', (-1.6, 0.35, 1.3), 0.4, 0.45, 0.15, inv='hump_hatchboxes', note='framed box on the mid block')
    K.hatchbox('HB6', (-5.3, 1.1, 1.52), 0.35, 0.4, 0.14, inv='hump_hatchboxes', note='framed box on the aft block')

    # ---- colour zones ----
    K.colour('weathered grey and soot plate', 7.25, -7.25, 'whole hull')
    K.colour('pale grey trophy plate (brow)', 6.05, 4.45, 'head roof')
    K.colour('rust patch', 5.3, 4.95, 'brow, port')
    K.colour('dried-blood red plates', 2.3, 0.95, 'fore block roof')
    K.colour('dried-blood red patch', -3.6, -4.9, 'aft block roof')

    # ---------- INSIDE (round 3b: follows the low hull and the top blocks) ----------
    K.deck('lower', -0.82, -5.4, 4.0)
    K.deck_box('top', 0.3, -5.3, 2.3, 1.3)
    K.deck_box('head', 0.0, 4.4, 5.9, 0.75)
    for i, x in enumerate((5.4, 4.0, 2.05, 0.8, -1.9, -4.7)):  # F2 off the B-1 seam station (a bulkhead face on the tear)
        K.bulkhead('F%d' % i, x)
    K.room('jaw_machinery', 'machinery', 4.45, 5.6, -0.75, 0.75, -0.6, -0.1, note='grabber arm rams and winches over the mouth')
    K.room('listening_bridge', 'bridge', 4.5, 5.7, -0.7, 0.7, 0.05, 0.55, note='listening room and bridge in the head')
    K.room('boarding_kennels', 'crew', 2.5, 3.9, -1.6, 1.6, -1.45, -0.88, note='boarding gangs behind the grabbers')
    K.room('loot_hold', 'hold', 0.85, 2.4, -1.7, 1.7, -1.45, -0.88, note='neck hold')
    K.room('rocket_magazine', 'magazine', 1.05, 2.0, -0.6, 0.6, 0.34, 0.7, note='under the rocket pod, in the fore block')
    K.room('crew_decks', 'crew', -1.65, -0.55, -1.3, 1.5, 0.34, 1.05, note='in the mid block')
    K.room('shell_magazine', 'magazine', -1.9, 0.8, -1.7, 1.7, -1.45, -0.88, note='battery magazines')
    K.room('flak_magazine', 'magazine', -5.2, -3.6, -0.8, 0.8, 0.34, 1.25, note='under the aft block twin')
    K.room('core', 'core', -4.5, -2.6, -1.1, 1.1, -1.45, 0.3, note='reactor core (hp_core)')
    K.room('engine_room', 'engroom', -5.4, -4.75, -1.6, 1.6, -1.2, 0.35, note='engine room and feeds')
    K.armour('head (forward of 4.4)', 0.4, 'ram plate and face panels over the mouth')
    K.armour('flank blocks', 0.3, 'armour blocks over the flank tier')
    K.armour('top blocks', 0.2, '')
    K.armour('belly', 0.25, 'flat armoured belly, the band stepping in')
    K.armour('engine end', 0.15, 'thinnest')
    K.break_line('B-1', 2.45, 'the neck seam behind the neck turrets: the head and grabbers tear off, opening the kennels and the hold',
                 path=[(2.6, 0.78), (2.2, 0.2), (2.7, -0.4), (2.25, -1.0), (2.65, -1.6)])
    # R226 (RULEBOOK 5.17): the seam runs along the weld between the saddle and aft blocks, kinked round the antennas AN1 and
    # AN2 ahead of it and the aft twin T1 and the stern thrusters Q3 and Q4 behind it, so every machine rides whole
    K.break_line('B-2', -3.35, 'the weld between the saddle and aft blocks: the aft block, its flak twin and the engine cluster tear away, '
                 'biting through the core and opening the engine room',
                 path=[(-3.7, 2.7), (-3.3, 1.9), (-3.15, 1.0), (-3.45, 0.25), (-3.2, -0.5), (-3.55, -1.3), (-3.25, -2.0), (-3.6, -2.7)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).'))
    K.point('core', 'hp_core', (-3.6, 0, -0.6))
    for i, (x, y, z, sec, side) in enumerate([(3.6, 1.95, -0.2, 'prow', 'port'), (3.0, -1.95, -0.4, 'prow', 'stbd'),
                                              (0.8, 2.0, 0.1, 'mid', 'port'), (-1.9, -2.05, -0.3, 'mid', 'stbd'),
                                              (-4.9, 1.85, 0.2, 'eng', 'port')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (3.75, sy(3.75, 1), -0.05), side='port')
    K.point('rcs', 'hp_rcs_1', (3.75, sy(3.75, -1), -0.05), side='stbd')
    K.point('board', 'hp_board_0', (-0.5, 2.05, -0.3), side='port')
    K.point('board', 'hp_board_1', (-0.5, -2.1, -0.3), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Long and low, to the concept\'s measured proportions', 'the Board on round 3: the build was short, tall and round; the hull is now length to beam 2.75 and length to height about 4 like the round 8 sheet, at the data.js length')
    K.change('The body is stacked angular blocks: a base hull, flank blocks, six top blocks stepping up toward the stern with gaps and undercuts', 'the concept\'s dense stack of armoured blocks; round 3 was one smooth body with plates stuck on')
    K.change('The head is narrow, chamfered and stepped, a face overhanging a cut-in jaw mouth, the scoop drums on its flanks', 'Ryan R217: "the front is also just a flat block"')
    K.change('The jaws are four articulated grabber arms (two segments, knuckles, rams, forked pincers), a pair a side closing toward each other', 'Ryan, R229: the round 3b flat prongs came from a bow crop that cut the grabbers off; the whole beauty and the sheet\'s side view show jointed arms (new kit part claw_arm)')
    K.change('Guns laid out as matched batteries by game slot', 'the picture scatters guns; scatter P and S are mirrored (a neck block turret, a mid block turret superfiring, a flank casemate per side), flak on the aft block and the belly, the rocket pod on the fore block')
    K.change('Engines are squat drums in two columns a side, exits level, no bell touching another', 'the concept\'s stacked cluster; the fit check found round 2\'s bells inside each other')
    K.change('The head follows the beauty: a big, tall, boxy front block over the neck, ear dishes on its shoulders (R229 sizes them)', 'the Board on round 3b: Ryan judges against the accepted picture, which draws the head larger than the round 8 sheet')
    K.change('Forward rocket pod, belly flak turret and four attitude thrusters added', 'data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters')
    K.change('Chains cut', 'Ryan, R221: "let\'s get rid of the chains randomly around the ship. There\'s no purpose"; every part has a job (ships.md 2c)')
    K.change('Neck and mid turrets moved outboard', 'R221: no gun in the rocket pod\'s firing lane or backblast (the fit check tests both)')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.change('The face is a narrower panel inside a deep bevel frame (corner and brow planes plated), with a lower lip over the mouth',
             'Ryan R217 on A17: "the front is also just a flat block which does not match the concept"; the beauty\'s head is chamfered all round, not a flat end (A17 build, issue 532)')
    K.change('Ear dishes 1.6 across (were 1.9), lower on the head\'s shoulders, turned forward and outward, rusted grey', 'the Board on PR 611 (R207, R229): measured on the whole beauty, each ear is about three quarters of the head\'s flank height across and sits at the rear of the head\'s shoulder; not a white disc high on the top corner (A17 build, issue 532)')
    K.change('Neck block raised from 0.78 to 1.12', 'in the beauty the deck behind the head steps down only a little; at 0.78 the head stood on the neck like a separate box (A17 build, issue 532)')
    K.change('Aft seam B-2 moved forward to the weld between the saddle and aft blocks, kinked round the antennas, T1 and the stern thrusters',
             'R226 (RULEBOOK 5.17): a machine never crosses a seam; at -4.75 the seam cut T1, Q3 and Q4 (A17 build, issue 532)')
    K.change('Mid turrets P2 and S2 rest at 35 degrees (were 25)', 'their data.js arc is 30 to 150; a rest outside it failed the export check (A17 build, issue 532)')
    K.change('Rooms in the top blocks kept under their roofs; the top deck lowered to 0.3', 'about 70 inside triangles sat outside the intact plating, above the low top blocks and in the gaps between them (issue 532 note from PR 608)')
    K.open_item('Belly detail between the grabber arm housings and the engines is designed here; the picture does not show the underside')

    # ---------- the fit report's fix column (round 2 clashes) ----------
    K.fix('Engine bells E1 to E6 inside each other; E2 and E5 exhausts on their neighbours', 'two columns a side, exits level at -7.25, centres spaced by the sum of the bell radii plus the lip')
    K.fix('P2 and S2 barrels striking the hump at every aft bearing', 'the mid block turrets now stand on the block top and superfire; the blocks behind them are no taller than their barrels')
    K.fix('P1 and S1 barrels through the ear dishes D1 and D2', 'the neck turrets stand inboard on barbettes high enough to fire over the head and the ears')
    K.fix('Ear dishes D1 and D2 had no mount on the hull', 'each dish stands on an armoured bracket out from the head\'s upper corner')
    K.fix('Q1 and Q2 bow thrusters inside the scoop drums, their exhaust on the drum ribs', 'bow thrusters on the body flank behind the drums, firing clear outboard')
    K.fix('Jaw blades inside the hull and the jaw housing', 'four grabber arms (R229), each shoulder in its own housing under the jaw, clear of the hull')
    K.fix('C2 girdle through the P2 and S2 turret rings', 'C2 runs in the gap between the mid and saddle blocks, clear of every ring')
    K.fix('Crest and belly turret housings sunk in the crest and the belly', 'turrets sit on their rings on block tops and the belly band, plates cleared under each mount')
