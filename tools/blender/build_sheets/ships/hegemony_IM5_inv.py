# hegemony_IM5 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg (three-quarter from
# above and off the starboard bow, the bow lower left) and IM5_top.jpg (true top view, bow down; its label hides the bow tip),
# with design_notes_758.md section IM5 (the weapon callouts are the h_boss slots). IM5 has no side or underside view.
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    # ---------------- the hull masses ----------------
    dict(id='hull', job='the one broad wedge hull: two raised armoured ridges carrying the crew decks and the shoulder lances, the canyon between them carrying the plant, the lower hull the reactor and the racks (R255: IM5, one vessel)', type='hull',
         what='the broad wedge with the canyon cut down its spine: ridge decks, chamfered deck edges, upper facets, the flank band, lower facets, a chine, a flat belly; the canyon\'s floor, stepped walls and lips; the shoulder pits',
         count=1, cells=ALL_TOP + ALL_SIDE + ['bow/below', 'mid/below', 'stern/below'], reads='facets and chamfers round a vertical band (never a flat wall, R244), the canyon walls stepped by a ledge, the pit steps', src='picture'),
    dict(id='bow_face', job='the blunt armoured bow round the ion trench at the canyon\'s mouth: it meets fire head on (R183 (1))', type='hull',
         what='the blunt bow face, the ridge ends and the bow deck running to it, armour plates and a trim frame round the trench mouth', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='the facets running to an upright face, the ridge ends standing over the bow deck, plates round the mouth', src='picture'),
    dict(id='bridges', job='the three bridge decks tie the ridges across the canyon, carry the crew between them and seat the bridge turrets', type='tier',
         what='three low bridge decks flush with the ridge decks (bow, midships, stern), chamfered undersides, girders, a trim band and a blue strip on each face',
         count=1, cells=ALL_TOP, reads='a face with trim and a blue strip, a panelled roof flush with the decks, the canyon opening under it', src='picture'),
    dict(id='module_bands', job='the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them', type='band',
         what='six raised trim rings round the whole section, canyon included, with a deep double seam between their halves', count=1, cells=ALL_TOP + ALL_SIDE,
         reads='two trim rings and a dark seam ring between them', src='picture'),
    dict(id='blue_line', job='the implant-blue light strips: the fleet\'s running lights, pulsing in time (factions.md: a line of blue light)', type='band',
         what='a blue strip along each flank band, broken at the module bands, and one on each face of each bridge', count=1, cells=ALL_SIDE + ALL_TOP, reads='a raised strip that glows', src='picture'),
    dict(id='deck_panels', job='deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md)', type='plate', what='flush panels on the ridge decks, the pit floors, the bow and stern decks and the bridge roofs', count=1,
         cells=ALL_TOP, reads='machined slabs with seams round them, the small-module cells', src='picture'),
    dict(id='canyon_panels', job='the canyon\'s armour: the floor and the stepped walls that shield the plant', type='plate', what='flush panels on the canyon floor, its walls and ledges', count=1,
         cells=ALL_TOP, reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='flank_panels', job='side armour on the facets', type='plate', what='flush panels on the upper and lower facets', count=1, cells=ALL_SIDE,
         reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='flush panels on the belly and the belly armour step', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='machined slabs with seams', src='designed'),
    # ---------------- weapons (data.js h_boss: hturbo P, hturbo S, turbo T, ion F, flak T) ----------------
    dict(id='lances', job='the heavy plasma lances (hturbo P and hturbo S, 3 shots each): the main broadside fire, one turret a side', type='gun',
         what='two low wide lance turrets sunk in the shoulder pits, two short thick barrels each', count=2, cells=['mid/top', 'mid/side'],
         reads='a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores (R221)', src='picture'),
    dict(id='bridge_lance', job='the plasma lance (turbo T, 2 shots): all-round fire from the midships bridge', type='gun',
         what='the lance turret at a smaller size on the midships bridge, two barrels', count=1, cells=['mid/top'],
         reads='a flush ring, a faceted housing, a glacis, cheeks, a bustle, a mantlet, barrels with coil rings, shrouds, blue bores', src='picture'),
    dict(id='pickets', job='the picket lasers (flak T, 3 shots): point defence against craft over the stern', type='gun', what='one twin picket turret on the stern bridge',
         count=1, cells=['stern/top'], reads='a flush ring, an eight-sided housing, a sensor eye, two short emitters with coil collars and lens tips (R221)', src='picture'),
    dict(id='ion_trench', job='the ion cannon (ion F, 1 shot): strips shields head on (lore 3.4)', type='ion_trench', what='the emitter trench recessed in the blunt bow face at the canyon\'s mouth (R183 (1))',
         count=1, cells=['bow/top', 'bow/side'], reads='lined walls, stacked field coil plates, an emitter block, a blue lens, feed conduits', src='picture'),
    # ---------------- sensing, the drives ----------------
    dict(id='sensor_fin', job='the ship\'s sensors: the one low sensor fin (factions.md), on the bow deck', type='antenna', what='a low swept fin on the centreline of the bow deck',
         count=1, cells=['bow/top', 'bow/side'], reads='a root plinth, the fin, sensor windows, a lens strip, a trim band', src='picture'),
    dict(id='engines', job='the main drives: a flat row of six rectangular blue-white nozzles (factions.md)', type='engine', what='six nozzle pods in one row across the stern', count=6,
         cells=['stern/top', 'stern/side'], reads='a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands and panels (R244: an opening with depth)', src='picture'),
    dict(id='thrusters', job='retro thrusters on the bow face (lore 3.4: backing off is cheap) and attitude thrusters on the facets', type='thruster',
         what='rectangular nozzle blocks', count=6, cells=['bow/side', 'stern/side'], reads='a block, rectangular nozzles with depth', src='designed'),
    # ---------------- the canyon plant (issue 768: machinery with a job) ----------------
    dict(id='capbanks', job='the ion cannon\'s charge banks on the canyon floor, forward', type='capbank', what='two capacitor banks of identical cells', count=2,
         cells=['bow/top', 'mid/top'], reads='a plinth, identical cells, trim caps, blue charge strips, bus bars, terminals', src='picture'),
    dict(id='exchangers', job='the reactor\'s and the drives\' heat exchangers: their heat leaves the hull in the open canyon', type='exchanger', what='four heat exchangers on the canyon floor', count=4,
         cells=['mid/top', 'stern/top'], reads='a plinth, a housing, a stack of cooling fins in a frame, inlet and outlet ports', src='picture'),
    dict(id='trunks', job='armoured power trunks: the reactor\'s power forward to the ion cannon and aft to the drives', type='pipe', what='two trunks along the canyon floor, one length per module, coupled at the bands',
         count=10, cells=ALL_TOP, reads='an eight-sided trunk, trim collars, end flanges, saddles', src='picture'),
    dict(id='coolant_lines', job='coolant lines: the exchangers\' loops out to the ridges\' plant rooms, along the canyon\'s ledges', type='pipe', what='two lines along the ledges, one length per stretch between the bands and the bridges',
         count=14, cells=ALL_TOP, reads='a trunk, trim collars, end flanges, saddles', src='picture'),
    # ---------------- fittings ----------------
    dict(id='latches', job='lock the hull modules together across each module band', type='latch', what='rows of four clamp heads beside the bands on the ridge decks',
         count=24, cells=ALL_TOP, reads='a base plate, four machined clamps', src='designed'),
    dict(id='vents', job='heat louvres over the crew decks, the drive coolant plant and the engine room', type='vent',
         what='long louvres on the ridge decks and the stern deck', count=8, cells=ALL_TOP, reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='windows', job='blue-white windows of the ridges\' crew decks (lore 3.3)', type='slit', what='window slits on the flank band, and the engine room\'s control windows facing up the canyon', count=24,
         cells=ALL_SIDE, reads='a trim frame round a recessed pane', src='picture'),
    dict(id='hatches', job='crew and stores access: deck, belly and flank hatches', type='hatch', what='flush rectangular armoured hatches', count=9,
         cells=['bow/top', 'bow/below', 'mid/below', 'stern/below', 'bow/side', 'stern/side'], reads='a trim rim, a flush door, a seam, a recessed grip', src='picture'),
    dict(id='lift_heads', job='the stern lift head: stores up to the engine room', type='hatchbox', what='a low module housing on the stern deck', count=1, cells=['stern/top'],
         reads='a chamfered frame, an inset lid with a seam, a blue strip', src='designed'),
]
LEFT_PLAIN = [
    'IM5 has no side view and no underside view: the side and below cells have no concept picture to tick against, and the concept\'s length to height is not measured.',
    'IM5_top.jpg\'s own "IM5 TOP" label covers the bow tip, so the concept top view\'s length is measured short (to the label\'s edge); the bow is read from the three-quarter.',
    'The flank band carries only the blue line, the windows and the breach anchors: IM5 draws it as a plain band under the light strip.',
    'Stencil marks are paint, not modelled (the Hegemony stack, a later job).',
]
STRUCTURE = {'bow/top': 3, 'mid/top': 6, 'stern/top': 5}
STRUCTURE_NOTE = 'IM5 top view by eye: bow, the two ridge ends and the bow deck with the fin; midships, the two ridges, the canyon, the bow and midships bridges, the shoulder turrets; stern, the two ridges, the canyon, the stern bridge, the stern block with the nozzles; no side or underside view'
