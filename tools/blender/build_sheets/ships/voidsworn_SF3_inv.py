# voidsworn_SF3 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg (one
# three-quarter view from above and to port of the bow, the drives lower right) and design_notes_757.md (section SF3, the production
# notes). The concept has no underside and no true views. A craft is bold and simple: fine greeble at this size reads as a shrunken
# capital ship (the production notes), so the list is short and every line has a job.
# Fields: id, job (what the part does on the craft, R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (point to 33 percent): the blade and the gun well ----------------
    dict(id='blade', job='the craft\'s one body: it carries the gun, the pilot, the reactor and the drives, and meets fire edge on', type='hull',
         what='one narrow forged blade: a low spine strip, the deck, upper facets sloping out to a thin knife edge, lower facets, a flat belly; widest at the stern third',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/side', 'stern/below'],
         reads='angled facets meeting at the knife edge, the spine strip, a flat belly (no wing, no sweep, no aerofoil)', src='picture'),
    dict(id='blade_plates', job='armour over the blade: forged plates in rows, sleek triangles on the upper facets (R243)', type='plate',
         what='forged plates over the deck, the facets and the belly', count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='guns', job='the interceptor guns (data.js guns T, 3 shots): the wing\'s only weapon', type='gun',
         what='three barrels in one emitter cluster on a shallow traverse ring, in an armoured well on the blade\'s back near the bow', count=1,
         cells=['bow/top', 'bow/side'], reads='a riveted well rim, a traverse ring, a low faceted housing, a block mantlet, a banded cluster jacket, three flared muzzles with dark bores (R221)',
         src='picture', note='the concept\'s three muzzles in a dorsal bow recess'),
    # ---------------- midships (33 to 66 percent): the stern block's face, the spire ----------------
    dict(id='stern_block', job='the armoured block the blade thickens into: it holds the pilot, the reactor and the drives', type='hull',
         what='a raised armoured block on the blade\'s stern, a sloping forward face, chamfered shoulders, upright flanks', count=1,
         cells=['mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='the sloping face, the shoulder chamfers, the flanks', src='picture'),
    dict(id='block_plates', job='armour over the stern block', type='plate', what='forged plates over the block\'s top and flanks', count=1,
         cells=['mid/top', 'stern/top', 'stern/side'], reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='sensor_slit', job='the pilot\'s view out: no canopy (Ryan, R254), an armoured slit at most', type='slit',
         what='one ember-lit armoured slit in the stern block\'s sloping face', count=1, cells=['mid/top'],
         reads='a forged frame round a recessed ember pane, a brow', src='designed', note='replaces any canopy; the concept\'s dark slot near the bow is the gun well'),
    dict(id='spire', job='sheds the drive reactor\'s heat (a hot reactor in vacuum must shed it, lore 2.5): the flagship\'s spire row reduced to one', type='radiator',
         what='one short radiator spire on the stern block, square-topped, four ember fins a side', count=1, cells=['mid/top', 'mid/side', 'stern/top'],
         reads='a forged root socket with an ember glow at its foot, a column (iron posts round a dark core), the ember fins, a forged cap, gusset braces', src='picture'),
    # ---------------- stern (66 to 100 percent): the drives and the louvres ----------------
    dict(id='drives', job='drive (sp 6): two deep bells, nozzle clusters inside armoured blocks (the owner\'s rule for craft)', type='engine',
         what='two deep bells sunk in eight-sided armoured cowls in the stern face', count=2, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='an eight-sided cowl with a riveted face, a band and a collar, the bell sunk in it with a lip and a stiffener ring, an ember lining, a hot throat, a glowing plug cone',
         src='picture'),
    dict(id='louvres', job='the drive room\'s heat louvres', type='vent', what='one heat louvre on each flank of the stern block', count=2,
         cells=['stern/side'], reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the concept\'s glowing flank slats'),
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 4, 'mid/side': 3, 'stern/top': 4, 'stern/side': 4}
STRUCTURE_NOTE = ('SF3 beauty, by eye (no true views): bow, the blade and the gun recess; midships, the blade, the block\'s face, the spire and '
                  'the flank panels; stern, the block, the two drive drums and the flank slats')
LEFT_PLAIN = [
    'The frost-white oath stripe along the blade edge, the trim lines and wear: paint, by the Sunward paint stack (issue 756, applied later), not modelled.',
    'The concept\'s glyph-like hull decals: generator noise, not markings (design_notes_757.md, production notes).',
    'Hatches, lamps and attitude thrusters: below what the battle camera shows on a 3.84 unit craft, and the drives turn it; not built.',
]
INV_NOTES = {}
