# voidsworn_SB4 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SB4.jpg (one
# three-quarter view from above and to starboard of the bow, the drives upper right) and design_notes_757.md (section SB4: "the
# hull IS the magazine"). The concept has no underside and no true views. Bold and simple: fine greeble at this size reads as a
# shrunken capital ship (the production notes).
# Fields: id, job (R221), type (tools/blender/kits/voidsworn/parts.py SUBPARTS), what, count, cells, reads, src.
KIT = 'voidsworn'
INVENTORY = [
    # ---------------- bow (bow face to 33 percent): the bomb cassette ----------------
    dict(id='bomb_cassette', job='the bomb payload (data.js bombs T, 2 shots): the wing\'s only weapon, the bomber\'s bow face', type='bomb_tube',
         what='a deep armoured cassette with two big tube mouths, heavy shaped rims, the next bomb seated in each bore, the bombardier\'s sight slit between',
         count=1, cells=['bow/top', 'bow/side'],
         reads='a front plate with two round mouths, a housing round the bores, dark bores with a bomb nose deep inside, twelve-sided rims with forged lugs and studs, the sight slit (R221, R244)',
         src='picture', note='the concept\'s two bow mouths on a traverse cassette'),
    dict(id='block', job='the craft\'s one body, built round the bomb magazine: the hull IS the magazine', type='hull',
         what='one massive faceted block: deck, deck chamfers, the vertical flank band, lower chamfers, a flat belly; the bow face set back for the cassette',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='angled chamfers round the flank band (never a flat wall, R244), a stepped bow face', src='picture'),
    dict(id='block_plates', job='armour over the block', type='plate', what='forged plates over the deck, the chamfers, the band and the belly, sleek triangles on the deck chamfers (R243)',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    # ---------------- midships (33 to 66 percent): the magazine ridges and belts ----------------
    dict(id='ridges', job='armoured roofs over the two bomb rows, one row feeding each tube', type='spine',
         what='two raised armour ridges along the deck, chamfered, their ends tapered', count=2, cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'],
         reads='a chamfered block with stepped ends and plates on it', src='picture', note='the concept\'s two raised dorsal blocks'),
    dict(id='ridge_plates', job='armour over the ridges', type='plate', what='forged plates over the ridges', count=1, cells=['mid/top', 'stern/top'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    dict(id='belts', job='a second forged layer over each flank where the bomb rows lie', type='belt', what='a raised armour belt along each flank band, its ends angled',
         count=2, cells=['mid/side', 'bow/side', 'stern/side'], reads='a band along the hull with angled ends, plates on it', src='picture',
         note='the concept\'s heavy flank armour panels'),
    dict(id='belt_plates', job='armour over the belts', type='plate', what='forged plates over the belts', count=1, cells=['mid/side'],
         reads='slabs with bevels, reinforcing steps and rivet lines', src='picture'),
    # ---------------- stern (66 to 100 percent): the drives and the louvres ----------------
    dict(id='drives', job='drive (sp 5): four deep bells, nozzle clusters inside armoured blocks (the owner\'s rule for craft)', type='engine',
         what='two pairs of deep bells sunk in eight-sided armoured cowls in the stern face', count=4, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='an eight-sided cowl with a riveted face, a band and a collar, the bell sunk in it with a lip and a stiffener ring, an ember lining, a hot throat, a glowing plug cone',
         src='picture', note='the concept\'s ember bell clusters in the stern faces'),
    dict(id='louvres', job='the drive room\'s heat louvres', type='vent', what='one heat louvre on the aft end of each ridge', count=2,
         cells=['stern/top'], reads='a forged frame, slanted slats over an ember-lit recess', src='picture', note='the concept\'s ember roof slits'),
]
STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'mid/top': 5, 'mid/side': 4, 'stern/top': 5, 'stern/side': 4}
STRUCTURE_NOTE = ('SB4 beauty, by eye (no true views): bow, the block, the bow face and the two rims; midships, the block, the two ridges, '
                  'the flank panels; stern, the block, the ridges, the drive pods and their glow')
LEFT_PLAIN = [
    'The frost-white oath band across one shoulder, the ember trim lines and wear: paint, by the Sunward paint stack (issue 756, applied later), not modelled.',
    'The concept\'s small panels, grilles and boxes on the flanks: fine greeble that reads as a shrunken capital ship at this size (production notes); the belts and plates carry the flanks.',
    'Hatches, lamps and attitude thrusters: below what the battle camera shows on a 3.84 unit craft, and the drives turn it; not built.',
]
INV_NOTES = {}
