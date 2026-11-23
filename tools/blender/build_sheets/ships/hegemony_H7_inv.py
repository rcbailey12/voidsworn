# hegemony_H7 parts inventory (R218), version 2: the merged Picket (Ryan, Nov 23 2026, R442): Astra's blind hull
# (contrib/codex/picket_astra_1122, PR 1745) with the Opus fittings on it. Read from
# contrib/muse/design/class_family_hegemony_2026_11/picket_sheet.webp and picket_beauty.webp, Muse run 3 (PR 1707; copies in
# docs/ship_pipeline/build_sheets/hegemony_H7/concept_*.jpg), plus what the designers add with its job (R221). designs.md
# "PICKET" governs where a picture differs; Ryan, Nov 22 2026: the speedboat keel goes, a flat worked belly (issue 1412).
# Fields: id, job, type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    # ---------------- the hull (Astra) ----------------
    dict(id='dart', job='the whole ship: one long tapering dart that carries the casemate, the barbette, the crew decks and the drives (designs.md: the only escort with no rails)', type='hull',
         what='nine lofted cross-sections: a clipped nose, broad aft shoulders, a flat deck, one broad upper bevel, the flank band, a lower bevel, a chine and a flat sole; three modules',
         count=1, cells=ALL_TOP + ALL_SIDE, reads='bevels round a vertical band (never a flat wall, R244), the taper in plan', src='picture'),
    dict(id='bow_face', job='the blunt armoured bow round the casemate (R183 (1)): it meets fire head on', type='hull', what='the blunt gun face with cheek webs, a sill and a lintel round the mouth, armour plates above and below it',
         count=1, cells=['bow/top', 'bow/side'], reads='the dart\'s bevels running to an upright face, plates round the mouth', src='picture'),
    dict(id='belly_floor', job='Ryan\'s flat worked belly in place of the concept\'s V keel: the service trunk', type='hull', what='five removable centreline covers with paired runners along the flat sole',
         count=1, cells=['mid/side'], reads='a flat sole, bolted covers and runners on it', src='designed'),
    dict(id='module_bands', job='the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them', type='band',
         what='two collars, each a pair of trim rings round a dark seam, at 27 and 74 percent from the stern', count=1, cells=ALL_TOP + ALL_SIDE, reads='two trim rings and a dark seam ring between them', src='picture'),
    dict(id='blue_line', job='the implant-blue running lights (factions.md: a line of blue light)', type='band',
         what='a trim race with a blue light along each flank band, broken at the joints and the boarding doors', count=1, cells=ALL_SIDE, reads='a raised strip that glows', src='picture'),
    dict(id='deck_panels', job='deck armour: module plates with deep plate-line cuts (R443)', type='plate', what='deck plates in two module sizes', count=1,
         cells=ALL_TOP, reads='machined slabs with deep seams round them', src='picture'),
    dict(id='flank_panels', job='side armour on the bevels and the chines', type='plate', what='plates on the upper and lower bevels and the chines', count=1, cells=ALL_SIDE,
         reads='machined slabs with deep seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='plates on the flat sole either side of the service trunk', count=1, cells=['mid/side'],
         reads='machined slabs with deep seams', src='designed'),
    # ---------------- weapons (godot/rules/data/tables.json h_picket: laser F, flak T) ----------------
    dict(id='casemate', job='the Plasma cannon (laser F, 2 shots): the Picket\'s forward gun', type='gun',
         what='a fixed casemate inside the bow face, two short bores side by side, recessed so they barely protrude (never the ion trench)', count=1, cells=['bow/top', 'bow/side'],
         reads='a lined recess, a trim frame, a mantlet, breeches, barrels with coil rings, muzzles, blue-lit bores', src='picture'),
    dict(id='barbette', job='the Picket lasers (flak T, 3 shots): point defence all round', type='gun', what='one low dorsal turret on an eight-sided plinth, three short emitters',
         count=1, cells=['mid/top'], reads='a faceted plinth, a flush ring, a faceted housing, three emitters with coil collars', src='picture'),
    # ---------------- sensing, the drives ----------------
    dict(id='sensor_fin', job='the ship\'s sensors: one low swept receiver (factions.md)', type='antenna', what='a low swept receiver on the centreline, ahead of the barbette',
         count=1, cells=['bow/top', 'bow/side'], reads='a root plinth, the fin, sensor windows, a lens strip', src='picture'),
    dict(id='engines', job='the main drives: two rectangular blue-white nozzles in one flat row (designs.md)', type='engine', what='two nozzle pods seated in the stern', count=2,
         cells=['stern/top', 'stern/side'], reads='a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands (R244: an opening with depth)', src='picture'),
    dict(id='coolers', job='heat rejection for the reactor and the drives (Astra: the radiator grills Ryan picked, R442)', type='vent',
         what='slatted cooler cassettes on the belly, five a side', count=10, cells=['mid/side'], reads='a machined frame, straight slats over a dark recess', src='designed'),
    dict(id='thrusters', job='retro thrusters on the bow face (lore 3.4: backing off is cheap; ability evasive) and attitude thrusters on the bevels', type='thruster',
         what='rectangular nozzle blocks', count=6, cells=['bow/side', 'stern/side'], reads='a block, rectangular nozzles with depth', src='designed'),
    dict(id='drone_doors', job='the faction\'s small drone bays (designs.md: flush flank doors only; no hangar in the rules, so no craft fly)', type='bay',
         what='flush armoured doors on each upper bevel aft', count=2, cells=['stern/side'], reads='a trim frame, two door leaves with ribs, the centre seam, blue guide lamps', src='picture'),
    # ---------------- fittings ----------------
    dict(id='latches', job='lock the hull modules together across each joint', type='latch', what='rows of clamp heads beside the joints',
         count=8, cells=ALL_TOP, reads='a base plate, machined clamps', src='designed'),
    dict(id='vents', job='heat louvres over the drive feeds and the cannon\'s capacitors', type='vent',
         what='louvres on the deck', count=4, cells=ALL_TOP, reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='windows', job='blue-white windows of the crew decks (lore 3.3)', type='slit', what='window slits low on the upper bevels', count=8,
         cells=['bow/side', 'mid/side'], reads='a trim frame round a recessed pane', src='designed'),
    dict(id='hatches', job='crew access: deck hatches and the boarding doors at the waist', type='hatch', what='flush rectangular armoured hatches', count=5,
         cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'], reads='a trim rim, a flush door, a seam, a recessed grip', src='picture'),
]
LEFT_PLAIN = [
    'The flank band carries only the light race, the boarding doors and the breach anchors.',
    'The concept\'s scattered surface greebles are not built one for one: the deep-cut module plates and the fittings with a job stand in for them (R221).',
    'Stencil marks are paint, not modelled (the Hegemony stack).',
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 3, 'mid/side': 2, 'stern/top': 2, 'stern/side': 2}
STRUCTURE_NOTE = 'Picket, merged build: bow, the clipped nose, the gun face and the casemate; midships, the broad shoulders, the receiver and the barbette; stern, the taper in and the two nozzle pods'
