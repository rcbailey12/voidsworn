# voidsworn_S11 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from the round 2 Harrow pictures, contrib/muse/design/class_family_sunward_2026_11/
# harrow_sheet.webp (top view above, side view middle, the stern view below; BOW ON THE LEFT in the top and side views) and
# harrow_beauty.webp (three-quarter from above, the bow lower left), PR 1163. designs.md "Harrow" governs counts (picture slips:
# five spires drawn, four tabled; the sheet's third view is the stern). The concept has no underside view.
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (prow tip to 33 percent): the leaf point, the tube cowls, the tubes, the magazine ----------------
    dict(id='spearhead', job='the blade\'s point and its forward armour (factions.md: a black iron blade)', type='hull',
         what='the forged point: one long leaf taper to a point at mid height, diamond in section', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, the centre ridge', src='picture'),
    dict(id='tube_cowls', job='carries the torpedo tubes: raised armoured houses on the deck, either side of the centreline', type='tier',
         what='two tube cowls on the deck at about 22 percent, their mouths forward, tapering aft into the deck', count=1, cells=['bow/top', 'bow/side'],
         reads='a forward face, a roof sloping back into the deck, the tube openings in it', src='picture'),
    dict(id='tubes', job='the Cinder torpedo salvo (torp F, 1 shot): the destroyer\'s reason to exist (designs.md: the torpedo bow)', type='launcher',
         what='twin torpedo tubes in raised deck cowls, one each side of the centreline', count=2, cells=['bow/top', 'bow/side'],
         reads='a tube house standing on the deck, a square riveted surround, a heavy forged collar with a rolled lip, a deep dark bore, the next torpedo\'s nose inside (R221)', src='picture'),
    dict(id='magazine_vents', job='the torpedo magazine sheds its reload heat (designs.md: ember heat-vent slits; data.js ability reload)', type='vent',
         what='three louvres on each upper facet over the magazine', count=6, cells=['bow/top', 'bow/side', 'mid/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the round 2 beauty\'s ember slits on the magazine section'),
    dict(id='blade', job='carries everything: the magazine, the crew deck, the reactor and the drives', type='hull',
         what='the faceted hull: a crowned deck, upper facets out to the knuckle, the vertical broadside band, lower facets, a flat worked belly', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine', src='picture'),
    dict(id='deck_plates', job='deck armour over the magazine and the crew deck', type='plate', what='ordered rows of forged plates over the deck', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flank_plates', job='side armour: the facets and the broadside band', type='plate', what='ordered rows of forged plates over the facets and the band', count=1,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belly_plates', job='belly armour', type='plate', what='forged plates over the belly and the armour step', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='trunk', job='the dorsal power trunk: the reactor\'s feed forward to the turrets and the tube room', type='spine',
         what='a banded armoured ridge along the centreline from the spine block\'s face to the tube cowls (the concept\'s centre stripe)', count=1,
         cells=['bow/top', 'mid/top'], reads='a stepped block with bands across it', src='picture'),
    # ---------------- midships (33 to 66 percent): the turret pair, the band ----------------
    dict(id='gun_deck', job='the hull\'s belt: armoured shelves over and under the plated band', type='belt', what='the broadside band with its upper and lower lips, both flanks',
         count=1, cells=['bow/side', 'mid/side', 'stern/side'], reads='a band along the hull with angled ends, plates on it', src='picture'),
    dict(id='band_louvres', job='the gallery spaces behind the band breathe out here', type='vent', what='small louvres in the plated band', count=10,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the round 2 sheet\'s small ember slits along the flank'),
    dict(id='turrets', job='the sear turret (turret T, 2 shots): the destroyer\'s guns against escorts', type='gun',
         what='one pair of single-emitter turrets on low tubs at the deck edges, station 46 percent', count=2, cells=['mid/top', 'mid/side'],
         reads='a riveted ring, a faceted forged dome, a block mantlet, one heavy emitter with cooling rings, an ember lens, a radiator bustle (R221)', src='picture'),
    dict(id='barbettes', job='the turrets\' footing at the deck edges', type='tier', what='two octagonal forged tubs', count=2, cells=['mid/top', 'mid/side'],
         reads='a skirt down the facet, a flat roof, the turret ring in it', src='picture'),
    dict(id='hatches', job='crew and stores access: deck hatches and belly hatches', type='hatch', what='forged round hatches on the deck and the belly step', count=6,
         cells=['bow/top', 'mid/top', 'mid/below'], reads='a studded rim, a door with a bar, a seam, hinges', src='designed'),
    # ---------------- stern (66 to 100 percent): the spire line and the engines ----------------
    dict(id='spine', job='the spire line\'s base: it carries the spires and the command deck\'s windows, and snaps off with the spires (B-3)', type='spine',
         what='the forged spine block along the centreline aft, its forward face', count=1, cells=['stern/top', 'stern/side', 'mid/top'], reads='a chamfered block, a stepped face, the window slits', src='picture'),
    dict(id='spine_plates', job='armour over the spine block', type='plate', what='forged plates over the spine block', count=1, cells=['stern/top', 'stern/side'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='bridge_slits', job='the command deck\'s windows', type='slit', what='three ember slits in the spine block\'s forward face', count=3,
         cells=['mid/top', 'stern/top'], reads='a forged frame round a recessed ember pane, a brow', src='picture'),
    dict(id='spires', job='shed the reactor\'s heat: the ember radiator spires', type='radiator',
         what='four radiator spires along the spine at 66 to 87 percent, tallest 0.85 (the final table), four profiles', count=4,
         cells=['stern/top', 'stern/side', 'mid/top'], reads='a forged root socket, iron posts fore and aft, iron fins out to each side with the ember core glowing between them, a forged cap, gusset braces',
         src='picture'),
    dict(id='vents', job='reactor heat louvres over the reactor room', type='vent', what='heat louvres on the upper facets aft', count=4, cells=['stern/side', 'stern/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='designed'),
    dict(id='engines', job='drive (sp 4): two ember bells, deep-set', type='engine', what='two engine bells, 0.8 across, offsets 0.55, on riveted drums', count=2,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='thrusters', job='attitude control at the bow and the stern (tn 2)', type='thruster', what='attitude thrusters on the upper facets fore and aft', count=4,
         cells=['bow/side', 'stern/side'], reads='a forged block, round nozzle throats with depth (R244)', src='designed'),
    dict(id='lamps', job='frost-white running points on the blade\'s edge (paint direction sunward.md 5)', type='lamp', what='small frost lamps along the knuckle forward and the deck edge aft', count=12,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a low housing, a hood, a round lens', src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the Harrow sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'mid/top': 4, 'mid/side': 4, 'stern/top': 6, 'stern/side': 7}
STRUCTURE_NOTE = ('Harrow round 2 sheet: bow, the spearhead, its ridge and the two tube mouths; midships, the body, the centre stripe and the turret pair; '
                  'stern, the body, the spine block, the spires, the two drums and bells')
LEFT_PLAIN = [
    'Frost-white markings (one thin stripe, a small sigil), soot and wear: surface texture, painted by the Sunward paint stack (stage 5), not modelled.',
    'The fifth spire the round 2 pictures draw: designs.md tables four.',
]
INV_NOTES = {'tubes': 'both tubes are built, as ONE launcher part with two bores (T1): data.js gives the Harrow one torp slot of 1 shot, and '
                        'weapon_match fails a pair of mounts on a 1-shot slot (SPLIT), so the two tubes are one mount that fires every volley'}
