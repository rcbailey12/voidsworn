# corsair_A18 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling (issue 633).
# Read from the WHOLE concept first (R229): contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg (v3, three
# quarter from the port bow, above) and corsair_A18_sheet.jpg (top view, true side view, bow-on), with designs.md for the
# fittings the picture drifted on and data.js c_raider (autocannon T, overburn) for the guns. The concept has no underside view.
# Fields as in corsair_A16_inv.py; each line names its job (R221).
INVENTORY = [
    # ---------------- bow: the wedge, face, chin and the dish shoulder (prow to about 33 percent) ----------------
    dict(id='hull_form', job='the raider\'s hull: a lean wedge that cuts a small target head-on', type='hull',
         what='the sloped wedge bow running down to a small face over a cut-in chin, the long low body, the aft taper', count=1,
         cells=['bow/top', 'bow/side', 'mid/side', 'stern/side'], reads='bevels, steps, an overhang (the face over the chin)', src='picture'),
    dict(id='face_plates', job='armour over the face and brow, where head-on fire lands', type='plate', what='brow and cheek plates round the face, a lip and straps',
         count=1, cells=['bow/side', 'bow/top'], reads='slabs with steps, bevels and rivets', src='picture'),
    dict(id='scoop', job='the wake-sniffer scoop: tastes the wake of ships ahead so the pack can follow them', type='tube',
         what='a scoop drum with a grille in the bow face', count=1, cells=['bow/side'], reads='ribbed drum, bands, rolled lip, a grille in a dark mouth', src='picture',
         note='the picture\'s grilled mouth; designs.md puts it under the chin'),
    dict(id='sponson', job='carries the dish out past the hull so it hears round the bow', type='tier', what='the dish sponson swelling the port bow shoulder, a vision slit in its front',
         count=1, cells=['bow/top', 'bow/side'], reads='a face, a roof, an opening', src='designed', note='designs.md: the port shoulder swollen out by the dish mount'),
    dict(id='sponson_plates', job='armour', type='plate', what='plates over the sponson', count=1, cells=['bow/top', 'bow/side'], reads='slabs with steps, bevels, rivets', src='designed'),
    dict(id='ear', job='the one big ear: hears prey before anything else in the pack (the Sniffer\'s job)', type='dish',
         what='an oversized listening dish on the port shoulder, three quarters of the beam across', count=1, cells=['bow/top', 'bow/side'],
         reads='ribbed bowl with a rim, a feed horn on struts, a yoke, a post, a base', src='picture', note='the picture\'s big round disc on the foredeck'),
    dict(id='grabbers', job='boarding grabbers: pin a fleeing hull long enough for the pack to catch up', type='claw_arm',
         what='one pair of small grabber arms under the chin', count=2, cells=['bow/below', 'bow/side'],
         reads='shoulder hinges on brackets, box segments, knuckles, rams, forked pincers', src='picture'),
    dict(id='chin_pipes', job='hydraulics that drive the grabbers', type='pipe', what='a pipe run under the chin to the grabber rams', count=1, cells=['bow/below'],
         reads='a run with flange rings', src='designed'),
    dict(id='hull_plates', job='armour, salvaged and mismatched', type='plate', what='patch plating over the whole hull, a few plates in trophy colours',
         count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='slabs with steps, bevels, rivets', src='picture'),
    dict(id='thrusters', job='attitude thrusters: the raider turns hard (evasion 28 in data.js)', type='thruster', what='attitude thruster quads at bow and stern',
         count=4, cells=['bow/side', 'stern/side'], reads='a block, splayed nozzles', src='designed'),
    # ---------------- midships: the spine and the flanks (33 to 66 percent) ----------------
    dict(id='spine', job='the armoured spine over the crew space and the core; lifts the gun so it sees all round', type='tier',
         what='five stacked spine blocks with gaps, the gun and sensor blocks tallest, slits in the fore block', count=1, cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'],
         reads='faces, roof lines with steps, openings', src='picture'),
    dict(id='autocannon', job='the raider\'s gun, data.js autocannon T: chews up escorts and fighters all round', type='gun',
         what='twin autocannon turret on the spine\'s gun block', count=1, cells=['mid/top', 'mid/side'],
         reads='turret ring, faceted housing, mantlet, breeches, barrels with sleeves and brakes', src='picture',
         note='the picture shows many guns; data.js gives one weapon'),
    dict(id='spine_boxes', job='ready-use lockers and deck access', type='hatchbox', what='framed boxes on the spine', count=2, cells=['mid/top', 'stern/top'],
         reads='a framed box, an inset lid, side ribs', src='picture'),
    dict(id='spine_hatch', job='crew access to the spine', type='hatch', what='a hatch on the aft spine block flank', count=1, cells=['stern/side'], reads='a rim, a door, a seam, hinges', src='picture'),
    dict(id='antenna', job='comms: calls the pack in on what the dish heard', type='antenna', what='a small antenna array on the sensor block', count=1,
         cells=['mid/top', 'mid/side'], reads='a base, a mast, whips, a pod (never a crossbar mast)', src='picture'),
    dict(id='flank_bricks', job='armour bricks over the flank where the crew space is', type='tier', what='bolted armour bricks on both flanks, unmatched', count=1,
         cells=['mid/side', 'bow/side', 'stern/side'], reads='a face, a roof, an undercut', src='picture'),
    dict(id='trophy', job='armour, and the pack\'s boast: plate torn from a Hegemony hull and an Eclipse one', type='patch',
         what='a pale Hegemony trophy plate bolted flat on the starboard flank; a violet Eclipse patch on the foredeck', count=2, cells=['mid/side', 'mid/top', 'bow/top'],
         reads='crooked slabs, a lifted corner, rivets', src='picture'),
    dict(id='lamps', job='running lights: pack mates see where it is (sparse and dim, it runs dark)', type='lamp', what='dim red lamps at bow, midships and stern',
         count=6, cells=['bow/side', 'mid/side', 'stern/side'], reads='hooded housings, red lenses', src='picture'),
    dict(id='belly_plates', job='armour under the hull', type='plate', what='flat armoured belly with the band stepping in', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with steps and rivets', src='designed', note='the picture shows no underside'),
    # ---------------- stern (66 to 100 percent) ----------------
    dict(id='engines', job='main thrust: the overburn engines that make it the fastest Hullbreaker', type='engine',
         what='two engine drums at the stern quarters (starboard larger) and a small centre bell', count=3, cells=['stern/side', 'stern/top', 'stern/below'],
         reads='banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars', src='picture'),
    dict(id='pylons', job='hold the engine drums out from the hull', type='pylon', what='short pylons from the stern quarters to the drums', count=1, cells=['stern/top', 'stern/side'],
         reads='a web with plates', src='picture'),
    dict(id='engine_block', job='the stern block the engines bolt to; houses the engine room', type='pylon', what='the low engine block at the stern', count=1,
         cells=['stern/top', 'stern/side'], reads='a web with plates', src='picture'),
    dict(id='vents', job='shed engine-room heat (overburn runs hot)', type='vent', what='louvre panels on the engine block flanks', count=2, cells=['stern/side'],
         reads='frames, slats', src='designed'),
]
# Structure: distinct block masses per blob-sweep cell, counted by eye on the concept sheet's top and side views (thirds of the
# length). The concept has no underside view.
STRUCTURE = {'bow/top': 4, 'bow/side': 4, 'mid/top': 5, 'mid/side': 5, 'stern/top': 5, 'stern/side': 5}
STRUCTURE_NOTE = ('A18 sheet: bow, the wedge, the face and chin, the flush disc, the spine\'s front block; midships, two spine blocks, the flank '
                  'tier and two flank bricks; stern, the aft spine, the engine block, two engine drums and the centre bells')
LEFT_PLAIN = [
    'Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stage 5), not modelled.',
    'The picture\'s rows of flank guns, designs.md\'s two bow casemates and its rocket rack: data.js c_raider has one weapon (autocannon T); '
    'a gun with no slot has no job (R221), so they are not built.',
    'The picture\'s three stacked centre bells: one small centre bell, with the two drums (designs.md gives two bells).',
]
