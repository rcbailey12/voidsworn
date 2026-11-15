# hegemony_H10 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg (top view
# above, side view below, BOW ON THE RIGHT in both) and hegemony_H10_beauty.jpg (three-quarter from above and aft of the port
# beam, the bow lower right; the small ship lower left is an escort, not this hull). The concept has no underside view.
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    # ---------------- the hull masses ----------------
    dict(id='wedge', job='carries the bow, the shoulder turrets, the command deck, the reactor and the lance rooms (factions.md: a heavy thick wedge)', type='hull',
         what='the wedge: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band, lower facets, a chine, a flat belly; the shoulder terraces',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below'], reads='facets and chamfers round a vertical band (never a flat wall, R244), the terrace steps', src='picture'),
    dict(id='bow_face', job='the blunt armoured bow round the ion trench: it meets fire head on (R183 (1))', type='hull', what='the blunt bow face, chamfered corners, armour plates and a trim frame round the trench mouth',
         count=1, cells=['bow/top', 'bow/side', 'bow/below'], reads='the wedge\'s facets running to an upright face, plates round the mouth', src='picture'),
    dict(id='rails', job='the twin rails: they carry the crew decks, the plant rooms and the drives (factions.md: a wedge on twin rails)', type='rail',
         what='two chamfered rail blocks in two module tiers (a recessed band at mid height), a gap between them', count=1,
         cells=['mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'], reads='chamfered edges, the mid-height recess, the blue strip in it', src='picture'),
    dict(id='bay_block', job='the drone hangar between the rails (data.js hangar 1)', type='tier', what='the hangar block between the rails\' roots, its roof a trough below the rail decks',
         count=1, cells=['mid/top'], reads='a face, a roof with the doors, the trough opening', src='picture'),
    dict(id='module_bands', job='the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them', type='band',
         what='raised trim rings round the wedge and the rails with a deep double seam between their halves', count=1, cells=ALL_TOP + ALL_SIDE,
         reads='two trim rings and a dark seam ring between them', src='picture'),
    dict(id='blue_line', job='the implant-blue light strips: the fleet\'s running lights, pulsing in time (factions.md: a line of blue light)', type='band',
         what='a blue strip along each flank band and in each rail\'s recess, broken at the module bands', count=1, cells=ALL_SIDE, reads='a raised strip that glows', src='picture'),
    dict(id='deck_panels', job='deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md)', type='plate', what='flush deck panels on the wedge and the terraces', count=1,
         cells=['bow/top', 'mid/top'], reads='machined slabs with seams round them, the small-module cells', src='picture'),
    dict(id='flank_panels', job='side armour on the wedge\'s facets', type='plate', what='flush panels on the upper and lower facets', count=1, cells=['bow/side', 'mid/side'],
         reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='flush panels on the belly and the belly armour step', count=1, cells=['bow/below', 'mid/below'],
         reads='machined slabs with seams', src='designed'),
    dict(id='rail_panels', job='the rails\' armour', type='plate', what='flush panels on the rails\' decks, flanks and bellies', count=1,
         cells=['mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'], reads='machined slabs with seams, two module sizes', src='picture'),
    # ---------------- weapons (data.js h_dominion: hturbo P, hturbo S, ion F, flak T) ----------------
    dict(id='lances', job='the heavy plasma lances (hturbo P and hturbo S, 3 shots each): the main broadside fire, one turret a side', type='gun',
         what='two low wide lance turrets sunk in the shoulder terraces, two short thick barrels each', count=2, cells=['mid/top', 'mid/side'],
         reads='a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores (R221)', src='picture'),
    dict(id='ion_trench', job='the ion cannon (ion F, 1 shot): strips shields head on (lore 3.4)', type='ion_trench', what='the emitter trench recessed in the blunt bow face (R183 (1))',
         count=1, cells=['bow/top', 'bow/side'], reads='lined walls, stacked field coil plates, an emitter block, a blue lens, feed conduits', src='picture'),
    dict(id='pickets', job='the picket lasers (flak T, 3 shots): point defence against craft from below', type='gun', what='two small twin turrets on the belly armour step',
         count=2, cells=['bow/below'], reads='a flush ring, an eight-sided housing, a sensor eye, two short emitters with coil collars and lens tips (R221)', src='designed'),
    # ---------------- sensing, the bay, the drives ----------------
    dict(id='sensor_fin', job='the ship\'s sensors: the one low sensor fin (factions.md), over the command deck', type='antenna', what='a low swept fin on the centreline between the turrets',
         count=1, cells=['mid/top', 'mid/side'], reads='a root plinth, the fin, sensor windows, a lens strip, a trim band', src='picture'),
    dict(id='bay', job='launches the drone escorts (data.js hangar 1, ability launch)', type='bay', what='flush armoured drone doors in the trough between the rails (R232)', count=1,
         cells=['mid/top'], reads='a trim frame, two door leaves with ribs, the centre seam, blue guide lamps', src='picture'),
    dict(id='engines', job='the main drives: a flat row of four rectangular blue-white nozzles (factions.md)', type='engine', what='four nozzle pods, two a rail', count=4,
         cells=['stern/top', 'stern/side'], reads='a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands and panels (R244: an opening with depth)', src='picture'),
    dict(id='thrusters', job='retro thrusters on the bow face (lore 3.4: backing off is cheap) and attitude thrusters on the facets and rails', type='thruster',
         what='rectangular nozzle blocks', count=6, cells=['bow/side', 'stern/side'], reads='a block, rectangular nozzles with depth', src='designed'),
    # ---------------- fittings ----------------
    dict(id='latches', job='lock the hull modules together across each module band (H10\'s rows of four blocks)', type='latch', what='rows of four clamp heads beside the bands',
         count=20, cells=ALL_TOP, reads='a base plate, four machined clamps', src='picture'),
    dict(id='vents', job='heat louvres over the lance capacitor rooms, the reactor, the crew decks and the engine rooms (H10\'s long slots)', type='vent',
         what='long louvres on the decks and the rails\' upper tiers', count=16, cells=ALL_TOP + ['mid/side', 'stern/side'], reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='windows', job='blue-white windows of the crew decks (lore 3.3)', type='slit', what='window slits on the flank band and the rails\' lower tier', count=10,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a trim frame round a recessed pane', src='picture'),
    dict(id='hatches', job='crew and stores access: deck, belly and flank hatches', type='hatch', what='flush rectangular armoured hatches', count=16,
         cells=['bow/top', 'mid/top', 'mid/below', 'stern/below', 'mid/side', 'stern/side'], reads='a trim rim, a flush door, a seam, a recessed grip', src='picture'),
    dict(id='lift_heads', job='the bow lift head: stores up to the forward decks', type='hatchbox', what='a low module housing on the deck', count=1, cells=['bow/top'],
         reads='a chamfered frame, an inset lid with a seam, a blue strip', src='designed'),
]
LEFT_PLAIN = [
    'The flank band carries only the blue line, the windows and the breach anchors: H10 draws it as a plain band under the light strip.',
    'Stencil marks (H10\'s "HD-14", "SECTION") are paint, not modelled (the Hegemony stack, a later job).',
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 5, 'mid/side': 4, 'stern/top': 3, 'stern/side': 3}
STRUCTURE_NOTE = 'H10 sheet: bow, the wedge and its bow face; midships, the wedge, the two turret bays, the rails\' roots and the bay with its two boxes; stern, the two rails and the nozzle pods; no underside view'
