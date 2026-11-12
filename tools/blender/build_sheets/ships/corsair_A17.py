# corsair_A17: Hullbreaker wrecker, the Pack Hunter (Ashfall Hullbreakers cruiser, class Cruiser, 14.5 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg (R201), from round 1 Pack Hunter
# (concept_directions_2026_11/corsair_B.jpg, R197). data.js c_marauder: scatter P, scatter S, torp F, flak T (no hangar).
# Units are world units. +X bow, +Y port, +Z up. Jaw tips at x = +7.25, engine exits near x = -7.25.
CODE = 'corsair_A17'
NAME = 'Hullbreaker wrecker (the Pack Hunter)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg'

# a heavy head, a narrower neck, a great shoulder hump, then the engine end
HULL = [
    (4.9, 2.4, 2.45, -1.45, 1.55, 0.5, 0.45),
    (4.3, 2.65, 2.7, -1.65, 1.8, 0.6, 0.5),
    (2.3, 2.6, 2.65, -1.7, 1.9, 0.75, 0.6),
    (0.2, 2.75, 2.8, -1.75, 2.35, 0.95, 0.6),
    (-2.8, 2.75, 2.8, -1.65, 2.6, 1.0, 0.6),
    (-4.8, 2.45, 2.5, -1.4, 2.5, 0.9, 0.5),
    (-5.8, 2.05, 2.1, -1.1, 1.95, 0.7, 0.4),
]


def build(K):
    K.mass('Hull (head, neck, hump)', K.hull(HULL, 'soot', shell=0.22), 'weathered grey and soot plate',
           note='heavy head, narrow neck, shoulder hump')
    K.mass('Head top block', K.loft('A17_headtop', [(4.7, 1.7, 1.8, 1.2, 1.85, 0.3, 0), (2.4, 1.8, 1.9, 1.4, 2.05, 0.3, 0)], 'pale'),
           'pale grey trophy plate with a rust patch')
    K.mass('Hump crest', K.loft('A17_crest', [(-0.6, 1.5, 1.6, 2.2, 2.95, 0.4, 0), (-4.4, 1.6, 1.7, 2.3, 3.15, 0.45, 0)], 'soot'),
           'soot with red patches', note='the shoulder hump top')
    K.box('A17_rust_head', 4.0, 4.6, -1.0, 0.6, 1.83, 1.9, 'rust')
    K.loft('A17_redstripe', [(3.6, -2.0, 2.62, 1.3, 1.62, 0, 0), (0.0, -2.2, 2.82, 1.8, 2.2, 0, 0)], 'blood')
    K.box('A17_red_hump', -1.6, -0.4, -1.0, 0.6, 2.95, 3.0, 'blood')
    K.loft('A17_red_flank', [(-3.2, 2.8, -2.6, 0.2, 1.4, 0, 0), (-4.2, 2.6, -2.4, 0.2, 1.4, 0, 0)], 'blood')
    K.mass('Engine block', K.box('A17_engblock', -6.4, -5.6, -1.9, 1.9, -1.0, 1.9, 'soot', ch=0.3), 'soot, steel')

    # ---- bow: scoops, dishes ("ears"), jaws ----
    K.intake('I1', (5.3, 1.6, -0.75), 0.6, 1.9, note='port scoop, low, ribbed duct along the port chin')
    K.cyl('A17_I1_rib', (3.2, 1.55, -0.75), (4.4, 1.55, -0.75), 0.7, 'steel')
    K.intake('I2', (5.15, -1.75, 0.15), 0.42, 1.0, note='starboard scoop, small (mismatched pair)')
    K.dish('D1', (3.3, 2.5, 1.0), 0.8, yaw=35, pitch=10, note='port ear, on the head flank')
    K.dish('D2', (4.0, -2.25, 1.55), 0.8, yaw=-30, pitch=15, note='starboard ear, on the head top edge')
    # jaws: open sideways, hooks turned inboard
    K.claw('J1', (4.5, -1.7, -1.1), [(5.5, -2.1, -1.25), (6.4, -2.2, -1.35), (6.9, -1.75, -1.45)], w=0.5,
           note='starboard upper jaw')
    K.claw('J2', (4.3, -1.0, -1.45), [(5.3, -1.35, -1.85), (6.0, -1.45, -2.1), (6.5, -1.0, -2.2)], w=0.45,
           note='starboard lower jaw (shorter, mismatched)')
    K.claw('J3', (4.0, 1.1, -1.45), [(4.9, 1.45, -1.95), (5.7, 1.55, -2.25), (6.2, 1.1, -2.4)], w=0.5,
           note='port lower jaw')
    K.claw('J4', (4.5, 1.8, -1.0), [(5.4, 2.15, -1.1), (6.3, 2.25, -1.2), (6.8, 1.8, -1.3)], w=0.45, src='designed',
           note='port upper jaw: hidden behind the port scoop in the picture; pairs J1 so the jaws can close')
    K.box('A17_jaw_housing', 3.4, 4.6, -1.9, 1.9, -1.8, -1.2, 'steel', ch=0.15)

    # ---- chains ----
    K.chain('C1', [(-0.2, 2.8, 1.8), (-0.4, 1.0, 3.0), (-0.6, -1.0, 3.0), (-0.8, -2.85, 1.8)], note='girdle over the hump front')
    K.chain('C2', [(3.4, -2.55, 1.45), (1.2, -2.6, 1.85), (-1.4, -2.85, 2.3)], note='starboard edge lashing, head to hump')

    # ---- weapons ----
    K.launcher('R1', (3.4, 0.5, 2.05), 2, 3, tube_r=0.16, depth=1.2, pitch=5, slot='F', weapon='torp', src='designed',
               note='rattle-rocket pod on the head top: data.js gives the wrecker a forward rocket slot; the picture shows none')
    K.gun('T1', (1.6, -0.3, 1.75), 0, 8, barrels=1, cal=0.1, blen=1.3, size=0.85, slot='T', weapon='flak', note='neck turret on a pedestal')
    K.gun('T2', (-2.6, 0.7, 3.12), 0, 6, barrels=2, cal=0.09, blen=1.2, size=0.8, slot='T', weapon='flak', note='hump-top twin')
    K.gun('S1', (3.3, -2.45, 1.45), -45, 0, barrels=2, cal=0.08, blen=1.0, size=0.7, slot='S', weapon='scatter', note='starboard edge')
    K.gun('S2', (1.9, -2.5, 1.7), -45, 0, barrels=2, cal=0.08, blen=1.0, size=0.7, slot='S', weapon='scatter', note='starboard edge')
    K.gun('S3', (0.4, -2.7, 2.3), -35, 0, barrels=1, cal=0.08, blen=1.0, size=0.7, slot='S', weapon='scatter', note='starboard edge')
    K.gun('S4', (-3.9, -2.8, 0.6), -50, 0, barrels=2, cal=0.09, blen=1.1, size=0.75, normal=(0, -1, 0), slot='S', weapon='scatter',
          src='designed', note='starboard hump casemate; the picture does not show the starboard flank')
    K.gun('P1', (-3.7, 2.8, 0.6), 50, 0, barrels=2, cal=0.09, blen=1.2, size=0.75, normal=(0, 1, 0), slot='P', weapon='scatter', note='port hump casemate')
    K.gun('P2', (-4.6, 2.55, 1.5), 55, 0, barrels=1, cal=0.08, blen=1.0, size=0.65, normal=(0, 1, 0), slot='P', weapon='scatter')
    K.gun('P3', (-2.7, 2.8, -0.7), 45, 0, barrels=1, cal=0.07, blen=0.8, size=0.6, normal=(0, 1, 0), slot='P', weapon='scatter')
    K.gun('P4', (-0.8, 2.3, -1.65), 35, -10, barrels=2, cal=0.08, blen=1.1, size=0.7, normal=(0, 0, -1), slot='P', weapon='scatter',
          note='port chin turret, hangs under the neck')

    # ---- engines (mismatched cluster, larger to port) ----
    K.engine('E1', (-6.4, 1.15, 1.3), 0.5, 1.4, bell=1.2, note='port upper')
    K.engine('E2', (-6.5, 1.35, 0.0), 0.62, 1.5, bell=1.2, note='port main, the large one')
    K.engine('E3', (-6.2, 1.5, -0.95), 0.34, 1.0, bell=1.25, note='port lower, small')
    K.engine('E4', (-6.2, -1.2, 1.4), 0.45, 1.3, bell=1.2, note='starboard upper')
    K.engine('E5', (-6.4, -1.3, -0.1), 0.52, 1.4, bell=1.2, src='designed', note='starboard main, smaller than E2')
    for i, x in enumerate((3.5, 1.0, -1.5, -4.0)):
        K.box('A17_light%d' % i, x - 0.08, x + 0.08, 2.5 + (0.25 if x < 0 else 0), 2.56 + (0.25 if x < 0 else 0), -0.45, -0.35, 'light')

    # ---- colour zones ----
    K.colour('weathered grey and soot plate', 7.25, -7.25, 'whole hull')
    K.colour('pale grey trophy plate (head top)', 4.7, 2.4, 'head top block')
    K.colour('rust patch', 4.6, 4.0, 'head top, forward')
    K.colour('dried-blood red stripe', 3.6, 0.0, 'starboard deck edge')
    K.colour('dried-blood red patch', -0.4, -1.6, 'hump top')
    K.colour('dried-blood red patch', -3.2, -4.2, 'port hump flank')

    # ---------- INSIDE ----------
    K.deck('lower', -0.55, -5.4, 4.6)
    K.deck('main', 0.75, -5.4, 4.6)
    K.deck('hump', 2.0, -4.6, 0.0)
    for i, x in enumerate((4.3, 2.3, 0.2, -2.8, -4.8)):
        K.bulkhead('F%d' % i, x)
    K.room('jaw_machinery', 'machinery', 3.4, 4.6, -1.8, 1.8, -1.3, -0.6, note='jaw rams and winches')
    K.room('boarding_kennels', 'crew', 2.4, 4.6, -1.9, 1.9, -0.45, 0.7, note='boarding gangs at the jaws')
    K.room('ears_sensor_room', 'bridge', 2.6, 4.4, -1.4, 1.4, 0.85, 1.6, note='listening room behind the dishes, the bridge')
    K.room('rocket_magazine', 'magazine', 2.6, 3.4, -0.4, 1.3, 1.45, 2.0, note='under the rocket pod')
    K.room('loot_hold', 'hold', 0.3, 2.2, -2.0, 2.0, -1.4, 0.65, note='neck hold')
    K.room('crew_decks', 'crew', -2.6, 0.1, -2.2, 2.2, 0.85, 1.9, note='')
    K.room('shell_magazine', 'magazine', -2.6, 0.1, -2.2, 2.2, -1.4, 0.65, note='battery magazines')
    K.room('flak_magazine', 'magazine', -3.4, -1.8, -0.6, 1.4, 2.1, 2.8, note='under the hump twin')
    K.room('core', 'core', -4.6, -2.9, -1.2, 1.2, -1.3, 0.65, note='reactor core (hp_core)')
    K.room('engine_room', 'engroom', -5.6, -4.9, -1.8, 1.8, -0.9, 1.8, note='engine room and feeds')
    K.armour('head (forward of 4.3)', 0.45, 'ram plate behind the jaws')
    K.armour('flanks', 0.25, 'patch plates')
    K.armour('hump roof and deck', 0.2, '')
    K.armour('belly', 0.25, 'flat armoured belly with chines')
    K.armour('engine end', 0.15, 'thinnest')
    K.break_line('B-1', 2.3, 'the neck seam under the C2 lashing: the head and jaws tear off, opening the kennels and the hold')
    K.break_line('B-2', -4.8, 'hump/engine seam: the engine cluster tears away, opening the engine room')
    K.point('core', 'hp_core', (-3.7, 0, -0.3))
    for i, (x, y, z, sec, side) in enumerate([(3.9, 2.4, 0.9, 'prow', 'port'), (3.0, -2.5, -0.6, 'prow', 'stbd'),
                                              (0.9, 2.7, 1.2, 'mid', 'port'), (-1.8, -2.85, 0.2, 'mid', 'stbd'),
                                              (-5.0, 2.35, 1.5, 'eng', 'port')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (4.6, 2.45, 0.6), side='port')
    K.point('rcs', 'hp_rcs_1', (4.6, -2.5, 0.6), side='stbd')
    K.point('board', 'hp_board_0', (-0.6, 2.75, 0.2), side='port')
    K.point('board', 'hp_board_1', (-0.6, -2.8, 0.2), side='stbd')

    # ---------- changed from the picture ----------
    K.change('Every gun rests facing forward or trained 35 to 55 degrees off the bow', 'the picture draws two port flank guns trained aft; no gun faces aft')
    K.change('Every gun sits on a turning ring or a ball casemate', 'several picture guns stand on thin posts or come straight out of plate')
    K.change('Jaws hinge on a housing under the head and their hooks turn inboard', 'the picture jaws are loose arms; jaws that open sideways must close on something')
    K.change('Fourth jaw J4 added (port upper)', 'the picture shows three; a pair per side lets the jaws close (it would sit behind the port scoop in the picture)')
    K.change('Chains are taut lashings between lugs', 'a slack chain cannot drape in space; the faction rule is chains between hull sections')
    K.change('Forward rocket pod R1 added on the head top', 'data.js gives the wrecker a forward rocket slot (torp F); the picture shows no launcher')
    K.change('Engine glow points aft only', 'the picture shows the upper starboard pod glowing at its front')
    K.change('Crystal shard removed', 'Ryan, R197')

    K.open_item('Starboard flank aft of the hump front: designed here (S4, E5); the picture does not show it')
    K.open_item('Belly between the jaw housing and the engines: flat armoured belly with chines, P4 chin turret; the picture does not show it')
