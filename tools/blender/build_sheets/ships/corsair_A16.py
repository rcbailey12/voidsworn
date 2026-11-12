# corsair_A16 round 3: the Warlord's Pyre-Barge (Ashfall Hullbreakers flagship, class Battle-barge, 26 world units).
# Accepted picture: contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (R201), from round 1 Scrap Brick
# (concept_directions_2026_11/corsair_A.jpg, R197). data.js c_boss: scatter P, scatter S, htorp F, flak T, hangar 2.
# Round 3 (Ryan, Nov 11 21:24 and 21:34 CST, R217 and R218): the parts inventory comes first (corsair_A16_inv.py, every line
# carried by an `inv=` below); every part is a real kit shape (tools/blender/kits/hullbreakers/parts.py); the prow is a
# shaped cap with a stepped brow over a deep tube cluster; the guns, rack, engines and thrusters are laid out so the fit
# check (clash.py) passes: the round 2 turret in front of the rack is gone, the flak superfires from the castle and bridge.
# Round 3b (the Board on round 3: the massing did not match; RULEBOOK 5.7 structure first). Measured off the round 8 sheet's true
# side and top views: hull length to beam about 3.0 and length to height about 4.45 (median over the middle 60 percent), the bow
# tapering from about 4.3 wide at the tube cluster to about 8 by a quarter of the length, a slab about 4 deep with tier 2 and the
# castle as low steps (the whole ship about 5.7 tall), the flank in layered belts (an upper armour belt, a recessed band of lights
# and vents, a lower belt), the engine pods close in, a curved pincer under the bow tip, short grabbers under the stern.
# +X bow, +Y port, +Z up. Hooded tube lips reach about x = +13.0; centre engine exit x = -12.95; flat belly z = -2.6.
CODE = 'corsair_A16'
NAME = "Warlord's Pyre-Barge"
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Battle-barge'
LENGTH = 26.0
GAME = "data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg'

# tier 1, the hull: (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer)
# the bow tapers in plan (about 4.3 wide at the tube cluster, 0.16 of the length; 6 at 1/12; 7.8 at 3/12) and is rounded by heavy
# chamfers; the slab is about 4 deep; the stern body narrows between the engine pods
HULL = [
    (11.75, 2.1, 2.15, -1.4, 0.9, 0.95, 0.85),
    (11.2, 2.6, 2.65, -1.95, 1.15, 1.0, 0.95),
    (10.3, 2.75, 2.8, -2.3, 1.3, 0.85, 0.9),
    (8.6, 3.25, 3.3, -2.55, 1.4, 0.9, 0.95),
    (6.0, 3.65, 3.75, -2.6, 1.4, 0.9, 1.0),
    (0.0, 3.85, 3.95, -2.6, 1.4, 0.9, 1.0),
    (-4.0, 3.8, 3.9, -2.6, 1.4, 0.9, 1.0),
    (-6.4, 3.3, 3.35, -2.45, 1.4, 0.85, 0.9),
    (-8.0, 2.75, 2.8, -2.2, 1.35, 0.7, 0.8),
    (-10.4, 2.4, 2.4, -1.9, 1.3, 0.6, 0.7),
    (-11.2, 1.9, 1.9, -1.4, 1.0, 0.5, 0.5),
]
PL = dict(size=(0.45, 1.2), thick=(0.05, 0.18), skip=0.1, stack=0.45, mats={'soot': 7, 'soot2': 5, 'rust': 3, 'iron': 2, 'blood': 1})
BELT_UP = (0.1, 0.9, 0.24)     # the upper armour belt: bottom, top, standing out from the hull side
BELT_LO = (-1.6, -0.7, 0.34)   # the lower belt; between them the recessed band (lights, vents, bow casemates)
RECESS_Z = -0.3


def build(K):
    import kit as _k
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Hull slab (tier 1)', K.hull(HULL, 'soot', shell=0.35, plates=dict(PL, seed=16, inv=['bow_plates', 'belly_plates']), rounded=True),
           'soot black, patched plate', note='a rounded wedge in section (round flanks and belly, a flatter deck), the bow tapering to a broad rounded nose')
    sf = lambda x, side, z: K.surf(x, side, z)  # noqa: E731
    # ---------------- the layered flank: upper belt, recessed band, lower belt (the concept's stepped belts) ----------------
    for nm, (zb, zt, out), x0, x1 in (('upper', BELT_UP, 10.0, -6.2), ('lower', BELT_LO, 9.2, -5.6)):
        secs = []
        for x in (x0, (x0 * 2 + x1) / 3, (x0 + x1 * 2) / 3, x1):
            h = _k.sec_at(HULL, x)
            secs.append((x, h[1] + out, h[2] + out, zb, zt, 0.12, 0.12))
        K.mass('%s armour belt' % nm.capitalize(), K.loft('A16_belt_%s' % nm, secs, 'iron' if nm == 'upper' else 'soot2',
                                                          plates=dict(PL, seed=91 if nm == 'upper' else 92, faces=[6, 7, 0, 2, 3, 4], size=(0.4, 0.9))),
               'iron and soot', note='layered flank belt, standing %.2f out' % out)
    K.mark('belt', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    belt_y = lambda x, side, which: sy(x, side) + side * (BELT_UP if which == 'up' else BELT_LO)[2]  # noqa: E731

    # ---------------- the prow: two big tubes are the face, a stepped brow over them, a chin under ----------------
    K.mass('Prow brow (two steps)', K.loft('A16_brow', [
        (11.75, 2.05, 2.05, 0.95, 1.2, 0.3, 0.1), (11.45, 2.4, 2.4, 0.9, 1.38, 0.45, 0.12), (10.6, 2.8, 2.85, 0.85, 1.5, 0.6, 0.15)],
        'soot', plates=dict(PL, seed=17, faces=[0, 1, 2, 3], size=(0.45, 1.0), inv='bow_plates')), 'soot', note='overhangs the tube mouths')
    K.mass('Brow step', K.loft('A16_brow_step', [(11.1, 2.2, 2.25, 1.3, 1.75, 0.35, 0), (9.95, 2.55, 2.6, 1.3, 1.82, 0.4, 0)], 'rust',
                               plates=dict(PL, seed=18, faces=[0, 1, 2, 3], size=(0.45, 0.9), inv='bow_plates')), 'rust', note='the second brow step')
    K.mass('Chin', K.loft('A16_chin', [(11.7, 2.0, 2.0, -1.95, -1.45, 0.1, 0.4), (10.8, 2.6, 2.65, -2.3, -1.35, 0.1, 0.5)], 'iron'), 'iron',
           note='under the tubes, carries the pincers')
    K.mark('prow', 'hull', ['bevel', 'step', 'overhang'])
    for side, fid in ((1, 'I1'), (-1, 'I2')):
        K.tube(fid, (12.62, 1.35 * side, -0.25), 0.95, 2.6, hood=0.4, bands=3, inv='ftubes', what='front tube (wake-sniffer scoop)',
               note='%s front tube: the ship\'s face; deep bore, hooded rolled lip, clamp bands' % ('port' if side > 0 else 'starboard'))
    K.box('A16_spine_block', 10.9, 12.0, -0.17, 0.17, -1.1, 0.65, 'soot', ch=0.04)
    K.vent('V0', (12.0, 0.0, -0.25), (1, 0, 0), 0.3, 1.5, slats=7, inv='ftube_spine', note='ribbed spine between the tubes')

    # ---------------- tier 2: a low raised deck (0.6), a sloped, stepped front at 7.0 ----------------
    T2 = [(7.0, 2.4, 2.5, 1.2, 1.55, 0.3, 0), (6.4, 3.05, 3.2, 1.2, 2.0, 0.42, 0), (0.0, 3.3, 3.45, 1.2, 2.0, 0.45, 0),
          (-2.6, 3.2, 3.35, 1.2, 2.0, 0.45, 0)]
    K.mass('Raised armoured deck (tier 2)', K.loft('A16_tier2', T2, 'rust', plates=dict(PL, seed=26, faces=[0, 1, 2, 3], inv='bow_plates')),
           'rust plate', note='a low step over the forward two thirds')
    for side in (1, -1):
        K.slit('SL%d' % (1 if side > 0 else 2), (6.72, 1.3 * side, 1.75), (0.8, 0, 0.6), 0.9, 0.14, inv='tier2', note='vision slit in the tier 2 front')
    K.mark('tier2', 'tier', ['face', 'roof', 'opening'])
    K.mass('Rack plinth', K.loft('A16_plinth', [(3.0, 1.2, 1.2, 1.9, 2.15, 0.2, 0), (2.6, 1.65, 1.65, 1.9, 2.45, 0.25, 0),
                                                (-0.2, 1.65, 1.65, 1.9, 2.45, 0.25, 0)], 'soot', plates=dict(PL, seed=27, faces=[0, 1, 2, 3], size=(0.45, 0.9))),
           'soot', note='lifts the rack so it fires clear over the bow')

    # ---------------- castle (tier 3, a low step), bridge, barbette ----------------
    CA = [(-2.2, 2.55, 2.65, 1.3, 2.05, 0.3, 0), (-2.85, 3.0, 3.1, 1.3, 2.6, 0.45, 0), (-7.0, 2.9, 3.0, 1.3, 2.6, 0.45, 0), (-7.8, 2.5, 2.6, 1.3, 2.25, 0.35, 0)]
    K.mass('Castle (tier 3)', K.loft('A16_castle', CA, 'soot', plates=dict(PL, seed=36, faces=[0, 1, 2, 3], inv='bow_plates')),
           'soot with a dried-blood band')
    K.mass('Bridge block', K.loft('A16_bridge', [(-4.5, 1.5, 1.5, 2.5, 2.92, 0.22, 0), (-4.85, 1.75, 1.75, 2.5, 3.0, 0.25, 0),
                                                 (-7.25, 1.85, 1.85, 2.5, 3.0, 0.28, 0)], 'soot'), 'soot', note='command deck on the castle roof')
    for side in (1, -1):
        K.slit('SL3%s' % ('p' if side > 0 else 's'), (-5.9, 1.83 * side, 2.78), (0, side, 0), 1.4, 0.13, inv='bridge', note='bridge flank vision slit')
    K.mark('bridge', 'tier', ['face', 'roof', 'opening'])
    K.loft('A16_redband', [(-2.15, 2.6, 2.7, 1.28, 2.1, 0.3, 0), (-2.9, 3.05, 3.15, 1.28, 2.65, 0.47, 0)], 'blood')
    cy = lambda x, side: _k.sec_at(CA, x)[1 if side > 0 else 2] * side  # noqa: E731
    for side in (1, -1):
        K.slit('SL%d' % (4 if side > 0 else 5), (-4.6, cy(-4.6, side), 2.2), (0, side, 0), 0.9, 0.14, inv='castle', note='castle flank slit')
        K.hatch('HC%d' % (1 if side > 0 else 2), (-5.95, cy(-5.95, side), 1.95), (0, side, 0), 0.5, 0.6, inv='castle_hatches', note='castle flank hatch')
    K.mark('castle', 'tier', ['face', 'roof', 'opening'])
    K.box('A16_barbette', -7.2, -6.1, -0.75, 0.75, 2.95, 3.25, 'iron', ch=0.12)
    K.mass('Stern deck', K.box('A16_aftdeck', -10.2, -7.7, -2.0, 2.0, 1.2, 1.7, 'steel', ch=0.18, plates=dict(PL, seed=46, faces=[1], size=(0.45, 0.9))),
           'steel', note='carries the upper pod and the round hatch')
    K.hatch('HR', (-8.6, 1.0, 1.7), (0, 0, 1), 0.7, round_=True, inv='round_hatch', note='round hatch with a hand wheel')
    for side, sn in ((1, 'p'), (-1, 's')):
        K.mass('Sponson %s' % ('port' if side > 0 else 'starboard'), K.box('A16_sponson_%s' % sn, -6.6, -2.9, min(side * 2.9, side * 4.3), max(side * 2.9, side * 4.3),
                                                                          -0.55, 1.2, 'soot', ch=0.22,
                                                                          plates=dict(PL, seed=60 + side, faces=[0, 1, 2, 3, 4, 5, 6, 7], size=(0.45, 1.0))),
               'soot', note='flank sponson under the castle')
    for i, x in enumerate((8.3, 5.0, -1.2)):
        for side in (1, -1):
            y = sf(x, side, -0.3) + 0.08 * side
            K.rib('RB%d%s' % (i, 'p' if side > 0 else 's'), [(x, y, -0.68), (x, y, 0.08)], w=0.2, inv='flank_ribs')

    # trophy plates on the belts, torn patches
    K.loft('A16_violet_fd', [(5.9, -1.7, 3.0, 1.98, 2.08, 0, 0), (4.4, -1.7, 3.0, 1.98, 2.08, 0, 0)], 'violet')
    K.loft('A16_violet_flank', [(5.7, 4.08, -3.75, 0.2, 0.8, 0, 0), (4.2, 4.12, -3.8, 0.2, 0.8, 0, 0)], 'violet')
    K.mark('bow_trophy', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    K.loft('A16_pale_flank', [(2.6, 4.22, -3.9, -1.5, -0.8, 0, 0), (-0.6, 4.3, -3.9, -1.5, -0.8, 0, 0)], 'pale')
    K.mark('pale_plates', 'plate', ['slab', 'step', 'bevel', 'rivet'])
    import random
    rp = random.Random(1616)
    for i, (x, z, side) in enumerate([(3.5, 0.5, 1), (-0.6, 0.45, 1), (3.3, 0.5, -1), (-0.8, 0.5, -1)]):
        K.patch('PT%d' % i, (x, belt_y(x, side, 'up') + 0.02 * side, z), (0, side, 0), rp.uniform(0.6, 0.85), rp.uniform(0.4, 0.55), ang=rp.uniform(-0.3, 0.3),
                lift=rp.uniform(0.08, 0.16), m=rp.choice(['iron', 'pale', 'rust']), inv='patches')
    for i, (x, side) in enumerate([(2.2, 1), (-1.9, 1), (2.0, -1), (-1.6, -1)]):
        K.patch('PT%d' % (4 + i), (x, sf(x, side, 1.12) + 0.02 * side, 1.12), K.surf_n(x, side, 1.12), rp.uniform(0.8, 1.0), 0.5, ang=0.2 * side, lift=0.13,
                m=rp.choice(['iron', 'rust']), inv='patches')

    # ---------------- bow fittings: dishes, the pincers under the tip, deck boxes ----------------
    K.box('A16_dish_plinth', 8.55, 9.75, -2.1, 2.1, 1.3, 1.52, 'steel', ch=0.08)
    K.dish('D1', (9.15, 1.15, 1.52), 0.92, yaw=8, pitch=12, post=1.2, inv='dishes', note='port listening dish')
    K.dish('D2', (9.15, -1.15, 1.52), 0.92, yaw=-8, pitch=12, post=1.2, inv='dishes', note='starboard listening dish')
    for side, fid in ((1, 'H1'), (-1, 'H2')):
        y = 1.25 * side
        K.claw(fid, (10.7, y, -2.8), [(11.35, y, -3.4), (11.95, y * 0.95, -3.6), (12.35, y * 0.85, -3.25)], w=0.75, fingers=2, inv='bow_claws',
               housing=(10.0, 11.3, y - 0.42, y + 0.42, -3.0, -2.08),
               note='%s pincer: a curved mandible under the bow tip, hooking forward' % ('port' if side > 0 else 'starboard'))
    for side, fid, x in ((1, 'H3', -6.0), (-1, 'H4', -8.3)):
        y = 1.3 * side
        K.claw(fid, (x, y, -2.85), [(x + 0.45, y, -3.3), (x + 0.6, y, -3.7)], w=0.5, fingers=3, src='picture', inv='grapples',
               housing=(x - 0.6, x + 0.45, y - 0.36, y + 0.36, -3.02, -2.15),
               note='short grabber under the stern (round 8 side sheet: grabbers under the stern; Ryan R196: hooks underneath)')
    K.hatchbox('HB1', (7.95, 1.8, K.deck_z(7.95, 2.25)), 0.9, 0.9, 0.3, inv='bow_hatchboxes', note='framed deck box, port')
    K.hatchbox('HB2', (7.95, -1.9, K.deck_z(7.95, -2.3)), 0.8, 0.8, 0.28, inv='bow_hatchboxes', note='framed deck box, starboard (smaller)')

    # ---------------- chains: real links, taut ----------------
    K.chain('C1', [(7.3, 3.95, 0.95), (7.3, 3.0, 1.45), (7.3, -3.05, 1.45), (7.3, -4.05, 0.95)], inv='mid_chain', note='girdle over the tier 2 seam')
    K.chain('C2', [(-1.75, 4.15, 0.95), (-1.75, 3.5, 2.05), (-1.75, -3.6, 2.05), (-1.75, -4.25, 0.95)], inv='stern_chain',
            note='girdle over the castle seam, at the foot of the castle front')
    K.chain('C3', [(7.95, belt_y(7.95, 1, 'lo') - 0.05, -0.62), (4.0, belt_y(4.0, 1, 'lo') - 0.05, -0.64), (-1.4, belt_y(-1.4, 1, 'lo') - 0.05, -0.64)],
            inv='bow_chain', note='port flank lashing along the lower belt top')
    K.chain('C4', [(6.4, belt_y(6.4, -1, 'lo') + 0.05, -0.62), (2.0, belt_y(2.0, -1, 'lo') + 0.05, -0.64), (-0.6, belt_y(-0.6, -1, 'lo') + 0.05, -0.64)],
            inv='bow_chain', note='starboard flank lashing, shorter (junky, unmatched)')

    # ---------------- weapons, by data.js slot ----------------
    K.launcher('R1', (2.55, 0.0, 2.45), 2, 5, cell=0.5, depth=2.4, pitch=10, slot='F', weapon='htorp', inv='rack',
               note='heavy rocket rack, 10 cells, magazine below')
    K.hatchbox('HB3', (4.75, 1.15, 2.0), 1.2, 1.3, 0.28, fins=2, inv='armour_vent', note='armoured vent housing with two slanted blades')
    K.gun('T1', (-2.95, 0.0, 2.6), 0, 10, barrels=2, cal=0.14, blen=1.75, size=1.3, slot='T', weapon='flak', inv='top_turret',
          note='castle flak turret, fires over the rack at 10 degrees and up')
    K.gun('T2', (-6.65, 0.0, 3.25), 0, 30, barrels=2, cal=0.16, blen=1.85, size=1.45, slot='T', weapon='flak', inv='top_turret', variant=1,
          note='bridge barbette flak turret, superfiring over T1, rests at 30 degrees')
    for side, sl in ((1, 'P'), (-1, 'S')):
        K.gun('%sB' % sl, (9.0, max(sf(8.6, side, RECESS_Z), sf(9.4, side, RECESS_Z), key=abs) + 0.02 * side, RECESS_Z), side * 20, 0, barrels=1, cal=0.18, blen=1.7, size=1.05,
              normal=(0, side, 0), slot=sl, weapon='scatter', inv='bow_casemates', note='bow casemate in the recessed band, trained forward')
        K.box('A16_barbette_%s2' % sl, 2.05, 3.55, min(side * 1.95, side * 3.45), max(side * 1.95, side * 3.45), 1.9, 2.75, 'iron', ch=0.2,
              plates=dict(PL, seed=80 + side, faces=[0, 2, 3], size=(0.4, 0.8)))
        for i, (x, z) in enumerate(((6.3, 2.0), (2.8, 2.75))):
            K.gun('%s%d' % (sl, i + 1), (x, side * 2.72, z), side * (15 + 5 * i), 2, barrels=2, cal=0.14, blen=2.2, size=1.3, variant=i,
                  slot=sl, weapon='scatter', inv='bow_guns', note='deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring)')
        K.gun('%s3' % sl, (-0.7, side * 2.72, 2.0), side * 25, 2, barrels=2, cal=0.14, blen=2.2, size=1.3, variant=1,
              slot=sl, weapon='scatter', inv='mid_guns', note='deck-edge twin turret, tier 2, aft')
        K.gun('%sM' % sl, (0.9, belt_y(0.9, side, 'up') + 0.02 * side, 0.5), side * 35, 0, barrels=2, cal=0.12, blen=1.7, size=1.0, normal=(0, side, 0),
              slot=sl, weapon='scatter', inv='mid_casemates', note='flank twin casemate on the upper belt amidships')
        for i, x in enumerate((-3.75, -5.8)):
            K.gun('%s%d' % (sl, i + 4), (x, side * 4.3, 0.35), side * 30, 0, barrels=2, cal=0.13, blen=1.9, size=1.1, variant=i,
                  normal=(0, side, 0), slot=sl, weapon='scatter', inv='stern_casemates', note='sponson twin casemate under the castle')

    # ---------------- engines: a centre main, two pods close in (port the larger), lower boosters, an upper pod ----------------
    K.engine('E0', (-12.95, 0.0, -0.35), 1.15, 1.7, bell=1.15, inv='main_engine', note='centre main engine, its housing sunk in the stern')
    for side, fid, r in ((1, 'E1', 1.05), (-1, 'E2', 0.9)):
        y = 3.6 * side
        K.mass('Pod pylon %s' % ('port' if side > 0 else 'starboard'),
               K.box('A16_%s_pylon' % fid, -10.4, -8.2, min(y, side * 2.3), max(y, side * 2.3), -0.1, 0.95, 'steel', ch=0.15,
                     plates=dict(PL, seed=70 + side, faces=[0, 1, 2, 3], size=(0.45, 0.9))), 'steel', note='pod pylon, stepped web with plates')
        K.engine(fid, (-12.4, y, 0.45), r, 2.6, bell=1.2, src='picture' if side > 0 else 'designed', inv='main_engine',
                 note='%s main pod%s' % ('port' if side > 0 else 'starboard', ', the large one' if side > 0 else ', smaller (mismatched)'))
    K.mark('pylons', 'pylon', ['web', 'plate'])
    for side, fid in ((1, 'E3'), (-1, 'E4')):
        K.engine(fid, (-12.1, 1.55 * side, -1.85), 0.45, 1.6, bell=1.25, src='picture' if side > 0 else 'designed', inv='boosters', note='lower booster')
    K.engine('E5', (-11.3, -1.2, 2.18), 0.48, 1.9, bell=1.2, inv='upper_pod', note='upper starboard pod on the stern deck')
    K.box('A16_E5_saddle', -10.0, -8.6, -1.75, -0.65, 1.6, 1.9, 'iron', ch=0.08)
    for i, (x, y, z, n) in enumerate([(10.45, sf(10.45, 1, 0.45), 0.45, K.surf_n(10.45, 1, 0.45)), (10.45, sf(10.45, -1, 0.45), 0.45, K.surf_n(10.45, -1, 0.45)),
                                      (-7.35, 2.78, 2.0, (0, 1, 0)), (-7.35, -2.88, 2.0, (0, -1, 0))]):
        K.thruster('Q%d' % (i + 1), (x, y, z), n, inv='bow_thrusters' if x > 0 else 'stern_thrusters', note='bow' if x > 0 else 'stern')
    for side in (1, -1):
        K.pipe('PP%d' % (1 if side > 0 else 2), [(-7.85, side * 2.35, 1.6), (-9.0, side * 2.35, 1.6), (-9.0, side * 2.35, 0.97)], r=0.09, inv='stern_pipes')
    K.antenna('AN1', (-9.75, 1.25, 1.7), 1.8, whips=3, inv='antennas', note='antenna array on the stern deck, port')
    K.antenna('AN2', (-8.9, -0.15, 1.7), 1.4, whips=2, inv='antennas', note='antenna array on the stern deck, centre')

    # ---------------- the recessed band: vents and lamps; belly bay ----------------
    for side in (1, -1):
        for i, x in enumerate((6.35, 2.6, -1.95)):
            K.vent('VF%d%s' % (i, 'p' if side > 0 else 's'), (x, max(sf(x - 0.55, side, RECESS_Z + 0.08), sf(x + 0.55, side, RECESS_Z + 0.08), key=abs) + 0.01 * side, RECESS_Z + 0.08),
                   (0, side, 0), 1.0, 0.45, slats=5, inv='flank_vents')
        for i, x in enumerate((7.6, 4.4, 1.6, -0.6, -3.1, -4.7)):
            yl = (max(sf(x - 0.1, side, RECESS_Z), sf(x + 0.1, side, RECESS_Z), key=abs) + 0.02 * side) if x > -2.9 else side * 4.32
            K.lamp('L%d%s' % (i, 'p' if side > 0 else 's'), (x, yl, RECESS_Z - 0.02 if x > -2.9 else -0.36), (0, side, 0), inv='lamps')
        K.lamp('LC%s' % ('p' if side > 0 else 's'), (-3.3, cy(-3.3, side) + 0.01 * side, 2.25), (0, side, 0), inv='lamps')
    K.bay('B1', (-2.25, 0.0, -2.6), 3.2, 3.4, inv='bay', note='data.js hangar 2: squadrons drop from the belly')

    # ---------- colour zones ----------
    K.colour('soot black base plate', 13.0, -13.0, 'whole hull', 'patched, worn; dim red running lights')
    K.colour('rust plate (tier 2, brow step)', 11.5, -2.6, 'raised armoured deck and the brow')
    K.colour('violet Eclipse trophy plate', 5.9, 4.4, 'tier 2 deck, starboard')
    K.colour('violet Eclipse trophy plate', 5.7, 4.2, 'port flank')
    K.colour('pale Hegemony grey trophy plates', 2.6, -0.6, 'port flank, under the belt')
    K.colour('dried-blood red band', -2.15, -2.95, 'castle front')

    # ---------- INSIDE (round 3b: follows the lower, slimmer hull) ----------
    K.deck('lower', -1.35, -10.0, 10.2)
    K.deck('main', 0.0, -10.2, 10.6)
    K.deck_box('gun', 1.6, -2.4, 6.6, 2.8)
    K.deck_box('castle', 1.95, -7.6, -2.6, 2.5)
    for i, x in enumerate((10.5, 8.0, 4.8, 0.8, -2.6, -6.4, -9.0)):
        K.bulkhead('F%d' % i, x, inset=0.75)  # inside the rounded section
    K.room('tube_ducts', 'machinery', 9.95, 10.9, -1.8, 1.8, -1.0, 0.6, note='front tube ducts and sniffer gear')
    K.room('claw_machinery', 'machinery', 8.1, 10.0, -2.4, 2.4, -2.1, -1.45, note='pincer rams and winches')
    K.room('kennel_decks', 'crew', 4.9, 9.9, -2.8, 2.8, -1.25, 1.2, note='boarding gangs, two decks')
    K.room('rocket_magazine', 'magazine', -0.4, 4.7, -1.5, 1.5, 0.1, 1.3, note='under the rocket rack')
    K.room('loot_hold', 'hold', 0.9, 4.7, -3.0, 3.0, -2.25, -1.45, note='loot holds')
    K.room('hangar', 'hangar', -4.2, 0.7, -2.5, 2.5, -2.3, -0.1, note='two squadrons, belly drop')
    K.room('core', 'core', -6.3, -4.3, -1.2, 1.2, -2.2, -0.1, note='reactor core (hp_core)')
    K.room('shell_magazine_p', 'magazine', -6.3, -2.7, 1.5, 3.1, 0.1, 1.25, note='port battery magazine')
    K.room('shell_magazine_s', 'magazine', -6.3, -2.7, -3.1, -1.5, 0.1, 1.25, note='starboard battery magazine')
    K.room('gun_deck', 'crew', -2.5, 6.4, -2.5, 2.5, 1.45, 1.9, note='turret crews and hoists')
    K.room('warlord_hall', 'crew', -7.5, -2.7, -2.3, 2.3, 1.95, 2.45, note='the warlord hall')
    K.room('bridge', 'bridge', -7.1, -4.6, -1.4, 1.4, 2.55, 2.9, note='command deck')
    K.room('engine_room', 'engroom', -10.2, -6.5, -1.9, 1.9, -1.8, 1.2, note='engine room and pod feeds')
    K.armour('ram bow (forward of 10.5)', 0.6, 'stacked scrap plating in the brow and chin, around the tube ducts')
    K.armour('flank belts', 0.4, 'the upper and lower armour belts over the base hull')
    K.armour('tier 2 and castle roof', 0.3, '')
    K.armour('belly', 0.35, 'flat armoured belly with chines')
    K.armour('engine end', 0.2, 'thinnest: the soft spot')
    K.break_line('B-1', 7.0, 'tier 2 seam under the C1 girdle: the bow and the kennel decks tear off; C1 holds them a moment',
                 path=[(7.3, 1.55), (6.8, 1.0), (7.5, 0.3), (6.9, -0.6), (7.6, -1.6), (7.1, -2.6)])
    K.break_line('B-2', -2.5, 'castle seam under the C2 girdle: opens the rocket magazine and the hangar',
                 path=[(-2.3, 2.6), (-2.9, 1.9), (-2.1, 1.0), (-2.8, 0.1), (-2.0, -1.1), (-2.7, -2.6)])
    K.break_line('B-3', -7.4, 'castle and engine room seam: the engine block tears away with the stern',
                 path=[(-7.8, 2.25), (-7.2, 1.4), (-7.9, 0.5), (-7.3, -0.8), (-7.7, -2.2)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors throughout the hull (R215): decks, frames, spaces and machinery along the whole length, hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).'))
    K.point('core', 'hp_core', (-5.3, 0, -1.1))
    for i, (x, y, z, sec, side) in enumerate([(9.4, 3.3, 0.2, 'prow', 'port'), (7.4, -3.9, -1.1, 'prow', 'stbd'),
                                              (4.0, 4.1, -0.5, 'mid', 'port'), (-2.5, -3.2, 1.8, 'mid', 'stbd'),
                                              (-0.8, 4.2, 0.6, 'mid', 'port'), (-7.5, 2.6, 0.7, 'eng', 'port'),
                                              (-8.6, -2.5, -1.2, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (10.45, sf(10.45, 1, 0.45), 0.45), side='port')
    K.point('rcs', 'hp_rcs_1', (10.45, sf(10.45, -1, 0.45), 0.45), side='stbd')
    K.point('board', 'hp_board_0', (2.0, 4.2, -0.3), side='port')
    K.point('board', 'hp_board_1', (2.0, -4.3, -0.3), side='stbd')
    K.point('bay', 'hp_bay_0', (-2.25, 0, -2.7), note='launch down')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('A rounded wedge in section (round flanks and belly, a flatter deck), tapering in plan to a broad rounded nose', 'the Board on round 3b: the hull still read as a straight-sided box; Ryan: "the builds look like square blocks basically"')
    K.change('A long, low slab to the concept\'s measured proportions, the bow tapering in plan, the flank in layered belts', 'the Board on round 3: the hull was a straight-sided box, too tall; now length to beam about 3 and length to height about 4.5 like the round 8 sheet, tier 2 and the castle as low steps')
    K.change('The front tubes are the ship\'s face: big, side by side across the prow, jutting ahead of a tapered nose under a stepped brow', 'Ryan R217: "the tubes at the front ... are just circles on the actual build"')
    K.change('Rack raised on a plinth and pitched 12 degrees; no turret in front of it', 'Ryan R217: "the guns are visibly blocking the rockets"; the fit check proves every cell fires clear over the bow')
    K.change('Flak superfires from the castle front (T1) and a bridge barbette (T2)', 'the round 2 bunker turret sat in the rack\'s line of fire; the picture puts its top turret on the castle')
    K.change('Guns laid out as matched port and starboard batteries by game slot', 'the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are mirrored: a bow casemate, three deck-edge twin turrets, a flank casemate amidships and two sponson casemates per side')
    K.change('Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block', 'one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof')
    K.change('Roof turrets rest facing forward', 'the picture draws its barrel aft; no gun faces aft')
    K.change('The mid-length starboard engine pod becomes an upper pod on the stern deck', 'a pod at mid-length glowing forward would push the ship backward and burn its own deck')
    K.change('Two main engine pods, port larger, plus a centre main and lower boosters', 'the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells')
    K.change('Attitude thrusters moved off the casemates and pods', 'the fit check found the round 2 bow quads firing into the bow casemates and the stern quads into the pods')
    K.change('Chains are taut girdles and flank lashings of real links', 'a slack chain cannot sag in space (R185); the girdles sit on the break lines')
    K.change('Curved pincers under the bow tip; short grabbers under the stern', 'the concept\'s mandibles hang under the bow tip and its grabbers under the stern (the Board on round 3: round 3\'s read as legs under midships)')
    K.change('Engine pods brought in close to the hull', 'the concept\'s pods sit inside the ship\'s beam (top view); round 3\'s stood far out')
    K.change('Ventral launch bay and four attitude thruster quads added', 'data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn')
    K.change('Crystal shard removed', 'Ryan, R197')
    K.open_item('Belly detail between the claws and the bay is designed here; the picture does not show it')
    K.open_item('The notch in each tube\'s lower lip is left for the build\'s kit pass')

    # ---------- the fit report's fix column: round 2 clashes and how round 3 fixed them ----------
    K.fix('R1 launch cells covered by T1 (the bunker turret in front of the rack)', 'bunker turret removed; flak moved to the castle front (T1) and a bridge barbette (T2); the rack raised on a plinth and pitched 12 degrees')
    K.fix('Q1 and Q2 exhaust into the bow casemates PB and SB', 'bow quads moved up onto the upper chamfer of the prow, firing up and out; casemates moved aft to 9.0')
    K.fix('Q3 and Q4 exhaust into the pods E1 and E2 and their pylons', 'stern quads moved to the castle\'s aft corners, above the pods')
    K.fix('E3 and E4 exhaust into the hull and the E0 housing', 'boosters moved below and aft of the stern end, exits at -12.1')
    K.fix('E0 had no mount on the hull', 'its housing now runs forward into the stern (a mount piece)')
    K.fix('Claw blades H1 to H4 inside their hull housings', 'each pincer and grabber has its own housing as its mount, the blades clear of the hull')
    K.fix('Tube bores I1 and I2 inside the prow', 'a sunk tube is a mount by design: its bore runs back into the prow; the mouth must be clear (EXIT check)')
    K.fix('Casemate housings P4, P5, S4, S5, SB inside hull masses', 'casemates set onto the sponson outer faces and the bow flank surface, plates cleared under each mount')
    K.fix('Dish posts D1 and D2 inside the plinth', 'dishes stand on the plinth top on their own base plates')


def bpy_obj(name):
    import bpy
    return bpy.data.objects[name]
