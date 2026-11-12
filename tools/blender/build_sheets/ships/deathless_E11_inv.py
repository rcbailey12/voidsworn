# deathless_E11 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg (three-quarter from ahead, starboard and
# above, the bow lower right) and deathless_E11_sheet.jpg (top view above, side view below, BOW ON THE RIGHT in both; the
# small ship in each view is the escort, not this hull). The concept has no underside view.
# Fields: id, type (tools/blender/kits/eclipse/parts.py SUBPARTS), what, count, cells, reads (the sub-parts that make it read
# as that thing), src (picture or designed).
KIT = 'eclipse'
INVENTORY = [
    # ---------------- bow (prow tip to 33 percent): the crescent shade and the corona arc projector ----------------
    dict(id='crescent', type='shade', what='the crescent shade: a broad blade curving forward round the projector, thick at its inner wall and '
         'knife-thin at its outer rim, horns reaching past the muzzle, the plane drooping a little toward the horns', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side'],
         reads='a lower blade, an upper layer stepped in from the rim, a short third layer at the root, a green-white corona line on every rim, '
               'dense plates', src='picture'),
    dict(id='crescent_plates', type='plate', what='dense small plates over the crescent faces (upper, inner wall, belly)', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='projector', type='spinal', what='the central barrel through the crescent: the corona arc projector (data.js doom F; the Tomb-ark spinal shell)',
         count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='stepped octagonal breech collars, shaft segments with bands and rails, an octagonal muzzle block, a dark bore, a green emitter lens',
         src='picture'),
    dict(id='bow_thrusters', type='thruster', what='attitude thrusters on the neck flanks', count=2, cells=['mid/side'], reads='a block, slot nozzles', src='designed'),
    # ---------------- midships (33 to 66 percent): the body behind the shade, the batteries ----------------
    dict(id='body', type='hull', what='the long oval body: widest behind the crescent, a gentle taper aft to a waist at the band collar', count=1,
         cells=['mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='a rounded oval section (never a box), a neck stepping down into the crescent root, an overhang over the collars', src='picture'),
    dict(id='body_plates', type='plate', what='the plate rows over the body: rows of small plates across the deck, ribbed rows down the flanks', count=1,
         cells=['mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'], reads='chamfered slabs with steps and fasteners',
         src='picture'),
    dict(id='dorsal_tiers', type='tier', what='layered dorsal plate tiers along the spine carrying the batteries (the concept\'s raised plate rows)', count=1,
         cells=['mid/top', 'mid/side'], reads='stepped faces, roof lines, openings (the core port and hatches)', src='picture'),
    dict(id='belts', type='belt', what='the flank belt: a raised strake of armour boxes at mid height, both flanks', count=2,
         cells=['mid/side', 'mid/top', 'stern/side'], reads='a band following the hull curve, plates on it', src='picture'),
    dict(id='skirt', type='belt', what='the lower flank skirt: tall narrow plates hanging in a row below the belt', count=2,
         cells=['mid/side', 'mid/below', 'stern/side'], reads='a band following the hull curve, tall narrow plates', src='picture'),
    dict(id='main_guns', type='gun', what='the two big twin turrets on the centreline (data.js gauss T, gauss T)', count=2,
         cells=['mid/top', 'mid/side'], reads='hex plinths, faceted housings under stacked shade plates, mantlets, breeches, coiled barrels, ringed muzzles',
         src='picture'),
    dict(id='core_port', type='corewin', what='the green hexagonal port on the deck: the trapped core\'s light seen through a gap (factions.md)', count=1,
         cells=['mid/top'], reads='a hex rim, glowing glass set back, bars', src='picture', note='README 8c called it a flak cluster; read as the core port'),
    dict(id='shade_gen', type='hatchbox', what='the raised deck housing between the core port and the aft turret', count=1, cells=['mid/top', 'mid/side'],
         reads='a framed block, an inset lid under a stacked plate, side ribs', src='picture'),
    dict(id='belly_flak', type='gun', what='belly twin turret covering below (data.js flak T, second mount)', count=1, cells=['mid/below'],
         reads='as the turrets', src='designed'),
    dict(id='hatches', type='hatch', what='octagonal hatches on the deck tiers and the belly', count=4, cells=['mid/top', 'mid/below'],
         reads='a rim, a door, a seam, hinges', src='designed'),
    dict(id='lamps', type='lamp', what='corona strip lights along the flank belt', count=8, cells=['mid/side', 'stern/side'],
         reads='a housing, a green-white bar lens', src='designed'),
    # ---------------- stern (66 to 100 percent): the band collar, the shade feathers, the engines ----------------
    dict(id='flak', type='gun', what='the small twin turret aft on the deck (data.js flak T)', count=1, cells=['stern/top', 'stern/side'],
         reads='as the turrets, smaller, slimmer barrels', src='picture'),
    dict(id='band_collar', type='belt', what='the heavy band collar round the body at about three quarters of the length', count=1,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a raised ring following the hull, segmented plates', src='picture'),
    dict(id='feathers', type='feather', what='layered swept shade blades round the stern, row over row, flaring toward the engines', count=24,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='tapered blades with a thickness step, overlapping rows', src='picture'),
    dict(id='engines', type='engine', what='the engine cluster: three bells stacked in the side view, two side by side in plan (a diamond of four)',
         count=4, cells=['stern/side', 'stern/top', 'stern/below'],
         reads='faceted ribbed drums, mount collars, vanes, short bells, a corona ring round a black shade disc (no flame)', src='picture'),
    dict(id='vents', type='vent', what='heat slot panels on the aft flanks over the belt', count=2, cells=['stern/side'],
         reads='a frame, slanted slats', src='designed'),
    dict(id='stern_thrusters', type='thruster', what='attitude thrusters on the stern flanks', count=2, cells=['stern/side'], reads='a block, slot nozzles',
         src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the 8c sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 6, 'bow/side': 5, 'mid/top': 8, 'mid/side': 8, 'stern/top': 8, 'stern/side': 8}
STRUCTURE_NOTE = ('E11 sheet: bow, the crescent\'s lower blade, upper layer and inner rim layer, the collars, shaft and muzzle block; midships, the '
                  'crescent root, the body, the deck plate rows, two turret plinths, the core port and housing, the flank rails; stern, the body, '
                  'the band collar, three feather rows, the engine cluster, the small turret, the belt')
LEFT_PLAIN = [
    'Grime, scuffs, the pale grey-green weathering patch on the inner crescent face (README 8c) and decals: surface texture, painted in the '
    'build (recipe stages 4 and 5), not modelled.',
    'The escort beside the flagship in every picture is its own ship (a later fleet brief), not part of this hull.',
]
