# corsair_A17 parts inventory (round 3, R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg (three-quarter from port, above) and
# corsair_A17_sheet.jpg (round 8 sheet: top view upper left, side view lower left). The concept has no underside view.
# Fields as in corsair_A16_inv.py (each line names its job, R221).
INVENTORY = [
    # ---------------- bow: the head (prow to about 33 percent) ----------------
    dict(id='head', job='the armoured ram head: takes the first hits and houses the sensors and jaw mouth', type='hull', what='the head: an octagonal block with heavy chamfers on every edge, a bevelled top edge, two roof steps, '
         'a face that overhangs the jaw mouth, a recessed jaw mouth under it', count=1, cells=['bow/top', 'bow/side'],
         reads='bevels, steps, an overhang, a cut-in mouth (never a flat block, R217)', src='picture'),
    dict(id='head_face', job='armour over the face, where head-on fire lands', type='plate', what='face panels on the head front: raised framed panels with vertical straps', count=1, cells=['bow/side'],
         reads='slabs with steps, bevels and rivets; straps', src='picture'),
    dict(id='head_hatchboxes', job='deck access and ready stores for the head', type='hatchbox', what='framed boxes on the head roof', count=3, cells=['bow/top'], reads='a framed box, an inset lid, side ribs', src='picture'),
    dict(id='scoops', job='wake-sniffer scoops: draw in the wake of ships ahead to track prey', type='tube', what='scoop drums at the lower corners of the head (port larger)', count=2, cells=['bow/side', 'bow/top'],
         reads='ribbed drums with bands, a rolled lip, a grille in a dark mouth', src='picture'),
    dict(id='ears', job='listening dishes: hear targets ahead and to the sides (the pack hunter\'s ears)', type='dish', what='listening dishes as ears on brackets at the upper sides of the head', count=2, cells=['bow/top', 'bow/side'],
         reads='ribbed bowls with rims, feed horns on struts, yokes, a base', src='picture'),
    dict(id='jaws', job='boarding grabbers: seize and pin a victim\'s hull for the boarding gangs (the Hullbreakers\' trade)', type='claw_arm',
         what='four articulated grabber arms from under the jaw, a pair a side, upper and lower, closing like pincers (R229: the whole beauty, not the bow crop)',
         count=4, cells=['bow/below', 'bow/side', 'bow/top'], reads='shoulder hinges on brackets, two box segments, knuckles with hinge plates, rams, forked hooked pincers', src='picture'),
    dict(id='jaw_pipes', job='hydraulics that close the jaws', type='pipe', what='coiled hoses and pipes under the head between the jaws', count=3, cells=['bow/below'],
         reads='runs with flange rings', src='picture'),
    dict(id='brow_rack', job='rattle rockets, data.js slot F (torp)', type='rack', what='rattle-rocket pod on the brow (data.js torp F)', count=1, cells=['bow/top'],
         reads='a box of cells with noses, frame, dividers, cheeks, a yoke and a ring', src='designed',
         note='the picture shows no launcher; data.js gives a forward torpedo slot'),
    dict(id='head_plates', job='armour', type='plate', what='armour plating over the head', count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='bow_thrusters', job='attitude thrusters: turn the head', type='thruster', what='attitude thruster quads at the head', count=2, cells=['bow/side'], reads='a block, splayed nozzles', src='designed'),
    # ---------------- midships: neck and hump (33 to 66 percent) ----------------
    dict(id='hump', job='armoured hump over the reactor and crew decks; raises the turrets', type='tier', what='the shoulder hump: stepped tiers with sloped faces, a crest, openings', count=1, cells=['mid/top', 'mid/side'],
         reads='sloped faces, roof lines with steps, slits and hatches in the faces', src='picture'),
    dict(id='hump_hatchboxes', job='deck access and ready stores for the deck guns', type='hatchbox', what='raised framed boxes on the hump and the neck deck', count=3, cells=['mid/top'],
         reads='a framed box, an inset lid, side ribs', src='picture'),
    dict(id='deck_guns', job='scatter guns, data.js slots P and S: the broadside battery', type='gun', what='deck-edge twin turrets', count=4, cells=['mid/top', 'mid/side'],
         reads='rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes', src='picture'),
    dict(id='crest_gun', job='flak, data.js slot T: all-round cover from the aft block', type='gun', what='twin turret on the hump crest', count=1, cells=['mid/top'], reads='as above', src='picture'),
    dict(id='patches', job='field repairs: plate welded over battle damage', type='patch', what='torn patch plates on the flanks and hump shoulder', count=8, cells=['mid/side', 'mid/top'],
         reads='crooked slabs, a lifted corner, rivets', src='picture'),
    dict(id='rust_plates', job='armour, salvaged and mismatched', type='plate', what='rust and dried-blood red plates (hump, deck edges)', count=3, cells=['mid/top', 'mid/side'],
         reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='flank_ribs', job='frame ribs: the hull\'s structure, showing through the plate', type='rib', what='vertical frame ribs on the flanks', count=6, cells=['mid/side', 'stern/side'], reads='raised rib bars', src='picture'),
    dict(id='lamps', job='running lights: pack mates see where it is', type='lamp', what='red lamps in rows along the lower flank', count=12, cells=['bow/side', 'mid/side', 'stern/side'],
         reads='hooded housings, red lenses', src='picture'),
    dict(id='belly_turret', job='flak, data.js slot T: covers below', type='gun', what='belly twin turret (covers below)', count=1, cells=['mid/below'], reads='as the deck turrets', src='designed'),
    dict(id='belly_plates', job='armour under the hull', type='plate', what='flat armoured belly with chines', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='slabs with steps and rivets', src='designed', note='the picture shows no underside'),
    # ---------------- stern (66 to 100 percent) ----------------
    dict(id='engines', job='main thrust: speed for the pack\'s chase', type='engine', what='the stacked engine cluster: three per side, port bells larger', count=6, cells=['stern/side', 'stern/top', 'stern/below'],
         reads='ribbed banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars', src='picture'),
    dict(id='engine_block', job='holds the engine cluster to the hull', type='pylon', what='the engine block the cluster mounts on', count=1, cells=['stern/side', 'stern/top'],
         reads='a stepped web with plates', src='picture'),
    dict(id='antennas', job='comms: talk to the pack', type='antenna', what='twin antenna arrays on the aft hump (sheet top view)', count=2, cells=['stern/top'],
         reads='a base, a mast, uneven whips, a pod (never a crossbar mast)', src='picture'),
    dict(id='stern_hatch', job='crew access to the engine room', type='hatch', what='hatches on the aft hump faces', count=2, cells=['stern/side', 'stern/top'], reads='a rim, a door, a seam, hinges', src='picture'),
    dict(id='stern_vents', job='shed engine-room heat', type='vent', what='louvre panels on the aft flanks over the engine room', count=2, cells=['stern/side'], reads='frames, slats', src='picture'),
    dict(id='stern_thrusters', job='attitude thrusters: turn the stern', type='thruster', what='attitude thruster quads at the stern', count=2, cells=['stern/side'], reads='a block, splayed nozzles', src='designed'),
]
# Structure (round 3b, the Board on round 3): distinct block masses per blob-sweep cell, counted by eye on the round 8 sheet's
# side and top views (thirds of the length). The concept has no underside view.
STRUCTURE = {'bow/top': 5, 'bow/side': 5, 'mid/top': 7, 'mid/side': 7, 'stern/top': 5, 'stern/side': 6}
STRUCTURE_NOTE = 'A17 sheet: bow, the head block, its roof step, the neck block, the flank tier and belly band; midships, three stepped top blocks over flank blocks; stern, two top blocks, the engine block and flank blocks'
LEFT_PLAIN = [
    'Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The picture\'s chains: cut, they have no job on the ship (Ryan, R221: "There\'s no purpose").',
    'The crystal shard: removed (R197).',
]
