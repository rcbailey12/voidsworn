# ROUND 2 LAYOUT, kept only to run the round 3 fit check on it (the "before" column of the fit report).
# Adapted to the round 3 kit API: intake() -> tube(), launcher(tube_r=r) -> launcher(cell=2.3 r). Not a live design.
# corsair_A17 round 2: Hullbreaker wrecker, the Pack Hunter (Ashfall Hullbreakers cruiser, class Cruiser, 14.5 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg (R201), from round 1 Pack Hunter
# (concept_directions_2026_11/corsair_B.jpg, R197). data.js c_marauder: scatter P, scatter S, torp F, flak T (no hangar).
# Round 2 (R213, Ryan 19:40 CST): designed from the picture's identity, lean (his pick): a heavy head with jaws, scoops and
# listening dishes as ears, a narrow neck, a shoulder hump, a stacked engine cluster. Profile from the round 8 side view.
# +X bow, +Y port, +Z up. Jaw tips x = +7.25, engine exits x = -7.25. Flat belly z = -1.75.
CODE = 'corsair_A17'
NAME = 'Hullbreaker wrecker (the Pack Hunter)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg'

HULL = [
    (4.9, 2.2, 2.2, -1.35, 1.15, 0.45, 0.45),
    (4.4, 2.45, 2.45, -1.6, 1.4, 0.55, 0.5),
    (2.75, 2.45, 2.45, -1.65, 1.45, 0.6, 0.55),
    (2.3, 2.15, 2.15, -1.6, 1.3, 0.55, 0.5),
    (1.2, 2.45, 2.5, -1.7, 1.5, 0.7, 0.6),
    (-1.0, 2.55, 2.6, -1.75, 1.6, 0.75, 0.6),
    (-4.0, 2.45, 2.5, -1.7, 1.6, 0.75, 0.6),
    (-5.2, 2.1, 2.15, -1.5, 1.45, 0.6, 0.5),
    (-5.8, 1.8, 1.85, -1.2, 1.2, 0.5, 0.4),
]
PL = dict(size=(0.5, 1.4), thick=(0.04, 0.15), skip=0.15, stack=0.35, mats={'soot': 5, 'iron': 5, 'pale': 2, 'rust': 2, 'soot2': 2})


def build(K):
    K.mass('Hull (head, neck, body)', K.hull(HULL, 'soot', shell=0.22, plates=dict(PL, seed=17)), 'weathered grey and soot plate',
           note='heavy head, pinched neck, lean body')
    K.mass('Head brow', K.loft('A17_brow', [(4.75, 1.75, 1.75, 1.05, 1.75, 0.3, 0), (2.8, 1.85, 1.85, 1.2, 1.85, 0.3, 0)], 'pale',
           plates=dict(PL, seed=27, faces=[0, 1, 2, 3])), 'pale grey trophy plate, rust patch', note='the raised brow of the head')
    K.mass('Shoulder hump', K.loft('A17_hump', [(0.4, 1.8, 1.85, 1.3, 1.9, 0.4, 0), (-0.6, 2.2, 2.25, 1.3, 2.75, 0.5, 0),
                                                (-4.2, 2.2, 2.25, 1.3, 2.85, 0.5, 0), (-5.0, 1.8, 1.85, 1.3, 2.2, 0.4, 0)], 'soot',
                                    plates=dict(PL, seed=37, faces=[0, 1, 2, 3])), 'soot with dried-blood patches', note='the shoulder hump')
    K.mass('Hump crest', K.box('A17_crest', -3.8, -1.2, -1.2, 1.2, 2.7, 3.2, 'soot', ch=0.25, plates=dict(PL, seed=47, faces=[0, 1, 2, 3])),
           'soot', note='stepped crest on the hump')
    K.box('A17_rust_brow', 4.0, 4.6, -1.0, 0.6, 1.75, 1.82, 'rust')
    K.box('A17_red_crest', -2.8, -1.6, -1.15, 1.15, 3.2, 3.25, 'blood')
    for side in (1, -1):
        K.loft('A17_redstripe_%d' % side, [(2.0, side * 2.47 if side > 0 else 2.0, -2.0 if side > 0 else 2.52, 1.0, 1.35, 0, 0),
                                            (-0.5, side * 2.62 if side > 0 else 2.0, -2.0 if side > 0 else 2.67, 1.0, 1.4, 0, 0)], 'blood')
    K.mass('Engine block', K.box('A17_engblock', -6.0, -5.4, -1.9, 1.9, -1.3, 1.6, 'soot', ch=0.25), 'soot, steel')
    # belt strake along both flanks
    import kit as _k
    K.loft('A17_belt', [(x, _k.sec_at(HULL, x)[1] + 0.2, _k.sec_at(HULL, x)[2] + 0.2, -0.75, -0.3, 0.08, 0.08) for x in (2.2, 0.0, -2.5, -5.0)], 'iron')

    # ---- head: scoops, ears (dishes), jaws ----
    for side, fi, fd, r in ((1, 'I1', 'D1', 0.62), (-1, 'I2', 'D2', 0.55)):
        y = 2.55 * side
        K.tube(fi, (5.3, y, 0.25), r, 2.4, src='picture', note='%s scoop drum along the head flank%s' % ('port' if side > 0 else 'starboard', ', the larger' if side > 0 else ''))
        for i, x in enumerate((3.4, 4.1)):
            K.cyl('A17_%s_rib%d' % (fi, i), (x - 0.12, y, 0.25), (x + 0.12, y, 0.25), r * 1.15, 'steel')
        K.box('A17_%s_saddle' % fi, 2.9, 4.9, min(y, side * 2.1), max(y, side * 2.1), -0.2, 0.7, 'steel', ch=0.08)
        K.dish(fd, (2.6, 2.4 * side, 1.4), 0.85, yaw=25 * side, pitch=10, note='%s ear, listening dish' % ('port' if side > 0 else 'starboard'))
    K.box('A17_jaw_housing', 3.4, 4.8, -2.0, 2.0, -2.05, -1.5, 'steel', ch=0.15)
    for side, fl, fu in ((1, 'J1', 'J3'), (-1, 'J2', 'J4')):
        s_ = 'port' if side > 0 else 'starboard'
        K.claw(fl, (4.4, 1.55 * side, -1.75), [(5.4, 1.9 * side, -1.85), (6.4, 1.95 * side, -1.9), (7.25, 1.45 * side, -1.85)],
               w=0.7, name='boarding jaw', note='%s lower jaw, hinged, opens sideways' % s_)
        K.claw(fu, (4.6, 2.2 * side, -0.85), [(5.5, 2.45 * side, -0.95), (6.3, 2.45 * side, -1.0), (6.85, 2.0 * side, -1.05)],
               w=0.5, name='boarding jaw', src='picture' if side < 0 else 'designed', note='%s upper jaw' % s_)

    # ---- chains: girdles over the neck and hump seams ----
    K.chain('C1', [(2.45, 2.35, -0.6), (2.45, 1.9, 1.35), (2.45, -1.9, 1.35), (2.45, -2.35, -0.6)], note='girdle over the neck seam')
    K.chain('C2', [(-0.7, 2.75, 0.2), (-0.7, 2.25, 2.0), (-0.7, 1.5, 2.8), (-0.7, -1.5, 2.8), (-0.7, -2.3, 2.0), (-0.7, -2.8, 0.2)],
            note='girdle over the hump front')

    # ---- weapons, by data.js slot ----
    K.launcher('R1', (4.35, 0.0, 1.85), 2, 3, cell=0.391, depth=1.3, pitch=5, slot='F', weapon='torp',
               note='rattle-rocket pod on the brow, firing over the jaws')
    K.gun('T1', (-2.5, 0.0, 3.2), 0, 8, barrels=2, cal=0.1, blen=1.4, size=0.9, slot='T', weapon='flak', note='hump-top twin, 360 degrees')
    K.gun('T2', (-1.6, 0.0, -1.75), 0, -8, barrels=2, cal=0.09, blen=1.2, size=0.8, normal=(0, 0, -1), slot='T', weapon='flak',
          note='belly twin, covers below')
    for side, sl in ((1, 'P'), (-1, 'S')):
        for i, x in enumerate((1.7, -0.3)):
            K.gun('%s%d' % (sl, i + 1), (x, side * 1.9, 1.5 if x > 0.5 else 1.6), side * 45, 2, barrels=2, cal=0.09, blen=1.25,
                  size=0.85, slot=sl, weapon='scatter', note='deck-edge twin turret')
        K.gun('%s3' % sl, (-3.3, side * 2.25, 2.1), side * 55, 0, barrels=2, cal=0.09, blen=1.2, size=0.8, normal=(0, side, 0),
              slot=sl, weapon='scatter', note='hump flank casemate')

    # ---- engines: a stacked cluster, three per side, port bells larger ----
    for side, base in ((1, 'E1'), (-1, 'E4')):
        for j, (z, r) in enumerate(((1.05, 0.5), (0.0, 0.58), (-0.95, 0.42))):
            rr = r * (1.08 if side > 0 else 0.95)
            K.engine('E%d' % ((1 if side > 0 else 4) + j), (-7.25 + 0.9 * rr, side * 1.1, z), rr, 1.0, bell=1.2,
                     src='picture' if side > 0 or j == 0 else 'designed', note='%s %s' % ('port' if side > 0 else 'starboard', ('upper', 'main', 'lower')[j]))
    for i, (x, y, z, n) in enumerate([(4.2, 2.45, 1.0, (0, 1, 0)), (4.2, -2.45, 1.0, (0, -1, 0)),
                                      (-5.3, 2.1, 1.0, (0, 1, 0)), (-5.3, -2.15, 1.0, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, note='bow' if x > 0 else 'stern')
    for i, x in enumerate((3.6, 1.0, -1.5, -4.0)):
        for side in (1, -1):
            K.box('A17_light%d%s' % (i, 'p' if side > 0 else 's'), x - 0.08, x + 0.08, side * 2.55 - 0.03, side * 2.55 + 0.03, -1.05, -0.95, 'light')

    # ---- colour zones ----
    K.colour('weathered grey and soot plate', 7.25, -7.25, 'whole hull')
    K.colour('pale grey trophy plate (brow)', 4.75, 2.8, 'head top')
    K.colour('rust patch', 4.6, 4.0, 'brow, forward')
    K.colour('dried-blood red stripes', 2.0, -0.5, 'both deck edges')
    K.colour('dried-blood red patch', -1.6, -2.8, 'hump crest')

    # ---------- INSIDE ----------
    K.deck('lower', -0.75, -5.4, 4.5)
    K.deck('main', 0.55, -5.4, 4.5)
    K.deck_box('hump', 1.9, -4.3, 0.2, 1.8)
    for i, x in enumerate((4.4, 2.5, 0.2, -2.6, -4.7)):
        K.bulkhead('F%d' % i, x)
    K.room('jaw_machinery', 'machinery', 3.4, 4.6, -1.8, 1.8, -1.45, -0.85, note='jaw rams and winches')
    K.room('boarding_kennels', 'crew', 2.9, 4.6, -1.9, 1.9, -0.65, 0.45, note='boarding gangs behind the jaws')
    K.room('ears_and_bridge', 'bridge', 2.9, 4.5, -1.4, 1.4, 0.65, 1.25, note='listening room and bridge under the brow')
    K.room('rocket_magazine', 'magazine', 3.4, 4.3, -0.6, 0.6, 1.3, 1.8, note='under the rocket pod')
    K.room('loot_hold', 'hold', 0.3, 2.3, -2.0, 2.0, -1.45, 0.45, note='neck hold')
    K.room('crew_decks', 'crew', -2.5, 0.1, -2.1, 2.1, 0.65, 1.8, note='')
    K.room('shell_magazine', 'magazine', -2.5, 0.1, -2.1, 2.1, -1.45, 0.45, note='battery magazines')
    K.room('flak_magazine', 'magazine', -3.4, -1.7, -0.8, 0.8, 2.0, 2.65, note='under the hump twin')
    K.room('core', 'core', -4.5, -2.8, -1.2, 1.2, -1.45, 0.45, note='reactor core (hp_core)')
    K.room('engine_room', 'engroom', -5.4, -4.8, -1.8, 1.8, -1.2, 1.4, note='engine room and feeds')
    K.armour('head (forward of 4.4)', 0.45, 'ram plate behind the jaws')
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
    K.point('rcs', 'hp_rcs_0', (4.2, 2.45, 1.0), side='port')
    K.point('rcs', 'hp_rcs_1', (4.2, -2.45, 1.0), side='stbd')
    K.point('board', 'hp_board_0', (-0.5, 2.6, 0.2), side='port')
    K.point('board', 'hp_board_1', (-0.5, -2.65, 0.2), side='stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Guns laid out as matched batteries by game slot', 'the picture scatters guns on one edge and the far flank; scatter P and S are mirrored (two deck-edge twin turrets and a hump casemate per side), flak on the spine and the belly, the rocket pod on the brow')
    K.change('Lean hull, profile from the round 8 side view', 'Ryan kept A17 lean (R213); the head sits low and heavy, the hump rises behind the neck')
    K.change('Jaws are two matched pairs hinged on a housing, hooks turned inboard', 'the picture shows three loose arms; jaws that open sideways must close on something')
    K.change('Scoops and ears made a matched pair (port scoop larger)', 'the picture shows a large port scoop and a small starboard one; kept mismatched in size, matched in place')
    K.change('Engines are a stacked cluster of three per side, glow aft only', 'the picture shows a port cluster and one starboard pod glowing at its front')
    K.change('Forward rocket pod, belly flak turret and four attitude thrusters added', 'data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters')
    K.change('Chains are taut girdles over the neck and hump seams', 'a slack chain cannot drape in space; the girdles sit on the break lines')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.open_item('Belly detail between the jaw housing and the engines is designed here; the picture does not show it')
