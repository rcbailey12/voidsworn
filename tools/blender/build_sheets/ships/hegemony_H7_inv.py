# hegemony_H7 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_hegemony_2026_11/picket_sheet.webp and
# picket_beauty.webp, Muse run 3 (PR 1707; copies in docs/ship_pipeline/build_sheets/hegemony_H7/concept_*.jpg): the sheet's
# three-quarter view upper left (bow lower left), port side view below it (BOW ON THE LEFT), top view on the right (BOW AT THE
# TOP); the beauty three-quarter from above the port bow. designs.md "PICKET" governs where a picture differs. Ryan, Nov 22
# 2026: "Agree with picket changes", and the speedboat keel goes: a flat worked belly (issue 1412).
# Fields: id, job, type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    # ---------------- the hull ----------------
    dict(id='dart', job='the whole ship: one solid dart that carries the casemate, the barbette, the crew decks and the drives (designs.md: the only escort with no rails)', type='hull',
         what='a single solid body: a blunt bow face, straight flanks out to the widest point at 58 percent, closing to a flat stern transom; a flat deck, chamfered deck edges, upper facets, the flank band, short lower facets, a flat belly',
         count=1, cells=ALL_TOP + ALL_SIDE, reads='facets and chamfers round a vertical band (never a flat wall, R244), the stern chamfer in the top line', src='picture'),
    dict(id='bow_face', job='the blunt armoured bow round the casemate (R183 (1)): it meets fire head on', type='hull', what='the blunt bow face, chamfered corners, armour plates round the casemate mouth',
         count=1, cells=['bow/top', 'bow/side'], reads='the dart\'s facets running to an upright face, plates round the mouth', src='picture'),
    dict(id='belly_step', job='belly armour: Ryan\'s flat worked belly in place of the concept\'s V keel', type='hull', what='a flat belly with a second armour layer, stepped at its edges',
         count=1, cells=['mid/side'], reads='a flat plate, a step round it, panels and hatches on it', src='designed'),
    dict(id='module_bands', job='the bulkhead rings between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them', type='band',
         what='two raised trim rings with a deep seam, at 35 and 70 percent', count=1, cells=ALL_TOP + ALL_SIDE, reads='two trim rings and a dark seam ring between them', src='picture'),
    dict(id='blue_line', job='the implant-blue running lights (factions.md: a line of blue light)', type='band',
         what='a blue strip along each flank band, broken at the module bands', count=1, cells=ALL_SIDE, reads='a raised strip that glows', src='picture'),
    dict(id='deck_panels', job='deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md)', type='plate', what='flush deck panels', count=1,
         cells=ALL_TOP, reads='machined slabs with seams round them, the small-module cells', src='picture'),
    dict(id='flank_panels', job='side armour on the facets', type='plate', what='flush panels on the upper and lower facets', count=1, cells=ALL_SIDE,
         reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='flush panels on the flat belly and its armour step', count=1, cells=['mid/side'],
         reads='machined slabs with seams', src='designed'),
    # ---------------- weapons (godot/rules/data/tables.json h_picket: laser F, flak T) ----------------
    dict(id='casemate', job='the Plasma cannon (laser F, 2 shots): the Picket\'s forward gun', type='gun',
         what='a low casemate inside the bow face, two short thick barrels side by side, recessed so they barely protrude (never the ion trench)', count=1, cells=['bow/top', 'bow/side'],
         reads='a lined recess, a trim frame, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores', src='picture'),
    dict(id='barbette', job='the Picket lasers (flak T, 3 shots): point defence all round', type='gun', what='one low faceted dorsal barbette, three short emitters',
         count=1, cells=['mid/top'], reads='a faceted plinth, a flush ring, an eight-sided housing, a sensor eye, three emitters with coil collars and lens tips', src='picture'),
    # ---------------- sensing, the drives ----------------
    dict(id='sensor_fin', job='the ship\'s sensors: the one low sensor fin (factions.md)', type='antenna', what='a low swept fin on the centreline, forward of the barbette',
         count=1, cells=['bow/top', 'bow/side'], reads='a root plinth, the fin, sensor windows, a lens strip, a trim band', src='picture'),
    dict(id='engines', job='the main drives: two rectangular blue-white nozzles in one flat row (designs.md)', type='engine', what='two nozzle pods in the stern block', count=2,
         cells=['stern/top', 'stern/side'], reads='a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands (R244: an opening with depth)', src='picture'),
    dict(id='thrusters', job='retro thrusters on the bow face (lore 3.4: backing off is cheap; ability evasive) and attitude thrusters on the facets', type='thruster',
         what='rectangular nozzle blocks', count=6, cells=['bow/side', 'stern/side'], reads='a block, rectangular nozzles with depth', src='picture'),
    dict(id='drone_doors', job='the faction\'s small drone bays (designs.md: flush flank doors only; no hangar in the rules, so no craft fly)', type='bay',
         what='flush armoured doors on each flank band aft', count=2, cells=['stern/side'], reads='a trim frame, two door leaves with ribs, the centre seam, blue guide lamps', src='picture'),
    # ---------------- fittings ----------------
    dict(id='latches', job='lock the hull modules together across each module band', type='latch', what='rows of clamp heads beside the bands',
         count=8, cells=ALL_TOP, reads='a base plate, machined clamps', src='designed'),
    dict(id='vents', job='heat louvres over the cannon\'s capacitors, the reactor and the engine room', type='vent',
         what='long louvres on the deck and the belly', count=8, cells=ALL_TOP + ['mid/side'], reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='windows', job='blue-white windows of the crew deck (lore 3.3)', type='slit', what='window slits on the flank band aft', count=4,
         cells=['stern/side'], reads='a trim frame round a recessed pane', src='picture'),
    dict(id='hatches', job='crew and stores access: deck, belly and flank hatches', type='hatch', what='flush rectangular armoured hatches', count=8,
         cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'], reads='a trim rim, a flush door, a seam, a recessed grip', src='picture'),
]
LEFT_PLAIN = [
    'The flank band carries only the blue line, the windows, the drone doors and the breach anchors.',
    'The concept\'s scattered surface greebles are not built one for one: the even Navy panel grid and the fittings with a job stand in for them (R221).',
    'Stencil marks are paint, not modelled (the Hegemony stack).',
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 3, 'mid/side': 2, 'stern/top': 2, 'stern/side': 3}
STRUCTURE_NOTE = 'Picket run 3: bow, the blunt face and the casemate; midships, the dart\'s widest part, the fin and the barbette; stern, the chamfer, the transom and the two nozzle pods'
