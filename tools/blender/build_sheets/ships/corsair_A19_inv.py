# corsair_A19 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling (issue 633).
# Read from the WHOLE concept first (R229): contrib/muse/design/class_family_corsair_2026_11/corsair_A19_beauty.jpg (v6, three
# quarter from the port bow, above) and corsair_A19_sheet.jpg (top view, true side view, bow-on), with designs.md for the
# fittings the picture drifted on, Ryan's ruling (the two casemates IN the bow face) and data.js c_reaver (torp F, scatter S).
# Fields as in corsair_A16_inv.py; each line names its job (R221).
INVENTORY = [
    # ---------------- bow: the foredeck plate, the face, the chin (prow to about 33 percent) ----------------
    dict(id='hull_form', job='the gutship\'s hull: a long lean slab that carries the guns to the fight', type='hull',
         what='an arrow-head wedge over the first third (a narrow bow face over a sloped chin, the flanks widening back to full beam), the long low body, the taper into the stern block', count=1,
         cells=['bow/top', 'bow/side', 'mid/side', 'stern/side'], reads='bevels, steps, an overhang (the foredeck plate over the face)', src='picture'),
    dict(id='spade', job='armour over the bow: the foredeck plate the casemates fire from under', type='tier', what='the broad flat bow plate, an arrow-head from above: a blunt point that widens over the first third, overhanging the bow face',
         count=1, cells=['bow/top', 'bow/side'], reads='a face, a roof, an overhang', src='picture'),
    dict(id='spade_plates', job='armour', type='plate', what='plates over the foredeck plate', count=1, cells=['bow/top'], reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='bow_launchers', job='data.js torp F: the rattle-rocket salvo, fired straight ahead from the bow face', type='bow_launcher',
         what='one rocket casemate IN the bow face: a short fat cluster of three tubes (R241: the long tube is cut, issue 676)', count=1, cells=['bow/side', 'bow/top'],
         reads='an armour plate, a box housing with a brow, launch tubes with lips, bands, bores and rocket noses, bolts', src='picture',
         note='Ryan\'s ruling: the casemates sit in the face'),
    dict(id='scoop', job='the wake-sniffer scoop: tastes the wake of ships ahead', type='tube', what='a scoop drum with a grille under the chin', count=1, cells=['bow/side', 'bow/below'],
         reads='ribbed drum, bands, rolled lip, a grille in a dark mouth', src='designed', note='designs.md: one chin scoop'),
    dict(id='grabbers', job='boarding grabbers: pin a hull for the boarding gangs', type='claw_arm',
         what='four grabber arms: a pair under the chin, a pair under the forefoot', count=4, cells=['bow/below', 'bow/side'],
         reads='shoulder hinges on brackets, box segments, knuckles, rams, forked pincers', src='picture'),
    dict(id='belly_pipes', job='hydraulics for the grabber rams', type='pipe', what='a pipe run under the belly between the grabber pairs', count=1, cells=['bow/below'],
         reads='a run with flange rings', src='designed'),
    dict(id='dishes', job='listening dishes: hear targets ahead and astern', type='dish', what='a large dish on the foredeck plate to port, a small one on the stern block to starboard',
         count=2, cells=['bow/top', 'bow/side', 'stern/top'], reads='ribbed bowls with rims, feed horns on struts, yokes, posts, bases', src='picture'),
    dict(id='hull_plates', job='armour, salvaged and mismatched', type='plate', what='patch plating over the whole hull, a few plates in trophy colours',
         count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='thrusters', job='attitude thrusters: turn the long hull', type='thruster', what='attitude thruster quads at bow and stern', count=4,
         cells=['bow/side', 'stern/side'], reads='a block, splayed nozzles', src='designed'),
    # ---------------- midships: the spine, the starboard battery, the port side block (33 to 66 percent) ----------------
    dict(id='spine', job='the armoured spine over the decks; lifts the turrets so they fire over the casemates', type='tier',
         what='three stacked spine blocks with gaps, a slit in the fore block', count=1, cells=['mid/top', 'mid/side', 'bow/top', 'stern/top'],
         reads='faces, roof lines with steps, openings', src='picture'),
    dict(id='deck_turrets', job='data.js scatter S: the starboard broadside, turning through the S arc', type='gun', what='two twin turrets on the spine, resting to starboard',
         count=2, cells=['mid/top', 'mid/side'], reads='turret rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes', src='picture'),
    dict(id='spine_boxes', job='ready-use lockers for the gun crews', type='hatchbox', what='framed boxes on the spine', count=2, cells=['mid/top', 'stern/top'],
         reads='a framed box, an inset lid, side ribs', src='picture'),
    dict(id='side_block', job='armour over the port flank and the crew hatch; widens the hull for the decks', type='tier', what='the port side block amidships',
         count=1, cells=['mid/top', 'mid/side'], reads='a face, a roof, an undercut', src='picture'),
    dict(id='side_block_plates', job='armour', type='plate', what='plates over the side block', count=1, cells=['mid/side'], reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='bricks', job='armour bricks between the starboard casemates', type='tier', what='four bolted bricks on the starboard flank', count=1,
         cells=['mid/side', 'bow/side', 'stern/side'], reads='a face, a roof, an undercut', src='picture'),
    dict(id='trophy', job='armour, and the pack\'s boast', type='patch', what='the big pale Hegemony trophy plate on the port side block; violet and rust patches on the foredeck; a red patch on the spine',
         count=4, cells=['mid/side', 'bow/top', 'mid/top'], reads='crooked slabs, a lifted corner, rivets', src='picture'),
    dict(id='hatches', job='crew and engine-room access', type='hatch', what='a hatch in the port side block, one on the stern block', count=2, cells=['mid/side', 'stern/side'],
         reads='a rim, a door, a seam, hinges', src='picture'),
    dict(id='lamps', job='running lights: pack mates see where it is (sparse and dim)', type='lamp', what='dim red lamps low on both flanks', count=7,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='hooded housings, red lenses', src='picture'),
    dict(id='belly_plates', job='armour under the hull', type='plate', what='flat armoured belly with the band stepping in', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with steps and rivets', src='designed', note='the picture shows little of the underside'),
    # ---------------- stern (66 to 100 percent) ----------------
    dict(id='stern_block', job='the raised stern block: carries the engines, houses the engine room', type='tier', what='the stern block, higher than the spine',
         count=1, cells=['stern/top', 'stern/side'], reads='a face, a roof, an opening', src='picture'),
    dict(id='stern_plates', job='armour', type='plate', what='plates over the stern block', count=1, cells=['stern/top', 'stern/side'], reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='engines', job='main thrust', type='engine', what='three bells in the stern block, the centre the largest', count=3, cells=['stern/side', 'stern/top', 'stern/below'],
         reads='banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars', src='picture'),
    dict(id='vents', job='shed engine-room heat', type='vent', what='louvre panels on the stern block flanks', count=2, cells=['stern/side'], reads='frames, slats', src='designed'),
    dict(id='antenna', job='comms: hears the Sniffer\'s calls and the pack\'s orders', type='antenna', what='an antenna array on the stern block', count=1,
         cells=['stern/top', 'stern/side'], reads='a base, a mast, whips, a pod (never a crossbar mast)', src='designed'),
]
STRUCTURE = {'bow/top': 3, 'bow/side': 4, 'mid/top': 5, 'mid/side': 5, 'stern/top': 4, 'stern/side': 4}
STRUCTURE_NOTE = ('A19 sheet: bow, the foredeck plate, the face, the chin and the belly; midships, two spine blocks, the main body and the '
                  'side block with its pods; stern, the aft spine, the stern block, the engine housings and the belly')
LEFT_PLAIN = [
    'Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stage 5), not modelled.',
    'The picture\'s guns on the port flank and on the foredeck plate: data.js c_reaver has one starboard battery (scatter S) and one forward '
    'launcher (torp F, the bow casemates); a gun with no slot has no job (R221).',
    'designs.md\'s rocket racks on the middle deck: the bow casemates fire the one torp slot.',
]
