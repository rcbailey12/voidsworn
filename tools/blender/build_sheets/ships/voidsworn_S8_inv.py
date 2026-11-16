# voidsworn_S8 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg (top view
# above, side view below, BOW ON THE RIGHT in both) and voidsworn_S8_beauty.jpg (three-quarter from astern, starboard and above,
# the engines lower left; the small ship lower right is an escort, not this hull). The concept has no underside view.
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (prow tip to 33 percent): the spearhead ----------------
    dict(id='spearhead', job='the blade\'s point and its forward armour: it meets fire head on as the line closes (factions.md: a black iron blade)', type='hull',
         what='the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull (replaces S8\'s fork, R232)', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, a raised centre ridge, two layers of cheek plates', src='picture'),
    dict(id='bow_plates', job='armour over the spearhead: forged plates in sleek triangles (R243)', type='plate', what='cheek plates and the bow facets\' plating', count=1,
         cells=['bow/top', 'bow/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='blade', job='carries everything: the gun deck, the galleries, the reactor and the drives', type='hull', what='the long faceted hull: a crowned deck, big upper facets sloping out to the knuckle, the vertical broadside band, lower facets, a flat worked belly; widest at the stern third',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine', src='picture'),
    dict(id='deck_plates', job='deck armour over the galleries and the turret wells', type='plate', what='ordered rows of forged plates over the deck', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flank_plates', job='side armour: the facets and the broadside band', type='plate', what='ordered rows of forged plates over the facets and the band', count=1,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belly_plates', job='belly armour', type='plate', what='forged plates over the belly and the armour step', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='lift_heads', job='armoured lift heads: stores up to the forward decks (HB1), power cells up to the Sear turrets (HB2)', type='hatchbox', what='low armoured deck housings on the centreline',
         count=2, cells=['bow/top', 'mid/top'], reads='a chamfered frame, an inset lid with a stacked plate, side ribs', src='designed'),
    dict(id='trunk', job='the dorsal power trunk: armoured conduits from the reactor to the turrets and the bow', type='spine', what='a low banded trunk along the deck\'s centreline (S8\'s long centre strip)',
         count=1, cells=['bow/top', 'mid/top'], reads='a stepped block with bands across it', src='picture'),
    # ---------------- midships (33 to 66 percent): the gun deck and the four deck turrets ----------------
    dict(id='gun_deck', job='the old manual gun deck: armoured shelves over and under the ports, the band they open in', type='belt', what='the broadside band with its upper and lower lips, both flanks (S8\'s recessed gun deck)',
         count=1, cells=['mid/side', 'mid/top'], reads='a band along the hull with angled ends, plates on it', src='picture'),
    dict(id='broadside', job='the heavy sear broadside (hbattery P and hbattery S, 5 shots each): the ship\'s main fire, a line of battle broadside', type='gun',
         what='heavy short guns in deep round ports, five a side (data.js hbattery P, hbattery S)', count=10, cells=['mid/side', 'mid/top'],
         reads='a square riveted surround, a deep round port collar with a rolled lip, a dark throat, a ball mantlet, a finned heat jacket, a banded barrel, a flared muzzle, a dark bore with an ember glow (R221)', src='picture'),
    dict(id='gallery_slits', job='the gun galleries\' vision slits: the crews behind the ports look out', type='slit', what='ember slits in the band between the ports', count=4,
         cells=['mid/side'], reads='a forged frame round a recessed ember pane, a brow', src='designed'),
    dict(id='sear_turrets', job='the Sear turret (turret T, 2 shots): a las weapon that turns all round', type='gun', what='two low domed turrets forward on tubs at the deck edges, one heavy emitter each',
         count=2, cells=['mid/top', 'mid/side'], reads='a flush riveted ring, a faceted forged dome with a banded skirt and a hatch, a radiator bustle with ember fins, a block mantlet, a finned jacket, a focusing tube, a lens collar, an ember lens (R221)',
         src='picture'),
    dict(id='flak', job='the spark flak (flak T, 3 shots): point defence against craft', type='gun', what='two low drum turrets aft on tubs at the deck edges, two barrels each', count=2,
         cells=['mid/top', 'mid/side'], reads='a riveted ring, a squat forged drum, a cradle, two ammunition drums, slotted cooling sleeves, squared muzzle brakes (R221)', src='picture'),
    dict(id='barbettes', job='the turret tubs: they raise the Sear pair over the flak and carry the turret rings', type='tier', what='low forged tubs under the four turrets', count=1,
         cells=['mid/top', 'mid/side'], reads='a face with ribs, a roof that takes the ring, the ring opening', src='designed'),
    dict(id='hatches', job='crew and stores access: deck hatches and belly hatches', type='hatch', what='forged round hatches on the deck and the belly step', count=8,
         cells=['bow/top', 'mid/top', 'mid/below', 'stern/below'], reads='a studded rim, a door with a bar, a seam, hinges', src='designed'),
    # ---------------- stern (66 to 100 percent): the spire line and the engines ----------------
    dict(id='spine', job='the spire line\'s base: it carries the spires and the command deck\'s windows, and snaps off with the spires (B-4)', type='spine',
         what='the forged spine block along the centreline aft, its stepped forward face', count=1, cells=['stern/top', 'stern/side'], reads='a chamfered block, a stepped face, the window slits', src='picture'),
    dict(id='spine_plates', job='armour over the spine block', type='plate', what='forged plates over the spine block', count=1, cells=['stern/top', 'stern/side'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='bridge_slits', job='the command deck\'s windows (factions.md: ember windows)', type='slit', what='three ember slits in the spine block\'s forward face', count=3,
         cells=['stern/top', 'mid/top'], reads='a forged frame round a recessed ember pane, a brow', src='picture', note='S8\'s lit block before the radiators'),
    dict(id='spires', job='shed the reactor\'s heat (a hot reactor in vacuum must shed it somewhere, lore 2.5): the ember radiator spires', type='radiator',
         what='seven radiator spires along the spine, tallest at the middle of the row, four profiles (blade, raked, stepped, twin)', count=7,
         cells=['stern/top', 'stern/side', 'mid/top'], reads='a forged root socket, a column (iron posts fore and aft round a dark core), a stack of horizontal radiator fins out to each side glowing ember, a forged cap, gusset braces',
         src='picture'),
    dict(id='vents', job='reactor heat louvres over the reactor room', type='vent', what='heat louvres on the upper facets aft', count=6, cells=['stern/side', 'stern/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='designed'),
    dict(id='engines', job='drive (sp 2): two big ember bells, deep-set', type='engine', what='two big engine bells on riveted drums (S8\'s two bells)', count=2,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a 16-sided drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='thrusters', job='attitude control at the bow and the stern, to turn the long hull (tn 1)', type='thruster', what='attitude thrusters on the upper facets, two forward and two aft', count=4,
         cells=['bow/side', 'stern/side'], reads='a forged block, round nozzle throats with depth (R244)', src='designed'),
    dict(id='lamps', job='frost-white running points on the blade\'s edge (paint direction sunward.md 5)', type='lamp', what='small frost lamps along the knuckle forward and the deck edge aft', count=14,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a low housing, a hood, a round lens', src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the S8 sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 4, 'bow/side': 2, 'mid/top': 8, 'mid/side': 5, 'stern/top': 7, 'stern/side': 6}
STRUCTURE_NOTE = ('S8 sheet: bow, the two fork blades, the slot between them and the centre strip; midships, the body, the two gun rows, the four '
                  'turret domes and the centre strip; stern, the body, the radiator bank (two halves), the lit block, the two drums and bells')
LEFT_PLAIN = [
    'Frost-white markings, the half-sun crest, chalked names, soot and wear: surface texture, painted by the Sunward paint stack (a later job, '
    'paint_direction_2026_11/sunward.md), not modelled.',
    'The escort beside the flagship in the beauty is its own ship (a later fleet brief), not part of this hull.',
]
INV_NOTES = {}
