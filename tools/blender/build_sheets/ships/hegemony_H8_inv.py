# hegemony_H8 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_hegemony_2026_11/cordon_sheet.webp and
# cordon_beauty.webp, Muse run 3 (PR 1707; copies in docs/ship_pipeline/build_sheets/hegemony_H8/concept_*.jpg): the sheet's
# three-quarter view upper left (bow left), port side view below it (BOW ON THE LEFT), top view on the right (BOW AT THE TOP);
# the beauty three-quarter from above the port bow. designs.md "CORDON" is the table; Ryan took the Cordon Nov 22 2026.
# Fields: id, job, type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    # ---------------- the hull masses ----------------
    dict(id='ion_block', job='the deep forward block: it carries the ion cannon, its capacitors, the command deck and the lance turret (designs.md: the anvil)', type='hull',
         what='slab sides at the full beam, deep; a flat deck, chamfered deck edges, upper facets, a tall flank band in two tiers, lower facets, a flat belly; the bow corners chamfered in plan',
         count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'], reads='facets and chamfers round a vertical band (never a flat wall, R244), the two-tier band', src='picture'),
    dict(id='bow_face', job='the blunt armoured bow round the ion trench (R183 (1))', type='hull', what='the blunt bow face, chamfered corners, armour plates and a trim frame round the trench mouth',
         count=1, cells=['bow/top', 'bow/side'], reads='the block\'s facets running to an upright face, plates round the mouth', src='picture'),
    dict(id='step', job='the hard step between the ion block and the aft body: plan and profile step in the same transverse face (designs.md)', type='hull',
         what='the ion block\'s aft face, the aft body set in 0.65 a side and its deck dropped', count=1, cells=['mid/top', 'mid/side'], reads='a flat transverse face, its edges chamfered', src='picture'),
    dict(id='aft_body', job='the narrower aft body: crew decks, plant rooms and the drives', type='hull',
         what='one narrower hull, sides parallel to a flat stern transom; the same faceted section, one flank band', count=1,
         cells=['mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='facets and chamfers round a vertical band', src='picture'),
    dict(id='module_bands', job='the bulkhead rings between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them', type='band',
         what='raised trim rings with a deep seam: one on the ion block, the step itself, one on the aft body', count=1, cells=ALL_TOP + ALL_SIDE,
         reads='two trim rings and a dark seam ring between them', src='picture'),
    dict(id='blue_line', job='the implant-blue running lights (factions.md)', type='band', what='blue strips along the flank bands, two rows on the ion block, one on the aft body',
         count=1, cells=ALL_SIDE, reads='a raised strip that glows', src='picture'),
    dict(id='deck_panels', job='deck armour in the even grid of two module sizes', type='plate', what='flush deck panels', count=1, cells=ALL_TOP,
         reads='machined slabs with seams, the small-module cells', src='picture'),
    dict(id='flank_panels', job='side armour on the facets', type='plate', what='flush panels on the upper and lower facets', count=1, cells=ALL_SIDE,
         reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='flush panels on the belly and its armour step', count=1, cells=['bow/side', 'mid/side'],
         reads='machined slabs with seams', src='designed'),
    # ---------------- weapons (godot/rules/data/tables.json h_interdictor: ion F, turbo T) ----------------
    dict(id='ion_trench', job='the ion cannon (ion F, 1 shot): strips shields head on; the Cordon\'s ionpulse', type='ion_trench',
         what='the emitter trench recessed in the blunt bow face, about 1.1 by 0.6, three stepped capacitor rings, a blue lens, an inset lip', count=1,
         cells=['bow/top', 'bow/side'], reads='lined walls, stepped capacitor rings, an emitter block, a blue lens, an inner glow', src='picture'),
    dict(id='lance', job='the Plasma lance (turbo T, 2 shots): one low turret on the centreline', type='gun',
         what='one low wide lance turret, two short thick barrels', count=1, cells=['mid/top'],
         reads='a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented shrouds, blue-lit bores', src='picture'),
    # ---------------- sensing, the drives ----------------
    dict(id='sensor_fin', job='the ship\'s sensors: one low sensor fin, aft of the step so it clears the lance\'s fire (designs.md)', type='antenna',
         what='a low swept fin on the aft body\'s centreline', count=1, cells=['mid/top', 'mid/side'], reads='a root plinth, the fin, sensor windows, a lens strip, a trim band', src='picture'),
    dict(id='engines', job='the main drives: two rectangular blue-white nozzles in one flat row (designs.md; the top view\'s third pod is a slip)', type='engine',
         what='two nozzle pods on the aft transom', count=2, cells=['stern/top', 'stern/side'], reads='a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands', src='picture'),
    dict(id='thrusters', job='retro thrusters on the bow face corners (the concept\'s four small blocks there) and attitude thrusters on the facets', type='thruster',
         what='rectangular nozzle blocks', count=8, cells=['bow/side', 'stern/side'], reads='a block, rectangular nozzles with depth', src='picture'),
    dict(id='drone_doors', job='the faction\'s small drone bays (designs.md: flush flank doors only; no hangar in the rules, so no craft fly)', type='bay',
         what='flush armoured doors on the aft body\'s upper facets', count=2, cells=['stern/side'], reads='a trim frame, two door leaves with ribs, the centre seam, blue guide lamps', src='picture'),
    # ---------------- fittings ----------------
    dict(id='latches', job='lock the hull modules together across each module band', type='latch', what='rows of clamp heads beside the bands', count=8, cells=ALL_TOP,
         reads='a base plate, machined clamps', src='picture'),
    dict(id='vents', job='heat louvres over the ion capacitors, the reactor and the engine room (the concept\'s many ladder louvres)', type='vent',
         what='long louvres on the decks', count=10, cells=ALL_TOP, reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='windows', job='blue-white windows of the crew decks (lore 3.3)', type='slit', what='window slits on the flank bands', count=8,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a trim frame round a recessed pane', src='picture'),
    dict(id='hatches', job='crew and stores access: deck, belly and flank hatches', type='hatch', what='flush rectangular armoured hatches', count=8,
         cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'], reads='a trim rim, a flush door, a seam, a recessed grip', src='picture'),
]
LEFT_PLAIN = [
    'The flank bands carry only the blue lines, the windows and the breach anchors.',
    'The concept\'s scattered greebles are not built one for one: the even Navy panel grid and the fittings with a job stand in for them (R221).',
    'Stencil marks are paint, not modelled (the Hegemony stack).',
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 4, 'mid/side': 3, 'stern/top': 2, 'stern/side': 3}
STRUCTURE_NOTE = 'Cordon run 3: bow, the deep ion block and the trench; midships, the lance turret, the step, the fin on the aft body; stern, the aft body, the transom and the two nozzle pods'
