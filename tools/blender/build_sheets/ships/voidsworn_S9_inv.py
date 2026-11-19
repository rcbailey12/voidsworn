# voidsworn_S9 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_sunward_2026_11/warden_sheet.webp (top view
# above, side view below left, front view below right; BOW ON THE LEFT in the top and side views) and warden_beauty.webp
# (three-quarter from above, the bow lower left). designs.md "Warden" governs counts (picture slips: four tubs drawn, one pair
# tabled; four spires drawn, three tabled). The concept has no underside view.
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (prow tip to 33 percent): the spearhead and the bow gun ----------------
    dict(id='spearhead', job='the blade\'s point and its forward armour: the knife the frigate leads with (factions.md: a black iron blade)', type='hull',
         what='the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, a raised centre ridge, a layer of cheek plates', src='picture'),
    dict(id='bow_plates', job='armour over the spearhead: forged plates in sleek triangles (R243)', type='plate', what='cheek plates and the bow facets\' plating', count=1,
         cells=['bow/top', 'bow/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='bow_gun', job='the Sear repeater (autocannon F, 3 shots): the frigate\'s main gun, fixed forward', type='gun',
         what='a compact forged casemate at the spearhead root, station 14 percent, a three-barrel rotary cluster', count=1, cells=['bow/top', 'bow/side'],
         reads='a riveted footing, an armoured housing with cheek plates and a sloped glacis, a round port collar, a ball mantlet, a heat jacket, clamp bands, three barrels, a muzzle ring, dark bores with ember lenses', src='picture'),
    dict(id='casemate', job='the bow gun\'s housing on the deck', type='tier', what='the casemate block (its face, roof and the port opening)', count=1,
         cells=['bow/top', 'bow/side'], reads='a face, a stepped roof, the port opening', src='picture'),
    dict(id='blade', job='carries everything: the crew deck, the magazines, the reactor and the drives', type='hull', what='the narrow faceted hull: a crowned deck, upper facets sloping out to the knuckle, the plated band, lower facets, a flat worked belly; widest at the stern third',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine', src='picture'),
    dict(id='deck_plates', job='deck armour over the crew deck and the magazines', type='plate', what='ordered rows of forged plates over the deck', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flank_plates', job='side armour: the facets and the band', type='plate', what='ordered rows of forged plates over the facets and the band', count=1,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belly_plates', job='belly armour', type='plate', what='forged plates over the belly and the armour step', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='trunk', job='the dorsal power trunk: armoured conduits from the reactor to the bow gun', type='spine', what='a low banded trunk along the deck\'s centreline (the concept\'s long centre rail)',
         count=1, cells=['bow/top', 'mid/top'], reads='a stepped block with bands across it', src='picture'),
    # ---------------- midships (33 to 66 percent): the plated band and the flak pair ----------------
    dict(id='gun_deck', job='the hull\'s armoured belt: the plated band with its lips (no ports: no broadside slot)', type='belt', what='the plated band with its upper and lower lips, both flanks',
         count=1, cells=['mid/side', 'mid/top'], reads='a band along the hull with angled ends, plates on it', src='picture'),
    dict(id='band_louvres', job='heat louvres in the band: the crew spaces and the magazines breathe out here', type='vent', what='louvres in the plated band, four a side', count=8,
         cells=['mid/side', 'stern/side'], reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the concept\'s lit marks along the band'),
    dict(id='flak', job='the spark flak (flak T, 3 shots): point defence against craft', type='gun', what='two low drum turrets on tubs at the deck edges, two barrels each, station 60 percent', count=2,
         cells=['mid/top', 'mid/side'], reads='a riveted ring, a squat forged drum, a cradle, two ammunition drums, slotted cooling sleeves, squared muzzle brakes (R221)', src='picture'),
    dict(id='barbettes', job='the flak tubs: they carry the turret rings at the deck edges', type='tier', what='low forged tubs under the two flak turrets', count=1,
         cells=['mid/top', 'mid/side'], reads='a face, a roof that takes the ring, the ring opening', src='picture'),
    dict(id='hatches', job='crew and stores access: deck hatches and belly hatches', type='hatch', what='forged round hatches on the deck and the belly step', count=4,
         cells=['bow/top', 'mid/below'], reads='a studded rim, a door with a bar, a seam, hinges', src='designed'),
    # ---------------- stern (66 to 100 percent): the spire line and the engines ----------------
    dict(id='spine', job='the spire line\'s base: it carries the spires and the command deck\'s windows, and snaps off with the spires (B-3)', type='spine',
         what='the forged spine block along the centreline aft, its forward face', count=1, cells=['stern/top', 'stern/side', 'mid/top'], reads='a chamfered block, a stepped face, the window slits', src='picture'),
    dict(id='spine_plates', job='armour over the spine block', type='plate', what='forged plates over the spine block', count=1, cells=['stern/top', 'stern/side'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='bridge_slits', job='the command deck\'s windows (factions.md: ember windows)', type='slit', what='three ember slits in the spine block\'s forward face', count=3,
         cells=['mid/top', 'stern/top'], reads='a forged frame round a recessed ember pane, a brow', src='picture', note='the concept\'s lit spine block face'),
    dict(id='spires', job='shed the reactor\'s heat (lore 2.5): the ember radiator spires, smaller per R331', type='radiator',
         what='three radiator spires along the spine block, the middle one tallest (0.65), three profiles (raked, stepped, blade)', count=3,
         cells=['stern/top', 'stern/side'], reads='a forged root socket, a column (iron posts fore and aft round a glowing core), a stack of horizontal iron fins with the ember in the slats between, a forged cap, gusset braces',
         src='picture'),
    dict(id='vents', job='reactor heat louvres over the reactor room', type='vent', what='heat louvres on the upper facets aft', count=4, cells=['stern/side', 'stern/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='designed'),
    dict(id='engines', job='drive (sp 5, the fastest Sunward hull): two ember bells, deep-set', type='engine', what='two engine bells 0.55 across on riveted drums', count=2,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a 16-sided drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='thrusters', job='attitude control at the bow and the stern (tn 3: the frigate turns its bow gun onto targets)', type='thruster', what='attitude thrusters on the upper facets, two forward and two aft', count=4,
         cells=['bow/side', 'stern/side'], reads='a forged block, round nozzle throats with depth (R244)', src='designed'),
    dict(id='lamps', job='frost-white running points on the blade\'s edge (paint direction sunward.md 5)', type='lamp', what='small frost lamps along the knuckle forward and the deck edge aft', count=10,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a low housing, a hood, a round lens', src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the Warden sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 3, 'bow/side': 3, 'mid/top': 4, 'mid/side': 4, 'stern/top': 5, 'stern/side': 6}
STRUCTURE_NOTE = ('Warden sheet: bow, the spearhead, its centre ridge and the casemate; midships, the body, the centre rail and the two flak tub '
                  'pairs (one pair tabled); stern, the body, the spine block, the spires, the two drums and bells')
LEFT_PLAIN = [
    'Frost-white markings, the half-sun crest, soot and wear: surface texture, painted by the Sunward paint stack (stage 5), not modelled.',
    'The concept\'s small panels and window dots along the hull are the paint stack\'s plate pattern and the band louvres; no portholes (factions.md).',
]
INV_NOTES = {'bow_plates': 'the cheek plates are themselves the forged layer on the spearhead (built, shaped, with bevels); their faces are too narrow '
                        'for a second plate course except at the root, which the casemate and the Q1 thrusters claim, so no rivet plates are laid on them'}
