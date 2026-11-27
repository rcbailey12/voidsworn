# voidsworn_S9O parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from docs/ship_pipeline/build_sheets/voidsworn_S9/concept_sheet.jpg (top view
# above, side view lower left, BOW ON THE LEFT in both; the bow-on view lower right) and concept_beauty.jpg (three-quarter from
# ahead, port and above, the bow lower left). designs.md's Warden table governs counts where a picture differs (its "Picture
# slips": the beauty's four deck tubs are one flak pair; its four spires are three).
# Fields: id, job, type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (point to 33 percent): the spearhead and the repeater ----------------
    dict(id='spearhead', job='the blade\'s point and its forward armour, carrying the repeater casemate', type='hull',
         what='the forged spearhead: one point at mid height, diamond in section at the tip, its facets running back into the hull', count=1,
         cells=['bow/top', 'bow/side', 'bow/below'], reads='upper and lower facets meeting at the band, a narrowing deck ridge, a chine', src='picture'),
    dict(id='repeater', job='the Sear repeater (autocannon F, 3 shots): the frigate is built round its bow gun', type='gun',
         what='a compact forged casemate at the spearhead root, station 14 percent, a three-barrel rotary cluster', count=1,
         cells=['bow/top', 'bow/side'], reads='a riveted footing, an armoured housing with cheek plates and a sloped glacis, a round port collar, a ball mantlet, a heat jacket, three barrels round a spindle, muzzles, dark bores',
         src='picture', note='the concept draws twin barrels on a box; the table and the kit: a three-barrel rotary cluster'),
    dict(id='spike', job='the worked-iron blade line on the spearhead\'s ridge (the concept\'s bright spike), broken round the casemate', type='belt',
         what='a raised iron race with a worked-iron inlay along the ridge from the point to the spearhead root', count=1,
         cells=['bow/top'], reads='a race and an inlay, cut at the casemate', src='picture'),
    dict(id='bow_plates', job='armour over the spearhead\'s facets and the casemate seat: forged plates in sleek triangles (R243)', type='plate',
         what='the spearhead\'s plating', count=1, cells=['bow/top', 'bow/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    # ---------------- the whole blade ----------------
    dict(id='blade', job='carries everything: the galleries, the reactor and the drives', type='hull',
         what='the long faceted hull (FlatSoleLoft modules): a flat deck, shoulders out to the band, the vertical band, lower facets, a chine, a flat worked sole; widest at 72 percent',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled facets and chamfers (never a flat wall, R244), the band\'s top and bottom lines, a chine', src='picture'),
    dict(id='deck_plates', job='deck armour over the galleries', type='plate', what='ordered rows of forged plates over the deck', count=1,
         cells=['mid/top', 'stern/top'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flank_plates', job='side armour: the shoulders, the band and the lower facets', type='plate', what='ordered rows of forged plates', count=1,
         cells=['mid/side', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belly_plates', job='belly armour', type='plate', what='forged plates over the chine and the sole', count=1,
         cells=['bow/below', 'mid/below', 'stern/below'], reads='slabs with bevels, reinforcing steps and rivet lines', src='designed'),
    # ---------------- midships (33 to 66 percent): the trunk, the flak pair, the band ----------------
    dict(id='trunk', job='the raised feed trunk: power and the shell feed run forward under it from the reactor to the bow magazine', type='spine',
         what='a raised armoured trunk along the centreline from behind the casemate to the spine block\'s face, banded across', count=1,
         cells=['mid/top', 'bow/top'], reads='a stepped block with bands across it', src='picture', note='the concept\'s long centreline rail'),
    dict(id='strakes', job='forged shelves along the deck edges that carry the flak tubs', type='belt', what='a strake along each deck edge midships', count=1,
         cells=['mid/top', 'mid/side'], reads='a shelf with angled ends, plates on it', src='picture', note='the concept\'s side strakes under the tubs'),
    dict(id='strake_plates', job='armour on the strakes', type='plate', what='forged plates on the strake tops', count=1, cells=['mid/top'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='flak', job='the spark flak (flak T, 3 shots): point defence against craft', type='gun',
         what='one pair of small twin drum turrets at the deck edges, station 60 percent', count=2, cells=['mid/top', 'mid/side'],
         reads='a riveted ring, a squat drum, ammunition drums on the cheeks, twin barrels in cooling sleeves, squared muzzle brakes, bores', src='picture',
         note='the beauty draws four tubs; the table: one pair'),
    dict(id='race', job='the frost trim race along each flank\'s band, broken round the boarding doors', type='belt',
         what='a raised iron race with a worked-iron inlay along the band', count=1, cells=['mid/side', 'stern/side'], reads='a race and an inlay, cut at the door', src='designed'),
    dict(id='doors', job='boarding doors in the band (hp_board)', type='hatch', what='a square door in each flank\'s band', count=2, cells=['mid/side'],
         reads='a studded rim, a door with a bar, a seam, hinges', src='designed'),
    dict(id='gallery_slits', job='the crew galleries\' vision slits (the concept\'s ember slits low on the band)', type='slit',
         what='ember slits along the band, six a side', count=12, cells=['mid/side', 'stern/side', 'bow/side'], reads='a forged frame round a recessed ember pane, a brow', src='picture'),
    dict(id='hatches', job='crew and stores access on the deck', type='hatch', what='forged round deck hatches', count=4, cells=['mid/top'],
         reads='a studded rim, a door with a bar, a seam, hinges', src='picture'),
    dict(id='lift_heads', job='the shell hoist head over the bow magazine\'s feed', type='hatchbox', what='a low armoured deck housing beside the trunk', count=1,
         cells=['mid/top'], reads='a chamfered frame, an inset lid with a stacked plate, side ribs', src='designed'),
    # ---------------- stern (66 to 100 percent): the spire line, coolers and engines ----------------
    dict(id='spine', job='the spire line\'s base: it carries the spires and the command windows, and snaps off with the spires (B-4)', type='spine',
         what='the forged spine block along the centreline aft, its forward face at station 58 percent', count=1, cells=['stern/top', 'stern/side', 'mid/top'],
         reads='a chamfered block, a stepped face, the window slits', src='picture'),
    dict(id='spine_plates', job='armour over the spine block', type='plate', what='forged plates over the spine block', count=1, cells=['stern/top'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='bridge_slits', job='the command deck\'s windows (designs.md: ember slits in the spine block face, station 58 percent)', type='slit',
         what='two ember slits in the spine block\'s forward face, either side of the trunk', count=2, cells=['mid/top', 'stern/top'], reads='a forged frame round a recessed ember pane, a brow', src='picture'),
    dict(id='spires', job='shed the reactor\'s heat: the ember radiator spires', type='radiator',
         what='three low radiator spires at 68 / 76 / 84 percent, tallest in the middle, three profiles', count=3, cells=['stern/top', 'stern/side'],
         reads='a forged root socket, iron posts, iron fin ribs with the ember core glowing between them, a forged cap, gusset braces', src='picture'),
    dict(id='coolers', job='the reactor\'s cooler cassettes on the aft deck beside the spine block', type='vent', what='four slatted cassettes a side', count=8,
         cells=['stern/top', 'mid/top'], reads='a forged frame, spaced slats over an ember-lit recess', src='picture', note='the concept\'s grilles round the spire base'),
    dict(id='vents', job='reactor heat louvres on the aft shoulders', type='vent', what='two louvres a side', count=4, cells=['stern/side', 'stern/top'],
         reads='a forged frame, slanted slats over an ember-lit recess', src='designed'),
    dict(id='engines', job='drive: two ember bells, deep-set', type='engine', what='two engine bells, 0.55 across, offsets 0.4, on riveted drums', count=2,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='a drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='thrusters', job='attitude control at the bow and the stern', type='thruster', what='attitude thrusters, two forward on the lower facets and two aft on the shoulders', count=4,
         cells=['bow/side', 'stern/side'], reads='a forged block, round nozzle throats with depth (R244)', src='designed'),
    dict(id='belly_covers', job='removable service covers over the belly trunk', type='cover', what='five covers along the belly centreline', count=5,
         cells=['mid/below', 'stern/below'], reads='a seated flange and a separate lid', src='designed'),
    dict(id='lamps', job='frost-white running points on the shoulder edges', type='lamp', what='small frost lamps along each shoulder, five a side', count=10,
         cells=['bow/side', 'mid/side', 'stern/side'], reads='a low housing, a hood, a round lens', src='designed'),
]
# Structure: distinct masses per blob-sweep cell, counted by eye on the Warden sheet's top and side views (thirds of the length).
STRUCTURE = {'bow/top': 3, 'bow/side': 2, 'mid/top': 4, 'mid/side': 3, 'stern/top': 6, 'stern/side': 6}
STRUCTURE_NOTE = ('Warden sheet: bow, the spearhead, its spike and the casemate; midships, the body, the centre rail and the two strakes with their tubs; '
                  'stern, the body, the spine block, the spires, the grilles, the two drums and bells')
LEFT_PLAIN = [
    'Frost-white markings, the half-sun crest, soot and wear: surface texture, painted by the Sunward paint stack, not modelled.',
    'The flame plumes the pictures draw at the bells: in game the bells glow ember and the game draws the plume.',
]
INV_NOTES = {}
