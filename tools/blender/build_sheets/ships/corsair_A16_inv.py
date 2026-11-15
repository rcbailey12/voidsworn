# corsair_A16 parts inventory (round 3, R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (three-quarter from port, above) and
# corsair_A16_sheet.jpg (round 8 sheet: top view upper left, side view lower left). The concept has no underside view: belly
# lines come from the side view's lower edge and from data.js, and say so.
# Fields: id, job (R221: what the part does on the ship; a part with no job is cut), type (the kit part type in tools/blender/kits/hullbreakers/parts.py), what, count, cells (blob-sweep cells
# region/view: bow, mid, stern x top, side, below), reads (the sub-parts that make it read as that thing), src, note.
INVENTORY = [
    # ---------------- bow (prow to about 33 percent) ----------------
    dict(id='prow', job='the armoured nose: takes the first hits and rams, and houses the tube cluster', type='hull', what='blunt rounded prow: faceted cap stepping down over the tube cluster, a brow overhang, plate steps',
         count=1, cells=['bow/top', 'bow/side'], reads='bevels, a stepped brow, an overhang over the tubes', src='picture'),
    dict(id='ftubes', job='wake-sniffer scoops: draw in the wake of ships ahead so the barge can track prey', type='tube', what='front tubes (wake-sniffer scoops) side by side under the brow', count=2, cells=['bow/side', 'bow/top'],
         reads='deep dark bores, thick rolled lips hooded on top, a notch in the lower lip, segmented bodies with clamp bands', src='picture'),
    dict(id='ftube_spine', job='carries the scoop ducting between the tubes into the hull', type='vent', what='ribbed housing between and above the tubes', count=1, cells=['bow/side'],
         reads='a frame with vertical ribs and a dark recess', src='picture'),
    dict(id='dishes', job='listening dishes: hear targets ahead (the ship\'s eyes forward)', type='dish', what='listening dishes side by side on a plinth over the prow', count=2, cells=['bow/top', 'bow/side'],
         reads='ribbed shallow bowls with rolled rims, feed horns on struts, yokes, a base', src='picture'),
    dict(id='bow_guns', job='scatter guns, data.js slots P and S: the broadside battery forward', type='gun', what='deck-edge twin turrets in a row along the forward deck edges (picture: port edge only)', count=4,
         cells=['bow/top', 'bow/side'], reads='rings, faceted housings, mantlets, breeches, long barrels with sleeves and brakes', src='picture',
         note='mirrored to starboard as a matched battery (R213)'),
    dict(id='bow_claws', job='boarding pincers: seize a victim\'s hull for the boarders (the Hullbreakers\' trade)', type='claw', what='big hooked boarding claws under the chin', count=2, cells=['bow/below', 'bow/side'],
         reads='hinge drums with caps, armoured segments, joint drums, piston rams, hooked fingers', src='picture'),
    dict(id='bow_hatchboxes', job='deck access and ready stores for the forward guns', type='hatchbox', what='raised framed deck boxes on the forward deck', count=2, cells=['bow/top'],
         reads='a framed box, an inset lid, side ribs', src='picture'),
    dict(id='bow_trophy', job='armour taken from beaten Eclipse ships, bolted on as plate and as a kill mark', type='plate', what='violet Eclipse trophy plates (deck and port flank)', count=2, cells=['bow/top', 'bow/side'],
         reads='thick slabs with bevels and rivets in their old colour', src='picture'),
    dict(id='bow_plates', job='armour', type='plate', what='armour plating of mixed size over the whole bow', count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='slabs with thickness steps, bevelled edges, rivets at the corners, a second slab stacked on some', src='picture'),
    dict(id='flank_vents', job='shed heat from the reactor and the gun decks', type='vent', what='louvre panels in a row along the lower flank', count=6, cells=['bow/side', 'mid/side'],
         reads='frames, slanted slats, dark recesses', src='picture'),
    dict(id='lamps', job='running lights: other ships see where the barge is in the fleet', type='lamp', what='dim red running lights along both flanks and on the castle', count=14,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='hooded housings with red lenses', src='picture'),
    dict(id='bow_thrusters', job='attitude thrusters: turn the bow', type='thruster', what='attitude thruster quads at the bow', count=2, cells=['bow/side'],
         reads='a bevelled block, four splayed nozzles', src='designed', note='a ship in space needs them to turn'),
    # ---------------- midships (33 to 66 percent) ----------------
    dict(id='tier2', job='raised armoured deck: carries the deck guns high enough to fire over the hull', type='tier', what='raised armoured deck (tier 2) with a sloped, stepped front', count=1, cells=['mid/top', 'mid/side'],
         reads='a sloped face, a roof line with a step, openings (vision slits) in the face', src='picture'),
    dict(id='rack', job='heavy rockets, data.js slot F (htorp)', type='rack', what='heavy rocket rack, 2 by 5 cells, on the spine', count=1, cells=['mid/top'],
         reads='a framed box of cells, rocket noses set back in each cell, dividers, side cheeks, a yoke and a ring', src='picture'),
    dict(id='armour_vent', job='armoured vent: dumps magazine and gun-deck heat', type='hatchbox', what='armoured vent housing forward of the rack: a raised box with two slanted blades', count=1,
         cells=['mid/top'], reads='a frame, an inset lid, ribs, two slanted armour fins', src='picture'),
    dict(id='mid_guns', job='scatter guns, slots P and S: the broadside battery amidships', type='gun', what='deck-edge twin turrets amidships', count=2, cells=['mid/top', 'mid/side'],
         reads='as the bow turrets', src='picture'),
    dict(id='patches', job='field repairs: plate welded over battle damage', type='patch', what='torn patch plates, crooked and overlapping, mid-flank and the tier 2 shoulder', count=8,
         cells=['mid/side', 'mid/top'], reads='crooked slabs, one corner lifted, rivets', src='picture'),
    dict(id='pale_plates', job='armour taken from Hegemony ships, bolted on as plate and as a kill mark', type='plate', what='pale Hegemony grey trophy plates on the port flank', count=1, cells=['mid/side'],
         reads='thick slabs with bevels and rivets', src='picture'),
    dict(id='flank_ribs', job='frame ribs: the hull\'s structure, showing through the plate', type='rib', what='vertical frame ribs dividing the flank into sections', count=8, cells=['mid/side', 'stern/side', 'bow/side'],
         reads='raised rib bars from the belt to the deck edge', src='picture'),
    dict(id='belt', job='armour belt: the thickest plate where broadside fire lands', type='plate', what='belt strake along each flank', count=2, cells=['bow/side', 'mid/side'], reads='a raised armour band', src='picture'),
    dict(id='antennas', job='comms and sensors: talk to the fleet, see around the ship', type='antenna', what='antenna arrays on the spine (the sheet top view shows tall sticks)', count=2, cells=['mid/top', 'stern/top'],
         reads='a base, a short mast, whips of uneven height, a sensor pod; never a crossbar mast (R185)', src='picture'),
    dict(id='grapples', job='grapples: hold a seized hull alongside under the stern', type='claw', what='grapple arms under the belly (sheet side view: three grabbers)', count=2, cells=['mid/below', 'stern/below'],
         reads='hinge drums, segments, joints, rams, three-finger grabbers', src='picture', note='a matched pair; the picture has three'),
    dict(id='belly_turret', job='flak, data.js slot T: covers below, where the deck guns cannot reach', type='gun', what='belly flak twin turret (R221: moved off the castle front, out of the rack\'s backblast)', count=1,
         cells=['mid/below'], reads='ring, housing, mantlet, breeches, barrels with brakes', src='designed', note='the picture shows no underside'),
    dict(id='bay', job='launch bay, data.js hangar 2: squadrons drop from the belly', type='bay', what='ventral launch bay (data.js hangar 2)', count=1, cells=['mid/below'],
         reads='a raised rim, two door leaves, a centre seam, hinges', src='designed', note='the picture shows no underside'),
    dict(id='belly_plates', job='armour under the hull', type='plate', what='flat armoured belly with chines', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='plates with steps and rivets, chine edges', src='designed', note='the picture shows no underside'),
    # ---------------- stern (66 to 100 percent) ----------------
    dict(id='castle', job='armoured citadel over the engine room and crew decks', type='tier', what='the castle (tier 3): sloped front with a dried-blood band, flank faces, window slits and hatches', count=1,
         cells=['stern/top', 'stern/side'], reads='sloped faces, a roof line, openings (slits and a hatch), edge bevels', src='picture'),
    dict(id='bridge', job='command deck: where the warlord fights the ship', type='tier', what='bridge block on the castle roof with a vision slit', count=1, cells=['stern/top', 'stern/side'],
         reads='a face, a roof line, a vision slit', src='picture'),
    dict(id='top_turret', job='flak, data.js slot T: all-round cover from the bridge', type='gun', what='castle-top turret with a long barrel', count=1, cells=['stern/top'],
         reads='ring, housing, mantlet, breeches, long barrels with brakes', src='picture', note='turned to face forward (R204: no gun aft)'),
    dict(id='main_engine', job='main thrust', type='engine', what='big main engine bells: the port pod the larger, a centre main', count=3, cells=['stern/side', 'stern/top'],
         reads='a bell with a thick lip, a throat, an inner cone, cooling rings, gimbal struts, a banded housing, a mount collar', src='picture'),
    dict(id='boosters', job='extra thrust for a ramming run', type='engine', what='small lower booster bells', count=2, cells=['stern/side', 'stern/below'], reads='as the main engines', src='picture'),
    dict(id='upper_pod', job='thrust (a salvaged pod set high)', type='engine', what='upper pod engine on the stern deck', count=1, cells=['stern/top'], reads='as the main engines', src='picture'),
    dict(id='pylons', job='hold the engine pods to the hull', type='pylon', what='armoured engine housings and pylons around the pods', count=2, cells=['stern/side', 'stern/top'],
         reads='a stepped web with plates', src='picture'),
    dict(id='round_hatch', job='crew access to the stern deck', type='hatch', what='round hatch with a hand wheel on the stern deck', count=1, cells=['stern/top'],
         reads='a rim, a door, a seam, hinges, a hand wheel', src='picture'),
    dict(id='castle_hatches', job='crew access to the castle flanks', type='hatch', what='flank hatches on the castle', count=2, cells=['stern/side'], reads='a rim, a door, a seam, hinges', src='picture'),
    dict(id='stern_pipes', job='fuel and coolant to the pods', type='pipe', what='pipe runs along the stern flanks to the pods', count=2, cells=['stern/side'], reads='runs with flange rings', src='picture'),
    dict(id='stern_thrusters', job='attitude thrusters: turn the stern', type='thruster', what='attitude thruster quads at the stern', count=2, cells=['stern/side'],
         reads='a bevelled block, four splayed nozzles', src='designed'),
]
# Structure (round 3b, the Board on round 3): distinct masses per blob-sweep cell, counted by eye on the round 8 sheet's side and
# top views (thirds of the length). The concept has no underside view.
STRUCTURE = {'bow/top': 5, 'bow/side': 6, 'mid/top': 6, 'mid/side': 7, 'stern/top': 7, 'stern/side': 7}
STRUCTURE_NOTE = 'A16 sheet: bow, the prow cap, brow steps, tube housing, chin and layered flank belts; midships, tier 2, the rack plinth, the vent box, three flank bands and the sponson; stern, castle, bridge, stern deck, two pod housings and flank bands'
LEFT_PLAIN = [
    'Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The picture\'s chains: cut, they have no job on the ship (Ryan, R221: "There\'s no purpose").',
    'The crystal shard: removed (R197).',
]
