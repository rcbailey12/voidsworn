# corsair_A16: the Warlord's Pyre-Barge (Ashfall Hullbreakers flagship, class Battle-barge, 26 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (R201), from round 1 Scrap Brick
# (concept_directions_2026_11/corsair_A.jpg, R197). data.js c_boss: scatter P, scatter S, htorp F, flak T, hangar 2.
# Units are world units. +X bow, +Y port, +Z up. The prow tip (intake lips) is at x = +13, the engine exits near x = -13.
CODE = 'corsair_A16'
NAME = "Warlord's Pyre-Barge"
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Battle-barge'
LENGTH = 26.0
GAME = "data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg'

# hull loft: (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer)
# Lopsided on purpose (factions.md: bigger on one side): the starboard gun gallery carries 0.4 more beam amidships.
HULL = [
    (11.7, 2.7, 3.1, -1.3, 1.35, 0.7, 0.8),
    (10.9, 3.2, 3.6, -1.3, 1.85, 0.8, 0.9),
    (8.5, 3.55, 4.05, -1.5, 2.05, 0.95, 1.0),
    (3.0, 4.0, 4.2, -2.2, 2.1, 1.05, 0.9),
    (-4.0, 4.1, 4.2, -2.35, 2.1, 1.0, 0.9),
    (-7.0, 3.7, 3.8, -1.85, 2.0, 0.9, 0.8),
    (-9.4, 2.8, 3.1, -1.2, 1.75, 0.75, 0.6),
]


def build(K):
    H = HULL
    K.mass('Hull slab', K.hull(H, 'soot', shell=0.3), 'soot black, patched plate', note='one long lopsided slab, blunt bow')
    # raised foredeck plating (bolted second skin over the forward two thirds)
    K.mass('Foredeck plating', K.loft('A16_foredeck', [
        (10.4, 2.3, 2.6, 1.4, 2.35, 0.35, 0), (3.0, 2.8, 3.2, 1.6, 2.6, 0.4, 0), (-0.8, 2.8, 3.2, 1.6, 2.6, 0.4, 0)], 'rust'),
        'rust plate', note='raised second skin')
    # command bunker with twin vision slots (the block at 30 percent in the picture)
    K.mass('Command bunker', K.loft('A16_bunker', [
        (5.2, 1.0, 1.0, 2.4, 3.3, 0.35, 0, 0.3), (3.3, 1.2, 1.2, 2.4, 3.55, 0.35, 0, 0.3)], 'soot'), 'soot', note='bridge, armoured')
    K.box('A16_bunker_slot1', 5.0, 5.25, 0.0, 0.25, 2.8, 3.2, 'dark')
    K.box('A16_bunker_slot2', 5.0, 5.25, 0.55, 0.8, 2.8, 3.2, 'dark')
    # aft castle: the tall stern block, stepped
    K.mass('Aft castle', K.loft('A16_castle', [
        (-0.6, 3.1, 2.4, 1.5, 3.0, 0.6, 0), (-3.4, 3.3, 2.7, 1.5, 3.8, 0.7, 0), (-8.6, 3.0, 2.8, 1.5, 4.1, 0.7, 0),
        (-10.2, 2.8, 2.6, 1.5, 4.0, 0.6, 0)], 'soot'), 'soot with a dried-blood band', note='stepped stern block')
    K.mass('Castle top deck', K.loft('A16_castle_top', [
        (-3.6, 1.8, 1.4, 3.7, 4.3, 0.3, 0), (-9.6, 2.0, 1.6, 3.7, 4.6, 0.35, 0)], 'soot'), 'soot')
    # dried-blood red band around the castle front (colour break at about 46 percent)
    K.loft('A16_redband', [(-0.5, 3.86, 4.26, -2.2, 2.15, 1.05, 0.88), (-1.6, 3.86, 4.26, -2.2, 2.15, 1.05, 0.88)], 'blood')
    K.loft('A16_redband_c', [(-0.5, 3.16, 2.46, 1.5, 3.05, 0.6, 0), (-1.6, 3.2, 2.56, 1.5, 3.3, 0.62, 0)], 'blood')
    # aft equipment body carrying the engines
    K.mass('Engine block', K.box('A16_engblock', -11.2, -9.2, -2.9, 2.9, -1.2, 2.6, 'soot', ch=0.5), 'soot, steel')

    # trophy plates (colour zones, not structure)
    K.box('A16_violet_fd', 8.6, 10.2, -2.9, -1.2, 2.33, 2.43, 'violet')      # foredeck, starboard side
    K.loft('A16_violet_flank', [(6.4, 3.84, -3.0, -0.3, 1.3, 0, 0), (4.6, 3.86, -3.0, -0.3, 1.3, 0, 0)], 'violet')
    K.loft('A16_pale_flank', [(2.8, 3.86, -3.0, -0.6, 1.6, 0, 0), (0.4, 3.86, -3.0, -0.6, 1.6, 0, 0)], 'pale')
    K.loft('A16_rust_flank', [(-1.2, 3.86, -3.0, -1.4, 1.0, 0, 0), (-4.5, 3.86, -3.0, -1.4, 1.0, 0, 0)], 'rust')

    # ---- bow: scoops, dishes, claws ----
    K.intake('I1', (12.95, 1.45, -0.45), 0.95, 1.6, note='port scoop')
    K.intake('I2', (12.95, -1.45, -0.45), 0.95, 1.6, note='starboard scoop')
    K.box('A16_scoop_cowl', 11.3, 12.6, -2.6, 2.6, 0.45, 0.95, 'soot', ch=0.2)
    K.dish('D1', (10.8, 1.4, 2.2), 0.85, yaw=10, pitch=15, note='port dish, faces forward')
    K.dish('D2', (10.5, -0.6, 2.3), 0.85, yaw=-5, pitch=15, note='centre dish, faces forward')
    K.claw('H1', (8.6, 1.5, -1.65), [(9.3, 1.5, -2.9), (9.9, 1.6, -3.9), (10.5, 1.6, -4.6), (10.9, 1.6, -5.0)], w=1.0,
           note='port boarding claw, hinged, folds back under the bow')
    K.claw('H2', (10.0, -1.7, -1.5), [(10.7, -1.7, -2.6), (11.3, -1.8, -3.5), (11.7, -1.8, -4.3), (11.6, -1.8, -4.8)], w=0.6,
           note='starboard boarding claw, mismatched (longer reach)')
    K.box('A16_claw_actuator1', 7.4, 8.8, 1.2, 1.8, -1.9, -1.4, 'steel', ch=0.1)
    K.box('A16_claw_actuator2', 8.6, 10.0, -2.0, -1.4, -1.8, -1.3, 'steel', ch=0.1)

    # ---- chains: taut lashings between hull sections (lugs at each end) ----
    K.chain('C1', [(9.4, 3.15, 1.45), (5.5, 3.65, 1.55), (1.0, 3.75, 1.6)], note='port upper lashing, bow to castle')
    K.chain('C2', [(8.0, 3.62, -0.9), (4.0, 3.82, -1.1), (-2.5, 3.82, -1.1)], note='port lower lashing, across the 1st break line')
    K.chain('C3', [(-0.2, 3.2, 2.65), (-0.4, 0.0, 2.75), (-0.6, -3.6, 2.65)], note='deck girdle over the foredeck/castle seam')

    # ---- weapons ----
    # forward heavy rocket rack (htorp F): the 2 x 5 tube block on the deck at about 40 percent
    K.launcher('R1', (1.6, -1.1, 2.6), 2, 5, tube_r=0.24, depth=2.2, pitch=6, slot='F', weapon='htorp',
               note='heavy rocket pod; tubes fire forward over the bow')
    # starboard deck-edge battery (scatter S), the row of guns along the far edge in the picture
    z_e = 2.25
    K.gun('S1', (9.6, -3.25, 2.0), -60, 0, barrels=1, cal=0.11, blen=0.75, slot='S', weapon='scatter', note='bow corner')
    K.gun('S2', (8.0, -3.45, 2.1), -60, 0, barrels=1, cal=0.11, blen=0.8, slot='S', weapon='scatter')
    K.gun('S3', (5.9, -3.55, z_e), -55, 2, barrels=1, cal=0.15, blen=1.3, size=1.2, slot='S', weapon='scatter', note='heavy single')
    K.gun('S4', (3.9, -3.6, z_e), -55, 2, barrels=1, cal=0.2, blen=1.5, size=1.35, slot='S', weapon='scatter', note='big-bore single')
    K.gun('S5', (1.9, -3.65, z_e), -55, 2, barrels=2, cal=0.12, blen=2.0, size=1.2, slot='S', weapon='scatter', note='twin')
    # starboard aft flank (hidden in the picture): designed here, two singles on castle sponsons
    K.gun('S6', (-5.0, -3.6, 2.25), -55, 0, barrels=1, cal=0.13, blen=2.0, mount='sponson', slot='S', weapon='scatter',
          src='designed', note='starboard castle; not visible in the picture')
    K.gun('S7', (-7.0, -3.85, 0.4), -50, 0, barrels=2, cal=0.12, blen=1.8, mount='sponson', normal=(0, -1, 0), slot='S',
          weapon='scatter', src='designed', note='starboard lower flank; not visible in the picture')
    # port flank battery (scatter P): twins and singles on sponson shelves aft of the bunker
    K.gun('P1', (-0.2, 3.95, 0.9), 50, 0, barrels=2, cal=0.12, blen=1.9, mount='sponson', normal=(0, 1, 0), slot='P', weapon='scatter')
    K.gun('P2', (-0.6, 3.95, -1.0), 45, -5, barrels=1, cal=0.12, blen=2.0, mount='sponson', normal=(0, 1, 0), slot='P', weapon='scatter')
    K.gun('P3', (-4.6, 3.75, 2.6), 55, 0, barrels=2, cal=0.12, blen=2.0, mount='sponson', slot='P', weapon='scatter', note='castle')
    K.gun('P4', (-6.6, 3.95, 0.9), 60, 0, barrels=2, cal=0.12, blen=1.9, mount='sponson', normal=(0, 1, 0), slot='P', weapon='scatter')
    K.gun('P5', (-3.6, 3.95, -0.6), 40, 0, barrels=1, cal=0.15, blen=2.4, mount='sponson', normal=(0, 1, 0), slot='P', weapon='scatter',
          note='long single')
    # flak turret on the castle top (flak T)
    K.gun('T1', (-6.0, 0.3, 4.42), 0, 10, barrels=2, cal=0.13, blen=2.0, size=1.25, slot='T', weapon='flak',
          note='roof turret; rests forward (the picture shows it aft)')

    # ---- engines (mismatched bells) ----
    K.engine('E1', (-11.675, 2.4, 0.4), 1.45, 2.4, bell=1.2, note='port main, the large one')
    K.engine('E2', (-11.2, -2.4, 0.5), 1.05, 2.2, bell=1.2, src='designed', note='starboard main, smaller (mismatched)')
    K.engine('E3', (-11.2, 2.8, -1.1), 0.55, 1.6, bell=1.25, note='port lower booster')
    K.engine('E4', (-10.9, -2.6, 2.75), 0.6, 2.0, bell=1.2, note='starboard upper stern pod')
    K.engine('E5', (-1.2, -4.6, 2.3), 0.62, 3.4, bell=1.2, note='starboard shoulder booster on a strut')
    K.box('A16_E5_strut', -0.8, 1.4, -4.6, -3.9, 1.8, 2.2, 'steel', ch=0.05)
    K.box('A16_E4_saddle', -10.5, -8.6, -3.2, -2.0, 2.2, 2.8, 'steel', ch=0.05)

    # ---- belly: hangar door and fittings (designed) ----
    K.box('A16_hangar_door', -3.5, 2.5, -1.6, 1.6, -2.0, -1.87, 'steel', ch=0.05)
    K.box('A16_belly_scoop', 5.0, 7.0, -0.9, 0.9, -2.15, -1.7, 'soot', ch=0.15)
    K.fitting('B1', 'ventral launch bay door, 6.0 x 3.2', (-0.5, 0, -2.2), aim=(0, -90), src='designed',
              note='data.js hangar 2: squadrons drop from the belly', kind='bay')
    K.fitting('B2', 'ventral scoop housing (claw stowage)', (6.0, 0, -2.15), src='designed', note='claws fold back into it')
    # running lights, port lower flank
    for i, x in enumerate((8.0, 5.0, 2.0, -1.5, -5.0, -8.0)):
        K.box('A16_light%d' % i, x - 0.12, x + 0.12, 3.84, 3.9, -0.55, -0.4, 'light')

    # ---------- INSIDE ----------
    K.deck('lower', -0.9, -9.0, 11.0)
    K.deck('main', 0.6, -9.0, 11.0)
    K.deck('castle', 2.3, -8.6, 0.7)
    for i, x in enumerate((10.4, 7.0, 3.6, 0.6, -3.2, -6.4, -9.0)):
        K.bulkhead('F%d' % i, x)
    K.room('ram_void', 'armour', 10.5, 11.4, -2.3, 2.3, -1.2, 1.0, note='ram plating backing and scoop ducts')
    K.room('claw_machinery', 'machinery', 7.2, 10.3, -2.6, 2.6, -1.9, -1.0, note='claw winches and stowage')
    K.room('kennel_decks', 'crew', 3.8, 10.2, -3.0, 3.0, -0.8, 0.5, note='boarding gangs, kennel decks')
    K.room('rocket_magazine', 'magazine', 1.0, 6.8, -1.4, 1.4, 0.7, 2.2, note='under the rocket rack')
    K.room('loot_hold', 'hold', 0.8, 6.8, -3.0, 3.0, -1.9, -1.0, note='loot holds')
    K.room('hangar', 'hangar', -3.0, 0.4, -2.4, 2.4, -1.9, 0.5, note='two squadrons, belly drop')
    K.room('shell_magazine_p', 'magazine', -6.2, -3.4, 1.4, 3.2, -0.8, 0.5, note='port battery magazine')
    K.room('shell_magazine_s', 'magazine', -6.2, -3.4, -3.4, -1.4, -0.8, 0.5, note='starboard battery magazine')
    K.room('core', 'core', -6.2, -3.4, -1.2, 1.2, -1.9, 0.5, note='reactor core (hp_core)')
    K.room('castle_crew', 'crew', -8.4, 0.6, -2.6, 2.6, 2.4, 3.3, note='warlord hall and gun crews')
    K.room('flak_magazine', 'magazine', -7.2, -4.8, -1.0, 1.0, 3.3, 4.3, note='flak turret magazine')
    K.room('engine_room', 'engroom', -9.0, -6.4, -3.0, 3.0, -1.9, 2.2, note='engine room and feeds')
    K.room('bunker_bridge', 'bridge', 3.4, 5.1, -0.6, 1.2, 2.45, 3.4, note='command bunker')
    K.armour('ram bow (forward of 10.4)', 0.6, 'stacked scrap ram plating')
    K.armour('flank belt (main and lower decks)', 0.35, 'patch plates over the base hull')
    K.armour('deck and castle roof', 0.25, '')
    K.armour('belly', 0.3, 'flat armoured belly with chines')
    K.armour('engine end', 0.2, 'thinnest: the soft spot')
    # break lines: Battle-barge has 3 authored break lines (factions.md); Hullbreakers break at the chained patch seams
    K.break_line('B-1', 6.9, 'chained seam behind the kennel decks; C2 lashing crosses it and holds the bow for a moment')
    K.break_line('B-2', 0.7, 'the foredeck/castle seam under the C3 girdle; opens the rocket magazine and hangar')
    K.break_line('B-3', -6.3, 'castle/engine room seam; the engine block tears away with the stern')
    # hard points (contract of PR 530: Battle-barge base 6, Hullbreakers +1 = 7 breach anchors, uneven, on patch seams)
    K.point('core', 'hp_core', (-4.8, 0, -0.7))
    for i, (x, y, z, sec, side) in enumerate([(9.0, 3.4, 0.4, 'prow', 'port'), (7.6, -3.85, -0.8, 'prow', 'stbd'),
                                              (4.0, 3.8, 0.2, 'mid', 'port'), (1.4, 0.4, 2.65, 'mid', 'top'),
                                              (-1.6, -4.2, 1.0, 'mid', 'stbd'), (-6.3, 3.8, 1.2, 'eng', 'port'),
                                              (-8.5, -3.4, -1.0, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (10.5, 3.3, 0.6), side='port')
    K.point('rcs', 'hp_rcs_1', (10.5, -3.45, 0.6), side='stbd')
    K.point('board', 'hp_board_0', (2.0, 3.85, -0.2), side='port')
    K.point('board', 'hp_board_1', (1.0, -4.25, -0.2), side='stbd')
    K.point('bay', 'hp_bay_0', (-0.5, 0, -2.25), note='launch down')

    # ---------- colour zones (stations of the breaks; finish from the beauty) ----------
    K.colour('soot black base plate', 13.0, -13.0, 'whole hull', 'patched, worn, dim red running lights')
    K.colour('rust plate (raised foredeck)', 10.4, -0.8, 'deck')
    K.colour('violet Eclipse trophy plate', 10.2, 8.6, 'deck, starboard of the dishes')
    K.colour('violet Eclipse trophy plate', 6.4, 4.6, 'port flank, upper')
    K.colour('pale Hegemony grey trophy plates', 2.8, 0.4, 'port flank, torn and overlapped')
    K.colour('dried-blood red band', -0.5, -1.6, 'round the hull and the castle front')
    K.colour('rust patch', -1.2, -4.5, 'port flank, lower')

    # ---------- changed from the picture ----------
    K.change('Roof turret T1 rests facing forward', 'the picture draws its barrel aft; no gun in the game faces aft')
    K.change('Chains are taut lashings between lugs on the hull', 'a slack chain cannot hang in a sagging loop in space; the faction rule is chains between hull sections')
    K.change('Every gun sits on a mount that can turn: deck-edge guns on turret rings, flank guns in ball casemates', 'several picture guns poke straight out of flat plate with no mount that could turn')
    K.change('Broadside guns rest trained 40 to 60 degrees forward of the beam', 'the picture draws the port guns square or slightly aft; no gun faces aft, and a barrel at rest must read in both the profile and the plan')
    K.change('Deck-edge barrels shortened (S4 big-bore 1.5 long, the light guns under 1)', 'the picture barrels are longer than the hull is deep at their stations and read as poles; kept heavy and short like the rest of the scrap guns')
    K.change('Starboard shoulder booster E5 put on a strut with its bell aft', 'the picture shows a pod at mid-length with its glow facing forward, which would push the ship backward')
    K.change('Claws are hinged on drums with actuator housings and fold back into a belly scoop', 'the picture hooks hang from nothing visible')
    K.change('Ventral launch bay added (B1)', 'data.js gives the Pyre-Barge a hangar of 2; the picture shows no bay')
    K.change('Crystal shard removed', 'Ryan, R197 (already gone from A16)')

    K.open_item('Starboard flank below the gallery: designed here (S6, S7, E2); the picture does not show it')
    K.open_item('Belly plating detail beyond the bay, scoop and claw stowage: the picture does not show it')
