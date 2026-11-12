# ROUND 2 LAYOUT, kept only to run the round 3 fit check on it (the "before" column of the fit report).
# Adapted to the round 3 kit API: intake() -> tube(), launcher(tube_r=r) -> launcher(cell=2.3 r). Not a live design.
# corsair_A16 round 2: the Warlord's Pyre-Barge (Ashfall Hullbreakers flagship, class Battle-barge, 26 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (R201), from round 1 Scrap Brick
# (concept_directions_2026_11/corsair_A.jpg, R197). data.js c_boss: scatter P, scatter S, htorp F, flak T, hangar 2.
# Round 2 (R213, and Ryan 19:40 CST: "the concept should inform and guide but it's not a final play by play guide"):
# designed as a warship from the picture's identity. Profile and plan from a true side and top reading (the round 8 sheet's
# side and top views, 48 px per unit) and the TRELLIS shape reference, not from one three-quarter camera.
# +X bow, +Y port, +Z up. Prow tip (scoop lips) x = +13; centre engine exit x = -13; flat belly z = -3.05.
CODE = 'corsair_A16'
NAME = "Warlord's Pyre-Barge"
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Battle-barge'
LENGTH = 26.0
GAME = "data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg'

# tier 1, the hull: (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer)
# blunt chin rising to the scoops, a deep flat-bellied slab, a narrower stern body between the engine pods
HULL = [
    (11.9, 2.3, 2.35, -0.9, 1.1, 0.55, 0.6),
    (11.1, 2.9, 2.95, -1.6, 1.55, 0.7, 0.9),
    (9.6, 3.4, 3.5, -2.45, 1.7, 0.85, 1.1),
    (8.0, 3.75, 3.9, -2.9, 1.75, 0.95, 1.1),
    (4.0, 4.15, 4.35, -3.05, 1.8, 1.0, 1.1),
    (0.0, 4.25, 4.45, -3.05, 1.85, 1.0, 1.1),
    (-3.5, 4.15, 4.3, -3.0, 1.85, 1.0, 1.1),
    (-6.2, 3.6, 3.7, -2.8, 1.85, 0.9, 1.0),
    (-7.6, 2.7, 2.75, -2.5, 1.8, 0.7, 0.9),
    (-10.4, 2.4, 2.4, -2.2, 1.7, 0.6, 0.8),
    (-11.2, 1.9, 1.9, -1.6, 1.3, 0.5, 0.6),
]
def bpy_obj(name, K):
    import bpy
    return bpy.data.objects[name]


PL = dict(size=(0.8, 2.2), thick=(0.06, 0.24), skip=0.15, stack=0.35, mats={'soot': 7, 'soot2': 5, 'rust': 3, 'iron': 2, 'blood': 1})


def build(K):
    K.mass('Hull slab (tier 1)', K.hull(HULL, 'soot', shell=0.35, plates=dict(PL, seed=16)), 'soot black, patched plate',
           note='deep flat-bellied slab, blunt chin')
    # tier 2: the raised armoured deck, a stepped and sloped front at 7.0
    K.mass('Raised armoured deck (tier 2)', K.loft('A16_tier2', [
        (7.0, 2.4, 2.5, 1.5, 1.95, 0.3, 0), (6.3, 3.1, 3.3, 1.5, 2.6, 0.45, 0), (0.0, 3.4, 3.55, 1.5, 2.65, 0.5, 0),
        (-2.6, 3.3, 3.45, 1.5, 2.65, 0.5, 0)], 'rust', plates=dict(PL, seed=26, faces=[0, 1, 2, 3])), 'rust plate',
        note='the stacked slab over the forward two thirds')
    # tier 3: the castle, sloped front, then the bridge block on its roof
    K.mass('Castle (tier 3)', K.loft('A16_castle', [
        (-2.2, 2.6, 2.7, 2.3, 2.75, 0.3, 0), (-2.9, 3.1, 3.2, 2.3, 3.45, 0.5, 0), (-7.0, 3.0, 3.1, 2.3, 3.45, 0.5, 0),
        (-7.8, 2.6, 2.7, 2.3, 3.05, 0.4, 0)], 'soot', plates=dict(PL, seed=36, faces=[0, 1, 2, 3])), 'soot with a dried-blood band')
    K.mass('Bridge block', K.loft('A16_bridge', [(-3.6, 1.6, 1.6, 3.35, 3.95, 0.3, 0), (-6.4, 1.9, 1.9, 3.35, 4.05, 0.35, 0)], 'soot'),
           'soot', note='command deck on the castle roof')
    K.box('A16_bridge_slit', -3.7, -3.55, -1.2, 1.2, 3.6, 3.8, 'dark')
    K.loft('A16_redband', [(-2.15, 2.65, 2.75, 2.28, 2.8, 0.3, 0), (-2.95, 3.15, 3.25, 2.28, 3.5, 0.52, 0)], 'blood')
    # the stern deck behind the castle carries the upper pod saddle
    K.box('A16_aftdeck', -10.2, -7.7, -2.0, 2.0, 1.6, 2.2, 'steel', ch=0.2, plates=dict(PL, seed=46, faces=[1]))

    # flank sponsons under the castle casemates and a belt strake along each flank (shape and elevation on the sides)
    import kit as _k
    for side, sn in ((1, 'p'), (-1, 's')):
        K.box('A16_sponson_%s' % sn, -6.4, -2.9, min(side * 2.9, side * 4.45), max(side * 2.9, side * 4.45),
              0.2, 1.75, 'soot', ch=0.25, plates=dict(PL, seed=60 + side, faces=[0, 1, 2, 3, 4, 5, 6, 7]))
    belt = []
    for x in (9.0, 6.0, 3.0, 0.0, -3.0, -6.0):
        h = _k.sec_at(HULL, x)
        belt.append((x, h[1] + 0.28, h[2] + 0.28, -1.15, -0.45, 0.12, 0.12))
    K.loft('A16_belt', belt, 'iron')
    K.mass('Flank sponsons and belt strakes', bpy_obj('A16_sponson_p', K), 'soot, iron', note='one per side, matched')

    # trophy plates (colour zones)
    K.box('A16_violet_fd', 4.4, 6.0, -3.2, -1.6, 2.6, 2.7, 'violet')
    K.loft('A16_violet_flank', [(6.4, 4.0, -3.4, -0.6, 1.0, 0, 0), (4.7, 4.18, -3.6, -0.6, 1.0, 0, 0)], 'violet')
    K.loft('A16_pale_flank', [(2.6, 4.26, -3.8, -1.4, 0.9, 0, 0), (-0.2, 4.31, -3.8, -1.4, 0.9, 0, 0)], 'pale')

    # ---- bow: scoops, dishes, claws ----
    K.tube('I1', (12.9, 1.2, -0.1), 0.95, 1.8, note='port wake-sniffer scoop')
    K.tube('I2', (12.9, -1.2, -0.1), 0.95, 1.8, note='starboard wake-sniffer scoop')
    K.box('A16_scoop_cowl', 11.0, 12.5, -2.4, 2.4, 0.85, 1.35, 'soot', ch=0.2)
    K.box('A16_scoop_cheek_p', 11.0, 12.3, 2.0, 2.5, -1.2, 0.9, 'steel', ch=0.1)
    K.box('A16_scoop_cheek_s', 11.0, 12.3, -2.5, -2.0, -1.2, 0.9, 'steel', ch=0.1)
    K.box('A16_dish_plinth', 9.0, 10.4, -2.1, 2.1, 1.7, 1.95, 'steel', ch=0.08)
    K.dish('D1', (9.8, 1.25, 1.95), 0.95, yaw=5, pitch=12, note='port listening dish')
    K.dish('D2', (9.8, -1.25, 1.95), 0.95, yaw=-5, pitch=12, note='starboard listening dish')
    for side, fid in ((1, 'H1'), (-1, 'H2')):
        y = 1.45 * side
        K.box('A16_%s_housing' % fid, 8.4, 10.4, y - 0.55, y + 0.55, -2.75, -2.1, 'steel', ch=0.12)
        K.claw(fid, (10.0, y, -2.55), [(10.8, y, -3.6), (11.5, y, -4.6), (11.5, y, -5.4), (10.9, y, -5.75)], w=1.35,
               note='%s boarding claw, hinged, swings forward to grip' % ('port' if side > 0 else 'starboard'))
    for side, fid in ((1, 'H3'), (-1, 'H4')):
        y = 2.1 * side
        K.box('A16_%s_housing' % fid, -2.4, -0.6, y - 0.45, y + 0.45, -3.4, -2.95, 'steel', ch=0.1)
        K.claw(fid, (-0.9, y, -3.25), [(-0.2, y, -3.95), (0.35, y, -4.45), (0.2, y, -4.9)], w=0.6, src='designed',
               note='grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath)')

    # ---- chains: taut girdles over the tier seams ----
    K.chain('C1', [(7.25, 3.75, 0.6), (7.25, 2.9, 1.95), (7.25, -2.95, 1.95), (7.25, -3.9, 0.6)], note='girdle over the tier 2 seam')
    K.chain('C2', [(-2.45, 4.4, 0.4), (-2.45, 3.5, 2.7), (-2.45, 2.7, 2.85), (-2.45, -2.75, 2.85), (-2.45, -3.6, 2.7), (-2.45, -4.6, 0.4)],
            note='girdle over the castle seam')
    K.chain('C3', [(9.2, 3.5, -0.2), (4.0, 4.3, -0.4), (-1.6, 4.43, -0.5)], note='port flank lashing, bow to midships')

    # ---- weapons, laid out by data.js slot ----
    # F (htorp): one heavy rocket rack on the spine, in front of the castle, firing over the bow
    K.launcher('R1', (2.4, 0.0, 2.65), 2, 5, cell=0.598, depth=2.6, pitch=6, slot='F', weapon='htorp',
               note='heavy rocket rack, 10 tubes, magazine below')
    # T (flak): two twin turrets on the spine, 360 degree arcs
    K.box('A16_bunker', 4.0, 5.6, -1.1, 1.1, 2.6, 3.45, 'soot', ch=0.3)
    K.box('A16_bunker_slit', 5.55, 5.65, -0.8, 0.8, 3.0, 3.2, 'dark')
    K.gun('T1', (4.8, 0.0, 3.45), 0, 10, barrels=2, cal=0.15, blen=2.3, size=1.4, slot='T', weapon='flak',
          note='forward flak turret on the gun bunker')
    K.gun('T2', (-5.0, 0.0, 4.05), 0, 10, barrels=2, cal=0.16, blen=2.4, size=1.5, slot='T', weapon='flak',
          note='castle flak turret, superfiring over the rack')
    # P and S (scatter): matched broadside batteries, one mount family per tier
    for side, sl in ((1, 'P'), (-1, 'S')):
        sy = side
        K.gun('%sB' % sl, (10.4, sy * 3.25, 0.3), sy * 15, 0, barrels=1, cal=0.2, blen=1.8, size=1.25, normal=(0, sy, 0),
              slot=sl, weapon='scatter', note='bow casemate, trained forward')
        for i, x in enumerate((6.0, 3.4, 0.8)):
            K.gun('%s%d' % (sl, i + 1), (x, sy * 2.75, 2.65), sy * 45, 2, barrels=2, cal=0.15, blen=2.2, size=1.4,
                  slot=sl, weapon='scatter', note='deck-edge twin turret, tier 2')
        for i, x in enumerate((-3.9, -6.1)):
            K.gun('%s%d' % (sl, i + 4), (x, sy * 3.12, 2.85), sy * 55, 0, barrels=2, cal=0.14, blen=2.0, size=1.25,
                  normal=(0, sy, 0), slot=sl, weapon='scatter', note='castle flank twin casemate')

    # ---- engines: a centre main, two main pods (port the larger), lower boosters, an upper pod ----
    K.engine('E0', (-11.8, 0.0, -0.1), 1.3, 1.5, bell=1.15, note='centre main engine')
    for side, fid, r in ((1, 'E1', 1.5), (-1, 'E2', 1.3)):
        y = 4.25 * side
        K.box('A16_%s_pylon' % fid, -10.2, -7.9, min(y, side * 2.4), max(y, side * 2.4), -0.6, 1.0, 'steel', ch=0.15)
        K.engine(fid, (-11.0, y, 0.3), r, 3.4, bell=1.2, src='picture' if side > 0 else 'designed',
                 note='%s main pod%s' % ('port' if side > 0 else 'starboard', ', the large one' if side > 0 else ', smaller (mismatched)'))
    for side, fid in ((1, 'E3'), (-1, 'E4')):
        K.engine(fid, (-10.6, 1.5 * side, -2.0), 0.5, 1.5, bell=1.25, src='picture' if side > 0 else 'designed',
                 note='lower booster')
    K.engine('E5', (-10.3, -1.3, 2.75), 0.55, 2.2, bell=1.2, note='upper starboard pod on the stern deck')
    for i, (x, y, z, n) in enumerate([(11.4, 2.85, 0.6, (0, 1, 0)), (11.4, -2.9, 0.6, (0, -1, 0)),
                                      (-9.6, 2.4, 1.2, (0, 1, 0)), (-9.6, -2.4, 1.2, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, note='bow' if x > 0 else 'stern')

    # ---- belly ----
    K.box('A16_bay_door', -4.0, -0.4, -1.7, 1.7, -3.18, -3.02, 'steel', ch=0.05)
    K.fitting('B1', 'ventral launch bay door, 3.6 x 3.4', (-2.2, 0, -3.1), aim=(0, -90), src='designed',
              note='data.js hangar 2: squadrons drop from the belly', kind='bay')
    for i, x in enumerate((8.5, 5.0, 1.5, -2.0, -5.5)):
        for side in (1, -1):
            K.box('A16_light%d%s' % (i, 'p' if side > 0 else 's'), x - 0.12, x + 0.12, side * 4.0 - 0.03, side * 4.0 + 0.03, -1.6, -1.45, 'light')

    # ---------- colour zones ----------
    K.colour('soot black base plate', 13.0, -13.0, 'whole hull', 'patched, worn; dim red running lights')
    K.colour('rust plate (tier 2)', 7.0, -2.6, 'raised armoured deck')
    K.colour('violet Eclipse trophy plate', 6.0, 4.4, 'tier 2 deck, starboard')
    K.colour('violet Eclipse trophy plate', 6.4, 4.7, 'port flank')
    K.colour('pale Hegemony grey trophy plates', 2.6, -0.2, 'port flank')
    K.colour('dried-blood red band', -2.15, -2.95, 'castle front')

    # ---------- INSIDE ----------
    K.deck('lower', -1.55, -10.0, 10.6)
    K.deck('main', 0.1, -10.2, 11.0)
    K.deck_box('gun', 1.95, -2.4, 6.6, 2.9)
    K.deck_box('castle', 2.75, -7.6, -2.6, 2.6)
    for i, x in enumerate((11.0, 8.0, 4.8, 0.8, -2.6, -6.4, -9.0)):
        K.bulkhead('F%d' % i, x)
    K.room('ram_void', 'armour', 11.0, 11.8, -2.0, 2.0, -1.0, 1.0, note='ram plating and scoop ducts')
    K.room('claw_machinery', 'machinery', 8.1, 10.9, -2.6, 2.6, -2.4, -1.65, note='claw rams and winches')
    K.room('kennel_decks', 'crew', 4.9, 10.8, -3.0, 3.0, -1.45, 1.6, note='boarding gangs, two decks')
    K.room('rocket_magazine', 'magazine', -0.4, 4.7, -1.6, 1.6, 0.2, 1.85, note='under the rocket rack')
    K.room('loot_hold', 'hold', 0.9, 4.7, -3.2, 3.2, -2.6, -1.65, note='loot holds')
    K.room('hangar', 'hangar', -4.2, 0.7, -2.6, 2.6, -2.7, 0.0, note='two squadrons, belly drop')
    K.room('core', 'core', -6.3, -4.3, -1.3, 1.3, -2.6, 0.0, note='reactor core (hp_core)')
    K.room('shell_magazine_p', 'magazine', -6.3, -2.7, 1.6, 3.3, 0.2, 1.8, note='port battery magazine')
    K.room('shell_magazine_s', 'magazine', -6.3, -2.7, -3.3, -1.6, 0.2, 1.8, note='starboard battery magazine')
    K.room('gun_deck', 'crew', -2.5, 6.4, -2.6, 2.6, 2.0, 2.5, note='turret crews and hoists')
    K.room('warlord_hall', 'crew', -7.5, -2.7, -2.4, 2.4, 2.8, 3.3, note='the warlord hall')
    K.room('bridge', 'bridge', -6.3, -3.7, -1.4, 1.4, 3.4, 3.9, note='command deck')
    K.room('engine_room', 'engroom', -10.2, -6.5, -2.0, 2.0, -2.1, 1.6, note='engine room and pod feeds')
    K.armour('ram bow (forward of 11.0)', 0.6, 'stacked scrap ram plating behind the scoops')
    K.armour('flank belt (lower and main decks)', 0.4, 'patch plates over the base hull')
    K.armour('tier 2 and castle roof', 0.3, '')
    K.armour('belly', 0.35, 'flat armoured belly with chines')
    K.armour('engine end', 0.2, 'thinnest: the soft spot')
    # break lines (factions.md "How it breaks": Hullbreakers part at the chained patch seams; Battle-barge 3 lines), uneven seam
    # paths, never a straight cut (R186); the death also takes a ragged bite out of the hull where the core goes (R215)
    K.break_line('B-1', 7.0, 'tier 2 seam under the C1 girdle: the bow and the kennel decks tear off; C1 holds them a moment',
                 path=[(7.3, 2.0), (6.8, 1.3), (7.5, 0.4), (6.9, -0.7), (7.6, -1.8), (7.1, -2.95)])
    K.break_line('B-2', -2.5, 'castle seam under the C2 girdle: opens the rocket magazine and the hangar',
                 path=[(-2.3, 3.45), (-2.9, 2.5), (-2.1, 1.4), (-2.8, 0.2), (-2.0, -1.2), (-2.7, -3.05)])
    K.break_line('B-3', -7.4, 'castle and engine room seam: the engine block tears away with the stern',
                 path=[(-7.8, 3.05), (-7.2, 1.9), (-7.9, 0.7), (-7.3, -0.8), (-7.7, -2.5)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215): decks, frames, spaces and machinery along the whole length, hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).'))
    K.point('core', 'hp_core', (-5.3, 0, -1.3))
    for i, (x, y, z, sec, side) in enumerate([(9.4, 3.45, 0.2, 'prow', 'port'), (7.4, -3.9, -1.2, 'prow', 'stbd'),
                                              (4.0, 4.2, -0.6, 'mid', 'port'), (-2.5, -3.3, 2.5, 'mid', 'stbd'),
                                              (-0.8, 4.4, 0.9, 'mid', 'port'), (-7.5, 2.7, 0.9, 'eng', 'port'),
                                              (-8.6, -2.6, -1.4, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (11.4, 3.1, 0.6), side='port')
    K.point('rcs', 'hp_rcs_1', (11.4, -3.15, 0.6), side='stbd')
    K.point('board', 'hp_board_0', (2.0, 4.3, -1.0), side='port')
    K.point('board', 'hp_board_1', (2.0, -4.5, -1.0), side='stbd')
    K.point('bay', 'hp_bay_0', (-2.2, 0, -3.15), note='launch down')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Guns laid out as matched port and starboard batteries by game slot', 'the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are now mirrored: a bow casemate, three deck-edge twin turrets and two castle casemates per side, the flak turrets on the spine')
    K.change('Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block', 'one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof and 7.1 to the bridge')
    K.change('Roof turret rests facing forward', 'the picture draws its barrel aft; no gun faces aft')
    K.change('The mid-length starboard engine pod becomes an upper pod on the stern deck', 'a pod at mid-length glowing forward would push the ship backward and burn its own deck')
    K.change('Two main engine pods, port larger, plus a centre main and lower boosters', 'the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells')
    K.change('Chains are taut girdles over the tier seams', 'a slack chain cannot sag in space; the faction rule is chains between hull sections, and the girdles sit on the break lines')
    K.change('Bow claws hinged on housings; two grapple arms added under the belly', 'the picture hooks hang from nothing; the round 8 side sheet and Ryan (R196) put hooks underneath')
    K.change('Ventral launch bay and four attitude thruster quads added', 'data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.open_item('Belly detail between the claws and the bay is designed here; the picture does not show it')
