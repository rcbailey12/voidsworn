# voidsworn_S10 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_sunward_2026_11/vigil_sheet.webp (top view
# above, side view lower left, BOW ON THE LEFT in both; the front view lower right) and vigil_beauty.webp (three-quarter from
# ahead, starboard and above, the bow lower left). designs.md's Vigil table governs counts where a picture differs (it lists the
# slips: the beauty's forked point, muddled port counts; the sheet's three port columns and seven spires).
# Fields: id, job (what the part does on the ship, R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (point to 33 percent): the spearhead and the lance ----------------
    dict(id='spearhead', job='the blade\'s point and its forward armour, carrying the lance', type='hull',
         what='the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull and forward into the lance collar', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, the centre ridge', src='picture'),
    dict(id='lance', job='the Oath lance (lance F, 1 shot, 20 damage, range 7): the cruiser\'s signature weapon', type='lance',
         what='one emitter in the spearhead\'s point (designs.md: "single emitter set in the spearhead face, station 4 percent")', count=1,
         cells=['bow/top', 'bow/side'], reads='breech collars, a banded capacitor housing, a diamond muzzle collar, a rolled lip, a deep dark bore, focusing rings, a small ember lens',
         src='picture', note='the beauty draws a big glowing disc between fork tines; the table and the Board\'s brief: one emitter in the point, never a big disc'),
    dict(id='trunk', job='the dorsal ridge: the lance\'s power trunk to station 30 percent, then the reactor feeds on to the spire block', type='spine',
         what='a raised armoured ridge along the centreline from the lance to the spine block (the concept\'s strongest line)',
         count=1, cells=['bow/top', 'bow/side', 'mid/top'], reads='a stepped block with bands across it', src='picture'),
    dict(id='trunk_plates', job='armour over the dorsal ridge', type='plate', what='forged plates over the ridge\'s faces', count=1, cells=['bow/top', 'mid/top'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='bow_plates', job='armour over the spearhead and the cheek housings: forged plates in sleek triangles (R243)', type='plate', what='the cheek housings\' and bow facets\' plating', count=1,
         cells=['bow/top', 'bow/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='cheek_vents', job='the capacitor banks shed their charge heat', type='vent', what='three small louvres on each cheek housing', count=6,
         cells=['bow/top', 'bow/side'], reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the beauty\'s ember slits along the bow facets'),
    dict(id='blade', job='carries everything: the gun deck, the galleries, the reactor and the drives', type='hull', what='the long faceted hull: a crowned deck, upper facets out to the knuckle, the vertical broadside band, lower facets, a flat worked belly; widest at the stern third',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine', src='picture'),
    dict(id='deck_plates', job='deck armour over the galleries', type='plate', what='ordered rows of forged plates over the deck', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flank_plates', job='side armour: the facets and the broadside band', type='plate', what='ordered rows of forged plates over the facets and the band', count=1,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belly_plates', job='belly armour', type='plate', what='forged plates over the belly and the armour step', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    # ---------------- midships (33 to 66 percent): the gun deck ----------------
    dict(id='gun_deck', job='the old manual gun deck: armoured shelves over and under the ports', type='belt', what='the broadside band with its upper and lower lips, both flanks',
         count=1, cells=['mid/side', 'mid/top'], reads='a band along the hull with angled ends, plates on it', src='picture'),
    dict(id='broadside', job='the Sear battery (battery P and battery S, 4 shots each): the cruiser\'s broadside', type='gun',
         what='guns in deep round ports, four a side at 38 / 47 / 56 / 65 percent (data.js battery P, battery S)', count=8, cells=['mid/side', 'mid/top'],
         reads='a square riveted surround, a deep round port collar with a rolled lip, a dark throat, a ball mantlet, a finned heat jacket, a barrel, a flared muzzle, an ember bore (R221)', src='picture'),
    dict(id='gallery_slits', job='the gun galleries\' vision slits', type='slit', what='ember slits in the band between two pairs of ports', count=4,
         cells=['mid/side'], reads='a forged frame round a recessed ember pane, a brow', src='picture', note='the sheet\'s ember gallery slits between the ports'),
    dict(id='hatches', job='crew and stores access: deck hatches and belly hatches', type='hatch', what='forged round hatches on the deck and the belly step', count=8,
         cells=['bow/top', 'mid/top', 'mid/below', 'stern/below'], reads='a studded rim, a door with a bar, a seam, hinges', src='designed'),
    dict(id='lift_heads', job='the hoist head over the gun deck: shells up from the shell rooms', type='hatchbox', what='a low armoured deck housing on the centreline',
         count=1, cells=['mid/top'], reads='a chamfered frame, an inset lid with a stacked plate, side ribs', src='designed'),
    # ---------------- stern (66 to 100 percent): the spire line and the engines ----------------
    dict(id='spine', job='the spire line\'s base: it carries the spires and the command deck\'s windows, and snaps off with the spires (B-4)', type='spine',
         what='the forged spine block along the centreline aft, its forward face', count=1, cells=['stern/top', 'stern/side', 'mid/top'], reads='a chamfered block, a stepped face, the window slits', src='picture'),
    dict(id='spine_plates', job='armour over the spine block', type='plate', what='forged plates over the spine block', count=1, cells=['stern/top', 'stern/side'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    dict(id='bridge_slits', job='the command deck\'s windows (designs.md: ember slits in the spine block face, station 60 percent)', type='slit', what='three ember slits in the spine block\'s forward face', count=3,
         cells=['mid/top', 'stern/top'], reads='a forged frame round a recessed ember pane, a brow', src='picture'),
    dict(id='spires', job='shed the reactor\'s heat: the ember radiator spires', type='radiator',
         what='five radiator spires along the spine at 64 to 88 percent, tallest (1.2, R331: 70 percent of the table\'s 1.7) in the middle, four profiles', count=5,
         cells=['stern/top', 'stern/side', 'mid/top'], reads='a forged root socket, iron posts fore and aft, iron fins out to each side with the ember core glowing between them, a forged cap, gusset braces',
         src='picture'),
    dict(id='vents', job='reactor heat louvres over the reactor room', type='vent', what='heat louvres on the upper facets aft', count=6, cells=['stern/side', 'stern/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='designed'),
    dict(id='engines', job='drive (sp 3): two ember bells, deep-set', type='engine', what='two engine bells, 1.2 across, offsets 0.8, on riveted drums', count=2,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='thrusters', job='attitude control at the bow and the stern (tn 2)', type='thruster', what='attitude thrusters, two forward on the lower facets and two aft on the upper facets', count=4,
         cells=['bow/side', 'stern/side'], reads='a forged block, round nozzle throats with depth (R244)', src='designed'),
    dict(id='lamps', job='frost-white running points on the blade\'s edge (paint direction sunward.md 5)', type='lamp', what='small frost lamps along the knuckle forward and the deck edge aft', count=14,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a low housing, a hood, a round lens', src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the Vigil sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 3, 'bow/side': 2, 'mid/top': 4, 'mid/side': 4, 'stern/top': 6, 'stern/side': 7}
STRUCTURE_NOTE = ('Vigil sheet: bow, the spearhead, the centre ridge and the lance; midships, the body, the two gun rows and the centre ridge; stern, '
                  'the body, the spine block, the spires, the two drums and bells')
LEFT_PLAIN = [
    'Frost-white markings, the half-sun crest, soot and wear: surface texture, painted by the Sunward paint stack, not modelled.',
    'The flame plumes the sheet draws at the bells: in game the bells glow ember and the game draws the plume.',
]
INV_NOTES = {}
