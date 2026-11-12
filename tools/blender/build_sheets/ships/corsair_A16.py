# corsair_A16 round 3: the Warlord's Pyre-Barge (Ashfall Hullbreakers flagship, class Battle-barge, 26 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (R201), from round 1 Scrap Brick
# (concept_directions_2026_11/corsair_A.jpg, R197). data.js c_boss: scatter P, scatter S, htorp F, flak T, hangar 2.
# Round 3 (Ryan, Nov 11 21:24 and 21:34 CST, R217 and R218): the parts inventory comes first (corsair_A16_inv.py, every line
# carried by an `inv=` below); every part is a real kit shape (tools/blender/kits/hullbreakers/parts.py); the prow is a
# shaped cap with a stepped brow over a deep tube cluster; the guns, rack, engines and thrusters are laid out so the fit
# check (clash.py) passes: the round 2 turret in front of the rack is gone, the flak superfires from the castle and bridge.
# +X bow, +Y port, +Z up. Hooded tube lips reach x = +13.0; centre engine exit x = -12.95; flat belly z = -3.05.
CODE = 'corsair_A16'
NAME = "Warlord's Pyre-Barge"
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Battle-barge'
LENGTH = 26.0
GAME = "data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg'

# tier 1, the hull: (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer)
# a rounded faceted prow cap (heavy chamfers) over the tube cluster, a deep flat-bellied slab, a narrower stern body
HULL = [
    (12.05, 1.9, 1.95, -1.05, 0.75, 0.75, 0.75),
    (11.6, 2.75, 2.8, -1.75, 1.35, 0.95, 0.95),
    (10.6, 3.3, 3.4, -2.35, 1.65, 0.95, 1.1),
    (9.4, 3.6, 3.7, -2.75, 1.75, 0.95, 1.1),
    (8.0, 3.8, 3.95, -2.95, 1.8, 0.95, 1.1),
    (4.0, 4.15, 4.35, -3.05, 1.8, 1.0, 1.1),
    (0.0, 4.25, 4.45, -3.05, 1.85, 1.0, 1.1),
    (-3.5, 4.15, 4.3, -3.0, 1.85, 1.0, 1.1),
    (-6.2, 3.6, 3.7, -2.8, 1.85, 0.9, 1.0),
    (-7.6, 2.7, 2.75, -2.5, 1.8, 0.7, 0.9),
    (-10.4, 2.4, 2.4, -2.2, 1.7, 0.6, 0.8),
    (-11.2, 1.9, 1.9, -1.6, 1.3, 0.5, 0.6),
]
PL = dict(size=(0.45, 1.25), thick=(0.05, 0.2), skip=0.1, stack=0.45, mats={'soot': 7, 'soot2': 5, 'rust': 3, 'iron': 2, 'blood': 1})


def build(K):
    import kit as _k
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Hull slab (tier 1)', K.hull(HULL, 'soot', shell=0.35, plates=dict(PL, seed=16, inv=['bow_plates', 'belly_plates'])),
           'soot black, patched plate', note='deep flat-bellied slab, rounded faceted prow cap')

    # ---------------- the prow: a stepped brow over the tube cluster (R217: the bow carries the concept's shaping) ----------------
    K.mass('Prow brow (two steps)', K.loft('A16_brow', [
        (12.55, 2.35, 2.35, 0.55, 1.05, 0.35, 0.12), (12.2, 2.7, 2.7, 0.5, 1.4, 0.45, 0.15), (11.2, 3.0, 3.05, 0.6, 1.72, 0.55, 0.2)],
        'soot', plates=dict(PL, seed=17, faces=[0, 1, 2, 3], size=(0.5, 1.1), inv='bow_plates')), 'soot', note='overhangs the tube mouths')
    K.loft('A16_brow_step', [(11.5, 2.4, 2.45, 1.4, 1.95, 0.4, 0), (10.2, 2.7, 2.75, 1.4, 2.05, 0.45, 0)], 'rust',
           plates=dict(PL, seed=18, faces=[0, 1, 2, 3], size=(0.5, 1.0), inv='bow_plates'))
    K.loft('A16_chin', [(12.35, 2.3, 2.3, -1.45, -0.95, 0.1, 0.4), (11.2, 2.9, 2.95, -1.9, -0.9, 0.1, 0.5)], 'iron')
    K.mark('prow', 'hull', ['bevel', 'step', 'overhang'])
    # the tube cluster: two deep tubes with hooded lips, a ribbed spine between them, cheek housings outside
    for side, fid in ((1, 'I1'), (-1, 'I2')):
        K.tube(fid, (12.62, 1.36 * side, -0.25), 0.88, 2.5, hood=0.45, bands=3, inv='ftubes', what='front tube (wake-sniffer scoop)',
               note='%s front tube: deep bore, hooded rolled lip, clamp bands' % ('port' if side > 0 else 'starboard'))
        K.box('A16_tube_cheek_%d' % side, 10.9, 12.45, min(side * 2.05, side * 2.6), max(side * 2.05, side * 2.6), -1.25, 0.75, 'steel', ch=0.18)
    K.box('A16_spine_block', 11.2, 12.25, -0.2, 0.2, -0.9, 0.5, 'soot', ch=0.05)
    K.vent('V0', (12.25, 0.0, -0.25), (1, 0, 0), 0.38, 1.25, slats=6, inv='ftube_spine', note='ribbed spine between the tubes')

    # ---------------- tier 2: the raised armoured deck, a sloped and stepped front at 7.0 ----------------
    T2 = [(7.0, 2.4, 2.5, 1.5, 1.95, 0.3, 0), (6.3, 3.1, 3.3, 1.5, 2.65, 0.5, 0), (0.0, 3.4, 3.55, 1.5, 2.65, 0.5, 0),
          (-2.6, 3.3, 3.45, 1.5, 2.65, 0.5, 0)]
    K.mass('Raised armoured deck (tier 2)', K.loft('A16_tier2', T2, 'rust', plates=dict(PL, seed=26, faces=[0, 1, 2, 3], inv='bow_plates')),
           'rust plate', note='the stacked slab over the forward two thirds')
    for side in (1, -1):
        K.slit('SL%d' % (1 if side > 0 else 2), (6.68, 1.3 * side, 2.32), (0.75, 0, 0.66), 0.9, 0.16, inv='tier2', note='vision slit in the tier 2 front')
    K.mark('tier2', 'tier', ['face', 'roof', 'opening'])
    # the rack plinth: a raised armoured block on the spine, its front sloped
    K.mass('Rack plinth', K.loft('A16_plinth', [(3.0, 1.2, 1.2, 2.5, 2.85, 0.25, 0), (2.6, 1.65, 1.65, 2.5, 3.25, 0.3, 0),
                                                (-0.2, 1.65, 1.65, 2.5, 3.25, 0.3, 0)], 'soot', plates=dict(PL, seed=27, faces=[0, 1, 2, 3], size=(0.5, 1.0))),
           'soot', note='lifts the rack so it fires clear over the bow')

    # ---------------- castle (tier 3), bridge on a barbette ----------------
    CA = [(-2.2, 2.6, 2.7, 2.3, 2.75, 0.3, 0), (-2.9, 3.1, 3.2, 2.3, 3.45, 0.5, 0), (-7.0, 3.0, 3.1, 2.3, 3.45, 0.5, 0), (-7.8, 2.6, 2.7, 2.3, 3.05, 0.4, 0)]
    K.mass('Castle (tier 3)', K.loft('A16_castle', CA, 'soot', plates=dict(PL, seed=36, faces=[0, 1, 2, 3], inv='bow_plates')),
           'soot with a dried-blood band')
    K.mass('Bridge block', K.loft('A16_bridge', [(-4.5, 1.5, 1.5, 3.35, 3.95, 0.3, 0), (-4.9, 1.75, 1.75, 3.35, 4.05, 0.3, 0),
                                                 (-7.25, 1.9, 1.9, 3.35, 4.05, 0.35, 0)], 'soot'), 'soot', note='command deck on the castle roof')
    for side in (1, -1):
        K.slit('SL3%s' % ('p' if side > 0 else 's'), (-5.9, 1.85 * side, 3.72), (0, side, 0), 1.4, 0.16, inv='bridge', note='bridge flank vision slit')
    K.mark('bridge', 'tier', ['face', 'roof', 'opening'])
    K.loft('A16_redband', [(-2.15, 2.65, 2.75, 2.28, 2.8, 0.3, 0), (-2.95, 3.15, 3.25, 2.28, 3.5, 0.52, 0)], 'blood')
    cy = lambda x, side: _k.sec_at(CA, x)[1 if side > 0 else 2] * side  # noqa: E731
    for side in (1, -1):
        K.slit('SL%d' % (4 if side > 0 else 5), (-4.6, cy(-4.6, side), 3.0), (0, side, 0), 0.9, 0.15, inv='castle', note='castle flank slit')
        K.hatch('HC%d' % (1 if side > 0 else 2), (-5.95, cy(-5.95, side), 2.85), (0, side, 0), 0.55, 0.7, inv='castle_hatches', note='castle flank hatch')
    K.mark('castle', 'tier', ['face', 'roof', 'opening'])
    K.box('A16_barbette', -7.2, -6.1, -0.75, 0.75, 4.0, 4.4, 'iron', ch=0.15)
    # the stern deck behind the castle carries the upper pod saddle and the round hatch
    K.box('A16_aftdeck', -10.2, -7.7, -2.0, 2.0, 1.6, 2.2, 'steel', ch=0.2, plates=dict(PL, seed=46, faces=[1], size=(0.5, 1.0)))
    K.hatch('HR', (-8.6, 1.0, 2.2), (0, 0, 1), 0.7, round_=True, inv='round_hatch', note='round hatch with a hand wheel')

    # flank sponsons under the castle casemates and a belt strake along each flank
    for side, sn in ((1, 'p'), (-1, 's')):
        K.box('A16_sponson_%s' % sn, -6.6, -2.9, min(side * 2.9, side * 4.45), max(side * 2.9, side * 4.45),
              0.2, 1.75, 'soot', ch=0.25, plates=dict(PL, seed=60 + side, faces=[0, 1, 2, 3, 4, 5, 6, 7], size=(0.5, 1.2)))
    belt = []
    for x in (9.0, 6.0, 3.0, 0.0, -3.0, -6.0):
        h = _k.sec_at(HULL, x)
        belt.append((x, h[1] + 0.28, h[2] + 0.28, -1.15, -0.45, 0.12, 0.12))
    K.loft('A16_belt', belt, 'iron')
    K.mark('belt', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    K.mass('Flank sponsons and belt strakes', bpy_obj('A16_sponson_p'), 'soot, iron', note='one per side, matched')
    # vertical frame ribs on both flanks, belt top to the deck edge
    for i, x in enumerate((8.3, 5.0, -1.2, -6.8)):
        for side in (1, -1):
            y = sy(x, side) + 0.12 * side
            K.rib('RB%d%s' % (i, 'p' if side > 0 else 's'), [(x, y, -0.4), (x, y, 0.75)], w=0.26, inv='flank_ribs')

    # trophy plates (colour zones), torn patches
    K.box('A16_violet_fd', 4.4, 5.9, -3.0, -1.7, 2.62, 2.72, 'violet')
    K.loft('A16_violet_flank', [(5.7, 4.08, -3.4, -0.6, 0.6, 0, 0), (4.2, 4.2, -3.6, -0.6, 0.6, 0, 0)], 'violet')
    K.mark('bow_trophy', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    K.loft('A16_pale_flank', [(2.6, 4.28, -3.8, -1.4, -0.5, 0, 0), (-0.6, 4.33, -3.8, -1.4, -0.5, 0, 0)], 'pale')
    K.mark('pale_plates', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    import random
    rp = random.Random(1616)
    for i, (x, z, side) in enumerate([(4.0, 0.35, 1), (-0.3, 0.45, 1), (4.1, 0.3, -1), (-0.4, 0.5, -1)]):
        K.patch('PT%d' % i, (x, sy(x, side) + 0.2 * side, z), (0, side, 0), rp.uniform(0.7, 0.9), rp.uniform(0.5, 0.7), ang=rp.uniform(-0.3, 0.3),
                lift=rp.uniform(0.08, 0.18), m=rp.choice(['iron', 'pale', 'rust']), inv='patches')
    for i, (x, side) in enumerate([(2.2, 1), (-1.9, 1), (2.0, -1), (-1.6, -1)]):
        hy = abs(sy(x, side)) - 0.5
        K.patch('PT%d' % (4 + i), (x, (hy + 0.12) * side, 1.42), (0, 0.7 * side, 0.7), rp.uniform(0.8, 1.1), 0.55, ang=0.2 * side, lift=0.14,
                m=rp.choice(['iron', 'rust']), inv='patches')

    # ---------------- bow: dishes, claws, deck boxes ----------------
    K.box('A16_dish_plinth', 9.0, 10.4, -2.1, 2.1, 1.75, 2.0, 'steel', ch=0.08)
    K.dish('D1', (9.75, 1.15, 2.0), 0.92, yaw=8, pitch=12, post=1.2, inv='dishes', note='port listening dish')
    K.dish('D2', (9.75, -1.15, 2.0), 0.92, yaw=-8, pitch=12, post=1.2, inv='dishes', note='starboard listening dish')
    for side, fid in ((1, 'H1'), (-1, 'H2')):
        y = 1.45 * side
        K.claw(fid, (9.9, y, -3.1), [(10.7, y, -3.95), (11.4, y, -4.8), (11.45, y, -5.45)], w=0.95, fingers=3, inv='bow_claws',
               housing=(8.6, 10.6, y - 0.55, y + 0.55, -3.3, -2.4),
               note='%s boarding claw, hinged, swings forward to grip' % ('port' if side > 0 else 'starboard'))
    for side, fid in ((1, 'H3'), (-1, 'H4')):
        y = 2.2 * side
        K.claw(fid, (-0.9, y, -3.42), [(-0.2, y, -4.1), (0.35, y, -4.55), (0.25, y, -5.0)], w=0.62, fingers=3, src='designed', inv='grapples',
               housing=(-2.4, -0.4, y - 0.45, y + 0.45, -3.45, -2.95),
               note='grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath)')
    K.hatchbox('HB1', (8.0, 2.0, 1.8), 0.9, 1.1, 0.32, inv='bow_hatchboxes', note='framed deck box, port')
    K.hatchbox('HB2', (8.2, -2.2, 1.8), 0.8, 0.9, 0.3, inv='bow_hatchboxes', note='framed deck box, starboard (smaller)')

    # ---------------- chains: real links, taut ----------------
    K.chain('C1', [(7.3, 3.85, 0.6), (7.3, 3.0, 1.98), (7.3, -3.05, 1.98), (7.3, -4.0, 0.6)], inv='mid_chain', note='girdle over the tier 2 seam')
    K.chain('C2', [(-1.75, 4.62, 0.4), (-1.75, 3.62, 2.66), (-1.75, -3.72, 2.66), (-1.75, -4.82, 0.4)],
            inv='stern_chain', note='girdle over the castle seam, at the foot of the castle front')
    K.chain('C3', [(8.4, 4.05, -0.3), (4.0, 4.5, -0.36), (-1.4, 4.6, -0.36)], inv='bow_chain', note='port flank lashing along the belt top')
    K.chain('C4', [(6.4, -4.2, -0.3), (2.0, -4.65, -0.36), (-0.6, -4.72, -0.36)], inv='bow_chain', note='starboard flank lashing, shorter (junky, unmatched)')

    # ---------------- weapons, by data.js slot ----------------
    # F (htorp): the heavy rack on its plinth, pitched to fire clear over the deck boxes and the dishes
    K.launcher('R1', (2.55, 0.0, 3.25), 2, 5, cell=0.5, depth=2.4, pitch=12, slot='F', weapon='htorp', inv='rack',
               note='heavy rocket rack, 10 cells, magazine below')
    K.hatchbox('HB3', (4.75, 1.15, 2.65), 1.2, 1.3, 0.3, fins=2, inv='armour_vent', note='armoured vent housing with two slanted blades')
    # T (flak): superfiring pair on the castle front and the bridge barbette
    K.gun('T1', (-2.95, 0.0, 3.45), 0, 10, barrels=2, cal=0.14, blen=1.75, size=1.3, slot='T', weapon='flak', inv='top_turret',
          note='castle flak turret, fires over the rack at 10 degrees and up')
    K.gun('T2', (-6.65, 0.0, 4.4), 0, 30, barrels=2, cal=0.16, blen=1.85, size=1.45, slot='T', weapon='flak', inv='top_turret', variant=1,
          note='bridge barbette flak turret, superfiring over T1, rests at 30 degrees')
    # P and S (scatter): matched broadside batteries
    for side, sl in ((1, 'P'), (-1, 'S')):
        K.gun('%sB' % sl, (9.4, max(sy(9.0, side), sy(9.8, side), key=abs) + 0.02 * side, -0.05), side * 20, 0, barrels=1, cal=0.2, blen=1.8, size=1.15, normal=(0, side, 0),
              slot=sl, weapon='scatter', inv='bow_casemates', note='bow casemate, trained forward')
        # the middle deck-edge turret superfires on a barbette so neighbours never meet when trained (R219 sweep)
        K.box('A16_barbette_%s2' % sl, 2.05, 3.55, min(side * 1.95, side * 3.45), max(side * 1.95, side * 3.45), 2.5, 3.45, 'iron', ch=0.2,
              plates=dict(PL, seed=80 + side, faces=[0, 2, 3], size=(0.4, 0.8)))
        for i, (x, z) in enumerate(((6.3, 2.65), (2.8, 3.45))):
            K.gun('%s%d' % (sl, i + 1), (x, side * 2.72, z), side * (15 + 5 * i), 2, barrels=2, cal=0.14, blen=2.2, size=1.3, variant=i,
                  slot=sl, weapon='scatter', inv='bow_guns', note='deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring)')
        K.gun('%s3' % sl, (-0.7, side * 2.72, 2.65), side * 25, 2, barrels=2, cal=0.14, blen=2.2, size=1.3, variant=1,
              slot=sl, weapon='scatter', inv='mid_guns', note='deck-edge twin turret, tier 2, aft')
        K.gun('%sM' % sl, (0.9, sy(0.9, side) + 0.02 * side, 0.32), side * 35, 0, barrels=2, cal=0.13, blen=1.8, size=1.1, normal=(0, side, 0),
              slot=sl, weapon='scatter', inv='mid_casemates', note='flank twin casemate amidships')
        for i, x in enumerate((-3.75, -5.8)):
            K.gun('%s%d' % (sl, i + 4), (x, side * 4.45, 1.0), side * 30, 0, barrels=2, cal=0.13, blen=1.9, size=1.1, variant=i,
                  normal=(0, side, 0), slot=sl, weapon='scatter', inv='stern_casemates', note='sponson twin casemate under the castle')

    # ---------------- engines: a centre main, two main pods (port the larger), lower boosters, an upper pod ----------------
    K.engine('E0', (-12.95, 0.0, -0.1), 1.3, 1.7, bell=1.15, inv='main_engine', note='centre main engine, its housing sunk in the stern')
    for side, fid, r in ((1, 'E1', 1.5), (-1, 'E2', 1.3)):
        y = 4.35 * side
        K.box('A16_%s_pylon' % fid, -10.4, -8.2, min(y, side * 2.3), max(y, side * 2.3), -0.5, 1.0, 'steel', ch=0.15,
              plates=dict(PL, seed=70 + side, faces=[0, 1, 2, 3], size=(0.5, 1.0)))
        K.engine(fid, (-12.4, y, 0.3), r, 3.0, bell=1.2, src='picture' if side > 0 else 'designed', inv='main_engine',
                 note='%s main pod%s' % ('port' if side > 0 else 'starboard', ', the large one' if side > 0 else ', smaller (mismatched)'))
    K.mark('pylons', 'pylon', ['web', 'plate'])
    for side, fid in ((1, 'E3'), (-1, 'E4')):
        K.engine(fid, (-12.1, 1.65 * side, -2.25), 0.5, 1.6, bell=1.25, src='picture' if side > 0 else 'designed', inv='boosters',
                 note='lower booster')
    K.engine('E5', (-11.3, -1.3, 2.85), 0.55, 1.9, bell=1.2, inv='upper_pod', note='upper starboard pod on the stern deck')
    K.box('A16_E5_saddle', -10.0, -8.6, -1.9, -0.7, 2.15, 2.5, 'iron', ch=0.08)
    # attitude thrusters: bow quads on the brow flanks, stern quads on the castle's aft corners (clear of every pod)
    for i, (x, y, z, n) in enumerate([(11.0, 3.0, 1.45, (0, 1, 0)), (11.0, -3.05, 1.45, (0, -1, 0)),
                                      (-7.35, 2.87, 2.95, (0, 1, 0)), (-7.35, -2.97, 2.95, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, inv='bow_thrusters' if x > 0 else 'stern_thrusters', note='bow' if x > 0 else 'stern')
    # pipe runs on the stern flanks to the pods, antenna arrays on the spine
    for side in (1, -1):
        x0, x1 = -6.9, -8.6
        K.pipe('PP%d' % (1 if side > 0 else 2), [(-7.3, side * 2.72, 2.27), (-9.0, side * 2.72, 2.27), (-9.0, side * 2.72, 1.02)],
               r=0.09, inv='stern_pipes')
    K.antenna('AN1', (-9.75, 1.25, 2.2), 2.0, whips=3, inv='antennas', note='antenna array on the stern deck, port')
    K.antenna('AN2', (-8.9, -0.15, 2.2), 1.6, whips=2, inv='antennas', note='antenna array on the stern deck, centre')

    # ---------------- flank vents, lamps, belly bay ----------------
    for side in (1, -1):
        for i, x in enumerate((6.35, 2.6, -1.95)):
            K.vent('VF%d%s' % (i, 'p' if side > 0 else 's'), (x, max(sy(x - 0.55, side), sy(x + 0.55, side), key=abs) + 0.01 * side, 0.22), (0, side, 0),
                   1.0, 0.55, slats=5, inv='flank_vents')
        for i, x in enumerate((8.5, 5.0, 1.5, -2.2, -5.4)):
            K.lamp('L%d%s' % (i, 'p' if side > 0 else 's'), (x, sy(x, side) + 0.02 * side, -1.62), (0, side, 0), inv='lamps')
        K.lamp('LC%s' % ('p' if side > 0 else 's'), (-3.3, cy(-3.3, side) + 0.01 * side, 3.1), (0, side, 0), inv='lamps')
        K.lamp('LD%s' % ('p' if side > 0 else 's'), (-6.75, cy(-6.75, side) + 0.01 * side, 2.6), (0, side, 0), inv='lamps')
    K.bay('B1', (-2.25, 0.0, -3.05), 3.2, 3.4, inv='bay', note='data.js hangar 2: squadrons drop from the belly')

    # ---------- colour zones ----------
    K.colour('soot black base plate', 13.0, -13.0, 'whole hull', 'patched, worn; dim red running lights')
    K.colour('rust plate (tier 2, brow step)', 11.5, -2.6, 'raised armoured deck and the brow')
    K.colour('violet Eclipse trophy plate', 5.9, 4.4, 'tier 2 deck, starboard')
    K.colour('violet Eclipse trophy plate', 5.7, 4.2, 'port flank')
    K.colour('pale Hegemony grey trophy plates', 2.6, -0.6, 'port flank, under the belt')
    K.colour('dried-blood red band', -2.15, -2.95, 'castle front')

    # ---------- INSIDE ----------
    K.deck('lower', -1.55, -10.0, 10.6)
    K.deck('main', 0.1, -10.2, 11.0)
    K.deck_box('gun', 1.95, -2.4, 6.6, 2.9)
    K.deck_box('castle', 2.75, -7.6, -2.6, 2.6)
    for i, x in enumerate((11.0, 8.0, 4.8, 0.8, -2.6, -6.4, -9.0)):
        K.bulkhead('F%d' % i, x)
    K.room('tube_ducts', 'machinery', 10.7, 11.6, -2.0, 2.0, -1.0, 0.7, note='front tube ducts and sniffer gear')
    K.room('claw_machinery', 'machinery', 8.1, 10.6, -2.6, 2.6, -2.4, -1.65, note='claw rams and winches')
    K.room('kennel_decks', 'crew', 4.9, 10.6, -3.0, 3.0, -1.45, 1.6, note='boarding gangs, two decks')
    K.room('rocket_magazine', 'magazine', -0.4, 4.7, -1.6, 1.6, 0.2, 1.85, note='under the rocket rack')
    K.room('loot_hold', 'hold', 0.9, 4.7, -3.2, 3.2, -2.6, -1.65, note='loot holds')
    K.room('hangar', 'hangar', -4.2, 0.7, -2.6, 2.6, -2.7, 0.0, note='two squadrons, belly drop')
    K.room('core', 'core', -6.3, -4.3, -1.3, 1.3, -2.6, 0.0, note='reactor core (hp_core)')
    K.room('shell_magazine_p', 'magazine', -6.3, -2.7, 1.6, 3.3, 0.2, 1.8, note='port battery magazine')
    K.room('shell_magazine_s', 'magazine', -6.3, -2.7, -3.3, -1.6, 0.2, 1.8, note='starboard battery magazine')
    K.room('gun_deck', 'crew', -2.5, 6.4, -2.6, 2.6, 2.0, 2.5, note='turret crews and hoists')
    K.room('warlord_hall', 'crew', -7.5, -2.7, -2.4, 2.4, 2.8, 3.3, note='the warlord hall')
    K.room('bridge', 'bridge', -7.1, -4.6, -1.4, 1.4, 3.4, 3.9, note='command deck')
    K.room('engine_room', 'engroom', -10.2, -6.5, -2.0, 2.0, -2.1, 1.6, note='engine room and pod feeds')
    K.armour('ram bow (forward of 11.0)', 0.6, 'stacked scrap plating in the brow and chin, around the tube ducts')
    K.armour('flank belt (lower and main decks)', 0.4, 'patch plates over the base hull')
    K.armour('tier 2 and castle roof', 0.3, '')
    K.armour('belly', 0.35, 'flat armoured belly with chines')
    K.armour('engine end', 0.2, 'thinnest: the soft spot')
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
    K.point('rcs', 'hp_rcs_0', (11.0, 3.0, 1.45), side='port')
    K.point('rcs', 'hp_rcs_1', (11.0, -3.05, 1.45), side='stbd')
    K.point('board', 'hp_board_0', (2.0, 4.3, -1.0), side='port')
    K.point('board', 'hp_board_1', (2.0, -4.5, -1.0), side='stbd')
    K.point('bay', 'hp_bay_0', (-2.25, 0, -3.15), note='launch down')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Front tubes built as deep tubes with hooded rolled lips, dark bores and clamp bands, under a stepped brow', 'Ryan R217: "the tubes at the front ... are just circles on the actual build"')
    K.change('Rack raised on a plinth and pitched 12 degrees; no turret in front of it', 'Ryan R217: "the guns are visibly blocking the rockets"; the fit check proves every cell fires clear over the bow')
    K.change('Flak superfires from the castle front (T1) and a bridge barbette (T2)', 'the round 2 bunker turret sat in the rack\'s line of fire; the picture puts its top turret on the castle')
    K.change('Guns laid out as matched port and starboard batteries by game slot', 'the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are mirrored: a bow casemate, three deck-edge twin turrets, a flank casemate amidships and two sponson casemates per side')
    K.change('Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block', 'one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof')
    K.change('Roof turrets rest facing forward', 'the picture draws its barrel aft; no gun faces aft')
    K.change('The mid-length starboard engine pod becomes an upper pod on the stern deck', 'a pod at mid-length glowing forward would push the ship backward and burn its own deck')
    K.change('Two main engine pods, port larger, plus a centre main and lower boosters', 'the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells')
    K.change('Attitude thrusters moved off the casemates and pods', 'the fit check found the round 2 bow quads firing into the bow casemates and the stern quads into the pods')
    K.change('Chains are taut girdles and flank lashings of real links', 'a slack chain cannot sag in space (R185); the girdles sit on the break lines')
    K.change('Bow claws hinged in their own housings; two grapple arms added under the belly', 'the picture hooks hang from nothing; the round 8 side sheet and Ryan (R196) put hooks underneath')
    K.change('Ventral launch bay and four attitude thruster quads added', 'data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.open_item('Belly detail between the claws and the bay is designed here; the picture does not show it')
    K.open_item('The notch in each tube\'s lower lip is left for the build\'s kit pass')

    # ---------- the fit report's fix column: round 2 clashes and how round 3 fixed them ----------
    K.fix('R1 launch cells covered by T1 (the bunker turret in front of the rack)', 'bunker turret removed; flak moved to the castle front (T1) and a bridge barbette (T2); the rack raised on a plinth and pitched 12 degrees')
    K.fix('Q1 and Q2 exhaust into the bow casemates PB and SB', 'bow quads moved up onto the brow flanks; casemates moved aft to 9.55')
    K.fix('Q3 and Q4 exhaust into the pods E1 and E2 and their pylons', 'stern quads moved to the castle\'s aft corners, above the pods')
    K.fix('E3 and E4 exhaust into the hull and the E0 housing', 'boosters moved below and aft of the stern end, exits at -12.1')
    K.fix('E0 had no mount on the hull', 'its housing now runs forward into the stern (a mount piece)')
    K.fix('Claw blades H1 to H4 inside their hull housings', 'each housing is now the claw\'s own mount, the hinge drum in it, the blades clear of the hull')
    K.fix('Tube bores I1 and I2 inside the prow', 'a sunk tube is a mount by design: its bore runs back into the prow; the mouth must be clear (EXIT check)')
    K.fix('Casemate housings P4, P5, S4, S5, SB inside hull masses', 'casemates set onto the sponson outer faces and the bow flank surface, plates cleared under each mount')
    K.fix('Dish posts D1 and D2 inside the plinth', 'dishes stand on the plinth top on their own base plates')


def bpy_obj(name):
    import bpy
    return bpy.data.objects[name]
