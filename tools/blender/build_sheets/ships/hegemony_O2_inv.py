# hegemony_O2 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_hegemony_2026_11/convoy_sheet.webp (top view
# above, side view below left, the stern view below right; BOW ON THE LEFT in the top and side views) and convoy_beauty.webp
# (three-quarter from above, the bow lower left), PR 1168. designs.md "CONVOY TRANSPORT" governs counts (picture slips: the
# beauty draws three modules, the sheet four). The concept has no underside view.
# Fields: id, job, type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    dict(id='wedge', job='carries the bridge, the holds, the reactor and the drives: the plain wedge bow and the drive section', type='hull',
         what='a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band, lower facets, a chine, a flat belly', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='facets and chamfers round a vertical band (never a flat wall, R244)', src='picture'),
    dict(id='rails', job='the rails either side of the cargo well: the corridors and the air plant run in them', type='rail',
         what='the raised rail decks either side of the well', count=1, cells=['mid/top', 'mid/side'], reads='a deck edge, a chamfer, the blue strip on the band below', src='picture'),
    dict(id='cargo_well', job='holds the cargo modules: an open well between the rails, its floor over the lower holds', type='tier',
         what='the open well amidships, its end walls lipped', count=1, cells=['mid/top'], reads='a floor, end walls with trim lips, the opening', src='picture'),
    dict(id='bow_face', job='the solid armoured bumper: the bow meets a dock head on (designs.md: no trench, no gun)', type='hull',
         what='the wedge\'s blunt face with a bumper plate and trim', count=1, cells=['bow/top', 'bow/side'], reads='facets running to an upright face, a bumper slab, trim bars', src='picture'),
    dict(id='docking_clamps', job='mate the transport to a station or a tug', type='latch', what='two clamp rows on the bumper', count=2, cells=['bow/side'],
         reads='a base plate, machined clamp heads', src='picture'),
    dict(id='cargo', job='the cargo: the thing the convoy carries (designs.md: four identical container modules)', type='container',
         what='four identical cargo modules in a row in the well', count=4, cells=['mid/top', 'mid/side', 'stern/top', 'stern/side'],
         reads='a plain slab box, an inset lid with a seam, stiffener ribs, corner castings, mooring clamps', src='picture'),
    dict(id='mooring', job='hold each module\'s lifting eyes on the rail decks', type='latch', what='a clamp pair beside each module, both rails', count=8,
         cells=['mid/top'], reads='a base plate, machined clamp heads', src='picture'),
    dict(id='module_bands', job='the joints between hull modules: the hull gives way here; the breach anchors sit on them', type='band',
         what='raised trim rings with a deep seam at 28, 50 and 72 percent', count=1, cells=ALL_TOP + ALL_SIDE, reads='two trim rings and a dark seam ring', src='picture'),
    dict(id='blue_line', job='the implant-blue running lights along the flanks (factions.md: a line of blue light)', type='band',
         what='a blue strip along each flank band, broken at the bands', count=1, cells=ALL_SIDE, reads='a raised strip that glows', src='picture'),
    dict(id='sensor_fin', job='navigation and the convoy link to its escorts', type='antenna', what='one low sensor fin on the bow deck ahead of the well', count=1,
         cells=['bow/top', 'bow/side'], reads='a root plinth, a raked fin, sensor windows, a lens strip', src='picture'),
    dict(id='engines', job='drive: four rectangular nozzle pods in one flat row', type='engine', what='four nozzle pods at the stern', count=4,
         cells=['stern/top', 'stern/side'], reads='a housing, a thick lip, a lining, a glowing throat, guide vanes, trim bands', src='picture'),
    dict(id='deck_panels', job='deck armour: flush panels in the even grid', type='plate', what='flush deck panels on the bow deck, the rail decks and the drive deck',
         count=1, cells=['bow/top', 'mid/top', 'stern/top'], reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='flank_panels', job='side armour on the facets', type='plate', what='flush panels on the upper and lower facets', count=1, cells=ALL_SIDE,
         reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='belly_panels', job='belly armour', type='plate', what='flush panels on the belly and the armour step', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='machined slabs with seams', src='designed'),
    dict(id='windows', job='the crew deck\'s blue-white windows (lore 3.3)', type='slit', what='three window slits each side forward', count=6, cells=['bow/side'],
         reads='a machined frame round a recessed pane', src='picture'),
    dict(id='vents', job='the reactor\'s and the holds\' air and heat louvres', type='vent', what='louvres on the drive deck and the rail decks', count=10,
         cells=['mid/top', 'stern/top'], reads='a machined frame, straight slats over a dark recess', src='picture'),
    dict(id='hatches', job='crew and stores access', type='hatch', what='flank hatches on the band, deck hatches, a belly hatch', count=11,
         cells=['bow/top', 'mid/side', 'stern/top', 'mid/below'], reads='a rim, a flush door, a seam, a grip', src='designed'),
    dict(id='thrusters', job='braking into a dock and attitude control', type='thruster', what='two retro thrusters on the bow face, two attitude thrusters aft', count=4,
         cells=['bow/side', 'stern/side'], reads='a machined block, rectangular nozzle throats with depth', src='designed'),
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 5, 'mid/side': 5, 'stern/top': 4, 'stern/side': 3}
STRUCTURE_NOTE = ('Convoy sheet: bow, the wedge and the fin; midships, the rails and the modules; stern, the last modules, the drive block and the nozzle pods')
LEFT_PLAIN = [
    'Stencil marks and the steel-blue trim tone: paint (the Hegemony stack), not modelled.',
    'The beauty\'s three modules: designs.md tables four.',
]
INV_NOTES = {}
