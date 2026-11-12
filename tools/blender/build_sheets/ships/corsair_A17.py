# corsair_A17 round 3: Hullbreaker wrecker, the Pack Hunter (Ashfall Hullbreakers cruiser, class Cruiser, 14.5 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg (R201), from round 1 Pack Hunter
# (concept_directions_2026_11/corsair_B.jpg, R197). data.js c_marauder: scatter P, scatter S, torp F, flak T (no hangar).
# Round 3 (Ryan, Nov 11 21:24 and 21:34 CST, R217 and R218): "the front is also just a flat block which does not match the
# concept". The head is now an octagonal block with heavy chamfers, two roof steps, a face that overhangs a cut-in jaw mouth,
# framed face panels with straps, scoop drums with grilles at its lower corners and ear dishes at its upper corners. Lean as
# Ryan kept it (R213). The parts inventory (corsair_A17_inv.py) came first; every part is a kit shape; the fit check passes.
# +X bow, +Y port, +Z up. Jaw finger tips about x = +7.2, engine exits x = -7.25. Flat belly z = -1.75.
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
HULL = [
    (5.15, 1.95, 1.95, -0.7, 1.0, 0.5, 0.35),
    (4.95, 2.3, 2.3, -0.95, 1.32, 0.6, 0.45),
    (4.4, 2.45, 2.45, -1.15, 1.45, 0.62, 0.5),
    (3.6, 2.45, 2.45, -1.65, 1.45, 0.62, 0.55),
    (2.75, 2.45, 2.45, -1.65, 1.45, 0.62, 0.55),
    (2.3, 2.15, 2.15, -1.6, 1.28, 0.55, 0.5),
    (1.2, 2.45, 2.5, -1.7, 1.5, 0.7, 0.6),
    (-1.0, 2.55, 2.6, -1.75, 1.6, 0.75, 0.6),
    (-4.0, 2.45, 2.5, -1.7, 1.6, 0.75, 0.6),
    (-5.2, 2.1, 2.15, -1.5, 1.45, 0.6, 0.5),
    (-5.8, 1.8, 1.85, -1.2, 1.2, 0.5, 0.4),
]
PL = dict(size=(0.35, 0.9), thick=(0.04, 0.13), skip=0.1, stack=0.45, mats={'soot': 5, 'iron': 5, 'pale': 2, 'rust': 2, 'soot2': 2})


def build(K):
    import kit as _k
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Hull (head, neck, body)', K.hull(HULL, 'soot', shell=0.22, plates=dict(PL, seed=17, inv=['head_plates', 'belly_plates'])),
           'weathered grey and soot plate', note='chamfered head over a cut-in jaw mouth, pinched neck, lean body')
    # ---------------- the head (R217: never a flat block) ----------------
    K.mass('Head roof, step 1 (brow)', K.loft('A17_brow', [(4.85, 1.6, 1.6, 1.3, 1.62, 0.25, 0), (4.6, 1.8, 1.8, 1.3, 1.8, 0.3, 0),
                                                         (2.85, 1.85, 1.85, 1.3, 1.85, 0.3, 0)], 'pale',
                                     plates=dict(PL, seed=27, faces=[0, 1, 2, 3], inv='head_plates')), 'pale grey trophy plate, rust patch',
           note='the first roof step, sloped at its front')
    K.mass('Head roof, step 2 (crown)', K.loft('A17_crown', [(4.0, 0.85, 0.85, 1.75, 1.95, 0.15, 0), (3.75, 0.98, 0.98, 1.75, 2.1, 0.2, 0),
                                                           (2.95, 1.0, 1.0, 1.75, 2.1, 0.2, 0)], 'soot'), 'soot', note='the second step, carries the rocket pod')
    K.loft('A17_mouth_roof', [(5.0, 1.7, 1.7, -0.98, -0.72, 0.05, 0.05), (3.6, 1.95, 1.95, -1.62, -0.75, 0.05, 0.1)], 'dark')
    K.mark('head', 'hull', ['bevel', 'step', 'overhang'])
    # face panels with vertical straps (the concept's framed front)
    for i, (y, w) in enumerate(((0.75, 1.05), (-0.75, 1.05))):
        K.patch('FP%d' % i, (5.16, y, 0.2), (1, 0, 0), w, 1.0, ang=0.03 * (1 if i else -1), lift=0.02, t=0.07, m='iron', inv='head_face')
    for i, y in enumerate((1.45, 0.0, -1.45)):
        K.box('A17_strap%d' % i, 5.12, 5.3, y - 0.07, y + 0.07, -0.55, 0.95, 'steel')
    K.mark('head_face', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    K.box('A17_rust_brow', 4.05, 4.55, -0.65, 0.35, 1.8, 1.86, 'rust')
    K.box('A17_red_crest', -2.8, -1.6, -1.15, 1.15, 3.2, 3.25, 'blood')
    for side in (1, -1):
        K.loft('A17_redstripe_%d' % side, [(2.0, side * 2.47 if side > 0 else 2.0, -2.0 if side > 0 else 2.52, 1.0, 1.35, 0, 0),
                                            (-0.5, side * 2.62 if side > 0 else 2.0, -2.0 if side > 0 else 2.67, 1.0, 1.4, 0, 0)], 'blood')
    K.mark('rust_plates', 'plate', ['slab', 'step', 'bevel', 'rivet'])

    # ---------------- the hump: stepped tiers with sloped faces, a crest ----------------
    HU = [(0.4, 1.8, 1.85, 1.3, 1.9, 0.4, 0), (-0.6, 2.2, 2.25, 1.3, 2.75, 0.5, 0), (-4.2, 2.2, 2.25, 1.3, 2.85, 0.5, 0), (-5.0, 1.8, 1.85, 1.3, 2.2, 0.4, 0)]
    K.mass('Shoulder hump', K.loft('A17_hump', HU, 'soot', plates=dict(PL, seed=37, faces=[0, 1, 2, 3])), 'soot with dried-blood patches', note='the shoulder hump')
    K.mass('Hump crest', K.loft('A17_crest', [(-1.2, 1.0, 1.0, 2.7, 3.0, 0.2, 0), (-1.55, 1.2, 1.2, 2.7, 3.2, 0.25, 0), (-3.8, 1.2, 1.2, 2.7, 3.2, 0.25, 0),
                                              (-4.05, 1.0, 1.0, 2.7, 2.95, 0.2, 0)], 'soot', plates=dict(PL, seed=47, faces=[0, 1, 2, 3])),
           'soot', note='stepped crest on the hump')
    hy = lambda x, side: _k.sec_at(HU, x)[1 if side > 0 else 2] * side  # noqa: E731
    for side in (1, -1):
        K.slit('SL%d' % (1 if side > 0 else 2), (0.05, 0.85 * side, 2.2), (0.65, 0, 0.76), 0.7, 0.14, inv='hump', note='slit in the hump front')
        K.hatch('HS%d' % (1 if side > 0 else 2), (-3.95, hy(-3.95, side), 1.95), (0, side, 0), 0.45, 0.6, inv='stern_hatch', note='hatch on the aft hump flank')
    K.slit('SL3', (-1.2, 0.0, 2.84), (1, 0, 0), 1.2, 0.12, inv='hump', note='slit in the crest front')
    K.mark('hump', 'tier', ['face', 'roof', 'opening'])
    K.mass('Engine block', K.box('A17_engblock', -6.0, -5.4, -1.9, 1.9, -1.45, 1.6, 'soot', ch=0.25, plates=dict(PL, seed=57, faces=[0, 1, 2, 3, 4, 5, 6, 7])), 'soot, steel')
    K.mark('engine_block', 'pylon', ['web', 'plate'])
    K.loft('A17_belt', [(x, _k.sec_at(HULL, x)[1] + 0.2, _k.sec_at(HULL, x)[2] + 0.2, -0.75, -0.3, 0.08, 0.08) for x in (2.2, 0.0, -2.5, -5.0)], 'iron')
    for i, x in enumerate((0.3, -1.8, -3.25)):
        for side in (1, -1):
            K.rib('RB%d%s' % (i, 'p' if side > 0 else 's'), [(x, sy(x, side) + 0.1 * side, -0.25), (x, sy(x, side) + 0.1 * side, 0.8)], w=0.22, inv='flank_ribs')
    import random
    rp = random.Random(1717)
    for i, (x, z, side) in enumerate([(1.0, 0.3, 1), (-1.0, 0.45, 1), (-2.7, 0.3, 1), (0.9, 0.4, -1), (-1.1, 0.25, -1), (-2.75, 0.5, -1)]):
        K.patch('PT%d' % i, (x, sy(x, side) + 0.18 * side, z), (0, side, 0), rp.uniform(0.55, 0.8), rp.uniform(0.45, 0.65), ang=rp.uniform(-0.3, 0.3),
                lift=rp.uniform(0.06, 0.14), m=rp.choice(['iron', 'pale', 'rust']), inv='patches')
    for i, side in enumerate((1, -1)):
        K.patch('PT%d' % (6 + i), (-2.2, (2.0 + 0.05) * side, 2.42), (0, 0.75 * side, 0.66), 0.8, 0.5, ang=0.25 * side, lift=0.12, m='rust', inv='patches')

    # ---------------- head fittings: scoop drums, ears, jaws, hoses ----------------
    for side, fi, r in ((1, 'I1', 0.62), (-1, 'I2', 0.55)):
        y = 2.42 * side
        K.box('A17_%s_saddle' % fi, 3.1, 5.0, min(y * 0.86, y), max(y * 0.86, y), -1.05, -0.25, 'steel', ch=0.08)
        K.tube(fi, (5.75, y, -0.32), r, 2.7, grille=True, bands=4, inv='scoops', what='scoop drum with a grille',
               note='%s scoop drum at the head\'s lower corner%s' % ('port' if side > 0 else 'starboard', ', the larger' if side > 0 else ''))
        K.dish('D%d' % (1 if side > 0 else 2), (4.3, 1.95 * side, 1.4), 0.82, yaw=30 * side, pitch=8, post=1.15, inv='ears',
               note='%s ear, listening dish' % ('port' if side > 0 else 'starboard'))
    for side, fi, fo in ((1, 'J1', 'J3'), (-1, 'J2', 'J4')):
        s_ = 'port' if side > 0 else 'starboard'
        yi, yo = 0.85 * side, 1.95 * side
        K.claw(fi, (4.0, yi, -1.88), [(5.0, yi * 1.05, -2.02), (5.85, yi * 1.08, -2.12), (6.45, yi * 0.95, -2.08)], w=0.62, fingers=3,
               housing=(3.2, 4.6, yi - 0.42, yi + 0.42, -2.05, -1.25), name='boarding jaw', inv='jaws', note='%s inner jaw, hinged in the mouth' % s_)
        K.claw(fo, (4.25, yo, -1.75), [(5.05, yo * 1.04, -1.93), (5.85, yo * 1.05, -2.0), (6.5, yo * 0.98, -1.98)], w=0.5, fingers=2,
               housing=(3.6, 4.75, yo - 0.33, yo + 0.33, -1.92, -1.12), name='boarding jaw', src='picture' if side < 0 else 'designed',
               inv='jaws', note='%s outer jaw under the scoop drum' % s_)
    for i, y in enumerate((0.24, 0.0, -0.24)):
        K.pipe('PH%d' % i, [(4.85, y, -1.0), (4.1, y, -1.15 - 0.05 * i), (3.35, y, -1.7), (2.4, y, -1.82)], r=0.07, inv='jaw_pipes')

    # ---------------- chains ----------------
    K.chain('C1', [(2.8, 2.6, -0.5), (2.8, 2.35, 1.0), (2.8, 1.83, 1.5), (2.8, -1.83, 1.5), (2.8, -2.35, 1.0), (2.8, -2.6, -0.5)],
            link=0.2, r=0.03, inv='neck_chain', note='girdle over the neck seam, at the back of the head')
    K.chain('C2', [(-1.62, 2.72, 0.3), (-1.62, 2.28, 2.1), (-1.62, 1.75, 2.8), (-1.62, 1.25, 2.8), (-1.62, 1.22, 3.22), (-1.62, -1.22, 3.22),
                   (-1.62, -1.25, 2.8), (-1.62, -1.75, 2.8), (-1.62, -2.33, 2.1), (-1.62, -2.77, 0.3)], link=0.2, r=0.03, inv='hump_chain', note='girdle over the hump and crest')

    # ---------------- weapons, by data.js slot ----------------
    K.launcher('R1', (3.95, 0.0, 2.1), 2, 3, cell=0.36, depth=1.15, pitch=8, slot='F', weapon='torp', inv='brow_rack',
               note='rattle-rocket pod on the crown, firing over the jaws')
    K.gun('T1', (-2.5, 0.0, 3.2), 0, 8, barrels=2, cal=0.1, blen=1.4, size=0.9, slot='T', weapon='flak', inv='crest_gun', note='crest twin, all round')
    K.gun('T2', (-1.6, 0.0, -1.75), 0, 8, barrels=2, cal=0.09, blen=1.2, size=0.8, normal=(0, 0, -1), slot='T', weapon='flak', inv='belly_turret',
          note='belly twin, covers below')
    for side, sl in ((1, 'P'), (-1, 'S')):
        K.box('A17_barbette_%s1' % sl, 1.35, 2.15, min(side * 1.2, side * 2.0), max(side * 1.2, side * 2.0), 1.3, 1.72, 'iron', ch=0.12)
        K.gun('%s1' % sl, (1.75, side * 1.6, 1.72), side * 35, 2, barrels=2, cal=0.09, blen=1.25, size=0.85, slot=sl, weapon='scatter', inv='deck_guns',
              note='neck deck twin turret on a low barbette')
        K.gun('%s2' % sl, (-0.75, side * 1.5, 2.75), side * 22, 3, barrels=2, cal=0.09, blen=1.3, size=0.85, slot=sl, weapon='scatter', inv='deck_guns',
              variant=1, note='hump-front twin turret, superfiring over the neck')
        K.gun('%s3' % sl, (-2.95, hy(-2.95, side) + 0.01 * side, 2.05), side * 35, 0, barrels=2, cal=0.09, blen=1.2, size=0.8, normal=(0, side, 0),
              slot=sl, weapon='scatter', inv='flank_casemates', note='hump flank casemate')

    # ---------------- engines: a stacked cluster, three per side, exits level, port bells larger ----------------
    for side, base in ((1, 1), (-1, 4)):
        k = 1.0 if side > 0 else 0.9
        for j, (y, z, r, nm) in enumerate(((1.15, 0.0, 0.6, 'main'), (1.36, 1.38, 0.46, 'upper'), (1.02, -1.32, 0.4, 'lower'))):
            K.engine('E%d' % (base + j), (-7.25, side * y, z), r * k, 1.0, bell=1.2, rings=3 if j == 0 else 2,
                     src='picture' if side > 0 or j == 0 else 'designed', inv='engines', note='%s %s' % ('port' if side > 0 else 'starboard', nm))
    # attitude thrusters: bow quads on the head flanks between the ears and the drums, stern quads on the engine block
    for i, (x, y, z, n) in enumerate([(3.35, 2.45, 0.95, (0, 1, 0)), (3.35, -2.45, 0.95, (0, -1, 0)),
                                      (-5.0, 2.22, 0.75, (0, 1, 0)), (-5.0, -2.27, 0.75, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, inv='bow_thrusters' if x > 0 else 'stern_thrusters', note='bow' if x > 0 else 'stern')
    K.antenna('AN1', (-4.6, 0.7, 2.53), 1.5, whips=3, inv='antennas', note='aft hump antenna array, port')
    K.antenna('AN2', (-4.55, -0.75, 2.57), 1.2, whips=2, inv='antennas', note='aft hump antenna array, starboard (shorter)')
    for side in (1, -1):
        K.vent('VS%s' % ('p' if side > 0 else 's'), (-4.05, max(sy(-3.7, side), sy(-4.4, side), key=abs) + 0.01 * side, 0.3), (0, side, 0), 0.7, 0.5,
               inv='stern_vents')
        for i, x in enumerate((2.65, 1.2, -0.6, -2.8, -4.4)):
            K.lamp('L%d%s' % (i, 'p' if side > 0 else 's'), (x, max(sy(x - 0.1, side), sy(x + 0.1, side), key=abs) + 0.02 * side, -0.98), (0, side, 0), inv='lamps')
        K.lamp('LH%s' % ('p' if side > 0 else 's'), (-2.2, hy(-2.2, side) + 0.01 * side, 1.65), (0, side, 0), inv='lamps')
    K.hatchbox('HB1', (4.35, 1.1, 1.83), 0.5, 0.55, 0.22, inv='head_hatchboxes', note='framed box on the brow, port')
    K.hatchbox('HB2', (4.4, -1.15, 1.83), 0.45, 0.5, 0.2, inv='head_hatchboxes', note='framed box on the brow, starboard')
    K.hatchbox('HB3', (3.3, -1.3, 1.86), 0.4, 0.55, 0.2, inv='head_hatchboxes', note='framed box on the brow, aft')
    K.hatchbox('HB4', (0.85, 0.0, 1.54), 0.8, 0.8, 0.25, inv='hump_hatchboxes', note='framed box on the neck deck')
    K.hatchbox('HB5', (-3.95, 1.45, 2.85), 0.4, 0.5, 0.18, inv='hump_hatchboxes', note='framed box on the hump top, port')
    K.hatchbox('HB6', (-3.95, -1.45, 2.85), 0.4, 0.6, 0.2, inv='hump_hatchboxes', note='framed box on the hump top')

    # ---- colour zones ----
    K.colour('weathered grey and soot plate', 7.25, -7.25, 'whole hull')
    K.colour('pale grey trophy plate (brow)', 4.85, 2.85, 'head roof')
    K.colour('rust patch', 4.55, 4.0, 'brow, forward')
    K.colour('dried-blood red stripes', 2.0, -0.5, 'both deck edges')
    K.colour('dried-blood red patch', -1.6, -2.8, 'hump crest')

    # ---------- INSIDE ----------
    K.deck('lower', -0.75, -5.4, 4.3)
    K.deck('main', 0.55, -5.4, 4.5)
    K.deck_box('hump', 1.9, -4.3, 0.2, 1.8)
    for i, x in enumerate((4.4, 2.5, 0.2, -2.6, -4.7)):
        K.bulkhead('F%d' % i, x)
    K.room('jaw_machinery', 'machinery', 3.0, 4.4, -1.8, 1.8, -1.45, -0.85, note='jaw rams and winches over the mouth')
    K.room('boarding_kennels', 'crew', 2.9, 4.6, -1.9, 1.9, -0.65, 0.45, note='boarding gangs behind the jaws')
    K.room('ears_and_bridge', 'bridge', 2.9, 4.5, -1.4, 1.4, 0.65, 1.25, note='listening room and bridge under the brow')
    K.room('rocket_magazine', 'magazine', 3.0, 3.9, -0.6, 0.6, 1.35, 1.95, note='under the rocket pod')
    K.room('loot_hold', 'hold', 0.3, 2.3, -2.0, 2.0, -1.45, 0.45, note='neck hold')
    K.room('crew_decks', 'crew', -2.5, 0.1, -2.1, 2.1, 0.65, 1.8, note='')
    K.room('shell_magazine', 'magazine', -2.5, 0.1, -2.1, 2.1, -1.45, 0.45, note='battery magazines')
    K.room('flak_magazine', 'magazine', -3.4, -1.7, -0.8, 0.8, 2.0, 2.65, note='under the crest twin')
    K.room('core', 'core', -4.5, -2.8, -1.2, 1.2, -1.45, 0.45, note='reactor core (hp_core)')
    K.room('engine_room', 'engroom', -5.4, -4.8, -1.8, 1.8, -1.2, 1.4, note='engine room and feeds')
    K.armour('head (forward of 4.4)', 0.45, 'ram plate and face panels over the mouth')
    K.armour('flanks', 0.25, 'patch plates and the belt strake')
    K.armour('hump roof and deck', 0.2, '')
    K.armour('belly', 0.25, 'flat armoured belly with chines')
    K.armour('engine end', 0.15, 'thinnest')
    K.break_line('B-1', 2.45, 'the neck seam under the C1 girdle: the head and jaws tear off, opening the kennels and the hold',
                 path=[(2.6, 1.85), (2.2, 1.0), (2.75, 0.2), (2.25, -0.6), (2.7, -1.75)])
    K.break_line('B-2', -4.75, 'hump and engine seam: the engine cluster tears away, opening the engine room',
                 path=[(-4.9, 2.2), (-4.5, 1.2), (-5.0, 0.3), (-4.55, -0.7), (-4.95, -1.7)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).'))
    K.point('core', 'hp_core', (-3.6, 0, -0.5))
    for i, (x, y, z, sec, side) in enumerate([(3.9, 2.45, 0.9, 'prow', 'port'), (2.9, -2.45, -0.6, 'prow', 'stbd'),
                                              (0.8, 2.5, 1.1, 'mid', 'port'), (-1.9, -2.6, 0.1, 'mid', 'stbd'),
                                              (-4.9, 2.2, 1.4, 'eng', 'port')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (3.35, 2.45, 0.95), side='port')
    K.point('rcs', 'hp_rcs_1', (3.35, -2.45, 0.95), side='stbd')
    K.point('board', 'hp_board_0', (-0.5, 2.6, 0.2), side='port')
    K.point('board', 'hp_board_1', (-0.5, -2.65, 0.2), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('The head is a chamfered block with two roof steps, a face overhanging a cut-in jaw mouth, framed face panels and straps', 'Ryan R217: "the front is also just a flat block which does not match the concept"')
    K.change('Guns laid out as matched batteries by game slot', 'the picture scatters guns on one edge and the far flank; scatter P and S are mirrored (a neck deck turret, a hump-front turret superfiring over it and a hump casemate per side), flak on the crest and the belly, the rocket pod on the crown')
    K.change('Engine bells set level at the stern and spaced so no bell touches another', 'the fit check found the round 2 cluster\'s bells inside each other and its exhausts washing the neighbours')
    K.change('Lean hull, profile from the round 8 side view', 'Ryan kept A17 lean (R213); the head sits low and heavy, the hump rises behind the neck')
    K.change('Jaws are two matched pairs hinged in their own housings, hooks turned inboard', 'the picture shows three loose arms; jaws that open sideways must close on something')
    K.change('Scoops and ears made a matched pair (port scoop larger)', 'the picture shows a large port scoop and a small starboard one; kept mismatched in size, matched in place')
    K.change('Forward rocket pod, belly flak turret and four attitude thrusters added', 'data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters')
    K.change('Chains are taut girdles of real links over the neck and the hump', 'a slack chain cannot drape in space (R185); the girdles sit on the break lines')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.open_item('Belly detail between the jaw housings and the engines is designed here; the picture does not show it')

    # ---------- the fit report's fix column ----------
    K.fix('Engine bells E1 to E6 inside each other; E2 and E5 exhausts on their neighbours', 'exits set level at -7.25; centres spaced by the sum of the bell radii plus the lip')
    K.fix('P2 and S2 barrels striking the hump at every aft bearing', 'moved up onto the hump\'s front corners, superfiring over the neck deck')
    K.fix('P1 and S1 barrels through the ear dishes D1 and D2', 'ears moved to the head\'s front corners; P1 and S1 back to the neck deck, resting 30 degrees out')
    K.fix('Ear dishes D1 and D2 had no mount on the hull', 'each dish stands on its own base plate on the head roof')
    K.fix('Q1 and Q2 bow thrusters inside the scoop drums, their exhaust on the drum ribs', 'thrusters moved up the head flanks between the ears and the drums')
    K.fix('Jaw blades inside the hull and the jaw housing', 'each jaw has its own housing (its mount) in the cut-in mouth; the blades clear the hull')
    K.fix('C2 girdle through the P2 and S2 turret rings', 'C2 moved aft to -1.62, over the hump and crest, clear of every ring')
    K.fix('Crest and belly turret housings sunk in the crest and the belly', 'turrets now sit on their rings on the surface, plates cleared under each mount')
